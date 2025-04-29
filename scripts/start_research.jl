using Pkg

# Activate project
Pkg.activate(dirname(dirname(@__FILE__)))

# Include main module
include(joinpath(dirname(dirname(@__FILE__)), "src", "UniversalCelestialIntelligence.jl"))
using .UniversalCelestialIntelligence

# Run research session
try
    println("🔬 Starting Scientific Research Session...")
    
    # Create and initialize system
    system = create_celestial_system()
    init_result = initialize!(system)
    
    if !init_result[:success]
        error("System initialization failed: $(init_result[:error])")
    end
    
    # Run research session
    result = run_research_sessions!(system)
    if !result.success
        error("Research session failed: $(result.error)")
    end
    
catch e 
    println("\n❌ Error during research session:")
    println(e)
    exit(1)
end

exit(0)
