using Revise
using RemoteGtkIDE
using Base.Test

#value  = String(read(`julia repl.jl`))

port, server = RemoteGtkIDE.start_server()

client = connect(port)
serialize(client,("test",))
deserialize(client)

# @async while true
#     response = deserialize(client)
#     println(response)
# end

@test length( RemoteGtkIDE.remote_eval(client, Main, :(x=rand(3))) ) == 3

@test RemoteGtkIDE.remotecall_fetch(sin, client, 0) ≈ 0.0

@test_throws MethodError throw(RemoteGtkIDE.remotecall_fetch(sin, client, "pi"))
