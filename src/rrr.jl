# RRR
# ---
#
# This file implements two variants of the original RRR:
# RRR: RRR of Claude and Navarro (2008)
#   - The block size is 15 bits and the original block is decoded from a universal table.
# * RRRNP: RRR of Navarro and Providel (2012)
#   - The block size is 63 bits and the original block is decoded on the fly.


# TODO: formatting citations
# Raman, R., Raman, V., & Satti, S. R. (2007).
# Succinct Indexable Dictionaries with Applications to Encoding k-ary Trees, Prefix Sums and Multisets,
# 3(4), 1–25. doi:10.1145/1290672.1290680
#
# Claude, F., & Navarro, G. (2008).
# Practical Rank / Select Queries over Arbitrary Sequences,
# 080019(i), 176–187.
#
# Navarro, G., & Providel, E. (2012). Fast , Small , Simple Rank / Select on Bitmaps, (1).

# Data Layout
# bits:      ..|...............|...............|... ...|...............|..
# blocks:      |   block j+1   |   block j+2   |  ...  |  block j+ssr  |
# superblocks: |                       superblock                      |

const superblock_sampling_rate = 16  # blocks per superblock

# sampling rate controls the tradeoff between performance and space
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

blocksizeof(::Type{RRR}) = 15
empty_rs(::Type{RRR}) = Uint16[]

RRR() = RRR(Uint8[], Uint8[], SuperBlock[], 0)
RRR(src::Union(BitVector,Vector)) = make_rrr(RRR, src)

function convert(::Type{RRR}, src::Union(BitVector,Vector))
    return RRR(src)
end

length(rrr::RRR) = rrr.len
endof(rrr::RRR) = rrr.len

function getindex(rrr::RRR, i::Integer)
    if !(1 ≤ i ≤ endof(rrr))
        throw(BoundsError())
    end
    blocksize = blocksizeof(RRR)
    j = div(i - 1, blocksize) + 1
    k, r, _ = jthblock(rrr, j)
    bits = E[K[k+1]+r+1] << (16 - blocksize)
    return bitat(Uint16, bits, rem(i - 1, blocksize) + 1)
end

function rank1(rrr::RRR, i::Integer)
    if !(0 ≤ i ≤ endof(rrr))
        throw(BoundsError())
    end
    blocksize = blocksizeof(RRR)
    j, rem = divrem(i - 1, blocksize)
    k, r, rank = jthblock(rrr, j + 1)
    bits = E[K[k+1]+r+1] << (16 - blocksize)
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


# RRR of Navarro and Providel
# the block size is 63 and the block is decoded on the fly.
type RRRNP <: AbstractIndexedBitVector
    ks::Vector{Uint8}
    rs::Vector{Uint64}
    superblocks::Vector{SuperBlock}
    len::Uint32
end

blocksizeof(::Type{RRRNP}) = 63
empty_rs(::Type{RRRNP}) = Uint64[]

# 3 elements of ks store 4 classes
# ks:      |........|........|........|  8bits for each
# classes: |......       .... ..      |  6bits for each
#          |      .. ....       ......|

RRRNP() = RRRNP(Uint8[], Uint64[], SuperBlock[], 0)
RRRNP(src::Union(BitVector,Vector)) = make_rrr(RRRNP, src)

function convert(::Type{RRRNP}, src::Union(BitVector,Vector))
    return RRRNP(src)
end

length(rrr::RRRNP) = rrr.len
endof(rrr::RRRNP) = rrr.len

function getindex(rrr::RRRNP, i::Integer)
    if !(1 ≤ i ≤ endof(rrr))
        throw(BoundsError())
    end
    blocksize = blocksizeof(RRRNP)
    j = div(i - 1, blocksize) + 1
    k, r, _ = jthblock(rrr, j)
    bits = rindex2bits(r, blocksize, convert(Int, k)) << (64 - blocksize)
    return bitat(Uint64, bits, rem(i - 1, blocksize) + 1)
end

function rank1(rrr::RRRNP, i::Integer)
    if !(0 ≤ i ≤ endof(rrr))
        throw(BoundsError())
    end
    blocksize = blocksizeof(RRRNP)
    j, rem = divrem(i - 1, blocksize)
    k, r, rank = jthblock(rrr, j + 1)
    bits = rindex2bits(r, blocksize, convert(Int, k)) << (64 - blocksize)
    rank += count_ones(bits & lmask(Uint64, rem + 1))
    return convert(Int, rank)
end

function classof(rrr::RRRNP, j::Int)
    ki, rem = divrem(j - 1, 4)
    # NOTE: convert(Uint8, ...) is not needed in v0.4
    @switch rem begin
        @case 0
            k = rrr.ks[3ki+1] >> 2
            break
        @case 1
            k1 = (rmask(Uint8, 2) & rrr.ks[3ki+1]) << 4
            k2 = rrr.ks[3ki+2] >> 4
            k = convert(Uint8, k1 + k2)
            break
        @case 2
            k1 = (rmask(Uint8, 4) & rrr.ks[3ki+2]) << 2
            k2 = rrr.ks[3ki+3] >> 6
            k = convert(Uint8, k1 + k2)
            break
        @default  # @case 3
            k = rrr.ks[3ki+3] & rmask(Uint8, 6)
            break
    end
    return k
end

function make_rrr{T<:Union(RRR,RRRNP)}(::Type{T}, src::Union(BitVector,Vector))
    len = length(src)
    blocksize = blocksizeof(T)
    n_blocks = div(len - 1, blocksize) + 1
    ks = Uint8[]
    rs = empty_rs(T)
    superblocks = SuperBlock[]
    rs_el_bits = bitsof(eltype(rs))
    rank = 0
    n_rembits = 0  # the number of remaining bits in rs
    for i in 1:n_blocks
        # sample superblock
        if i % superblock_sampling_rate == 1
            push!(superblocks, SuperBlock(rank, sizeof(rs) * 8 - n_rembits + 1))
        end

        # bits, class and r-index
        bits = packbits(src, (i - 1) * blocksize + 1, blocksize)
        k = count_ones(bits)
        r = bits2rindex(bits, blocksize, k)
        @assert 0 ≤ k ≤ blocksize
        @assert 0 ≤ r < Comb[blocksize,k]
        rank += k

        # store the class to ks
        if T === RRR
            if isodd(i)
                # use upper 4 bits: here----
                push!(ks, k << 4)
            else
                # use lower 4 bits: ----here
                ks[end] |= k
            end
        elseif T === RRRNP
            if i % 4 == 1
                push!(ks, 0, 0, 0)
            end
            @switch i % 4 begin
                @case 1
                    ks[end-2] |= k << 2
                    break
                @case 2
                    ks[end-2] |= k >> 4
                    ks[end-1] |= k << 4
                    break
                @case 3
                    ks[end-1] |= k >> 2
                    ks[end]   |= k << 6
                    break
                @default  # @case 0
                    ks[end]   |= k
                    break
            end
        else
            error()
        end

        # store the r-index to rs
        if isempty(rs)
            push!(rs, 0)
            n_rembits += rs_el_bits
        end
        # the number of bits required to store r-index
        n_rbits = nbits(blocksize, k)
        @assert n_rbits ≤ rs_el_bits
        if n_rembits ≥ n_rbits
            # this r-index can be stored in the last element
            rs[end] |= r << (n_rembits - n_rbits)
        else
            # this r-index spans the two last elements
            rs[end] |= r >> (n_rbits - n_rembits)
            push!(rs, 0)
            rs[end] |= r << (rs_el_bits - (n_rbits - n_rembits))
            n_rembits += rs_el_bits
        end
        n_rembits -= n_rbits
    end
    return T(ks, rs, superblocks, len)
end

# Compute the class and r-index of the j-th block, and
# the rank value at the beginning of the j-th block
function jthblock(rrr::Union(RRR,RRRNP), j::Int)
    @assert 1 ≤ j
    i = div(j - 1, superblock_sampling_rate)
    superblock = rrr.superblocks[i+1]
    blocksize = blocksizeof(typeof(rrr))
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
function read_rindex{T<:Unsigned}(rs::Vector{T}, offset::Int, len::Int)
    w = bitsof(T)
    ri, rem = divrem(offset - 1, w)
    if w - rem ≥ len
        # stored in an element (T = Uint16, w = 16)
        # |      ri+1      |      ri+2      |
        # |................|................|
        # |    xxxxxx      |                |
        #----->|offset
        # |<->|rem
        #      |<-->|len
        @inbounds r = rs[ri+1] & rmask(T, w - rem)
        r >>= w - (rem + len)
    else
        # spans two elements (T = Uint16, w = 16)
        # |      ri+1      |      ri+2      |
        # |................|................|
        # |          xxxxxx|xxxx            |
        #----------->|offset
        # |<------->|rem
        #            |<---- -->|len
        # |<--------------- -->|rem+len
        @inbounds r1 = rs[ri+1] & rmask(T, w - rem)
        r1 <<= rem + len - w
        @inbounds r2 = rs[ri+2] & lmask(T, rem + len - w)
        r2 >>= 2w - (rem + len)
        r = convert(T, r1 + r2)
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
            r += Comb[t-1,k]
            k -= 1
        end
        i += 1
        t -= 1
    end
    return r
end

# Inverse transformation of bits2rindex (decoding).
function rindex2bits(r::Int, t::Int, k::Int)
    @assert 0 ≤ r < Comb[t,k]
    @assert 0 ≤ k ≤ t ≤ 64
    bits = zero(Uint64)
    while r > 0
        if r ≥ Comb[t-1,k]
            # the first bit is 1
            bits |= 1 << (t - 1)
            r -= Comb[t-1,k]
            k -= 1
        end
        t -= 1
    end
    bits |= typemax(Uint64) >>> (64 - k)
    return bits
end

# Look-up Tables
# --------------

immutable CombinationTable
    table::Matrix{Int}
end

getindex(comb::CombinationTable, t::Int, k::Int) = comb.table[t+1,k+1]

const Comb = CombinationTable([binomial(t, k) for t in 0:63, k in 0:63])

# enumeration of bit patterns for blocks, sorted by class and r-index
const E, K = let
    t = blocksizeof(RRR) + 1
    bitss = Uint16[]
    offsets = Int[]
    for k in 0:t
        push!(offsets, length(bitss))
        for r in 0:Comb[t,k]-1
            bits = rindex2bits(r, t, k)
            push!(bitss, bits)
        end
    end
    bitss, offsets
end

# Lookup table to know the number of bits to encode class k's r-index with length t
const NBits = [t ≥ k ? ceil(Int, log2(Comb[t,k])) : 0 for t in 1:63, k in 0:63]

function nbits(t, k)
    return NBits[t,k+1]
end

# assume 1 byte = 8 bits
bitsof{T<:Unsigned}(::Type{T}) = sizeof(T) * 8
