# Tests

Line numbers should match up with the source markdown files:

```julia
LINE = @__LINE__
```

`LINE` should be visible during the next code block and the `@__FILE__` macro
should return the correct file:

```julia
@testset "Basics" begin
    @test LINE == 6
    @test last(splitdir(@__FILE__)) == "tests.md"
end
```

Code blocks that don't have `julia` set as the language shouldn't be evaluated.
The following block would raise an error since it doesn't provide enough
arguments to the `@test` macro.

```
@test # This should not be evaluated.
```

We define a custom configuration that will capture all the raw text from the
valid code blocks. Aside from that it won't do anything different.

```julia
struct Config
    source::Vector{String}
end
MDInclude.source(config::Config, node) = last(push!(config.source, node.literal))

config = Config([])
@mdinclude("config.md", config)
```

Some tests to make sure we've actually evaluated and capture the correct blocks:

```julia
@testset "Configuration" begin
    @test config.source == ["x = 1\n", "y = 2\n"]
    @test x == 1
    @test y == 2
end
```
