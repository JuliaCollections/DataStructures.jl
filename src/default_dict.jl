# Dictionary which returns (and sets) a default value for a requested item not
# already in to the dictionary

# DefaultDictBase is the main class used to in Default*Dicts.
#
# Each related (immutable) Default*Dict class contains a single
# DefaultDictBase object as a member, and delegates almost all
# functions to this object.
#
# The main rationale for doing this instead of using type aliases is
# that this way, we can have actual class names and constructors for
# each of the DefaultDictBase "subclasses", in some sense getting
# around the Julia limitation of not allowing concrete classes to be
# subclassed.
#

struct DefaultDictBase{K,V,F,D} <: AbstractDict{K,V}
    default::F
    d::D
    passkey::Bool

    check_D(D,K,V) = (D <: AbstractDict{K,V}) ||
        throw(ArgumentError("Default dict must be <: AbstractDict{$K,$V}"))

    DefaultDictBase{K,V,F,D}(x::F, kv::AbstractArray{Tuple{K,V}}; passkey=false) where {K,V,F,D} =
        (check_D(D,K,V); new{K,V,F,D}(x, D(kv), passkey))
    DefaultDictBase{K,V,F,D}(x::F, ps::Pair{K,V}...; passkey=false) where {K,V,F,D} =
        (check_D(D,K,V); new{K,V,F,D}(x, D(ps...), passkey))

    DefaultDictBase{K,V,F,D}(x::F, d::D; passkey=d.passkey) where {K,V,F,D<:DefaultDictBase} =
        (check_D(D,K,V); DefaultDictBase(x, d.d; passkey=passkey))
    DefaultDictBase{K,V,F,D}(x::F, d::D = D(); passkey=false) where {K,V,F,D} =
        (check_D(D,K,V); new{K,V,F,D}(x, d, passkey))
end

# Constructors

DefaultDictBase(; kwargs...) = throw(ArgumentError("no default specified"))
DefaultDictBase(k, v; kwargs...) = throw(ArgumentError("no default specified"))

# syntax entry points
DefaultDictBase(default::F; kwargs...) where {F} = DefaultDictBase{Any,Any,F,Dict{Any,Any}}(default; kwargs...)
DefaultDictBase(default::F, kv::AbstractArray{Tuple{K,V}}; kwargs...) where {K,V,F} = DefaultDictBase{K,V,F,Dict{K,V}}(default, kv; kwargs...)
DefaultDictBase(default::F, ps::Pair{K,V}...; kwargs...) where {K,V,F} = DefaultDictBase{K,V,F,Dict{K,V}}(default, ps...; kwargs...)
DefaultDictBase(default::F, d::D; kwargs...) where {F,D<:AbstractDict} = (K=keytype(d); V=valtype(d); DefaultDictBase{K,V,F,D}(default, d; kwargs...))

# Constructor for DefaultDictBase{Int,Float64}(0.0)
DefaultDictBase{K,V}(default::F; kwargs...) where {K,V,F} = DefaultDictBase{K,V,F,Dict{K,V}}(default; kwargs...)

# Functions

# most functions are simply delegated to the wrapped dictionary
@delegate DefaultDictBase.d [ Base.get, Base.haskey, Base.getkey, Base.pop!,
                              Base.iterate, Base.isempty, Base.length ]

# Some functions are delegated, but then need to return the main dictionary
# NOTE: push! is not included below, because the fallback version just
#       calls setindex!
@delegate_return_parent DefaultDictBase.d [ Base.delete!, Base.empty!, Base.setindex!, Base.sizehint! ]

Base.empty(d::DefaultDictBase{K,V,F}) where {K,V,F} = DefaultDictBase{K,V,F}(d.default; passkey=d.passkey)

Base.getindex(d::DefaultDictBase, key) = get!(d.d, key, d.default)

function Base.getindex(d::DefaultDictBase{K,V,F}, key) where {K,V,F<:Base.Callable}
    if d.passkey
        return get!(d.d, key) do
            d.default(key)
        end
    else
        return get!(d.d, key) do
            d.default()
        end
    end
end


################

# Here begins the actual definition of the DefaultDict and
# DefaultOrderedDict classes.  As noted above, these are simply
# wrappers around a DefaultDictBase object, and delegate all functions
# to that object

for _Dict in [:Dict, :OrderedDict]
    DefaultDict = Symbol("Default"*string(_Dict))
    @eval begin
        struct $DefaultDict{K,V,F} <: AbstractDict{K,V}
            d::DefaultDictBase{K,V,F,$_Dict{K,V}}

            $DefaultDict{K,V,F}(x, ps::Pair{K,V}...; kwargs...) where {K,V,F} =
                new{K,V,F}(DefaultDictBase{K,V,F,$_Dict{K,V}}(x, ps...; kwargs...))
            $DefaultDict{K,V,F}(x, kv::AbstractArray{Tuple{K,V}}; kwargs...) where {K,V,F} =
                new{K,V,F}(DefaultDictBase{K,V,F,$_Dict{K,V}}(x, kv; kwargs...))
            $DefaultDict{K,V,F}(x, d::$DefaultDict) where {K,V,F} = $DefaultDict(x, d.d)
            $DefaultDict{K,V,F}(x, d::$_Dict; kwargs...) where {K,V,F} =
                new{K,V,F}(DefaultDictBase{K,V,F,$_Dict{K,V}}(x, d; kwargs...))
            $DefaultDict{K,V,F}(x; kwargs...) where {K,V,F} =
                new{K,V,F}(DefaultDictBase{K,V,F,$_Dict{K,V}}(x; kwargs...))
        end

        ## Constructors

        $DefaultDict() = throw(ArgumentError("$DefaultDict: no default specified"))
        $DefaultDict(k,v) = throw(ArgumentError("$DefaultDict: no default specified"))

        # syntax entry points
        $DefaultDict(default::F; kwargs...) where {F} = $DefaultDict{Any,Any,F}(default; kwargs...)
        $DefaultDict(default::F, kv::AbstractArray{Tuple{K,V}}; kwargs...) where {K,V,F} = $DefaultDict{K,V,F}(default, kv; kwargs...)
        $DefaultDict(default::F, ps::Pair{K,V}...; kwargs...) where {K,V,F} = $DefaultDict{K,V,F}(default, ps...; kwargs...)

        $DefaultDict(default::F, d::AbstractDict; kwargs...) where {F} = ((K,V)= (Base.keytype(d), Base.valtype(d)); $DefaultDict{K,V,F}(default, $_Dict(d); kwargs...))

        # Constructor syntax: DefaultDictBase{Int,Float64}(default)
        $DefaultDict{K,V}(; kwargs...) where {K,V} = throw(ArgumentError("$DefaultDict: no default specified"))
        $DefaultDict{K,V}(default::F; kwargs...) where {K,V,F} = $DefaultDict{K,V,F}(default; kwargs...)

        ## Functions

        # Most functions are simply delegated to the wrapped DefaultDictBase object
        @delegate $DefaultDict.d [ Base.getindex, Base.get, Base.get!, Base.haskey,
                                   Base.getkey, Base.pop!, Base.iterate,
                                   Base.isempty, Base.length ]

        # Some functions are delegated, but then need to return the main dictionary
        # NOTE: push! is not included below, because the fallback version just
        #       calls setindex!
        @delegate_return_parent $DefaultDict.d [ Base.delete!, Base.empty!, Base.setindex!, Base.sizehint! ]

        # NOTE: The second and third definition of push! below are only
        # necessary for disambiguating with the fourth, fifth, and sixth
        # definitions of push! below.
        # If these are removed, the second and third definitions can be
        # removed as well.
        Base.push!(d::$DefaultDict, p::Pair) = (setindex!(d.d, p.second, p.first); d)
        Base.push!(d::$DefaultDict, p::Pair, q::Pair) = push!(push!(d, p), q)
        Base.push!(d::$DefaultDict, p::Pair, q::Pair, r::Pair...) = push!(push!(push!(d, p), q), r...)

        Base.push!(d::$DefaultDict, p) = (setindex!(d.d, p[2], p[1]); d)
        Base.push!(d::$DefaultDict, p, q) = push!(push!(d, p), q)
        Base.push!(d::$DefaultDict, p, q, r...) = push!(push!(push!(d, p), q), r...)

        Base.empty(d::$DefaultDict{K,V,F}) where {K,V,F} = $DefaultDict{K,V,F}(d.d.default)
        Base.in(key, v::Base.KeySet{K,T}) where {K,T<:$DefaultDict{K}} = key in keys(v.dict.d.d)
    end
end

OrderedCollections.isordered(::Type{T}) where {T<:DefaultOrderedDict} = true

## This should be uncommented to provide a DefaultSortedDict

# struct DefaultSortedDict{K,V,F} <: AbstractDict{K,V}
#     d::DefaultDictBase{K,V,F,SortedDict{K,V}}

#     DefaultSortedDict(x, kv::AbstractArray{(K,V)}) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x, kv))
#     DefaultSortedDict(x, d::DefaultSortedDict) = DefaultSortedDict(x, d.d)
#     DefaultSortedDict(x, d::SortedDict) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x, d))
#     DefaultSortedDict(x) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x))
#     DefaultSortedDict(x, ks, vs) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x,ks,vs))
# end

## Constructors

# DefaultSortedDict() = throw(ArgumentError("DefaultSortedDict: no default specified"))
# DefaultSortedDict(k,v) = throw(ArgumentError("DefaultSortedDict: no default specified"))

# # TODO: these mimic similar Dict constructors, but may not be needed
# DefaultSortedDict{K,V,F}(default::F, ks::AbstractArray{K}, vs::AbstractArray{V}) = DefaultSortedDict{K,V,F}(default,ks,vs)
# DefaultSortedDict{F}(default::F,ks,vs) = DefaultSortedDict{Any,Any,F}(default, ks, vs)

# # syntax entry points
# DefaultSortedDict{F}(default::F) = DefaultSortedDict{Any,Any,F}(default)
# DefaultSortedDict{K,V,F}(::Type{K}, ::Type{V}, default::F) = DefaultSortedDict{K,V,F}(default)
# DefaultSortedDict{K,V,F}(default::F, kv::AbstractArray{(K,V)}) = DefaultSortedDict{K,V,F}(default, kv)

# DefaultSortedDict{F}(default::F, d::AbstractDict) = ((K,V)=eltype(d); DefaultSortedDict{K,V,F}(default, SortedDict(d)))

## Functions

## Most functions are simply delegated to the wrapped DefaultDictBase object

# @delegate DefaultSortedDict.d [ getindex, get, get!, haskey,
#                                 getkey, pop!, start, next,
#                                 done, isempty, length]
# @delegate_return_parent DefaultSortedDict.d [ delete!, empty!, setindex!, sizehint! ]

# similar{K,V,F}(d::DefaultSortedDict{K,V,F}) = DefaultSortedDict{K,V,F}(d.d.default)
# in{T<:DefaultSortedDict}(key, v::Base.KeySet{T}) = key in keys(v.dict.d.d)
