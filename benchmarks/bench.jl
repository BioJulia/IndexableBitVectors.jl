using IndexableBitVectors

Random.seed!(12345)

const step = 16

function bench_getindex(bv, n)
    range = 1:step:endof(bv)
    # warming up
    for i in range
        bv[i]
    end
    t = @elapsed for _ in 1:n
        for i in range
            bv[i]
        end
    end
    return t / (n * length(range))
end

function bench_rank1(bv, n)
    range = 1:step:endof(bv)
    for i in range
        rank1(bv, i)
    end
    t = @elapsed for _ in 1:n
        for i in range
            rank1(bv, i)
        end
    end
    return t / (n * length(range))
end

function bench_select1(bv, n)
    range = 1:step:endof(bv)
    for i in range
        select1(bv, i)
    end
    t = @elapsed for _ in 1:n
        for i in range
            select1(bv, i)
        end
    end
    return t / (n * length(range))
end

let
    name = popfirst!(ARGS)
    T = name == "CompactBitVector" ? CompactBitVector :
        name == "SucVector" ? SucVector :
        name == "RRR" ? RRR :
        name == "LargeRRR" ? LargeRRR : error("unknown type name: ", name)
    columns = ["type", "length", "r", "bench_getindex", "bench_rank1", "bench_select1"]
    println(join(columns, '\t'))
    for r in [0.01, 0.1, 0.5], p in 10:2:30
        #info("$r $p")
        len = 2^p
        vec = rand(Float32, len) .< r
        bv = convert(T, vec)
        print(T, '\t', len, '\t', r, '\t')
        n = max(1, div(2^26, 2^p))
        gc()
        print(bench_getindex(bv, n), '\t')
        gc()
        print(bench_rank1(bv, n), '\t')
        gc()
        print(bench_select1(bv, n), '\n')
    end
end
