run_task() = _run_task
isdone() = _run_task.state == :done
interrupt_task() = @async Base.throwto(_run_task, InterruptException())

""" 
    serialized_value(x) = nothing

Allow types to be serialized back to GtkREPL, by default sends `nothing`.
GtkREPL will call `display` on these objects.
"""
serialized_value(x) = nothing

# FIXME dirty hack
# see https://github.com/JunoLab/Atom.jl/blob/52ef77a93605cb4ddbf455ba36d1d7e9ae637edc/src/eval.jl#L129
function clean_error_msg(s::String)
    r  = r"^(.*)\s\[\d\] _eval_command_remotely.*$"s
    m = match(r, s)
    !isnothing(m) && return m.captures[1]
    s
end

function trim(s::AbstractString, L::Int)#need to be AbstracString to accept SubString
    if length(s) > L
        return string(s[1:L], "...")
    end
    s
end

function format_output(x)
    io = IOBuffer()
    io = IOContext(io, :display_size=>(20, 20))
    io = IOContext(io, :limit=>true)
    show(io, MIME"text/plain"(), x)
    String(take!(io.io))
end

function eval_command_remotely(cmd::String, eval_in::String)
    @async begin
        mod =  @eval Main $(Meta.parse(eval_in))
        t = @elapsed finalOutput, v = _eval_command_remotely(cmd, mod)
        #TODO check stdout at this point ? Let's wait a bit at least
        sleep(50/1000)
        lock(serialize_lock) do
            serialize(gtkrepl.socket, (EvalDone(
                gtkrepl.console_idx,
                (finalOutput,v),
                t
            ),))
        end
    end
    true
end

function eval_shell_remotely(cmd::String, eval_in::String)
    @async begin
        t = @elapsed finalOutput, v = _eval_shell_remotely(cmd)
        #TODO merge this with eval_command_remotely ?
        lock(serialize_lock) do
            serialize(gtkrepl.socket, (EvalDone(
                gtkrepl.console_idx,
                (finalOutput,v),
                t
            ),))
        end
    end
    true
end

function _eval_command_remotely(cmd::String, eval_in::Module)

    evalout = ""
    v = :()
    try
        v = include_string(eval_in, cmd)
        Core.eval(eval_in, :(ans = $(Expr(:quote, v))))
        evalout = isnothing(v) ? "" : format_output(v)
    catch err
        bt = catch_backtrace()
        evalout = clean_error_msg( sprint(showerror, err, bt) )
    end

    evalout = trim(evalout, 4000)
    finalOutput = evalout == "" ? "" : "$evalout\n"

    v = serialized_value(v)
    
    return finalOutput, v
end

function _eval_shell_remotely(cmd::String)
    evalout = try
        cmd = Core.eval(Main, :(Base.cmd_gen($(Base.shell_parse(cmd)[1]))) )
        evalout = read(cmd, String)
    catch err
        bt = catch_backtrace()
        evalout = clean_error_msg( sprint(showerror, err, bt) )
    end
    return evalout, nothing
end

function remote_completions(cmd)
    comp, dotpos = completions(cmd, lastindex(cmd))
    comp = REPL.completion_text.(comp)# avoid returning the object itself https://github.com/JuliaLang/julia/issues/33747
    comp, dotpos
end