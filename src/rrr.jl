# RRR
# ---

# Raman, R., Raman, V., & Satti, S. R. (2007).
# Succinct Indexable Dictionaries with Applications to Encoding k-ary Trees, Prefix Sums and Multisets,
# 3(4), 1–25. doi:10.1145/1290672.1290680
#
# Claude, F., & Navarro, G. (2008).
# Practical Rank / Select Queries over Arbitrary Sequences,
# 080019(i), 176–187.

const blocksize = 15
const classsize =  4
const superblock_sampling_rate = 32  # blocks per superblock
const superblocksize = blocksize * superblock_sampling_rate

@assert 1 ≤ blocksize ≤ 63

immutable SuperBlock
    # partial sum of rank values
    rank::Uint32
    # offset of the starting position of r-index
    offset::Uint32
end

type RRR <: AbstractIndexedBitVector
    # class values for each block
    # class values are encoded in 4 bits, hence `ks` is a packed array of 4-bit elements
    ks::Vector{Uint8}
    # r-indices (or offset) for each block
    # r-index is a variable-length encoding of position in a class. This array is also packed without delimiters.
    rs::Vector{Uint16}
    # sampled blocks
    superblocks::Vector{SuperBlock}
    # length of bits
    len::Uint32
end

RRR() = RRR(Uint8[], Uint8[], SuperBlock[], 0)

function RRR(src::Union(BitVector,Vector))
    len = length(src)
    n_blocks = div(len - 1, blocksize) + 1
    ks = Uint8[]
    rs = Uint16[]
    superblocks = SuperBlock[]
    rank = 0
    n_rembits = 0  # the number of remaining bits in rs
    for i in 1:n_blocks
        # sample superblock
        if i % superblock_sampling_rate == 1
            superblock = SuperBlock(rank, length(rs) * 16 - n_rembits + 1)
            push!(superblocks, superblock)
        end

        # bits, class and r-index
        bits = packbits(src, (i - 1) * blocksize + 1, blocksize)
        k = count_ones(bits)
        r = bits2rindex(bits, blocksize, k)
        @assert 0 ≤ k ≤ blocksize
        @assert 0 ≤ r < binomial(blocksize, k)
        rank += k

        # store the class to ks
        if isodd(i)
            # use upper 4 bits: here----
            push!(ks, k << 4)
        else
            # use lower 4 bits: ----here
            ks[end] |= k
        end

        # store the r-index to rs
        if isempty(rs)
            push!(rs, 0x0000)
            n_rembits += 16
        end
        # the number of bits required to store r-index
        n_rbits = nbits(blocksize, k)
        @assert n_rbits ≤ 16
        if n_rembits ≥ n_rbits
            # this r-index can be stored in the last element
            rs[end] |= r << (n_rembits - n_rbits)
        else
            # this r-index spans the two last elements
            rs[end] |= r >>> (n_rbits - n_rembits)
            push!(rs, 0x0000)
            rs[end] |= r << (16 - (n_rbits - n_rembits))
            n_rembits += 16
        end
        n_rembits -= n_rbits
    end
    return RRR(ks, rs, superblocks, len)
end

function convert(::Type{RRR}, src::Union(BitVector,Vector))
    return RRR(src)
end

length(rrr::RRR) = rrr.len
endof(rrr::RRR) = rrr.len

function getindex(rrr::RRR, i::Integer)
    @assert 1 ≤ i ≤ length(rrr)
    j = div(i - 1, blocksize) + 1
    k, r, _ = jthblock(rrr, j)
    bits = E[K[k+1]+r+1]
    bits <<= 16 - blocksize
    return bitat(Uint16, bits, rem(i - 1, blocksize) + 1)
end

function rank1(rrr::RRR, i::Integer)
    @assert 0 ≤ i ≤ length(rrr)
    j, rem = divrem(i - 1, blocksize)
    k, r, rank = jthblock(rrr, j + 1)
    bits = E[K[k+1]+r+1]
    bits <<= 16 - blocksize
    rank += count_ones(bits & lmask(Uint16, rem + 1))
    return convert(Int, rank)
end

# return the class of j-th block
function classof(rrr::RRR, j::Int)
    ki, rem = divrem(j - 1, 2)
    @inbounds k = rrr.ks[ki+1]
    if rem == 0
        k >>= 4
    else
        k &= 0x0f
    end
    return k
end

function jthblock(rrr::RRR, j::Int)
    @assert 1 ≤ j
    i = div(j - 1, superblock_sampling_rate)
    superblock = rrr.superblocks[i+1]
    # read blocks just before the j-th block in the superblock
    rank = convert(Int, superblock.rank)
    offset = convert(Int, superblock.offset)
    lo = i * superblock_sampling_rate + 1
    hi = j - 1
    for j′ in lo:hi
        k = classof(rrr, j′)
        offset += nbits(blocksize, k)
        rank += k
    end
    # read the j-th block
    k = classof(rrr, j)
    r = read_rindex(rrr.rs, offset, nbits(blocksize, k))
    return k, r, rank
end

lmask{T<:Unsigned}(typ::Type{T}, n::Int) = typemax(typ) << (sizeof(typ) * 8 - n)
rmask{T<:Unsigned}(typ::Type{T}, n::Int) = typemax(typ) >> (sizeof(typ) * 8 - n)

# return left-aligned bits
function packbits(src::Union(BitVector,Vector), from::Int, len::Int)
    @assert 1 ≤ len ≤ 64
    bits = zero(Uint64)
    to = from + len - 1
    for i in from:min(to, endof(src))
        bits <<= 1
        if src[i]
            bits |= 1
        end
    end
    if to > endof(src)
        # align bits to the left
        bits <<= to - endof(src)
    end
    return bits
end

# offset is 1-based index
function read_rindex(rs::Vector{Uint16}, offset::Int, len::Int)
    ri, rem = divrem(offset - 1, 16)
    if 16 - rem ≥ len
        # stored in an element
        # |      ri+1      |      ri+2      |
        # |................|................|
        # |    xxxxxx      |                |
        #----->|offset
        # |<->|rem
        #      |<-->|len
        @inbounds r = rs[ri+1] & rmask(Uint16, 16 - rem)
        r >>= 16 - (rem + len)
    else
        # spans two elements
        # |      ri+1      |      ri+2      |
        # |................|................|
        # |          xxxxxx|xxxx            |
        #----------->|offset
        # |<------->|rem
        #            |<---- -->|len
        # |<--------------- -->|rem+len
        @inbounds r1 = rs[ri+1] & rmask(Uint16, 16 - rem)
        r1 <<= rem + len - 16
        @inbounds r2 = rs[ri+2] & lmask(Uint16, rem + len - 16)
        r2 >>= 32 - (rem + len)
        r = convert(Uint16, r1 + r2)
    end
    return convert(Int, r)
end

# Bit Encoding
# ------------

# Example: t = 4, k = 2
#   r | bits
#   - | ----
#   0 | 0011
#   1 | 0101
#   2 | 0110
#   3 | 1001
#   4 | 1010
#   5 | 1100

# Inverse transformation of bits2rindex (encoding).
# `bits` should be filled from the least significant bit.
# For example, 0b00...001 is the first bits of the class k=1.
function bits2rindex(bits::Uint64, t::Int, k::Int)
    @assert count_ones(bits) == k
    @assert 0 ≤ k ≤ t ≤ 64
    r = 0
    i = 65 - t
    while k > 0
        if bitat(bits, 65 - t)
            r += binomial(t - 1, k)
            k -= 1
        end
        i += 1
        t -= 1
    end
    return r
end

# Inverse transformation of bits2rindex (decoding).
function rindex2bits(r::Int, t::Int, k::Int)
    @assert 0 ≤ r < binomial(t, k)
    @assert 0 ≤ k ≤ t ≤ 64
    bits = zero(Uint64)
    while r > 0
        if r ≥ binomial(t - 1, k)
            # the first bit is 1
            bits |= 1 << (t - 1)
            r -= binomial(t - 1, k)
            k -= 1
        end
        t -= 1
    end
    bits |= typemax(Uint64) >>> (64 - k)
    return bits
end

# enumeration of bit patterns for blocks, sorted by class and r-index
const E, K = let
    t = 16
    @assert t == blocksize + 1
    bitss = Uint16[]
    offsets = Int[]
    for k in 0:blocksize+1
        push!(offsets, length(bitss))
        for r in 0:binomial(t, k)-1
            bits = rindex2bits(r, t, k)
            push!(bitss, convert(Uint16, bits))
        end
    end
    bitss, offsets
end

# Lookup table to know the number of bits to encode class k's r-index with length t
const NBits = [t ≥ k ? iceil(log2(binomial(t, k))) : 0 for t in 1:blocksize, k in 0:blocksize]

function nbits(t, k)
    return NBits[t,k+1]
end

