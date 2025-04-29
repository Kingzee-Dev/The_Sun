module LawFileGenerator

using JSON3

"""
    generate_law_files!(laws_config::Dict, discovered_law::Dict)
Generate Julia source files for discovered laws based on templates
"""
function generate_law_files!(laws_config::Dict, discovered_law::Dict)
    base_path = laws_config["file_generation"]["base_path"]
    
    # Create domain directory if needed
    domain_path = joinpath(base_path, discovered_law["domain"])
    mkpath(domain_path)
    
    # Generate law file from template
    template = read(laws_config["file_generation"]["templates"]["law_module"], String)
    filename = "$(titlecase(discovered_law["name"]))Law.jl"
    filepath = joinpath(domain_path, filename)
    
    # Replace template placeholders
    content = replace(template,
        "{{LAW_NAME}}" => discovered_law["name"],
        "{{FORMULA}}" => get(discovered_law, "formula", ""),
        "{{DOMAIN}}" => discovered_law["domain"]
    )
    
    # Write law file
    write(filepath, content)
    
    return filepath
end

export generate_law_files!

end # module
