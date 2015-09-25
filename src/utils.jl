# return the i-th bit
@inline bitat(chunk::UInt64, i::Int) = (chunk >>> (64 - i)) & 0x01 == 0x01
@inline bitat{T<:Unsigned}(::Type{T}, chunk::T, i::Int) = (chunk >>> (sizeof(T) * 8 - i)) & 1 == 1

# assume 1 byte = 8 bits
@inline bitsof{T<:Unsigned}(::Type{T}) = sizeof(T) * 8

@inline mod64(i) = i & 63

# make a bit mask
@inline lmask{T<:Unsigned}(typ::Type{T}, n::Int) = typemax(typ) << (bitsof(typ) - n)
@inline rmask{T<:Unsigned}(typ::Type{T}, n::Int) = typemax(typ) >> (bitsof(typ) - n)
