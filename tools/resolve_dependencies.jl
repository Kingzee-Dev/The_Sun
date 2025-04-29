using Pkg

"""
Resolve and install all required packages for the Universal Celestial Intelligence system
"""
function resolve_dependencies()
    # Activate the project
    Pkg.activate(dirname(dirname(@__FILE__)))
    
    println("🔄 Updating package registry...")
    Pkg.Registry.update()
    
    println("📦 Adding required packages...")
    # Standard library packages don't need to be added explicitly
    std_packages = [
        "Base64",
        "Dates",
        "FileWatching",
        "InteractiveUtils",
        "LinearAlgebra",
        "Pkg",
        "Random",
        "SHA",
        "Statistics",
        "Test"
    ]
    
    # External packages that need to be added
    external_packages = [
        "CSV",
        "CUDA",
        "DataFrames",
        "DataStructures",
        "DifferentialEquations",
        "Distributions",
        "Graphs",
        "HTTP",
        "JSON3",
        "MacroTools",
        "Preferences",
        "StatsBase"
    ]

    for pkg in external_packages
        try
            println("Adding package: $pkg")
            Pkg.add(pkg)
        catch e
            @warn "Failed to add $pkg" exception=e
        end
    end

    println("🔍 Resolving project state...")
    Pkg.resolve()

    println("✨ Installing dependencies...")
    Pkg.instantiate()

    println("✅ All dependencies have been resolved and installed")
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    resolve_dependencies()
end
