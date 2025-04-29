module RealDataIngestion

using HTTP
using JSON3
using CSV
using DataFrames

"""
    fetch_open_data(source::String; format::Symbol=:json)
Fetch and parse real-world open data from a URL or local file. Supports :json and :csv formats.
Returns a vector of Dicts for downstream processing.
"""
function fetch_open_data(source::String; format::Symbol=:json)
    if startswith(source, "http")
        resp = HTTP.get(source)
        if format == :json
            data = JSON3.read(String(resp.body))
            return isa(data, Vector) ? data : [data]
        elseif format == :csv
            io = IOBuffer(resp.body)
            df = CSV.read(io, DataFrame)
            return [Dict(row) for row in eachrow(df)]
        else
            error("Unsupported format: $format")
        end
    else
        if format == :json
            data = JSON3.read(read(source, String))
            return isa(data, Vector) ? data : [data]
        elseif format == :csv
            df = CSV.read(source, DataFrame)
            return [Dict(row) for row in eachrow(df)]
        else
            error("Unsupported format: $format")
        end
    end
end

export fetch_open_data

end # module
