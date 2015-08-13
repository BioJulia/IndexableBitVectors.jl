# CSucVector
# ----------
#
# A variant of SucVector written in C. This is written to compare the
# performance of the Julia and C implementations.

const libbitvector = "deps/libbitvector"

type CSucVector <: AbstractIndexableBitVector
    ptr::Ptr{Void}

    function CSucVector(src::Union(BitVector,Vector{Bool}))
        ptr = ccall((:make_sucvector, libbitvector), Ptr{Void}, ())
        vec = new(ptr)
        finalizer(vec, vec -> ccall((:delete_sucvector, libbitvector), Void, (Ptr{Void},), vec.ptr))
        chunks = UInt64[]
        i = 1
        while i ≤ endof(src)
            chunk = IndexableBitVectors.read_chunk(src, i)
            push!(chunks, chunk)
            i += 64
        end
        @assert ccall((:read_chunks, libbitvector), Cint, (Ptr{Void}, Ptr{Uint64}, Csize_t), ptr, chunks, length(src)) == 0
        return vec
    end
end

function convert(::Type{CSucVector}, v::Union(BitVector,Vector{Bool}))
    return CSucVector(v)
end

function length(v::CSucVector)
    ccall((:length, libbitvector), Int64, (Ptr{Void},), v.ptr)
end

function getindex(v::CSucVector, i::Integer)
    if !(1 ≤ i ≤ endof(v))
        throw(BoundsError())
    end
    ccall((:access, libbitvector), Bool, (Ptr{Void}, Int64), v.ptr, i - 1)
end

function rank1(v::CSucVector, i::Int)
    if !(0 ≤ i ≤ endof(v))
        throw(BoundsError())
    end
    return unsafe_rank1(v, i)
end

function unsafe_rank1(v::CSucVector, i::Int)
    ccall((:rank1, libbitvector), Int64, (Ptr{Void}, Int64), v.ptr, i - 1)
end
