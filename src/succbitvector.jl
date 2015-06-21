# simple succinct bit vector
# --------------------------

# Classical indexable bit vector implementation with 1/4 bits/bit additional space.
# Exactly speaking, this data structure is not succinct: Θ(n) additional space is required rather than o(n).
# But in practice, this is almost the same as theoretically optimal additional space and efficient in actual
# computers.

# Bitvector with cached rank values in two types of blocks (large blocks and small blocks).
type SuccinctBitVector <: AbstractIndexableBitVector
    # data
    bits::BitVector
    # large blocks
    lbs::Vector{Uint32}
    # small blocks
    sbs::Vector{Uint8}
end

function SuccinctBitVector()
    return SuccinctBitVector(convert(BitVector, Bool[]), Uint32[], Uint8[])
end

function SuccinctBitVector(v::Union(BitVector,Vector))
    sv = SuccinctBitVector()
    for bit in v
        push!(sv, bit != 0)
    end
    return sv
end

#function convert{T<:Integer}(::Type{SuccinctBitVector}, v::Union(BitVector,Vector{T}))
function convert(::Type{SuccinctBitVector}, v::Union(BitVector,Vector))
    return SuccinctBitVector(v)
end

function show(io::IO, v::SuccinctBitVector)
    write(io, "SuccinctBitVector(bits=[...],")
    write(io, "large_blocks=$(v.lbs),")
    write(io, "small_blocks=$(v.sbs))")
end

immutable LargeBlock end
immutable SmallBlock end

size(::Type{SmallBlock}) =  64
size(::Type{LargeBlock}) = 256
const n_smallblocks_per_largeblock = div(size(LargeBlock), size(SmallBlock))

function push!(v::SuccinctBitVector, bit::Bool)
    if length(v) + 1 > typemax(Uint32)
        error("overflow")
    end
    # expand blocks if necessary
    if expand!(v, SmallBlock)
        k = rem(length(v.sbs), n_smallblocks_per_largeblock)
        if k == 1
            # the first small block within the current large block; this is always zero
            v.sbs[end] = 0
        else
            v.sbs[end] = v.sbs[end-1] + count_ones(v.bits.chunks[end])
        end
    end
    if expand!(v, LargeBlock)
        # note that if large blocks are expanded, small blocks are expanded, too
        if length(v.lbs) == 1
            # the first large block is always filled with zero
            v.lbs[end] = 0
        else
            prevrank = v.lbs[end-1] + v.sbs[end-1]
            v.lbs[end] = prevrank + count_ones(v.bits.chunks[end])
        end
    end
    push!(v.bits, bit)
    return v
end
push!(v::SuccinctBitVector, b::Integer) = push!(v::SuccinctBitVector, b != 0)

length(v::SuccinctBitVector) = length(v.bits)
endof(v::SuccinctBitVector)  = length(v.bits)

getindex(v::SuccinctBitVector, i::Int) = v.bits[i]

function rank1(v::SuccinctBitVector, i::Int)
    if i == 0
        return 0
    elseif i > length(v)
        throw(BoundsError())
    end
    lbi = div(i - 1, size(LargeBlock))
    sbi = div(i - 1, size(SmallBlock))
    @inbounds byte = v.bits.chunks[sbi+1]
    r = rem(i, 64)
    if r != 0
        byte &= ~(typemax(Uint64) << r)
    end
    @inbounds ret = v.lbs[lbi+1] + v.sbs[sbi+1] + count_ones(byte)
    return convert(Int, ret)
end

# expand blocks to store 1 more bit if necessaary
function expand!(v::SuccinctBitVector, ::Type{LargeBlock})
    nbits = length(v)
    if rem(nbits, size(LargeBlock)) == 0
        push!(v.lbs, 0)
        return true
    end
    return false
end

function expand!(v::SuccinctBitVector, ::Type{SmallBlock})
    nbits = length(v)
    if rem(nbits, size(SmallBlock)) == 0
        push!(v.sbs, 0)
        return true
    end
    return false
end
