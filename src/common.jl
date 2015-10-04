# some common functions
# Query operations are located in the derived.jl file.

abstract AbstractIndexableBitVector <: AbstractVector{Bool}
typealias AbstractBitVector Union{BitVector,AbstractIndexableBitVector}

size(b::AbstractIndexableBitVector) = (length(b),)
