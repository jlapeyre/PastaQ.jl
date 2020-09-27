using PastaQ
using Random
using ITensors

Random.seed!(1234)
N = 10  # Number of spins
B = 1.0 # Transverse magnetic field

# Build Ising Hamiltonian
sites = siteinds("S=1/2",N)
ampo = AutoMPO()
for j in 1:N-1
  # Ising ZZ interactions
  ampo .+= (-2.0,"Sz",j,"Sz",j+1)
end
for j in 1:N
  # Transverse field X
  ampo .+= (-B,"Sx",j)
end
H = MPO(ampo,sites)

# Run DMRG
dmrg_iter   = 20      # DMRG steps
dmrg_cutoff = 1E-10   # Cutoff
Ψ0 = randomMPS(sites) # Initial state
sweeps = Sweeps(dmrg_iter)
maxdim!(sweeps, 10,20,30,40,50,100)
cutoff!(sweeps, dmrg_cutoff)
# Run DMRG
E , Ψ = dmrg(H,Ψ0,sweeps)

# Generate data
nshots = 10000
bases = randombases(N,nshots)
data = generatedata(Ψ,bases)

# Quantum state tomography
# Initialize variational state
χ = maxlinkdim(Ψ)
ψ0 = randomstate(N;χ=χ)
# Optimizer
opt = SGD(η = 0.01)
# Run tomography
ψ = tomography(ψ0,data,opt;
               batchsize=500,
               epochs=20,
               target=Ψ)
@show ψ
