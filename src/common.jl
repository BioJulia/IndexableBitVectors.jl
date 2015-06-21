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
