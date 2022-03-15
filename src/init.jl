# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions to initialize the simulation.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Initialize the model.
function initialize_model(;
    number_of_departments::Int                       = 5,
    number_of_projects_per_department::Int           = 5,
    debug_agent::Bool                                = true,
    debug_model::Bool                                = true,
    num_cycles_to_lay_off::Int                       = 10,
    company_events_satisfaction_boost::Number        = 1.1,
    company_recognition_level::Number                = 1.0,
    dispute_avarage_rate_of_occurencce::Int          = 4,
    dispute_avarage_number_of_employees::Int         = 10,
    dispute_satisfaction_boost::Number               = 1.15,
    dispute_satisfaction_decrease::Number            = 0.7,
    maximum_number_of_employees_in_a_project::Int    = 30,
    minimum_number_of_employees_in_a_project::Int    = 20,
    maximum_number_of_projects_per_department::Int   = 5,
    minimum_number_of_projects_per_department::Int   = 0,
    prob_company_events_per_cycle::Number            = 0.01,
    prob_finding_new_job::Number                     = 0.15,
    prob_lateral_relocation_acceptance::Number       = 0.1,
    prob_project_creation_per_cycle::Number          = 0.5,
    prob_remote_work_acceptance::Number              = 0.1,
    project_duration_span::Tuple{Int, Int}           = (10, 100),
    project_innovation_level::Number                 = 0.8,
    project_schedule_predictability::Number          = 0.1,
    lateral_relocation_satisfaction_boost::Number    = 1.3,
    lateral_relocation_satisfaction_decrease::Number = 0.97,
    lay_off_satisfaction_decrease::Number            = 0.9,
    lay_off_satisfaction_boost::Number               = 1.1,
    remote_work_satisfaction_boost::Number           = 1.3,
    remote_work_satisfaction_decrease::Number        = 0.97
)
    T = Float64

    # The simulation space is very simple. You have one node per department and
    # the agents are randomly placed in them.
    space = SimpleGraph(number_of_departments) |> GraphSpace

    # For each department, create the projects and assign employees.
    projects_per_department = Vector{Vector{Project}}(undef, number_of_departments)

    # Create the properties dictionary.
    properties = (;
        debug_agent,
        debug_model,
        num_cycles_to_lay_off,
        company_events_satisfaction_boost,
        company_recognition_level,
        dispute_avarage_rate_of_occurencce,
        dispute_avarage_number_of_employees,
        dispute_satisfaction_boost,
        dispute_satisfaction_decrease,
        maximum_number_of_employees_in_a_project,
        minimum_number_of_employees_in_a_project,
        maximum_number_of_projects_per_department,
        minimum_number_of_projects_per_department,
        prob_company_events_per_cycle,
        prob_finding_new_job,
        prob_lateral_relocation_acceptance,
        prob_project_creation_per_cycle,
        prob_remote_work_acceptance,
        project_duration_span,
        project_innovation_level,
        project_schedule_predictability,
        projects_per_department,
        lateral_relocation_satisfaction_boost,
        lateral_relocation_satisfaction_decrease,
        lay_off_satisfaction_decrease,
        lay_off_satisfaction_boost,
        remote_work_satisfaction_boost,
        remote_work_satisfaction_decrease
    )

    # Create the model.
    model = ABM(Employee{T}, space; properties)

    # Projects
    # ==========================================================================

    for pos in positions(model)
        projects_in_department = Project[]

        for _ in 1:number_of_projects_per_department
            new_project, ~, ~ = create_project!(model, pos)
            push!(projects_in_department, new_project)
        end

        projects_per_department[pos] = projects_in_department
    end

    # Lay-off position
    # ==========================================================================

    # The last position in the model contains all the employees in lay off.
    add_node!(model)

    return model
end
