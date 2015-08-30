VERSION >= v"0.4.0-dev+6521" && __precompile__()

module DataStructures

    using Compat

    import Base: <, <=, length, isempty, start, next, done,
                 show, dump, empty!, getindex, setindex!, get, get!,
                 in, haskey, keys, merge, copy, cat,
                 push!, pop!, shift!, unshift!, insert!,
                 union!, delete!, similar, sizehint,
                 isequal, hash,
                 map, reverse,
                 first, last, eltype, getkey, values,
                 merge!, lt, Ordering, ForwardOrdering, Forward,
                 ReverseOrdering, Reverse, Lt,
                 isless,
                 union, intersect, symdiff, setdiff, issubset,
                 find, searchsortedfirst, searchsortedlast, endof

    export Deque, Stack, Queue
    export deque, enqueue!, dequeue!, update!,iter
    export capacity, num_blocks, front, back, top, sizehint

    export Accumulator, counter
    export ClassifiedCollections
    export classified_lists, classified_sets, classified_counters

    export IntDisjointSets, DisjointSets, num_groups, find_root, in_same_set
    export push!

    export AbstractHeap, compare, extract_all!
    export BinaryHeap, binary_minheap, binary_maxheap, nlargest, nsmallest
    export MutableBinaryHeap, mutable_binary_minheap, mutable_binary_maxheap

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
    export orderobject, Lt, compare

    export MultiDict, enumerateall

    if VERSION < v"0.4.0-dev"
        using Docile
    end

    include("delegate.jl")

    include("deque.jl")
    include("stack.jl")
    include("queue.jl")
    include("accumulator.jl")
    include("classifiedcollections.jl")
    include("disjoint_set.jl")
    include("heaps.jl")

    include("hashdict.jl")
    include("ordereddict.jl")
    include("orderedset.jl")
    include("defaultdict.jl")
    include("trie.jl")

    include("list.jl")
    include("balancedTree.jl")
    include("tokens.jl")

    import .Tokens: IntSemiToken

    include("multidict.jl")
    include("sortedDict.jl")
    include("sortedMultiDict.jl")
    include("sortedSet.jl")
    include("tokens2.jl")
    include("containerloops.jl")

    export status
    export deref_key, deref_value, deref, advance, regress


    @deprecate stack Stack
    @deprecate queue Queue
    @deprecate add! push!

    @deprecate HashDict{K,V}(ks::AbstractArray{K}, vs::AbstractArray{V}) HashDict{K,V,Unordered}(ks,vs)
    @deprecate HashDict(ks, vs) HashDict{Any,Any,Unordered}(ks, vs)

    @deprecate OrderedDict(ks, vs) OrderedDict(zip(ks,vs))
    @deprecate OrderedDict{K,V}(ks::AbstractArray{K}, vs::AbstractArray{V}) OrderedDict{K,V}(zip(ks,vs))
    @deprecate OrderedDict{K,V}(::Type{K},::Type{V}) OrderedDict{K,V}()

    @deprecate OrderedSet(a, b...) OrderedSet(Any[a, b...])
    @deprecate OrderedSet{T<:Number}(xs::T...)  OrderedSet{T}(xs)      # (almost) mimic Set deprecation in Base
end
