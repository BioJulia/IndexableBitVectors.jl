using IndexableBitVectors
import IndexableBitVectors

srand(1024)

function bench{T}(::Type{T}, len::Int, ord::Vector{Int}; r=0.5)
    b = convert(T, rand(len) .> (1.0 - r))
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

    #println(n)
end

let
    random = false
    r = 0.5
    while !isempty(ARGS)
        arg = shift!(ARGS)
        if arg == "--random" || arg == "-r"
            random = true
        elseif arg == "--sparsity" || arg == "-s"
            r = parse(Float64, shift!(ARGS))
        else
            error("$arg")
        end
    end

    for p in [4, 8, 12, 16, 20, 24]
        len = 2^p
        ord = collect(1:len)
        if random
            shuffle!(ord)
        end
        println("length: $len bits")
        for t in [SuccinctBitVector, SucVector, CSucVector, RRR, RRRNP]
            bench(t, len, ord, r=r)
        end
        println()
    end
end
