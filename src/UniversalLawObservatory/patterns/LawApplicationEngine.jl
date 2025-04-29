module LawApplicationEngine

using Graphs
using Statistics
using DataStructures

"""
    LawEngine
Engine for applying and managing universal laws
"""
mutable struct LawEngine
    active_laws::Dict{String, Function}
    law_dependencies::SimpleGraph{Int}
    law_indices::Dict{String, Int}
    reverse_indices::Dict{Int, String}
    law_metrics::Dict{String, CircularBuffer{Float64}}
    conflict_resolution::Dict{Tuple{String, String}, Function}
    application_history::CircularBuffer{Dict{String, Any}}
end

"""
    create_law_engine()
Initialize a new law application engine
"""
function create_law_engine()
    LawEngine(
        Dict{String, Function}(),
        SimpleGraph(0),
        Dict{String, Int}(),
        Dict{Int, String}(),
        Dict{String, CircularBuffer{Float64}}(),
        Dict{Tuple{String, String}, Function}(),
        CircularBuffer{Dict{String, Any}}(1000)
    )
end

"""
    register_law!(engine::LawEngine, law_id::String, law_fn::Function, dependencies::Vector{String}=String[])
Register a new law with the engine
"""
function register_law!(engine::LawEngine, law_id::String, law_fn::Function, dependencies::Vector{String}=String[])
    # Add law to active laws
    engine.active_laws[law_id] = law_fn
    engine.law_metrics[law_id] = CircularBuffer{Float64}(1000)
    
    # Add vertex to dependency graph
    new_index = length(engine.law_indices) + 1
    engine.law_indices[law_id] = new_index
    engine.reverse_indices[new_index] = law_id
    add_vertex!(engine.law_dependencies)
    
    # Add dependency edges
    for dep in dependencies
        if haskey(engine.law_indices, dep)
            add_edge!(engine.law_dependencies, engine.law_indices[dep], new_index)
        end
    end
    
    return (success=true, index=new_index)
end

"""
    apply_law!(engine::LawEngine, law_id::String, context::Dict{String, Any})
Apply a specific law to a context
"""
function apply_law!(engine::LawEngine, law_id::String, context::Dict{String, Any})
    if !haskey(engine.active_laws, law_id)
        return (success=false, reason="Law not found")
    end
    
    # Get law function
    law_fn = engine.active_laws[law_id]
    
    # Apply law and measure performance
    start_time = time()
    try
        result = law_fn(context)
        end_time = time()
        
        # Record performance metric
        performance = calculate_law_performance(result, end_time - start_time)
        push!(engine.law_metrics[law_id], performance)
        
        # Record application
        push!(engine.application_history, Dict(
            "law" => law_id,
            "timestamp" => start_time,
            "performance" => performance,
            "context" => context
        ))
        
        return (success=true, result=result, performance=performance)
    catch e
        return (success=false, reason="Law application failed: $e")
    end
end

"""
    apply_laws!(engine::LawEngine, context::Dict{String, Any})
Apply all relevant laws to a context in dependency order
"""
function apply_laws!(engine::LawEngine, context::Dict{String, Any})
    results = Dict{String, Any}()
    performances = Dict{String, Float64}()
    
    # Get topological sorting of laws based on dependencies
    try
        ordered_indices = topological_sort_by_dfs(engine.law_dependencies)
        ordered_laws = [engine.reverse_indices[i] for i in ordered_indices]
        
        # Apply laws in order
        current_context = copy(context)
        for law_id in ordered_laws
            result = apply_law!(engine, law_id, current_context)
            
            if result.success
                # Update context with law's results
                merge!(current_context, result.result)
                results[law_id] = result.result
                performances[law_id] = result.performance
            end
        end
        
        return (
            success=true,
            final_state=current_context,
            individual_results=results,
            performances=performances
        )
    catch e
        return (success=false, reason="Law application sequence failed: $e")
    end
end

"""
    resolve_conflicts(engine::LawEngine, conflicts::Vector{Tuple{String, String}}, context::Dict{String, Any})
Resolve conflicts between multiple law applications
"""
function resolve_conflicts(engine::LawEngine, conflicts::Vector{Tuple{String, String}}, context::Dict{String, Any})
    resolutions = Dict{Tuple{String, String}, Any}()
    
    for (law1, law2) in conflicts
        # Check if we have a specific resolution function
        resolution_key = (law1, law2)
        if haskey(engine.conflict_resolution, resolution_key)
            resolver = engine.conflict_resolution[resolution_key]
            try
                resolution = resolver(
                    engine.active_laws[law1],
                    engine.active_laws[law2],
                    context
                )
                resolutions[resolution_key] = resolution
            catch e
                resolutions[resolution_key] = Dict(
                    "status" => "failed",
                    "reason" => "Resolution failed: $e"
                )
            end
        else
            # Default resolution: average numerical values, keep most recent others
            result1 = apply_law!(engine, law1, context)
            result2 = apply_law!(engine, law2, context)
            
            if result1.success && result2.success
                resolution = merge(
                    result1.result,
                    result2.result
                ) do v1, v2
                    if isa(v1, Number) && isa(v2, Number)
                        return (v1 + v2) / 2
                    else
                        return v2  # Keep most recent
                    end
                end
                resolutions[resolution_key] = resolution
            end
        end
    end
    
    return resolutions
end

"""
    update_interaction_graph!(engine::LawEngine)
Update the interaction graph for laws based on application history
"""
function update_interaction_graph!(engine::LawEngine)
    # Create new graph for current interactions
    n_laws = length(engine.law_indices)
    new_graph = SimpleGraph(n_laws)
    
    # Analyze recent applications
    recent_apps = collect(Iterators.take(engine.application_history, 100))
    
    # Track which laws are commonly applied together
    cooccurrence = Dict{Tuple{String, String}, Int}()
    
    for i in 1:length(recent_apps)
        for j in (i+1):length(recent_apps)
            app1 = recent_apps[i]
            app2 = recent_apps[j]
            
            # If applications are close in time
            if abs(app1["timestamp"] - app2["timestamp"]) < 1.0
                law_pair = (app1["law"], app2["law"])
                cooccurrence[law_pair] = get(cooccurrence, law_pair, 0) + 1
            end
        end
    end
    
    # Add edges for strong interactions
    for ((law1, law2), count) in cooccurrence
        if count >= 5  # Threshold for significant interaction
            if haskey(engine.law_indices, law1) && haskey(engine.law_indices, law2)
                add_edge!(
                    new_graph,
                    engine.law_indices[law1],
                    engine.law_indices[law2]
                )
            end
        end
    end
    
    # Update the dependency graph
    engine.law_dependencies = new_graph
    
    return (success=true, interactions=length(edges(new_graph)))
end

"""
    get_law_performance(engine::LawEngine, law_id::String)
Get performance metrics for a law
"""
function get_law_performance(engine::LawEngine, law_id::String)
    if !haskey(engine.law_metrics, law_id)
        return (success=false, reason="Law not found")
    end
    
    metrics = engine.law_metrics[law_id]
    if isempty(metrics)
        return (success=true, metrics=Dict{String, Float64}())
    end
    
    recent_metrics = collect(Iterators.take(metrics, 100))
    
    return (
        success=true,
        metrics=Dict(
            "mean_performance" => mean(recent_metrics),
            "std_performance" => std(recent_metrics),
            "min_performance" => minimum(recent_metrics),
            "max_performance" => maximum(recent_metrics),
            "trend" => length(recent_metrics) >= 2 ? 
                      (last(recent_metrics) - first(recent_metrics)) / length(recent_metrics) :
                      0.0
        )
    )
end

# Helper functions
function calculate_law_performance(result::Dict{String, Any}, execution_time::Float64)
    # Combine execution time, result quality, and impact metrics
    time_score = 1.0 / (1.0 + execution_time)
    
    # Calculate result quality (presence of expected fields)
    expected_fields = ["state", "impact", "confidence"]
    quality_score = sum(haskey(result, field) for field in expected_fields) / length(expected_fields)
    
    # Calculate impact score
    impact_score = get(result, "impact", 0.0)
    
    # Weighted combination
    return 0.3 * time_score + 0.3 * quality_score + 0.4 * impact_score
end

export LawEngine, create_law_engine, register_law!, apply_law!,
       apply_laws!, resolve_conflicts, update_interaction_graph!,
       get_law_performance

end # module