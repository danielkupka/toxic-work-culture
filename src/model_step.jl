# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Model step function.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function model_step!(model)
    # First, remove all agents that left the company in the previous step.
    for a in allagents(model)
        a.left && kill_agent!(a, model)
    end

    # Unpack
    # ==========================================================================

    company_recognition_level = model.properties.company_recognition_level

    company_events_satisfaction_boost =
        model.properties.company_events_satisfaction_boost

    debug_model = model.properties.debug_model

    dispute_avarage_rate_of_occurencce =
        model.properties.dispute_avarage_rate_of_occurencce

    dispute_avarage_number_of_employees =
        model.properties.dispute_avarage_number_of_employees

    dispute_satisfaction_boost = model.properties.dispute_satisfaction_boost

    dispute_satisfaction_decrease = model.properties.dispute_satisfaction_decrease

    minimum_number_of_projects_per_department =
        model.properties.minimum_number_of_projects_per_department

    maximum_number_of_projects_per_department =
        model.properties.maximum_number_of_projects_per_department

    num_cycles_to_lay_off = model.properties.num_cycles_to_lay_off

    lay_off_satisfaction_decrease =
        model.properties.lay_off_satisfaction_decrease

    lay_off_satisfaction_boost = model.properties.lay_off_satisfaction_boost

    prob_company_events_per_cycle =
        model.properties.prob_company_events_per_cycle

    prob_project_creation_per_cycle =
        model.properties.prob_project_creation_per_cycle

    # Auxiliary variables
    # ==========================================================================

    lay_off_pos = lay_off_position(model)

    # Update variables in agents
    # ==========================================================================

    lay_off = false

    for a in allagents(model)
        if isnothing(a.project)
            a.num_cycles_without_project += 1

            # Check if the employee must be laid off.
            if a.num_cycles_without_project ≥ num_cycles_to_lay_off
                move_agent!(a, lay_off_pos, model)
                lay_off = true
            end
        else
            a.num_cycles_without_project = 0
        end
    end

    # In case we have a lay-off, we need to decrease the satisfaction of all
    # employees.
    lay_off && apply_satisfaction_factor_to_all!(model, lay_off_satisfaction_decrease)

    # Cycle projects
    # ==========================================================================

    projects_per_department = model.properties.projects_per_department

    for pos in positions(model)
        pos == lay_off_pos && continue

        agents = agents_in_position(pos, model)

        i = 1

        while i ≤ length(projects_per_department[pos])
            project = projects_per_department[pos][i]

            project.cycles_to_finish -= 1

            # If the project duration reached the end, kill it by removing from
            # all the agents and also removing from the vector.
            if project.cycles_to_finish ≤ 0
                # Apply the satisfaction boost related to the company
                # recognition level to all employees that worked in this
                # project.
                for a in agents
                    if a.project == project
                        apply_satisfaction_factor!(a, company_recognition_level)
                    end
                end

                kill_project!(agents, project)
                deleteat!(projects_per_department[pos], i)
            else
                num_employees = count_employees_in_a_project(agents, project)

                # If the number of employees if below the minimum, fill it with more
                # employees.
                if num_employees < project.minimum_number_of_employees
                    Δ = project.minimum_number_of_employees - num_employees

                    for _ in 1:Δ
                        agent_id, ~, ~ = get_employee_for_project(model, pos)
                        model.agents[agent_id].project = project
                    end
                end

                i += 1
            end
        end
    end

    # Try new projects
    # ==========================================================================

    for pos in positions(model)
        pos == lay_off_pos && continue

        num_projects = length(projects_per_department[pos])
        num_projects ≥ maximum_number_of_projects_per_department && continue

        # Make sure we have at least the minimum number of projects.
        if num_projects < minimum_number_of_projects_per_department
            for _ in 1:(minimum_number_of_projects_per_department - num_projects)
                new_project, from_lay_off, num_employees_hired =
                    create_project!(model, pos)

                push!(projects_per_department[pos], new_project)

                debug_model && @info "[MODEL] New project created at department $pos."

                if from_lay_off
                    debug_model && @info "    Laid off employees were reintegrated."
                    apply_satisfaction_factor_to_all!(model, lay_off_satisfaction_boost)
                end

                if debug_model && (num_employees_hired > 0)
                    @info "    $(num_employees_hired) new employees were hired."
                end
            end
        end

        s = rand()

        if s ≤ prob_project_creation_per_cycle
            new_project, from_lay_off, num_employees_hired =
            create_project!(model, pos)

            push!(projects_per_department[pos], new_project)

            debug_model && @info "[MODEL] New project created at department $pos."

            if from_lay_off
                debug_model && @info "    Laid off employees were reintegrated."
                apply_satisfaction_factor_to_all!(model, lay_off_satisfaction_boost)
            end

            if debug_model && (num_employees_hired > 0)
                @info "    $(num_employees_hired) new employees were hired."
            end
        end
    end

    # Dispute between agents
    # ==========================================================================

    for pos in positions(model)
        pos == lay_off_pos && continue

        agents = agents_in_position(pos, model) |> collect

        # If the department does not have any agent, then we cannot have a
        # dispute.
        isempty(agents) && continue

        # For each department, select the number of disputes.
        nd = rand(Poisson(dispute_avarage_rate_of_occurencce))

        for i in 1:nd
            # Randomly select the number of employees in the department
            # involved in the dispute.
            ne = rand(Poisson(dispute_avarage_number_of_employees))
            ve = rand(agents, ne) |> unique
            ne = length(ve)
            ne == 0 && continue

            debug_model && @info "[MODEL] Dispute started between $ne employees in department $pos."

            # In this case, only one employee can be the winner and all have the
            # same probability to win.
            ~, winner_id = rand(ne) |> findmax

            for j in 1:ne
                if j != winner_id
                    apply_satisfaction_factor!(ve[j], dispute_satisfaction_decrease)
                else
                    apply_satisfaction_factor!(ve[j], dispute_satisfaction_boost)
                end
            end
        end
    end

    # Company events
    # ==========================================================================

    s = rand()

    if s < prob_company_events_per_cycle
        debug_model && @info "[MODEL] Company event happened."
        apply_satisfaction_factor_to_all!(model, company_events_satisfaction_boost)
    end

    return nothing
end
