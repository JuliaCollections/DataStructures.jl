# Test of indexer

using DataStructures
using Base.Test

idx = Indexer()
@assert isa(idx, Indexer)

@test get_index(idx, "foo") == 1
@test get_index(idx, "bar") == 2
@test get_index(idx, "foo") == 1

@test reverse_index(idx, convert(Int32,2)) == "bar"
