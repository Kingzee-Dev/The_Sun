module BiologicalLaws

using Statistics
using DataStructures

# Import from parent module
using ..EvolutionaryPatterns: analyze_evolution, detect_patterns
using ..HomeostasisControl: analyze_stability, optimize_control!
using ..SymbioticSystems: calculate_cooperation_level, analyze_symbiotic_relationships

"""
    apply_biological_laws!(observatory, data)
Apply all biological laws to the given data
"""
function apply_biological_laws!(observatory, data::Dict{String, Any})
    result_state = Dict{String, Any}()
    observations = Dict{String, Any}()

    # Apply evolutionary laws
    if haskey(data, "population")
        result_state["evolution"] = Dict(
            "fitness" => analyze_evolution(data["population"]),
            "adaptation" => detect_patterns(data["population"])
        )
    end

    # Apply homeostasis laws 
    if haskey(data, "variables")
        result_state["homeostasis"] = Dict(
            "stability" => analyze_stability(data["variables"]),
            "regulation" => optimize_control!(data["variables"])
        )
    end

    # Apply symbiotic laws with explicit error handling
    if haskey(data, "interactions")
        try
            result_state["symbiosis"] = Dict(
                "cooperation" => calculate_cooperation_level(data["interactions"]),
                "mutual_benefit" => analyze_symbiotic_relationships(data["interactions"])
            )
        catch e
            @warn "Error applying symbiotic laws" exception=e
            result_state["symbiosis"] = Dict(
                "cooperation" => 0.0,
                "mutual_benefit" => 0.0
            )
        end
    end

    return (state=result_state, observations=observations)
end

export apply_biological_laws!

end # module
