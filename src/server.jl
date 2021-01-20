abstract type Message end

""" Structure that holds data when evaluation is done on remote
console and result is sent back to GtkREPL"""
struct EvalDone{T} <: Message 
    console_idx::Int
    data::T
    time::Float64
end

""" Structure that holds data when stout is sent"""
struct StdOutData{T} <: Message 
    console_idx::Int
    data::T
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
            (err, )
        end

        response =  try
            @debug data
            process_message(data...)
        catch err
            @warn "Faile to process data" err
            err
        end

        try
            if typeof(response) == Task # cannot serialize a running Task
                istaskstarted(response) && !istaskdone(response) && wait(response)
            end
            serialize(sock, response)
        catch err
            @warn "Fail to serialize client: $err"
            @show sock
            serialize(sock, FAILURE)
            continue
        end
    end
end

process_message() = nothing

function process_message(data)
    @warn "process_message: No processing implemented for $data"
    nothing
end

process_message(f::Function, args...) = @safe f(args...)

function process_message(mod::Module, ex::Expr)
    @safe Core.eval(mod, ex)
end

function remotecall_fetch(f::Function, client::TCPSocket, args...)
    @safe serialize(client, (f, args...) )
    @safe deserialize(client)
end
