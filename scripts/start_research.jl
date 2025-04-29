using Pkg

# Activate and resolve project environment
Pkg.activate(dirname(dirname(@__FILE__)))

# Add required packages if not already present
Pkg.add(["JSON3", "DataFrames", "CSV"])

# Directly include the main module
include(joinpath(dirname(dirname(@__FILE__)), "src", "UniversalCelestialIntelligence.jl"))
using .UniversalCelestialIntelligence

# Create research session
try
    println("🔬 Starting Scientific Research Session...")
    
    # Create and initialize system
    system = create_celestial_system()
    init_result = initialize!(system)
    
    if !init_result[:success]
        error("System initialization failed: $(init_result[:error])")
    end
    
    # Run research cycle
    run_research_sessions!(system)
    
catch e 
    println("\n❌ Error during research session:")
    println(e)
    return 1
end

return 0
