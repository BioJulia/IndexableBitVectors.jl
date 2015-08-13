using IndexableBitVectors

srand(12345)

function bench_getindex(bv, n)
    # warming up
    for i in 1:endof(bv)
        bv[i]
    end
    t = @elapsed for _ in 1:n
        for i in 1:endof(bv)
            bv[i]
        end
    end
    return t / (n * length(bv))
end

function bench_rank1(bv, n)
    for i in 1:endof(bv)
        rank1(bv, i)
    end
    t = @elapsed for _ in 1:n
        for i in 1:endof(bv)
            rank1(bv, i)
        end
    end
    return t / (n * length(bv))
end

function bench_select1(bv, n)
    for i in 1:endof(bv)
        select1(bv, i)
    end
    t = @elapsed for _ in 1:n
        for i in 1:endof(bv)
            select1(bv, i)
        end
    end
    return t / (n * length(bv))
end

let
    name = shift!(ARGS)
    T = name == "CompactBitVector" ? CompactBitVector :
        name == "SucVector" ? SucVector :
        name == "RRR" ? RRR :
        name == "LargeRRR" ? LargeRRR : error("unknown type name: ", name)
    columns = ["type", "length", "r", "bench_getindex", "bench_rank1", "bench_select1"]
    println(join(columns, '\t'))
    for r in [0.01, 0.1, 0.5], p in 10:2:24
        len = 2^p
        vec = rand(len) .< r
        bv = convert(T, vec)
        print(T, '\t', len, '\t', r, '\t')
        print(bench_getindex(bv, 5), '\t')
        print(bench_rank1(bv, 5), '\t')
        print(bench_select1(bv, 5), '\n')
    end
end
