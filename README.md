# IndexableBitVectors

[![Build Status](https://travis-ci.org/BioJulia/IndexableBitVectors.jl.svg?branch=master)](https://travis-ci.org/BioJulia/IndexableBitVectors.jl)
[![IndexableBitVectors.jl](http://pkg.julialang.org/badges/IndexableBitVectors_0.4.svg)](http://pkg.julialang.org/?pkg=IndexableBitVectors&ver=0.4)

This package exports following operations over bit vectors with extremely fast
speed while keeping extra memory usage small:

* `getindex(bv::IndexableBitVectors, i::Integer)`: `i`-th element of `bv`
* `rank(b::Bool, bv::AbstractIndexableBitVector, i::Integer)`: the number of occurrences of bit `b` in `bv[1:i]`
* `select(b::Bool, bv::AbstractIndexableBitVector, i::Integer)`: the index of `i`-th occurrence of `b` in `bv`.

And other shortcuts:

* `rank0(bv, i)` = `rank(false, bv, i)`
* `rank1(bv, i)` = `rank(true,  bv, i)`
* `select0(bv, i)` = `select(0, bv, i)`
* `select1(bv, i)` = `select(1, bv, i)`

The following two types are exported:

* `SucVector`: rank values are precomputed in blocks.
* `RRR`: compressible indexable bit vector.

In general, queries on `SucVector` is faster than those on `RRR`, but `RRR` is compressible.

## Benchmarks:

The script and result of benchmarks can be found in the [benchmarks](./benchmarks)
directory. Plots are in a Jupyter notebook: [benchmarks/plot.ipynb](./benchmarks/plot.ipynb).
