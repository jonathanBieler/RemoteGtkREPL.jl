run_task() = _run_task
isdone() = _run_task.state == :done
interrupt_task() = @async Base.throwto(_run_task, InterruptException())

#FIXME dirty hack
function clean_error_msg(s::String)

    if VERSION < v"0.6.0"

        r  = Regex("(.*)in eval_command_remotely.*","s")
        m = match(r,s)
        m != nothing && return m.captures[1]
    else
        r  = Regex("""(.*)\\[\\d\\] eval_command_remotely.*""","s")
        m = match(r,s)
        m != nothing && return m.captures[1]
    end
    s
end

function trim(s::AbstractString,L::Int)#need to be AbstracString to accept SubString
    if length(s) > L
        return string(s[1:L],"...")
    end
    s
end

function format_output(x)
    io = IOBuffer()
    io = IOContext(io,:display_size=>(20,20))
    io = IOContext(io,:limit=>true)
    show(io,MIME"text/plain"(),x)
    String(take!(io.io))
end

is_plot(v) = typeof(v) <: Gadfly.Plot ? v : nothing

function eval_command_remotely(cmd::String,eval_in::Module)
    global _run_task = @async _eval_command_remotely(cmd,eval_in)
    nothing
end

function eval_shell_remotely(cmd::String)
    global _run_task = @async _eval_shell_remotely(cmd)
    nothing
end

function _eval_command_remotely(cmd::String,eval_in::Module)
    ex = Base.parse_input_line(cmd)
    ex = Meta.lower(eval_in,ex)

    evalout = ""
    v = :()
    try
        v = Core.eval(eval_in,ex)
        Core.eval(eval_in, :(ans = $(Expr(:quote, v))))

        evalout = v == nothing ? "" : format_output(v)

    catch err
        bt = catch_backtrace()
        evalout = clean_error_msg( sprint(showerror,err,bt) )
    end

    evalout = trim(evalout,4000)
    finalOutput = evalout == "" ? "" : "$evalout\n"

    if @eval isdefined(:Gadfly)
        v = is_plot(v)
    else
        v = nothing
    end
    # are not defined on worker 1

    return finalOutput, v
end

import Base: shell_wrap_true, shell_escape

function repl_cmd(cmd)
    shell = Base.shell_split(get(ENV,"JULIA_SHELL",get(ENV,"SHELL","/bin/sh")))
    shell_name = Base.basename(shell[1])

    if isempty(cmd.exec)
        throw(ArgumentError("no cmd to execute"))
    elseif cmd.exec[1] == "cd"
        new_oldpwd = pwd()
        if length(cmd.exec) > 2
            throw(ArgumentError("cd method only takes one argument"))
        elseif length(cmd.exec) == 2
            dir = cmd.exec[2]
            if dir == "-"
                if !haskey(ENV, "OLDPWD")
                    error("cd: OLDPWD not set")
                end
                cd(ENV["OLDPWD"])
            else
                cd(@static Sys.iswindows() ? dir : readchomp(`$shell -c "echo $(shell_escape(dir))"`))
            end
        else
            cd()
        end
        ENV["OLDPWD"] = new_oldpwd
        return pwd()
    else
        return readstring(ignorestatus(@static Sys.iswindows() ? cmd : (isa(STDIN, Base.TTY) ? `$shell -i -c "$(shell_wrap_true(shell_name, cmd))"` : `$shell -c "$(shell_wrap_true(shell_name, cmd))"`)))
    end
    ""
end

function _eval_shell_remotely(cmd::String)
    evalout = try
        cmd = Core.eval( :(Base.cmd_gen($(Base.shell_parse(cmd)[1]))) )
        repl_cmd(cmd)
    catch err
        bt = catch_backtrace()
        evalout = clean_error_msg( sprint(showerror,err,bt) )
    end
    return evalout, nothing
end
