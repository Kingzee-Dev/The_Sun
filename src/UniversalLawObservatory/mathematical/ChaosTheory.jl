module ChaosTheory

using DifferentialEquations
using Statistics
using LinearAlgebra
using DataStructures

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

"""
    AttractorSystem
System for tracking and analyzing chaotic attractors
"""
mutable struct AttractorSystem
    trajectories::Dict{String, Vector{Vector{Float64}}}
    lyapunov_exponents::Dict{String, CircularBuffer{Float64}}
    bifurcation_points::Dict{String, Vector{Float64}}
    phase_space::Dict{String, Matrix{Float64}}
    stability_metrics::Dict{String, Float64}
    dimension::Int
end

"""
    create_attractor_system(dimension::Int=3)
Initialize a new attractor system with specified dimension
"""
function create_attractor_system(dimension::Int=3)
    AttractorSystem(
        Dict{String, Vector{Vector{Float64}}}(),
        Dict{String, CircularBuffer{Float64}}(),
        Dict{String, Vector{Float64}}(),
        Dict{String, Matrix{Float64}}(),
        Dict{String, Float64}(),
        dimension
    )
end

"""
    track_trajectory!(system::AttractorSystem, id::String, point::Vector{Float64})
Track a point in the system's phase space
"""
function track_trajectory!(system::AttractorSystem, id::String, point::Vector{Float64})
    if length(point) != system.dimension
        return (success=false, reason="Invalid point dimension")
    end
    
    # Initialize trajectory if needed
    if !haskey(system.trajectories, id)
        system.trajectories[id] = Vector{Vector{Float64}}()
        system.lyapunov_exponents[id] = CircularBuffer{Float64}(1000)
        system.phase_space[id] = zeros(0, system.dimension)
    end
    
    # Add point to trajectory
    push!(system.trajectories[id], point)
    
    # Update phase space
    system.phase_space[id] = vcat(
        system.phase_space[id],
        reshape(point, 1, system.dimension)
    )
    
    # Calculate local Lyapunov exponent
    if length(system.trajectories[id]) >= 2
        lyap = calculate_local_lyapunov(
            system.trajectories[id][end-1],
            point
        )
        push!(system.lyapunov_exponents[id], lyap)
    end
    
    return (success=true, point_id=length(system.trajectories[id]))
end

"""
    analyze_attractor(system::AttractorSystem, id::String)
Analyze the attractor properties for a given trajectory
"""
function analyze_attractor(system::AttractorSystem, id::String)
    if !haskey(system.trajectories, id)
        return (success=false, reason="Trajectory not found")
    end
    
    trajectory = system.trajectories[id]
    if length(trajectory) < 3
        return (success=false, reason="Insufficient points")
    end
    
    # Calculate attractor properties
    metrics = Dict{String, Any}()
    
    # Calculate average Lyapunov exponent
    lyap_values = collect(system.lyapunov_exponents[id])
    metrics["lyapunov_exponent"] = mean(lyap_values)
    
    # Estimate attractor dimension
    metrics["correlation_dimension"] = estimate_correlation_dimension(trajectory)
    
    # Calculate trajectory stability
    metrics["stability"] = calculate_trajectory_stability(trajectory)
    
    # Detect periodic behavior
    metrics["periodicity"] = detect_periodicity(trajectory)
    
    # Update system stability metrics
    system.stability_metrics[id] = metrics["stability"]
    
    return (success=true, metrics=metrics)
end

"""
    predict_bifurcations(system::AttractorSystem, id::String, parameter_range::Vector{Float64})
Predict potential bifurcation points in the system
"""
function predict_bifurcations(system::AttractorSystem, id::String, parameter_range::Vector{Float64})
    if !haskey(system.trajectories, id)
        return (success=false, reason="Trajectory not found")
    end
    
    trajectory = system.trajectories[id]
    if length(trajectory) < 100
        return (success=false, reason="Insufficient data")
    end
    
    # Calculate stability changes across parameter range
    bifurcations = Float64[]
    stability_values = Float64[]
    
    for param in parameter_range
        # Calculate stability at parameter value
        stability = calculate_parametric_stability(trajectory, param)
        push!(stability_values, stability)
        
        # Detect sharp changes in stability
        if length(stability_values) >= 2
            if abs(stability_values[end] - stability_values[end-1]) > 0.2
                push!(bifurcations, param)
            end
        end
    end
    
    # Store bifurcation points
    system.bifurcation_points[id] = bifurcations
    
    return (
        success=true,
        bifurcations=bifurcations,
        stability_profile=stability_values
    )
end

"""
    detect_chaos(system::AttractorSystem, id::String)
Detect and characterize chaotic behavior
"""
function detect_chaos(system::AttractorSystem, id::String)
    if !haskey(system.trajectories, id)
        return (success=false, reason="Trajectory not found")
    end
    
    # Get Lyapunov spectrum
    lyap_values = collect(system.lyapunov_exponents[id])
    
    if isempty(lyap_values)
        return (success=false, reason="No Lyapunov exponents available")
    end
    
    # Calculate chaos metrics
    avg_lyap = mean(lyap_values)
    max_lyap = maximum(lyap_values)
    
    # Characterize behavior
    chaos_type = if max_lyap > 0.1
        if avg_lyap > 0
            :strong_chaos
        else
            :weak_chaos
        end
    elseif max_lyap > 0
        :edge_of_chaos
    else
        :stable
    end
    
    # Calculate predictability horizon
    if max_lyap > 0
        prediction_horizon = 1 / max_lyap
    else
        prediction_horizon = Inf
    end
    
    return (
        success=true,
        chaos_type=chaos_type,
        max_lyapunov=max_lyap,
        avg_lyapunov=avg_lyap,
        prediction_horizon=prediction_horizon
    )
end

"""
    optimize_prediction(system::AttractorSystem, id::String)
Optimize prediction parameters based on system behavior
"""
function optimize_prediction(system::AttractorSystem, id::String)
    if !haskey(system.trajectories, id)
        return (success=false, reason="Trajectory not found")
    end
    
    trajectory = system.trajectories[id]
    if length(trajectory) < 100
        return (success=false, reason="Insufficient data")
    end
    
    # Analyze predictability
    chaos_analysis = detect_chaos(system, id)
    if !chaos_analysis.success
        return chaos_analysis
    end
    
    # Calculate optimal embedding parameters
    embedding_dimension = estimate_embedding_dimension(trajectory)
    delay = estimate_time_delay(trajectory)
    
    # Calculate prediction confidence based on chaos characteristics
    if chaos_analysis.chaos_type == :strong_chaos
        confidence = exp(-1 / chaos_analysis.prediction_horizon)
    elseif chaos_analysis.chaos_type == :weak_chaos
        confidence = 0.5 + 0.5 * exp(-1 / chaos_analysis.prediction_horizon)
    else
        confidence = 0.9
    end
    
    return (
        success=true,
        embedding_dimension=embedding_dimension,
        time_delay=delay,
        prediction_confidence=confidence,
        chaos_type=chaos_analysis.chaos_type
    )
end

# Helper functions
function calculate_local_lyapunov(point1::Vector{Float64}, point2::Vector{Float64})
    distance = norm(point2 - point1)
    if distance < 1e-10
        return 0.0
    end
    return log(distance)
end

function estimate_correlation_dimension(trajectory::Vector{Vector{Float64}})
    if length(trajectory) < 2
        return 0.0
    end
    
    # Calculate pairwise distances
    n_points = min(length(trajectory), 1000)  # Limit computation
    distances = [
        norm(trajectory[i] - trajectory[j])
        for i in 1:n_points
        for j in (i+1):n_points
    ]
    
    # Estimate dimension using correlation sum
    r_values = sort(unique(distances))
    correlation_sums = Float64[]
    
    for r in r_values
        c = sum(d <= r for d in distances) / length(distances)
        push!(correlation_sums, c)
    end
    
    # Estimate dimension from log-log slope
    if length(correlation_sums) >= 2
        log_r = log.(r_values)
        log_c = log.(correlation_sums)
        return (log_c[end] - log_c[1]) / (log_r[end] - log_r[1])
    end
    
    return 0.0
end

function calculate_trajectory_stability(trajectory::Vector{Vector{Float64}})
    if length(trajectory) < 3
        return 1.0
    end
    
    # Calculate consecutive differences
    differences = [
        norm(trajectory[i+1] - trajectory[i])
        for i in 1:(length(trajectory)-1)
    ]
    
    # Calculate stability metric (1 = stable, 0 = unstable)
    std_diff = std(differences)
    mean_diff = mean(differences)
    
    return 1.0 / (1.0 + std_diff / mean_diff)
end

function detect_periodicity(trajectory::Vector{Vector{Float64}})
    if length(trajectory) < 4
        return 0.0
    end
    
    # Calculate autocorrelation
    n = length(trajectory)
    max_lag = min(n ÷ 2, 100)
    
    correlations = Float64[]
    for lag in 1:max_lag
        correlation = mean([
            dot(trajectory[i], trajectory[i+lag]) / 
            (norm(trajectory[i]) * norm(trajectory[i+lag]))
            for i in 1:(n-lag)
        ])
        push!(correlations, correlation)
    end
    
    # Find strongest periodic component
    if !isempty(correlations)
        return maximum(correlations)
    end
    
    return 0.0
end

function calculate_parametric_stability(trajectory::Vector{Vector{Float64}}, parameter::Float64)
    if length(trajectory) < 2
        return 0.0
    end
    
    # Calculate stability metric based on parameter value
    differences = [
        norm(trajectory[i+1] - trajectory[i])
        for i in 1:(length(trajectory)-1)
    ]
    
    # Modulate differences by parameter
    modulated_diff = differences .* exp(-parameter)
    return 1.0 / (1.0 + std(modulated_diff))
end

function estimate_embedding_dimension(trajectory::Vector{Vector{Float64}})
    # Use false nearest neighbors method
    max_dim = min(10, length(first(trajectory)))
    
    # Start with dimension that preserves 95% of variance
    if length(trajectory) >= 2
        points_matrix = reduce(hcat, trajectory)
        svd_values = svd(points_matrix).S
        var_explained = cumsum(svd_values) / sum(svd_values)
        dim = findfirst(>=(0.95), var_explained)
        return isnothing(dim) ? max_dim : min(dim, max_dim)
    end
    
    return 2  # Default minimal dimension
end

function estimate_time_delay(trajectory::Vector{Vector{Float64}})
    if length(trajectory) < 4
        return 1
    end
    
    # Use first minimum of mutual information
    # Simplified using autocorrelation
    n = length(trajectory)
    max_delay = min(n ÷ 4, 50)
    
    correlations = [
        mean([
            dot(trajectory[i], trajectory[i+delay]) / 
            (norm(trajectory[i]) * norm(trajectory[i+delay]))
            for i in 1:(n-delay)
        ])
        for delay in 1:max_delay
    ]
    
    # Find first local minimum
    for i in 2:(length(correlations)-1)
        if correlations[i] < correlations[i-1] && 
           correlations[i] < correlations[i+1]
            return i
        end
    end
    
    return 1  # Default delay
end

export DynamicalSystem, SystemTrajectory, calculate_trajectory,
       predict_horizon, analyze_stability,
       AttractorSystem, create_attractor_system,
       track_trajectory!, analyze_attractor,
       predict_bifurcations, detect_chaos,
       optimize_prediction

end # module