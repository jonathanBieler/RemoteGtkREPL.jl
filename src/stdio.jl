function send_stream(rd::IO, sock::TCPSocket, id::Int, mod)
    nb = nb_available(rd)
    if nb > 0
        d = read(rd, nb)
        s = String(copy(d))

        if !isempty(s)
            # remotecall_fetch(print_to_console_remote,sock,s,id)

            info("sending $s to $(string(sock)) with id: $id")

            remotecall_fetch(include_string, sock,"
                eval($mod,:(
                    print_to_console_remote(\"$(s)\", $(id))
                ))
            ")

        end
    end
end

function watch_stream(rd::IO, sock::TCPSocket, id::Int, mod)
    while !eof(rd) # blocks until something is available
        send_stream(rd,sock,id,mod)
        sleep(0.01) # a little delay to accumulate output
    end
end

function print_to_console_remote(s,idx::Integer)
    info("received print data with index $idx" )
    #print the output to the right console
    for i = 1:length(main_window.console_manager)
        c = get_tab(main_window.console_manager,i)
        if c.worker_idx == idx
            write(c.stdout_buffer,s)
        end
    end
end
