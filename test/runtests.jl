using IndexableBitVectors
using FactCheck

srand(12345)

function test_access{T}(::Type{T})
    b = convert(T, Bool[])
    @fact_throws b[0]
    @fact_throws b[1]

    b = convert(T, [true])
    @fact_throws b[0]
    @fact b[1] --> 1
    @fact_throws b[2]

    b = convert(T, [false])
    @fact_throws b[0]
    @fact b[1] --> 0
    @fact_throws b[2]

    b = convert(T, [false, false, true, true])
    @fact_throws b[0]
    @fact b[1] --> 0
    @fact b[2] --> 0
    @fact b[3] --> 1
    @fact b[4] --> 1
    @fact_throws b[5]

    b = convert(T, trues(1024))
    @fact b[1] --> true
    @fact b[end] --> true
    @fact all([b[i] for i in 1:1024]) --> true

    b = convert(T, falses(1024))
    @fact b[1] --> false
    @fact b[end] --> false
    @fact all([b[i] for i in 1:1024]) --> false

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @fact b[i] --> bitv[i]; end

    b = convert(T, rand(10) .> 0.5)
    for i in 1:10; @fact typeof(b[i]) --> Bool; end
end

function test_rank{T}(::Type{T})
    b = convert(T, Bool[])
    @fact rank0(b, 0) --> 0
    @fact rank0(b, 1) --> 0
    @fact rank1(b, 0) --> 0
    @fact rank1(b, 1) --> 0

    b = convert(T, [false])
    @fact rank0(b, 0) --> 0
    @fact rank0(b, 1) --> 1
    @fact rank0(b, 2) --> 1
    @fact rank1(b, 0) --> 0
    @fact rank1(b, 1) --> 0
    @fact rank1(b, 2) --> 0

    b = convert(T, [true])
    @fact rank0(b, 0) --> 0
    @fact rank0(b, 1) --> 0
    @fact rank0(b, 2) --> 0
    @fact rank1(b, 0) --> 0
    @fact rank1(b, 1) --> 1
    @fact rank1(b, 2) --> 1

    b = convert(T, [false, false, true, true])
    # rank0
    @fact rank0(b, 0) --> 0
    @fact rank0(b, 1) --> 1
    @fact rank0(b, 2) --> 2
    @fact rank0(b, 3) --> 2
    @fact rank0(b, 4) --> 2
    @fact rank(0, b, 0) --> 0
    @fact rank(0, b, 4) --> 2
    @fact rank(0, b, 5) --> 2
    # rank1
    @fact rank1(b, 0) --> 0
    @fact rank1(b, 1) --> 0
    @fact rank1(b, 2) --> 0
    @fact rank1(b, 3) --> 1
    @fact rank1(b, 4) --> 2
    @fact rank(1, b, 0) --> 0
    @fact rank(1, b, 4) --> 2
    @fact rank(1, b, 5) --> 2

    b = convert(T, trues(1024))
    for i in 1:1024; @fact rank0(b, i) --> 0; end
    for i in 1:1024; @fact rank1(b, i) --> i; end

    b = convert(T, falses(1024))
    for i in 1:1024; @fact rank0(b, i) --> i; end
    for i in 1:1024; @fact rank1(b, i) --> 0; end

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @fact rank0(b, i) --> rank0(bitv, i); end
    for i in 1:1024; @fact rank1(b, i) --> rank1(bitv, i); end

    b = convert(T, rand(10) .> 0.5)
    for i in 1:10; @fact typeof(rank0(b, i)) --> Int; end
    for i in 1:10; @fact typeof(rank1(b, i)) --> Int; end
end

function test_select{T}(::Type{T})
    b = convert(T, Bool[])
    @fact select0(b, -1) --> 0
    @fact select0(b, 0) --> 0
    @fact select0(b, 1) --> 0
    @fact select1(b, -1) --> 0
    @fact select1(b, 0) --> 0
    @fact select1(b, 1) --> 0

    b = convert(T, [false])
    @fact select0(b, -1) --> 0
    @fact select0(b, 0) --> 0
    @fact select0(b, 1) --> 1
    @fact select0(b, 2) --> 0
    @fact select1(b, -1) --> 0
    @fact select1(b, 0) --> 0
    @fact select1(b, 1) --> 0
    @fact select1(b, 2) --> 0

    b = convert(T, [true])
    @fact select0(b, -1) --> 0
    @fact select0(b, 0) --> 0
    @fact select0(b, 1) --> 0
    @fact select0(b, 2) --> 0
    @fact select1(b, -1) --> 0
    @fact select1(b, 0) --> 0
    @fact select1(b, 1) --> 1
    @fact select1(b, 2) --> 0

    b = convert(T, [false, false, true, true])
    # select0
    @fact select0(b, -1) --> 0
    @fact select0(b, 0) --> 0
    @fact select0(b, 1) --> 1
    @fact select0(b, 2) --> 2
    @fact select0(b, 3) --> 0
    # select1
    @fact select1(b, -1) --> 0
    @fact select1(b, 0) --> 0
    @fact select1(b, 1) --> 3
    @fact select1(b, 2) --> 4
    @fact select1(b, 3) --> 0

    b = convert(T, trues(1024))
    for i in 0:1025; @fact select0(b, i) --> 0; end
    for i in 0:1024; @fact select1(b, i) --> i; end
    @fact select1(b, 1025) --> 0

    b = convert(T, falses(1024))
    for i in 0:1024; @fact select0(b, i) --> i; end
    @fact select0(b, 1025) --> 0
    for i in 0:1025; @fact select1(b, i) --> 0; end

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @fact select0(b, i) --> select0(bitv, i); end
    for i in 1:1024; @fact select1(b, i) --> select1(bitv, i); end

    b = convert(T, rand(10) .> 0.5)
    for i in 1:10; @fact typeof(select0(b, i)) --> Int; end
    for i in 1:10; @fact typeof(select1(b, i)) --> Int; end
end

function test_long{T}(::Type{T})
    len = 2^33 + 1000
    b  = bitrand(len)
    while sum(b) ≤ typemax(UInt32)
        b  = bitrand(len)
    end
    b′ = T(b)
    for i in [1, 2, 2^32-1, 2^32, 2^32+1, len-1, len]
        @fact b′[i] --> b[i]
        @fact rank1(b′, i) --> sum(b[1:i])
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
    context("long") do
        test_long(SucVector)
    end
end

#=
facts("CompactBitVector") do
    context("access") do
        test_access(IndexableBitVectors.CompactBitVector)
    end
    context("rank") do
        test_rank(IndexableBitVectors.CompactBitVector)
    end
    context("select") do
        test_select(IndexableBitVectors.CompactBitVector)
    end
end
=#

facts("RRR") do
    context("access") do
        test_access(RRR)
    end
    context("rank") do
        test_rank(RRR)
    end
    context("select") do
        test_select(RRR)
    end
end

facts("LargeRRR") do
    context("access") do
        test_access(IndexableBitVectors.LargeRRR)
    end
    context("rank") do
        test_rank(IndexableBitVectors.LargeRRR)
    end
    context("select") do
        test_select(IndexableBitVectors.LargeRRR)
    end
end

facts("sizeof") do
    context("compressible") do
        bv = falses(10_000)
        @fact sizeof(RRR(bv)) < sizeof(bv) < sizeof(SucVector(bv)) --> true
        bv = trues(10_000)
        @fact sizeof(RRR(bv)) < sizeof(bv) < sizeof(SucVector(bv)) --> true
    end
    context("incompressible") do
        bv = bitrand(10_000)
        @fact sizeof(bv) < sizeof(SucVector(bv)) < sizeof(RRR(bv)) --> true
    end
end
