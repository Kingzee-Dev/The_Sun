module DependencyManager

using Pkg

"""
Clean up existing package files
"""
function cleanup_packages()
    root_dir = dirname(dirname(@__FILE__))
    
    println("🧹 Cleaning up existing package files...")
    for file in ["Manifest.toml", "Project.toml"]
        path = joinpath(root_dir, file)
        if isfile(path)
            println("  Removing $file")
            rm(path)
        end
    end
end

"""
Check if package is part of standard library
"""
function is_stdlib_package(pkg)
    # Convert any string type to String
    pkg_name = String(pkg)
    stdlib = ["Base", "Core", "LinearAlgebra", "Statistics", "Random", 
             "Test", "Pkg", "REPL", "InteractiveUtils", "Dates"]
    return pkg_name in stdlib
end

"""
Add a local package by creating a dev symlink
"""
function add_local_package!(pkg_name::String)
    root_dir = dirname(dirname(@__FILE__))
    pkg_dir = joinpath(root_dir, "src", pkg_name)
    
    if isdir(pkg_dir)
        try
            Pkg.develop(path=pkg_dir)
            return true
        catch e
            @warn "Failed to add local package $pkg_name" exception=e
            return false
        end
    end
    return false
end

"""
Install a package from the registry
"""
function add_registry_package!(pkg_name::String)
    try
        Pkg.add(pkg_name)
        return true
    catch e
        if !contains(string(e), "not found in registry")
            @warn "Failed to add package $pkg_name" exception=e
        end
        return false
    end
end

"""
Install a batch of packages with precompilation monitoring
"""
function install_package_batch(packages::Vector{String})
    for pkg in packages
        if !is_stdlib_package(pkg)
            try
                println("  Adding $pkg...")
                Pkg.add(pkg)
                println("  ✓ Added $pkg")
            catch e
                @warn "Failed to add $pkg" exception=e
            end
        end
    end
    
    # Force resolve after each batch
    Pkg.resolve()
end

"""
Analyze codebase for package dependencies
"""
function analyze_dependencies()
    root_dir = dirname(dirname(@__FILE__))
    deps = Dict{String, Dict{String, Any}}()
    
    for (root, _, files) in walkdir(root_dir)
        for file in files
            if endswith(file, ".jl")
                path = joinpath(root, file)
                content = read(path, String)
                
                # Find package imports and usings with improved pattern matching
                for m in eachmatch(r"(?:using|import)\s+([A-Za-z][A-Za-z0-9_.]*)(?:\s*:\s*([^#\n]*))?", content)
                    # Convert match to String explicitly
                    pkg = String(m.captures[1])
                    if !is_stdlib_package(pkg)
                        deps[pkg] = get(deps, pkg, Dict{String, Any}(
                            "usages" => 0,
                            "imports" => String[],
                            "weight" => 0
                        ))
                        deps[pkg]["usages"] += 1
                    end
                end
            end
        end
    end
    
    return deps
end

"""
Resolve dependencies in batches with precompilation monitoring
"""
function resolve()
    cleanup_packages()
    
    println("\n📦 Creating new project...")
    root_dir = dirname(dirname(@__FILE__))
    Pkg.activate(root_dir)
    
    println("\n🔄 Updating package registry...")
    Pkg.Registry.update()
    
    # Core packages first
    basic_pkgs = ["DataStructures", "JSON3", "HTTP"]
    stats_pkgs = ["StatsBase", "Distributions"]
    data_pkgs = ["CSV", "Graphs"]
    sci_pkgs = ["DifferentialEquations"]
    
    println("\n📚 Installing and precompiling packages...")

    # Install basic packages first
    for pkg in basic_pkgs
        println("📥 Adding $pkg...")
        try
            Pkg.add(pkg)
            println("✓ Added $pkg")
        catch e
            @warn "Failed to add $pkg" exception=e
        end
    end

    # Precompile first batch
    println("\n⚙️ Precompiling core packages...")
    try
        Base.compilecache(Base.PkgId("DataStructures"))
        GC.gc() # Force garbage collection
    catch e
        @warn "Precompilation warning (non-fatal)" exception=e
    end

    # Install remaining packages with precompilation breaks
    for (i, batch) in enumerate([stats_pkgs, data_pkgs, sci_pkgs])
        println("\n📦 Installing batch $(i)/3...")
        for pkg in batch
            try
                Pkg.add(pkg)
                println("✓ Added $pkg")
                GC.gc() # Clean up after each package
            catch e
                @warn "Failed to add $pkg" exception=e
            end
        end
        
        # Brief pause between batches
        println("⏳ Letting system stabilize...")
        sleep(2)
    end

    println("\n✨ Finalizing project...")
    Pkg.resolve()
    
    return true
end

export resolve

end # module
