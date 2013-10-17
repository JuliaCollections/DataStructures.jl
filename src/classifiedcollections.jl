# A Classified Collection is a map which associates a collection to each key
#
# The collection can be either an array or a set, a counter, or other data structures
# that support the push! method
#

type ClassifiedCollections{K, Collection}
	map::Dict{K, Collection}
end

## constructors

ClassifiedCollections(K::Type, C::Type) = ClassifiedCollections{K, C}((K=>C)[])

classified_lists(K::Type, V::Type) = ClassifiedCollections(K, Vector{V})
classified_sets(K::Type, V::Type) = ClassifiedCollections(K, Set{V})
classified_counters(K::Type, T::Type) = ClassifiedCollections(K, Accumulator{T, Int})

_create_empty{T}(::Type{Vector{T}}) = Array(T, 0)
_create_empty{T}(::Type{Set{T}}) = Set{T}()
_create_empty{T,V}(::Type{Accumulator{T,V}}) = Accumulator(T, V)

copy{K, C}(cc::ClassifiedCollections{K, C}) = ClassifiedCollections{K, C}(copy(cc.map))

length(cc::ClassifiedCollections) = length(cc.map)

## retrieval

getindex{T,C}(cc::ClassifiedCollections{T,C}, x::T) = cc.map[x]

haskey{T,C}(cc::ClassifiedCollections{T,C}, x::T) = haskey(cc.map, x)

keys(cc::ClassifiedCollections) = keys(cc.map)

## iteration

start(cc::ClassifiedCollections) = start(cc.map)
next(cc::ClassifiedCollections, state) = next(cc.map, state) 
done(cc::ClassifiedCollections, state) = done(cc.map, state)

# manipulation

function add!{K, C}(cc::ClassifiedCollections{K, C}, key::K, e)
	c = get(cc.map, key, nothing)
	if is(c, nothing)
		c = _create_empty(C)
		cc.map[key] = c
	end
	push!(c, e)
end

pop!{K}(cc::Accumulator{K}, key::K) = pop!(cc.map, key)

