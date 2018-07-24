using RemoteGtkREPL
using Base.Test

global const c = Condition()

function client_start_cb(port)

    info("getting called $port")
    client = connect(port)

    #@test RemoteGtkREPL.remotecall_fetch(sin, client, 0) ≈ 0.0

    #for i=1:100
    #    @assert length(RemoteGtkREPL.remotecall_fetch(rand, client, i)) == i
    #end

    notify(c)
    RemoteGtkREPL.remotecall_fetch(quit, client) #brutally kill the client
    info("Done")
end

@testset "Server and Eval" begin

    port, server = RemoteGtkREPL.start_server()

    client = connect(port)
    serialize(client,("hello",))
    deserialize(client)

    #
    @test RemoteGtkREPL._eval_command_remotely("x=2",current_module()) == ("2\n",nothing)
    @test x == 2

    #
    RemoteGtkREPL.eval_command_remotely("x=3",current_module())
    while !RemoteGtkREPL.isdone() sleep(0.01) end
    @test RemoteGtkREPL.run_task().result == ("3\n",nothing)
    @test x == 3

    #
    @test length( RemoteGtkREPL.remote_eval(client, Main, :(x=rand(3))) ) == 3
    @test RemoteGtkREPL.remotecall_fetch(sin, client, 0) ≈ 0.0
    @test_throws MethodError throw(RemoteGtkREPL.remotecall_fetch(sin, client, "pi"))

    p = joinpath(Pkg.dir(),"RemoteGtkREPL","test","remote_startup.jl")

    #s = "tell application \"Terminal\" to do script \"julia -i \\\"$p\\\" $port 1\""
    #run(`osascript -e $s`)

    @schedule run(`julia $p $port 1`)#this will call back client_start_cb and notify c
    wait(c)


end
