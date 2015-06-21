# estimation of the space in bytes
function sizeof(v::AbstractIndexableBitVector)
    size = 0
    for name in fieldnames(v)
        size += sizeof(v.(name))
        if !isbits(typeof(v.(name)))
            # word size in bytes
            size += sizeof(Int)
        end
    end
    return size
end

# return the i-th bit
bitat(chunk::Uint64, i::Int) = (chunk >>> (64 - i)) & 0x01 == 0x01
bitat{T<:Unsigned}(::Type{T}, chunk::T, i::Int) = (chunk >>> (sizeof(T) * 8 - i)) & 1 == 1

# assume 1 byte = 8 bits
bitsof{T<:Unsigned}(::Type{T}) = sizeof(T) * 8

# make a bit mask
lmask{T<:Unsigned}(typ::Type{T}, n::Int) = typemax(typ) << (bitsof(typ) - n)
rmask{T<:Unsigned}(typ::Type{T}, n::Int) = typemax(typ) >> (bitsof(typ) - n)
