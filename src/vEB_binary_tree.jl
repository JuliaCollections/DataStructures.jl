@inline hyperceil(x::Float64) = 1 << (ceil(Int,log2(x)));
@inline hyperfloor(x::Float64) = 1 << (floor(Int,log2(x)));


type vEBEntry{K}
	value::K
	isblank::boolean
	isleaf::boolean
	MPAidx::Int
	function vEBEntry(value::K)
		this.value = value
		this.isblank = false
		this.isleaf = false
	end
	function vEBEntry()
		this.isblank = true
		this.isleaf = false
	end
	function vEBEntry(value::K,MPAidx::Int)
		this.value = value
		this.isblank = false
		this.isleaf = true
		this.MPAidx = MPAidx
	end
end

type UpdateInfo{K}
	value::K
	isblank::boolean
	n::Int
end

type vEBBinaryTree{K}
	store::Array{vEBEntry{K},1}
	tree_size::Int
	n_elements::Int
	MPA::MemoryPackedArray{K}
	function vEBBinaryTree(tree_size::Int)
		this.tree_size = tree_size
		n_elements = 0
		this.MPA = MemoryPackedArray{K}(tree_size,0.0,0.1,0.5,0.9)
	end
	function isEmpty()
		return n_elemnts==0
	end

	function find(key::K)
		root = 1
		find_rec(root,key)
	end

	function find_rec(n::Int,key::K)
		idx = vEB_index(n)
		if store[idx].isleaf
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
		updates = this.MPA.insert!(MPAidx,key)
		perform_update(updates)
	end

	function delete_p(key::K)
		MPAidx, found = find(key)
		if found:
			updates = this.MPA.delete!(MPAidx)
			update_leafs(updates)
		end
	end


	function perform_update(updates::Array{UpdateInfo{K},1})
		parents = []
		for u in updates:
				idx = vEB_index(u.n)
				if store[idx].isblank != u.blank || store[idx].value != u.value:
					store[idx].isblank = u.blank
					store[idx].value = u.value
					parents.append!(u/2)
				end
		end
		update_path(parents)
	end


	function update_path(updates::Array{Int,1})
		parent_update = []
		for u in updates:
			idx = vEB_index(u)
			left_child = vEB_index(u*2)
			right_child = vEB_index(u*2+1)

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
				parent_update.append!(u/2)
			end
		end
		if size(parent_update)>0:
			update_path(parent_update)
		end
	end


	function vEB_index(n::Int, depth::Int, height::Int)
		if height<3
			return n
		end

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
