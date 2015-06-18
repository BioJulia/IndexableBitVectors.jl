using IndexedBitVectors
import IndexedBitVectors

srand(1024)

function bench{T}(::Type{T}, len::Int; r=0.5, random=false)
    b = convert(T, rand(len) .> r)
    ord = collect(1:len)
    if random
        shuffle!(ord)
    end
    b[1]
    rank1(b, 1)
    select1(b, 1)

    gc()
    n = 0

    t0 = time_ns()
    for i in ord; n += b[i]; end
    t1 = time_ns()
    @printf "%s (access) : %10.3f ns/op\n" T (t1 - t0) / len

    t0 = time_ns()
    for i in ord; n += rank1(b, i); end
    t1 = time_ns()
    @printf "%s (rank1)  : %10.3f ns/op\n" T (t1 - t0) / len

    t0 = time_ns()
    for i in ord; n += select1(b, i); end
    t1 = time_ns()
    @printf "%s (select1): %10.3f ns/op\n" T (t1 - t0) / len

    println(n)
end

let
    for p in [4, 8, 12, 16, 20, 24]
        len = 2^p
        println("length: $len bits")
        for t in [SuccinctBitVector, SucVector, CSucVector]
            bench(t, len, random=true)
        end
        println()
    end
end
