# SucVector
# ---------
#
# Almost the same as CompactBitVector, but the layout of data is different.
# Four chunks of bits are stored in a block and blocks are stored in a vector.
# As a result, all data are Interleaved and thus the CPU cache may be used
# efficiently.  The idea is taken from:
# https://github.com/herumi/cybozulib/blob/master/include/cybozu/sucvector.hpp
# Note that in v0.3 the blocks will not be packed in a vector.

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
    @assert offset ≤ 2^40 - 1
    a =     convert(UInt8, count_ones(chunks[1]))
    b = a + convert(UInt8, count_ones(chunks[2]))
    c = b + convert(UInt8, count_ones(chunks[3]))
    Block(offset, (offset >>> 32, a, b, c), chunks)
end

@inline function block_id(i)
    j = Int(i - 1)
    (j >>> 8) + 1, (j & 0b11111111) + 1
end

@inline function chunk_id(i)
    j = Int(i - 1)
    (j >>> 6) + 1, (j & 0b00111111) + 1
end

type SucVector <: AbstractIndexableBitVector
    blocks::Vector{Block}
    len::Int
end

SucVector() = SucVector(Block[], 0)

function convert(::Type{SucVector}, vec::Union(BitVector,Vector{Bool}))
    len = length(vec)
    n_blocks = div(len, bits_per_block) + 1
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
    # read a 64-bit chunk from a bitvector
    chunk = zero(UInt64)
    for i in from:from+63
        chunk <<= 1
        if i ≤ endof(src)
            chunk += src[i] ≠ 0
        end
    end
    return chunk
end

function read_4chunks(src, from::Int)
    # read four 64-bit chunks from a bitvector at once
    a = read_chunk(src, from)
    b = read_chunk(src, from + 64 * 1)
    c = read_chunk(src, from + 64 * 2)
    d = read_chunk(src, from + 64 * 3)
    (a, b, c, d)
end

Base.length(v::SucVector) = v.len

@inline function getindex(v::SucVector, i::Integer)
    if !(1 ≤ i ≤ endof(v))
        throw(BoundsError())
    end
    return unsafe_getindex(v, i)
end

@inline function unsafe_getindex(v::SucVector, i::Integer)
    q, r = block_id(i)
    @inbounds block = v.blocks[q]
    q, r = chunk_id(r)
    @inbounds chunk = block.chunks[q]
    return bitat(chunk, r)
end

@inline function rank1(v::SucVector, i::Integer)
    if i < 0 || i > endof(v)
        throw(BoundsError())
    end
    return unsafe_rank1(v, i)
end

@inline function unsafe_rank1(v::SucVector, i::Integer)
    if i == 0
        return 0
    end
    q, r = block_id(i)
    @inbounds begin
        block = v.blocks[q]
        # large block
        ret = Int(block.large) + Int(block.smalls[1]) << 32
        # small block
        q, r = chunk_id(r)
        ret += ifelse(q == 1, 0x00, block.smalls[q])
        # remaining bits
        chunk = block.chunks[q]
    end
    ret += count_ones(chunk & lmask(UInt64, r))
    return ret
end
