# IndexedBitVectors

[![Build Status](https://travis-ci.org/bicycle1885/IndexedBitVectors.jl.svg?branch=master)](https://travis-ci.org/bicycle1885/IndexedBitVectors.jl)

**This package is now experimantal.**

This package exports following operations over bit vectors with extremely fast speed while keeping extra memory usage small:

* `getindex(bv::AbstractIndexedBitVector, i::Int)`: `i`-th element of `bv`
* `rank(b::Bool, bv::AbstractIndexedBitVector, i::Int)`: the number of occurrences of bit `b` in `bv[1:i]`
* `select(b::Bool, bv::AbstractIndexedBitVector, i::Int)`: the index of `i`-th occurrence of `b` in `bv`.

And other shortcuts:

* `rank0(bv, i)` = `rank(false, bv, i)`
* `rank1(bv, i)` = `rank(true,  bv, i)`
* `select0(bv, i)` = `select(0, bv, i)`
* `select1(bv, i)` = `select(1, bv, i)`

`AbstractIndexedBitVector`s:

* `SuccinctBitVector`: rank values are precomputed in large and small blocks.

## Benchmarks:

Compared `SuccinctBitVector` with `BitVector`:

    $ julia bench.jl
    length: 16 bits
    BitArray{1} (access) :     55.375 ns per operation
    BitArray{1} (rank1)  :     98.688 ns per operation
    BitArray{1} (select1):    203.500 ns per operation
    SuccinctBitVector (access) :     56.563 ns per operation
    SuccinctBitVector (rank1)  :     59.375 ns per operation
    SuccinctBitVector (select1):    110.813 ns per operation

    length: 256 bits
    BitArray{1} (access) :      7.848 ns per operation
    BitArray{1} (rank1)  :    358.809 ns per operation
    BitArray{1} (select1):   4615.379 ns per operation
    SuccinctBitVector (access) :      7.309 ns per operation
    SuccinctBitVector (rank1)  :     14.145 ns per operation
    SuccinctBitVector (select1):     98.480 ns per operation

    length: 4096 bits
    BitArray{1} (access) :      4.242 ns per operation
    BitArray{1} (rank1)  :   5905.896 ns per operation
    BitArray{1} (select1):  46423.166 ns per operation
    SuccinctBitVector (access) :      3.374 ns per operation
    SuccinctBitVector (rank1)  :      7.356 ns per operation
    SuccinctBitVector (select1):    120.525 ns per operation

    length: 65536 bits
    BitArray{1} (access) :      2.802 ns per operation
    BitArray{1} (rank1)  :  88319.224 ns per operation
    BitArray{1} (select1): 880926.654 ns per operation
    SuccinctBitVector (access) :      3.277 ns per operation
    SuccinctBitVector (rank1)  :      7.928 ns per operation
    SuccinctBitVector (select1):     94.291 ns per operation
