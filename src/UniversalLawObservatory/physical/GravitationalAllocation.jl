module GravitationalAllocation

using LinearAlgebra
using Graphs

"""
    ResourcePoint
Represents a point in the resource space
"""
struct ResourcePoint
    position::Vector{Float64}
    mass::Float64
    capacity::Float64
end

"""
    GravitationalField
Represents the gravitational field for resource allocation
"""
mutable struct GravitationalField
    points::Vector{ResourcePoint}
    connections::SimpleGraph{Int}
    field_strength::Float64
    equilibrium_threshold::Float64
end

"""
    create_gravitational_field()
Initialize a new gravitational field
"""
function create_gravitational_field()
    GravitationalField(
        ResourcePoint[],
        SimpleGraph(0),
        1.0,
        0.01
    )
end

"""
    add_resource_point!(field::GravitationalField, position::Vector{Float64}, mass::Float64, capacity::Float64)
Add a new resource point to the field
"""
function add_resource_point!(field::GravitationalField, position::Vector{Float64}, mass::Float64, capacity::Float64)
    point = ResourcePoint(position, mass, capacity)
    push!(field.points, point)
    
    # Update connection graph
    n_points = length(field.points)
    new_graph = SimpleGraph(n_points)
    
    if n_points > 1
        # Copy existing connections
        for e in edges(field.connections)
            add_edge!(new_graph, src(e), dst(e))
        end
        
        # Connect new point to others based on distance
        for i in 1:(n_points-1)
            if calculate_gravitational_force(point, field.points[i]) > field.equilibrium_threshold
                add_edge!(new_graph, i, n_points)
            end
        end
    end
    
    field.connections = new_graph
    return point
end

"""
    allocate_resources!(field::GravitationalField, resources::Float64)
Allocate resources using gravitational principles
"""
function allocate_resources!(field::GravitationalField, resources::Float64)
    n_points = length(field.points)
    if n_points == 0
        return Dict{Int, Float64}()
    end
    
    # Calculate gravitational forces between points
    forces = zeros(n_points)
    for i in 1:n_points
        for j in 1:n_points
            if i != j
                forces[i] += calculate_gravitational_force(
                    field.points[i],
                    field.points[j]
                )
            end
        end
    end
    
    # Normalize forces to represent allocation proportions
    total_force = sum(forces)
    if total_force > 0
        proportions = forces ./ total_force
    else
        # Equal distribution if no forces
        proportions = fill(1.0 / n_points, n_points)
    end
    
    # Allocate resources based on proportions and capacities
    allocations = Dict{Int, Float64}()
    remaining = resources
    
    for i in 1:n_points
        # Allocate based on proportion but respect capacity
        allocation = min(
            proportions[i] * resources,
            field.points[i].capacity,
            remaining
        )
        allocations[i] = allocation
        remaining -= allocation
    end
    
    # Distribute any remaining resources
    if remaining > 0
        # Find points under capacity
        available = findall(i -> allocations[i] < field.points[i].capacity, 1:n_points)
        
        while remaining > 0 && !isempty(available)
            extra = remaining / length(available)
            for i in available
                space = field.points[i].capacity - allocations[i]
                added = min(extra, space)
                allocations[i] += added
                remaining -= added
            end
            available = findall(i -> allocations[i] < field.points[i].capacity, 1:n_points)
        end
    end
    
    return allocations
end

"""
    optimize_field!(field::GravitationalField)
Optimize the gravitational field for better resource allocation
"""
function optimize_field!(field::GravitationalField)
    n_points = length(field.points)
    if n_points < 2
        return (success=false, reason="Not enough points")
    end
    
    # Analyze current distribution
    allocations = allocate_resources!(field, sum(p.capacity for p in field.points))
    
    # Calculate distribution metrics
    utilization = mean(alloc / field.points[i].capacity for (i, alloc) in allocations)
    balance = 1.0 - std(values(allocations)) / mean(values(allocations))
    
    # Adjust field strength based on metrics
    if utilization < 0.8
        field.field_strength *= 1.1  # Increase attraction
    elseif balance < 0.7
        field.field_strength *= 0.9  # Decrease attraction for better balance
    end
    
    # Adjust equilibrium threshold
    field.equilibrium_threshold = max(0.001, field.equilibrium_threshold * (balance > 0.9 ? 1.1 : 0.9))
    
    return (
        success=true,
        metrics=Dict(
            "utilization" => utilization,
            "balance" => balance,
            "field_strength" => field.field_strength,
            "threshold" => field.equilibrium_threshold
        )
    )
end

"""
    calculate_field_stability(field::GravitationalField)
Calculate the stability of the current field configuration
"""
function calculate_field_stability(field::GravitationalField)
    n_points = length(field.points)
    if n_points < 2
        return 1.0
    end
    
    # Calculate average force balance
    force_balances = Float64[]
    
    for i in 1:n_points
        # Sum of forces on point i
        net_force = zeros(length(field.points[1].position))
        
        for j in 1:n_points
            if i != j
                force = calculate_gravitational_vector(
                    field.points[i],
                    field.points[j]
                )
                net_force .+= force
            end
        end
        
        # Calculate force balance (0 = perfect balance)
        push!(force_balances, norm(net_force))
    end
    
    # Convert to stability metric (1 = perfect stability)
    avg_imbalance = mean(force_balances)
    return 1.0 / (1.0 + avg_imbalance)
end

# Helper functions
function calculate_gravitational_force(p1::ResourcePoint, p2::ResourcePoint)
    distance = norm(p1.position - p2.position)
    if distance < 1e-10
        return 0.0
    end
    return (p1.mass * p2.mass) / (distance * distance)
end

function calculate_gravitational_vector(p1::ResourcePoint, p2::ResourcePoint)
    direction = p2.position - p1.position
    distance = norm(direction)
    if distance < 1e-10
        return zeros(length(p1.position))
    end
    unit_direction = direction / distance
    force_magnitude = (p1.mass * p2.mass) / (distance * distance)
    return force_magnitude * unit_direction
end

export GravitationalField, create_gravitational_field,
       add_resource_point!, allocate_resources!,
       optimize_field!, calculate_field_stability

end # module