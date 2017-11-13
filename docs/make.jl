using Documenter
using DataStructures


makedocs(
    format = :html,
    sitename = "DataStructures.jl",
    pages = [
        "accumulators.md",
        "circ_deque.md",
        "default_dict.md",
        "disjoint_sets.md",
        "index.md",
        "linked_list.md",
        "priority-queue.md",
        "stack_and_queue.md",
        "circ_buffer.md",
        "deque.md",
        "heaps.md",
        "intset.md",
        "ordered_containers.md",
        "sorted_containers.md",
        "trie.md",
    ]
)

deploydocs(
    repo = "github.com/JuliaCollections/DataStructures.jl",
    julia  = "0.6",
    latest = "master",
    target = "build",
    deps = nothing,  # we use the `format = :html`, without `mkdocs`
    make = nothing,  # we use the `format = :html`, without `mkdocs`
)