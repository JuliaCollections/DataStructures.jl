using DataStructures
using Base.Test

t=Trie{Int}()

t["amy"]=56
t["ann"]=15
t["emma"]=30
t["rob"]=27
t["roger"]=52

@test haskey(t, "roger")
@test get(t,"rob") == 27
