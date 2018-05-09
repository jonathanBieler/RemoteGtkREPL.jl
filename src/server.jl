@enum Messages DONE=1

function start_server()
    port, server = listenany(8000)

    @async begin
        while true
            sock = accept(server)
            @async process_client(sock)
        end
    end
    port, server
end

function process_client(sock)
    while isopen(sock)
        data = deserialize(sock)
        response = process_message(data...)
        serialize(sock, response)
    end
end

macro safe(ex)
    esc(quote
        try 
            $ex
        catch err
            err
        end
    end)
end

function process_message(data)
    println(data)
    DONE
end

function remotecall_fetch(f::Function, client::TCPSocket,args...)
    serialize(client, (f, args...) )
    deserialize(client)
end
process_message(f::Function, args...) = @safe f(args...)

function remote_eval(client, mod::Module, ex::Expr)
    serialize(client, (mod, ex) )
    deserialize(client)
end
function process_message(mod::Module,ex::Expr)
    @safe eval(mod,ex)
end