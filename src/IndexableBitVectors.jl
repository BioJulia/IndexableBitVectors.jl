module IndexableBitVectors

export
    # types
    AbstractIndexableBitVector, AbstractBitVector,
    SuccinctBitVector, SucVector, CSucVector, RRR, RRRNP,
    # operations
    rank, rank0, rank1, select, select0, select1

import Base: rank, select, show, size, push!, getindex, length, endof, sizeof, convert
using Compat
using Switch

abstract AbstractIndexableBitVector <: DenseArray{Bool,1}
typealias AbstractBitVector Union(BitVector,AbstractIndexableBitVector)

include("common.jl")
include("bitvector.jl")
include("succbitvector.jl")
include("sucvector.jl")
include("csucvector.jl")
include("rrr.jl")

end # module
