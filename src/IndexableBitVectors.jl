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
    select1,
    search,
    search0,
    search1

import Base:
    convert,
    endof,
    getindex,
    length,
    push!,
    rank,
    search,
    select,
    size,
    sizeof

using Switch

abstract AbstractIndexableBitVector <: AbstractVector{Bool}
typealias AbstractBitVector Union{BitVector,AbstractIndexableBitVector}

include("utils.jl")
include("bitvector.jl")
include("compactbitvector.jl")
include("sucvector.jl")
include("rrr.jl")
include("derived.jl")

# help

# By convention, variable `i` is used to represent the index (or position) of a
# bit vector and `j` is used to represent the count (or cardinality) of a bit
# vector.

"""
    rank0(rb, i)

Count the number of 0s (`false`s) within `bv[1:i]`.
"""
rank0

"""
    rank1(bv, i)

Count the number of 1s (`true`s) within `bv[1:i]`.
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

"""
    search(x, bv, i)

Search the position of the next `x` in `bv` starting from `i`.
"""
search

"""
    search0(bv, i)

Search the position of the next 0 in `bv` starting from `i`.
"""
search0

"""
    search1(bv, i)

Search the position of the next 1 in `bv` starting from `i`.
"""
search1

end # module
