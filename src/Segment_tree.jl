abstract type Abstractsegmenttreenode{Dtype, Op, iterated_op} end
abstract type Abstractsegmenttree{node_type} end

#=
Segment trees have the following traits.
1) can_add_range: either Val{True} or Val{False}.
2) can_change_range: either Val{True} or Val{False}. 
3) is_functional: either Val{True} or Val{False}

Dispatching will have "valid". Dispatching for invalid would be error.
=#
can_add_range(::Abstractsegmenttree)= false;
can_change_range(::Abstractsegmenttree) = true;
is_functional(::Abstractsegmenttree) = false;


function repeat_op(base,time::Integer, op::Function)
    #Hopefully segment tree not larger than 64. Otherwise, big number segment tree may be needed.
    Iterations = convert(UInt,time)
    #Find trailing zeros.
    baseline = base
    for i in 1:trailing_zeros(Iterations)
        baseline = op(baseline,baseline)
    end
    Iterations = Iterations>>trailing_zeros(Iterations)
    
    #Operate to get to the baseline.
    #baseline = #Working in progress.
    
    #Then, you can iterate.
    final_value = baseline
    while (Iterations!=0)
        Iterations>>=1
        baseline = op(baseline,baseline)
        if isodd(Iterations)
            final_value = op(final_value,baseline)
        end
    end
    #Something

    
    return final_value
end



mutable struct Segment_tree{node_type<:Abstractsegmenttreenode}<:Abstractsegmenttree{node_type}
    size::UInt64
    head::node_type
end

struct functional_segment_tree{node_type<:Abstractsegmenttreenode}<:Abstractsegmenttree{node_type}
    size::UInt64
    head::node_type
end

mutable struct Segment_tree_node{Dtype, Op, iterated_op}<:Abstractsegmenttreenode{Dtype,Op,iterated_op}