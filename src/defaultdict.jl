# Dictionary which returns (and sets) a default value for a requested item not
# already in to the dictionary

# DefaultDictBase is the main class used to in Default*Dicts.
#
# Each related (immutable) Default*Dict class contains a single
# DefautlDictBase object as a member, and delegates almost all
# functions to this object.
#
# The main rationale for doing this instead of using type aliases is
# that this way, we can have actual class names and constructors for
# each of the DefaultDictBase "subclasses", in some sense getting
# around the Julia limitation of not allowing concrete classes to be
# subclassed.
#

immutable DefaultDictBase{K,V,F,D} <: Associative{K,V}
    default::F
    d::D

    check_D(D,K,V) = (D <: Associative{K,V}) ||
        error("Default dict must be <: Associative{K,V}")

    DefaultDictBase(x::F, kv::AbstractArray{@compat Tuple{K,V}}) = (check_D(D,K,V); new(x, D(kv)))
    if VERSION >= v"0.4.0-dev+980"
        DefaultDictBase(x::F, ps::Pair{K,V}...) = (check_D(D,K,V); new(x, D(ps...)))
    end

    DefaultDictBase(x::F, d::DefaultDictBase) = (check_D(D,K,V); DefaultDictBase(x, d.d))
    DefaultDictBase(x::F, d::D=D()) = (check_D(D,K,V); new(x, d))
    DefaultDictBase(x, ks, vs) = (check_D(D,K,V); new(x, D(ks,vs)))
end

# Constructors

DefaultDictBase() = error("no default specified")
DefaultDictBase(k,v) = error("no default specified")

# TODO: these mimic similar Dict constructors, but may not be needed
DefaultDictBase{K,V,F}(default::F, ks::AbstractArray{K}, vs::AbstractArray{V}) =
    DefaultDictBase{K,V,F,Dict{K,V}}(default,ks,vs)
DefaultDictBase{F}(default::F,ks,vs) = DefaultDictBase{Any,Any,F,Dict}(default, ks, vs)

# syntax entry points
DefaultDictBase{F}(default::F) = DefaultDictBase{Any,Any,F,Dict}(default)
DefaultDictBase{K,V,F}(::Type{K}, ::Type{V}, default::F) = DefaultDictBase{K,V,F,Dict}(default)
DefaultDictBase{K,V,F}(default::F, kv::AbstractArray{@compat Tuple{K,V}}) = DefaultDictBase{K,V,F,Dict}(default, kv)

if VERSION >= v"0.4.0-dev+980"
    DefaultDictBase{K,V,F}(default::F, ps::Pair{K,V}...) = DefaultDictBase{K,V,F,Dict}(default, ps...)
end

DefaultDictBase{F,D<:Associative}(default::F, d::D) = ((K,V)=eltype(d); DefaultDictBase{K,V,F,D}(default, d))

# Functions

# most functions are simply delegated to the wrapped dictionary
@delegate DefaultDictBase.d [ sizehint, empty!, setindex!, get, haskey,
                             getkey, pop!, delete!, start, done, next,
                             isempty, length ]

similar{K,V,F}(d::DefaultDictBase{K,V,F}) = DefaultDictBase{K,V,F}(d.default)
in{T<:DefaultDictBase}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d)
next{T<:DefaultDictBase}(v::Base.KeyIterator{T}, i) = (v.dict.d.keys[i], Base.skip_deleted(v.dict.d,i+1))
next{T<:DefaultDictBase}(v::Base.ValueIterator{T}, i) = (v.dict.d.vals[i], Base.skip_deleted(v.dict.d,i+1))

getindex(d::DefaultDictBase, key) = get!(d.d, key, d.default)

# TODO: remove this if/when minimum julia version is 0.3 or greater
if !applicable(get!, (Dict,))
    global getindex
    function getindex{K,V,F<:Base.Callable}(d::DefaultDictBase{K,V,F,Dict}, key)
        if !haskey(d.d, key)
            return (d.d[key] = d.default())
        end
        return d.d[key]
    end

    function getindex{K,V,F}(d::DefaultDictBase{K,V,F,Dict}, key)
        if !haskey(d.d, key)
            return (d.d[key] = d.default)
        end
        return d.d[key]
    end
end


################

# Here begins the actual definition of the DefaultDict and
# DefaultOrderedDict classes.  As noted above, these are simply
# wrappers around a DefaultDictBase object, and delegate all functions
# to that object

for (DefaultDict,O) in [(:DefaultDict, :Unordered), (:DefaultOrderedDict, :Ordered)]
    @eval begin
        immutable $DefaultDict{K,V,F} <: Associative{K,V}
            d::DefaultDictBase{K,V,F,HashDict{K,V,$O}}

            if VERSION >= v"0.4.0-dev+980"
                $DefaultDict(x, ps::Pair{K,V}...) = new(DefaultDictBase{K,V,F,HashDict{K,V,$O}}(x, ps...))
            end
            $DefaultDict(x, kv::AbstractArray{@compat Tuple{K,V}}) = new(DefaultDictBase{K,V,F,HashDict{K,V,$O}}(x, kv))
            $DefaultDict(x, d::$DefaultDict) = $DefaultDict(x, d.d)
            $DefaultDict(x, d::HashDict) = new(DefaultDictBase{K,V,F,HashDict{K,V,$O}}(x, d))
            $DefaultDict(x) = new(DefaultDictBase{K,V,F,HashDict{K,V,$O}}(x))
            $DefaultDict(x, ks, vs) = new(DefaultDictBase{K,V,F,HashDict{K,V,$O}}(x,ks,vs))
        end

        ## Constructors

        $DefaultDict() = error("$DefaultDict: no default specified")
        $DefaultDict(k,v) = error("$DefaultDict: no default specified")

        # TODO: these mimic similar Dict constructors, but may not be needed
        $DefaultDict{K,V,F}(default::F, ks::AbstractArray{K}, vs::AbstractArray{V}) = $DefaultDict{K,V,F}(default,ks,vs)
        $DefaultDict{F}(default::F,ks,vs) = $DefaultDict{Any,Any,F}(default, ks, vs)

        # syntax entry points
        $DefaultDict{F}(default::F) = $DefaultDict{Any,Any,F}(default)
        $DefaultDict{K,V,F}(::Type{K}, ::Type{V}, default::F) = $DefaultDict{K,V,F}(default)
        $DefaultDict{K,V,F}(default::F, kv::AbstractArray{@compat Tuple{K,V}}) = $DefaultDict{K,V,F}(default, kv)
        if VERSION >= v"0.4.0-dev+980"
            $DefaultDict{K,V,F}(default::F, ps::Pair{K,V}...) = $DefaultDict{K,V,F}(default, ps...)
        end

        if VERSION < v"0.4.0-dev+4139"
            $DefaultDict{F}(default::F, d::Associative) = ((K,V)=eltype(d); $DefaultDict{K,V,F}(default, HashDict(d)))
        else
            $DefaultDict{F}(default::F, d::Associative) = ((K,V)= (Base.keytype(d), Base.valtype(d)); $DefaultDict{K,V,F}(default, HashDict(d)))
        end

        ## Functions

        # Most functions are simply delegated to the wrapped DefaultDictBase object
        @delegate $DefaultDict.d [ sizehint, empty!, setindex!,
                                   getindex, get, get!, haskey,
                                   getkey, pop!, delete!, start, next,
                                   done, isempty, length ]

        similar{K,V,F}(d::$DefaultDict{K,V,F}) = $DefaultDict{K,V,F}(d.d.default)
        in{T<:$DefaultDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d.d)
    end
end


## If/when a SortedDict becomes available, this should be uncommented to provide a DefaultSortedDict

# immutable DefaultSortedDict{K,V,F} <: Associative{K,V}
#     d::DefaultDictBase{K,V,F,SortedDict{K,V}}

#     DefaultSortedDict(x, kv::AbstractArray{(K,V)}) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x, kv))
#     DefaultSortedDict(x, d::DefaultSortedDict) = DefaultSortedDict(x, d.d)
#     DefaultSortedDict(x, d::SortedDict) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x, d))
#     DefaultSortedDict(x) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x))
#     DefaultSortedDict(x, ks, vs) = new(DefaultDictBase{K,V,F,SortedDict{K,V}}(x,ks,vs))
# end

## Constructors

# DefaultSortedDict() = error("DefaultSortedDict: no default specified")
# DefaultSortedDict(k,v) = error("DefaultSortedDict: no default specified")

# # TODO: these mimic similar Dict constructors, but may not be needed
# DefaultSortedDict{K,V,F}(default::F, ks::AbstractArray{K}, vs::AbstractArray{V}) = DefaultSortedDict{K,V,F}(default,ks,vs)
# DefaultSortedDict{F}(default::F,ks,vs) = DefaultSortedDict{Any,Any,F}(default, ks, vs)

# # syntax entry points
# DefaultSortedDict{F}(default::F) = DefaultSortedDict{Any,Any,F}(default)
# DefaultSortedDict{K,V,F}(::Type{K}, ::Type{V}, default::F) = DefaultSortedDict{K,V,F}(default)
# DefaultSortedDict{K,V,F}(default::F, kv::AbstractArray{(K,V)}) = DefaultSortedDict{K,V,F}(default, kv)

# DefaultSortedDict{F}(default::F, d::Associative) = ((K,V)=eltype(d); DefaultSortedDict{K,V,F}(default, SortedDict(d)))

## Functions

## Most functions are simply delegated to the wrapped DefaultDictBase object

# @delegate DefaultSortedDict.d [ sizehint, empty!, setindex!,
#                            getindex, get, get!, haskey,
#                            getkey, pop!, delete!, start, next,
#                            done, isempty, length]

# similar{K,V,F}(d::DefaultSortedDict{K,V,F}) = DefaultSortedDict{K,V,F}(d.d.default)
# in{T<:DefaultSortedDict}(key, v::Base.KeyIterator{T}) = key in keys(v.dict.d.d)
