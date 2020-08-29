## These functions define the possible iterations for the
## sorted containers.
## The prefix SDM is for SortedDict and SortedMultiDict
## The prefix SS is for SortedSet.  The prefix SA
## is for all sorted containers.
## The following two definitions now appear in tokens2.jl

# const SDMContainer = Union{SortedDict, SortedMultiDict}
# const SAContainer = Union{SDMContainer, SortedSet}

extractcontainer(s::SAContainer) = s
getrangeobj(s::SAContainer) = s


## This holds an object describing an exclude-last
## iteration.


abstract type AbstractExcludeLast{ContainerType <: SAContainer} end

struct SDMExcludeLast{ContainerType <: SDMContainer} <:
                              AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end

Base.keytype(::SDMExcludeLast{T}) where {T <: SAContainer} = keytype(T)
Base.keytype(::Type{SDMExcludeLast{T}}) where {T <: SAContainer} = keytype(T)
Base.valtype(::SDMExcludeLast{T}) where {T <: SAContainer} = valtype(T)
Base.valtype(::Type{SDMExcludeLast{T}}) where {T <: SAContainer} = valtype(T)
Base.eltype(::SDMExcludeLast{T}) where {T <: SAContainer} = eltype(T)
Base.eltype(::Type{SDMExcludeLast{T}}) where {T <: SAContainer} = eltype(T)


struct SSExcludeLast{ContainerType <: SortedSet} <:
                              AbstractExcludeLast{ContainerType}
    m::ContainerType
    first::Int
    pastlast::Int
end

Base.eltype(::SSExcludeLast{T}) where {T <: SortedSet} = eltype(T)
Base.eltype(::Type{SSExcludeLast{T}}) where {T <: SortedSet} = eltype(T)


extractcontainer(s::AbstractExcludeLast) = s.m
getrangeobj(s::AbstractExcludeLast) = s

## This holds an object describing an include-last
## iteration.

abstract type AbstractIncludeLast{ContainerType <: SAContainer} end


struct SDMIncludeLast{ContainerType <: SDMContainer} <:
                               AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end

Base.keytype(::SDMIncludeLast{T}) where {T <: SAContainer} = keytype(T)
Base.keytype(::Type{SDMIncludeLast{T}}) where {T <: SAContainer} = keytype(T)
Base.valtype(::SDMIncludeLast{T}) where {T <: SAContainer} = valtype(T)
Base.valtype(::Type{SDMIncludeLast{T}}) where {T <: SAContainer} = valtype(T)
Base.eltype(::SDMIncludeLast{T}) where {T <: SAContainer} = eltype(T)
Base.eltype(::Type{SDMIncludeLast{T}}) where {T <: SAContainer} = eltype(T)


struct SSIncludeLast{ContainerType <: SortedSet} <:
                               AbstractIncludeLast{ContainerType}
    m::ContainerType
    first::Int
    last::Int
end

Base.eltype(::SSIncludeLast{T}) where {T <: SortedSet} = eltype(T)
Base.eltype(::Type{SSIncludeLast{T}}) where {T <: SortedSet} = eltype(T)


extractcontainer(s::AbstractIncludeLast) = s.m
getrangeobj(s::AbstractIncludeLast) = s


Base.IteratorSize(::Type{T} where {T <: SAContainer}) = HasLength()
Base.IteratorSize(::Type{T} where {T <: AbstractExcludeLast}) = SizeUnknown()
Base.IteratorSize(::Type{T} where {T <: AbstractIncludeLast}) = SizeUnknown()


## The basic iterations are either over the whole sorted container, an
## exclude-last object or include-last object.

const SDMIterableTypesBase = Union{SDMContainer,
                                   SDMExcludeLast,
                                   SDMIncludeLast}

const SSIterableTypesBase = Union{SortedSet,
                                  SSExcludeLast,
                                  SSIncludeLast}


const SAIterableTypesBase = Union{SAContainer,
                                  AbstractExcludeLast,
                                  AbstractIncludeLast}


## The compound iterations are obtained by applying keys(..) or values(..)
## to the basic iterations of the SDM.. type.
## Furthermore, semitokens(..) can be applied
## to either a basic iteration or a keys/values iteration.

struct SDMKeyIteration{T <: SDMIterableTypesBase}
    base::T
end

Base.eltype(::Type{SDMKeyIteration{T}}) where {T} = keytype(T)
Base.eltype(s::SDMKeyIteration) = keytype(extractcontainer(s.base))
Base.length(s::SDMKeyIteration{T} where T <: SDMContainer) = length(extractcontainer(s.base))


struct SDMValIteration{T <: SDMIterableTypesBase}
    base::T
end

Base.eltype(::Type{SDMValIteration{T}}) where {T} = valtype(T)
Base.eltype(s::SDMValIteration) = valtype(extractcontainer(s.base))
Base.length(s::SDMValIteration{T} where T <: SDMContainer) = length(extractcontainer(s.base))


struct SDMSemiTokenIteration{T <: SDMIterableTypesBase}
    base::T
end

Base.eltype(::Type{SDMSemiTokenIteration{T}}) where {T} =
    Tuple{IntSemiToken, keytype(T), valtype(T)}
Base.eltype(s::SDMSemiTokenIteration) = Tuple{IntSemiToken,
                                         keytype(extractcontainer(s.base)),
                                         valtype(extractcontainer(s.base))}
Base.length(s::SDMSemiTokenIteration{T} where T <: SDMContainer) = length(s.base)


struct SSSemiTokenIteration{T <: SSIterableTypesBase}
    base::T
end

Base.eltype(::Type{SSSemiTokenIteration{T}}) where {T} =
    Tuple{IntSemiToken, eltype(T)}
Base.eltype(s::SSSemiTokenIteration) = Tuple{IntSemiToken,
                                        eltype(extractcontainer(s.base))}
Base.length(s::SSSemiTokenIteration{T} where T <: SortedSet) = length(s.base)


struct SDMSemiTokenKeyIteration{T <: SDMIterableTypesBase}
    base::T
end

Base.eltype(::Type{SDMSemiTokenKeyIteration{T}}) where {T} =
    Tuple{IntSemiToken,
          keytype(T)}
Base.eltype(s::SDMSemiTokenKeyIteration) = Tuple{IntSemiToken,
                                            keytype(extractcontainer(s.base))}
Base.length(s::SDMSemiTokenKeyIteration{T} where T <: SDMContainer) = length(s.base)

struct SAOnlySemiTokensIteration{T <: SAIterableTypesBase}
    base::T
end

Base.eltype(::Type{SAOnlySemiTokensIteration{T}} where {T}) = IntSemiToken
Base.eltype(::SAOnlySemiTokensIteration) = IntSemiToken
Base.length(s::SAOnlySemiTokensIteration{T} where T <: SAContainer) = length(s.base)

struct SDMSemiTokenValIteration{T <: SDMIterableTypesBase}
    base::T
end

Base.eltype(::Type{SDMSemiTokenValIteration{T}}) where {T} =
    Tuple{IntSemiToken, valtype(T)}
Base.eltype(s::SDMSemiTokenValIteration) = Tuple{IntSemiToken,
                                            valtype(extractcontainer(s.base))}
Base.length(s::SDMSemiTokenValIteration{T} where T <: SDMContainer) = length(s.base)

const SACompoundIterable = Union{SDMKeyIteration,
                                 SDMValIteration,
                                 SDMSemiTokenIteration,
                                 SSSemiTokenIteration,
                                 SDMSemiTokenKeyIteration,
                                 SDMSemiTokenValIteration,
                                 SAOnlySemiTokensIteration}

extractcontainer(s::SACompoundIterable) = extractcontainer(s.base)
getrangeobj(s::SACompoundIterable) = getrangeobj(s.base)

const SAIterable = Union{SAIterableTypesBase, SACompoundIterable}


Base.IteratorEltype(::Type{T} where {T <: SAIterable}) = HasEltype()
Base.IteratorSize(::Type{SDMKeyIteration{T}}) where {T} = IteratorSize(T)
Base.IteratorSize(::Type{SDMValIteration{T}}) where {T} = IteratorSize(T)
Base.IteratorSize(::Type{SDMSemiTokenIteration{T}}) where {T} = IteratorSize(T)
Base.IteratorSize(::Type{SSSemiTokenIteration{T}}) where {T} = IteratorSize(T)
Base.IteratorSize(::Type{SDMSemiTokenKeyIteration{T}}) where {T} = IteratorSize(T)
Base.IteratorSize(::Type{SDMSemiTokenValIteration{T}}) where {T} = IteratorSize(T)
Base.IteratorSize(::Type{SAOnlySemiTokensIteration{T}}) where {T} = IteratorSize(T)


## All the loops maintain a state which is an object of the
## following type.

struct SAIterationState
    next::Int
    final::Int
end


exclusive(m::SDMContainer, ii::Tuple{IntSemiToken,IntSemiToken}) =
    SDMExcludeLast(m, ii[1].address, ii[2].address)
exclusive(m::SortedSet, ii::Tuple{IntSemiToken,IntSemiToken}) =
    SSExcludeLast(m, ii[1].address, ii[2].address)
exclusive(m::SAContainer, i1::IntSemiToken, i2::IntSemiToken) =
    exclusive(m, (i1, i2))

inclusive(m::SDMContainer, ii::Tuple{IntSemiToken,IntSemiToken}) =
    SDMIncludeLast(m, ii[1].address, ii[2].address)
inclusive(m::SortedSet, ii::Tuple{IntSemiToken,IntSemiToken}) =
    SSIncludeLast(m, ii[1].address, ii[2].address)
inclusive(m::SAContainer, i1::IntSemiToken, i2::IntSemiToken) =
    inclusive(m, (i1, i2))


# Next definition needed to break ambiguity with keys(AbstractDict) from Dict.jl

Base.keys(ba::SortedDict) = SDMKeyIteration(ba)
Base.keys(ba::SDMIterableTypesBase) = SDMKeyIteration(ba)


Base.in(k, keyit::SDMKeyIteration{SortedDict{K,D,Ord}} where {K,D,Ord}) =
    haskey(extractcontainer(keyit.base), k)

Base.in(k, keyit::SDMKeyIteration{SortedMultiDict{K,D,Ord}} where {K,D,Ord}) =
    haskey(extractcontainer(keyit.base), k)


# Next definition needed to break ambiguity with values(AbstractDict) from Dict.jl
Base.values(ba::SortedDict) = SDMValIteration(ba)
Base.values(ba::SDMIterableTypesBase) = SDMValIteration(ba)
semitokens(ba::SDMIterableTypesBase) = SDMSemiTokenIteration(ba)
semitokens(ba::SSIterableTypesBase) = SSSemiTokenIteration(ba)
semitokens(ki::SDMKeyIteration) = SDMSemiTokenKeyIteration(ki.base)
semitokens(vi::SDMValIteration) = SDMSemiTokenValIteration(vi.base)
onlysemitokens(ba::SAIterableTypesBase) = SAOnlySemiTokensIteration(ba)


function nexthelper(c::SAContainer, state::SAIterationState)
    sn = state.next
    (sn < 3 || !(sn in c.bt.useddatacells)) && throw(BoundsError())
    SAIterationState(nextloc0(c.bt, sn), state.final)
end


getitem(::SDMIterableTypesBase, dt, sn) = dt.k => dt.d
getitem(::SSIterableTypesBase, dt, sn) = dt.k
getitem(::SDMKeyIteration, dt, sn) = dt.k
getitem(::SDMValIteration, dt, sn) = dt.d
getitem(::SDMSemiTokenIteration, dt, sn) = (IntSemiToken(sn), dt.k, dt.d)
getitem(::SSSemiTokenIteration, dt, sn) = (IntSemiToken(sn), dt.k)
getitem(::SDMSemiTokenKeyIteration, dt, sn) = (IntSemiToken(sn), dt.k)
getitem(::SDMSemiTokenValIteration, dt, sn) = (IntSemiToken(sn), dt.d)
getitem(::SAOnlySemiTokensIteration, dt, sn) = IntSemiToken(sn)


function get_init_state(e::AbstractExcludeLast)
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
     !(e.pastlast in e.m.bt.useddatacells)) &&
     throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.pastlast) < 0
        return SAIterationState(e.first, e.pastlast)
    else
        return SAIterationState(2, 2)
    end
end

function get_init_state(e::AbstractIncludeLast)
    (!(e.first in e.m.bt.useddatacells) || e.first == 1 ||
     !(e.last in e.m.bt.useddatacells) || e.last == 2) &&
     throw(BoundsError())
    if compareInd(e.m.bt, e.first, e.last) <= 0
        return SAIterationState(e.first, nextloc0(e.m.bt, e.last))
    else
        return SAIterationState(2, 2)
    end
end

get_init_state(m::SAContainer) = SAIterationState(beginloc(m.bt), 2)

function Base.iterate(s::SAIterable, state = get_init_state(getrangeobj(s)))
    if state.next == state.final
        return nothing
    else
        c = extractcontainer(s)
        dt = isa(s, SAOnlySemiTokensIteration) ? nothing : c.bt.data[state.next]
        return (getitem(s, dt, state.next),
                nexthelper(c, state))
    end
end


Base.eachindex(sd::SortedDict) = keys(sd)
Base.eachindex(sdm::SortedMultiDict) = onlysemitokens(sdm)
Base.eachindex(ss::SortedSet) = onlysemitokens(ss)
Base.eachindex(sd::SDMExcludeLast{SortedDict{K,D,Ord}} where {K,D,Ord <: Ordering}) = keys(sd)
Base.eachindex(smd::SDMExcludeLast{SortedMultiDict{K,D,Ord}} where {K,D,Ord <: Ordering}) =
     onlysemitokens(smd)
Base.eachindex(ss::SSExcludeLast) = onlysemitokens(ss)
Base.eachindex(sd::SDMIncludeLast{SortedDict{K,D,Ord}} where {K,D,Ord <: Ordering}) = keys(sd)
Base.eachindex(smd::SDMIncludeLast{SortedMultiDict{K,D,Ord}} where {K,D,Ord <: Ordering}) =
     onlysemitokens(smd)
Base.eachindex(ss::SSIncludeLast) = onlysemitokens(ss)


Base.empty!(m::SAContainer) =  empty!(m.bt)
Base.length(m::SAContainer) = length(m.bt.data) - length(m.bt.freedatainds) - 2
Base.isempty(m::SAContainer) = length(m) == 0
