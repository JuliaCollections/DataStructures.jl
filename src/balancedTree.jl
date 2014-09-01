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
## called the "leaves" in this file, sit about one more layer
## of data nodes, which are stored in a different array.  


## KDRec is one data node:
##  k: the key of the node
##  d: the data of the node
##  parent: the tree leaf that is the parent of this
##    node.  Parent pointers are needed in order
##    to implement indices.
##  There are two constructors, the standard one (first)
##  and the incomplete one (second).  The incomplete constructor
##  is needed because when the data structure is first created,
##  there are no valid K or D values to store in the initial
##  data nodes.


using Order

immutable KDRec{K,D}
    parent::Int
    k::K
    d::D
    function KDRec(p::Int, k1::K, d1::D)
        new(p,k1,d1)
    end
    function KDRec(p::Int)
        new(p)
    end
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

immutable TreeNode{K}
    child1::Int
    child2::Int
    child3::Int
    parent::Int
    splitkey1::K
    splitkey2::K
    function TreeNode(::Type{K}, c1::Int, c2::Int, c3::Int, p::Int)
        new(c1, c2, c3, p)
    end
    function TreeNode(c1::Int, c2::Int, c3::Int,
                      p::Int, sk1::K, sk2::K)
        new(c1, c2, c3, p, sk1, sk2)
    end
end



## The next two functions are called to initialize the tree
## by inserting a dummy tree node with two children, the before-start
## marker whose index is 1 and the after-end marker whose index is 2.
## These two markers live in dummy data nodes.

function initializeTree!{K}(tree::Array{TreeNode{K},1})
    resize!(tree,1)
    tree[1] = TreeNode{K}(K, 1, 2, 0, 0)
end

function initializeData!{K,D}(data::Array{KDRec{K,D},1})
    resize!(data, 2)
    data[1] = KDRec{K,D}(1)
    data[2] = KDRec{K,D}(1)
end


## Type BalancedTree{K,D,Ord} is 'base class' for
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
## useddatacells: IntSet (i.e., bit vector) showing which
##    data cells are taken.  The complementary positions are
##    exactly those stored in freedatainds.  This array is
##    used only for error checking (only present at debug level 1 and 2)
## deletionchild and deletionleftkey are two work-arrays
## for the delete function.

type BalancedTree{K, D, Ord <: Ordering}
    ord::Ord
    data::Array{KDRec{K,D}, 1}
    tree::Array{TreeNode{K}, 1}
    rootloc::Int
    depth::Int
    freetreeinds::Array{Int,1}
    freedatainds::Array{Int,1}
    useddatacells::IntSet 
    # The next two arrays are used as a workspace by the delete!
    # function.
    deletionchild::Array{Int,1}
    deletionleftkey::Array{K,1}
    function BalancedTree(ord1::Ord)
        tree1 = Array(TreeNode{K}, 1)
        initializeTree!(tree1)
        data1 = Array(KDRec{K,D}, 2)
        initializeData!(data1)
        u1 = IntSet()
        push!(u1, 1)
        push!(u1, 2)
        new(ord1, data1, tree1, 1, 1, Array(Int,0), Array(Int,0), 
            u1, 
            Array(Int,3), Array(K,3))
    end
end


## Function cmp2 checks a tree node with two children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey or 2 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp2{K, Ord <: Ordering}(o::Ord, 
                                  treenode::TreeNode{K}, 
                                  k::K, 
                                  isleaf::Bool)
    ((isleaf && treenode.child2 == 2) || 
     lt(o, k, treenode.splitkey1))? 1 : 2
end


## Function cmp2le checks a tree node with two children
## against a given key, and returns 1 if the given key is
## less than or equal to the node's splitkey or 2 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp2le{K, Ord <: Ordering}(o::Ord, 
                                    treenode::TreeNode{K}, 
                                    k::K, 
                                    isleaf::Bool)
    ((isleaf && treenode.child2 == 2) || 
     !lt(o,treenode.splitkey1,k))? 1 : 2
end



## Function cmp3 checks a tree node with three children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey1, 2 if less than splitkey2, or
## 3 else. Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp3{K, Ord <: Ordering}(o::Ord,
                                  treenode::TreeNode{K}, 
                                  k::K, 
                                  isleaf::Bool)
    (lt(o, k, treenode.splitkey1))? 1 :
    (((isleaf && treenode.child3 == 2) || 
      lt(o, k, treenode.splitkey2))? 2 : 3)
end

## Function cmp3le checks a tree node with three children
## against a given key, and returns 1 if the given key is
## less than or equal to the node's splitkey1, 2 if less than or equal 
## to splitkey2, or
## 3 else. Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp3le{K, Ord <: Ordering}(o::Ord,
                                    treenode::TreeNode{K}, 
                                    k::K, 
                                    isleaf::Bool)
    (!lt(o,treenode.splitkey1,k))? 1 :
    (((isleaf && treenode.child3 == 2) || 
      !lt(o,treenode.splitkey2,k))? 2 : 3)
end


## The empty! function deletes all data in the balanced tree.
## Therefore, it invalidates all indices.

function empty!{K,D,Ord <: Ordering}(t::BalancedTree{K,D,Ord})
    resize!(t.data,2)
    initializeData!(t.data)
    resize!(t.tree,1)
    initializeTree!(t.tree)
    t.depth = 1
    t.rootloc = 1
    t.freetreeinds = Array(Int,0)
    t.freedatainds = Array(Int,0)
    empty!(t.useddatacells)
    push!(t.useddatacells,1)
    push!(t.useddatacells,2)
end

## Default implementations of eq for Forward and Reverse
## ordering

eq(::ForwardOrdering, a, b) = isequal(a,b)
eq(::ReverseOrdering{ForwardOrdering}, a, b) = isequal(a,b)


## The findkey function finds the index of a (key,data) pair in the tree that
## where the given key lives (if it is present), or
## if the key is not present, to the lower bound for the key,
## i.e., the data item that comes immediately before it.
## If there are multiple equal keys, then it finds the last one.

function findkey{K,D, Ord <: Ordering}(t::BalancedTree{K,D,Ord}, k::K)
    curnode = t.rootloc
    for depthcount = 1 : t.depth
        isleaf = (depthcount == t.depth)
        cmp = (t.tree[curnode].child3 == 0)?
        cmp2(t.ord, t.tree[curnode], k, isleaf) :
        cmp3(t.ord, t.tree[curnode], k, isleaf)
        curnode = (cmp == 1)? t.tree[curnode].child1 :
        ((cmp == 2)? t.tree[curnode].child2 : t.tree[curnode].child3)

    end
    return curnode, (curnode > 2 && eq(t.ord, t.data[curnode].k, k))
end


## The findkeyless function finds the index of a (key,data) pair in the tree that
## with the greatest key that is less than the given key.  If there is no
## key less than the given key, then it returns 1 (the before-start node).

function findkeyless{K, D, Ord <: Ordering}(t::BalancedTree{K,D,Ord}, k::K)
    curnode = t.rootloc
    for depthcount = 1 : t.depth
        isleaf = (depthcount == t.depth)
        cmp = (t.tree[curnode].child3 == 0)?
        cmp2le(t.ord, t.tree[curnode], k, isleaf) :
        cmp3le(t.ord, t.tree[curnode], k, isleaf)
        curnode = (cmp == 1)? t.tree[curnode].child1 :
        ((cmp == 2)? t.tree[curnode].child2 : t.tree[curnode].child3)
    end
    curnode
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

function insert!{K,D, Ord <: Ordering}(t::BalancedTree{K,D,Ord}, 
                                       k::K, 
                                       d::D, 
                                       allowdups::Bool)
    
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
        @assert(t.rootloc == 1 && t.depth == 1)
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
    # that duplicates are allowed.
    # In this case we insert a new node.
    depth = t.depth

    ## Check if there is a free space in the 
    ## data array (due to previous deletions);
    ## if so, use it, else create a new space.
    if size(t.freedatainds,1) == 0
        newind = size(t.data, 1) + 1
        pushdata = true
    else
        newind = pop!(t.freedatainds)
        pushdata = false
    end
    p1 = parent
    oldchild = leafind
    newchild = newind
    minkeynewchild = k
    splitroot = false
    curdepth = depth

    ## This loop ascends the tree (i.e., follows a path from a leaf to the root)
    ## starting from the parent p1 of 
    ## where the new key k would go.  For each 3-node we encounter
    ## during the ascent, we add a new child, which requires splitting
    ## the 3-node into two 2-nodes.  Then we keep going until we hit the root.
    ## If we encounter a 2-node, then the ascent can stop; we can 
    ## change the 2-node to a 3-node with the new child. Invariant fields
    ## during this loop are:
    ##     p1: the parent node (a tree node index) where the insertion must occur
    ##     oldchild,newchild: the two children of the parent node; oldchild
    ##          was already in the tree; newchild was just added to it.
    ##     minkeynewchild:  This is the key that is the minimum value in
    ##         the subtree rooted at newchild.

    while true
        isleaf = (curdepth == depth)
        oldtreenode = t.tree[p1]

        ## If we hit a 3-node, then there are three cases for how to
        ## insert new child; all three cases involve splitting the
        ## existing node (oldtreenode, numbered p1) into
        ## two new nodes.  One keeps the index p1; the other has 
        ## has a new index called newparentnum.

        if oldtreenode.child3 > 0
            cmp = cmp3(oldtreenode, minkeynewchild, isleaf)
            if cmp == 1
                lefttreenodenew = TreeNode{K}(oldtreenode.child1, newchild, 0,
                                              oldtreenode.parent,
                                              minkeynewchild, minkeynewchild)
                righttreenodenew = TreeNode{K}(oldtreenode.child2, oldtreenode.child3, 0,
                                               oldtreenode.parent, oldtreenode.splitkey2, 
                                               oldtreenode.splitkey2)
                minkeynewchild = oldtreenode.splitkey1
                whichp = 1
            elseif cmp == 2
                # @assert(oldtreenode.child2 == oldchild)
                lefttreenodenew = TreeNode{K}(oldtreenode.child1, oldtreenode.child2, 0,
                                              oldtreenode.parent,
                                              oldtreenode.splitkey1, oldtreenode.splitkey1)
                righttreenodenew = TreeNode{K}(newchild, oldtreenode.child3, 0,
                                               oldtreenode.parent,
                                               oldtreenode.splitkey2, oldtreenode.splitkey2)
                whichp = 2
            else
                # @assert(oldtreenode.child3 == oldchild)
                lefttreenodenew = TreeNode{K}(oldtreenode.child1, oldtreenode.child2, 0,
                                              oldtreenode.parent,
                                              oldtreenode.splitkey1, oldtreenode.splitkey1)
                righttreenodenew = TreeNode{K}(oldtreenode.child3, newchild, 0,
                                               oldtreenode.parent,
                                               minkeynewchild, minkeynewchild)
                minkeynewchild = oldtreenode.splitkey2
                whichp = 2
            end
            # Replace p1 with a new 2-node and insert another 2-node at
            # index newparentnum.
            t.tree[p1] = lefttreenodenew
            if size(t.freetreeinds,1) == 0
                push!(t.tree, righttreenodenew)
                newparentnum = size(t.tree,1)
            else
                newparentnum = pop!(t.freetreeinds)
                t.tree[newparentnum] = righttreenodenew
            end
            if isleaf
                # If we inserted the leaf above the new data, then
                # we should also insert the new data itself.
                par = (whichp == 1)? p1 : newparentnum
                if pushdata
                    push!(t.data, KDRec{K,D}(par, k,d))
                else
                    t.data[newind] = KDRec{K,D}(par, k,d)
                end
                push!(t.useddatacells, newind)

                # The two children of the node at newparentnum (data nodes) 
                # have a new parent (newparentnum instead of p1)
                # so we have to fix them.

                for childind = 1 : 2
                    procchild = (childind == 1)? righttreenodenew.child1 : righttreenodenew.child2
                    olddata = t.data[procchild]
                    @inbounds t.data[procchild] = KDRec{K,D}(newparentnum, olddata.k, olddata.d)
                end
            else

                # If this is not a leaf, we still have to fix the
                # parent fields of the two nodes that are now children
                ## of the newparent.
                for childind = 1 : 2
                    procchild = (childind == 1)? righttreenodenew.child1 : righttreenodenew.child2
                    oldtreenode = t.tree[procchild]
                    @inbounds t.tree[procchild] = TreeNode{K}(oldtreenode.child1, oldtreenode.child2,
                                                    oldtreenode.child3, newparentnum,
                                                    oldtreenode.splitkey1, oldtreenode.splitkey2)
                end
            end
            ## If p1 is the root (i.e., we have encountered only 3-nodes during
            ## our ascent of the tree), then the root must be split.
            oldchild = p1
            newchild = newparentnum

            if p1 == t.rootloc
                @assert(curdepth == 1)
                splitroot = true
                break
            end
            p1 = t.tree[oldchild].parent
        else

            ## If our ascent reaches a 2-node, then we convert it to
            ## a 3-node by giving it a child3 field that is >0.
            ## Encountering a 2-node halts the ascent up the tree.

            t.tree[p1] = (cmp2(oldtreenode, minkeynewchild, isleaf) == 1)?
                TreeNode{K}(oldtreenode.child1, newchild, oldtreenode.child2,
                            oldtreenode.parent,
                            minkeynewchild, oldtreenode.splitkey1) :
                TreeNode{K}(oldtreenode.child1, oldtreenode.child2, newchild,
                            oldtreenode.parent,
                            oldtreenode.splitkey1, minkeynewchild)
            if isleaf
                if pushdata
                    push!(t.data,KDRec{K,D}(p1, k, d))
                else
                    t.data[newind] = KDRec{K,D}(p1, k,d)
                end
                push!(t.useddatacells, newind)
            end
            break
        end
        curdepth -= 1
    end

    ## Splitroot is set if the ascent of the tree encountered only 3-nodes.
    ## In this case, the root itself was replaced by two nodes, so we need
    ## a new root above those two.

    if splitroot
        newroot = TreeNode{K}(oldchild, newchild, 0, 0,
                              minkeynewchild, minkeynewchild)
        if size(t.freetreeinds,1) == 0
            push!(t.tree, newroot)
            newrootloc = size(t.tree,1)
        else
            newrootloc = pop!(t.freetreeinds)
            t.tree[newrootloc] = newroot
        end
        for whichchild = 1 : 2
            procchild = (whichchild == 1)? oldchild : newchild
            childrec = t.tree[procchild]
            @inbounds t.tree[procchild] = TreeNode{K}(childrec.child1, childrec.child2,
                                            childrec.child3, newrootloc,
                                            childrec.splitkey1, childrec.splitkey2)
        end
        t.rootloc = newrootloc
        t.depth += 1
    end
    true, newind
end




## nextloc0: returns the next item in the tree according to the
## sort order, given an index i (subscript of t.data) of a current
## item. 
## The routine returns 2 if there is no next item (i.e., we started
## from the last one in the sorted order).

function nextloc0{K, D, Ord <: Ordering}(t::BalancedTree{K,D,Ord}, i::Int)
    ii = i
    @assert(i != 2 && in(i,t.useddatacells))
    p = t.data[i].parent
    nextchild = 0
    depthp = t.depth
    while true
        if depthp < t.depth
            p = t.tree[ii].parent
        end
        if t.tree[p].child1 == ii
            nextchild = t.tree[p].child2
            break
        end
        @inbounds if t.tree[p].child2 == ii && t.tree[p].child3 > 0
            nextchild = t.tree[p].child3
            break
        end
        if p == t.rootloc
            return 2
        end
        ii = p
        depthp -= 1
    end
    while true
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


function prevloc0{K,D, Ord <: Ordering}(t::BalancedTree{K,D,Ord}, i::Int)
    @assert(i != 1 && in(i,t.useddatacells))
    ii = i
    p = t.data[i].parent
    prevchild = 0
    depthp = t.depth
    while true
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
        if p == t.rootloc
            return 1
        end
        ii = p
        depthp -= 1
    end
    while true
        if depthp == t.depth
            return prevchild
        end
        p = prevchild
        c3 = t.tree[p].child3
        prevchild = c3 > 0? c3 : t.tree[p].child2
        depthp += 1
    end
end


## beginloc, endloc return the index (into t.data) of the first, last item in the 
## sorted order of the tree.  beginloc works by going to the before-start marker
## (data node 1) and executing a next operation on it.  endloc is the opposite.

function beginloc{K, D, Ord <: Ordering}(t::BalancedTree{K,D,Ord})
    nextloc0(t,1)
end

function endloc{K, D, Ord <: Ordering }(t::BalancedTree{K,D,ord})
    prevloc0(t,2)
end


## The following are helper routines for the delete! function.

function replaceparent!{K,D}(data::Array{KDRec{K,D},1}, whichind::Int, newparent::Int)
    data[whichind] = KDRec{K,D}(newparent, data[whichind].k, data[whichind].d)
end

function replaceparent!{K}(tree::Array{TreeNode{K},1}, whichind::Int, newparent::Int)
    tree[whichind] = TreeNode{K}(tree[whichind].child1, tree[whichind].child2,
                                 tree[whichind].child3, newparent,
                                 tree[whichind].splitkey1, 
                                 tree[whichind].splitkey2)
end
 


## delete! routine deletes an entry from the balanced tree.

function delete!{K, D, Ord <: Ordering}(t::BalancedTree{K,D,Ord}, it::Int)
    
    ## Put the cell indexed by 'it' into the deletion list.
    ##
    ## Create the following data items maintained in the 
    ## upcoming loop.
    ##
    ## p is a tree-node ancestor of the deleted node
    ## The children of p are stored in
    ## t.deletionchild[..]
    ## The number of these children are newchildcount, which is 1, 2 or 3.
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
    @assert(newchildcount == 1 || newchildcount == 2)
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
        @inbounds if newchildcount == 2
            t.tree[p] = TreeNode{K}(t.deletionchild[1],
                                    t.deletionchild[2], 0, pparent,
                                    t.deletionleftkey[2], defaultKey)

            break
        end
        @inbounds if newchildcount == 3
            t.tree[p] = TreeNode{K}(t.deletionchild[1], t.deletionchild[2],
                                    t.deletionchild[3], pparent, 
                                    t.deletionleftkey[2], t.deletionleftkey[3])
            break
        end
        @assert(newchildcount == 1)
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
            @inbounds rightsib = t.tree[pparent].child2
            
            ## Here p is child1 and rightsib is child2.  
            ## If rightsib has 2 children, then p and 
            ## rightsib are merged into a single node
            ## that has three children.
            ## If rightsib has 3 children, then p and
            ## rightsib are reformed so that each has
            ## two children.

            if t.tree[rightsib].child3 == 0
                @inbounds rc1 = t.tree[rightsib].child1
                @inbounds rc2 = t.tree[rightsib].child2
                @inbounds t.tree[p] = TreeNode{K}(t.deletionchild[1],
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
                @inbounds t.deletionchild[1] = p
            else
                @inbounds rc1 = t.tree[rightsib].child1
                @inbounds t.tree[p] = TreeNode{K}(t.deletionchild[1], rc1, 0,
                                        pparent,
                                        t.tree[pparent].splitkey1, 
                                        defaultKey)
                @inbounds sk1 = t.tree[rightsib].splitkey1
                @inbounds t.tree[rightsib] = TreeNode{K}(t.tree[rightsib].child2,
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
                @inbounds t.deletionchild[1] = p
                @inbounds t.deletionchild[2] = rightsib
                @inbounds t.deletionleftkey[2] = sk1
            end 
            
            ## If pparent had a third child (besides p and rightsib)
            ## then we add this to t.deletionchild
            
            @inbounds c3 = t.tree[pparent].child3
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

            @inbounds leftsib = t.tree[pparent].child1
            @inbounds lk = deletionleftkey1_valid? 
            t.deletionleftkey[1] : t.tree[pparent].splitkey1
            if t.tree[leftsib].child3 == 0
                @inbounds lc1 = t.tree[leftsib].child1
                @inbounds lc2 = t.tree[leftsib].child2
                @inbounds t.tree[p] = TreeNode{K}(lc1, lc2,
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
                @inbounds lc3 = t.tree[leftsib].child3
                @inbounds t.tree[p] = TreeNode{K}(lc3, t.deletionchild[1], 0,
                                        pparent, lk, defaultKey)
                @inbounds sk2 = t.tree[leftsib].splitkey2
                @inbounds t.tree[leftsib] = TreeNode{K}(t.tree[leftsib].child1,
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
                @inbounds t.deletionchild[1] = leftsib
                @inbounds t.deletionchild[2] = p
                @inbounds t.deletionleftkey[2] = sk2
            end
            
            ## If pparent had a third child (besides p and leftsib)
            ## then we add this to t.deletionchild
            
            @inbounds c3 = t.tree[pparent].child3
            if c3 > 0
                newchildcount += 1
                t.deletionchild[newchildcount] = c3
                @inbounds t.deletionleftkey[newchildcount] = t.tree[pparent].splitkey2
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
            
            @assert(t.tree[pparent].child3 == p)
            @inbounds leftsib = t.tree[pparent].child2
            @inbounds lk = deletionleftkey1_valid? 
            t.deletionleftkey[1] : t.tree[pparent].splitkey2
            @inbounds if t.tree[leftsib].child3 == 0
                @inbounds lc1 = t.tree[leftsib].child1
                @inbounds lc2 = t.tree[leftsib].child2
                @inbounds t.tree[p] = TreeNode{K}(lc1, lc2,
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
                @inbounds t.deletionchild[1] = t.tree[pparent].child1
                @inbounds t.deletionleftkey[2] = t.tree[pparent].splitkey1
                @inbounds t.deletionchild[2] = p
            else
                @inbounds lc3 = t.tree[leftsib].child3
                @inbounds t.tree[p] = TreeNode{K}(lc3, t.deletionchild[1], 0,
                                        pparent, lk, defaultKey)
                @inbounds sk2 = t.tree[leftsib].splitkey2
                @inbounds t.tree[leftsib] = TreeNode{K}(t.tree[leftsib].child1,
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
                @inbounds t.deletionchild[1] = t.tree[pparent].child1
                @inbounds t.deletionchild[2] = leftsib
                @inbounds t.deletionchild[3] = p
                @inbounds t.deletionleftkey[2] = t.tree[pparent].splitkey1
                @inbounds t.deletionleftkey[3] = sk2
            end
            p = pparent
            deletionleftkey1_valid = false
        end
        curdepth -= 1
    end
    if mustdeleteroot
        @assert(!deletionleftkey1_valid)
        @assert(p == t.rootloc)
        @inbounds t.rootloc = t.deletionchild[1]
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
            @inbounds pparentnode = t.tree[pparent]
            @inbounds if pparentnode.child2 == p
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
                @assert(curdepth > 0)
            end
        end
    end                                  
end



