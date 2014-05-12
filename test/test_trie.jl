using DataStructures
using Base.Test

t=Trie{Int}()

t["amy"]=56
t["ann"]=15
t["emma"]=30
t["rob"]=27
t["roger"]=52

@test haskey(t, "roger")
@test get(t,"rob",nothing) == 27
@test sort(keys(t)) == ["amy", "ann", "emma", "rob", "roger"]
@test t["rob"] == 27
@test sort(keys_with_prefix(t,"ro")) == ["rob", "roger"]


# constructors
ks = ["amy", "ann", "emma", "rob", "roger"]
vs = [56, 15, 30, 27, 52]
@test typeof(Trie(ks, vs)) == Trie{Int}
@test typeof(Trie(collect(zip(ks,vs)))) == Trie{Int}
@test typeof(Trie(Dict(ks, vs))) == Trie{Int}
@test typeof(Trie(ks)) == Trie{Nothing}
