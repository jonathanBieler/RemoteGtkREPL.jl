using RemoteGtkIDE
using Base.Test

global const c = Condition()
wake_up() = notify(c)

@testset "local" begin

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

p = joinpath(Pkg.dir(),"RemoteGtkIDE","test","remote_startup.jl")
s = "tell application \"Terminal\" to do script \"julia -i --color=no \\\"$p\\\" $port 1\""
run(`osascript -e $s`)

wait(c)
RemoteGtkIDE.remotecall_fetch(quit, client)

end