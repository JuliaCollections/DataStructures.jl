# This file was copied from Transducers.jl
# which is available under an MIT license (see LICENSE).
using PkgBenchmark

mkconfig(; kwargs...) =
    BenchmarkConfig(
        env = Dict(
            "JULIA_NUM_THREADS" => "1",
        );
        kwargs...
    )

group_target = benchmarkpkg(
    dirname(@__DIR__),
    mkconfig(),
    resultfile = joinpath(@__DIR__, "result-target.json"),
)
