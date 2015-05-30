module IndexableDicts

export
    # types
    AbstractIndexedBitVector, AbstractBitVector,
    SuccinctBitVector,
    # operations
    rank, rank0, rank1, select, select0, select1

import Base: rank, select, show, size, push!, getindex, length, endof, convert

abstract AbstractIndexedBitVector <: DenseArray{Bool,1}
typealias AbstractBitVector Union(BitVector,AbstractIndexedBitVector)

include("common.jl")
include("bitvector.jl")
include("succbitvector.jl")

end # module
