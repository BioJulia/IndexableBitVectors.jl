using IndexableBitVectors
import IndexableBitVectors
using Humanize

srand(1024)

function bench{T}(::Type{T}, len::Int, ord::Vector{Int}; r=0.5)
    b = convert(T, rand(len) .> (1.0 - r))
    b[1]
    rank1(b, 1)
    select1(b, 1)

    n = 0

    gc()
    t0 = time_ns()
    for i in ord; n += b[i]; end
    t1 = time_ns()
    @printf "%s (access) : %10.3f ns/op\n" T (t1 - t0) / length(ord)

    gc()
    t0 = time_ns()
    for i in ord; n += rank1(b, i); end
    t1 = time_ns()
    @printf "%s (rank1)  : %10.3f ns/op\n" T (t1 - t0) / length(ord)

    gc()
    t0 = time_ns()
    for i in ord; n += select1(b, i); end
    t1 = time_ns()
    @printf "%s (select1): %10.3f ns/op\n" T (t1 - t0) / length(ord)

    return sizeof(b)
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

    for p in [6, 12, 18, 24, 30]
        len = 2^p
        ord = collect(1:len)
        if random
            ord = ord[rand(1:length(ord), 10_000)]
        end
        println("length: $len bits = $(datasize(div(len, 8), style=:bin))")
        for t in [CompactBitVector, SucVector, CSucVector, RRR, RRRNP]
            size = bench(t, len, ord, r=r)
            println("sizeof(bitvector) = $(datasize(size, style=:bin))")
        end
        println()
    end
end
