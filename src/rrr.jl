# RRR
# ---
#
# Indexable and compressible bit vectors. The compression is based on the
# abandance of 1s (or 0s) in a block. If 1s or 0s are clustered in regions, RRR
# can achieve high compression.  This file implements two variants of the RRR:
# * RRR: RRR of Claude and Navarro (2008)
#   - The block size is 15 bits and the original block is decoded from a universal table.
# * LargeRRR: RRR of Navarro and Providel (2012)
#   - The block size is 63 bits and the original block is decoded on the fly.
#
# Data Layout
# bits:      ..|...............|...............|... ...|...............|..
# blocks:      |   block j+1   |   block j+2   |  ...  |  block j+ssr  |
# superblocks: |                       superblock                      |
#
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

const superblock_sampling_rate = 16  # blocks per superblock

# sampling rate controls the tradeoff between performance and space
immutable SuperBlock
    # partial sum of rank values
    rank::UInt64
    # offset of the starting position of r-index
    offset::UInt64
end

"""
Compressed indexable bit vector.

`RRR` compresses a bit vector in an information-theoretically optimal representation.
This compression is based on local abundance of bits; if 0s or 1s are clustered in a
bit vector, it will be compressed even when the numbers of 0s and 1s are globally equal.

Let `n` be the length of a `RRR`, the asymptotic query times are

* getindex: `O(1)`
* rank: `O(1)`
* select: `O(log n)`

See (Raman et al, 2007, doi:10.1145/1290672.1290680) for more details.
"""
type RRR <: AbstractIndexableBitVector
    # class values for each block
    # class values are encoded in 4 bits, hence `ks` is a packed array of 4-bit elements
    ks::Vector{UInt8}
    # r-indices (or offset) for each block
    # r-index is a variable-length encoding of position in a class. This array is also packed without delimiters.
    rs::Vector{UInt16}
    # sampled blocks
    superblocks::Vector{SuperBlock}
    # length of bits
    len::Int
end

blocksizeof(::Type{RRR}) = 15
empty_rs(::Type{RRR}) = UInt16[]

Base.copy(rrr::RRR) = RRR(copy(rrr.ks), copy(rrr.rs), copy(rrr.superblocks), rrr.len)

RRR() = RRR(UInt8[], UInt8[], SuperBlock[], 0)
convert(::Type{RRR}, vec::AbstractVector{Bool}) = make_rrr(RRR, vec)

length(rrr::RRR) = rrr.len

# data size of payload in bytes
sizeof(rrr::RRR) = sizeof(rrr.ks) + sizeof(rrr.rs) + sizeof(rrr.superblocks)

function getindex(rrr::RRR, i::Integer)
    checkbounds(rrr, i)
    blocksize = blocksizeof(RRR)
    j = div(i - 1, blocksize) + 1
    k, r, _ = jthblock(rrr, j)
    bits = E[K[k+1]+r+1] << (16 - blocksize)
    return bitat(UInt16, bits, rem(i - 1, blocksize) + 1)
end

function rank1(rrr::RRR, i::Int)
    i = clamp(i, 0, rrr.len)
    if i == 0
        return 0
    end
    blocksize = blocksizeof(RRR)
    j, rem = divrem(i - 1, blocksize)
    k, r, rank = jthblock(rrr, j + 1)
    bits = E[K[k+1]+r+1] << (16 - blocksize)
    rank += count_ones(bits & lmask(UInt16, rem + 1))
    return convert(Int, rank)
end

rank1(rrr::RRR, i::Integer) = rank1(rrr, Int(i))

# return the class of j-th block
@inline function classof(rrr::RRR, j::Int)
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
type LargeRRR <: AbstractIndexableBitVector
    ks::Vector{UInt8}
    rs::Vector{UInt64}
    superblocks::Vector{SuperBlock}
    len::Int
end

blocksizeof(::Type{LargeRRR}) = 63
empty_rs(::Type{LargeRRR}) = UInt64[]

Base.copy(rrr::LargeRRR) = LargeRRR(
    copy(rrr.ks), copy(rrr.rs), copy(rrr.superblocks), rrr.len)

# 3 elements of ks store 4 classes
# ks:      |........|........|........|  8bits for each
# classes: |......       .... ..      |  6bits for each
#          |      .. ....       ......|

LargeRRR() = LargeRRR(UInt8[], UInt64[], SuperBlock[], 0)
convert(::Type{LargeRRR}, vec::Union{BitVector,Vector{Bool}}) = make_rrr(LargeRRR, vec)

length(rrr::LargeRRR) = rrr.len

function getindex(rrr::LargeRRR, i::Integer)
    checkbounds(rrr, i)
    blocksize = blocksizeof(LargeRRR)
    j = div(i - 1, blocksize) + 1
    k, r, _ = jthblock(rrr, j)
    bits = rindex2bits(r, blocksize, convert(Int, k)) << (64 - blocksize)
    return bitat(UInt64, bits, rem(i - 1, blocksize) + 1)
end

function rank1(rrr::LargeRRR, i::Integer)
    i = clamp(i, 0, rrr.len)
    if i == 0
        return 0
    end
    blocksize = blocksizeof(LargeRRR)
    j, rem = divrem(i - 1, blocksize)
    k, r, rank = jthblock(rrr, j + 1)
    bits = rindex2bits(r, blocksize, convert(Int, k)) << (64 - blocksize)
    rank += count_ones(bits & lmask(UInt64, rem + 1))
    return convert(Int, rank)
end

function classof(rrr::LargeRRR, j::Int)
    ki, rem = divrem(j - 1, 4)
    if rem == 0
        k = rrr.ks[3ki+1] >> 2
    elseif rem == 1
        k1 = (rmask(UInt8, 2) & rrr.ks[3ki+1]) << 4
        k2 = rrr.ks[3ki+2] >> 4
        k = convert(UInt8, k1 + k2)
    elseif rem == 2
        k1 = (rmask(UInt8, 4) & rrr.ks[3ki+2]) << 2
        k2 = rrr.ks[3ki+3] >> 6
        k = convert(UInt8, k1 + k2)
    else  # rem == 3
        k = rrr.ks[3ki+3] & rmask(UInt8, 6)
    end
    return k
end

function make_rrr{T<:Union{RRR,LargeRRR}}(::Type{T}, src::AbstractVector{Bool})
    len = length(src)
    if len > typemax(Int)
        error("the bit vector is too large")
    end
    blocksize = blocksizeof(T)
    n_blocks = div(len - 1, blocksize) + 1
    ks = UInt8[]
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

        # bits and class
        bits = read_bits(src, (i - 1) * blocksize + 1, blocksize)
        k = convert(eltype(ks), count_ones(bits))
        @assert 0 ≤ k ≤ blocksize
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
        elseif T === LargeRRR
            rem = i % 4
            if rem == 1
                push!(ks, 0, 0, 0)
                ks[end-2] |= k << 2
            elseif rem == 2
                ks[end-2] |= k >> 4
                ks[end-1] |= k << 4
            elseif rem == 3
                ks[end-1] |= k >> 2
                ks[end]   |= k << 6
            else  # rem == 4
                ks[end]   |= k
            end
        else
            error()
        end

        # store the r-index to rs
        r = convert(eltype(rs), bits2rindex(bits, blocksize, k))
        @assert 0 ≤ r < Comb[blocksize,k]
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
function jthblock(rrr::Union{RRR,LargeRRR}, j::Int)
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

# return left-aligned bits
function read_bits(src, from, len)
    @assert 1 ≤ len ≤ 64
    bits = zero(UInt64)
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
        # stored in an element (T = UInt16, w = 16)
        # |      ri+1      |      ri+2      |
        # |................|................|
        # |    xxxxxx      |                |
        #----->|offset
        # |<->|rem
        #      |<-->|len
        @inbounds r = rs[ri+1] & rmask(T, w - rem)
        r >>= w - (rem + len)
    else
        # spans two elements (T = UInt16, w = 16)
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
function bits2rindex(bits::UInt64, t::Int, k::Integer)
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
function rindex2bits(r::Int, t::Int, k::Integer)
    @assert 0 ≤ r < Comb[t,k]
    @assert 0 ≤ k ≤ t ≤ 64
    bits = zero(UInt64)
    @inbounds while r > 0
        c = Comb[t-1,k]
        if r ≥ c
            # the first bit is 1
            bits |= 1 << (t - 1)
            r -= c
            k -= 1
        end
        t -= 1
    end
    bits |= typemax(UInt64) >>> (64 - k)
    return bits
end

# Look-up Tables
# --------------

immutable CombinationTable
    table::Matrix{Int}
end

@inline function getindex(comb::CombinationTable, t::Int, k::Integer)
    @inbounds c = comb.table[t+1,k+1]
    return c
end

@assert blocksizeof(RRR) ≤ blocksizeof(LargeRRR)

const Comb = CombinationTable([binomial(t, k) for t in 0:blocksizeof(LargeRRR), k in 0:blocksizeof(LargeRRR)])

# enumeration of bit patterns for blocks, sorted by class and r-index
const E, K = let
    t = blocksizeof(RRR) + 1
    bitss = UInt16[]
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

# Lookup table to know the number of bits to encode class k's r-indices with blocksize t
const NBitsTable = [t ≥ k ? ceil(Int, log2(Comb[t,k])) : 0 for t in 1:blocksizeof(LargeRRR), k in 0:blocksizeof(LargeRRR)]

function nbits(t, k)
    return NBitsTable[t,k+1]
end
