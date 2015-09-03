isdefined(Base, :__precompile__) && __precompile__()

module IndexableBitVectors

export
    # types
    AbstractBitVector,
    AbstractIndexableBitVector,
    SucVector,
    RRR,
    # query operations
    rank,
    rank0,
    rank1,
    select,
    select0,
    select1

import Base:
    rank,
    select,
    push!,
    getindex,
    length,
    endof,
    sizeof,
    convert

using Compat
using Switch

abstract AbstractIndexableBitVector <: AbstractVector{Bool}
typealias AbstractBitVector Union(BitVector,AbstractIndexableBitVector)

include("utils.jl")
include("bitvector.jl")
include("compactbitvector.jl")
include("sucvector.jl")
include("csucvector.jl")
include("rrr.jl")
include("derived.jl")

end # module
