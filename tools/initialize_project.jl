using Pkg

"""
Initialize the project with proper dependencies in order
"""
function initialize_project()
    println("🌟 Initializing Universal Celestial Intelligence project...")
    
    # Start fresh
    Pkg.activate(dirname(dirname(@__FILE__)))
    
    println("🔄 Updating package registry...")
    Pkg.Registry.update()
    
    println("📦 Generating new Project.toml...")
    # Recreate Project.toml with basic info
    open(joinpath(dirname(dirname(@__FILE__)), "Project.toml"), "w") do io
        write(io, """
        name = "UniversalCelestialIntelligence"
        uuid = "12345678-1234-5678-1234-567812345678"
        version = "0.1.0"

        [deps]

        [compat]
        julia = "1.6"
        """)
    end
    
    # First add the foundation packages
    println("\n📦 Adding foundation packages...")
    foundation_packages = [
        "DataStructures",
        "JSON3",
        "HTTP"
    ]
    
    for pkg in foundation_packages
        try
            println("Adding $pkg...")
            Pkg.add(pkg)
            Pkg.resolve()
        catch e
            @warn "Failed to add $pkg" exception=e
        end
    end

    # Add data processing packages
    println("\n📦 Adding data processing packages...")
    data_packages = [
        "CSV",
        "DataFrames",
        "StatsBase",
    ]
    
    for pkg in data_packages
        try
            println("Adding $pkg...")
            Pkg.add(pkg)
            Pkg.resolve()
        catch e
            @warn "Failed to add $pkg" exception=e
        end
    end

    # Add scientific computing packages
    println("\n📦 Adding scientific packages...")
    scientific_packages = [
        "Distributions",
        "Graphs",
        "DifferentialEquations"
    ]
    
    for pkg in scientific_packages
        try
            println("Adding $pkg...")
            Pkg.add(pkg)
            Pkg.resolve()
        catch e
            @warn "Failed to add $pkg" exception=e
        end
    end

    # Add optional packages
    println("\n📦 Adding optional packages...")
    optional_packages = [
        "CUDA",
        "SHA",
        "MacroTools",
        "Preferences"
    ]
    
    for pkg in optional_packages
        try
            println("Adding $pkg...")
            Pkg.add(pkg)
            Pkg.resolve()
        catch e
            @warn "Failed to add $pkg" exception=e
        end
    end

    println("\n🔍 Final project resolution...")
    Pkg.resolve()
    
    println("\n✨ Installing dependencies...")
    Pkg.instantiate()
    
    println("\n✅ Project initialization complete")
    return true
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    initialize_project()
end
