module ChaosTheory

using DifferentialEquations
using Statistics
using LinearAlgebra

"""
    DynamicalSystem
Represents a dynamical system with chaotic properties
"""
struct DynamicalSystem
    dimension::Int
    parameters::Vector{Float64}
    initial_state::Vector{Float64}
    time_span::Tuple{Float64, Float64}
end

"""
    SystemTrajectory
Stores the trajectory of a dynamical system
"""
struct SystemTrajectory
    times::Vector{Float64}
    states::Vector{Vector{Float64}}
    lyapunov_exponents::Vector{Float64}
end

"""
    lorenz_system!(du, u, p, t)
Implements the Lorenz system equations
"""
function lorenz_system!(du, u, p, t)
    σ, ρ, β = p
    du[1] = σ * (u[2] - u[1])
    du[2] = u[1] * (ρ - u[3]) - u[2]
    du[3] = u[1] * u[2] - β * u[3]
end

"""
    calculate_trajectory(system::DynamicalSystem)
Calculate the trajectory of a dynamical system
"""
function calculate_trajectory(system::DynamicalSystem)
    prob = ODEProblem(lorenz_system!, system.initial_state, system.time_span, system.parameters)
    sol = solve(prob, Tsit5())
    
    times = sol.t
    states = [[s[i] for i in 1:system.dimension] for s in sol.u]
    
    # Calculate Lyapunov exponents
    lyap = calculate_lyapunov_exponents(states)
    
    SystemTrajectory(times, states, lyap)
end

"""
    calculate_lyapunov_exponents(states::Vector{Vector{Float64}})
Calculate the Lyapunov exponents of a trajectory
"""
function calculate_lyapunov_exponents(states::Vector{Vector{Float64}})
    n = length(states[1])
    m = min(length(states), 1000)  # Use at most 1000 points
    
    # Calculate divergence rates
    rates = zeros(n)
    for i in 1:n
        for j in 1:m-1
            δ = abs(states[j+1][i] - states[j][i])
            if δ > 0
                rates[i] += log(δ)
            end
        end
        rates[i] /= m
    end
    
    sort!(rates, rev=true)
    return rates
end

"""
    predict_horizon(trajectory::SystemTrajectory)
Calculate the predictability horizon of the system
"""
function predict_horizon(trajectory::SystemTrajectory)
    if isempty(trajectory.lyapunov_exponents)
        return Inf
    end
    
    # Use the largest positive Lyapunov exponent
    λ = maximum(trajectory.lyapunov_exponents)
    if λ <= 0
        return Inf  # System is not chaotic
    end
    
    # Estimate time until predictability is lost
    initial_uncertainty = 1e-10  # Initial measurement uncertainty
    final_uncertainty = 1.0     # Maximum acceptable uncertainty
    
    horizon = (1/λ) * log(final_uncertainty/initial_uncertainty)
    return horizon
end

"""
    analyze_stability(trajectory::SystemTrajectory)
Analyze the stability characteristics of the system
"""
function analyze_stability(trajectory::SystemTrajectory)
    if isempty(trajectory.states)
        return (stable=false, chaotic=false, dimension=0.0)
    end
    
    # Calculate correlation dimension
    dimension = estimate_correlation_dimension(trajectory.states)
    
    # Determine stability characteristics
    max_lyap = maximum(trajectory.lyapunov_exponents)
    stable = max_lyap < 0
    chaotic = max_lyap > 0
    
    return (
        stable=stable,
        chaotic=chaotic,
        dimension=dimension,
        lyapunov_spectrum=copy(trajectory.lyapunov_exponents)
    )
end

"""
    estimate_correlation_dimension(states::Vector{Vector{Float64}})
Estimate the correlation dimension of the attractor
"""
function estimate_correlation_dimension(states::Vector{Vector{Float64}})
    n = length(states)
    if n < 100
        return 0.0
    end
    
    # Sample pairs of points
    samples = min(1000, n)
    distances = Float64[]
    
    for i in 1:samples
        for j in (i+1):samples
            push!(distances, norm(states[i] - states[j]))
        end
    end
    
    # Estimate dimension using correlation sum scaling
    r_values = exp10.(range(-2, 0, length=20))
    correlations = Float64[]
    
    for r in r_values
        c = count(d -> d < r, distances) / (samples * (samples - 1) / 2)
        push!(correlations, c)
    end
    
    # Estimate dimension from log-log slope
    valid_points = correlations .> 0
    if sum(valid_points) < 2
        return 0.0
    end
    
    x = log.(r_values[valid_points])
    y = log.(correlations[valid_points])
    
    # Linear regression to find slope
    A = [ones(length(x)) x]
    slope = (A \ y)[2]
    
    return slope
end

export DynamicalSystem, SystemTrajectory, calculate_trajectory,
       predict_horizon, analyze_stability

end # module