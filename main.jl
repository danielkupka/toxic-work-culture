using Agents
using CSV
using DataFrames
using Distributions
using LightGraphs
using Random

################################################################################
#                                   Includes
################################################################################

include("./src/types.jl")

include("./src/agent_step.jl")
include("./src/employees.jl")
include("./src/init.jl")
include("./src/model_step.jl")
include("./src/projects.jl")
include("./src/run.jl")
include("./src/space.jl")
