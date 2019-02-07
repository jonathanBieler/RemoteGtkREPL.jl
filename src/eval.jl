run_task() = _run_task
isdone() = _run_task.state == :done
interrupt_task() = @async Base.throwto(_run_task, InterruptException())

#FIXME dirty hack
function clean_error_msg(s::String)
    r  = r"^(.*)\s\[\d\] _eval_command_remotely.*$"s
    m = match(r,s)
    m != nothing && return m.captures[1]
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

function eval_command_remotely(cmd::String,eval_in::String)
    mod =  @eval Main $(Meta.parse(eval_in))
    global _run_task = @async _eval_command_remotely(cmd,mod)
    nothing
end

function eval_shell_remotely(cmd::String,eval_in::String)
    mod =  @eval Main $(Meta.parse(eval_in))
    global _run_task = @async _eval_shell_remotely(cmd,mod)
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

    if @eval @isdefined Gadfly
        v = is_plot(v)
    else
        v = nothing
    end
    # are not defined on worker 1

    return finalOutput, v
end

function repl_cmd(cmd)
    read(cmd,String)
end

function _eval_shell_remotely(cmd::String,eval_in::Module)
    evalout = try
        cmd = Core.eval(Main, :(Base.cmd_gen($(Base.shell_parse(cmd)[1]))) )
        evalout = repl_cmd(cmd)
    catch err
        bt = catch_backtrace()
        evalout = clean_error_msg( sprint(showerror,err,bt) )
    end
    return evalout, nothing
end
