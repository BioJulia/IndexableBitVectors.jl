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

bitat(chunk::Uint64, i::Int) = (chunk >>> (64 - i)) & 0x01 == 0x01
bitat{T<:Unsigned}(::Type{T}, chunk::T, i::Int) = (chunk >>> (sizeof(T) * 8 - i)) & 1 == 1
