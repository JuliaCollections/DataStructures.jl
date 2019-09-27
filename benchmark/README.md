## Notes on regression testing with PkgBenchmark

### To troubleshoot benchmark script locally:
```
julia --project=benchmark -e '
    using Pkg; Pkg.instantiate();
    include("benchmark/runbenchmarks.jl");'
```

### To compare against baseline locally:

Note, must have a `baseline` branch, which will be the refrence point against the currently active branch. A common use case is to point the baseline to the previous commit.

This can be accomplished with
```
git branch baseline HEAD~
```

If there are errors preventing branch creation (likely due to earlier local benchmarking), may force a repoint with
```
git branch -f baseline HEAD~
```

Then run this command:
```
julia --project=benchmark -e '
    using Pkg; Pkg.instantiate();
    include("benchmark/runjudge.jl");
    include("benchmark/pprintjudge.jl");'
```