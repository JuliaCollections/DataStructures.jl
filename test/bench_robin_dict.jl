using BenchmarkTools, Random, DataStructures, Printf, Plots, Statistics

include("../src/robin_dict.jl")

function add_entries(h::AbstractDict, entries::Vector{Pair{K, V}}) where {K, V}
	for (k, v) in entries
		h[k] = v
	end
end

find_key_present(h::AbstractDict, entry) = h[entry]
find_key_absent(h::AbstractDict, entry) = getkey(h, entry, -1)

delete_one_key(h::AbstractDict) = pop!(h)

@printf(".\nSample #1 Key => Integer , Size => 10^6 entries\n.\n")

sample1 = rand(Int, 10^6, 2)
entries1 = Vector{Pair{Int, Int}}()
sizehint!(entries1, 10^6)
for i = 1 : 10^6
	push!(entries1, Pair{Int, Int}(sample1[i, 1], sample1[i, 2]))
end

h = RobinDict()
d = Dict()
@printf("	add_entries for RobinDict{Any, Any}()\n")
@btime add_entries(h, entries1)

@printf("	find_key_present for RobinDict{Any, Any}()\n") 
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Any, Any}()\n")
@btime find_key_absent(h, 1000005)

@printf("	delete_one_key for RobinDict{Any, Any}()\n")
@btime delete_one_key(x) setup = (x = copy(h)) samples = 100 evals = 10;

@printf("	empty! for RobinDict{Any, Any}()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Any, Any}()\n")
@btime add_entries(d, entries1)

@printf("	find_key_present for Dict{Any, Any}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i]; 
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Any, Any}()\n")
@btime find_key_absent(d, 1000005)

@printf("	delete_one_key for Dict{Any, Any}()\n")
@btime delete_one_key(x) setup = (x = copy(d)) samples = 100 evals = 10;

@printf("	empty! for Dict()\n")
@btime empty!(d)

h = RobinDict{Int, Int}()
d = Dict{Int, Int}()
@printf("	add_entries for RobinDict{Int, Int}()\n")
@btime add_entries(h, entries1)

@printf("	find_key_present for RobinDict{Int, Int}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Int, Int}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict{Int, Int}()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Int, Int}()\n")
@btime add_entries(d, entries1)

@printf("	find_key_present for Dict{Int, Int}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Int, Int}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict{Int, Int}()\n")
@btime empty!(d)

@printf(".\nSample #2 Key => Float32 , Size => 10^6 entries\n.\n")

sample2 = rand(Float32, 10^6, 2)
entries2 = Vector{Pair{Float32, Float32}}()
sizehint!(entries2, 10^6)
for i = 1 : 10^6
	push!(entries2, Pair{Float32, Float32}(sample1[i, 1], sample1[i, 2]))
end

h = RobinDict()
d = Dict()
@printf("	add_entries for RobinDict{Any, Any}()\n")
@btime add_entries(h, entries2)

@printf("	find_key_present for RobinDict{Any, Any}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Any, Any}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Any, Any}()\n")
@btime add_entries(d, entries2)

@printf("	find_key_present for Dict{Any, Any}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Any, Any}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)

h = RobinDict{Float32, Float32}()
d = Dict{Float32, Float32}()
@printf("	add_entries for RobinDict{Float32, Float32}()\n")
@btime add_entries(h, entries2)

@printf("	find_key_present for RobinDict{Float32, Float32}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Float32, Float32}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Float32, Float32}()\n")
@btime add_entries(d, entries2)

@printf("	find_key_present for Dict{Float32, Float32}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Float32, Float32}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)


@printf(".\nSample #3 Key => String , Size => 10^6 entries\n.\n")

entries3 = Vector{Pair{String, String}}()
sizehint!(entries3, 10^6)
for i = 1 : 10^6
	push!(entries3, Pair{String, String}(randstring(), randstring()))
end

h = RobinDict()
d = Dict()
@printf("	add_entries for RobinDict{Any, Any}()\n")
@btime add_entries(h, entries3)

@printf("	find_key_present for RobinDict{Any, Any}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Any, Any}()\n")
@btime find_key_absent(h, "absc")

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Any, Any}()\n")
@btime add_entries(d, entries3)

@printf("	find_key_present for Dict{Any, Any}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Any, Any}()\n")
@btime find_key_absent(d, "abcd")

@printf("	empty! for Dict()\n")
@btime empty!(d)

h = RobinDict{String, String}()
d = Dict{String, String}()
@printf("	add_entries for RobinDict{String, String}()\n")
@btime add_entries(h, entries3)

@printf("	find_key_present for RobinDict{String, String}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{String, String}()\n")
@btime find_key_absent(h, "abcd")

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{String, String}()\n")
@btime add_entries(d, entries3)

@printf("	find_key_present for Dict{String, String}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{String, String}()\n")
@btime find_key_absent(d, "abcd")

@printf("	empty! for Dict()\n")
@btime empty!(d)


@printf(".\nSample #4 Key => Integer , Size => 10^7 entries\n.\n")

sample1 = rand(Int, 10^7, 2)
entries1 = Vector{Pair{Int, Int}}()
sizehint!(entries1, 10^7)
for i = 1 : 10^7
	push!(entries1, Pair{Int, Int}(sample1[i, 1], sample1[i, 2]))
end

h = RobinDict()
d = Dict()
@printf("	add_entries for RobinDict{Any, Any}()\n")
@btime add_entries(h, entries1)

@printf("	find_key_present for RobinDict{Any, Any}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Any, Any}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Any, Any}()\n")
@btime add_entries(d, entries1)

@printf("	find_key_present for Dict{Any, Any}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Any, Any}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)

h = RobinDict{Int, Int}()
d = Dict{Int, Int}()
@printf("	add_entries for RobinDict{Int, Int}()\n")
@btime add_entries(h, entries1)

@printf("	find_key_present for RobinDict{Int, Int}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Int, Int}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Int, Int}()\n")
@btime add_entries(d, entries1)

@printf("	find_key_present for Dict{Int, Int}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Int, Int}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)

@printf(".\nSample #5 Key => Integer , Size => 10^5 entries\n.\n")

sample1 = rand(Int, 10^5, 2)
entries1 = Vector{Pair{Int, Int}}()
sizehint!(entries1, 10^5)
for i = 1 : 10^5
	push!(entries1, Pair{Int, Int}(sample1[i, 1], sample1[i, 2]))
end

h = RobinDict()
d = Dict()
@printf("	add_entries for RobinDict{Any, Any}()\n")
@btime add_entries(h, entries1)

@printf("	find_key_present for RobinDict{Any, Any}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Any, Any}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Any, Any}()\n")
@btime add_entries(d, entries1)

@printf("	find_key_present for Dict{Any, Any}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Any, Any}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)

h = RobinDict{Int, Int}()
d = Dict{Int, Int}()
@printf("	add_entries for RobinDict{Int, Int}()\n")
@btime add_entries(h, entries1)

@printf("	find_key_present for RobinDict{Int, Int}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Int, Int}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Int, Int}()\n")
@btime add_entries(d, entries1)

@printf("	find_key_present for Dict{Int, Int}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Int, Int}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)


@printf(".\nSample #6 Key => Float32 , Size => 10^5 entries\n.\n")

sample2 = rand(Float32, 10^5, 2)
entries2 = Vector{Pair{Float32, Float32}}()
sizehint!(entries2, 10^5)
for i = 1 : 10^5
	push!(entries2, Pair{Float32, Float32}(sample1[i, 1], sample1[i, 2]))
end

h = RobinDict()
d = Dict()
@printf("	add_entries for RobinDict{Any, Any}()\n")
@btime add_entries(h, entries2)

@printf("	find_key_present for RobinDict{Any, Any}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Any, Any}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Any, Any}()\n")
@btime add_entries(d, entries2)

@printf("	find_key_present for Dict{Any, Any}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Any, Any}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)

h = RobinDict{Float32, Float32}()
d = Dict{Float32, Float32}()
@printf("	add_entries for RobinDict{Float32, Float32}()\n")
@btime add_entries(h, entries2)

@printf("	find_key_present for RobinDict{Float32, Float32}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Float32, Float32}()\n")
@btime find_key_absent(h, 1000005)

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Float32, Float32}()\n")
@btime add_entries(d, entries2)

@printf("	find_key_present for Dict{Float32, Float32}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Float32, Float32}()\n")
@btime find_key_absent(d, 1000005)

@printf("	empty! for Dict()\n")
@btime empty!(d)


@printf(".\nSample #7 Key => String , Size => 10^5 entries\n.\n")

entries3 = Vector{Pair{String, String}}()
sizehint!(entries3, 10^5)
for i = 1 : 10^5
	push!(entries3, Pair{String, String}(randstring(), randstring()))
end

h = RobinDict()
d = Dict()
@printf("	add_entries for RobinDict{Any, Any}()\n")
@btime add_entries(h, entries3)

@printf("	find_key_present for RobinDict{Any, Any}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{Any, Any}()\n")
@btime find_key_absent(h, "absc")

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{Any, Any}()\n")
@btime add_entries(d, entries3)

@printf("	find_key_present for Dict{Any, Any}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{Any, Any}()\n")
@btime find_key_absent(d, "abcd")

@printf("	empty! for Dict()\n")
@btime empty!(d)

h = RobinDict{String, String}()
d = Dict{String, String}()
@printf("	add_entries for RobinDict{String, String}()\n")
@btime add_entries(h, entries3)

@printf("	find_key_present for RobinDict{String, String}()\n")
hval = h.keys[h.idxfloor]; @btime find_key_present(h, hval)

@printf("	find_key_absent for RobinDict{String, String}()\n")
@btime find_key_absent(h, "abcd")

@printf("	empty! for RobinDict()\n")
@btime empty!(h)

@printf("	add_entries for Dict{String, String}()\n")
@btime add_entries(d, entries3)

@printf("	find_key_present for Dict{String, String}()\n")
i = d.idxfloor
while d.slots[Main.i] != 0x1
	Main.i += 1
end
dval = d.keys[i];
@btime find_key_present(d, dval)

@printf("	find_key_absent for Dict{String, String}()\n")
@btime find_key_absent(d, "abcd")

@printf("	empty! for Dict()\n")
@btime empty!(d)

## Plots

get_load_factor(h::AbstractDict) = (h.count / length(h.keys))

function get_mean_dibs(h::RobinDict)
	sz = length(h.keys)
	dibs = zeros(Int8, sz)
	for i = 1:sz
		if isslotfilled(h, i)
			dibs[i] = calculate_distance(h, i)
		end
	end
	mean(dibs)
end

function get_variance_dibs(h::RobinDict)
	sz = length(h.keys)
	dibs = zeros(Int8, sz)
	for i = 1:sz
		if isslotfilled(h, i)
			dibs[i] = calculate_distance(h, i)
		end
	end
	var(dibs)
end

function plot_helper_add_entries(h::RobinDict, entries::Vector{Pair{K, V}}) where {K, V}
	num = 0
	sz = length(entries)
	sq = floor(sqrt(sz))
	x = Int[]
	lf = Float32[]
	xx = Int[]
	mean_dibs = Float32[]
	var_dibs = Float32[]
	for (k, v) in entries
		push!(x, num)
		push!(lf, get_load_factor(h))
		if (num % sq == 0)
			push!(mean_dibs, get_mean_dibs(h))
			push!(var_dibs, get_variance_dibs(h))
			push!(xx, num)
		end
		h[k] = v
		num += 1
	end
	push!(x, num)
	push!(lf, get_load_factor(h))
	if (num % sq == 0)
		push!(mean_dibs, get_mean_dibs(h))
		push!(var_dibs, get_variance_dibs(h))
		push!(xx, num)
	end
	y = [lf]
	yy = [mean_dibs var_dibs]
	png(plot(x, y, label = ["Load Factor"]), "lf_$(Int(sz/1000))K @$(ROBIN_DICT_LOAD_FACTOR) L.F")
	png(plot(xx, yy, label = ["mean(DIB)", "var(DIB)"]), "dibs_$(Int(sz/1000))K  @$(ROBIN_DICT_LOAD_FACTOR) L.F")
end

sample1 = rand(Int, 10^6, 2)
entries1 = Vector{Pair{Int, Int}}()
sizehint!(entries1, 10^6)
for i = 1 : 10^6
	push!(entries1, Pair{Int, Int}(sample1[i, 1], sample1[i, 2]))
end

plot_helper_add_entries(RobinDict{Int, Int}(), entries1)