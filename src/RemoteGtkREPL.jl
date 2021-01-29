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
        remote_module::String
    end
    function estalbish_connection(ARGS)
        gtkrepl_port = parse(Int, ARGS[1])
        idx = parse(Int, ARGS[2]) # console/worker id
        remote_module = ARGS[3]     # the module calling us as a String

        port, server = start_server()
    
        socket = connect(gtkrepl_port)
        global gtkrepl = GtkREPL_Server(socket, idx, remote_module)

        remotecall_fetch(include_string, socket, Main,
            "$(remote_module).add_remote_console_cb($(idx), $(port))"
        )

        @async begin    
            read_stdout, wr = redirect_stdout()
            watch_stdio_task = @async watch_stream(read_stdout, socket, idx, remote_module)
        end
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
