module LibPNG

using Colors,
      ImageCore,
      FixedPointNumbers

export readimage,
       writeimage


const depsfile = joinpath(dirname(@__FILE__), "..", "deps", "deps.jl")
if isfile(depsfile)
    include(depsfile)
else
    error("LibPNG not properly installed. Please run Pkg.build(\"LibPNG\") then restart Julia.")
end

include("types.jl")
include("functions.jl")
include("io.jl")
#
end # module