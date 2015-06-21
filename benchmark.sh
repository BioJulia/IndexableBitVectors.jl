#!/usr/bin sh

if [[ ! -d benchmarks ]]; then
    mkdir benchmarks
fi

julia bench.jl -r -s 0.50 > benchmarks/dense.txt
julia bench.jl -r -s 0.10 > benchmarks/sparse.txt
julia bench.jl -r -s 0.01 > benchmarks/very-sparse.txt
