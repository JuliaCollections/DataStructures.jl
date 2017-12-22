__precompile__()

module DataStructures

    import Base: <, <=, ==, length, isempty, start, next, done, delete!,
                 show, dump, empty!, getindex, setindex!, get, get!,
                 in, haskey, keys, merge, copy, cat,
                 push!, pop!, shift!, unshift!, insert!,
                 union!, delete!, similar, sizehint!,
                 isequal, hash,
                 map, reverse,
                 first, last, eltype, getkey, values, sum,
                 merge, merge!, lt, Ordering, ForwardOrdering, Forward,
                 ReverseOrdering, Reverse, Lt,
                 isless,
                 union, intersect, symdiff, setdiff, issubset,
                 find, searchsortedfirst, searchsortedlast, endof, in

    using Compat: uninitialized, Nothing, Cvoid, AbstractDict

    export Deque, Stack, Queue, CircularDeque
    export deque, enqueue!, dequeue!, dequeue_pair!, update!, reverse_iter
    export capacity, num_blocks, front, back, top, top_with_handle, sizehint!

    export Accumulator, counter, reset!, inc!, dec!

    export ClassifiedCollections
    export classified_lists, classified_sets, classified_counters

    export IntDisjointSets, DisjointSets, num_groups, find_root, in_same_set, root_union!

    export AbstractHeap, compare, extract_all!
    export BinaryHeap, binary_minheap, binary_maxheap, nlargest, nsmallest
    export MutableBinaryHeap, mutable_binary_minheap, mutable_binary_maxheap
    export heapify!, heapify, heappop!, heappush!, isheap

    export OrderedDict, OrderedSet
    export DefaultDict, DefaultOrderedDict
    export Trie, subtrie, keys_with_prefix, path

    export LinkedList, Nil, Cons, nil, cons, head, tail, list, filter, cat,
           reverse
    export SortedDict, SortedMultiDict, SortedSet
    export SDToken, SDSemiToken, SMDToken, SMDSemiToken
    export SetToken, SetSemiToken
    export startof
    export pastendsemitoken, beforestartsemitoken
    export searchsortedafter, searchequalrange
    export packcopy, packdeepcopy
    export exclusive, inclusive, semitokens
    export orderobject, ordtype, Lt, compare, onlysemitokens

    export MultiDict, enumerateall

    import Base: eachindex, keytype, valtype

    include("delegate.jl")

    include("deque.jl")
    include("circ_deque.jl")
    include("stack.jl")
    include("queue.jl")
    include("accumulator.jl")
    include("classified_collections.jl")
    include("disjoint_set.jl")
    include("heaps.jl")

    include("dict_support.jl")
    include("ordered_dict.jl")
    include("ordered_set.jl")
    include("default_dict.jl")
    include("trie.jl")

    include("int_set.jl")

    include("list.jl")
    include("balanced_tree.jl")
    include("tokens.jl")

    import .Tokens: IntSemiToken

    include("multi_dict.jl")
    include("sorted_dict.jl")
    include("sorted_multi_dict.jl")
    include("sorted_set.jl")
    include("tokens2.jl")
    include("container_loops.jl")

    include("dict_sorting.jl")

    export
        CircularBuffer,
        capacity,
        isfull
    include("circular_buffer.jl")

    export status
    export deref_key, deref_value, deref, advance, regress

    export PriorityQueue, peek

    include("priorityqueue.jl")

    # Deprecations

    # Remove when Julia 0.7 (or whatever version is after v0.6) is released
    @deprecate DefaultDictBase(default, ks::AbstractArray, vs::AbstractArray) DefaultDictBase(default, zip(ks, vs))
    @deprecate DefaultDictBase(default, ks, vs) DefaultDictBase(default, zip(ks, vs))
    @deprecate DefaultDictBase(::Type{K}, ::Type{V}, default) where {K,V} DefaultDictBase{K,V}(default)

    @deprecate DefaultDict(default, ks, vs) DefaultDict(default, zip(ks, vs))
    @deprecate DefaultDict(::Type{K}, ::Type{V}, default) where {K,V} DefaultDict{K,V}(default)

    @deprecate DefaultOrderedDict(default, ks, vs) DefaultOrderedDict(default, zip(ks, vs))
    @deprecate DefaultOrderedDict(::Type{K}, ::Type{V}, default) where {K,V} DefaultOrderedDict{K,V}(default)

    function SortedMultiDict(ks::AbstractVector{K},
                             vs::AbstractVector{V},
                             o::Ordering=Forward) where {K,V}
        Base.depwarn("SortedMultiDict(ks, vs, o::Ordering=Forward) is deprecated.\n" * "Use SortedMultiDict(o, zip(ks,vs)) or SortedMultiDict(zip(ks, vs))", :SortedMultiDict)
        if length(ks) != length(vs)
            throw(ArgumentError("SortedMultiDict(ks,vs,o): ks and vs arrays must be the same length"))
        end
        SortedMultiDict(o, zip(ks,vs))
    end

    @deprecate PriorityQueue(::Type{K}, ::Type{V}) where {K,V} PriorityQueue{K,V}()
    @deprecate PriorityQueue(::Type{K}, ::Type{V}, o::Ordering) where {K,V} PriorityQueue{K,V,typeof(o)}(o)
    @deprecate (PriorityQueue{K,V,ForwardOrdering}() where {K,V}) PriorityQueue{K,V}()

    function PriorityQueue(ks::AbstractVector{K},
                           vs::AbstractVector{V},
                           o::Ordering=Forward) where {K,V}
        Base.depwarn("PriorityQueue(ks, vs, o::Ordering=Forward) is deprecated.\n" * "Use PriorityQueue(o, zip(ks,vs)) or PriorityQueue(zip(ks, vs))", :PriorityQueue)
        if length(ks) != length(vs)
            throw(ArgumentError("PriorityQueue(ks,vs,o): ks and vs arrays must be the same length"))
        end
        PriorityQueue(o, zip(ks,vs))
    end

end
