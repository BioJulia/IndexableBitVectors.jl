# BitVector
# ---------

# This is slow, but simple and valuable as a reference implementation.

function rank1(b::BitVector, i::Int)
    i = clamp(i, 0, length(b))
    if i == 0
        return 0
    end
    n = 0
    for i′ in 1:i
        n += b[i′]
    end
    return n
end
