module IndexableBitVectors

export
    # types
    AbstractBitVector,
    AbstractIndexableBitVector,
    CompactBitVector,
    SucVector,
    CSucVector,
    RRR,
    LargeRRR,
    # query operations
    rank,
    rank0,
    rank1,
    select,
    select0,
    select1

import Base: rank, select, push!, getindex, length, endof, sizeof, convert
using Compat
using Switch

abstract AbstractIndexableBitVector
typealias AbstractBitVector Union(BitVector,AbstractIndexableBitVector)

include("common.jl")
include("bitvector.jl")
include("compactbitvector.jl")
include("sucvector.jl")
include("csucvector.jl")
include("rrr.jl")
include("derived.jl")

end # module
