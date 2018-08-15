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
    select1,
    search,
    search0,
    search1,
    rsearch,
    rsearch0,
    rsearch1

include("common.jl")
include("utils.jl")
include("bitvector.jl")
include("compactbitvector.jl")
include("sucvector.jl")
include("rrr.jl")
include("derived.jl")
include("help.jl")

end # module
