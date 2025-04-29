using Pkg

"""
Scan Julia files for potential dependencies by analyzing using/import statements
"""
function scan_dependencies(root_path::String)
    dependencies = Set{String}()
    
    for (root, _, files) in walkdir(root_path)
        for file in files
            if endswith(file, ".jl")
                filepath = joinpath(root, file)
                open(filepath) do f
                    for line in eachline(f)
                        if startswith(strip(line), "using ")
                            pkg = split(strip(line), " ")[2]
                            pkg = replace(pkg, "," => "")
                            push!(dependencies, pkg)
                        elseif startswith(strip(line), "import ")
                            pkg = split(strip(line), " ")[2]
                            pkg = split(pkg, ".")[1]
                            push!(dependencies, pkg)
                        end
                    end
                end
            end
        end
    end
    
    # Filter out local modules
    filter!(pkg -> !isfile(joinpath(root_path, "src", "$pkg.jl")), collect(dependencies))
    return dependencies
end

export scan_dependencies
