# Required method
# * rank1(bv, i)     - the number of 1s' occurrences within bv[1:i]

# the following methods are derived from the rank1 method

function getindex(b::AbstractIndexableBitVector, i::Integer)
    if i == 0
        return 0
    end
    return rank(b, i) - rank(b, i - 1)
end

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
