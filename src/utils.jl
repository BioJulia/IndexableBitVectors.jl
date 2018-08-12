# return the i-th bit
@inline bitat(chunk::UInt64, i::Int) = (chunk >>> (64 - i)) & 0x01 == 0x01
@inline bitat(::Type{T}, chunk::T, i::Int) where {T<:Unsigned} = (chunk >>> (sizeof(T) * 8 - i)) & 1 == 1

# assume 1 byte = 8 bits
@inline bitsof(::Type{T}) where {T<:Unsigned} = sizeof(T) * 8

@inline mod64(i) = i & 63

# make a bit mask
@inline lmask(typ::Type{T}, n::Int) where {T<:Unsigned} = typemax(typ) << (bitsof(typ) - n)
@inline rmask(typ::Type{T}, n::Int) where {T<:Unsigned} = typemax(typ) >> (bitsof(typ) - n)
