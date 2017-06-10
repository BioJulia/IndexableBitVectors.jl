# some common functions
# Query operations are located in the derived.jl file.

@compat abstract type AbstractIndexableBitVector <: AbstractVector{Bool} end
const AbstractBitVector = Union{BitVector,AbstractIndexableBitVector}

size(b::AbstractIndexableBitVector) = (length(b),)
