module ModelRegistry

using Statistics
using DataStructures
using Graphs
using StatsBase

"""
    Capability
Represents a system capability
"""
struct Capability
    name::String
    version::String
    dependencies::Set{String}
    requirements::Dict{String, Any}
    performance_metrics::Dict{String, Float64}
end

"""
    Model
Represents a registered model
"""
mutable struct Model
    id::String
    name::String
    version::String
    capabilities::Vector{Capability}
    state::Symbol  # :active, :inactive, :deprecated
    performance_history::CircularBuffer{Dict{String, Float64}}
    dependencies::Dict{String, String}  # model_id => version
    metadata::Dict{String, Any}
end

"""
    Registry
Main registry for managing models and capabilities
"""
mutable struct Registry
    models::Dict{String, Model}
    capabilities::Dict{String, Capability}
    dependency_graph::SimpleDiGraph
    version_history::Dict{String, Vector{String}}
    performance_thresholds::Dict{String, Float64}
end

"""
    create_registry()
Create a new model registry
"""
function create_registry()
    Registry(
        Dict{String, Model}(),
        Dict{String, Capability}(),
        SimpleDiGraph(0),
        Dict{String, Vector{String}}(),
        Dict{String, Float64}()
    )
end

"""
    register_model!(registry::Registry, model::Model)
Register a new model in the registry
"""
function register_model!(registry::Registry, model::Model)
    if haskey(registry.models, model.id)
        return (success=false, reason="Model ID already exists")
    end
    
    # Validate dependencies
    for (dep_id, dep_version) in model.dependencies
        if !haskey(registry.models, dep_id)
            return (success=false, reason="Dependency not found: $dep_id")
        end
        if !in(dep_version, registry.version_history[dep_id])
            return (success=false, reason="Invalid dependency version: $dep_id@$dep_version")
        end
    end
    
    # Add model
    registry.models[model.id] = model
    
    # Update version history
    if !haskey(registry.version_history, model.id)
        registry.version_history[model.id] = String[]
    end
    push!(registry.version_history[model.id], model.version)
    
    # Update dependency graph
    add_vertex!(registry.dependency_graph)
    for dep_id in keys(model.dependencies)
        dep_idx = findfirst(id -> id == dep_id, collect(keys(registry.models)))
        if dep_idx !== nothing
            model_idx = length(vertices(registry.dependency_graph))
            add_edge!(registry.dependency_graph, model_idx, dep_idx)
        end
    end
    
    return (success=true, model_id=model.id)
end

"""
    register_capability!(registry::Registry, capability::Capability)
Register a new capability in the registry
"""
function register_capability!(registry::Registry, capability::Capability)
    if haskey(registry.capabilities, capability.name)
        return (success=false, reason="Capability already exists")
    end
    
    registry.capabilities[capability.name] = capability
    registry.performance_thresholds[capability.name] = 0.8  # Default threshold
    
    return (success=true, name=capability.name)
end

"""
    validate_model(registry::Registry, model::Model)
Validate a model's capabilities and dependencies
"""
function validate_model(registry::Registry, model::Model)
    validation_results = Dict{String, Bool}()
    
    # Validate capabilities
    for capability in model.capabilities
        threshold = get(registry.performance_thresholds, capability.name, 0.8)
        performance = get(capability.performance_metrics, "accuracy", 0.0)
        validation_results["capability_$(capability.name)"] = performance >= threshold
    end
    
    # Validate dependencies
    for (dep_id, dep_version) in model.dependencies
        if haskey(registry.models, dep_id)
            dep_model = registry.models[dep_id]
            validation_results["dependency_$dep_id"] = dep_model.state == :active
        else
            validation_results["dependency_$dep_id"] = false
        end
    end
    
    return validation_results
end

"""
    update_model!(registry::Registry, model_id::String, updates::Dict{String, Any})
Update an existing model in the registry
"""
function update_model!(registry::Registry, model_id::String, updates::Dict{String, Any})
    if !haskey(registry.models, model_id)
        return (success=false, reason="Model not found")
    end
    
    model = registry.models[model_id]
    
    # Apply updates
    if haskey(updates, "version")
        # Create new version
        model.version = updates["version"]
        push!(registry.version_history[model_id], updates["version"])
    end
    
    if haskey(updates, "capabilities")
        # Update capabilities
        model.capabilities = updates["capabilities"]
    end
    
    if haskey(updates, "state")
        # Update state
        model.state = Symbol(updates["state"])
    end
    
    if haskey(updates, "performance")
        # Add performance metrics to history
        push!(model.performance_history, updates["performance"])
    end
    
    # Validate model after updates
    validation_results = validate_model(registry, model)
    
    # Update model state based on validation
    if all(values(validation_results))
        model.state = :active
    elseif any(values(validation_results))
        model.state = :inactive
    else
        model.state = :deprecated
    end
    
    return (success=true, validation=validation_results)
end

"""
    query_models(registry::Registry, criteria::Dict{String, Any})
Query models based on specific criteria
"""
function query_models(registry::Registry, criteria::Dict{String, Any})
    matching_models = Model[]
    
    for model in values(registry.models)
        matches = true
        
        # Check each criterion
        for (key, value) in criteria
            if key == "capability"
                # Check if model has specific capability
                if !any(c.name == value for c in model.capabilities)
                    matches = false
                    break
                end
            elseif key == "min_performance"
                # Check if model meets minimum performance
                avg_performance = mean(
                    mean(values(hist)) for hist in model.performance_history
                )
                if avg_performance < value
                    matches = false
                    break
                end
            elseif key == "state"
                if model.state != Symbol(value)
                    matches = false
                    break
                end
            end
        end
        
        if matches
            push!(matching_models, model)
        end
    end
    
    return matching_models
end

"""
    analyze_dependencies(registry::Registry, model_id::String)
Analyze dependencies for a specific model
"""
function analyze_dependencies(registry::Registry, model_id::String)
    if !haskey(registry.models, model_id)
        return (success=false, reason="Model not found")
    end
    
    model = registry.models[model_id]
    
    # Find all dependencies recursively
    dependency_chain = Dict{String, Vector{String}}()
    visited = Set{String}()
    
    function traverse_dependencies(current_id)
        if current_id in visited
            return
        end
        push!(visited, current_id)
        
        if haskey(registry.models, current_id)
            current_model = registry.models[current_id]
            dependency_chain[current_id] = collect(keys(current_model.dependencies))
            
            for dep_id in keys(current_model.dependencies)
                traverse_dependencies(dep_id)
            end
        end
    end
    
    traverse_dependencies(model_id)
    
    # Check for circular dependencies
    circular_deps = find_circles(registry.dependency_graph)
    
    return (
        dependencies=dependency_chain,
        circular_dependencies=!isempty(circular_deps),
        total_deps=length(dependency_chain)
    )
end

"""
    optimize_registry!(registry::Registry)
Optimize the registry by cleaning up deprecated models and updating dependencies
"""
function optimize_registry!(registry::Registry)
    changes = Dict{String, Any}()
    
    # Find and handle deprecated models
    deprecated_models = [
        id for (id, model) in registry.models
        if model.state == :deprecated
    ]
    
    for model_id in deprecated_models
        # Find dependent models
        dependents = [
            id for (id, model) in registry.models
            if haskey(model.dependencies, model_id)
        ]
        
        if isempty(dependents)
            # Safe to remove
            delete!(registry.models, model_id)
            changes[model_id] = "removed"
        else
            # Mark for update
            changes[model_id] = "needs_update"
        end
    end
    
    # Update performance thresholds based on current model performance
    for (name, capability) in registry.capabilities
        performances = Float64[]
        for model in values(registry.models)
            if any(c.name == name for c in model.capabilities)
                # Get average performance for this capability
                for hist in model.performance_history
                    if haskey(hist, name)
                        push!(performances, hist[name])
                    end
                end
            end
        end
        
        if !isempty(performances)
            # Set threshold to 75th percentile of observed performance
            registry.performance_thresholds[name] = percentile(performances, 75)
        end
    end
    
    return changes
end

export Registry, Model, Capability, create_registry,
       register_model!, register_capability!, validate_model,
       update_model!, query_models, analyze_dependencies,
       optimize_registry!

end # module