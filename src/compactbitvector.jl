# compact bit vector
# ------------------

# Classical indexable bit vector implementation with 1/4 bits per bit additional
# space.  Exactly speaking, this data structure is not succinct: n/4 (= Θ(n))
# additional space is required rather than o(n).  But in practice, this is
# almost the same as theoretically optimal additional space and efficient in
# actual computers.
#
# A compact bit vector has two types of blocks: large blocks and small blocks.
# Four small blocks are associated to a large block. Large blocks hold the rank
# value at the beginning of the block while small blocks hold the offset of the
# rank value from a large block the small block belongs to. If we naively store
# the offset values of small blocks, the first small blocks for each large block
# is always filled with zero. To expand the maximum length of a bit vector, we
# exploit these small blocks: the rank value at the beginning of a large block
# is smallblock[1] << 32 + largeblock. As a result, about 2^(8 + 32) = 2^40 bits
# = 128 GiB can be stored in a compact bit vector.
#
# Data Layout
# bits: ..|................|................|................|................|..
# sbs:    |  smallblock 1  |  smallblock 2  |  smallblock 3  |  smallblock 4  |
# lbs:    |                            large block                            |

type CompactBitVector <: AbstractIndexableBitVector
    # data
    bits::BitVector
    # large blocks
    lbs::Vector{Uint32}
    # small blocks
    sbs::Vector{Uint8}
end

maxlength(::Type{CompactBitVector}) = 2^40 - 1

function CompactBitVector()
    return CompactBitVector(convert(BitVector, Bool[]), Uint32[], Uint8[])
end

function CompactBitVector(v::Union(BitVector,Vector{Bool}))
    sv = CompactBitVector()
    for bit in v
        push!(sv, bit != 0)
    end
    return sv
end

function convert(::Type{CompactBitVector}, v::Union(BitVector,Vector{Bool}))
    return CompactBitVector(v)
end

function show(io::IO, v::CompactBitVector)
    write(io, "CompactBitVector(bits=[...],")
    write(io, "large_blocks=$(v.lbs),")
    write(io, "small_blocks=$(v.sbs))")
end

immutable LargeBlock end
immutable SmallBlock end

size(::Type{SmallBlock}) =  64
size(::Type{LargeBlock}) = 256
const n_smallblocks_per_largeblock = div(size(LargeBlock), size(SmallBlock))

function push!(v::CompactBitVector, bit::Bool)
    len = length(v) + 1
    if len > maxlength(CompactBitVector)
        error("overflow")
    end
    ensureroom!(v, len)
    if len % size(LargeBlock) == 1 && length(v.lbs) > 1
        # the first bit of a large block
        rank  = convert(Int, v.lbs[end-1])
        rank += v.sbs[end-1]
        rank += count_ones(v.bits.chunks[end])
        v.lbs[end] = rank & typemax(Uint32)
        v.sbs[end] = rank >> bitsof(Uint32)
    elseif len % size(SmallBlock) == 1 && length(v.sbs) > 1
        # the first bit of a small block
        v.sbs[end] = v.sbs[end-1] + count_ones(v.bits.chunks[end])
    end
    push!(v.bits, bit)
    return v
end
push!(v::CompactBitVector, b::Integer) = push!(v::CompactBitVector, b != 0)

length(v::CompactBitVector) = length(v.bits)
endof(v::CompactBitVector)  = length(v.bits)

getindex(v::CompactBitVector, i::Integer) = v.bits[i]

function rank1(v::CompactBitVector, i::Integer)
    if !(0 ≤ i ≤ endof(v))
        throw(BoundsError())
    end
    return unsafe_rank1(v, i)
end

function unsafe_rank1(v::CompactBitVector, i::Integer)
    if i == 0
        return 0
    end
    lbi = div(i - 1, size(LargeBlock)) + 1
    sbi = div(i - 1, size(SmallBlock)) + 1
    @inbounds byte = v.bits.chunks[sbi]
    r = rem(i, 64)
    if r != 0
        byte &= rmask(Uint64, r)
    end
    @inbounds ret = (
          convert(Int, v.sbs[sbi-rem(sbi, n_smallblocks_per_largeblock)+1]) << bitsof(Uint32)
        + v.lbs[lbi]
        + v.sbs[sbi]
        + count_ones(byte)
    )
    return ret
end

# ensure room to store `len` bits
function ensureroom!(v::CompactBitVector, len::Int)
    @assert len ≥ length(v)
    n_required_sbs = div(len - 1, size(SmallBlock)) + 1
    if n_required_sbs ≤ length(v.sbs)
        # enough space to hold `len` bits
        return v
    end
    len_sbs = length(v.sbs)
    len_lbs = length(v.lbs)
    resize!(v.sbs, n_required_sbs)
    resize!(v.lbs, div(n_required_sbs - 1, 4) + 1)
    for i in len_sbs+1:endof(v.sbs) v.sbs[i] = 0 end
    for i in len_lbs+1:endof(v.lbs) v.lbs[i] = 0 end
    @assert length(v.sbs) ≤ length(v.lbs) * n_smallblocks_per_largeblock
    return v
end
