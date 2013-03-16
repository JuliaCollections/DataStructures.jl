# Various heap implementation

###########################################################
#
#   Heap interface specification
#
#   Each heap is associated with a handle type (H), and
#   a value type v. 
#
#   Here, the value type must be comparable, and a handle
#   is an object through which one can refer to a specific
#   node of the heap and thus update its value.
#
#   Each heap type must implement all of the following
#   functions. Here, let h be a heap, i be a handle, and
#   v be a value.
#
#   - length(h)         returns the number of elements
#
#   - isempty(h)        returns whether the heap is
#                       empty
#
#   - add!(h, v)        add a value to the heap
#                       return a handle to the value
#
#   - sizehint(h)       set size hint to a heap
#
#   - top(h)            return the top value of a heap
#
#   - pop!(h)           removes the top value, and
#                       returns it
#
#   - update!(h, i, v)  updates the value of an element 
#                       (referred to by the handle i)
#   
###########################################################

# HT: handle type
# VT: value type  
abstract AbstractHeap{HT,VT}

# comparer

immutable LessThan
end

immutable GreaterThan
end

compare(c::LessThan, x, y) = x < y
compare(c::GreaterThan, x, y) = x > y

# heap implementations

include("heaps/binary_heap.jl")

# generic functions

function extract_all!{HT,VT}(h::AbstractHeap{HT,VT})
    n = length(h)
    r = Array(VT, n)
    for i = 1 : n
        r[i] = pop!(h)
    end
    r
end
