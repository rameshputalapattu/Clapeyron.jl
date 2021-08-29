struct UNIFACParam <: EoSParam
    A::PairParam{Float64}
    B::PairParam{Float64}
    C::PairParam{Float64}
    R::SingleParam{Float64}
    Q::SingleParam{Float64}
end

abstract type UNIFACModel <: ActivityModel end

struct UNIFAC{c<:EoSModel} <: UNIFACModel
    components::Array{String,1}
    icomponents::UnitRange{Int}
    groups::GroupParam
    params::UNIFACParam
    puremodel::Vector{c}
    absolutetolerance::Float64
    references::Array{String,1}
end

has_sites(::Type{<:UNIFACModel}) = false
has_groups(::Type{<:UNIFACModel}) = true
built_by_macro(::Type{<:UNIFACModel}) = false

function Base.show(io::IO, mime::MIME"text/plain", model::UNIFAC)
    return eosshow(io, mime, model)
end

function Base.show(io::IO, model::UNIFAC)
    return eosshow(io, model)
end

Base.length(model::UNIFAC) = Base.length(model.icomponents)

molecular_weight(model::UNIFAC,z=SA[1.0]) = group_molecular_weight(mw(model),z)

export UNIFAC

function UNIFAC(components; puremodel=PR,
    userlocations=String[], 
     verbose=false)
    groups = GroupParam(components, ["Activity/UNIFAC/UNIFAC_groups.csv"]; verbose=verbose)

    params = getparams(groups, ["Activity/UNIFAC/UNIFAC_like.csv", "Activity/UNIFAC/UNIFAC_unlike.csv"]; userlocations=userlocations, asymmetricparams=["A","B","C"], ignore_missing_singleparams=["A","B","C"], verbose=verbose)
    A  = params["A"]
    B  = params["B"]
    C  = params["C"]
    R  = params["R"]
    Q  = params["Q"]
    icomponents = 1:length(components)
    
    init_puremodel = [puremodel([components[i]]) for i in icomponents]
    packagedparams = UNIFACParam(A,B,C,R,Q)
    references = String[]
    model = UNIFAC(components,icomponents,groups,packagedparams,init_puremodel,1e-12,references)
    return model
end

function activity_coefficient(model::UNIFACModel,V,T,z)
    return exp.(@f(lnγ_comb)+@f(lnγ_res))
end

function lnγ_comb(model::UNIFACModel,V,T,z)
    Q = model.params.Q.values
    R = model.params.R.values

    v  = model.groups.n_flattenedgroups

    x = z ./ sum(z)

    r =sum(v[:][k]*R[k] for k in @groups)
    q =sum(v[:][k]*Q[k] for k in @groups)

    Φ = r/sum(x[i]*r[i] for i ∈ @comps)
    Φ_p = r.^(3/4)/sum(x[i]*r[i]^(3/4) for i ∈ @comps)
    θ = q/sum(x[i]*q[i] for i ∈ @comps)
    lnγ_comb = @. log(Φ_p)+(1-Φ_p)-5*q*(log(Φ/θ)+(1-Φ/θ))
    return lnγ_comb
end

function lnγ_res(model::UNIFACModel,V,T,z)
    v  = model.groups.n_flattenedgroups

    lnΓ_ = @f(lnΓ)
    lnΓi_ = @f(lnΓi)
    lnγ_res_ =  sum(v[:][k].*(lnΓ_[k].-lnΓi_[:][k]) for k ∈ @groups)
    return lnγ_res_
end

function lnΓ(model::UNIFACModel,V,T,z)
    A = model.params.A.values
    B = model.params.B.values
    C = model.params.C.values
    Q = model.params.Q.values
    
    v  = model.groups.n_flattenedgroups

    x = z ./ sum(z)

    ψ = @. exp(-(A+B*T+C*T^2)/T)
    X = sum(v[i][:]*x[i] for i ∈ @comps) ./ sum(sum(v[i][k]*x[i] for k ∈ @groups) for i ∈ @comps)
    θ = X.*Q / dot(X,Q)

    lnΓ_ = Q.*(1 .-log.(sum(θ[m]*ψ[m,:] for m ∈ @groups)) .- sum(θ[m]*ψ[:,m]./sum(θ[n]*ψ[n,m] for n ∈ @groups) for m ∈ @groups))
    return lnΓ_
end

function lnΓi(model::UNIFACModel,V,T,z)
    A = model.params.A.values
    B = model.params.B.values
    C = model.params.C.values
    Q = model.params.Q.values
    
    v  = model.groups.n_flattenedgroups

    ψ = @. exp(-(A+B*T+C*T^2)/T)
    X = v ./ sum(v[:][k] for k ∈ @groups)
    θ = X.*Q ./ sum(X[:][n]*Q[n] for n ∈ @groups)
    lnΓi_ = [Q.*(1 .-log.(sum(θ[i][m]*ψ[m,:] for m ∈ @groups)) .- sum(θ[i][m]*ψ[:,m]./sum(θ[i][n]*ψ[n,m] for n ∈ @groups) for m ∈ @groups)) for i ∈ @comps]
    return lnΓi_
end

is_splittable(::UNIFAC) = true
