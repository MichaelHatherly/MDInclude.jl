# MDInclude

`include` your markdown files as if they were Julia source files. This package
was inspired by the similar package for Jupyter notebooks called
[NBInclude.jl](https://github.com/stevengj/NBInclude.jl).

## Installation

```
pkg> add https://github.com/MichaelHatherly/MDInclude.jl
```

## Usage

Why not turn your README into the package source! What could go wrong...

```julia
module MyPackage

using MDInclude

@mdinclude("../README.md")

end
```

More seriously though, you can use the macro `@mdinclude` as you would
`include` from `Base` or `@nbinclude` from NBInclude.jl to write your package,
or just for writing a once-off script.

Additionally, a `mdinclude` function is provided so that you can set the
`Module` into which you want to evaluate the code in your markdown file.

```julia
mdinclude(MyModule, "file.md")
```

## Custom Evaluation

The parsing and evaluation of markdown files can be customised by providing a
"configuration" object as the final argument to either `@mdinclude` or
`mdinclude`. This can be used to change what is done during each step of
parsing and evaluating the file. The following functions provide access points
within the parsing and evaluation steps for customisation:

  - `markdown(config, path)`
  - `isvalid(config, node)`
  - `source(config, node)`
  - `expression(config, ex)`
  - `setmodule(config, node, default)`
  - `capture(f, config)`

Read the docstrings for details regarding their use.
