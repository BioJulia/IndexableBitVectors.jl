# BitVector
# ---------

# This is slow, but simple and hence valuable as a reference implementation.

function rank(x::Integer, b::BitVector, i::Int)
    return x == 0 ? rank0(b, i) : rank1(b, i)
end

function rank0(b::BitVector, i::Int)
    return i - rank1(b, i)
end

function rank1(b::BitVector, i::Int)
    n = 0
    for i′ in 1:i
        n += b[i′]
    end
    return n
end

function select(x::Integer, b::BitVector, j::Int)
    i = 0
    j′ = 0
    while j′ < j && i < endof(b)
        i += 1
        if x == b[i]
            j′ += 1
        end
    end
    return ifelse(j′ == j, i, NotFound)
end

select0(b::BitVector, j::Int) = select(0, b, j)
select1(b::BitVector, j::Int) = select(1, b, j)
