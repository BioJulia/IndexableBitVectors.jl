# some common functions
# Query operations are located in the derived.jl file.

abstract type AbstractIndexableBitVector <: AbstractVector{Bool} end
const AbstractBitVector = Union{BitVector,AbstractIndexableBitVector}

Base.size(b::AbstractIndexableBitVector) = (length(b),)
