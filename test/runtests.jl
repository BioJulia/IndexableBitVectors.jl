using IndexableBitVectors
using Test
using Random

Random.seed!(12345)

function test_access(::Type{T}) where T
    b = convert(T, Bool[])
    @test_throws BoundsError b[0]
    @test_throws BoundsError b[1]

    b = convert(T, [false])
    @test_throws BoundsError b[0]
    @test b[1] == 0
    @test_throws BoundsError b[2]

    b = convert(T, [true])
    @test_throws BoundsError b[0]
    @test b[1] == 1
    @test_throws BoundsError b[2]

    b = convert(T, [false, false, true, true])
    @test_throws BoundsError b[0]
    @test b[1] == 0
    @test b[2] == 0
    @test b[3] == 1
    @test b[4] == 1
    @test_throws BoundsError b[5]

    b = convert(T, falses(1024))
    @test b[1] == false
    @test b[end] == false
    @test all([b[i] for i in 1:1024]) == false

    b = convert(T, trues(1024))
    @test b[1] == true
    @test b[end] == true
    @test all([b[i] for i in 1:1024]) == true

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @test b[i] == bitv[i]; end

    b = convert(T, rand(10) .> 0.5)
    for i in 1:10; @test isa(b[i], Bool); end
end

function test_rank(::Type{T}) where T
    b = convert(T, Bool[])
    @test rank0(b, 0) == 0
    @test rank0(b, 1) == 0
    @test rank1(b, 0) == 0
    @test rank1(b, 1) == 0

    b = convert(T, [false])
    @test rank0(b, 0) == 0
    @test rank0(b, 1) == 1
    @test rank0(b, 2) == 1
    @test rank1(b, 0) == 0
    @test rank1(b, 1) == 0
    @test rank1(b, 2) == 0

    b = convert(T, [true])
    @test rank0(b, 0) == 0
    @test rank0(b, 1) == 0
    @test rank0(b, 2) == 0
    @test rank1(b, 0) == 0
    @test rank1(b, 1) == 1
    @test rank1(b, 2) == 1

    b = convert(T, [false, false, true, true])
    # rank0
    @test rank0(b, 0) == 0
    @test rank0(b, 1) == 1
    @test rank0(b, 2) == 2
    @test rank0(b, 3) == 2
    @test rank0(b, 4) == 2
    @test rank(0, b, 0) == 0
    @test rank(0, b, 4) == 2
    @test rank(0, b, 5) == 2
    # rank1
    @test rank1(b, 0) == 0
    @test rank1(b, 1) == 0
    @test rank1(b, 2) == 0
    @test rank1(b, 3) == 1
    @test rank1(b, 4) == 2
    @test rank(1, b, 0) == 0
    @test rank(1, b, 4) == 2
    @test rank(1, b, 5) == 2

    b = convert(T, falses(1024))
    for i in 1:1024; @test rank0(b, i) == i; end
    for i in 1:1024; @test rank1(b, i) == 0; end

    b = convert(T, trues(1024))
    for i in 1:1024; @test rank0(b, i) == 0; end
    for i in 1:1024; @test rank1(b, i) == i; end

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @test rank0(b, i) == rank0(bitv, i); end
    for i in 1:1024; @test rank1(b, i) == rank1(bitv, i); end

    b = convert(T, rand(10) .> 0.5)
    for i in 0:11; @test isa(rank0(b, i), Int); end
    for i in 0:11; @test isa(rank1(b, i), Int); end
end

function test_select(::Type{T}) where T
    b = convert(T, Bool[])
    @test select0(b, -1) == 0
    @test select0(b, 0) == 0
    @test select0(b, 1) == 0
    @test select1(b, -1) == 0
    @test select1(b, 0) == 0
    @test select1(b, 1) == 0

    b = convert(T, [false])
    @test select0(b, -1) == 0
    @test select0(b, 0) == 0
    @test select0(b, 1) == 1
    @test select0(b, 2) == 0
    @test select1(b, -1) == 0
    @test select1(b, 0) == 0
    @test select1(b, 1) == 0
    @test select1(b, 2) == 0

    b = convert(T, [true])
    @test select0(b, -1) == 0
    @test select0(b, 0) == 0
    @test select0(b, 1) == 0
    @test select0(b, 2) == 0
    @test select1(b, -1) == 0
    @test select1(b, 0) == 0
    @test select1(b, 1) == 1
    @test select1(b, 2) == 0

    b = convert(T, [false, false, true, true])
    # select0
    @test select0(b, -1) == 0
    @test select0(b, 0) == 0
    @test select0(b, 1) == 1
    @test select0(b, 2) == 2
    @test select0(b, 3) == 0
    # select1
    @test select1(b, -1) == 0
    @test select1(b, 0) == 0
    @test select1(b, 1) == 3
    @test select1(b, 2) == 4
    @test select1(b, 3) == 0

    b = convert(T, falses(1024))
    for i in 0:1024; @test select0(b, i) == i; end
    @test select0(b, 1025) == 0
    for i in 0:1025; @test select1(b, i) == 0; end

    b = convert(T, trues(1024))
    for i in 0:1025; @test select0(b, i) == 0; end
    for i in 0:1024; @test select1(b, i) == i; end
    @test select1(b, 1025) == 0

    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024; @test select0(b, i) == select0(bitv, i); end
    for i in 1:1024; @test select1(b, i) == select1(bitv, i); end

    b = convert(T, rand(10) .> 0.5)
    for i in 0:11; @test isa(select0(b, i), Int); end
    for i in 0:11; @test isa(select1(b, i), Int); end
end

function test_search(::Type{T}) where T
    b = convert(T, Bool[])
    @test search0(b, 0) == 0
    @test search0(b, 1) == 0
    @test search1(b, 0) == 0
    @test search1(b, 1) == 0

    b = convert(T, [false])
    @test search0(b, 0) == 1
    @test search0(b, 1) == 1
    @test search0(b, 2) == 0
    @test search1(b, 0) == 0
    @test search1(b, 1) == 0
    @test search1(b, 2) == 0

    b = convert(T, [true])
    @test search0(b, 0) == 0
    @test search0(b, 1) == 0
    @test search0(b, 2) == 0
    @test search1(b, 0) == 1
    @test search1(b, 1) == 1
    @test search1(b, 2) == 0

    b = convert(T, [false, false, true, true])
    # search0
    @test search0(b, 0) == 1
    @test search0(b, 1) == 1
    @test search0(b, 2) == 2
    @test search0(b, 3) == 0
    @test search0(b, 4) == 0
    # search1
    @test search1(b, 0) == 3
    @test search1(b, 1) == 3
    @test search1(b, 2) == 3
    @test search1(b, 3) == 3
    @test search1(b, 4) == 4

    b = convert(T, falses(1024))
    for i in 1:1024; @test search0(b, i) == i; end
    for i in 1:1024; @test search1(b, i) == 0; end

    b = convert(T, trues(1024))
    for i in 1:1024; @test search0(b, i) == 0; end
    for i in 1:1024; @test search1(b, i) == i; end

    function linsearch(x, bv, i)
        while i ≤ lastindex(bv) && bv[i] != x
            i += 1
        end
        return i > lastindex(bv) ? 0 : i
    end
    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024
        @test search0(b, i) == linsearch(0, bitv, i)
        @test search1(b, i) == linsearch(1, bitv, i)
    end

    b = convert(T, rand(10) .> 0.5)
    for i in 0:11; @test isa(search0(b, i), Int); end
    for i in 0:11; @test isa(search1(b, i), Int); end
end

function test_rsearch(::Type{T}) where T
    b = convert(T, Bool[])
    @test rsearch0(b, 0) == 0
    @test rsearch0(b, 1) == 0
    @test rsearch1(b, 0) == 0
    @test rsearch1(b, 1) == 0

    b = convert(T, [false])
    @test rsearch0(b, 0) == 0
    @test rsearch0(b, 1) == 1
    @test rsearch0(b, 2) == 1
    @test rsearch1(b, 0) == 0
    @test rsearch1(b, 1) == 0
    @test rsearch1(b, 2) == 0

    b = convert(T, [true])
    @test rsearch0(b, 0) == 0
    @test rsearch0(b, 1) == 0
    @test rsearch0(b, 2) == 0
    @test rsearch1(b, 0) == 0
    @test rsearch1(b, 1) == 1
    @test rsearch1(b, 2) == 1

    b = convert(T, [false, false, true, true])
    # rsearch0
    @test rsearch0(b, 0) == 0
    @test rsearch0(b, 1) == 1
    @test rsearch0(b, 2) == 2
    @test rsearch0(b, 3) == 2
    @test rsearch0(b, 4) == 2
    # rsearch1
    @test rsearch1(b, 0) == 0
    @test rsearch1(b, 1) == 0
    @test rsearch1(b, 2) == 0
    @test rsearch1(b, 3) == 3
    @test rsearch1(b, 4) == 4

    b = convert(T, falses(1024))
    for i in 1:1024; @test rsearch0(b, i) == i; end
    for i in 1:1024; @test rsearch1(b, i) == 0; end

    b = convert(T, trues(1024))
    for i in 1:1024; @test rsearch0(b, i) == 0; end
    for i in 1:1024; @test rsearch1(b, i) == i; end

    function linrsearch(x, bv, i)
        while i ≥ 1 && bv[i] != x
            i -= 1
        end
        return i < 1 ? 0 : i
    end
    bitv = rand(1024) .> 0.5
    b = convert(T, bitv)
    for i in 1:1024
        @test rsearch0(b, i) == linrsearch(0, bitv, i)
        @test rsearch1(b, i) == linrsearch(1, bitv, i)
    end

    b = convert(T, rand(10) .> 0.5)
    for i in 0:11; @test isa(rsearch0(b, i), Int); end
    for i in 0:11; @test isa(rsearch1(b, i), Int); end
end

function test_long(::Type{T}) where T
    len = 2^33 + 1000
    b  = bitrand(len)
    while sum(b) ≤ typemax(UInt32)
        b  = bitrand(len)
    end
    b′ = T(b)
    for i in [1, 2, 2^32-1, 2^32, 2^32+1, len-1, len]
        @test b′[i] == b[i]
        @test rank1(b′, i) == sum(b[1:i])
    end
end

function test_copy(::Type{T}) where T
    b = convert(T, Bool[])
    @test copy(b) == b
    @test copy(b) !== b

    b = convert(T, rand(100) .> 0.5)
    @test copy(b) == b
    @test copy(b) !== b

    b = convert(T, rand(10000) .> 0.5)
    @test copy(b) == b
    @test copy(b) !== b
end


@testset "BitVector" begin
    @testset "access" begin
        test_access(BitVector)
    end
    @testset "rank" begin
        test_rank(BitVector)
    end
    @testset "select" begin
        test_select(BitVector)
    end
end

@testset "SucVector" begin
    @testset "access" begin
        test_access(SucVector)
    end
    @testset "rank" begin
        test_rank(SucVector)
    end
    @testset "select" begin
        test_select(SucVector)
    end
    @testset "search" begin
        test_search(SucVector)
    end
    @testset "rsearch" begin
        test_rsearch(SucVector)
    end
    @testset "long" begin
        test_long(SucVector)
    end
    @testset "copy" begin
        test_copy(SucVector)
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

@testset "RRR" begin
    @testset "access" begin
        test_access(RRR)
    end
    @testset "rank" begin
        test_rank(RRR)
    end
    @testset "select" begin
        test_select(RRR)
    end
    @testset "search" begin
        test_search(RRR)
    end
    @testset "rsearch" begin
        test_rsearch(RRR)
    end
    @testset "copy" begin
        test_copy(RRR)
    end
end

@testset "LargeRRR" begin
    @testset "access" begin
        test_access(IndexableBitVectors.LargeRRR)
    end
    @testset "rank" begin
        test_rank(IndexableBitVectors.LargeRRR)
    end
    @testset "select" begin
        test_select(IndexableBitVectors.LargeRRR)
    end
    @testset "copy" begin
        test_copy(IndexableBitVectors.LargeRRR)
    end
end

@testset "Size" begin
    @testset "compressible" begin
        bv = falses(10_000)
        @test sizeof(RRR(bv)) < sizeof(bv) < sizeof(SucVector(bv))
        bv = trues(10_000)
        @test sizeof(RRR(bv)) < sizeof(bv) < sizeof(SucVector(bv))
    end
    @testset "incompressible" begin
        bv = bitrand(10_000)
        @test sizeof(bv) < sizeof(SucVector(bv)) < sizeof(RRR(bv))
    end
end
