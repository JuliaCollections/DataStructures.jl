## This file implements memory-packed arrays
## The array is going to be used to implement cache-oblivious B-trees


## Functions simplifing notation: 
## Function returning the closest power of 2 >= x 
@inline hyperceil(x::Float64) = 1 << (ceil(Int,log2(x)));
## Function returning the closest power of 2 <= x
@inline hyperfloor(x::Float64) = 1 << (floor(Int,log2(x))); 

## Note:  
##	size - is equal to some c*N where 
## 		N - number of elements stored
##		c - some desired constant 
##	segment_size - the size of a segment, this is ceil(lg(size))
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
	size::Int
	segment_size::Int
	number_of_segments::Int
	p0::Float64
	pd::Float64 
	t0::Float64
	td::Float64
	store::Array{D,1} 
	exists::Array{Bool,1}
	function MemoryPackedArray(size::Int, pd::Float64, p0::Float64, t0::Float64, td::Float64)
			seg_size = ceil(Int,log2(size));
			no_seg = hyperceil(size/seg_size);
			sizeP = no_seg*seg_size;
			store = Array(D,sizeP);
			exists = zeros(sizeP);
			new(sizeP,seg_size,no_seg,p0,pd,t0,td,store,exists)
	end
end

## Scans the segment,
##	from - start of the segment (inclusive) 
##	to - end of the segment (exclusive)
##	returns: number of elements in the segment
	 
function scan{D}(A::MemoryPackedArray{D},from::Int,to::Int)
	sum(A.exists[from:(to-1)]);	
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
	local d = log2(A.number_of_segments);
	local l = d-k;
	local t = A.t0+((A.td-A.t0)/d)*l;
	local p = A.p0-((A.p0-A.pd)/d)*l;
	density = number_of_elements/(right-left);	
	p<=density && density<=t
end


## Finds the parent of given segment
##	left - start of the segment (inclusive)
##	right - end of the segment (exclusive)
##	seg_pos - the position of a segemnt in current tree level
##	returns: the bounds of ancestor segment and newly scaned elements 
function ancestor{D}(A::MemoryPackedArray{D},left::Int,right::Int,seg_pos::Int)
	local nr::Int;
	local seg_size = right-left;
	if (seg_pos & 1)==1 ## we are in left child;
		nr = scan(A,right,right+seg_size);
		right = right+seg_size;
	else 
		nr = scan(A,left-seg_size,left);
		left = left-seg_size;
	end
	left,right,nr
end

## Extends the array by factor 2
function extend!{D}(A::MemoryPackedArray{D})
	local taken=0;
	local size = A.size*2;
	local store = Array(D,size);
	local exists::Array{Bool,1} = zeros(size);
	for i in 1:A.size
		if A.exists[i]
			taken = taken+1;
			exists[i] = true;
			store[i] = A.store[i];
		end
	end
	A.number_of_segments = 2*A.number_of_segments;
	A.size = size;
	A.store = store;
	A.exists = exists;
	rebalance!(A,1,A.size,taken);
	nothing
end


## Extends the array by factor 2 and inserts an element
function extend!{D}(A::MemoryPackedArray{D},index::Int,element::D)
	local taken=0;
	local size = A.size*2;
	local store = Array(D,size);
	local exists::Array{Bool,1} = zeros(size);
	for i in 1:A.size
		if A.exists[i]
			taken = taken+1;
			exists[i] = true;
			store[i] = A.store[i];
		end
	end
	A.number_of_segments = 2*A.number_of_segments;
	A.size = size;
	A.store = store;
	A.exists = exists;
	rebalance!(A,1,A.size,taken,index,element);
	nothing
end

## Decreases the array by factor 2 
function decrease!{D}(A::MemoryPackedArray{D})
	local taken = 0;
	local size = A.size/2;
	store = Array(D,size);
	exists = Array(Bool,size);
	local j=1;
	for i in 1:A.size
		if A.exists[i]
			taken = taken+1;
			exists[j] = true;
			store[j] = A.store[i];
			j = j+1;
		end
	end
	A.number_of_segments = 2*A.number_of_segments;
	A.size = size;
	A.store = store;
	A.exists = exists;
	rebalance!(A,1,A.size,taken);
	nothing
end


## Rebalances given segemnt
##	left - start of the segment (inclusive)
##	right - left of the segment (exlusive)
##	number_of_elements - number of elements in the segment
function rebalance!{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int)
	local gap = (right-left)/(number_of_elements+1);
	local j = right-1;
	local i = right-1;
	local p = 1;

##	Move everthing to the right
	while i>=left
		if A.exists[i]
			A.store[j] = A.store[i];
			j = j-1;
		end
		A.exists[i] = false;
		i = i-1;
	end

	
	i = left+floor(Int,p*gap)-1;
	p = p+1;
	
	
	if j==right-1
## 	No place taken - just insert and move on
		A.store[index] = element;
		A.exists[index] = true;
	else
		j = j+1; 
##	j = Last taken place
##	Move the elements to right positions 
		while i<right && j<right
			A.store[i] = A.store[j];
			A.exists[i] = true;
			j = j+1;
			i = left+floor(Int,p*gap)-1;
			p = p+1;
		end
		
	end
	nothing 
end

## Rebalances given segemnt with inserting a new element
##	left - start of the segment (inclusive)
##	right - left of the segment (exlusive)
##	number_of_elements - number of elements in the segment
##	index - the index after which insert the element
##	element - the element to be inserted 
function rebalance!{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int,index::Int,element::D)
	local gap = (right-left)/(number_of_elements+1);
	local j = right-1;
	local i = right-1;
	local k = 0;
	local p = 1;
	
	while i>=left
		if i==index
			k = j+1;
		end
		if A.exists[i]
			A.store[j] = A.store[i];
			j = j-1;
		end
		A.exists[i] = false;
		i = i-1;
	end

	k = max(1,k);
	i = left+floor(Int,p*gap)-1;
	p = p+1;
	
	
	if j==right-1 
##	No elements in this segemnt, place at index
		A.store[index] = element;
		A.exists[index] = true;
		println("HERE1");
	else
		j = j+1; 
		while i<right && j<k
			A.store[i] = A.store[j];
			A.exists[i] = true;
			j = j+1;
			i = left+floor(Int,p*gap)-1;
			p = p+1;
		end
		if i<right 
## 	Then j==k, so insert the new element here
			A.store[i] = element;
			A.exists[i] = true;
			i = left+floor(Int,p*gap)-1;
			p = p+1;
		
		end
		while i<right && j<right
			A.store[i] = A.store[j];
			A.exists[i] = true;
			j = j+1;
			i =left+floor(Int,p*gap)-1;
				p = p+1;
		end
	end
	nothing
end


## Deletes element at given index
##	index - the position of the element to be deleted
function delete!{D}(A::MemoryPackedArray{D},index::Int)

	A.exists[index] = false;
	
	local segment_position = ceil(Int,index/A.segment_size);
	local right = segment_position*A.segment_size+1;
	local left = right-A.segment_size;
	local number_of_elements = scan(A,left,right);
	local leaf_depth = log2(A.number_of_segments);
	local seg_size = A.segment_size;

	println(seg_size," ",right-left);
	
	local k = 0;

	while !(in_threshold(A,left,right,number_of_elements,k)) && k <= leaf_depth 
		k += 1 
		if k>leaf_depth break end;

		seg_pos = ceil(Int,index/seg_size);
		left, right, nr = ancestor(A,left,right,seg_pos);
		number_of_elements = nr+number_of_elements;
		seg_size = seg_size << 1;
	end

	if k>leaf_depth
		extend(A);
		return  
	end

	rebalance!(A,left,right,number_of_elements);
	nothing
end	


## Inserts element at given index
##	index - the index after which to insert. 
##	Note: 	The index indicates only after which elements insert the new element,
##		due to rebalancing the real position of the element may differ from index, 
##		but the ordering is preserved
##	element - the element to be inserted.   
function insert!{D}(A::MemoryPackedArray{D},index::Int,element::D)

##	Left - left border of the segemnt containing element at "index", inclusive
##	Right - right border of the segement conatining element at "index", exclusive


	local segment_position = ceil(Int,index/A.segment_size);

	segment_position = max(segment_position,1);
	
	local right = segment_position*A.segment_size+1;
	local left = right-A.segment_size;
	local number_of_elements = scan(A,left,right);
	local leaf_depth = log2(A.number_of_segments);
	local seg_size = A.segment_size;
	local k = 0;


	if (index<A.size && in_threshold(A,left,right,number_of_elements,k) && A.exists[index+1]==false)
		A.exists[index+1] = true;
		A.store[index+1] = element;
		println("HERE2");
		return	
	end

	while !(in_threshold(A,left,right,number_of_elements,k)) && k <= leaf_depth 
		k += 1 
		if k>leaf_depth break end;
		seg_pos = ceil(Int,index/seg_size);
		left, right, nr = ancestor(A,left,right,seg_pos);
		number_of_elements = nr+number_of_elements;
		seg_size = seg_size << 1;
	end

	if k>leaf_depth
		extend!(A,index,element); 
		return;
	end

##	Rebalance with inserting the element. 
	rebalance!(A,left,right,number_of_elements,index,element);
	
	nothing 	
end

