# IndexableBitVectors

[![Build Status](https://travis-ci.org/bicycle1885/IndexableBitVectors.jl.svg?branch=master)](https://travis-ci.org/bicycle1885/IndexableBitVectors.jl)

**This package is now alpha version.**

This package exports following operations over bit vectors with extremely fast speed while keeping extra memory usage small:

* `getindex(bv::IndexableBitVectors, i::Integer)`: `i`-th element of `bv`
* `rank(b::Bool, bv::AbstractIndexableBitVector, i::Integer)`: the number of occurrences of bit `b` in `bv[1:i]`
* `select(b::Bool, bv::AbstractIndexableBitVector, i::Integer)`: the index of `i`-th occurrence of `b` in `bv`.

And other shortcuts:

* `rank0(bv, i)` = `rank(false, bv, i)`
* `rank1(bv, i)` = `rank(true,  bv, i)`
* `select0(bv, i)` = `select(0, bv, i)`
* `select1(bv, i)` = `select(1, bv, i)`

`AbstractIndexableBitVector`s:

* `CompactBitVector`: rank values are precomputed in large and small blocks.
* `SucVector`: similar to `CompactBitVector`, but the data layout is different.
* `RRR`: compressible indexable bit vector.
* `RRRNP`: similar to `RRR`, but compressed code is decoded on the fly.

## Benchmarks:

* [Dense (0.50)](benchmarks/dense.txt)
* [Sparse (0.10)](benchmarks/sparse.txt)
* [Very Sparse (0.01)](benchmarks/very-sparse.txt)

