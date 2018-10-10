@enum Messages DONE=1 FAILURE=2

macro safe(ex)
    esc(quote
        try
            $ex
        catch err
            err
        end
    end)
end

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
        data = try
            deserialize(sock)
        catch err
            @warn "Fail to deserialize client: $err"
            serialize(sock, FAILURE)
            ""
        end

        response = process_message(data...)
        try
            if typeof(response) == Task # cannot serialize a running Task
                istaskstarted(response) && !istaskdone(response) && wait(response)
            end
            serialize(sock, response)
        catch err
            @warn "Fail to serialize client: $err"
            serialize(sock, FAILURE)
            continue
        end
    end
end

process_message(data) = begin @show "process_message" data; nothing end
function process_message(data)
    @show "process_message" data
    nothing
end

function remotecall_fetch(f::Function, client::TCPSocket,args...)
    @safe serialize(client, (f, args...) )
    x = @safe deserialize(client)
    x
end
process_message(f::Function, args...) = @safe f(args...)

function process_message(mod::Module,ex::Expr)
    @safe Core.eval(mod,ex)
end
