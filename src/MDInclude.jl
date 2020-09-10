module MDInclude

# Imports

using CommonMark

# Exports

export @mdinclude, mdinclude, markdown, isvalid, source, expression, setmodule, capture

# User Interface

"""
    @mdinclude(path, [config])

Include the given `path` in the current module. A configuration object may be
passed as well to control the behaviour of the file inclusion.
"""
macro mdinclude(args...)
    :(mdinclude(@__MODULE__, $(map(esc, args)...)))
end

"""
    mdinclude([module], path, [config])

Similar to `@mdinclude`, but allows an optional module to be given where the
`path` will be evaluated.
"""
function mdinclude(m::Module, path::AbstractString, config=nothing)
    path, prev = Base._include_dependency(m, path)
    ans = nothing
    for (node, enter) in markdown(config, path)
        if enter && isvalid(config, node)
            line = node.sourcepos[1][1]
            newm = setmodule(config, node, m)
            ans = capture(config) do
                _include_string(newm, source(config, node), path, prev) do expr
                    expression(config, _walk(x -> fixline(x, line), expr))
                end
            end
        end
    end
    return ans
end

# Configuration Interface

"""
    ast = markdown(config, path)

Returns the parsed AST for the given `path`. Can be used to customise the
markdown parser extensions.
"""
markdown(config, path) = open(Parser(), path)

"""
    valid = isvalid(config, node)

Checks whether the `node` should be `included` in the file's source code or
not. Returns either `true` or `false`.
"""
isvalid(config, node) = node.t isa CommonMark.CodeBlock && node.t.info == "julia"

"""
    src = source(config, src)

Returns the literal source that should be `included` for each valid AST node.
Can be used to perform textual transformations prior to Julia parsing the text.
"""
source(config, node) = node.literal

"""
    ex = expression(config, ex)

Returns the expression parsed by the Julia parser prior to being evaluated in
the module.
"""
expression(config, ex) = ex

"""
    mod = setmodule(config, node, default)

Select the module to evaluate the given node in. This allows for custom module
choices to be made based on the contents of the `node`. `default` is the
default module provided to `mdinclude`.
"""
setmodule(config, node, default) = default

"""
    value = capture(f, config)

Wraps the evaluation of each code block. Can be used to capture the `stdout`
and `stderr` streams during the evaluation as well as the value of the
evaluation. Should return the value of evaluating `f`.
"""
capture(f, config) = f()

# Utilities

# Traverse the expression and call `f` on each node.
function _walk(f, ex::Expr)
    for (nth, x) in enumerate(ex.args)
        ex.args[nth] = _walk(f, x)
    end
    return ex
end
_walk(f, @nospecialize(other)) = f(other)

# Based on `my_include_string` from NBInclude.jl.
function _include_string(mapexpr, m, txt, path, prev)
    tls = task_local_storage()
    tls[:SOURCE_PATH] = path
    try
        @static if VERSION < v"1.5"
            Core.eval(m, mapexpr(Base.parse_input_line(txt; filename=path)))
        else
            include_string(mapexpr, m, txt, path)
        end
    finally
        prev ≡ nothing ? delete!(tls, :SOURCE_PATH) : tls[:SOURCE_PATH] = prev
    end
end

# Adjust line numbers to match the source markdown file.
fixline(x, line) = x isa LineNumberNode ? LineNumberNode(x.line + line, x.file) : x

end # module
