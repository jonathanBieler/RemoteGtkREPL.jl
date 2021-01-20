module RemoteGtkREPL

    using Base64, Sockets, Serialization, Distributed, Pkg, REPL

    import Distributed: remotecall_fetch, remotecall
    import REPL.REPLCompletions.completions

    export eval_command_remotely, isdone, interrupt_task, run_task, eval_symbol

    """ Reference to the socket to GtkREPL and the console index in GtkREPL's 
    ConsoleManager """
    struct GtkREPL_Server
        socket::Sockets.TCPSocket
        console_idx::Int
    end
    function init(socket, idx)
        global gtkrepl = GtkREPL_Server(socket, idx)#this is called in remote_console_startup.jl
    end

    function __init__()
        global _run_task = @async begin end
        global serialize_lock = ReentrantLock()
    end

    include("eval.jl")
    include("server.jl")
    include("doc.jl")
    include("stdio.jl")

end # module
