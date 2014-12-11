using DataStructures
x = DataStructures.MultiHashDict{Int,ASCIIString}()
push!(x,1=>"Hello")
push!(x,2=>"Test")
push!(x,1=>"World")
@assert collect(x[1]) == ["Hello", "World"]
@assert collect(x[2]) == ["Test"]
