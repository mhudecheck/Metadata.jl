
"""
    ElementwiseMetaArray

Array with metadata attached to each element.
"""
struct ElementwiseMetaArray{T,N,P<:AbstractArray{<:MetaStruct{T},N}} <: AbstractArray{T,N}
    parent::P

    function ElementwiseMetaArray(x::AbstractArray{T,N}) where {T,N}
        if has_metadata(T)
            return new{parent_type(T),N,typeof(x)}(x)
        else
            throw(ArgumentError("eltype of array does not have metadata: got $T."))
        end
    end

    function ElementwiseMetaArray(x::AbstractArray, m)
        return ElementwiseMetaArray(attach_eachmeta(x, m))
    end
end

ArrayInterface.parent_type(::Type{ElementwiseMetaArray{T,N,P}}) where {T,N,P} = P

Base.parent(A::ElementwiseMetaArray) = getfield(A, :parent)

function metadata_type(::Type{T}) where {T<:ElementwiseMetaArray}
    return metadata_type(parent_type(T))
end

function metadata_keys(x::ElementwiseMetaArray{T,N,P}) where {T,N,P}
    ks = known_keys(metadata_type(x))
    if ks === nothing
        return metadata_keys(first(parent(x)))
    else
        return ks
    end
end

@propagate_inbounds function Base.getindex(A::ElementwiseMetaArray{T}, args...) where {T}
    val = getindex(parent(A), args...)
    if val isa T
        return parent(val)
    else
        return ElementwiseMetaArray(val)
    end
end

# TODO how should setindex! work with metadata?
@propagate_inbounds function Base.setindex!(A::ElementwiseMetaArray, val, args...)
    return setindex!(parent(A), val, args...)
end

"""
    MetaView{L}

A view of an array of metadata bound elements whose elements are paired to the key `L`.
"""
struct MetaView{L,T,N,P<:AbstractArray{<:Any,N}} <: AbstractArray{T,N}
    parent::P

    function MetaView{L}(x::AbstractArray{T,N}) where {L,T,N}
        if has_metadata(T)
            return new{L,metadata_type(T, L),N,typeof(x)}(x)
        else
            throw(ArgumentError("eltype of array does not have metadata: got $T."))
        end
    end
end

ArrayInterface.parent_type(::Type{MetaView{L,T,N,P}}) where {L,T,N,P} = P

Base.parent(x::MetaView) = getfield(x, :parent)

@propagate_inbounds function Base.getindex(x::MetaView{L,T}, args...) where {L,T}
    if val isa T
        return val
    else
        return MetaView{L}(val)
    end
end

@inline function metadata(A::ElementwiseMetaArray)
    ks = known_keys(A)
    if ks === nothing
        return Dict(map(k -> metadata(A, k), metadata_keys(A))...)
    else
        return NamedTuple{ks}(map(k -> metadata(A, k), ks))
    end
end

metadata(A::ElementwiseMetaArray, k::Symbol) = MetaView{k}(parent(A))


# TODO function drop_metadata(x::ElementwiseMetaArray) end

#=
struct AdjacencyList{T,L<:AbstractVector{<:AbstractVector{T}}} <: AbstractGraph{T}
    list::L
end

const MetaAdjacencyList{T,M} = AdjacencyList{T,Vector{ElementwiseMetaArray{T,1,Vector{Tuple{T,M}}}}}
=#

