# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Definition of the types used in the simulation.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

Base.@kwdef mutable struct Project
    cycles_to_finish::Int
    maximum_number_of_employees::Int
    minimum_number_of_employees::Int
end

Base.@kwdef mutable struct Employee{T} <: AbstractAgent
    id::Int
    pos::Int

    # Current satisfaction of the employee.
    satisfaction::T

    # Current project ID of the employee in their department.
    project::Union{Nothing, Project} = nothing

    # Parameters related to the employee.
    minimum_satisfaction_for_proposing_lateral_relocation::T
    minimum_satisfaction_for_proposing_remote_work::T
    minimum_satisfaction_for_searching_job::T
    remote_work::Bool = false
    was_relocated::Bool = false
    workload_satisfaction_factor::T

    # Number of cycles without a project.
    num_cycles_without_project::Int = 0

    # If `true`, then the employee left the company and will be destroyed in the
    # next step.
    left::Bool = false
end

# Add a keyword construction to make initialization easier.
function Employee{T}(
    id::Int,
    pos::Int;
    kwargs...
) where T
    return Employee{T}(;
        id,
        pos,
        kwargs...
    )
end
