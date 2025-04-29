using Pkg

"""
Clean up existing package files and dynamically resolve dependencies
"""
function clean_and_resolve()
    root_dir = dirname(dirname(@__FILE__))
    
    # Clean up existing TOML files
    println("🧹 Cleaning up existing package files...")
    toml_files = ["Manifest.toml", "Project.toml"]
    for file in toml_files
        path = joinpath(root_dir, file)
        if isfile(path)
            println("  Removing $file")
            rm(path)
        end
    end

    # Create fresh project
    println("\n📦 Creating new project...")
    Pkg.activate(root_dir)
    
    # Update registry to get latest package info
    println("\n🔄 Updating package registry...")
    Pkg.Registry.update()
    
    # Analyze code to find actual dependencies
    println("\n🔍 Analyzing project dependencies...")
    deps = Dict{String, Dict{String, Any}}()
    
    # Recursively search all Julia files
    for (root, _, files) in walkdir(root_dir)
        for file in files
            if endswith(file, ".jl")
                path = joinpath(root, file)
                content = read(path, String)
                
                # Find package imports and usings
                for m in eachmatch(r"(?:using|import)\s+([A-Za-z][A-Za-z0-9_.]*)(?:\s*:\s*([^#\n]*))?", content)
                    pkg = m.captures[1]
                    if !is_stdlib_package(pkg)
                        deps[pkg] = get(deps, pkg, Dict{String, Any}(
                            "usages" => 0,
                            "imports" => String[],
                            "weight" => 0
                        ))
                        deps[pkg]["usages"] += 1
                        
                        # Track imported symbols
                        if length(m.captures) > 1 && m.captures[2] !== nothing
                            append!(deps[pkg]["imports"], 
                                   filter(x -> !isempty(x), 
                                        strip.(split(m.captures[2], ','))))
                        end
                    end
                end
            end
        end
    end

    # Calculate dependency weights based on usage and imports
    for (pkg, info) in deps
        info["weight"] = info["usages"] + length(info["imports"]) * 0.5
    end

    # Sort packages by weight for optimal installation order
    sorted_deps = sort(collect(keys(deps)), 
                      by=pkg -> deps[pkg]["weight"],
                      rev=true)

    # Install packages in order
    println("\n📚 Installing packages in dependency order...")
    for pkg in sorted_deps
        try
            println("  Adding $pkg...")
            Pkg.add(pkg)
            Pkg.resolve()
        catch e
            @warn "Failed to add $pkg" exception=e
        end
    end

    println("\n✨ Finalizing project...")
    Pkg.resolve()
    Pkg.instantiate()
    
    return true
end

"""
Check if a package is part of Julia's standard library
"""
function is_stdlib_package(pkg::String)
    stdlib = ["Base", "Core", "LinearAlgebra", "Statistics", "Random", 
             "Test", "Pkg", "REPL", "InteractiveUtils", "Dates"]
    return pkg in stdlib
end

if abspath(PROGRAM_FILE) == @__FILE__
    clean_and_resolve()
end
