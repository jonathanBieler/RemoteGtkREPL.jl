module GtkREPLWorker

    using Reexport
    @reexport using RemoteGtkREPL

    gtkrepl_port = parse(Int,ARGS[1])
    global const  id = parse(Int,ARGS[2])
    port, server = RemoteGtkREPL.start_server()

    global const gtkrepl = connect(gtkrepl_port)

end

RemoteGtkREPL.remotecall_fetch(include_string, GtkREPLWorker.gtkrepl,"client_start_cb($(GtkREPLWorker.port))")
