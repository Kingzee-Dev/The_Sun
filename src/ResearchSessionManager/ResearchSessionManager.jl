module ResearchSessionManager

using Statistics
using DataStructures
using HTTP
using JSON3

"""
    ResearchSession
Base research session type
"""
mutable struct ResearchSession
    observations::Dict{String, Vector{Dict{String, Any}}}
    metrics::Dict{String, Vector{Float64}}
    session_start::Float64
    session_duration::Float64
end

function create_research_session()
    ResearchSession(
        Dict{String, Vector{Dict{String, Any}}}(),
        Dict{String, Vector{Float64}}(),
        time(),
        3600.0
    )
end

function record_observation!(session::ResearchSession, domain::String, observation::Dict{String, Any})
    if !haskey(session.observations, domain)
        session.observations[domain] = Vector{Dict{String, Any}}()
    end
    push!(session.observations[domain], observation)
    
    # Update metrics
    numeric_values = Float64[]
    for (_, value) in observation
        if isa(value, Number)
            push!(numeric_values, Float64(value))
        end
    end
    
    if !isempty(numeric_values)
        if !haskey(session.metrics, domain)
            session.metrics[domain] = Float64[]
        end
        push!(session.metrics[domain], mean(numeric_values))
    end
end

export ResearchSession, create_research_session, record_observation!

end # module
