"""
    α_function(model::CubicModel,V,T,z,αmodel::AlphaModel)  

Interface function used in cubic models. it should return a vector of αᵢ(T).

## Example:

```julia
function α_function(model::CubicModel,V,T,z,alpha_model::RKAlphaModel)
    return 1 ./ sqrt.(T ./ Tc)
end
```
"""
function α_function end


function init_model(model::AlphaModel,components,userlocations,verbose)
    return model
end

function init_model(model::Type{<:AlphaModel},components,userlocations,verbose)
    verbose && @info("""Now creating alpha model:
    $model""")
    return model(components;userlocations,verbose)
end

include("NoAlpha.jl")
include("ClausiusAlpha.jl")
include("RKAlpha.jl")
include("soave.jl")
include("PRAlpha.jl")
include("PatelTejaAlpha.jl")
include("PTVAlpha.jl")
include("CPAAlpha.jl")
include("sCPAAlpha.jl")
include("PR78Alpha.jl")
include("BM.jl")
include("Twu.jl")
include("MT.jl")
include("KUAlpha.jl")
