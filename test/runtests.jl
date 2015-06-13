using IndexedBitVectors
using FactCheck

srand(12345)

function test_access{T}(::Type{T})
    b = convert(T, Int[])
    @fact_throws b[0]
    @fact_throws b[1]

    b = convert(T, [1])
    @fact_throws b[0]
    @fact b[1] => 1
    @fact_throws b[2]

    b = convert(T, [0])
    @fact_throws b[0]
    @fact b[1] => 0
    @fact_throws b[2]

    b = convert(T, [0, 0, 1, 1])
    @fact_throws b[0]
    @fact b[1] => 0
    @fact b[2] => 0
    @fact b[3] => 1
    @fact b[4] => 1
    @fact_throws b[5]

    b = convert(T, trues(1024))
    @fact b[1] => true
    @fact b[end] => true
    @fact all([b[i] for i in 1:1024]) => true

    b = convert(T, falses(1024))
    @fact b[1] => false
    @fact b[end] => false
    @fact all([b[i] for i in 1:1024]) => false

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @fact b[i] => bitv[i]; end
end

function test_rank{T}(::Type{T})
    b = convert(T, Int[])
    @fact rank0(b, 0) => 0
    @fact_throws rank0(b, 1)
    @fact rank1(b, 0) => 0
    @fact_throws rank1(b, 1)

    b = convert(T, [0])
    @fact rank0(b, 0) => 0
    @fact rank0(b, 1) => 1
    @fact_throws rank0(b, 2)
    @fact rank1(b, 0) => 0
    @fact rank1(b, 1) => 0
    @fact_throws rank1(b, 2)

    b = convert(T, [1])
    @fact rank0(b, 0) => 0
    @fact rank0(b, 1) => 0
    @fact_throws rank0(b, 2)
    @fact rank1(b, 0) => 0
    @fact rank1(b, 1) => 1
    @fact_throws rank1(b, 2)

    b = convert(T, [0, 0, 1, 1])
    # rank0
    @fact rank0(b, 0) => 0
    @fact rank0(b, 1) => 1
    @fact rank0(b, 2) => 2
    @fact rank0(b, 3) => 2
    @fact rank0(b, 4) => 2
    @fact rank(0, b, 0) => 0
    @fact rank(0, b, 4) => 2
    @fact_throws rank(0, b, 5) "out of bound"
    # rank1
    @fact rank1(b, 0) => 0
    @fact rank1(b, 1) => 0
    @fact rank1(b, 2) => 0
    @fact rank1(b, 3) => 1
    @fact rank1(b, 4) => 2
    @fact rank(1, b, 0) => 0
    @fact rank(1, b, 4) => 2
    @fact_throws rank(1, b, 5) "out of bound"

    b = convert(T, trues(1024))
    for i in 1:1024; @fact rank0(b, i) => 0; end
    for i in 1:1024; @fact rank1(b, i) => i; end

    b = convert(T, falses(1024))
    for i in 1:1024; @fact rank0(b, i) => i; end
    for i in 1:1024; @fact rank1(b, i) => 0; end

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @fact rank0(b, i) => rank0(bitv, i); end
    for i in 1:1024; @fact rank1(b, i) => rank1(bitv, i); end
end

function test_select{T}(::Type{T})
    b = convert(T, Int[])
    @fact select0(b, 0) => 0
    @fact select1(b, 0) => 0

    b = convert(T, [0])
    @fact select0(b, 0) => 0
    @fact select0(b, 1) => 1
    @fact select0(b, 2) => 0
    @fact select1(b, 0) => 0
    @fact select1(b, 1) => 0
    @fact select1(b, 2) => 0

    b = convert(T, [1])
    @fact select0(b, 0) => 0
    @fact select0(b, 1) => 0
    @fact select0(b, 2) => 0
    @fact select1(b, 0) => 0
    @fact select1(b, 1) => 1
    @fact select1(b, 2) => 0

    b = convert(T, [0, 0, 1, 1])
    # select0
    @fact select0(b, 0) => 0
    @fact select0(b, 1) => 1
    @fact select0(b, 2) => 2
    @fact select0(b, 3) => 0
    # select1
    @fact select1(b, 0) => 0
    @fact select1(b, 1) => 3
    @fact select1(b, 2) => 4
    @fact select1(b, 3) => 0

    b = convert(T, trues(1024))
    for i in 1:1024; @fact select0(b, i) => 0; end
    for i in 1:1024; @fact select1(b, i) => i; end

    b = convert(T, falses(1024))
    for i in 1:1024; @fact select0(b, i) => i; end
    for i in 1:1024; @fact select1(b, i) => 0; end

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @fact select0(b, i) => select0(bitv, i); end
    for i in 1:1024; @fact select1(b, i) => select1(bitv, i); end
end

facts("SucVector") do
    context("access") do
        test_access(SucVector)
    end
    context("rank") do
        test_rank(SucVector)
    end
    context("select") do
        test_select(SucVector)
    end
end

facts("BitVector") do
    context("access") do
        test_access(BitVector)
    end
    context("rank") do
        test_rank(BitVector)
    end
    context("select") do
        test_select(BitVector)
    end
end

facts("SuccinctBitVector") do
    context("access") do
        test_access(SuccinctBitVector)
    end
    context("rank") do
        test_rank(SuccinctBitVector)
    end
    context("select") do
        test_select(SuccinctBitVector)
    end
end
