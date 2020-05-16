module JL0

import MacroTools
using AutoHashEquals: @auto_hash_equals

include("syntax.jl")
include("parse.jl")
include("insns.jl")
include("lower.jl")
include("state.jl")
include("eval.jl")
include("repl.jl")

end # module
