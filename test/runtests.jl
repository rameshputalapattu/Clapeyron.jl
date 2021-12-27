using Clapeyron, Test, Unitful , Printf

t1 = @elapsed using Clapeyron
@info @sprintf("Loading Clapeyron took %.1f seconds", t1)

macro printline()  # useful in hunting for where tests get stuck
    file = split(string(__source__.file), "/")[end]
    printstyled("  ", file, ":", __source__.line, "\n", color=:light_black)
end

@testset "All tests" begin
    include("test_database.jl")
    include("test_solvers.jl")
    include("test_differentials.jl")
    include("test_misc.jl")
    include("test_models.jl")
    include("test_methods.jl")
end
