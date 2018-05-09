__precompile__()
module RemoteGtkIDE

    using Reexport
    @reexport using Gadfly

    import Base.remotecall_fetch #doesn't need to be exported, it gets propagated in parent module automatically

    export eval_command_remotely, isdone, interrupt_task, run_task, eval_symbol

    function __init__()
        global _run_task = @schedule begin end
    end

    include("eval.jl")
    include("server.jl")    
    include("doc.jl")
    include("stdio.jl")

end # module

