# BitVector
# ---------

# This is slow, but simple and valuable as a reference implementation.

function rank1(b::BitVector, i::Int)
    n = 0
    for i′ in 1:i
        n += b[i′]
    end
    return n
end
