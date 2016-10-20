

## --------------------------- WARNING:: WORK IN PROGRESS --------------------------- ##


## This file implements memory-packed arrays
## The array is used to implement cache-oblivious trees


## Functions simplifing notation: 

## Function returning the closest power of 2 >= x 
#@inline hyperceil(x::Float64) = 1 << (ceil(log2(x)));
## Function returning the closest power of 2 <= x
#@inline hyperfloor(x::Float64) = 1 << (floor(log2(x))); 

## TODO: make the constructor idiotensicher ??


## Note:  
##	size - is equal c*N where 
## 		N - number of elemnts stored
##		c - some desired constant 
##	segment_size - the size of a segment, this is ceil(lg(size))
##	number_of_segments - the number of segments 
##	p0 - density lower threshold for root
##	t0 - density upper threshold for root
##	pd - density lower threshold for leaves
## 	td - density upper threashold for leaves
##		thresholds should satisfy:
##		0 < pd < p0 < to < td = 1 
##

##	exists - flags indicating whether a coresponding 
##		cell in store is occupied  
##	store  - the array storing the actual elemnts	
## TODO: search for alternatives for exists

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
	function MemoryPackedArray(size::Int, p0::Float64, pd::Float64, t0::Float64, td::Float64)
			seg_size = ceil(log2(size));
			no_seg = hyperceil(size/seg_size);
			sizeP = number_of_segments*segment_size;
			store = Array(D,sizeP);
			exists = zeros(sizeP);
			new(sizeP,seg_size,no_seg,p0,pd,t0,td,store,exists)
	end
end

## Function that scans the entire segment,
##	from - start of the segment (inclusive) 
##	to - end of the segment (exclusive).
##	returns: number of elemnts in the segment
	 
function scan{D}(A::MemoryPackedArray{D},from::Int,to::Int)
	local nr = 0;
	local i = from;
	local j = to-1;
	while(i<j)
		if(A.exists[i])
			nr = nr+1;
		end
		if(A.exists[j])
			nr = nr+1;
		end
		i = i+1;
		j = j-1;	
	end

## 	If segemnt_size is odd we haven't checked the element in the middle.
s
	if ((A.segment_size & 1) == 1) && (A.exists[i])
		nr = nr+1;
	end
##	return	
	nr
end

function in_threashold{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elements::Int, k::Int)
	local d = log2(A.number_of_segments);
	local l = d-k;
	local t = A.t0+((A.td-A.t0)/d)*l;
	local p = A.p0-((A.p0-A.pd)/d)*l;
	density = number_of_elemnts/(right-left);
	## return	
	p<=density && density<=t
end

function ancestor{D}(A::MemoryPackedArray{D},left::Int,right::Int,seg_pos::Int, seg_size::Int)
	local nr::Int;
	if (seg_pos & 1)==1 ## we are in left child;
		nr = scan(A,right,right+seg_size+1);
		right = right+seg_size;
	else 
		nr = scan(A,left-seg_size,left);
		left = left-seg_size;
	end
##	return 
	left,right,nr
end


##	TODO:make this wiser
function rebalance{D}(A::MemoryPackedArray{D},left::Int,right::Int,number_of_elemnts::Int,index::Int,elemnt::D)
	local gap = ceil((right-left)/number_of_elemnts);
	local j = left;
	local i = left;
	local k::Int;
	## move everthing to the left
	while i<right
		if A.exists[i]
			A.store[j] = A.store[i];
			j = j+1;
		end
		if i==index
			k = j-1;
		end
		A.exists[i] = false;
		i = i+1;
	end
	
	i = right-1
	while i>=left && j-1>k
		A.store[i] = A.store[j-1];
		A.exists[i] = true;
		j = j-1;
		i = i-gap;
	end
	if i>=left
		A.store[i] = elemnt;
		A.exists[i] = true;
		i = i-gap;
	end

	while i>=left && j-1>=left
		A.store[i] = A.store[j-1];
		A.exists[i] = true;
		j = j-1;
		i = i-gap;
	end
	
	nothing
end

function insert!{D}(A::MemoryPackedArray{D},index::Int,element::D)

##	left - left border of the segemnt containing elemnt at "index", inclusive
##		this is the same as div(index/seg_size)*seg_size
##	right - right border of the segement conatining elemnt at "index", exclusive

	local left =  index - index%(A.segment_size)+1;
	local right = left+A.segment_size+1;


##	scan couting the elemnts;
	local number_of_elements = scan(A,left,right);
	local leaf_depth = log2(A.number_of_segments);
	local seg_size = A.segment_size;
	local k = 0;

	while !(in_threashold(A,left,right,number_of_elemnts,k)) && k <= leaf_depth 
		seg_pos = ceil(index/seg_size);
		left, right, number_of_elemnts = ancestor(A,left,right,seg_pos,seg_size);
		seg_size << 1;
		k=k+1;
	end

	if (k>leaf_depth)
		##TODO: handle the situation  
	end

##	rebalnace with inserting the element. 
	rebalnace(A,left,right,number_of_elements,index,element);
		
	nothing 	
end

