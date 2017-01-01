## This file implements memory-packed arrays
## The array is going to be used to implement cache-oblivious B-trees

immutable MPACell{D}
	value::D
	up::Int
	down::Array{Int,1}
	function MPACell(value::D)
		new(value,0,Int[])
	end
end

## Functions simplifing notation: 
## Function returning the closest power of 2 >= x 
@inline hyperceil(x::Float64) = 1 << (ceil(Int,log2(x)));
## Function returning the closest power of 2 <= x
@inline hyperfloor(x::Float64) = 1 << (floor(Int,log2(x))); 

## Note:  
##	capacity - is equal to some c*N where 
## 		N - number of elements stored
##		c - some desired constant 
##	segment_capacity - the capacity of a segment, this is ceil(lg(capacity))
##	number_of_segments - the number of segments 
##	p0 - density lower threshold for root
##	t0 - density upper threshold for root
##	pd - density lower threshold for leaves
## 	td - density upper threashold for leaves
##	thresholds should satisfy:
##	pd < p0 < t0 < td = 1 
##

##	exists - flags indicating whether a coresponding 
##		cell in store is occupied  
##	store  - the array storing the actual elements	

type MemoryPackedArray{D}
	capacity::Int
	segment_capacity::Int
	number_of_segments::Int
	p0::Float64
	pd::Float64 
	t0::Float64
	td::Float64
	store::Array{MPACell{D},1} 
	exists::Array{Bool,1}
	function MemoryPackedArray(capacity::Int, pd::Float64, p0::Float64, t0::Float64, td::Float64)
			seg_capacity = ceil(Int,log2(capacity));
			no_seg = hyperceil(capacity/seg_capacity);
			capacityP = no_seg*seg_capacity;
			store = Array(MPACell{D},capacityP);
			exists = zeros(capacityP);
			new(capacityP,seg_capacity,no_seg,p0,pd,t0,td,store,exists)
	end
end

## handle replacement
function handleReplacementLeft!{D}(A::MemoryPackedArray{D}, cell::MPACell{D}, neww::Int)		
		for i in cell.down
			if A.store[i].up > 0				
				A.store[i].up = neww
			end
		end
	end
function handleReplacementRight!{D}(A::MemoryPackedArray{D}, cell::MPACell{D}, old::Int, neww::Int)
		if cell.up > 0		
		for i in 1:length(A.store[cell.up].down)		
			if A.store[cell.up].down[i]==old
				A.store[cell.up].down[i] = neww
			end
		end
		end
	end

## Scans the segment,
##	from - start of the segment (inclusive) 
##	to - end of the segment (exclusive)
##	returns: number of elements in the segment
	 
function scan{D}(A::MemoryPackedArray{D},from::Int,to::Int)
	nr = 0
	i = from
	j = to-1
	while i<j
		if(A.exists[i])
			nr+=1
		end
		if(A.exists[j])
			nr+=1
		end
		i+=1
		j-=1	
	end

## 	If segemnt_capacity is odd we haven't checked the element in the middle.
	if ((A.segment_capacity & 1) == 1) && (A.exists[i])
		nr += 1
	end
##	return	
	nr
end

## Checks if a segment is within a threshold
##	left - start of the segment (inclusive)
##	right - end of the segment (exclusive)
##	number_of_elements - number of elements in segment
##	k - height of the tree corresponding to given segment 
##	returns: true if segemnt is within threshold, false otherwise
function in_threshold{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int, k::Int)
##	d - depth of leaf nodes
##	l - depth of node correspodning to given segment
	d = log2(A.number_of_segments)
	l = d-k
	t = A.t0+((A.td-A.t0)/d)*l
	p = A.p0-((A.p0-A.pd)/d)*l
	density = number_of_elements/(right-left)	
	p<=density && density<=t
end

## Checks if a segment is within a threshold
##	left - start of the segment (inclusive)
##	right - end of the segment (exclusive)
##	number_of_elements - number of elements in segment
##	k - height of the tree corresponding to given segment 
##	returns: true if segemnt is within threshold, false otherwise
function in_upper_threshold{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int, k::Int)
##	d - depth of leaf nodes
##	l - depth of node correspodning to given segment
	d = log2(A.number_of_segments)
	l = d-k
	t = A.t0+((A.td-A.t0)/d)*l
	density = number_of_elements/(right-left)	
	density<=t
end

## Checks if a segment is within a threshold
##	left - start of the segment (inclusive)
##	right - end of the segment (exclusive)
##	number_of_elements - number of elements in segment
##	k - height of the tree corresponding to given segment 
##	returns: true if segemnt is within threshold, false otherwise
function in_lower_threshold{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int, k::Int)
##	d - depth of leaf nodes
##	l - depth of node correspodning to given segment
	d = log2(A.number_of_segments)
	l = d-k
	p = A.p0-((A.p0-A.pd)/d)*l
	density = number_of_elements/(right-left)	
	p<=density 
end

## Finds the parent of given segment
##	left - start of the segment (inclusive)
##	right - end of the segment (exclusive)
##	seg_pos - the position of a segemnt in current tree level
##	returns: the bounds of ancestor segment and newly scaned elements 
function ancestor{D}(A::MemoryPackedArray{D},left::Int,right::Int,seg_pos::Int)
	local nr::Int
	seg_capacity = right-left
	if (seg_pos & 1)==1 ## we are in left child;
		nr = scan(A,right,right+seg_capacity)
		right+=seg_capacity
	else 
		nr = scan(A,left-seg_capacity,left)
		left-=seg_capacity
	end
	left,right,nr
end

## Extends the array by factor 2
function extend!{D}(A::MemoryPackedArray{D})
	taken=0
	capacity = (A.capacity << 1)
	store = Array(MPACell{D},capacity)
	exists::Array{Bool,1} = zeros(capacity)
	for i in 1:A.capacity
		if A.exists[i]
			taken += 1
			exists[i] = true
			store[i] = A.store[i]
		end
	end
	A.number_of_segments <<= 1 
	A.capacity = capacity
	A.store = store
	A.exists = exists
	rebalance!(A,1,A.capacity,taken)
	nothing
end


## Extends the array by factor 2 and inserts an element
function extend!{D}(A::MemoryPackedArray{D},index::Int,element::MPACell{D})
	taken=0
	capacity = (A.capacity << 1)
	store = Array(MPACell{D},capacity)
	exists::Array{Bool,1} = zeros(capacity)
	for i in 1:A.capacity
		if A.exists[i]
			taken+=1
			exists[i] = true
			store[i] = A.store[i]
		end
	end
	A.number_of_segments <<= 1
	A.capacity = capacity
	A.store = store
	A.exists = exists
	rebalance!(A,1,A.capacity,taken,index,element)
	nothing
end

## Decreases the array by factor 2 
function decrease!{D}(A::MemoryPackedArray{D})
	taken = 0
	capacity = (A.capacity >> 1)
	store = Array(MPACell{D},capacity)
	exists = Array(Bool,capacity)
	local j=1
	for i in 1:A.capacity
		if A.exists[i]
			taken+=1
			exists[j] = true
			store[j] = A.store[i]
			j+=1 
		end
	end
	A.number_of_segments >>= 1
	A.capacity = capacity
	A.store = store
	A.exists = exists
	rebalance!(A,1,A.capacity,taken)
	nothing
end


## Rebalances given segemnt
##	left - start of the segment (inclusive)
##	right - left of the segment (exlusive)
##	number_of_elements - number of elements in the segment
function rebalance!{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int)
	gap = (right-left)/(number_of_elements+1)
	j = right-1
	i = right-1
	p = 1

##	Move everthing to the right
	while i>=left
		if A.exists[i]
			A.store[j] = A.store[i]
			handleReplacementRight!(A,A.store[j],i,j)
			j -= 1
		end
		A.exists[i] = false
		i -= 1
	end

	
	i = left+floor(Int,p*gap)-1
	p += 1
	
	j += 1 
##	j = Last taken place
##	Move the elements to right positions 
		while i<right && j<right
			A.store[i] = A.store[j]
			handleReplacementLeft!(A,A.store[i],i)
			A.exists[i] = true;
			j += 1
			i = left+floor(Int,p*gap)-1
			p += 1
		end
	nothing 
end

## Rebalances given segemnt with inserting a new element
##	left - start of the segment (inclusive)
##	right - left of the segment (exlusive)
##	number_of_elements - number of elements in the segment
##	index - the index after which insert the element
##	element - the element to be inserted 
function rebalance!{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int,index::Int,element::MPACell{D})
	local gap = (right-left)/(number_of_elements+1)
	local j = right-1
	local i = right-1
	local k = 0
	local p = 1
	
	while i>=left
		if i==index
			k = j+1
		end
		if A.exists[i]
			A.store[j] = A.store[i]
			handleReplacementRight!(A,A.store[j],i,j)
			j -= 1
		end
		A.exists[i] = false
		i -= 1
	end

	k = max(1,k)
	i = left+floor(Int,p*gap)-1
	p += 1
	
	
	if j==right-1 
##	No elements in this segment, place at index
		A.store[index] = element
		A.exists[index] = true
		handleReplacementLeft!(A,A.store[index],index)
	else
		j +=1 
		while i<right && j<k
			A.store[i] = A.store[j]
			handleReplacementLeft!(A,A.store[i],i)
			A.exists[i] = true
			j += 1
			i = left+floor(Int,p*gap)-1
			p += 1
		end
		if i<right 
## 	Then j==k, so insert the new element here
			A.store[i] = element
			handleReplacementLeft!(A,A.store[i],i)
			A.exists[i] = true
			i = left+floor(Int,p*gap)-1
			p += 1
		
		end
		while i<right && j<right
			A.store[i] = A.store[j]
			handleReplacementLeft!(A,A.store[i],i)
			A.exists[i] = true
			j += 1
			i =left+floor(Int,p*gap)-1
				p += 1
		end
	end
	nothing
end


## Deletes element at given index
##	index - the position of the element to be deleted
function delete!{D}(A::MemoryPackedArray{D},index::Int)

	A.exists[index] = false
	
	segment_position = ceil(Int,index/A.segment_capacity)
	right = segment_position*A.segment_capacity+1
	left = right-A.segment_capacity
	number_of_elements = scan(A,left,right)
	leaf_depth = log2(A.number_of_segments)
	seg_capacity = A.segment_capacity
	
	k = 0
	while !(in_lower_threshold(A,left,right,number_of_elements,k)) && k <= leaf_depth 
		k += 1 
		if k>leaf_depth break end

		seg_pos = ceil(Int,index/seg_capacity)
		left, right, nr = ancestor(A,left,right,seg_pos)
		number_of_elements = nr+number_of_elements
		seg_capacity = seg_capacity << 1
	end

	if k>leaf_depth
		extend!(A)
		return  
	end

	rebalance!(A,left,right,number_of_elements)
	nothing
end	


## Inserts element at given index
##	index - the index after which to insert. 
##	Note: 	The index indicates only after which elements insert the new element,
##		due to rebalancing the real position of the element may differ from index, 
##		but the ordering is preserved
##	element - the element to be inserted.   
function insert!{D}(A::MemoryPackedArray{D},index::Int,element::MPACell{D})

##	Left - left border of the segemnt containing element at "index", inclusive
##	Right - right border of the segement conatining element at "index", exclusive


	segment_position = max(ceil(Int,index/A.segment_capacity),1)
	right = segment_position*A.segment_capacity+1
	left = right-A.segment_capacity
	number_of_elements = scan(A,left,right)
	leaf_depth = log2(A.number_of_segments)
	seg_capacity = A.segment_capacity
	
	k = 0
	if (index<A.capacity && in_upper_threshold(A,left,right,number_of_elements,k) && A.exists[index+1]==false)
		A.exists[index+1] = true
		A.store[index+1] = element
		return	
	end

	while !(in_upper_threshold(A,left,right,number_of_elements,k)) && k <= leaf_depth 
		k += 1 
		if k>leaf_depth break end
		seg_pos = max(ceil(Int,index/seg_capacity),1)
		left, right, nr = ancestor(A,left,right,seg_pos)
		number_of_elements = nr+number_of_elements
		seg_capacity = seg_capacity << 1
	end

	if k>leaf_depth
		extend!(A,index,element)
		return
	end

##	Rebalance with inserting the element. 
	rebalance!(A,left,right,number_of_elements,index,element)
	
	nothing 	
end

