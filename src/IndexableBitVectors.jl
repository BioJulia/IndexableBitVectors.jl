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

# help

"""
    rank0(rb, i)

Count the number of 0s within `bv[1:i]`.
"""
rank0

"""
    rank1(bv, i)

Count the number of 1s within `bv[1:i]`.
"""
rank1

"""
    rank(x, bv, i)

Count the number of `x`s within `bv[1:i]`.
"""
rank

"""
    select0(bv, j)

Return the position of the `j`-th occurrence of 0 in `bv`.
"""
select0

"""
    select1(bv, j)

Return the position of the `j`-th occurrence of 1 in `bv`.
"""
select1

"""
    select(x, bv, j)

Return the position of the `j`-th occurrence of `x` in `bv`.
"""
select

end # module
