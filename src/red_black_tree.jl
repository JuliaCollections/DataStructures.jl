
# color is true if it's a Red Node, else it's false
mutable struct RBTreeNode{K}
	color::Bool 
	data::K
	leftChild::Union{Nothing, RBTreeNode{K}}
	rightChild::Union{Nothing, RBTreeNode{K}}
	parent::Union{Nothing, RBTreeNode{K}}

	RBTreeNode{K}() where K = new{K}(true, nothing, nothing, nothing, nothing)
	
	RBTreeNode{K}(d::K) where K = new{K}(true, d, nothing, nothing, nothing)
end

RBTreeNode() = RBTreeNode{Any}()
RBTreeNode(d) = RBTreeNode{Any}(d)

mutable struct RBTree{K}
	root::RBTreeNode{K}

	RBTree{K}() where K = new{K}(RBTreeNode{K}())
end

RBTree() = RBTree{Any}()

function search_node(tree::RBTree{K}, d::K) where K
	node = tree.root
	(node == nothing) && return nothing
	while (node != nothing)
		if (d < node.data)
			(node.leftChild == nothing) && break
			node = node.leftChild
		elseif (d > node.data)
			(node.rightChild == nothing) && break
			node = node.rightChild
		else
			break
		end
	end
	return node
end

function search_key(tree::RBTree{K}, d::K) where K 
	node = search_node(tree, d)
	(node == nothing) && return false
	return (node.data == d)
end

function insert(root::Union{Nothing, RBTreeNode}, node::RBTreeNode)
	if root == nothing || root.data == nothing
		return node
	else
		if (node.data > root.data)
			root.rightChild = insert(root.rightChild, node)
			root.rightChild.parent = root
		else
			root.leftChild = insert(root.leftChild, node)
			root.leftChild.parent = root
		end
		return root
	end
end

function left_rotate!(tree::RBTree, node_x::RBTreeNode)
	node_y = node_x.rightChild
	node_x.rightChild = node_y.leftChild
	if node_x.rightChild != nothing
		node_x.rightChild.parent = node_x
	end
	node_y.parent = node_x.parent
	if (node_x.parent == nothing)
		tree.root = node_y
	elseif (node_x == node_x.parent.leftChild)
		node_x.parent.leftChild = node_y
	else
		node_x.parent.rightChild = node_y
	end
	node_y.leftChild = node_x
	node_x.parent = node_y
end	

function right_rotate!(tree::RBTree, node_x::RBTreeNode)
	node_y = node_x.leftChild
	node_x.leftChild = node_y.rightChild
	if node_x.leftChild != nothing
		node_x.leftChild.parent = node_x
	end
	node_y.parent = node_x.parent
	if (node_x.parent == nothing)
		tree.root = node_y
	elseif (node_x == node_x.parent.leftChild)
		node_x.parent.leftChild = node_y
	else
		node_x.parent.rightChild = node_y
	end
	node_y.rightChild = node_x
	node_x.parent = node_y
end	

node_color(color::Bool) = (color) ? "RED" : "BLACK"
desc_node(relation, node::RBTreeNode) = println("$relation is ", node.data, " color is ", node_color(node.color))

function balance!(tree::RBTree, node::RBTreeNode)
	parent = nothing
	grand_parent = nothing
	# for root node, we need to change the color to black
	# other nodes, we need to maintain the property such that
	# no two adjacent nodes are red in color
	while (node != tree.root && node.color && node.parent.color)
		parent = node.parent
		grand_parent = parent.parent
		
		# parent is the leftChild of grand_parent
		if (parent == grand_parent.leftChild)
			uncle = grand_parent.rightChild

			# uncle is red in color
			if (uncle != nothing && uncle.color)
				grand_parent.color = true
				parent.color = false
				uncle.color = false
				node = grand_parent
			# uncle is black in color
			else 
				# node is rightChild of it's parent
				if (node == parent.rightChild)
					left_rotate!(tree, parent)
					node = parent
					parent = node.parent
				end
				# node is leftChild of it's parent
				right_rotate!(tree, grand_parent)
				parent.color, grand_parent.color = grand_parent.color, parent.color
				node = parent
			end
		# parent is the rightChild of grand_parent
		else 
			uncle = grand_parent.leftChild

			# uncle is red in color
			if (uncle != nothing && uncle.color)
				grand_parent.color = true
				parent.color = false
				uncle.color = false
				node = grand_parent
			# uncle is black in color
			else 
				# node is leftChild of it's parent
				if (node == parent.leftChild)
					right_rotate!(tree, parent)
					node = parent
					parent = node.parent
				end
				# node is rightChild of it's parent
				left_rotate!(tree, grand_parent)
				parent.color, grand_parent.color = grand_parent.color, parent.color
				node = parent
			end
		end
	end
	tree.root.color = false
end

function insert!(tree::RBTree{K}, d::K) where K
	node = RBTreeNode(d)
	tree.root = insert(tree.root, node)
	balance!(tree, node)
	return tree
end

function print_tree_inorder(node::Union{Nothing, RBTreeNode})
	if (node != nothing)
		print_tree_inorder(node.leftChild)
		println("value -> ", node.data)
		print_tree_inorder(node.rightChild)
	end
end

function print_tree_levelorder(node::Union{Nothing, RBTreeNode{K}}) where K
	level = Dict{Int, Vector{K}}()
	function traverse_tree(node::Union{Nothing, RBTreeNode}, lvl = 1)
		if (node != nothing)
			if (haskey(level, lvl))
				push!(level[lvl], node.data)
			else
				level[lvl] = K[node.data]
			end
			traverse_tree(node.leftChild, lvl+1)
			traverse_tree(node.rightChild, lvl+1)
		end
	end

	traverse_tree(node)

	for (k, v) in level
		println("Level -> ", k)
		println(v)
	end
end
