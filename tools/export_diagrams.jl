using HTTP
using JSON3
using Base64

"""
    export_mermaid_diagram(mermaid_code::String, output_file::String; format::String="svg", scale::Int=3)

Export a Mermaid diagram to an image file using the Mermaid live editor API.
Supports PNG and SVG formats with configurable scaling for high resolution.
"""
function export_mermaid_diagram(mermaid_code::String, output_file::String; format::String="svg", scale::Int=3)
    # Mermaid Live Editor API endpoint
    api_url = "https://mermaid.ink/img/"

    # Add scaling configuration to the init block
    if !contains(mermaid_code, "%%{init:")
        mermaid_code = """%%{init: {'theme': 'base', 'pixelRatio': $scale}}%%\n""" * mermaid_code
    else
        # Insert pixelRatio into existing init block
        mermaid_code = replace(mermaid_code, "%%{init:" => "%%{init: {'pixelRatio': $scale,")
    end

    # Encode the Mermaid code
    encoded_diagram = base64encode(mermaid_code)
    
    # Construct the full URL
    full_url = api_url * encoded_diagram

    try
        # Download the image
        response = HTTP.get(full_url)
        
        # Write to file
        open(output_file, "w") do io
            write(io, response.body)
        end
        
        println("✅ Exported high-resolution diagram to: $output_file")
        return true
    catch e
        println("❌ Failed to export diagram: $e")
        return false
    end
end

"""
    extract_mermaid_code(markdown_file::String)

Extract all Mermaid diagram code blocks from a Markdown file.
Returns an array of diagram codes.
"""
function extract_mermaid_code(markdown_file::String)
    content = read(markdown_file, String)
    diagrams = String[]
    
    # Find all Mermaid code blocks
    for m in eachmatch(r"```mermaid\n(.*?)\n```"s, content)
        push!(diagrams, m.captures[1])
    end
    
    return diagrams
end

"""
    export_architecture_diagrams()

Export all diagrams from the architecture documentation.
"""
function export_architecture_diagrams()
    # Create output directory
    output_dir = joinpath(@__DIR__, "..", "docs", "diagrams")
    mkpath(output_dir)
    
    # Source markdown file
    arch_doc = joinpath(@__DIR__, "..", "docs", "ARCHITECTURE_WORKFLOW.md")
    
    # Extract and export each diagram
    diagrams = extract_mermaid_code(arch_doc)
    
    println("Found $(length(diagrams)) diagrams")
    
    for (i, diagram) in enumerate(diagrams)
        name = if i == 1
            "system_flow"
        elseif i == 2
            "component_interactions"
        else
            "universal_integration"
        end
        
        # Export as both PNG and SVG
        for format in ["png", "svg"]
            output_file = joinpath(output_dir, "$(name).$(format)")
            export_mermaid_diagram(diagram, output_file, format=format)
        end
    end
    
    println("\n📊 Diagrams exported to: $output_dir")
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    export_architecture_diagrams()
end
