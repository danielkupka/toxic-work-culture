# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Functions to sample a project.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Count how many employees are not in a project.
function count_employees_without_project(agents)
    num_agents = 0

    for a in agents
        if isnothing(a.project)
            num_agents += 1
        end
    end

    return num_agents
end

# Count how many employees are in a project.
function count_employees_in_a_project(agents, project)
    num_agents = 0

    for a in agents
        if a.project == project
            num_agents += 1
        end
    end

    return num_agents
end

# Create a new project getting laid off employees, employees without a project,
# and hiring new employees.
function create_project!(model, department)
    agents = agents_in_position(department, model)
    lay_off_pos = lay_off_position(model)

    # Sample a project.
    new_project = sample_project(model)

    # Select the number of employees it will be selected to work in this
    # project.
    n = rand(
        new_project.minimum_number_of_employees:
        new_project.maximum_number_of_employees
    )

    from_lay_off = false
    num_employees_hired = 0

    # Sample agents to participate in this project.
    for i in 1:n
        agent_id, n_lay_off, n_hired = get_employee_for_project(model, department)
        employee = model.agents[agent_id]

        if n_lay_off
            from_lay_off = true
        end

        num_employees_hired += n_hired
        employee.project = new_project

        # Apply the satisfaction modification given the properties of the
        # project.
        apply_satisfaction_factor!(employee, 1 - model.properties.project_innovation_level * 0.05)
        apply_satisfaction_factor!(employee, 1 + model.properties.project_schedule_predictability * 0.05)
    end

    return new_project, from_lay_off, num_employees_hired
end

# Create a project in a department for the simulation initialization.
function initial_project_creation!(model, department)
    agents = agents_in_position(department, model)

    # Sample a project.
    new_project = sample_project(model)

    # Select the number of employees for this project.
    n = rand(
        new_project.minimum_number_of_employees:
        new_project.maximum_number_of_employees
    )

    # Hire the employees.
    for i in 1:n
        employee = create_new_employee!(model, department)
        employee.project = new_project
    end

    return new_project
end

# Remove the project in all agents.
function kill_project!(agents, project)
    # Remove the project in all agents.
    for a in agents
        if a.project == project
            a.project = nothing
        end
    end

    return nothing
end

# Sample a project.
function sample_project(model)
    minimum_number_of_employees_in_a_project =
        model.properties.minimum_number_of_employees_in_a_project

    maximum_number_of_employees_in_a_project =
        model.properties.maximum_number_of_employees_in_a_project

    project_duration_span = model.properties.project_duration_span

    project_duration = rand(project_duration_span[1]:1:project_duration_span[2])

    return Project(
        cycles_to_finish = project_duration,
        maximum_number_of_employees = maximum_number_of_employees_in_a_project,
        minimum_number_of_employees = minimum_number_of_employees_in_a_project,
    )
end

# Sample available project in other department.
function sample_available_project_in_other_department(model, current_department)
    layoff_pos = model |> positions |> last

    # Go throught the departments randomly.
    for pos in (model |> positions |> shuffle)

        if (pos != layoff_pos) && (pos != current_department)

            # Go throught the projects randomly.
            projects = model.properties.projects_per_department[pos]
            agents   = agents_in_position(pos, model)

            for project in (projects |> shuffle)
                # Count the number of employees.
                np = count_employees_in_a_project(agents, project)

                # If the number of employees is lower than the maximum, we can
                # return this project as an available project.
                if np < project.maximum_number_of_employees
                    return pos, project
                end
            end
        end
    end

    return nothing, nothing
end
