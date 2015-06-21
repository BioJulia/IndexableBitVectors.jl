# SucVector
# ---------
#
# Almost the same as CompactBitVector, but the layout of data is different.
# Four chunks of bits are stored in a block and blocks are stored in a vector.
# As a result, all data are interleaved and thus the CPU cache may be used
# efficiently.  The idea is taken from:
# https://github.com/herumi/cybozulib/blob/master/include/cybozu/sucvector.hpp
# Note that in v0.3 the blocks will not be packed in a vector.

immutable Block
    # bit chunks (64bits × 4 = 256bits)
    chunks::NTuple{4,Uint64}
    # large block
    large::Uint32
    # 8-bit extension of the large block (32 + 8 = 40 bits in total)
    ext::Uint8
    # small blocks
    smalls::NTuple{3,Uint8}
end

const bits_per_chunk =  64
const bits_per_block = 256

function Block(chunks::NTuple{4,Uint64}, offset::Int)
    @assert offset ≤ 2^40 - 1
    a =     convert(Uint8, count_ones(chunks[1]))
    b = a + convert(Uint8, count_ones(chunks[2]))
    c = b + convert(Uint8, count_ones(chunks[3]))
    Block(chunks, offset, offset >>> 32, (a, b, c))
end

type SucVector <: AbstractIndexableBitVector
    blocks::Vector{Block}
    len::Int
end

SucVector() = SucVector(Block[], 0)

function SucVector(src::Union(BitVector,Vector{Bool}))
    len = length(src)
    n_blocks = div(len, bits_per_block) + 1
    blocks = Array(Block, n_blocks)
    offset = 0
    for i in 1:n_blocks
        chunks = read_4chunks(src, (i - 1) * bits_per_block + 1)
        blocks[i] = Block(chunks, offset)
        for j in 1:4
            offset += count_ones(chunks[j])
        end
    end
    return SucVector(blocks, len)
end

function read_chunk(src, from::Int)
    # read a 64-bit chunk from a bitvector
    chunk = zero(Uint64)
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

function convert(::Type{SucVector}, v::Union(BitVector,Vector{Bool}))
    return SucVector(v)
end

Base.length(v::SucVector) = v.len

function getindex(v::SucVector, i::Integer)
    if !(1 ≤ i ≤ endof(v))
        throw(BoundsError())
    end
    return unsafe_getindex(v, i)
end

function unsafe_getindex(v::SucVector, i::Integer)
    q, r = divrem(i - 1, bits_per_block)
    block = v.blocks[q+1]
    q, r = divrem(r, bits_per_chunk)
    chunk = block.chunks[q+1]
    return bitat(chunk, r + 1)
end

function rank1(v::SucVector, i::Integer)
    if !(0 ≤ i ≤ endof(v))
        throw(BoundsError())
    end
    return unsafe_rank1(v, i)
end

function unsafe_rank1(v::SucVector, i::Integer)
    q, r = divrem(i - 1, bits_per_block)
    @inbounds block = v.blocks[q+1]
    ret = 0
    # large block
    ret += block.ext << 32 + convert(Int64, block.large)
    # small block
    q, r = divrem(r, bits_per_chunk)
    if q > 0
        @inbounds ret += block.smalls[q]
    end
    # remaining bits
    @inbounds chunk = block.chunks[q+1]
    ret += count_ones(chunk & lmask(Uint64, r + 1))
    return ret
end
