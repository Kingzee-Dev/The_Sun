using UniversalCelestialIntelligence

function test_precompilation()
    # Create a simple test system
    system = create_celestial_system()
    
    # Verify system initialization
    @assert system !== nothing "System creation failed"
    
    # Test basic functionality
    initialize!(system)
    
    println("✅ Precompilation verification passed")
    return true
end

if abspath(PROGRAM_FILE) == @__FILE__
    test_precompilation()
end
