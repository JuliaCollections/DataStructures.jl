# This file was copied from Transducers.jl
# which is available under an MIT license (see LICENSE).
using PkgBenchmark
include("pprinthelper.jl")
group_target = PkgBenchmark.readresults(joinpath(@__DIR__, "result-target.json"))
group_baseline = PkgBenchmark.readresults(joinpath(@__DIR__, "result-baseline.json"))
judgement = judge(group_target, group_baseline)

displayresult(judgement)

printnewsection("Target result")
displayresult(group_target)

printnewsection("Baseline result")
displayresult(group_baseline)
