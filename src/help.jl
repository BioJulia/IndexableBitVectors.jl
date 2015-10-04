# Help Document
# -------------
#
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

"""
    rsearch(x, bv, i)

Search the position of the previous `x` in `bv` starting from `i`.
"""
rsearch

"""
    rsearch0(bv, i)

Search the position of the previous 0 in `bv` starting from `i`.
"""
rsearch0

"""
    rsearch1(bv, i)

Search the position of the previous 1 in `bv` starting from `i`.
"""
rsearch1


