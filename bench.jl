using IndexedBitVectors

srand(1024)

function bench{T}(::Type{T}, len::Int, r=0.5)
    b = convert(T, rand(len) .> r)
    b[1]
    rank1(b, 1)
    select1(b, 1)

    gc()

    t0 = time_ns()
    for i in 1:len; b[i]; end
    t1 = time_ns()
    @printf "%s (access) : %10.3f ns per operation\n" T (t1 - t0) / len

    t0 = time_ns()
    for i in 1:len; rank1(b, i); end
    t1 = time_ns()
    @printf "%s (rank1)  : %10.3f ns per operation\n" T (t1 - t0) / len

    t0 = time_ns()
    for i in 1:len; select1(b, i); end
    t1 = time_ns()
    @printf "%s (select1): %10.3f ns per operation\n" T (t1 - t0) / len
end

let
    for p in [4, 8, 12, 16, 20, 24]
        len = 2^p
        println("length: $len bits")
        #for t in [BitVector, SuccinctBitVector, SucVector]
        for t in [SuccinctBitVector, SucVector]
            bench(t, len)
        end
        println()
    end
end
