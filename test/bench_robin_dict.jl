using BenchmarkTools, Random, DataStructures, Printf, Plots, Statistics

include("../src/robin_dict.jl")

function add_entries(h::AbstractDict, entries::Vector{Pair{K, V}}) where {K, V}
	for (k, v) in entries
		h[k] = v
	end
end

@printf(".\nSample #1 Key => Integer , Size => 10^6 entries\n.\n")

sample1 = rand(Int, 10^6, 2)
entries1 = Vector{Pair{Int, Int}}()
sizehint!(entries1, 10^6)
for i = 1 : 10^6
	push!(entries1, Pair{Int, Int}(sample1[i, 1], sample1[i, 2]))
end

@printf("	add_entries for RobinDict()\n")
@btime add_entries(RobinDict(), entries1)

@printf("	add_entries for Dict()\n")
@btime add_entries(Dict(), entries1)

@printf("	add_entries for RobinDict{Int, Int}()\n")
@btime add_entries(RobinDict{Int, Int}(), entries1)

@printf("	add_entries for Dict{Int, Int}()\n")
@btime add_entries(Dict{Int, Int}(), entries1)

@printf(".\nSample #2 Key => Float32 , Size => 10^6 entries\n.\n")

sample2 = rand(Float32, 10^6, 2)
entries2 = Vector{Pair{Float32, Float32}}()
sizehint!(entries2, 10^6)
for i = 1 : 10^6
	push!(entries2, Pair{Float32, Float32}(sample1[i, 1], sample1[i, 2]))
end

@printf("	add_entries for RobinDict()\n")
@btime add_entries(RobinDict(), entries2)

@printf("	add_entries for Dict()\n")
@btime add_entries(Dict(), entries2)

@printf("	add_entries for RobinDict{Float32, Float32}()\n")
@btime add_entries(RobinDict{Float32, Float32}(), entries2)

@printf("	add_entries for Dict{Float32, Float32}()\n")
@btime add_entries(Dict{Float32, Float32}(), entries2)



@printf(".\nSample #3 Key => String , Size => 10^6 entries\n.\n")

entries3 = Vector{Pair{String, String}}()
sizehint!(entries3, 10^6)
for i = 1 : 10^6
	push!(entries3, Pair{String, String}(randstring(), randstring()))
end

@printf("	add_entries for RobinDict()\n")
@btime add_entries(RobinDict(), entries3)

@printf("	add_entries for Dict()\n")
@btime add_entries(Dict(), entries3)

@printf("	add_entries for RobinDict{String, String}()\n")
@btime add_entries(RobinDict{String, String}(), entries3)

@printf("	add_entries for Dict{String, String}()\n")
@btime add_entries(Dict{String, String}(), entries3)

@printf(".\nSample #4 Key => Integer , Size => 10^7 entries\n.\n")

sample1 = rand(Int, 10^7, 2)
entries1 = Vector{Pair{Int, Int}}()
sizehint!(entries1, 10^7)
for i = 1 : 10^7
	push!(entries1, Pair{Int, Int}(sample1[i, 1], sample1[i, 2]))
end

@printf("	add_entries for RobinDict()\n")
@btime add_entries(RobinDict(), entries1)

@printf("	add_entries for Dict()\n")
@btime add_entries(Dict(), entries1)

@printf("	add_entries for RobinDict{Int, Int}()\n")
@btime add_entries(RobinDict{Int, Int}(), entries1)

@printf("	add_entries for Dict{Int, Int}()\n")
@btime add_entries(Dict{Int, Int}(), entries1)

@printf(".\nSample #5 Key => Integer , Size => 10^5 entries\n.\n")

sample1 = rand(Int, 10^5, 2)
entries1 = Vector{Pair{Int, Int}}()
sizehint!(entries1, 10^5)
for i = 1 : 10^5
	push!(entries1, Pair{Int, Int}(sample1[i, 1], sample1[i, 2]))
end

@printf("	add_entries for RobinDict()\n")
@btime add_entries(RobinDict(), entries1)

@printf("	add_entries for Dict()\n")
@btime add_entries(Dict(), entries1)

@printf("	add_entries for RobinDict{Int, Int}()\n")
@btime add_entries(RobinDict{Int, Int}(), entries1)

@printf("	add_entries for Dict{Int, Int}()\n")
@btime add_entries(Dict{Int, Int}(), entries1)

@printf(".\nSample #6 Key => Float32 , Size => 10^5 entries\n.\n")

sample2 = rand(Float32, 10^5, 2)
entries2 = Vector{Pair{Float32, Float32}}()
sizehint!(entries2, 10^5)
for i = 1 : 10^5
	push!(entries2, Pair{Float32, Float32}(sample1[i, 1], sample1[i, 2]))
end

@printf("	add_entries for RobinDict()\n")
@btime add_entries(RobinDict(), entries2)

@printf("	add_entries for Dict()\n")
@btime add_entries(Dict(), entries2)

@printf("	add_entries for RobinDict{Float32, Float32}()\n")
@btime add_entries(RobinDict{Float32, Float32}(), entries2)

@printf("	add_entries for Dict{Float32, Float32}()\n")
@btime add_entries(Dict{Float32, Float32}(), entries2)



@printf(".\nSample #7 Key => String , Size => 10^5 entries\n.\n")

entries3 = Vector{Pair{String, String}}()
sizehint!(entries3, 10^5)
for i = 1 : 10^5
	push!(entries3, Pair{String, String}(randstring(), randstring()))
end

@printf("	add_entries for RobinDict()\n")
@btime add_entries(RobinDict(), entries3)

@printf("	add_entries for Dict()\n")
@btime add_entries(Dict(), entries3)

@printf("	add_entries for RobinDict{String, String}()\n")
@btime add_entries(RobinDict{String, String}(), entries3)

@printf("	add_entries for Dict{String, String}()\n")
@btime add_entries(Dict{String, String}(), entries3)


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