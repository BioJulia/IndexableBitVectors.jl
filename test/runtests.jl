using IndexableDicts
using FactCheck

facts("rank/select") do
    context("BitVector") do
        # BitVector
        b = convert(BitVector, [0, 0, 1, 1])
        # rank
        @fact rank(0, b, 0) => 0
        @fact rank(0, b, 1) => 1
        @fact rank(0, b, 2) => 2
        @fact rank(0, b, 3) => 2
        @fact rank(0, b, 4) => 2
        @fact_throws rank(0, b, 5) "out of bound"
        @fact rank(1, b, 0) => 0
        @fact rank(1, b, 1) => 0
        @fact rank(1, b, 2) => 0
        @fact rank(1, b, 3) => 1
        @fact rank(1, b, 4) => 2
        @fact_throws rank(1, b, 5) "out of bound"
        # select
        @fact select(0, b, 0) => 0
        @fact select(0, b, 1) => 1
        @fact select(0, b, 2) => 2
        @fact select(0, b, 3) => NotFound
        @fact select(1, b, 0) => 0
        @fact select(1, b, 1) => 3
        @fact select(1, b, 2) => 4
        @fact select(1, b, 3) => NotFound
    end
end
