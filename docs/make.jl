using Documenter
using DataStructures

DocMeta.setdocmeta!(DataStructures, :DocTestSetup, :(using DataStructures); recursive=true)

makedocs(
    sitename = "DataStructures.jl",
    warnonly = true,  # FIXME: address all warnings and resolve them
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
        "robin_dict.md",
        "swiss_dict.md",
        "trie.md",
        "linked_list.md",
        "mutable_linked_list.md",
        "intset.md",
        "sorted_containers.md",
        "dibit_vector.md",
        "red_black_tree.md",
        "avl_tree.md",
        "splay_tree.md",
    ],
    modules = [DataStructures],
    format = Documenter.HTML()
)

deploydocs(
    repo = "github.com/JuliaCollections/DataStructures.jl.git",
)
