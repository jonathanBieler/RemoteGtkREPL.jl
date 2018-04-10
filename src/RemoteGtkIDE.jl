__precompile__()
module RemoteGtkIDE

    import Base.remotecall_fetch
    using Reexport
    @reexport using Gadfly

    function __init__()
        global _run_task = @schedule begin end
    end

    include("eval.jl")
    include("server.jl")    
    include("doc.jl")

end # module

