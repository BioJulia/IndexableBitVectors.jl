# Required method
# * rank1(bv, i)     - the number of 1s' occurrences within bv[1:i]

# the following methods are derived from the rank1 method

#function getindex(b::AbstractBitVector, i::Int)
#    if i == 0
#        return 0
#    end
#    return rank(b, i) - rank(b, i - 1)
#end

function rank0(b::AbstractBitVector, i::Integer)
    return i - rank1(b, i)
end

function rank(x::Integer, b::AbstractBitVector, i::Integer)
    return x == 0 ? rank0(b, i) : rank1(b, i)
end

function select0(b::AbstractBitVector, i::Integer)
    return select(0, b, i)
end

function select1(b::AbstractBitVector, i::Integer)
    return select(1, b, i)
end

function select(x::Integer, b::AbstractBitVector, i::Integer)
    lo = 0
    hi = endof(b)
    if i == 0 || rank(x, b, hi) < i
        return 0
    end
    # binary search
    while lo < hi
        mi = div(lo + hi, 2)
        if rank(x, b, mi) >= i
            hi = mi
        else
            # rank(mi) < i
            lo = mi + 1
        end
    end
    return lo
end

# estimation of the space in bytes
function sizeof(v::AbstractIndexableBitVector)
    size = 0
    for name in names(v)
        size += sizeof(v.(name))
        if !isbits(typeof(v.(name)))
            # word size in bytes
            size += sizeof(Int)
        end
    end
    return size
end

# Internal BitVecor
# This mimics the behaviour of Base.BitVector. We could use
# the Base.BitVecor, but we have to touch the internal members
# for efficiency hence I re-implemented this data type.
type IBitVector
    chunks::Vector{Uint64}
    len::Int
end

length(v::IBitVector) = v.len

function push!(v::IBitVector, bit::Bool)
    r = rem(v.len, 64)
    if r == 0
        push!(v.chunks, zero(Uint64))
    end
    if bit
        v.chunks[end] |= one(Uint64) << (63 - r)
    end
    v.len += 1
    return v
end

function getindex(v::IBitVector, i::Int)
    if !(1 ≤ i ≤ v.len)
        error(BoundsError())
    end
    q, r = divrem(i - 1, 64)
    return bitat(v.chunks[q+1], r + 1)
end

bitat(chunk::Uint64, i::Int) = (chunk >>> (64 - i)) & 0x01 == 0x01
bitat{T<:Unsigned}(::Type{T}, chunk::T, i::Int) = (chunk >>> (sizeof(T) * 8 - i)) & 1 == 1
