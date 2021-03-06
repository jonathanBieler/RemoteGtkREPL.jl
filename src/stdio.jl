function send_stream(rd::IO, sock::TCPSocket, id::Int, mod)
    nb = bytesavailable(rd)
    if nb > 0
        d = read(rd, nb)
        s = String(copy(d))

        if !isempty(s)
            #info("sending $s to $(string(sock)) with id: $id")
            #= lock(serialize_lock) do
                remotecall_fetch(include_string, sock, Main, "
                    $(mod).print_to_console_remote(\"$(s)\", $(id))
                ")
            end =#
            lock(serialize_lock) do
                serialize(sock, (StdOutData(id,s),))
            end
        end
    end
end

function watch_stream(rd::IO, sock::TCPSocket, id::Int, mod)
    while !eof(rd) # blocks until something is available
        send_stream(rd, sock, id, mod)
        sleep(0.01) # a little delay to accumulate output
    end
end