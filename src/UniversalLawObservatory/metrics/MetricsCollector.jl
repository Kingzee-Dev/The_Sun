module MetricsCollector

using Statistics
using DataStructures

"""
    MetricsCollection
Collects and manages system-wide metrics
"""
mutable struct MetricsCollection
    observations::Dict{String, CircularBuffer{Float64}}
    thresholds::Dict{String, Float64}
    last_update::Float64
end

"""
    create_metrics_collector(buffer_size::Int=1000)
Initialize a new metrics collector
"""
function create_metrics_collector(buffer_size::Int=1000)
    MetricsCollection(
        Dict{String, CircularBuffer{Float64}}(),
        Dict{String, Float64}(),
        time()
    )
end

"""
    record_metric!(collector::MetricsCollection, name::String, value::Float64)
Record a new metric value
"""
function record_metric!(collector::MetricsCollection, name::String, value::Float64)
    if !haskey(collector.observations, name)
        collector.observations[name] = CircularBuffer{Float64}(1000)
    end
    push!(collector.observations[name], value)
    collector.last_update = time()
end

"""
    get_metrics_summary(collector::MetricsCollection)
Generate summary statistics for all metrics
"""
function get_metrics_summary(collector::MetricsCollection)
    summary = Dict{String, Dict{String, Float64}}()
    
    for (name, values) in collector.observations
        if !isempty(values)
            summary[name] = Dict(
                "mean" => mean(values),
                "std" => std(values),
                "min" => minimum(values),
                "max" => maximum(values),
                "last" => last(values)
            )
        end
    end
    
    return summary
end

export MetricsCollection, create_metrics_collector,
       record_metric!, get_metrics_summary

end # module
