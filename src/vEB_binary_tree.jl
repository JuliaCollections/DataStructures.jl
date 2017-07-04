@inline hyperceil(x::Float64) = 1 << (ceil(Int,log2(x)));
@inline hyperfloor(x::Float64) = 1 << (floor(Int,log2(x)));


type vEBEntry{K}
	value::K
	isblank::boolean
	isleaf::boolean
	MPAidx::Int
	function vEBEntry(value::K)
		isblank = false
		isleaf = false
		return new(value,isblank,isleaf,Nullable{Int}())
	end
	function vEBEntry()
		value = Nullable{K}()
		isblank = true
		isleaf = false
		return new(value,isblank,isleaf)
	end
	function vEBEntry(value::K,MPAidx::Int)
		isblank = false
		isleaf = true
		return new(value,isblank,isleaf,MPAidx)
	end
end

type vEBBinaryTree{K}
	store::Array{vEBEntry{K},1}
	tree_size::Int
	n_elements::Int
	MPA::MemoryPackedArray{K}
	height::Int
	function vEBBinaryTree(capacity_size::Int)
		n_elements = 0
		MPA = MemoryPackedArray{K}(capacity_size,0.0,0.1,0.5,0.9)
		height = ceil(Int.log2(this.MPA.capacity))
		store = Array(vEBBinaryTree{K}, 1<<(height+1))
		tree_size = 1<<(height+1)
		return new(store,tree_size,n_elements,MPA,height)
end


function isEmpty{K}(vEBTree::vEBBinaryTree{K})
	return vEBTree.n_elements==0
end

function find{K}(vEBTree::vEBBinaryTree{K}, key::K)
	root = 1
	return find_rec(vEBTree,root,key)
end

function find_rec{K}(vEBTree::vEBBinaryTree{K},n::Int,key::K)
		idx = vEB_index{K}(vEBTree,n,this.height)
		if this.vstore[idx].isleaf
			return store[idx].MPAidx
		elseif store[idx].isblank || store[idx].value<=key
			return find_rec((2*n),key)
		else
			return find_rec((2*n)+1,key)
		end
end

	function delete!(key::K)
		delete_p(key)
	end

	function insert!(key::K)
		insert_p(key)
	end

	function insert_p(key::K)
		MPAidx = find(key)
		updates, capacity_changed = this.MPA.insert!(MPAidx,key)
		perform_update(updates,capacity_changed)
		this.n_elements+=1
	end

	function delete_p(key::K)
		MPAidx = find(key)
		if MPA.store[MPAidx].value==key:
			updates, capacity_changed = this.MPA.delete!(MPAidx)
			perform_update(updates,capacity_changed)
			this.n_elements-=1
		end
	end

	function perform_update(updates::Array{UpdateInfo{K},1},capacity_changed)
		if capacity_changed:
			build_tree(updates)
			return
		end
		parents = []
		for u in updates:
				idx = vEB_index(u.n,this.height)
				if store[idx].isblank != u.blank || store[idx].value != u.value:
					store[idx].isblank = u.blank
					store[idx].value = u.value
					parents.append!(div(u.n,2))
				end
		end
		update_path(parents)
	end


	function update_path(updates::Array{Int,1})
		parent_update = []
		for u in updates:
			idx = vEB_index(u,this.height)
			left_child = vEB_index(u*2.this.height)
			right_child = vEB_index(u*2+1,this.height)

			node = store[idx]

			old_blank = node.isblank
			old_vaule::K
			if !node.isblank:
				old_value = node.value
			end

			if left_child.isblank && right_child.isblank:
				node.isblank = true
			elseif left_child.isblank:
				node.value = right_child.value
				node.isblank = false
			elseif right_child.isblank:
				node.value = left_child.value
				node.isblank = false
			else
				node.value = max(left_child.value,right_child.value)
				node.isblank = false
			end

			if old_blank != node.isblank || old_value != node.value
				parent_update.append!(div(u,2))
			end

		end
		if size(parent_update)>0:
			update_path(parent_update)
		end
	end

	function build_tree{K}(updates):
			this.height = ceil(Int.log2(this.MPA.capacity))
			this.tree_size = 1<<(height+1)
			new_store = Array(vEBEntry{K},this.tree_size)
			parents = []
			for u in updates:
					idx = vEB_index(u.n,this.height)
					new_store[idx].isblank = u.blank
					new_store[idx].value = u.value
					parents.append!(div(u.n,2))
			end
			this.store = new_store
			update_path(parents)
	end


	function vEB_index(n::Int, height::Int)
		if height<3
			return n
		end

		depth = floor(Int,log2(n))

		bottom_h = hyperceil(h*1.0/2)
		top_h = h - bottom_h

		if depth<top_h:
			cal_new_depth
			return vEB_index(n,cal_new_depth,top_h)
		end

		sub_d = depth - top_h
		sub_root = n >> sub_d

		num_sub = 1 <<top_h
		n &= (1<<sub_d)-1
		n |= 1 << sub_d

		sub_size = (1 << bottom_h)-1
		top_size = (1 <<top_h) -1

		x = top_size+(sub_root & (num_sub-1))*sub_size

		return x + vEB_index(n,bottom_h)
	end
end
