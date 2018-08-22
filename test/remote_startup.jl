module GtkREPLWorker

    using Reexport, Sockets
    @reexport using RemoteGtkREPL

    gtkrepl_port = parse(Int,ARGS[1])
    global const  id = parse(Int,ARGS[2])
    port, server = RemoteGtkREPL.start_server()

    global const gtkrepl = connect(gtkrepl_port)

end

GtkREPLWorker.RemoteGtkREPL.remotecall_fetch(include_string,GtkREPLWorker.gtkrepl,
    Main,"client_start_cb($(GtkREPLWorker.port))")
