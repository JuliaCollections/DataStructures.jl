mutable struct AVLTreeNode{K}
    height::Int8
    data::K
    leftChild::Union{AVLTreeNode{K}, Nothing}
    rightChild::Union{AVLTreeNode{K}, Nothing}

    AVLTreeNode{K}() where K = new{K}(0, nothing, nothing, nothing)
    AVLTreeNode{K}(d::K) where K = new{K}(1, d, nothing, nothing)
end

AVLTreeNode(d) = AVLTreeNode{Any}(d)

AVLTreeNode_or_null{T} = Union{AVLTreeNode{T}, Nothing}

mutable struct AVLTree{T}
    root::AVLTreeNode_or_null{T}

    AVLTree{T}() where T = new{T}(AVLTreeNode{T}())
end

AVLTree() = AVLTree{Any}()

function get_height(node::Union{AVLTreeNode, Nothing})
    if node == nothing
        return 0
    else
        return node.height
    end
end

function get_balance(node::Union{AVLTreeNode, Nothing})
    if node == nothing
        return 0
    else
        return get_height(node.leftChild) - get_height(node.rightChild)
    end
end

fix_height(node::Union{AVLTreeNode, Nothing}) = 1 + max(get_height(node.leftChild), get_height(node.rightChild))

function left_rotate(z::AVLTreeNode)
    y = z.rightChild
    α = y.leftChild
    y.leftChild = z
    z.rightChild = α
    z.height = fix_height(z)
    y.height = fix_height(y)
    return y
end

function right_rotate(z::AVLTreeNode)
    y = z.leftChild
    α = y.rightChild
    y.rightChild = z
    z.leftChild = α
    z.height = fix_height(z)
    y.height = fix_height(y)
    return y
end

function get_minimum_node(node::Union{AVLTreeNode, Nothing})
    while node != nothing && node.leftChild != nothing
        node = node.leftChild
    end
    return node
end

function Base.insert!(tree::AVLTree{K}, d::K) where K

    function insert_node(node::Union{AVLTreeNode, Nothing}, key)
        if node == nothing || node.data == nothing
            return AVLTreeNode{K}(key)
        elseif key < node.data
            node.leftChild = insert_node(node.leftChild, key)
        else
            node.rightChild = insert_node(node.rightChild, key)
        end
        
        node.height = fix_height(node)
        balance = get_balance(node)
        
        if balance > 1
            if key < node.leftChild.data
                return right_rotate(node)
            else
                node.leftChild = left_rotate(node.leftChild)
                return right_rotate(node)
            end
        end

        if balance < -1
            if key > node.rightChild.data
                return left_rotate(node)
            else
                node.rightChild = right_rotate(node)
                return left_rotate(node)
            end
        end

        return node
    end
    tree.root = insert_node(tree.root, d)
    return tree
end

function Base.delete!(tree::AVLTree{K}, d::K) where K

    function delete_node(node::Union{AVLTreeNode, Nothing}, key)
        if node == nothing || node.data == nothing
            return nothing
        elseif key < node.data
            node.leftChild = delete_node(node.leftChild, key)
        elseif key > node.data
            node.rightChild = delete_node(node.rightChild, key)
        else
            if node.leftChild == nothing
                temp = node.rightChild
                node = nothing
                return temp
            elseif node.rightChild == nothing
                temp = node.leftChild
                node = nothing
                return temp
            else 
                temp = get_minimum_node(node.rightChild)
                node.data = temp.data
                node.rightChild = delete_node(node.rightChild, temp.data)
            end 
        end

        if node == nothing
            return node
        end

        node.height = fix_height(node)
        balance = get_balance(node)

        if balance > 1
            if get_balance(node.leftChild) >= 0
                return right_rotate(node)
            else
                node.leftChild = left_rotate(node.leftChild)
                return right_rotate(node)
            end
        end

        if balance < -1
            if get_balance(node.rightChild) <= 0
                return left_rotate(node)
            else
                node.rightChild = right_rotate(node.rightChild)
                return left_rotate(node)
            end
        end 

        return node
    end

    tree.root = delete_node(tree.root, d)
    return tree
end

function print_tree(tree::AVLTree)
    function print_tree_helper(node::AVLTreeNode_or_null, indent, isright)
        if node != nothing && node.data != nothing
            print(indent)
            if isright
                print("R--")
                indent *= "   "
            else
                if (node == tree.root)
                    print("-->")
                    indent *= "   "
                else
                    print("L--")
                    indent *= "|  "
                end

            end
            println(node.data, " (", get_balance(node), ")" , "H[", get_height(node), "]")
            print_tree_helper(node.leftChild, indent, false)
            print_tree_helper(node.rightChild, indent, true)
        end
    end
    print_tree_helper(tree.root, "", false)
end

Base.show(io::IO, t::AVLTree) = print_tree(t)