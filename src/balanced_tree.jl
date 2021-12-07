## This file implements 2-3 trees for sorted containers.
## The types and functions in this file are not exported; they
## are meant to be used by SortedDict, MultiMap and SortedSet.
## A 2-3 tree is a rooted trees in which all leaves are at the same
## depth (i.e., it is "balanced")
## and in which each internal node of the tree has either 2 or 3
## children.
## All the internal tree
## nodes are stored in an array of TreeNodes.  The bottom layer
## of internal tree nodes,
## called the "leaves" in this file, sit above one more layer
## of data nodes, which are stored in a different array.


## KDRec is one data node:
##  k: the key of the node
##  d: the data of the node
##  parent: the tree leaf that is the parent of this
##    node.  Parent pointers are needed in order
##    to implement tokens.
##  There are two constructors, the standard one (first)
##  and the incomplete one (second).  The incomplete constructor
##  is needed because when the data structure is first created,
##  there are no valid K or D values to store in the initial
##  data nodes.


macro invariant(expr)
end

macro invariant_support_statement(expr)
end


struct KDRec{K,D}
    parent::Int
    k::K
    d::D
    KDRec{K,D}(p::Int, k1::K, d1::D) where {K,D} = new{K,D}(p,k1,d1)
    KDRec{K,D}(p::Int) where {K,D} = new{K,D}(p)
end

## TreeNode is an internal node of the tree.
## child1,child2,child3:
##     These are the three children node numbers.
##     If the node is a 2-node (rather than 3), then child3 == 0.
##     If this is a leaf then child1,child2,child3 are subscripts
##       of data nodes, else they are subscripts  of other tree nodes.
## splitkey1:
##    the minimum key of the subtree at child2.  If this is a leaf
##    then it is the key of child2.
## splitkey2:
##    if child3 > 0 then splitkey2 is the minimum key of the subtree at child3.
##    If this is a leaf, then it is the key of child3.
## Again, there are two constructors for the same reason mentioned above.

struct TreeNode{K}
    child1::Int
    child2::Int
    child3::Int
    parent::Int
    splitkey1::K
    splitkey2::K
    TreeNode{K}(::Type{K}, c1::Int, c2::Int, c3::Int, p::Int) where {K} = new{K}(c1, c2, c3, p)
    TreeNode{K}(c1::Int, c2::Int, c3::Int, p::Int, sk1::K, sk2::K) where {K} =
        new{K}(c1, c2, c3, p, sk1, sk2)
end


## The next two functions are called to initialize the tree
## by inserting a dummy tree node with two children, the before-start
## marker whose index is 1 and the after-end marker whose index is 2.
## These two markers live in dummy data nodes.

function initializeTree!(tree::Array{TreeNode{K},1}) where K
    resize!(tree,1)
    tree[1] = TreeNode{K}(K, 1, 2, 0, 0)
    return nothing
end

function initializeData!(data::Array{KDRec{K,D},1}) where {K,D}
    resize!(data, 2)
    data[1] = KDRec{K,D}(1)
    data[2] = KDRec{K,D}(1)
    return nothing
end


## Type BalancedTree23{K,D,Ord} is 'base class' for
## SortedDict, SortedMultiDict and SortedSet.
## K = key type, D = data type
## Key type must support an ordering operation defined by Ordering
## object Ord.
## The default is Forward which implies that the ordering function
## is isless (see ordering.jl)
## The fields are as follows.
## ord: The ordering object.  Often the ordering type
##   is a singleton type, so this field is empty, but it
##   is still necessary to direct the multiple dispatch.
## data: the (key,data) pairs of the tree.
##   The first and second entries of the data array are dummy placeholders
##   for the beginning and end of the sorted order of the keys
## tree: the nodes of a 2-3 tree that sits above the data.
## rootloc: the index of the entry of tree (i.e., a subscript to
##   treenodes) that is the tree's root
## depth: the depth of the tree, (number
##    of tree levels, not counting the level of data at the bottom)
##    depth==1 means that there is a single root node
##      whose children are data nodes.
## freetreeinds: Array of indices of free locations in the
##    tree array (locations are freed due to deletion)
## freedatainds: Array of indices of free locations in the
##    data array (locations are freed due to deletion)
## useddatacells: BitSet (i.e., bit vector) showing which
##    data cells are taken.  The complementary positions are
##    exactly those stored in freedatainds.  This array is
##    used only for error checking.
## deletionchild and deletionleftkey are two work-arrays
## for the delete function.

mutable struct BalancedTree23{K, D, Ord <: Ordering}
    ord::Ord
    data::Array{KDRec{K,D}, 1}
    tree::Array{TreeNode{K}, 1}
    rootloc::Int
    depth::Int
    freetreeinds::Array{Int,1}
    freedatainds::Array{Int,1}
    useddatacells::BitSet
    # The next two arrays are used as a workspace by the delete!
    # function.
    deletionchild::Array{Int,1}
    deletionleftkey::Array{K,1}
    function BalancedTree23{K,D,Ord}(ord1::Ord) where {K,D,Ord<:Ordering}
        tree1 = Vector{TreeNode{K}}(undef, 1)
        initializeTree!(tree1)
        data1 = Vector{KDRec{K,D}}(undef, 2)
        initializeData!(data1)
        u1 = BitSet()
        push!(u1, 1, 2)
        new{K,D,Ord}(ord1, data1, tree1, 1, 1, Vector{Int}(), Vector{Int}(),
                     u1,
                     Vector{Int}(undef, 3), Vector{K}(undef, 3))
    end
end


## Function cmp2 checks a tree node with two children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey or 2 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

@inline function cmp2_nonleaf(o::Ordering,
                              treenode::TreeNode,
                              k)
    lt(o, k, treenode.splitkey1) ? 1 : 2
end


@inline function cmp2_leaf(o::Ordering,
                           treenode::TreeNode,
                           k)
    (treenode.child2 == 2) ||
    lt(o, k, treenode.splitkey1) ? 1 : 2
end


## Function cmp3 checks a tree node with three children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey1, 2 if the key is greater than or
## equal to splitkey1 but less than splitkey2, or 3 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

@inline function cmp3_nonleaf(o::Ordering,
                              treenode::TreeNode,
                              k)
    lt(o, k, treenode.splitkey1) ? 1 :
    lt(o, k, treenode.splitkey2) ? 2 : 3
end


@inline function cmp3_leaf(o::Ordering,
                           treenode::TreeNode,
                           k)
    lt(o, k, treenode.splitkey1) ?                           1 :
    (treenode.child3 == 2 || lt(o, k, treenode.splitkey2)) ? 2 : 3
end


## Function cmp2le checks a tree node with two children
## against a given key, and returns 1 if the given key is
## less than or equal to the node's splitkey or 2 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

@inline function cmp2le_nonleaf(o::Ordering,
                                treenode::TreeNode,
                                k)
    !lt(o,treenode.splitkey1,k) ? 1 : 2
end


@inline function cmp2le_leaf(o::Ordering,
                             treenode::TreeNode,
                             k)
    treenode.child2 == 2 || !lt(o,treenode.splitkey1,k) ? 1 : 2
end


## Function cmp3le checks a tree node with three children
## against a given key, and returns 1 if the given key is
## less than or equal to the node's splitkey1, 2 if less than or equal
## to splitkey2, or
## 3 else. Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

@inline function cmp3le_nonleaf(o::Ordering,
                                treenode::TreeNode,
                                k)
    !lt(o,treenode.splitkey1, k) ? 1 :
    !lt(o,treenode.splitkey2, k) ? 2 : 3
end

@inline function cmp3le_leaf(o::Ordering,
                             treenode::TreeNode,
                             k)
    !lt(o,treenode.splitkey1,k) ?                            1 :
    (treenode.child3 == 2 || !lt(o,treenode.splitkey2, k)) ? 2 : 3
end


## The empty! function deletes all data in the balanced tree.
## Therefore, it invalidates all indices.

function Base.empty!(t::BalancedTree23)
    resize!(t.data,2)
    initializeData!(t.data)
    resize!(t.tree,1)
    initializeTree!(t.tree)
    t.depth = 1
    t.rootloc = 1
    t.freetreeinds = Vector{Int}()
    t.freedatainds = Vector{Int}()
    empty!(t.useddatacells)
    push!(t.useddatacells, 1, 2)
    return nothing
end

## Default implementations of eq for Forward, Reverse
## and default ordering

eq(::ForwardOrdering, a, b) = isequal(a,b)
eq(::ReverseOrdering{ForwardOrdering}, a, b) = isequal(a,b)
eq(o::Ordering, a, b) = !lt(o, a, b) && !lt(o, b, a)


## The findkey function finds the index of a (key,data) pair in the tree
## where the given key lives (if it is present), or
## if the key is not present, to the lower bound for the key,
## i.e., the data item that comes immediately before it.
## If there are multiple equal keys, then it finds the last one.
## It returns the index of the key found and a boolean indicating
## whether the exact key was found or not.

function findkey(t::BalancedTree23, k)
    curnode = t.rootloc
    for depthcount = 1 : t.depth - 1
        @inbounds thisnode = t.tree[curnode]
        cmp = thisnode.child3 == 0 ?
                         cmp2_nonleaf(t.ord, thisnode, k) :
                         cmp3_nonleaf(t.ord, thisnode, k)
        curnode = cmp == 1 ? thisnode.child1 :
                  cmp == 2 ? thisnode.child2 : thisnode.child3
    end
    @inbounds thisnode = t.tree[curnode]
    cmp = thisnode.child3 == 0 ?
                cmp2_leaf(t.ord, thisnode, k) :
                cmp3_leaf(t.ord, thisnode, k)
    curnode = cmp == 1 ? thisnode.child1 :
              cmp == 2 ? thisnode.child2 : thisnode.child3
    @inbounds return curnode, (curnode > 2 && eq(t.ord, t.data[curnode].k, k))
end


## The findkeyless function finds the index of a (key,data) pair in the tree that
## with the greatest key that is less than the given key.  If there is no
## key less than the given key, then it returns 1 (the before-start node).

function findkeyless(t::BalancedTree23, k)
    curnode = t.rootloc
    for depthcount = 1 : t.depth - 1
        @inbounds thisnode = t.tree[curnode]
        cmp = thisnode.child3 == 0 ?
               cmp2le_nonleaf(t.ord, thisnode, k) :
               cmp3le_nonleaf(t.ord, thisnode, k)
        curnode = cmp == 1 ? thisnode.child1 :
                  cmp == 2 ? thisnode.child2 : thisnode.child3
    end
    @inbounds thisnode = t.tree[curnode]
    cmp = thisnode.child3 == 0 ?
            cmp2le_leaf(t.ord, thisnode, k) :
            cmp3le_leaf(t.ord, thisnode, k)
    curnode = cmp == 1 ? thisnode.child1 :
              cmp == 2 ? thisnode.child2 : thisnode.child3
    return curnode
end


## The following are helper routines for the insert! and delete! functions.
## They replace the 'parent' field of either an internal tree node or
## a data node at the bottom tree level.

function replaceparent!(data::Array{KDRec{K,D},1}, whichind::Int, newparent::Int) where {K,D}
    data[whichind] = KDRec{K,D}(newparent, data[whichind].k, data[whichind].d)
    return nothing
end

function replaceparent!(tree::Array{TreeNode{K},1}, whichind::Int, newparent::Int) where K
    tree[whichind] = TreeNode{K}(tree[whichind].child1, tree[whichind].child2,
                                 tree[whichind].child3, newparent,
                                 tree[whichind].splitkey1,
                                 tree[whichind].splitkey2)
    return nothing
end


## Helper function for either grabbing a brand new location in a
## array (if there are no free locations) or else grabbing a free
## location and marking it as used.  The return value is the
## index of the data just inserted into the vector.

function push_or_reuse!(a::Vector, freelocs::Array{Int,1}, item)
    if isempty(freelocs)
        push!(a, item)
        return length(a)
    end
    loc = pop!(freelocs)
    a[loc] = item
    return loc
end


## Function insert! inserts a new data item into the tree.
## The arguments are the (K,D) pair to insert.
## The return values are a bool and an index.  The
## bool indicates whether the insertion inserted a new record (true) or
## whether it replaced an existing record (false).
## The index returned is the subscript in t.data where the
## inserted value sits.
## "allowdups" (i.e., "allow duplicate keys") means that no check is
## done whether the iterm
## is already in the tree, so insertion of a new item always succeeds.


function Base.insert!(t::BalancedTree23{K,D,Ord}, k, d, allowdups::Bool) where {K,D,Ord <: Ordering}

    ## First we find the greatest data node that is <= k.
    leafind, exactfound = findkey(t, k)
    parent = t.data[leafind].parent

    ## The following code is necessary because in the case of a
    ## brand new tree, the initial tree and data entries were incompletely
    ## initialized by the constructor.  In this case, the call to insert!
    ## underway carries
    ## valid K and D values, so these valid values may now be
    ## stored in the dummy placeholder nodes so that they no
    ## longer hold undefined references.

    if size(t.data,1) == 2
        @invariant t.rootloc == 1 && t.depth == 1
        t.tree[1] = TreeNode{K}(t.tree[1].child1, t.tree[1].child2,
                                t.tree[1].child3, t.tree[1].parent,
                                k, k)
        t.data[1] = KDRec{K,D}(t.data[1].parent, k, d)
        t.data[2] = KDRec{K,D}(t.data[2].parent, k, d)
    end

    ## If we have found exactly k in the tree, then we
    ## replace the data associated with k and return.

    if exactfound && !allowdups
        t.data[leafind] = KDRec{K,D}(parent, k,d)
        return false, leafind
    end

    # We get here if k was not already found in the tree or
    # if duplicates are allowed.
    # In this case we insert a new node.
    depth = t.depth
    ord = t.ord

    ## Store the new data item in the tree's data array.  Later
    ## go back and fix the parent.

    newind = push_or_reuse!(t.data, t.freedatainds, KDRec{K,D}(0,k,d))
    push!(t.useddatacells, newind)
    p1 = parent
    newchild = newind
    minkeynewchild = k
    splitroot = false
    curdepth = depth
    existingchild = leafind

    
    ## This loop ascends the tree (i.e., follows the path from a leaf to the root)
    ## starting from the parent p1 of
    ## where the new key k will go.
    ## Variables updated by the loop:
    ##   p1: parent of where the new node goes
    ##   newchild: index of the child to be inserted
    ##   minkeynewchild: the minimum key in the subtree rooted at newchild
    ##   existingchild: a child of p1; the newchild must
    ##      be inserted in the slot to the right of existingchild
    ##   curdepth: depth of newchild
    ## For each 3-node we encounter
    ## during the ascent, we add a new child, which requires splitting
    ## the 3-node into two 2-nodes.  Then we keep going until we hit the root.
    ## If we encounter a 2-node, then the ascent can stop; we can
    ## change the 2-node to a 3-node with the new child.

    while true


        # Let newchild1,...newchild4 be the new children of
        # the parent node
        # Initially, take the three children of the existing parent
        # node and set newchild4 to 0.

        newchild1 = t.tree[p1].child1
        newchild2 = t.tree[p1].child2
        minkeychild2 = t.tree[p1].splitkey1
        newchild3 = t.tree[p1].child3
        minkeychild3 = t.tree[p1].splitkey2
        p1parent = t.tree[p1].parent
        newchild4 = 0

        # Now figure out which of the 4 children is the new node
        # and insert it into newchild1 ... newchild4

        if newchild1 == existingchild
            newchild4 = newchild3
            minkeychild4 = minkeychild3
            newchild3 = newchild2
            minkeychild3 = minkeychild2
            newchild2 = newchild
            minkeychild2 = minkeynewchild
        elseif newchild2 == existingchild
            newchild4 = newchild3
            minkeychild4 = minkeychild3
            newchild3 = newchild
            minkeychild3 = minkeynewchild
        elseif newchild3 == existingchild
            newchild4 = newchild
            minkeychild4 = minkeynewchild
        else
            throw(AssertionError("Tree structure is corrupted 1"))
        end

        # Two cases: either we need to split the tree node
        # if newchild4>0 else we convert a 2-node to a 3-node
        # if newchild4==0

        if newchild4 == 0
            # Change the parent from a 2-node to a 3-node
            t.tree[p1] = TreeNode{K}(newchild1, newchild2, newchild3,
                                     p1parent, minkeychild2, minkeychild3)
            if curdepth == depth
                replaceparent!(t.data, newchild, p1)
            else
                replaceparent!(t.tree, newchild, p1)
            end
            break
        end
        # Split the parent
        t.tree[p1] = TreeNode{K}(newchild1, newchild2, 0,
                                 p1parent, minkeychild2, minkeychild2)
        newtreenode = TreeNode{K}(newchild3, newchild4, 0,
                                  p1parent, minkeychild4, minkeychild2)
        newparentnum = push_or_reuse!(t.tree, t.freetreeinds, newtreenode)
        if curdepth == depth
            replaceparent!(t.data, newchild2, p1)
            replaceparent!(t.data, newchild3, newparentnum)
            replaceparent!(t.data, newchild4, newparentnum)
        else
            replaceparent!(t.tree, newchild2, p1)
            replaceparent!(t.tree, newchild3, newparentnum)
            replaceparent!(t.tree, newchild4, newparentnum)
        end
        # Update the loop variables for the next level of the
        # ascension
        existingchild = p1
        newchild = newparentnum
        p1 = p1parent
        minkeynewchild = minkeychild3
        curdepth -= 1
        if curdepth == 0
            splitroot = true
            break
        end
    end

    # If the root has been split, then we need to add a level
    # to the tree that is the parent of the old root and the new node.

    if splitroot
        @invariant existingchild == t.rootloc
        newroot = TreeNode{K}(existingchild, newchild, 0,
                              0, minkeynewchild, minkeynewchild)
        
        newrootloc = push_or_reuse!(t.tree, t.freetreeinds, newroot)
        replaceparent!(t.tree, existingchild, newrootloc)
        replaceparent!(t.tree, newchild, newrootloc)
        t.rootloc = newrootloc
        t.depth += 1
    end
    return true, newind
end


## nextloc0: returns the next item in the tree according to the
## sort order, given an index i (subscript of t.data) of a current
## item.
## The routine returns 2 if there is no next item (i.e., we started
## from the last one in the sorted order).

function nextloc0(t, i::Int)
    ii = i
    @invariant i != 2 && i in t.useddatacells
    @inbounds p = t.data[i].parent
    nextchild = 0
    depthp = t.depth
    @inbounds while true
        if depthp < t.depth
            p = t.tree[ii].parent
        end
        if t.tree[p].child1 == ii
            nextchild = t.tree[p].child2
            break
        end
        if t.tree[p].child2 == ii && t.tree[p].child3 > 0
            nextchild = t.tree[p].child3
            break
        end
        ii = p
        depthp -= 1
    end
    @inbounds while true
        if depthp == t.depth
            return nextchild
        end
        p = nextchild
        nextchild = t.tree[p].child1
        depthp += 1
    end
end


## prevloc0: returns the previous item in the tree according to the
## sort order, given an index i (subscript of t.data) of a current
## item.
## The routine returns 1 if there is no previous item (i.e., we started
## from the first one in the sorted order).


function prevloc0(t::BalancedTree23, i::Int)
    @invariant i != 1 && i in t.useddatacells
    ii = i
    @inbounds p = t.data[i].parent
    prevchild = 0
    depthp = t.depth
    @inbounds while true
        if depthp < t.depth
            p = t.tree[ii].parent
        end
        if t.tree[p].child3 == ii
            prevchild = t.tree[p].child2
            break
        end
        if t.tree[p].child2 == ii
            prevchild = t.tree[p].child1
            break
        end
        ii = p
        depthp -= 1
    end
    @inbounds while true
        if depthp == t.depth
            return prevchild
        end
        p = prevchild
        c3 = t.tree[p].child3
        prevchild = c3 > 0 ? c3 : t.tree[p].child2
        depthp += 1
    end
end

## This function takes two indices into t.data and checks which
## one comes first in the sorted order by chasing them both
## up the tree until a common ancestor is found.
## The return value is -1 if i1 precedes i2, 0 if i1 == i2
##, 1 if i2 precedes i1.

function compareInd(t::BalancedTree23, i1::Int, i2::Int)
    @invariant(i1 in t.useddatacells && i2 in t.useddatacells)
    if i1 == i2
        return 0
    end
    i1a = i1
    i2a = i2
    p1 = t.data[i1].parent
    p2 = t.data[i2].parent
    @invariant_support_statement curdepth = t.depth
    curdepth = t.depth
    while true
        @invariant curdepth > 0
        if p1 == p2
            if i1a == t.tree[p1].child1
                @invariant t.tree[p1].child2 == i2a || t.tree[p1].child3 == i2a
                return -1
            end
            if i1a == t.tree[p1].child2
                if (t.tree[p1].child1 == i2a)
                    return 1
                end
                @invariant t.tree[p1].child3 == i2a
                return -1
            end
            @invariant i1a == t.tree[p1].child3
            @invariant t.tree[p1].child1 == i2a || t.tree[p1].child2 == i2a
            return 1
        end
        i1a = p1
        i2a = p2
        p1 = t.tree[i1a].parent
        p2 = t.tree[i2a].parent
        @invariant_support_statement curdepth -= 1
        curdepth -= 1
    end
end


## beginloc, endloc return the index (into t.data) of the first, last item in the
## sorted order of the tree.  beginloc works by going to the before-start marker
## (data node 1) and executing a next operation on it.  endloc is the opposite.

beginloc(t::BalancedTree23) = nextloc0(t,1)
endloc(t::BalancedTree23) = prevloc0(t,2)


## delete! routine deletes an entry from the balanced tree.

function Base.delete!(t::BalancedTree23{K,D,Ord}, it::Int) where {K,D,Ord<:Ordering}

    ## Put the cell indexed by 'it' into the deletion list.
    ##
    ## Create the following data items maintained in the
    ## upcoming loop.
    ##
    ## p is a tree-node ancestor of the deleted node
    ## The children of p are stored in
    ## t.deletionchild[..]
    ## The number of these children is newchildcount, which is 1, 2 or 3.
    ## The keys that lower bound the children
    ## are stored in t.deletionleftkey[..]
    ## There is a special case for t.deletionleftkey[1]; the
    ## flag deletionleftkey1_valid indicates that the left key
    ## for the immediate right neighbor of the
    ## deleted node has not yet been been stored in the tree.
    ## Once it is stored, t.deletionleftkey[1] is no longer needed
    ## or used.
    ## The flag mustdeleteroot means that the tree has contracted
    ## enough that it loses a level.

    p = t.data[it].parent
    newchildcount = 0
    c1 = t.tree[p].child1
    deletionleftkey1_valid = true
    if c1 != it
        deletionleftkey1_valid = false
        newchildcount += 1
        t.deletionchild[newchildcount] = c1
        t.deletionleftkey[newchildcount] = t.data[c1].k
    end
    c2 = t.tree[p].child2
    if c2 != it
        newchildcount += 1
        t.deletionchild[newchildcount] = c2
        t.deletionleftkey[newchildcount] = t.data[c2].k
    end
    c3 = t.tree[p].child3
    if c3 != it && c3 > 0
        newchildcount += 1
        t.deletionchild[newchildcount] = c3
        t.deletionleftkey[newchildcount] = t.data[c3].k
    end
    @invariant newchildcount == 1 || newchildcount == 2
    push!(t.freedatainds, it)
    pop!(t.useddatacells,it)
    defaultKey = t.tree[1].splitkey1
    curdepth = t.depth
    mustdeleteroot = false
    pparent = -1

    ## The following loop ascends the tree and contracts nodes (reduces their
    ## number of children) as
    ## needed.  If newchildcount == 2 or 3, then the ascent is terminated
    ## and a node is created with 2 or 3 children.
    ## If newchildcount == 1, then the ascent must continue since a tree
    ## node cannot have one child.

    while true
        pparent = t.tree[p].parent
        ## Simple cases when the new child count is 2 or 3
        if newchildcount == 2
            t.tree[p] = TreeNode{K}(t.deletionchild[1],
                                    t.deletionchild[2], 0, pparent,
                                    t.deletionleftkey[2], defaultKey)

            break
        end
        if newchildcount == 3
            t.tree[p] = TreeNode{K}(t.deletionchild[1], t.deletionchild[2],
                                    t.deletionchild[3], pparent,
                                    t.deletionleftkey[2], t.deletionleftkey[3])
            break
        end
        @invariant newchildcount == 1
        ## For the rest of this loop, we cover the case
        ## that p has one child.

        ## If newchildcount == 1 and curdepth==1, this means that
        ## the root of the tree has only one child.  In this case, we can
        ## delete the root and make its one child the new root (see below).

        if curdepth == 1
            mustdeleteroot = true
            break
        end

        ## We now branch on three cases depending on whether p is child1,
        ## child2 or child3 of its parent.

        if t.tree[pparent].child1 == p
            rightsib = t.tree[pparent].child2

            ## Here p is child1 and rightsib is child2.
            ## If rightsib has 2 children, then p and
            ## rightsib are merged into a single node
            ## that has three children.
            ## If rightsib has 3 children, then p and
            ## rightsib are reformed so that each has
            ## two children.

            if t.tree[rightsib].child3 == 0
                rc1 = t.tree[rightsib].child1
                rc2 = t.tree[rightsib].child2
                t.tree[p] = TreeNode{K}(t.deletionchild[1],
                                        rc1, rc2,
                                        pparent,
                                        t.tree[pparent].splitkey1,
                                        t.tree[rightsib].splitkey1)
                if curdepth == t.depth
                    replaceparent!(t.data, rc1, p)
                    replaceparent!(t.data, rc2, p)
                else
                    replaceparent!(t.tree, rc1, p)
                    replaceparent!(t.tree, rc2, p)
                end
                push!(t.freetreeinds, rightsib)
                newchildcount = 1
                t.deletionchild[1] = p
            else
                rc1 = t.tree[rightsib].child1
                t.tree[p] = TreeNode{K}(t.deletionchild[1], rc1, 0,
                                        pparent,
                                        t.tree[pparent].splitkey1,
                                        defaultKey)
                sk1 = t.tree[rightsib].splitkey1
                t.tree[rightsib] = TreeNode{K}(t.tree[rightsib].child2,
                                               t.tree[rightsib].child3,
                                               0,
                                               pparent,
                                               t.tree[rightsib].splitkey2,
                                               defaultKey)
                if curdepth == t.depth
                    replaceparent!(t.data, rc1, p)
                else
                    replaceparent!(t.tree, rc1, p)
                end
                newchildcount = 2
                t.deletionchild[1] = p
                t.deletionchild[2] = rightsib
                t.deletionleftkey[2] = sk1
            end

            ## If pparent had a third child (besides p and rightsib)
            ## then we add this to t.deletionchild

            c3 = t.tree[pparent].child3
            if c3 > 0
                newchildcount += 1
                t.deletionchild[newchildcount] = c3
                t.deletionleftkey[newchildcount] = t.tree[pparent].splitkey2
            end
            p = pparent
        elseif t.tree[pparent].child2 == p

            ## Here p is child2 and leftsib is child1.
            ## If leftsib has 2 children, then p and
            ## leftsib are merged into a single node
            ## that has three children.
            ## If leftsib has 3 children, then p and
            ## leftsib are reformed so that each has
            ## two children.

            leftsib = t.tree[pparent].child1
            lk = deletionleftkey1_valid ?
                      t.deletionleftkey[1] :
                      t.tree[pparent].splitkey1
            if t.tree[leftsib].child3 == 0
                lc1 = t.tree[leftsib].child1
                lc2 = t.tree[leftsib].child2
                t.tree[p] = TreeNode{K}(lc1, lc2,
                                        t.deletionchild[1],
                                        pparent,
                                        t.tree[leftsib].splitkey1,
                                        lk)
                if curdepth == t.depth
                    replaceparent!(t.data, lc1, p)
                    replaceparent!(t.data, lc2, p)
                else
                    replaceparent!(t.tree, lc1, p)
                    replaceparent!(t.tree, lc2, p)
                end
                push!(t.freetreeinds, leftsib)
                newchildcount = 1
                t.deletionchild[1] = p
            else
                lc3 = t.tree[leftsib].child3
                t.tree[p] = TreeNode{K}(lc3, t.deletionchild[1], 0,
                                        pparent, lk, defaultKey)
                sk2 = t.tree[leftsib].splitkey2
                t.tree[leftsib] = TreeNode{K}(t.tree[leftsib].child1,
                                              t.tree[leftsib].child2,
                                              0, pparent,
                                              t.tree[leftsib].splitkey1,
                                              defaultKey)
                if curdepth == t.depth
                    replaceparent!(t.data, lc3, p)
                else
                    replaceparent!(t.tree, lc3, p)
                end
                newchildcount = 2
                t.deletionchild[1] = leftsib
                t.deletionchild[2] = p
                t.deletionleftkey[2] = sk2
            end

            ## If pparent had a third child (besides p and leftsib)
            ## then we add this to t.deletionchild

            c3 = t.tree[pparent].child3
            if c3 > 0
                newchildcount += 1
                t.deletionchild[newchildcount] = c3
                t.deletionleftkey[newchildcount] = t.tree[pparent].splitkey2
            end
            p = pparent
            deletionleftkey1_valid = false
        else
            ## Here p is child3 and leftsib is child2.
            ## If leftsib has 2 children, then p and
            ## leftsib are merged into a single node
            ## that has three children.
            ## If leftsib has 3 children, then p and
            ## leftsib are reformed so that each has
            ## two children.

            @invariant t.tree[pparent].child3 == p
            leftsib = t.tree[pparent].child2
            lk = deletionleftkey1_valid ?
                       t.deletionleftkey[1] :
                       t.tree[pparent].splitkey2
            if t.tree[leftsib].child3 == 0
                lc1 = t.tree[leftsib].child1
                lc2 = t.tree[leftsib].child2
                t.tree[p] = TreeNode{K}(lc1, lc2,
                                        t.deletionchild[1],
                                        pparent,
                                        t.tree[leftsib].splitkey1,
                                        lk)
                if curdepth == t.depth
                    replaceparent!(t.data, lc1, p)
                    replaceparent!(t.data, lc2, p)
                else
                    replaceparent!(t.tree, lc1, p)
                    replaceparent!(t.tree, lc2, p)
                end
                push!(t.freetreeinds, leftsib)
                newchildcount = 2
                t.deletionchild[1] = t.tree[pparent].child1
                t.deletionleftkey[2] = t.tree[pparent].splitkey1
                t.deletionchild[2] = p
            else
                lc3 = t.tree[leftsib].child3
                t.tree[p] = TreeNode{K}(lc3, t.deletionchild[1], 0,
                                        pparent, lk, defaultKey)
                sk2 = t.tree[leftsib].splitkey2
                t.tree[leftsib] = TreeNode{K}(t.tree[leftsib].child1,
                                              t.tree[leftsib].child2,
                                              0, pparent,
                                              t.tree[leftsib].splitkey1,
                                              defaultKey)
                if curdepth == t.depth
                    replaceparent!(t.data, lc3, p)
                else
                    replaceparent!(t.tree, lc3, p)
                end
                newchildcount = 3
                t.deletionchild[1] = t.tree[pparent].child1
                t.deletionchild[2] = leftsib
                t.deletionchild[3] = p
                t.deletionleftkey[2] = t.tree[pparent].splitkey1
                t.deletionleftkey[3] = sk2
            end
            p = pparent
            deletionleftkey1_valid = false
        end
        curdepth -= 1
    end
    if mustdeleteroot
        @invariant !deletionleftkey1_valid
        @invariant p == t.rootloc
        t.rootloc = t.deletionchild[1]
        t.depth -= 1
        push!(t.freetreeinds, p)
    end

    ## If deletionleftkey1_valid, this means that the new
    ## min key of the deleted node and its right neighbors
    ## has never been stored in the tree.  It must be stored
    ## as splitkey1 or splitkey2 of some ancestor of the
    ## deleted node, so we continue ascending the tree
    ## until we find a node which has p (and therefore the
    ## deleted node) as its descendent through its second
    ## or third child.
    ## It cannot be the case that the deleted node is
    ## is a descendent of the root always through
    ## first children, since this would mean the deleted
    ## node is the leftmost placeholder, which
    ## cannot be deleted.

    if deletionleftkey1_valid
        while true
            pparentnode = t.tree[pparent]
            if pparentnode.child2 == p
                t.tree[pparent] = TreeNode{K}(pparentnode.child1,
                                              pparentnode.child2,
                                              pparentnode.child3,
                                              pparentnode.parent,
                                              t.deletionleftkey[1],
                                              pparentnode.splitkey2)
                break
            elseif pparentnode.child3 == p
                t.tree[pparent] = TreeNode{K}(pparentnode.child1,
                                              pparentnode.child2,
                                              pparentnode.child3,
                                              pparentnode.parent,
                                              pparentnode.splitkey1,
                                              t.deletionleftkey[1])
                break
            else
                p = pparent
                pparent = pparentnode.parent
                curdepth -= 1
                @invariant curdepth > 0
            end
        end
    end
    return nothing
end
