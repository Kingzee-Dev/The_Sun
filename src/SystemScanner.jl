# SystemScanner.jl
module SystemScanner

using Dates

export scan_system_hardware

function scan_cpu()
    cpuinfo = Dict()
    try
        cpuinfo["model"] = Sys.cpu_info()[1].model
        cpuinfo["cores"] = Sys.CPU_THREADS
        cpuinfo["arch"] = Sys.ARCH
    catch
        cpuinfo["model"] = "Unknown"
        cpuinfo["cores"] = Sys.CPU_THREADS
        cpuinfo["arch"] = Sys.ARCH
    end
    return cpuinfo
end

function scan_gpu()
    gpus = []
    # Try CUDA (NVIDIA)
    try
        @eval begin
            import CUDA
            for dev in CUDA.devices()
                push!(gpus, Dict(
                    "vendor" => "NVIDIA",
                    "name" => CUDA.name(dev),
                    "uuid" => CUDA.uuid(dev),
                    "memory" => CUDA.totalmem(dev)
                ))
            end
        end
    catch
    end
    # Try AMDGPU (AMD)
    try
        @eval begin
            import AMDGPU
            for dev in AMDGPU.devices()
                push!(gpus, Dict(
                    "vendor" => "AMD",
                    "name" => AMDGPU.name(dev),
                    "memory" => AMDGPU.memory(dev)
                ))
            end
        end
    catch
    end
    # Try system tools for iGPU/eGPU (Linux only)
    try
        gpuinfo = read(pipeline(`lspci`, `grep -i 'vga\\|3d\\|display'`), String)
        for line in split(gpuinfo, '\n')
            if !isempty(line)
                push!(gpus, Dict("vendor" => "Unknown", "info" => line))
            end
        end
    catch
    end
    return gpus
end

function scan_system_hardware()
    return Dict(
        "timestamp" => Dates.format(now(), "yyyy-mm-dd HH:MM:SS"),
        "cpu" => scan_cpu(),
        "gpus" => scan_gpu(),
        "memory_gb" => Sys.total_memory() / 1e9
    )
end

end # module
