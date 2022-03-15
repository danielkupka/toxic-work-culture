# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions related to the employees.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Apply a satisfaction factor to an employee.
function apply_satisfaction_factor!(employee, satisfaction_factor)
    employee.satisfaction = clamp(
        employee.satisfaction * satisfaction_factor,
        0,
        1
    )
    return nothing
end

# Apply a satisfaction factor to all employees.
function apply_satisfaction_factor_to_all!(model, satisfaction_factor)
    lay_off_pos = lay_off_position(model)

    for employee in allagents(model)
        if employee.pos != lay_off_pos
            apply_satisfaction_factor!(employee, satisfaction_factor)
        end
    end

    return nothing
end

# Create a new employee in the model.
function create_new_employee!(model, department = nothing)
    # Sample the satisfaction levels to take into account the specificities of
    # each employee.
    vs = rand(3) |> sort

    minimum_satisfaction_for_proposing_remote_work        = vs[3]
    minimum_satisfaction_for_proposing_lateral_relocation = vs[2]
    minimum_satisfaction_for_searching_job                = vs[1]

    # Create the information about the workload satisfaction.
    workload_satisfaction_factor = rand() * 1e-1

    if isnothing(department)
        return add_agent!(
            model;
            satisfaction = 1.0,
            minimum_satisfaction_for_proposing_lateral_relocation,
            minimum_satisfaction_for_proposing_remote_work,
            minimum_satisfaction_for_searching_job,
            workload_satisfaction_factor
        )
    else
        return add_agent!(
            department,
            model;
            satisfaction = 1.0,
            minimum_satisfaction_for_proposing_lateral_relocation,
            minimum_satisfaction_for_proposing_remote_work,
            minimum_satisfaction_for_searching_job,
            workload_satisfaction_factor
        )
    end
end

# Get an employee for a project.
function get_employee_for_project(model, department)
    agents = agents_in_position(department, model)

    from_lay_off = false
    num_employees_hired = 0

    # Try to get an agent from the lay off.
    agent_id = sample_employee_in_lay_off(model)

    if isnothing(agent_id)
        # Try to get an agent without a project.
        agent_id = sample_employee_without_project(agents)

        if isnothing(agent_id)
            # Hire a new employee.
            agent = create_new_employee!(model, department)
            agent_id = agent.id
            num_employees_hired += 1
        end

    else
        from_lay_off = true
        move_agent!(model.agents[agent_id], department, model)
    end

    return agent_id, from_lay_off, num_employees_hired
end

# Sample an employee without a project.
function sample_employee_without_project(agents)
    v = findall(x -> isnothing(x.project), agents)

    if !isempty(v)
        id = v |> rand
        return iterate(agents, id)[1].id
    else
        return nothing
    end
end

# Sample an employee currently in lay off.
function sample_employee_in_lay_off(model)
    lay_off_pos = lay_off_position(model)
    agents = agents_in_position(lay_off_pos, model)

    if length(agents) > 0
        s = agents |> collect |> rand
        return s.id
    else
        return nothing
    end
end

