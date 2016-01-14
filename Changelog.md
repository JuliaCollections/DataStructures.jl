
v0.4.2 / 2016-01-13
==================

  * Fix OrderedDict constructors (with tests)
  * Add IntSet to DataStructures 
    (see #114, https://github.com/JuliaLang/julia/pull/10065)
  * Dead code, tree.jl removal

v0.4.1 / 2015-12-29
===================

  * Updated Changelog
  * Merge pull request #156 from JuliaLang/kms/remove-v0.3-part2
  * Replace tuple_or_pair with Pair() or Pair{}
  * More thorough removal of v0.3 support
  * Updated Changelog.md

v0.4.1 / 2015-12-29
==================

  * More thorough removal of v0.3 support
  * Replace tuple_or_pair with Pair() or Pair{}

v0.4.0 / 2015-12-28
===================

  * Remove support for Julia 0.3

v0.3.14 / 2015-11-14
====================

  * Accumulator: add sum, values functions
  * OrderedDict:
    * Implement merge for OrderedDict
    * Serialize and deserialize
  * Remove invalid rst and align elements
  * Fix #34, implement `==` instead of `isequal` in places
  * Define ==(x::Nil, y::Nil) and ==(x::Cons, y::Cons)
  * Change eltype of sorted containers to Pair{}

v0.3.13 / 2015-09-18
====================

  * Julia v0.4 updates
    * Union() -> Union{}
    * 0.4 bindings deprecation
    * Add operator imports to fix deprecation warnings
  * Travis
    * Run tests on 0.3, 0.4, and nightly (0.5)
    * Enable osx
    * (Re)enable codecov
  * Additional tests for dequeue, lists
  * Add precompile directive
  * Stack and Queue: make iterable
  * Switched setindex! to insert!
  * Added SortedMultiDict, MultiDict, SortedSet
  * Sorted containers
    * Additional constructors
    * New behavior for 'in' function
  * Fix Pair usage for OrderedDict

v0.3.11 / 2015-07-14
====================

  * Fix deprecated syntax in OrderedSet test
  * Updated README with extra DefaultDict examples
  * More formatting updates to README.rst
  * Remove syntax deprecation warnings on 0.4

v0.3.10 / 2015-06-29
====================

  * REQUIRE: bump Julia version to v0.3
  * Fix serialization ambiguity warnings

v0.3.9 / 2015-05-03
===================

  * Fix error on 0.4-dev, allow running tests without installing

v0.3.8 / 2015-04-18
===================

  * Add special OrderedDict deprection for Numbers
  * Fix warning about {A, B...}

v0.3.7 / 2015-04-17
===================

  * 0.4 Compat fixes
  * Implement nlargest and nsmallest

v0.3.6 / 2015-03-05
===================

  * Updated OrderedSet, OrderedDict tests
  * Update OrderedDict, OrderedSet constructors to take iterables
  * Use Julia 0.4 syntax
  * Added compat support for Julia v0.3
  * Added all SortedDict/balanced tree code and tests
  * Rewrite README in rst format (instead of md)
  * Get coverage data generation back up for Coveralls
  * Update Travis to use Julia Language Support
  * use Base.warn_once() instead of warn()
  * Support v0.4 style association construction via Pair operator
  * Update syntax to avoid deprecation warnings on Julia 0.4
  * Make DefaultDictBase signature valid on Julia master
  * Consistent whitespace

v0.3.4 / 2014-10-14
===================

  * Fix #60
  * Update Dict construction to use new syntax
  * Fix signed/unsigned issue in hashindex
  * Modernize Travis, Pkg.test compat, coverage, badges

v0.3.2 / 2014-08-31
===================

  * Add documentation for new Trie methods
  * Remove trailing whitespace
  * Add path(::Trie, ::String)
  * Add more constructors for Trie
  * Remove trailing whitespace
  * README: DisjointSet -> DisjointSets
  * IntDisjointSets: use bounds-checking on user-supplied indices

v0.3.1 / 2014-07-14
===================

  * Update README
  * Deprecate add\! in favor of push\!

v0.3.0 / 2014-06-10
===================

  * Bump REQUIRE to v0.3, for incompatible change in test_throws

v0.2.15 / 2014-06-10
====================

  * Revert "fix `@test_throw` warnings"

v0.2.14 / 2014-06-02
====================

  * Import serialize_type in hashdict.jl
  * Fixes #38, error in `empty!` for Deque.
  * Add some clarification on code examples
  * remove a code_native statement in disjoint_set.jl
  * fix `@test_throw` warnings
  * slight performance improvement of Disjoint set implementation
  * use SVG logo for travis status
  * rename run_tests.jl to runtests.jl

v0.2.13 / 2014-05-08
====================

  * Revert "Remove unused code"
  * Fix broken tests
  * Add test for similar(DefaultDict)
  * Fix similar for DefaultDict
  * Remove trailing spaces from defaultdict.jl

v0.2.12 / 2014-04-26
====================

  * Import Base.reverse
  * Fix README for Trie.
  * LinkedList cat function is more efficient and returns a list of the nearest common supertype
  * Renamed List type to LinkedList. Map function can generate a list of elements of a different type. No more stack overflows.
  * Implemented filter and reverse functions for list
  * Implemented tests for list.jl
  * Inserted missing comma
  * Added linked list to readme
  * Add linked list to module
  * Allow iteration on empty list
  * Avoid stack overflow in length method. Use iterator in show method
  * Changed name from add_singleton! to push!
  * Update README.md

v0.2.11 / 2014-04-10
====================

  * Update README.md (closes #24)
  * Add trie to initial list
  * Changed the name make_set to add_singleton
  * import serialize, deserialize
  * Update Trie tests.
  * Clean up code. Follow Dict interface more closely.
  * Added working test of make_set!
  * Added make_set! to exports in DataStructures.jl
  * Added make_set! for arbitrary typed DisjointSets
  * Changed length(s.parents) to length(s)
  * Added version of make_set! which automatically chooses the new element as the next available one
  * Added ! to the name of the make_set function, since it modifies the structure
  * Added make_set to add single element as a new disjoint set, with its parent equal to itself
  * Implemented list iterator functions
  * add list and binary tree. closes #17
  * moving Trie to DataStructures

v0.2.10 / 2014-03-02
====================

  * Revert "Update REQUIRE to julia v0.3"

v0.2.9 / 2014-02-26
===================

  * Update REQUIRE to julia v0.3
  * Update README.md
  * Add deprecation for queue/stack
  * Change queue/stack to Queue/Stack. Partially fixes #8.
  * Remove uses of dequeue
  * Fix travis config. Enable testing with releases.
  * Change Travis badge url to JuliaLang
  * fix function argument annotation of push! and unshift! for deque
  * README.md: OrderedDefaultDict -> DefaultOrderedDict
  * fix C++ template syntax in README
  * Added/updated various dictionary, set variants
  * Updated DefaultDict
  * Added DefaultDict
  * update travis.yml (disable apt-get upgrade)
  * add classified counters
  * add classified collections

v0.2.6 / 2013-10-10
===================

  * add length method for Accumulator
  * add a test of keys for accumulator

v0.2.5 / 2013-10-08
===================

  * add accumulators/counters doc
  * add accumulator tests to run_tests.jl
  * add accumulator
  * add @inbounds statement for heaps
  * add benchmark for deque traversal
  * add @inbounds to critical statements in deque
  * add @inbounds to disjoint sets
  * improved benchmark scripts

0.2.4 / 2013-07-27
==================

  * add travis logo to readme
  * add travis.yml
  * use run_tests.jl in the place of test/test_all.jl
  * Revised implementation of Deque, without using Union(Nothing, DequeBlock).
  * Fixed the doc regarding API for heaps: binary_heap -> binary_{min|max}heap and mutable_binary_heap -> mutable_binary_{min|max}heap
  * Added 1 missing API call to the documentation
  * Fixed bugs related to Dequeue functions front and back. 
    * Front would give garbage data when called on a newly created queue, and back when popping a queue from the front.
  * Implemented simple show method inside Dequeue to hide unnecessary (large!) implementation detail from the client, in particular when using REPL

0.2.3 / 2013-04-21
==================

  * export in_same_set
  * mutable heap declaration change

0.2.0 / 2013-04-15
==================

  * add julia version requirement
  * Test ==> Base.Test & add test_all.jl
  * add empty REQUIRE file
  * Update README.md
  * add license
  * add readme
  * add binary_heap (tested)
  * binary_heap ==> mutable_binary_heap
  * improved interface and added test
  * modified bench_heaps
  * add bench_heaps
  * add binary heap (tested)
  * add disjoint_set of arbitrary types
  * add integer disjoint set
  * change names to conform to Dequeue interface
  * change default block size, which seems a good balance
  * renamed to DataStructures
  * add stack and queue (tested)
  * add Dequeue (tested)
  * Initial commit

