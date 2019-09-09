using Documenter
using DataStructures


makedocs(
    format = :html,
    sitename = "DataStructures.jl",
    pages = [
        "index.md",
        "deque.md",
        "circ_buffer.md",
        "circ_deque.md",
        "stack_and_queue.md",
        "priority-queue.md",
        "fenwick.md",
        "accumulators.md",
        "disjoint_sets.md",
        "heaps.md",
        "ordered_containers.md",
        "default_dict.md",
        "trie.md",
        "linked_list.md",
        "mutable_linked_list.md",
        "intset.md",
        "sorted_containers.md",
    ],
    modules = [DataStructures]
)

deploydocs(
    repo = "github.com/JuliaCollections/DataStructures.jl.git",
)
