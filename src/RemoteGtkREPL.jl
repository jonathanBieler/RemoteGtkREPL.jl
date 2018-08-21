__precompile__()
module RemoteGtkREPL

    using Base64, Sockets, Serialization, Distributed

    function gadfly()
        @eval begin
            import Gadfly
            export Gadfly
        end
    end

    import Base.remotecall_fetch #doesn't need to be exported, it gets propagated in parent module automatically

    export eval_command_remotely, isdone, interrupt_task, run_task, eval_symbol

    function __init__()
        global _run_task = @async begin end
    end

    include("eval.jl")
    include("server.jl")
    include("doc.jl")
    include("stdio.jl")

end # module
