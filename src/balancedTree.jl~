## This file implements 2-3 trees for sorted containers.
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


## Type BalancedTree{K,D} is 'base class' for
## SortedDict, MultiMap, SortedSet.  
## K = key type, D = data type
## Key type must support 'isless' operation.
## Ideally, it also supports isequal_l (equality relationship
## compatible with isless)
## but a generic versions of the isequal_l function appear below.
## The fields are as follows.
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

type BalancedTree{K,D}
    data::Array{KDRec{K,D}, 1}
    tree::Array{TreeNode{K}, 1}
    rootloc::Int
    depth::Int
    freetreeinds::Array{Int,1}
    freedatainds::Array{Int,1}
    useddatacells::IntSet 
    # The next four arrays are used as a workspace by the delete!
    # function.
    deletionchild::Array{Int,1}
    deletionleftkey::Array{K,1}
    function BalancedTree()
        tree1 = Array(TreeNode{K}, 1)
        initializeTree!(tree1)
        data1 = Array(KDRec{K,D}, 2)
        initializeData!(data1)
        u1 = IntSet()
        push!(u1, 1)
        push!(u1, 2)
        new(data1, tree1, 1, 1, Array(Int,0), Array(Int,0), 
            u1, 
            Array(Int,3), Array(K,3))
    end
end


## Function cmp2 checks a tree node with two children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey or 2 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp2{K}(treenode::TreeNode{K}, k::K, isleaf::Bool)
    ((isleaf && treenode.child2 == 2) || 
     isless(k, treenode.splitkey1))? 1 : 2
end


## Function cmp2le checks a tree node with two children
## against a given key, and returns 1 if the given key is
## less than or equal to the node's splitkey or 2 else.  Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp2le{K}(treenode::TreeNode{K}, k::K, isleaf::Bool)
    ((isleaf && treenode.child2 == 2) || 
     !isless(treenode.splitkey1,k))? 1 : 2
end



## Function cmp3 checks a tree node with three children
## against a given key, and returns 1 if the given key is
## less than the node's splitkey1, 2 if less than splitkey2, or
## 3 else. Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp3{K}(treenode::TreeNode{K}, k::K, isleaf::Bool)
    (isless(k, treenode.splitkey1))? 1 :
    (((isleaf && treenode.child3 == 2) || 
      isless(k, treenode.splitkey2))? 2 : 3)
end

## Function cmp3le checks a tree node with three children
## against a given key, and returns 1 if the given key is
## less than or equal to the node's splitkey1, 2 if less than or equal 
## to splitkey2, or
## 3 else. Special case
## if the node is a leaf and its right child is the end
## of the sorted order.

function cmp3le{K}(treenode::TreeNode{K}, k::K, isleaf::Bool)
    (!isless(treenode.splitkey1,k))? 1 :
    (((isleaf && treenode.child3 == 2) || 
      !isless(treenode.splitkey2,k))? 2 : 3)
end


## The empty! function deletes all data in the balanced tree.
## Therefore, it invalidates all indices.

function empty!{K,D}(t::BalancedTree{K,D})
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

## Default implementation of isequal_l.  For many built-in
## key types, isequal_l should be redefined by the user
## to be isequal, which is more efficient than the 
## default implementation below.
## However, Julia does not guarantee the logical
## relationship:
##   isequal(a,b)  <==>  !isless(a,b) && !isless(b,a)
## so isequal cannot be the default implementation of isequal_l.

function isequal_l(x::Any, y::Any)
    !isless(x,y) && !isless(y,x)
end



## The findkey function finds the index of a (key,data) pair in the tree that
## where the given key lives (if it is present), or
## if the key is not present, to the lower bound for the key,
## i.e., the data item that comes immediately before it.
## If there are multiple equal keys, then it finds the last one.

function findkey{K,D}(t::BalancedTree{K,D}, k::K)
    curnode = t.rootloc
    for depthcount = 1 : t.depth
        isleaf = (depthcount == t.depth)
        cmp = (t.tree[curnode].child3 == 0)?
        cmp2(t.tree[curnode], k, isleaf) :
        cmp3(t.tree[curnode], k, isleaf)
        curnode = (cmp == 1)? t.tree[curnode].child1 :
        ((cmp == 2)? t.tree[curnode].child2 : t.tree[curnode].child3)

    end
    return curnode, (curnode > 2 && isequal_l(t.data[curnode].k, k))
end


## The findkeyless function finds the index of a (key,data) pair in the tree that
## with the greatest key that is less than the given key.  If there is no
## key less than the given key, then it returns 1 (the before-start node).

function findkeyless{K,D}(t::BalancedTree{K,D}, k::K)
    curnode = t.rootloc
    for depthcount = 1 : t.depth
        isleaf = (depthcount == t.depth)
        cmp = (t.tree[curnode].child3 == 0)?
        cmp2le(t.tree[curnode], k, isleaf) :
        cmp3le(t.tree[curnode], k, isleaf)
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

function insert!{K,D}(t::BalancedTree{K,D}, k::K, d::D, allowdups::Bool)
    
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

function nextloc0{K,D}(t::BalancedTree{K,D}, i::Int)
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


function prevloc0{K,D}(t::BalancedTree{K,D}, i::Int)
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

function beginloc{K,D}(t::BalancedTree{K,D})
    nextloc0(t,1)
end

function endloc{K,D}(t::BalancedTree{K,D})
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

function delete!{K,D}(t::BalancedTree{K,D}, it::Int)
    
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
    ## for the for the immediate right neighbor of the 
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
    

    ## The following loop ascends the tree and contracts nodes (reduced their
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





## A SortedDict is a wrapper around balancedTree with
## methods similiar to those of Julia container Dict.

type SortedDict{K,D} <: Associative{K,D}
    bt::BalancedTree{K,D}
end


function SortedDict{K,D}(d::Dict{K,D})
    bt1 = BalancedTree{K,D}()
    for pr in d
        insert!(bt1, pr[1], pr[2], false)
    end
    SortedDict(bt1)
end


## A SortedDictIndex is a small structure for iterating
## over the items in a tree in sorted order.  It is
## a wrapper around an Int; the int is the index
## of the current item in t.data.  An iterator
## should never point to a deleted item.  An iterator
## that points to the before-start item (=1)
## or the after-end item (=2) cannot be  dereferenced.


immutable SortedDictIndex{K,D}
    address::Int
end


## This function implements m[k]; it returns the
## data item associated with key k.

function getindex{K,D}(m::SortedDict{K,D}, k::K)
    i, exactfound = findkey(m.bt, k)
    if !exactfound
        throw(KeyError(k))
    end
    return m.bt.data[i].d
end

## This function implements m[k]=d; it sets the 
## data item associated with key k equal to d.

function setindex!{K,D}(m::SortedDict{K,D}, d::D, k::K)
    insert!(m.bt, k, d, false)
end

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function ind_find{K,D}(m::SortedDict{K,D}, k::K)
    ll, exactfound = findkey(m.bt, k)
    exactfound?
    SortedDictIndex{K,D}(ll) :
    SortedDictIndex{K,D}(2)
end

## This function inserts an item into the tree.
## Unlike m[k]=d, it also returns a bool and a Index.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The index points to the newly inserted item.

function ind_insert!{K,D}(m::SortedDict{K,D}, k::K, d::D)
    b, i = insert!(m.bt, k, d, false)
    b, SortedDictIndex{K,D}(i)
end


## delete_ind! deletes an item given an index.

function delete_ind!{K,D}(m::SortedDict{K,D}, ii::SortedDictIndex{K,D})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
    end
    if ii.address < 3
        throw(BoundsError())
    end
    delete!(m.bt, ii.address)
end
    


## Function ind_first returns the index that points
## to the first sorted order of the tree.  It returns
## the past-end index (i.e., 2) if the tree is empty.

function ind_first{K,D}(m::SortedDict{K,D})
    SortedDictIndex{K,D}(beginloc(m.bt))
end

## Function is_ind_past_end tests whether an index is at the
## end marker.

function is_ind_past_end{K,D}(m::SortedDict{K,D}, ii::SortedDictIndex{K,D})
    ii.address == 2
end

## Function past_end returns the index past the end of the data.

function past_end{K,D}(m::SortedDict{K,D})
    SortedDictIndex{K,D}(2)
end

## Function before_start returns the index past the end of the data.

function before_start{K,D}(m::SortedDict{K,D})
    SortedDictIndex{K,D}(1)
end

## Function is_ind_before_start tests whether an index is before
## the start marker.

function is_ind_before_start{K,D}(m::SortedDict{K,D}, ii::SortedDictIndex{K,D})
    ii.address == 1
end


## Function advance_ind takes an index and returns the
## next index in the sorted order. 

function advance_ind{K,D}(m::SortedDict{K,D}, 
                         ii::SortedDictIndex{K,D})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("advance_ind invoked on deleted index")
    end
    if ii.address == 2
        throw(BoundsError())
        #error("advance_ind invoked on past-end data item")
    end

    SortedDictIndex{K,D}(nextloc0(m.bt, ii.address))
end


## Function regress_ind takes an index and returns the
## previous index in the sorted order. 

function regress_ind{K,D}(m::SortedDict{K,D}, 
                         ii::SortedDictIndex{K,D})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("regress_ind invoked on deleted index")
    end
    if ii.address == 1
        throw(BoundsError())
        #error("regress_ind invoked on before-start data item")
    end
    SortedDictIndex{K,D}(prevloc0(m.bt, ii.address))
end

## Endof returns the index of the last item in the sorted order,
## or the before-start marker if the SortedDict is empty.

function endof{K,D}(m::SortedDict{K,D})
    SortedDictIndex{K,D}(endloc(m.bt))
end

## First and last return the first and last (key,data) pairs
## in the SortedDict.  It is an error to invoke them on an
## empty SortedDict.

function first{K,D}(m::SortedDict{K,D})
    i = beginloc(m.bt)
    if i == 2
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end


function last{K,D}(m::SortedDict{K,D})
    i = endloc(m.bt)
    if i == 1
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end




## Function deref_ind(m,ii), where ii is an index, returns the
## (k,d) pair indexed by ii.

function deref_ind{K,D}(m::SortedDict{K,D}, 
                       ii::SortedDictIndex{K,D})
    addr = ii.address
    if addr < 3
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(addr, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return m.bt.data[addr].k, m.bt.data[addr].d
end

## Function deref_key_only_ind(m,ii), where ii is an index, returns the
## key indexed by ii.

function deref_key_only_ind{K,D}(m::SortedDict{K,D}, 
                                 ii::SortedDictIndex{K,D})
    addr = ii.address
    if addr < 3
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(addr, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry $ii")
    end
    return m.bt.data[addr].k
end

## This function takes a key and returns the index
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_equal_or_greater{K,D}(m::SortedDict{K,D}, k::K)
    i, exactfound = findkey(m.bt, k)
    exactfound?
    SortedDictIndex{K,D}(i) :
    SortedDictIndex{K,D}(nextloc0(m.bt, i))
end

## This function takes a key and returns an index
## to the first item in the tree that is > the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_greater{K,D}(m::SortedDict{K,D}, k::K)
    i, exactfound = findkey(m.bt, k)
    SortedDictIndex{K,D}(nextloc0(m.bt, i))
end



## The next three functions are for iterating over a SortedDict
## with a for-loop.

function start{K,D}(m::SortedDict{K,D})
    nextloc0(m.bt,1)
end


function done{K,D}(m::SortedDict{K,D}, state::Int)
    state == 2
end

function next{K,D}(m::SortedDict{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((m.bt.data[state].k, m.bt.data[state].d), nextloc0(m.bt, state))
end



    
type SortedDictRangeIteration{K,D}
    m::SortedDict{K,D}
    startit::Int
    endit::Int
end



## The next three functions are for iterating over a range of a
## SortedDict with a for-loop; the range is specified by a start
## and end index.


function sorted_dict_range_iteration{K,D}(m1::SortedDict{K,D},
                                           startit1::SortedDictIndex{K,D},
                                           endit1::SortedDictIndex{K,D})
    SortedDictRangeIteration(m1, startit1.address, endit1.address)
end




function start{K,D}(sodri::SortedDictRangeIteration{K,D})
    sodri.startit
end

function done{K,D}(sodri::SortedDictRangeIteration{K,D}, state::Int)
    state == 2 || state == sodri.endit
end

function next{K,D}(sodri::SortedDictRangeIteration{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, sodri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((sodri.m.bt.data[state].k, sodri.m.bt.data[state].d),
     nextloc0(sodri.m.bt, state))
end



type EnumerateSOD{K,D}
    m::SortedDict{K,D}
end


## The next three functions support "for p = enumerated_ind(m)... end"
## where m is a SortedDict.


function enumerate_ind{K,D}(m::SortedDict{K,D})
    EnumerateSOD{K,D}(m)
end

function start{K,D}(esod::EnumerateSOD{K,D})
    nextloc0(esod.m.bt,1)
end

function done{K,D}(esod::EnumerateSOD{K,D}, state::Int)
    state == 2
end

function next{K,D}(esod::EnumerateSOD{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, esod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((SortedDictIndex{K,D}(state), 
      (esod.m.bt.data[state].k,esod.m.bt.data[state].d)),
      nextloc0(esod.m.bt, state))
end

## These functions support "for p = enumerate_ind(sorted_dict_range_iteration(m,i1,i2))"

type EnumerateSODRI{K,D}
    sodri::SortedDictRangeIteration{K,D}
end

function enumerate_ind{K,D}(m::SortedDictRangeIteration{K,D})
    EnumerateSODRI{K,D}(m)
end


function start{K,D}(esodri::EnumerateSODRI{K,D})
    esodri.sodri.startit
end

function done{K,D}(esodri::EnumerateSODRI{K,D}, state::Int)
    state == 2 || state == esodri.sodri.endit
end

function next{K,D}(esodri::EnumerateSODRI{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, esodri.sodri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedDictIndex{K,D}(state), 
     (esodri.sodri.m.bt.data[state].k, esodri.sodri.m.bt.data[state].d)),
    nextloc0(esodri.sodri.m.bt, state)
end


function isempty{K,D}(m::SortedDict{K,D})
    size(m.bt.data,1) - size(m.bt.freedatainds, 1) == 2
end


## This function clears a SortedDict -- all items deleted.

function empty!{K,D}(m::SortedDict{K,D})
    empty!(m.bt)
end

function length{K,D}(m::SortedDict{K,D})
   size(m.bt.data,1) - size(m.bt.freedatainds, 1) - 2
end

function in{K,D}(p::(K,D), m::SortedDict{K,D})
    @inbounds i, exactfound = findkey(m.bt,p[1])
    @inbounds return exactfound && isequal(m.bt.data[i].d,p[2])
end

function eltype{K,D}(m::SortedDict{K,D})
    (K,D)
end

function haskey{K,D}(m::SortedDict{K,D}, k::K)
    i, exactfound = findkey(m.bt,k)
    exactfound
end

function get{K,D}(m::SortedDict{K,D}, k::K, default::D)
    i, exactfound = findkey(m.bt, k)
   return  exactfound? m.bt.data[i].d : default
end


function get!{K,D}(m::SortedDict{K,D}, k::K, default::D)
    i, exactfound = findkey(m.bt, k)
    if exactfound
        return m.bt.data[i].d
    else
        insert!(m.bt, k, default, false)
        return default
    end
end


function getkey{K,D}(m::SortedDict{K,D}, k::K, default::K)
    i, exactfound = findkey(m.bt, k)
    exactfound? k : default
end

## Function delete! deletes an item at a given 
## key

function delete!{K,D}(m::SortedDict{K,D}, k::K)
    i, exactfound = findkey(m.bt,k)
    if !exactfound
        throw(KeyError(k))
        #error("Key not in SortedDict in delete!")
    end
    delete!(m.bt, i)
    m
end

function pop!{K,D}(m::SortedDict{K,D}, k::K)
    i, exactfound = findkey(m.bt,k)
    if !exactfound
        throw(KeyeError(k))
        #error("Key not in SortedDict in pop!")
    end
    d = m.bt.data[i].d
    delete!(m.bt, i)
    d
end


## The next three function support "for k = keys(m)" where m is
## a SortedDict.

type KeySOD{K,D}
    m::SortedDict{K,D}
end

function keys{K,D}(m::SortedDict{K,D})
    KeySOD(m)
end

function start{K,D}(ksod::KeySOD{K,D})
    nextloc0(ksod.m.bt, 1)
end

function done{K,D}(ksod::KeySOD{K,D}, state::Int)
    state == 2
end

function next{K,D}(ksod::KeySOD{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, ksod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ksod.m.bt.data[state].k, nextloc0(ksod.m.bt, state)
end


# The functions support "for p = enumerate_ind(keys(m))"


type EKeySOD{K,D}
    m::SortedDict{K,D}
end

function enumerate_ind{K,D}(ksod::KeySOD{K,D})
    EKeySOD(ksod.m)
end

function start{K,D}(eksod::EKeySOD{K,D})
    nextloc0(eksod.m.bt, 1)
end

function done{K,D}(eksod::EKeySOD{K,D}, state::Int)
    state == 2
end

function next{K,D}(eksod::EKeySOD{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, eksod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedDictIndex{K,D}(state),eksod.m.bt.data[state].k), 
    nextloc0(eksod.m.bt, state)
end


# These functions support "for p = values(m)"


type ValueSOD{K,D}
    m::SortedDict{K,D}
end

function values{K,D}(m::SortedDict{K,D})
    ValueSOD(m)
end

function start{K,D}(vsod::ValueSOD{K,D})
    nextloc0(vsod.m.bt, 1)
end

function done{K,D}(vsod::ValueSOD{K,D}, state::Int)
    state == 2
end

function next{K,D}(vsod::ValueSOD{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, vsod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return vsod.m.bt.data[state].d, nextloc0(vsod.m.bt, state)
end


# These functions support "for p = enumerate_ind(values(m))"


type EValueSOD{K,D}
    m::SortedDict{K,D}
end

function enumerate_ind{K,D}(vsod::ValueSOD{K,D})
    EValueSOD(vsod.m)
end

function start{K,D}(evsod::EValueSOD{K,D})
    nextloc0(evsod.m.bt, 1)
end

function done{K,D}(evsod::EValueSOD{K,D}, state::Int)
    state == 2
end

function next{K,D}(evsod::EValueSOD{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, evsod.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedDictIndex{K,D}(state), evsod.m.bt.data[state].d), 
    nextloc0(evsod.m.bt, state)
end


## Check if two SortedDicts are equal in the sense of containing
## the same (K,D) pairs.  This sense of equality does not mean
## that indices valid for one are also valid for the other.

function isequal{K,D}(m1::SortedDict{K,D},
                      m2::SortedDict{K,D})
    p1 = ind_first(m1)
    p2 = ind_first(m2)
    while true
        if is_ind_past_end(m1,p1)
            return is_ind_past_end(m2,p2)
        end
        if is_ind_past_end(m2,p2)
            return false
        end
        k1,d1 = deref_ind(m1,p1)
        k2,d2 = deref_ind(m2,p2)
        if !isequal_l(k1,k2) || !isequal(d1,d2)
            return false
        end
        p1 = advance_ind(m1,p1)
        p2 = advance_ind(m2,p2)
    end
end


function mergetwo!{K,D}(m::SortedDict{K,D}, m2::SortedDict{K,D})
    for p = m2
        @inbounds m[p[1]] = p[2]
    end
end

function packcopy{K,D}(m::SortedDict{K,D})
    w = SortedDict((K=>D)[])
    mergetwo!(w,m)
    w
end

function packdeepcopy{K,D}(m::SortedDict{K,D})
    w = SortedDict((K=>D)[])
    for p in m
        newk = deepcopy(p[1])
        newv = deepcopy(p[2])
        w[newk] = newv
    end
    w
end

    

function merge!{K,D}(m::SortedDict{K,D}, 
                     others::SortedDict{K,D}...)
    apply(others) do m2
        mergetwo!(m, m2)
    end
end

function merge{K,D}(m::SortedDict{K,D}, 
                    others::SortedDict{K,D}...)
    result = packcopy(m)
    merge!(result, others...)
    result
end


## A MultiMap is similar to a SortedDict except the same
## key can occur multiple times.

type MultiMap{K,D}
    bt::BalancedTree{K,D}
end

function MultiMap{K,D}(keys::AbstractArray{K,1}, values::AbstractArray{D,1})
    n = size(keys,1)
    if size(values,1) != n
        error("MultiMap initializer should have same number of keys and values")
    end
    bt1 = BalancedTree{K,D}()
    for i = 1 : n
        insert!(bt1, keys[i], values[i], true)
    end
    MultiMap(bt1)
end

        

immutable MultiMapIndex{K,D}
    address::Int
end

    


function ind_insert!{K,D}(m::MultiMap{K,D}, k::K, d::D)
    scrap, i = insert!(m.bt, k, d, true)
    MultiMapIndex{K,D}(i)
end

function delete_ind!{K,D}(m::MultiMap{K,D}, ii::MultiMapIndex{K,D})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("delete_ind! invoked on deleted index")
    end
    if ii.address < 3
        throw(BoundsError())
        #error("delete_ind! invoked on before-start or past-end iterator")
    end
    delete!(m.bt, ii.address)
end


## This function looks up a key in the tree;
## If found, it returns a pair of indices: the
## first index with that key and and the
## first index of the following key.
## if not found, then it returns a pair in which
## both indices are past-end markers.
        
function ind_findrange{K,D}(m::MultiMap{K,D}, k::K)
    i1 = findkeyless(m.bt, k)
    i2, exactfound = findkey(m.bt, k)
    if exactfound
        i1a = nextloc0(m.bt, i1)
        i2a = nextloc0(m.bt, i2)
        @assert(m.bt.data[i1a].k == k)
        return MultiMapIndex{K,D}(i1a), MultiMapIndex{K,D}(i2a)
    else
        return MultiMapIndex{K,D}(2), MultiMapIndex{K,D}(2)
    end
end


## Function ind_first returns the index of
## the first sorted order of the tree.  It returns
## the end marker if the tree is empty.

function ind_first{K,D}(m::MultiMap{K,D})
    MultiMapIndex{K,D}(beginloc(m.bt))
end

## Function is_ind_past_end tests whether an index is at the
## end marker.

function is_ind_past_end{K,D}(m::MultiMap{K,D}, ii::MultiMapIndex{K,D})
    ii.address == 2
end

## Function past_end returns the index past the end of the data.

function past_end{K,D}(m::MultiMap{K,D})
    MultiMapIndex{K,D}(2)
end

## Function before_start returns the index before the start of the data.

function before_start{K,D}(m::MultiMap{K,D})
    MultiMapIndex{K,D}(1)
end

## Function is_ind_before_start tests whether an index is before
## the start marker.

function is_ind_before_start{K,D}(m::MultiMap{K,D}, ii::MultiMapIndex{K,D})
    ii.address == 1
end


## Function advance_ind takes an index and returns the
## next index in the sorted order. 

function advance_ind{K,D}(m::MultiMap{K,D}, 
                         ii::MultiMapIndex{K,D})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("advance_ind invoked on deleted index")
    end
    if ii.address == 2
        throw(BoundsError())
        #error("advance_ind invoked on past-end data item")
    end
    MultiMapIndex{K,D}(nextloc0(m.bt, ii.address))
end


## Function regress_ind takes an index and returns the
## previous index in the sorted order. 

function regress_ind{K,D}(m::MultiMap{K,D}, 
                         ii::MultiMapIndex{K,D})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("regress_ind invoked on deleted index")
    end
    if ii.address == 1
        throw(BoundsError())
        #error("regress_ind invoked on before-start data item")
    end
    MultiMapIndex{K,D}(prevloc0(m.bt, ii.address))
end


function endof{K,D}(m::MultiMap{K,D})
    MultiMapIndex{K,D}(endloc(m.bt))
end


function first{K,D}(m::MultiMap{K,D})
    i = beginloc(m.bt)
    if i == 2
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end


function last{K,D}(m::MultiMap{K,D})
    i = endloc(m.bt)
    if i == 1
        throw(BoundsError())
    end
    return m.bt.data[i].k, m.bt.data[i].d
end




## Function deref_ind(m,ii), where ii is an index, returns the
## (k,d) pair indexed by ii.

function deref_ind{K,D}(m::MultiMap{K,D}, 
                       ii::MultiMapIndex{K,D})
    addr = ii.address
    if addr < 3
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of MultiMap")
    end
    if !in(addr, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return m.bt.data[addr].k, m.bt.data[addr].d
end



## Function deref_key_only_ind(m,ii), where ii is an index, returns the
## key indexed by ii.

function deref_key_only_ind{K,D}(m::MultiMap{K,D}, 
                                 ii::MultiMapIndex{K,D})
    addr = ii.address
    if addr < 3
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of MultiMap")
    end
    if !in(addr, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry $ii")
    end
    return m.bt.data[addr].k
end

## This function takes a key and returns the index of
## the first item in the tree that is >= the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_equal_or_greater{K,D}(m::MultiMap{K,D}, k::K)
    i = findkeyless(m.bt, k)
    MultiMapIndex{K,D}(nextloc0(m.bt, i))
end

## This function takes a key and returns the index of
## the first item in the tree that is > the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_greater{K,D}(m::MultiMap{K,D}, k::K)
    i, exactfound = findkey(m.bt, k)
    MultiMapIndex{K,D}(nextloc0(m.bt, i))
end

## These functions support "for p = m", where m is a MultiMap.

function start{K,D}(m::MultiMap{K,D})
    nextloc0(m.bt,1)
end


function done{K,D}(m::MultiMap{K,D}, state::Int)
    state == 2
end

function next{K,D}(m::MultiMap{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of MultiMap")
    end
    if !in(state, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((m.bt.data[state].k, m.bt.data[state].d), nextloc0(m.bt, state))
end
    

type MultiMapRangeIteration{K,D}
    m::MultiMap{K,D}
    startit::Int
    endit::Int
end


## These functions support "for p = multimap_range_iteration(m,starti,endi)", 
## where m is a MultiMap, starti is the starting index and endi is the
## ending index.


function multimap_range_iteration{K,D}(m1::MultiMap{K,D},
                                       startit1::MultiMapIndex{K,D},
                                       endit1::MultiMapIndex{K,D})
    MultiMapRangeIteration(m1, startit1.address, endit1.address)
end



function start{K,D}(mmri::MultiMapRangeIteration{K,D})
    mmri.startit
end

function done{K,D}(mmri::MultiMapRangeIteration{K,D}, state::Int)
    state == 2 || state == mmri.endit
end

function next{K,D}(mmri::MultiMapRangeIteration{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of MultiMap")
    end
    if !in(state, mmri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((mmri.m.bt.data[state].k, mmri.m.bt.data[state].d),
     nextloc0(mmri.m.bt, state))
end

type EnumerateMM{K,D}
    m::MultiMap{K,D}
end

## These support the loop "for p = enumerate_ind(m)", 
## where m is a MultiMap.

function enumerate_ind{K,D}(m::MultiMap{K,D})
    EnumerateMM{K,D}(m)
end

function start{K,D}(emm::EnumerateMM{K,D})
    nextloc0(emm.m.bt,1)
end

function done{K,D}(emm::EnumerateMM{K,D}, state::Int)
    state == 2
end

function next{K,D}(emm::EnumerateMM{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of MultiMap")
    end
    if !in(state, emm.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return ((MultiMapIndex{K,D}(state), 
      (emm.m.bt.data[state].k,emm.m.bt.data[state].d)),
      nextloc0(emm.m.bt, state))
end

type EnumerateMMRI{K,D}
    mmri::MultiMapRangeIteration{K,D}
end

# These functions support 
# "for p = enumerate_ind(multimap_range_iteration(m, starti, endi))"


function enumerate_ind{K,D}(m::MultiMapRangeIteration{K,D})
    EnumerateMMRI{K,D}(m)
end


function start{K,D}(emmri::EnumerateMMRI{K,D})
    emmri.mmri.startit
end

function done{K,D}(emmri::EnumerateMMRI{K,D}, state::Int)
    state == 2 || state == emmri.mmri.endit
end

function next{K,D}(emmri::EnumerateMMRI{K,D}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of MultiMap")
    end
    if !in(state, emmri.mmri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (MultiMapIndex{K,D}(state), 
     (emmri.mmri.m.bt.data[state].k, emmri.mmri.m.bt.data[state].d)),
    nextloc0(emmri.mmri.m.bt, state)
end


function isempty{K,D}(m::MultiMap{K,D})
    size(m.bt.data,1) - size(m.bt.freedatainds, 1) == 2
end


## This function clears a multimap -- all items deleted.

function empty!{K,D}(m::MultiMap{K,D})
    empty!(m.bt)
end

function length{K,D}(m::MultiMap{K,D})
   size(m.bt.data,1) - size(m.bt.freedatainds, 1) - 2
end

function eltype{K,D}(m::MultiMap{K,D})
    (K,D)
end

function haskey{K,D}(m::MultiMap{K,D}, k::K)
    i, exactfound = findkey(m.bt,k)
    exactfound
end
    


function isequal{K,D}(m1::MultiMap{K,D},
                      m2::MultiMap{K,D})
    p1 = ind_first(m1)
    p2 = ind_first(m2)
    while true
        if is_ind_past_end(m1,p1)
            return is_ind_past_end(m2,p2)
        end
        if is_ind_past_end(m2,p2)
            return false
        end
        k1,d1 = deref_ind(m1,p1)
        k2,d2 = deref_ind(m2,p2)
        if !isequal_l(k1,k2) || !isequal(d1,d2)
            return false
        end
        p1 = advance_ind(m1,p1)
        p2 = advance_ind(m2,p2)
    end
end


function packcopy{K,D}(m::MultiMap{K,D})
    w = MultiMap(K[], D[])
    for p in m
        ind_insert!(w, p[1], p[2])
    end
    w
end

function packdeepcopy{K,D}(m::MultiMap{K,D})
    w = MultiMap(K[], D[])
    for p in m
        newk = deepcopy(p[1])
        newv = deepcopy(p[2])
        ind_insert!(w, newk, newv)
    end
    w
end


## A SortedSet is a wrapper around balancedTree
## in which the data type is None.

type SortedSet{K}
    bt::BalancedTree{K,Nothing}
end


function SortedSet{K}(d::AbstractArray{K,1})
    bt1 = BalancedTree{K,Nothing}()
    for pr in d
        insert!(bt1, pr, nothing, true)
    end
    SortedSet(bt1)
end


## A SortedSetIndex is a small structure for iterating
## over the items in a tree in sorted order.  It is
## a wrapper around an Int; the int is the index
## of the current item in t.data.  An iterator
## should never point to a deleted item; a deferenceable
## iterator cannot point to the before-start or past-end items.


immutable SortedSetIndex{K}
    address::Int
end

## This function looks up a key in the tree;
## if not found, then it returns a marker for the
## end of the tree.
        
function ind_find{K}(m::SortedSet{K}, k::K)
    ll, exactfound = findkey(m.bt, k)
    exactfound?
    SortedSetIndex{K}(ll) :
    SortedSetIndex{K}(2)
end

## This function inserts an item into the tree.
## Unlike push!(m, k), it returns a bool and index.
## The bool is true if the inserted item is new.
## It is false if there was already an item
## with that key.
## The Index points to the newly inserted item.

function ind_insert!{K}(m::SortedSet{K}, k::K)
    b, i = insert!(m.bt, k, nothing, false)
    b, SortedSetIndex{K}(i)
end

function push!{K}(m::SortedSet{K}, k::K)
    b, i = insert!(m.bt, k, nothing, false)
    m
end


## delete_ind! deletes an item given an index.

function delete_ind!{K}(m::SortedSet{K}, ii::SortedSetIndex{K})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("delete_ind! invoked on deleted index")
    end
    if ii.address < 3
        throw(BoundsError())
        #error("delete_ind! invoked on before-start or past-end iterator")
    end
    delete!(m.bt, ii.address)
end
    


## Function ind_first returns the index of 
## the first sorted order of the tree.  It returns
## the end marker if the tree is empty.

function ind_first{K}(m::SortedSet{K})
    SortedSetIndex{K}(beginloc(m.bt))
end

## Function is_ind_past_end tests whether an index is at the
## end marker.

function is_ind_past_end{K}(m::SortedSet{K}, ii::SortedSetIndex{K})
    ii.address == 2
end

## Function past_end returns the index past the end of the data.

function past_end{K}(m::SortedSet{K})
    SortedSetIndex{K}(2)
end

## Function before_start returns the index before the start of the data.

function before_start{K}(m::SortedSet{K})
    SortedSetIndex{K}(1)
end

## Function is_ind_before_start tests whether an iterator is before
## the start marker.

function is_ind_before_start{K}(m::SortedSet{K}, ii::SortedSetIndex{K})
    ii.address == 1
end

## Function advance_ind takes an iterator and returns the
## next iterator in the sorted order. 

function advance_ind{K}(m::SortedSet{K}, 
                        ii::SortedSetIndex{K})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("advance_ind invoked on deleted index")
    end
    if ii.address == 2
        throw(BoundsError())
        #error("advance_ind invoked on past-end data item")
    end

    SortedSetIndex{K}(nextloc0(m.bt, ii.address))
end


## Function regress_ind takes an iterator and returns the
## previous iterator in the sorted order. 

function regress_ind{K}(m::SortedSet{K}, 
                        ii::SortedSetIndex{K})
    if !in(ii.address, m.bt.useddatacells)
        throw(BoundsError())
        #error("regress_ind invoked on deleted index")
    end
    if ii.address == 1
        throw(BoundsError())
        #error("regress_ind invoked on before-start data item")
    end
    SortedSetIndex{K}(prevloc0(m.bt, ii.address))
end


function endof{K}(m::SortedSet{K})
    SortedSetIndex{K}(endloc(m.bt))
end


function first{K}(m::SortedSet{K})
    i = beginloc(m.bt)
    if i == 2
        throw(BoundsError())
    end
    return m.bt.data[i].k
end


function last{K}(m::SortedSet{K})
    i = endloc(m.bt)
    if i == 1
        throw(BoundsError())
    end
    return m.bt.data[i].k
end



## Function deref_ind(m,ii), where ii is an index, returns the
## (k,d) pair indexed by ii.

function deref_ind{K}(m::SortedSet{K}, 
                      ii::SortedSetIndex{K})
    addr = ii.address
    if addr < 3
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(addr, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return m.bt.data[addr].k
end

deref_key_only_ind{K}(m::SortedSet{K}, ii::SortedSetIndex{K}) = deref_ind(m,ii)


## This function takes a key and returns the index
## of the first item in the tree that is >= the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_equal_or_greater{K}(m::SortedSet{K}, k::K)
    i, exactfound = findkey(m.bt, k)
    exactfound?
    SortedSetIndex{K}(i) :
    SortedSetIndex{K}(nextloc0(m.bt, i))
end


## This function takes a key and returns the index
## of the first item in the tree that is > the given
## key in the sorted order.  It returns the end marker
## if there is none.

function ind_greater{K}(m::SortedSet{K}, k::K)
    i, exactfound = findkey(m.bt, k)
    SortedSetIndex{K}(nextloc0(m.bt, i))
end


function start{K}(m::SortedSet{K})
    nextloc0(m.bt,1)
end


function done{K}(m::SortedSet{K}, state::Int)
    state == 2
end

function next{K}(m::SortedSet{K}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedSet")
    end
    if !in(state, m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (m.bt.data[state].k, nextloc0(m.bt, state))
end
    
type SortedSetRangeIteration{K}
    m::SortedSet{K}
    startit::Int
    endit::Int
end


function sorted_set_range_iteration{K}(m1::SortedSet{K},
                                        startit1::SortedSetIndex{K},
                                        endit1::SortedSetIndex{K})
    SortedSetRangeIteration(m1, startit1.address, endit1.address)
end

function start{K}(sosri::SortedSetRangeIteration{K})
    sosri.startit
end

function done{K}(sosri::SortedSetRangeIteration{K}, state::Int)
    state == 2 || state == sosri.endit
end

function next{K}(sosri::SortedSetRangeIteration{K}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedSet")
    end
    if !in(state, sosri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (sosri.m.bt.data[state].k, nextloc0(sosri.m.bt, state))
end

type EnumerateSOS{K}
    m::SortedSet{K}
end

function enumerate_ind{K}(m::SortedSet{K})
    EnumerateSOS{K}(m)
end

function start{K}(esod::EnumerateSOS{K})
    nextloc0(esod.m.bt,1)
end

function done{K}(esos::EnumerateSOS{K}, state::Int)
    state == 2
end

function next{K}(esos::EnumerateSOS{K}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedSet")
    end
    if !in(state, esos.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedSetIndex{K}(state), 
      esos.m.bt.data[state].k), nextloc0(esos.m.bt, state)
end

type EnumerateSOSRI{K}
    sosri::SortedSetRangeIteration{K}
end

function enumerate_ind{K}(m::SortedSetRangeIteration{K})
    EnumerateSOSRI{K}(m)
end


function start{K}(esosri::EnumerateSOSRI{K})
    esosri.sosri.startit
end

function done{K}(esosri::EnumerateSOSRI{K}, state::Int)
    state == 2 || state == esosri.sosri.endit
end

function next{K}(esosri::EnumerateSOSRI{K}, state::Int)
    if state == 2
        throw(BoundsError())
        #error("Attempt to retrieve data before start or past end of SortedDict")
    end
    if !in(state, esosri.sosri.m.bt.useddatacells)
        throw(BoundsError())
        #error("Attempt to access deleted entry")
    end
    return (SortedSetIndex{K}(state), 
     esosri.sosri.m.bt.data[state].k),
    nextloc0(esosri.sosri.m.bt, state)
end


function isempty{K}(m::SortedSet{K})
    size(m.bt.data,1) - size(m.bt.freedatainds, 1) == 2
end


## This function clears a SortedSet -- all items deleted.

function empty!{K}(m::SortedSet{K})
    empty!(m.bt)
end

function length{K}(m::SortedSet{K})
   size(m.bt.data,1) - size(m.bt.freedatainds, 1) - 2
end

function in{K}(p::K, m::SortedSet{K})
    i, exactfound = findkey(m.bt,p)
    return exactfound 
end

function eltype{K}(m::SortedSet{K})
    K
end

## Function delete! deletes an item at a given 
## key

function delete!{K}(m::SortedSet{K}, k::K)
    i, exactfound = findkey(m.bt,k)
    if !exactfound
        throw(KeyError(k))
        #error("Key not in SortedSet in delete!")
    end
    delete!(m.bt, i)
    m
end



function isequal{K}(m1::SortedSet{K},
                    m2::SortedSet{K})
    p1 = ind_first(m1)
    p2 = ind_first(m2)
    while true
        if is_ind_past_end(m1,p1)
            return is_ind_past_end(m2,p2)
        end
        if is_ind_past_end(m2,p2)
            return false
        end
        k1 = deref_ind(m1,p1)
        k2 = deref_ind(m2,p2)
        if !isequal_l(k1,k2)
            return false
        end
        p1 = advance_ind(m1,p1)
        p2 = advance_ind(m2,p2)
    end
end

function union!{K}(m1::SortedSet{K}, iterable_item)
    for k = iterable_item
        push!(m1,k)
    end
end

function union{K}(m1::SortedSet{K}, others::SortedSet{K}...)
    mr = packcopy(m1)
    apply(others) do m2
        union!(mr, m2)
    end
    return mr
end

function intersect2{K}(m1::SortedSet{K}, m2::SortedSet{K})
    mi = SortedSet(K[])
    p1 = ind_first(m1)
    p2 = ind_first(m2)
    while true
        if is_ind_past_end(m1,p1) || is_ind_past_end(m2,p2)
            return mi
        end
        k1 = deref_ind(m1,p1)
        k2 = deref_ind(m2,p2)
        if isless(k1,k2)
            p1 = advance_ind(m1,p1)
        elseif isless(k2,k1)
            p2 = advance_ind(m2,p2)
        else
            push!(mi,k1)
            p1 = advance_ind(m1,p1)
            p2 = advance_ind(m2,p2)
        end
    end
end

            
function intersect{K}(m1::SortedSet{K}, others::SortedSet{K}...)
    if length(others) == 0
        return m1
    else
        mi = intersect2(m1, others[1])
        for pr = others[2:end]
            mi = intersect2(mi, s2)
        end
        return mi
    end
end
    

function symdiff{K}(m1::SortedSet{K}, m2::SortedSet{K})
    mi = SortedSet(K[])
    p1 = ind_first(m1)
    p2 = ind_first(m2)
    while true
        if is_ind_past_end(m1,p1) && is_ind_past_end(m2,p2)
            return mi
        elseif is_ind_past_end(m1,p1)
            push!(mi, deref_ind(m2,p2))
            p2 = advance_ind(m2,p2)
        elseif is_ind_past_end(m2,p2)
            push!(mi, deref_ind(m1,p1))
            p1 = advance_ind(m1,p1)
        else
            k1 = deref_ind(m1,p1)
            k2 = deref_ind(m2,p2)
            if isless(k1,k2)
                push!(mi, deref_ind(m1,p1))
                p1 = advance_ind(m1,p1)
            elseif isless(k2,k1)
                push!(mi, deref_ind(m2,p2))
                p2 = advance_ind(m2,p2)
            else
                p1 = advance_ind(m1,p1)
                p2 = advance_ind(m2,p2)
            end
        end
    end
end
    
function setdiff{K}(m1::SortedSet{K}, m2::SortedSet{K})
    mi = SortedSet(K[])
    p1 = ind_first(m1)
    p2 = ind_first(m2)
    while true
        if is_ind_past_end(m1,p1)
            return mi
        elseif is_ind_past_end(m2,p2)
            push!(mi, deref_ind(m1,p1))
            p1 = advance_ind(m1,p1)
        else
            k1 = deref_ind(m1,p1)
            k2 = deref_ind(m2,p2)
            if isless(k1,k2)
                push!(mi, deref_ind(m1,p1))
                p1 = advance_ind(m1,p1)
            elseif isless(k2,k1)
                p2 = advance_ind(m2,p2)
            else
                p1 = advance_ind(m1,p1)
                p2 = advance_ind(m2,p2)
            end
        end
    end
end

function setdiff!{K}(m1::SortedSet{K}, iterable_item)
    for p = iterable_item
        i = ind_find(m1, p)
        if !is_ind_past_end(m1,i)
            delete_ind!(m1,i)
        end
    end
end


    
function issubset{K}(m1::SortedSet{K}, m2::SortedSet{K})
    for k = m1
        if !in(k, m2)
            return false
        end
    end
    return true
end


function packcopy{K}(m::SortedSet{K})
    w = SortedSet(K[])
    for k in m
        push!(w, k)
    end
    w
end

function packdeepcopy{K}(m::SortedSet{K})
    w = SortedSet(K[])
    for k in m
        newk = deepcopy(k)
        push!(w, newk)
    end
    w
end




