#
# product
#

"""
    product(ops::Vector{<:ITensor}, ψ::MPS;
            apply_dag::Bool = false)

Apply the ITensors `ops` to the MPS `ψ`.
"""
function ITensors.product(ops::Vector{<:ITensor},
                          ψ::Union{MPS, MPO};
                          apply_dag::Bool = false,
                          kwargs...)
  ψ0 = ψ
  s0 = siteinds(ψ0)
  for o in ops
    ψ = product(o, ψ; move_sites_back = false,
                      apply_dag = apply_dag,
                      kwargs...)
  end
  s = siteinds(ψ)
  ns = 1:length(ψ)
  ns′ = [findsite(ψ0, i) for i in s]
  # Move the sites back to their original positions
  ψ = movesites(ψ, ns .=> ns′; kwargs...)
  return ψ
end

"""
    product(ops::Vector{<:ITensor}, ψ::ITensor)

Apply the ITensors `ops` to the ITensor `ψ`.
"""
function ITensors.product(ops::Vector{<:ITensor},
                          ψ::ITensor;
                          apply_dag::Bool = false)
  for o in ops
    ψ = product(o, ψ; apply_dag = apply_dag)
  end
  return ψ
end

const apply = product

#"""
#    sitedict(::Vector{<:Index})
#
#Return a dictionary that maps a Vector of indices to
#the integer position of the Index in the Vector.
#"""
#function sitedict(sites::Vector{IndexT}) where {IndexT <: Index}
#  d = Dict{IndexT, Int}()
#  for (n, s) in enumerate(sites)
#    d[s] = n
#  end
#  return d
#end

#"""
#    product(o::ITensor, ψ::MPS)
#
#Apply the ITensor `o` to the MPS `ψ`.
#"""
#ITensors.product(o::ITensor{N}, ψ::Union{MPS, MPO};
#                 kwargs...) where {N} =
#  product(o, ψ, findsites(ψ, o); kwargs...)

#"""
#    product(o::ITensor, ψ::MPS, ns::Tuple;
#            move_sites_back::Bool = true)
#
#Get the product of the operator `o` with the MPS `ψ`,
#where the operator is applied to the sites `ns`.
#
#If `ns` are non-contiguous, the sites of the MPS are
#moved to be contiguous. By default, the sites are moved
#back to their original locations. You can leave them where
#they are by setting the keyword argument `move_sites_back`
#to false.
#"""
#function ITensors.product(o::ITensor,
#                          ψ::Union{MPS, MPO},
#                          ns::Vector{Int};
#                          move_sites_back::Bool = true,
#                          apply_dag::Bool = false,
#                          kwargs...)
#  N = length(ns)
#  ns = sort(ns)
#
#  # TODO: make this smarter by minimizing
#  # distance to orthogonalization.
#  # For example, if ITensors.orthocenter(ψ) > ns[end],
#  # set to ns[end].
#  ψ = orthogonalize(ψ, ns[1])
#  diff_ns = diff(ns)
#  ns′ = ns
#  if any(!=(1), diff_ns)
#    ns′ = [ns[1] + n - 1 for n in 1:N]
#    ψ = movesites(ψ, ns .=> ns′; kwargs...)
#  end
#  ϕ = ψ[ns′[1]]
#  for n in 2:N
#    ϕ *= ψ[ns′[n]]
#  end
#  ϕ = product(o, ϕ; apply_dag = apply_dag)
#  ψ[ns′[1]:ns′[end], kwargs...] = ϕ
#  move_sites_back && error("move_sites_back is not supported yet")
#  return ψ
#end

#"""
#    product(A::ITensor, B::ITensor)
#
#Get the product of ITensor `A` and ITensor `B`.
#
#`A` should have pairs of unprimed and primed indices,
#and `B` should either have pairs of primed or unprimed
#indices that are shared with `A` or just unprimed indices
#shared with `A`.
#
#If `B` has pairs of unprimed and primed indices shared with `A`,
#it is treated as a matrix, and `A` is contracted as a matrix-matrix
#product, with a result that has the same unprimed and primed
#indices as `A` and `B`.
#
#If `B` just has unprimed indices shared with `A`, then
#`A` is contracted as a matrix-vector product, and the
#result is unprimed so that it has the unprimed indices
#that were shared between `A` and `B`.
#
#`A` and `B` can both have unshared indices, which are not
#contracted or effected by the operation. This would correspond
#to batched matrix-matrix or matrix-vector products.
#"""
#function ITensors.product(A::ITensor,
#                          B::ITensor;
#                          apply_dag::Bool = false)
#  commonABis = commoninds(A, B)
#  if all(hasplev(0), commonABis)
#    # B is a state
#    apply_dag && error("Cannot apply to both sides of a state")
#    return noprime(A * B; inds = commonABis')
#  end
#  # B is an operator
#  commonABis = filterinds(commonABis; plev = 0)
#  uniqueAis = uniqueinds(A, B)
#  A′ = prime(A; inds = not(uniqueAis))
#  AB = setprime(A′ * B, 1; inds = commonABis'')
#  if apply_dag
#    uniqueBis = uniqueinds(B, A)
#    AB = prime(AB; inds = not(unioninds(uniqueAis, uniqueBis)))
#    Adag = swapprime(dag(A), 0, 1; inds = not(uniqueAis))
#    AB = setprime(AB * Adag, 1; inds = commonABis'')
#  end
#  return AB
#end

