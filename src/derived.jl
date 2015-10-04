# The following methods can be derived from the rank1 method.
#   * rank1(bv, i)     - the number of 1s' occurrences within bv[1:i]

function getindex(b::AbstractIndexableBitVector, i::Integer)
    return rank1(b, i) != rank1(b, i - 1)
end

function rank(x::Integer, b::AbstractBitVector, i::Integer)
    return x == 0 ? rank0(b, i) : rank1(b, i)
end

function rank0(b::AbstractBitVector, i::Integer)
    return clamp(i, 0, length(b)) - rank1(b, i)
end

function select(x::Integer, b::AbstractBitVector, i::Integer)
    lo = 0
    hi = endof(b)
    if i ≤ 0 || rank(x, b, hi) < i
        return 0
    end
    # binary search
    while lo < hi
        mi = div(lo + hi, 2)
        if rank(x, b, mi) >= i
            hi = mi
        else
            lo = mi + 1
        end
    end
    return lo
end

function select0(b::AbstractBitVector, i::Integer)
    return select(0, b, i)
end

function select1(b::AbstractBitVector, i::Integer)
    return select(1, b, i)
end

function search(x::Integer, bv::AbstractBitVector, i::Integer)
    return x == 0 ? search0(bv, i) : search1(bv, i)
end

search0(bv::AbstractBitVector, i::Integer) = select0(bv, rank0(bv, i - 1) + 1)
search1(bv::AbstractBitVector, i::Integer) = select1(bv, rank1(bv, i - 1) + 1)

function rsearch(x::Integer, bv::AbstractBitVector, i::Integer)
    return x == 0 ? rsearch0(bv, i) : rsearch1(bv, i)
end

rsearch0(bv::AbstractBitVector, i::Integer) = select0(bv, rank0(bv, i))
rsearch1(bv::AbstractBitVector, i::Integer) = select1(bv, rank1(bv, i))
