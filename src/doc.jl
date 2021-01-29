  # Some utilities to modify nested QuoteNode's

  "takes :A, :B, :C and return :(A.B.C)"
  qn(a, b) = Expr(:(.), a, QuoteNode(b))
  qn(a, b, rest...) = qn(qn(a, b), rest...)


  "parse :(A.B.C) and returns an array of symbols with :A, :B, :C"
  qs(ex::Expr) = qs(ex, Symbol[])
  qs(s::Symbol) = [s]
  function qs(ex::Expr, out::Vector{Symbol})

      if ex.head == :(.)
          qs(ex.args[1], out)
          qs(ex.args[2], out)
      end
      out
  end
  qs(s::Symbol, out::Vector{Symbol}) = push!(out, s)
  qs(s::QuoteNode, out::Vector{Symbol}) = qs(s.value, out)

  #qn(:A, qs(:(B.C))...) == :(A.B.C)
  #qn(:A, :B, :C) == :(A.B.C)


  """
      eval_symbol(s, eval_in::Module)

  eval s in module eval_in, used for data hint.

  """
  function eval_symbol(ex::Union{Expr, Symbol}, eval_in::Module)

      #this prepends eval_in so we can evaluate in Main directly :(eval_in.ex)
      ex = qn(eval_in, qs(ex)...)

      evalout = try Core.eval(Main, ex) catch err; "" end
  end

  function get_doc(s::Symbol, eval_in::Module)
      Base.Docs.doc(
          Base.Docs.Binding(eval_in, s)
      )
  end
  function get_doc(ex::Expr, eval_in::Module)
      try Core.eval(eval_in, :( @doc $ex )) catch; "" end
  end
  function get_doc(ex::String, eval_in::Module)
      try get_doc(Meta.parse(ex), eval_in::Module) catch err; return err end
  end
