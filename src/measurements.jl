"""
    measure(ψ::MPS, measurement::Tuple{String,Int}, s::Vector{<:Index})
    measure(ψ::MPS, measurement::Tuple{String,Int})
  
Perform a measurement of a 1-local operator on an MPS ψ. The operator
is identifyed by a String (corresponding to a `gate`) and a site.
If an additional set of indices `s` is provided, the correct site is 
extracted by comparing the MPS with the index order in `s`.
"""
function measure(ψ::MPS, measurement::Tuple{String,Int}, s::Vector{<:Index})
  site0 = measurement[2]
  site = findsite(ψ,s[site0])
  ϕ = orthogonalize!(copy(ψ), site)
  ϕs = ϕ[site]
  obs_op = gate(measurement[1], firstsiteind(ϕ, site))
  T = noprime(ϕs * obs_op)
  return real((dag(T) * ϕs)[])
end

measure(ψ::MPS, measurement::Tuple{String,Int}) = 
  measure(ψ, measurement, siteinds(ψ))

measure(L::LPDO{MPS}, args...) = measure(L.X, args...)

function measure(ρ::MPO, args...)
  error("Measurement of one-body operator on MPOs not yet implemented")
end

measure(L::LPDO{MPO}, args...) = measure(MPO(L), args...)


"""
    measure(ψ::MPS, measurement::Tuple{String,Array{Int}}, s::Vector{<:Index})
    measure(ψ::MPS, measurement::Tuple{String,Array{Int}})
    measure(ψ::MPS, measurement::Tuple{String,AbstractRange}, s::Vector{<:Index})
    measure(ψ::MPS, measurement::Tuple{String,AbstractRange})
    measure(ψ::MPS, measurement::String, s::Vector{<:Index})
    measure(ψ::MPS, measurement::String)

Perform a measurement of a 1-local operator on an MPS ψ on a set of sites passed 
as a vector. If an additional set of indices `s` is provided, the correct site is 
extracted by comparing the MPS with the index order in `s`.
"""
function measure(ψ::MPS, measurement::Tuple{String,Array{Int}}, s::Vector{<:Index})
  result = []
  sites0 = measurement[2]
  ϕ = copy(ψ)
  for site0 in sites0
    site = findsite(ϕ,s[site0])
    orthogonalize!(ϕ, site)
    ϕs = ϕ[site]
    obs_op = gate(measurement[1], firstsiteind(ϕ, site))
    T = noprime(ϕs * obs_op)
    push!(result, real((dag(T) * ϕs)[]))
  end
  return result
end

measure(ψ::MPS, measurement::Tuple{String,Array{Int}}) = 
   measure(ψ,measurement,siteinds(ψ))

# for a range of sites
measure(ψ::MPS, measurement::Tuple{String,AbstractRange}, s::Vector{<:Index}) = 
  measure(ψ, (measurement[1], Array(measurement[2])), s)

measure(ψ::MPS, measurement::Tuple{String,AbstractRange}) = 
  measure(ψ, (measurement[1], Array(measurement[2])), siteinds(ψ))

# for every sites
measure(ψ::MPS, measurement::String, s::Vector{<:Index}) = 
  measure(ψ::MPS, (measurement, 1:length(ψ)),s)

## for every sites
measure(ψ::MPS, measurement::String) = 
  measure(ψ::MPS, (measurement, 1:length(ψ)), siteinds(ψ))


# at a given site
"""
    measure(ψ::MPS, measurement::Tuple{String,Int,String,Int}, s::Vector{<:Index})


Perform a measurement of a 2-body tensor-product operator on an MPS ψ. The two operators
are defined by Strings (for op name) and the sites. If an additional set of indices `s` is provided, the correct site is 
extracted by comparing the MPS with the index order in `s`.
"""
function measure(ψ::MPS, measurement::Tuple{String,Int,String,Int}, s::Vector{<:Index})
  obsA  = measurement[1]
  obsB  = measurement[3]
  siteA0 = measurement[2]
  siteB0 = measurement[4]
  siteA = findsite(ψ,s[siteA0])
  siteB = findsite(ψ,s[siteB0])
  
  if siteA > siteB
    obsA, obsB  = obsB, obsA
    siteA,siteB = siteB,siteA
  end
  ϕ = orthogonalize!(copy(ψ), siteA)
  ϕdag = prime(dag(ϕ),tags="Link")
  
  if siteA == siteB
    C = ϕ[siteA] * gate(obsA, firstsiteind(ϕ, siteA))
    C = noprime(C,tags="Site") * gate(obsA, firstsiteind(ϕ, siteA)) 
    C = noprime(C,tags="Site") * noprime(ϕdag[siteA])
    return real(C[])
  end
  if siteA == 1
    C = ϕ[siteA] * gate(obsA, firstsiteind(ϕ, siteA))
    C = noprime(C,tags="Site") * ϕdag[siteA]
  else
    C = prime(ϕ[siteA],commonind(ϕ[siteA],ϕ[siteA-1])) * gate(obsA, firstsiteind(ϕ, siteA))
    C = noprime(C,tags="Site") * ϕdag[siteA]
  end
  for j in siteA+1:siteB-1
    C = C * ϕ[j]
    C = C * ϕdag[j]
  end
  if siteB == length(ϕ)
    C = C * ϕ[siteB] * gate(obsB, firstsiteind(ϕ, siteB))
    C = noprime(C,tags="Site") * ϕdag[siteB]
  else
    C = C * prime(ϕ[siteB],commonind(ϕ[siteB],ϕ[siteB+1])) * gate(obsB, firstsiteind(ϕ, siteB))
    C = noprime(C,tags="Site") * ϕdag[siteB]
  end
  return real(C[])
end

measure(ψ::MPS, measurement::Tuple{String,Int,String,Int}) = 
  measure(ψ, measurement, siteinds(ψ))

function measure(ψ::MPS, measurement::Tuple{String,String}, s::Vector{<:Index})
  N = length(ψ)
  C = Matrix{Float64}(undef,N,N)
  for siteA in 1:N
    for siteB in 1:N
      m = (measurement[1],siteA,measurement[2],siteB)
      result = measure(ψ, m, s)
      C[siteA,siteB] = result
    end
  end
  return C
end

# for every sites
measure(ψ::MPS, measurement::Tuple{String,String}) = 
  measure(ψ::MPS, measurement, siteinds(ψ))


"""
Observer
"""

function measure!(observer::Observer, M::Union{MPS,MPO}, ref_indices::Vector{<:Index})
  for measurement in keys(observer.measurements)
    if observer.measurements[measurement] isa Pair{<:Function, <:Any}
      res = first(observer.measurements[measurement])(M, last(observer.measurements[measurement])...)
    elseif observer.measurements[measurement] isa Function
      res = observer.measurements[measurement](M)
    else
      res = measure(M, observer.measurements[measurement], ref_indices)
    end
    push!(observer.results[measurement], res)
  end
end

measure!(observer::Observer, L::LPDO{MPS}, ref_indices::Vector{<:Index}) = 
  measure!(observer, L.X, ref_indices)

measure!(observer::Observer, L::LPDO{MPO}, ref_indices::Vector{<:Index}) =
  measure!(observer, MPO(L), ref_indices)

measure!(observer::Observer, M::Union{MPS,MPO,LPDO}) = 
  measure!(observer, M, hilbertspace(M))


