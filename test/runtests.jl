using RemoteGtkREPL
using Test
using Serialization, Distributed, Sockets

global const c = Condition()

struct TestType end

function client_start_cb(port)

    @info "getting called $port"
    client = connect(port)

    @assert remotecall_fetch(sin, client, 0) ≈ 0.0
    @info 1
    for i=1:10
        @assert length(remotecall_fetch(rand, client, i)) == i
    end
    @info 2
    # eval x=3 on client and check if x is set
    remotecall_fetch(
        RemoteGtkREPL.eval_command_remotely,client,"x=3","RemoteGtkREPL"
    )
    @info 3
    while !remotecall_fetch(RemoteGtkREPL.isdone,client); sleep(0.01) end
    @info 3.5
    @assert remotecall_fetch(RemoteGtkREPL.run_task,client).result == ("3\n",nothing)
    @assert remotecall_fetch(include_string,client,Main,"@eval RemoteGtkREPL.x ") == 3
    @info 4.1
    remotecall_fetch(info,client,TestType())#this will fail and throw a warning

    notify(c)

    RemoteGtkREPL.remotecall_fetch(exit, client) #brutally kill the client
    close(client)

    @info "Done"
end

@testset "Server and Eval" begin

    port, server = RemoteGtkREPL.start_server()

    client = connect(port)
    serialize(client,("hello",))
    deserialize(client)
    #
    @test RemoteGtkREPL._eval_command_remotely("x=2", @__MODULE__) == ("2\n",nothing)
    @test x == 2
    #

    RemoteGtkREPL.eval_command_remotely("x=3",string(@__MODULE__))
    while !RemoteGtkREPL.isdone() sleep(0.01) end
    @test RemoteGtkREPL.run_task().result == ("3\n",nothing)
    @test x == 3
    #
    @test remotecall_fetch(sin, client, 0) ≈ 0.0
    @test_throws MethodError throw(remotecall_fetch(sin, client, "pi"))

    p = joinpath(@__DIR__,"remote_startup.jl")

    #s = "tell application \"Terminal\" to do script \"julia -i \\\"$p\\\" $port 1\""
    #run(`osascript -e $s`)
    juliapath = ENV["_"] #what kind of variable name is this ?
    @async run(`$juliapath $p $port 1`)#this will call back client_start_cb and notify c
    wait(c)
    close(client)
    close(server)
end

