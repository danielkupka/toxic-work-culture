# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Agent step function.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function agent_step!(employee::Employee, model)
    # Unpack
    # ==========================================================================

    # Fields related with the model properties
    # --------------------------------------------------------------------------

    debug_agent = model.properties.debug_agent

    lateral_relocation_satisfaction_boost =
        model.properties.lateral_relocation_satisfaction_boost

    lateral_relocation_satisfaction_decrease =
        model.properties.lateral_relocation_satisfaction_decrease

    project_innovation_level = model.properties.project_innovation_level

    project_schedule_predictability = model.properties.project_schedule_predictability

    prob_finding_new_job = model.properties.prob_finding_new_job

    prob_lateral_relocation_acceptance =
        model.properties.prob_lateral_relocation_acceptance

    prob_remote_work_acceptance =
        model.properties.prob_remote_work_acceptance

    remote_work_satisfaction_boost =
        model.properties.remote_work_satisfaction_boost

    remote_work_satisfaction_decrease =
        model.properties.remote_work_satisfaction_decrease

    # Fields related with the employee
    # --------------------------------------------------------------------------

    satisfaction = employee.satisfaction

    minimum_satisfaction_for_proposing_lateral_relocation =
        employee.minimum_satisfaction_for_proposing_lateral_relocation

    minimum_satisfaction_for_proposing_remote_work =
        employee.minimum_satisfaction_for_proposing_remote_work

    minimum_satisfaction_for_searching_job =
        employee.minimum_satisfaction_for_searching_job

    # Check current action
    # ==========================================================================

    action = nothing

    if satisfaction < minimum_satisfaction_for_searching_job
        action = :search_job

    elseif satisfaction < minimum_satisfaction_for_proposing_lateral_relocation
        if !employee.was_relocated
            action = :try_lateral_relocation
        end

    elseif satisfaction < minimum_satisfaction_for_proposing_remote_work
        if !employee.remote_work
            action = :try_remote_work
        end
    end

    # Execute actions
    # ==========================================================================

    satisfaction_factor = 1.0

    if action == :try_remote_work
        debug_agent && @info "[EMPLOYEE] Employee requested remote work:"
        s = rand()

        if s < prob_remote_work_acceptance
            debug_agent && @info "    Remote work was accepted."
            employee.remote_work = true
            satisfaction_factor = remote_work_satisfaction_boost
        else
            debug_agent && @info "    Remote work was rejected."
            satisfaction_factor = remote_work_satisfaction_decrease
        end


    elseif action == :try_lateral_relocation
        debug_agent && @info "[EMPLOYEE] Employee requested lateral relocation:"

        # Let's try to find a project in another department.
        new_department, new_project =
            sample_available_project_in_other_department(model, employee.pos)

        if !isnothing(new_department)
            s = rand()
            if s < prob_lateral_relocation_acceptance
                debug_agent && @info "    Rellocation was accepted."
                move_agent!(employee, new_department, model)
                employee.project = new_project
                employee.was_relocated = true
                satisfaction_factor = lateral_relocation_satisfaction_boost

            else
                debug_agent && @info "    Rellocation was rejected."
                satisfaction_factor = lateral_relocation_satisfaction_decrease
            end

        else
            debug_agent && @info "    No available proejct was found."
        end

    elseif action == :search_job
        debug_agent && @info "[EMPLOYEE] Employee started searching for a new job:"

        s = rand()

        if s < prob_finding_new_job
            debug_agent && @info "    New job found, employee left the company."
            employee.left = true
        else
            debug_agent && @info "    New job not found."

        end
    end

    # Update the satisfaction given the projects
    # ==========================================================================

    if !isnothing(employee.project)
        project = employee.project

        agents = agents_in_position(employee.pos, model)
        total_employees = count_employees_in_a_project(agents, project)

        # Compute the workload per employee.
        emin     = project.minimum_number_of_employees
        emax     = project.maximum_number_of_employees
        mid      = (emin + emax) / 2
        workload = 2 * (total_employees - mid) / (emax - emin)
        factor   = 1 + workload * employee.workload_satisfaction_factor

        # Compute the workload satisfaction decrease.
        apply_satisfaction_factor!(employee, factor)
    end

    return nothing
end
