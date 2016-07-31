using AbstractTrees

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

""" KDRec is one data node. """
immutable KDRec{K,D}
    " The tree leaf (idex in the BalancedTree23 `tree` array) that is the
      parent of this node"
    parent::Int
    " The key of the node "
    k::K
    " The data of the node "
    d::D
    KDRec(p::Int, k1::K, d1::D) = new(p,k1,d1)
end


"""
`TreeNode` is an internal node of the tree.
`child1-3`:  
     These are the three children node numbers.
     If the node is a 2-node (rather than 3), then `child3 == 0`.
     If this is the lowest `tree` level (i.e. the level above the data
     level), then child1,child2,child3 are subscripts of data nodes,
     else they are subscripts  of other tree nodes.
splitkey1:
    the minimum key of the subtree at child2.
splitkey2: 
    if child3 > 0 then `splitkey2` is the minimum key of the subtree at `child3`.
"""
immutable TreeNode{K}
    child1::Int
    child2::Int
    child3::Int
    parent::Int
    splitkey1::K
    splitkey2::K
    TreeNode(c1::Int, c2::Int, c3::Int, p::Int, sk1::K, sk2::K) = 
        new(c1, c2, c3, p, sk1, sk2)
    " Update the TreeNode `node`, changing only the field(s) indicated by
      the passed keyword argument(s)"
    TreeNode(node::TreeNode{K}; child1 = node.child1, child2 = node.child2,
        child3 = node.child3, parent = node.parent, splitkey1 = node.splitkey1,
        splitkey2 = node.splitkey2) =
        new(child1, child2, child3, parent, splitkey1, splitkey2)
end

## Type BalancedTree23{K,D,Ord} is 'base class' for
## SortedDict.
## K = key type, D = data type
## Key type must support an ordering operation defined by Ordering
## object Ord.
## The default is Forward which implies that the ordering function
## is isless (see ordering.jl)
## The fields are as follows.
## ord:: The ordering object.  Often the ordering type
##   is a singleton type, so this field is empty, but it
##   is still necessary to direct the multiple dispatch.
## data: the (key,data) pairs of the tree. 
## tree: the nodes of a 2-3 tree that sits above the data.
## rootloc: the index of the node that is tree's root (note if depth==0,
## this is an index into data)
## depth: the depth of the tree, (number
##    of tree levels, not counting the level of data at the bottom)
## freetreeinds: Array of indices of free locations in the
##    tree array (locations are freed due to deletion)
## freedatainds: Array of indices of free locations in the
##    data array (locations are freed due to deletion)
## useddatacells: IntSet (i.e., bit vector) showing which
##    data cells are taken.  The complementary positions are
##    exactly those stored in freedatainds.  This array is
##    used only for error checking

type BalancedTree23{K, D, Ord <: Ordering}
    ord::Ord
    data::Array{KDRec{K,D}, 1}
    tree::Array{TreeNode{K}, 1}
    rootloc::Int
    depth::Int
    freetreeinds::Array{Int,1}
    freedatainds::Array{Int,1}
    useddatacells::IntSet 
    function BalancedTree23(ord1::Ord)
        tree1 = Array(TreeNode{K}, 0)
        data1 = Array(KDRec{K,D}, 0)
        new(ord1, data1, tree1, 0, 0, Array(Int,0), Array(Int,0), 
            IntSet())
    end
end
function AbstractTrees.printnode(io::IO, tree::BalancedTree23)
    if tree.rootloc == 0
        print(io, "Empty Tree")
    else
        AbstractTrees.printnode(io, children(tree))
    end
end

function Base.show(io::IO, tree::BalancedTree23)
    print(io, "Balanced 2-3 tree of depth $(tree.depth)")
end

immutable Subtree
    tree::BalancedTree23
    idx::Int
    level::Int
end
function AbstractTrees.show(io::IO, st::Subtree)
    # Is a leaf
    if st.tree.depth == st.level
        node = st.tree.data[st.idx]
        print(io, node.k => node.d)
    else
        node = st.tree.tree[st.idx]
        if node.child3 == 0
            print(io, "L < $(node.splitkey1) ≦ R")
        else
            print(io, "L < $(node.splitkey1) ≦ M < $(node.splitkey2) ≦ R")
        end
    end
end

"""
    Dumps the internals of a node, useful for debugging, particularly as
    print_tree(printinternals, STDOUT, st)
"""
function printinternals(io::IO, st::Subtree)  
    if st.tree.depth == st.level
        node = st.tree.data[st.idx]
        print(io, "Leaf / idx=", st.idx, " / parent=", node.parent,
            " / key=", node.k ," / data=", node.d)
    else
        node = st.tree.tree[st.idx]
        print(io, "Internal / idx=", st.idx, " / parent=", node.parent,
            " / children=", join((node.child1,node.child2,node.child3),','),
            " / splitkeys=", join((node.splitkey1,node.splitkey2),','))
    end
end
function printinternals(io::IO, tree::BalancedTree23)
    if tree.rootloc == 0
        print(io, "Empty Tree")
    else
        printinternals(io, Subtree(tree,tree.rootloc,0))
    end
end


AbstractTrees.children(tree::BalancedTree23) = Subtree(tree,tree.rootloc,0)
Base.start(st::Subtree) = 1
function Base.getindex(st::Subtree, idx)
    node = st.tree.tree[st.idx]
    Subtree(st.tree, ifelse(idx == 1, node.child1,
        ifelse(idx == 2, node.child2, node.child3)), st.level + 1)
end
AbstractTrees.nextind(st::Subtree, idx) = idx + 1
Base.next(st::Subtree, idx) = (st[idx], AbstractTrees.nextind(st, idx))
Base.done(st::Subtree,idx) = idx > length(st)
Base.length(st::Subtree) =
    (st.level == st.tree.depth) ? 0 : 
    st.tree.tree[st.idx].child3 != 0 ? 3 :
    st.tree.tree[st.idx].child2 == 0 ? 1 : 2
AbstractTrees.parentlinks(st::Subtree) = AbstractTrees.StoredParents()
AbstractTrees.siblinglinks(st::Subtree) = AbstractTrees.StoredSiblings()
AbstractTrees.parent(_,st::Subtree) = Subtree(st.tree,
    st.level == st.tree.depth ? st.tree.data[st.idx].parent :
        st.tree.tree[st.idx].parent, st.level - 1)
AbstractTrees.parent(st::Subtree) = AbstractTrees.parent(st,st)
AbstractTrees.isroot(_,st::Subtree) = st.level == 0
AbstractTrees.isroot(st::Subtree) = AbstractTrees.isroot(st, st)
function AbstractTrees.relative_state(_,parent,child)
    node = parent.tree.tree[parent.idx]
    node.child1 == child.idx ? 1 : node.child2 == child.idx ? 2 : 3
end
level(st::Subtree) = st.level
isleaf(st::Subtree) = st.level == st.tree.depth
function AbstractTrees.parentind(st::Subtree)
    isleaf(st) ? st.tree.data[st.idx].parent : st.tree.tree[st.idx].parent
end
function Base.setindex!(st::Subtree, val)
    isleaf(st) ? st.tree.data[st.idx] = val : st.tree.tree[st.idx] = val
end
function Base.setindex!(st::Subtree, idx::Int, which)
    @assert !isleaf(st)
    @assert which in 1:3
    node = st.tree.tree[st.idx]
    st.tree.tree[st.idx] = which == 1 ? typeof(node)(node; child1 = idx) :
        which == 2 ? typeof(node)(node; child2 = idx) :
        typeof(node)(node; child3 = idx) 
end
Base.setindex!(st::Subtree, idx::Subtree, which) =
    Base.setindex!(st, idx.idx, which)

using AbstractTrees: parentind, isroot, ascend


immutable KeyView
    st::Subtree
end
function getindex(kv::KeyView, which)
    node = kv.st.tree.tree[kv.st.idx]
    which == 1 ? node.splitkey1 : node.splitkey2
end
function Base.setindex!(kv::KeyView, key, which)
    node = kv.st.tree.tree[kv.st.idx]
    kv.st.tree.tree[kv.st.idx] = which == 1 ?
        typeof(node)(node; splitkey1 = key) :
        typeof(node)(node; splitkey2 = key)
end
Base.start(kv::KeyView) = 1
Base.next(kv::KeyView, i) = kv[i], i + 1
Base.done(kv::KeyView, i) = i > length(kv)
Base.length(kv::KeyView) = length(children(kv.st))-1
Base.keys(st::Subtree) = KeyView(st)

## The empty! function deletes all data in the balanced tree.
## Therefore, it invalidates all indices.

function empty!(t::BalancedTree23)
    resize!(t.data,0)
    resize!(t.tree,0)
    t.depth = 1
    t.rootloc = 1
    t.freetreeinds = Array(Int,0)
    t.freedatainds = Array(Int,0)
    empty!(t.useddatacells)
    nothing
end

## Default implementations of eq for Forward, Reverse
## and default ordering

eq(::ForwardOrdering, a, b) = isequal(a,b)
eq(::ReverseOrdering{ForwardOrdering}, a, b) = isequal(a,b)
eq(o::Ordering, a, b) = !lt(o, a, b) && !lt(o, b, a)

function keybucket(o, st, k)
    lt(o, k, keys(st)[1])? 1 :
    (length(children(st)) == 2 || lt(o, k, keys(st)[2])) ? 2 : 3
end

function keybucketle(o, st, k)
    !lt(o,keys(st)[1], k)  ? 1 :
    (length(children(st)) == 2 || !lt(o,keys(st)[2], k)) ? 2 : 3
end

## The findkey function finds the index of a (key,data) pair in the tree 
## where the given key lives (if it is present), or
## if the key is not present, to the lower bound for the key,
## i.e., the data item that comes immediately before it.
## If there are multiple equal keys, then it finds the last one.
## It returns the index of the key found and a boolean indicating
## whether the exact key was found or not.

function _findkey(t::BalancedTree23, k)
    curnode = AbstractTrees.descend(st->(st.level == t.depth) ? 0 :
        keybucket(t.ord, st, k),children(t))
    curnode, eq(t.ord, t.data[curnode.idx].k, k)
end
function findkey(t::BalancedTree23, k)
    curnode, exactfound = _findkey(t, k)
    curnode.idx, exactfound
end



## The findkeyless function finds the index of a (key,data) pair in the tree that
## with the greatest key that is less than the given key.  If there is no
## key less than the given key, then it returns 1 (the before-start node).

function findkeyless(t::BalancedTree23, k)
    curnode = AbstractTrees.descend(st->(st.level == t.depth) ? 0 :
        keybucketle(t.ord, st, k),t)
    curnode.idx, eq(t.ord, t.data[curnode.idx].k, k)
end

"""
    Set the parent of the node `child` (either a tree or a data node) to
    `newparent`
"""
function replaceparent!(child::Subtree, newparent)
    if child.level == child.tree.depth
        child.tree.data = 
            KDRec{K,D}(newparent, data[whichind].k, data[whichind].d)
    else
        child.tree.tree[child.idx] = TreeNode{K}(tree, parent = newparent)
    end
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

function fix_links!(st::Subtree)
    for child in children(st)
        replaceparent!(child, st.idx)
    end
end

## Function insert! 

"""
# Insert a new data item into the tree.

The `k`,`d` arguments are the pair to insert.
The return values are a bool and an index.
bool indicates whether the insertion inserted a new record (true) or 
whether it replaced an existing record (false).
The index returned is the subscript in t.data where the inserted value sits.
"allowdups" (i.e., "allow duplicate keys") means that no check is 
done whether the iterm is already in the tree, so insertion of a new
item always succeeds.
"""
function insert!{K,D,Ord <: Ordering}(t::BalancedTree23{K,D,Ord}, k, d, allowdups::Bool)    
    ## If empty, insert a root
    if t.rootloc == 0
        t.rootloc = push_or_reuse!(t.data, t.freedatainds, KDRec{K,D}(0,k,d))
        push!(t.useddatacells, t.rootloc)
        return false, t.rootloc
    end
    
    ## First we find the greatest data node that is <= k (unless k is the
    ## smallest node, in which case we get the smallest data node)
    node, exactfound = _findkey(t, k)
    
    ## If we have found exactly k in the tree, then we
    ## replace the data associated with k and return.
    if exactfound && !allowdups
        node[] = KDRec{K,D}(parentind(node), k,d)
        return false, node.idx
    end
    
    ## Store the new data item in the tree's data array.
    newind =
        push_or_reuse!(t.data, t.freedatainds, KDRec{K,D}(parentind(node),k,d))
    push!(t.useddatacells, newind)
    
    # Given a node and a minimum key/index to be inserted, get the in-order
    # arrays of child-indices and splitkeys for the new node(s)
    function nnars(node, newind, minkeynewchild)
        bucket = keybucket(t.ord, node, minkeynewchild)
        (insert!(map(st->st.idx,children(node)),bucket+1,newind),
         insert!(collect(keys(node)), bucket, minkeynewchild))
    end
    
    minkeynewchild = k
    local newparentnum::Int
    local splitroot = true
    
    # Ascend the tree splitting 3-child nodes, until we hit a 2-child note
    # newind is the index of the currently pending subtree, minkeynewchild the
    # minimum key in that subtree
    node = ascend(node) do node
        isleaf(node) && return true
        length(children(node)) == 3 || (splitroot = false; return false)
        cchildren, ckeys = nnars(node, newind, minkeynewchild)
        # Note: We reuse to the key, to avoid having to conjure up an invalid
        # key, since we don't know anything about the type of the key
        node[] = TreeNode{K}(cchildren[1:2]...,0,parentind(node),ckeys[1],ckeys[1])
        minkeynewchild = ckeys[2]
        newnode = TreeNode{K}(cchildren[3:4]...,0,parentind(node),ckeys[3],ckeys[3])
        newind = push_or_reuse!(t.tree, t.freetreeinds, newnode)
        fix_links!(Subtree(t, newind, node.level))
        return true
    end

    # We've only encounterd 3-child nodes on our way up the tree, create new root
    if isroot(node) && splitroot
        newnode = if isleaf(node)
            # In the ascend above, we maintain the invariant that the newind
            # subtree has larger keys than the node subtree, but if we're still
            # at the leaf level, we never established that, so we need to take
            # special care
            splitkey = max(t.data[node.idx].k, k)
            TreeNode{K}(
                (splitkey == k ? (t.rootloc,newind) : (newind, t.rootloc))...,
                0,0,splitkey,splitkey)
        else
            TreeNode{K}(t.rootloc,newind,0,0,minkeynewchild,minkeynewchild)
        end
        t.rootloc = push_or_reuse!(t.tree, t.freetreeinds, newnode)
        t.depth += 1
        fix_links!(Subtree(t, t.rootloc, 0))
    else
        # Similar problem as above - the invariant was not established
        firstchildidx = first(children(node)).idx
        if level(node) == t.depth - 1 &&
                lt(t.ord, k, t.data[firstchildidx].k)
            children(node)[1] = newind
            newind, minkeynewchild = firstchildidx, t.data[firstchildidx].k
        end
        cchildren, ckeys = nnars(node, newind, minkeynewchild)
        node[] = TreeNode{K}(cchildren..., parentind(node), ckeys...)
    end
    true, newind
end

"""
 This function takes two indices into t.data and checks which
 one comes first in the sorted order by chasing them both
 up the tree until a common ancestor is found.  
 The return value is -1 if i1 precedes i2, 0 if i1 == i2
, 1 if i2 precedes i1.
"""
function compareInd(t::BalancedTree23, i1::Int, i2::Int)
    @assert(i1 in t.useddatacells && i2 in t.useddatacells)
    (i1 == i2) && return 0
    x1 = p1 = parent(tree, i1), x2 = p2 = parent(tree, i2)
    while true
        (p1 == p2) && return relative_state(p1, x1) < relative_state(p1, x2) ? -1 : 1
        x1 = p1, x2 = p2
        p1 = parent(tree, p1), p2 = parent(tree, p2)
    end
end        


## beginloc, endloc return the index (into t.data) of the first, last item in the 
## sorted order of the tree. 
beginloc(t::BalancedTree23) = first(Leaves(t)).idx
endloc(t::BalancedTree23) = last(Leaves(t)).idx


function delete_child!(p, node)
    children(p)[1] == node && (children(p)[1] = children(p)[2])
    children(p)[3] != node && (children(p)[2] = children(p)[3])
    children(p)[3] = 0
end

# Liquidate a parent and its children into one combined arrays
function liquidate(p)
    cchildren = Any[]
    ckeys = Any[]
    for (i,child) in enumerate(children(p))
        (i != 1) && push!(ckeys,keys(p)[i-1])
        append!(cchildren, map(st->st.idx,children(child)))
        append!(ckeys, collect(keys(child)))
    end
    ckeys, cchildren
end

function update!(st::Subtree, ckeys, cchildren)
    children(st)[3] = 0
    for (i,key) in enumerate(ckeys)
        keys(st)[i] = key
    end
    for (i,child) in enumerate(cchildren)
        children(st)[i] = child
    end
end

function deallocate!(st::Subtree)
    if isleaf(st)
        push!(st.tree.freedatainds, st.idx)
        pop!(st.tree.useddatacells, st.idx)
    else
        push!(st.tree.freetreeinds, st.idx)
    end
end

"""
# Deletes an entry from the balanced tree.

 For a high level overview of the algorithm, see e.g.
 http://www-bcf.usc.edu/~dkempe/CS104/11-19.pdf
"""
function delete!{K,D,Ord<:Ordering}(t::BalancedTree23{K,D,Ord}, it::Int)
    node = Subtree(t, it, t.depth)

    # Handle the case where there's only one (leaf) node, since we can't
    # look at the parent in that case
    isroot(node) && (deallocate!(node); t.rootloc = t.depth = 0; return)
    
    p = parent(node)
    
    # Ok, delete the child from this node
    delete_child!(p, node)
    deallocate!(node)
    
    # If it still has two children we're done
    (length(children(p)) == 2) && return
    
    # If not, we need to go up and contract the tree
    ascend(p) do node
        if isroot(node)
            # We're done, contract the tree
            t.rootloc = first(children(node)).idx
            deallocate!(node)
            t.depth -= 1
            replaceparent!(Subtree(t,t.rootloc,0), 0)
            return false
        end
        
        p = parent(node)

        # Determine if any of our siblings have 3 children
        siblings = collect(children(p))
        fatsibling = findfirst(sibling->length(children(sibling)) == 3, siblings)
        if fatsibling != 0
            # Borrow node from fat sibling. To do, this take the parent key
            # that used to be between us and our sibling and move it into our
            # node.
            splitkeys, cchildren = liquidate(p)
            update!(siblings[1], (splitkeys[1],), cchildren[1:2])
            keys(p)[1] = splitkeys[2]; children(p)[3] = 0
            update!(siblings[2], (splitkeys[3],), cchildren[3:4])
            if length(siblings) == 3
                keys(p)[2] = splitkeys[4]
                update!(siblings[3], (splitkeys[5],), cchildren[5:end])
            end
            fix_links!(siblings[1]); fix_links!(siblings[2])
            return false
        elseif length(children(p)) == 3
            # Borrow from parent
            splitkeys, cchildren = liquidate(p)
            # There's an ambiguity here as to whether the left child or the
            # right child should be fat. We always choose the left for no
            # particular reason
            other_sibs = collect(filter(sib->sib != node, siblings))
            update!(other_sibs[1], splitkeys[1:2], cchildren[1:3])
            keys(p)[1] = splitkeys[3]; children(p)[3] = 0
            update!(other_sibs[2], (splitkeys[4],), cchildren[4:5])
            fix_links!(other_sibs[1]); fix_links!(other_sibs[2])
            return false
        else
            # Combine with sibling
            other_sib = first(filter(sib->sib != node, siblings))
            splitkeys, cchildren = liquidate(p)
            update!(other_sib, splitkeys, cchildren)
            fix_links!(other_sib)
            delete_child!(p, node)
            deallocate!(node)
            return true
        end
    end
end
