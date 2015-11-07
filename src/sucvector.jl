# SucVector
# ---------
#
# Almost the same as CompactBitVector, but the layout of data is different.
# Four chunks of 64 bits are stored in a block and blocks are stored in a vector.
# As a result, all data are interleaved and thus the CPU cache may be used
# efficiently.  The idea is taken from:
# https://github.com/herumi/cybozulib/blob/master/include/cybozu/sucvector.hpp
# Note that in v0.3 blocks will not be packed in a vector.

immutable Block
    # large block
    large::UInt32
    # small blocks
    #   the first small block is used for 8-bit extension of the large block
    #   hence, 40 (= 32 + 8) bits are available in total
    smalls::NTuple{4,UInt8}
    # bit chunks (64bits × 4 = 256bits)
    chunks::NTuple{4,UInt64}
end

const bits_per_chunk =  64
const bits_per_block = 256

function Block(chunks::NTuple{4,UInt64}, offset::Int)
    a =     convert(UInt8, count_ones(chunks[1]))
    b = a + convert(UInt8, count_ones(chunks[2]))
    c = b + convert(UInt8, count_ones(chunks[3]))
    Block(offset & ~UInt32(0), (offset >>> 32, a, b, c), chunks)
end

@inline function block_id(i)
    j = Int(i - 1)
    (j >>> 8) + 1, (j & 0b11111111) + 1
end

@inline function chunk_id(i)
    j = Int(i - 1)
    (j >>> 6) + 1, (j & 0b00111111) + 1
end

"""
Static indexable bit vector.

`SucVector` requires 5/4 bits per bit in order to keep bits and the number of bits
(i.e. a `SucVector` object becomes ~25% bigger when converted from a `BitVector` object).
Bits are split into blocks: four chunks of 64 bits are stored in a block and blocks are stored in a vector.
Blocks are contiguous in momery so that memory cache works efficiently.

The number of bits is limited up to 2^40 bits. This is 128GiB so would be enough in most cases.

Let `n` be the length of a `SucVector`, the asymptotic query times are

* getindex: `O(1)`
* rank: `O(1)`
* select: `O(log n)`
"""
type SucVector <: AbstractIndexableBitVector
    blocks::Vector{Block}
    len::Int
end

SucVector() = SucVector(Block[], 0)

# data size of payload in bytes
sizeof(bv::SucVector) = sizeof(bv.blocks)

function convert(::Type{SucVector}, vec::AbstractVector{Bool})
    len = length(vec)
    @assert len ≤ 2^40
    n_blocks = cld(len, bits_per_block)
    blocks = Vector{Block}(n_blocks)
    offset = 0
    for i in 1:n_blocks
        chunks = read_4chunks(vec, (i - 1) * bits_per_block + 1)
        blocks[i] = Block(chunks, offset)
        for j in 1:4
            offset += count_ones(chunks[j])
        end
    end
    return SucVector(blocks, len)
end

function read_chunk(src, from::Int)
    @assert bits_per_chunk == sizeof(UInt64) * 8
    chunk = UInt64(0)
    for k in 0:bits_per_chunk-1
        i = from + k
        chunk >>= 1
        if i ≤ endof(src) && src[i]
            chunk |= UInt64(1) << 63
        end
    end
    return chunk
end

function read_4chunks(src::AbstractVector{Bool}, from::Int)
    a = read_chunk(src, from)
    b = read_chunk(src, from + bits_per_chunk * 1)
    c = read_chunk(src, from + bits_per_chunk * 2)
    d = read_chunk(src, from + bits_per_chunk * 3)
    return a, b, c, d
end

function read_4chunks(src::BitVector, from::Int)
    @assert rem(from, bits_per_block) == 1
    # NOTE: this method depends on the internal data layout of BitVector
    # (but much faster).
    if length(src) >= from + bits_per_block - 1
        i = div(from - 1, bits_per_chunk) + 1
        a = src.chunks[i]
        b = src.chunks[i+1]
        c = src.chunks[i+2]
        d = src.chunks[i+3]
    else
        a = read_chunk(src, from)
        b = read_chunk(src, from + bits_per_chunk * 1)
        c = read_chunk(src, from + bits_per_chunk * 2)
        d = read_chunk(src, from + bits_per_chunk * 3)
    end
    return a, b, c, d
end

length(v::SucVector) = v.len

@inline function getindex(v::SucVector, i::Integer)
    checkbounds(v, i)
    return unsafe_getindex(v, i)
end

@inline function unsafe_getindex(v::SucVector, i::Integer)
    q, r = block_id(i)
    @inbounds block = v.blocks[q]
    q, r = chunk_id(r)
    @inbounds chunk = block.chunks[q]
    return (chunk >> (r - 1)) & 1 == 1
end

@inline function rank1(bv::SucVector, i::Int)
    i = clamp(i, 0, bv.len)
    if i == 0
        return 0
    end
    q, r = block_id(i)
    @inbounds begin
        block = bv.blocks[q]
        # large block
        ret = Int(block.large) + Int(block.smalls[1]) << 32
        # small block
        q, r = chunk_id(r)
        ret += ifelse(q == 1, 0x00, block.smalls[q])
        # remaining bits
        chunk = block.chunks[q]
    end
    ret += count_ones(chunk & rmask(UInt64, r))
    return ret
end

@inline rank1(bv::SucVector, i::Integer) = rank1(bv, Int(i))

# run getindex and rank1 in one shot
function accrank1(bv::SucVector, i)
    q, r = block_id(i)
    @inbounds begin
        block = bv.blocks[q]
        # large block
        rnk1 = Int(block.large) + Int(block.smalls[1]) << 32
        q, r = chunk_id(r)
        # small block
        rnk1 += ifelse(q == 1, 0x00, block.smalls[q])
        chunk = block.chunks[q]
        rnk1 += count_ones(chunk & rmask(UInt64, r))
    end
    return (chunk >> (r - 1)) & 1 == 1, rnk1
end
