module InternetModule

using HTTP
using JSON3

"""
    is_connected()
Check if the system has internet connectivity.
"""
function is_connected()
    try
        HTTP.get("https://www.google.com"; connect_timeout=3)
        return true
    catch
        return false
    end
end

"""
    search_web(query::String)
Search the web using DuckDuckGo Instant Answer API (free, no key required).
"""
function search_web(query::String)
    url = "https://api.duckduckgo.com/?q=$(HTTP.escapeuri(query))&format=json&no_redirect=1&no_html=1"
    try
        resp = HTTP.get(url)
        data = JSON3.read(resp.body)
        return get(data, :Abstract, "No summary found.")
    catch e
        return "Search failed: $(e)"
    end
end

"""
    enrich_codebase(topics::Vector{String})
Suggest improvements for healing and evolution based on web search.
"""
function enrich_codebase(topics::Vector{String})
    suggestions = Dict{String, String}()
    for topic in topics
        suggestions[topic] = search_web("software architecture evolution " * topic)
    end
    return suggestions
end

export is_connected, search_web, enrich_codebase

end # module
