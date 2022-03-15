# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Function to run the simulation.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function run_simulation(model)
    adf, mdf = run!(
        model,
        agent_step!,
        model_step!,
        terminate;
        agents_first = false,
        adata = [
            (x -> true, count),
            (:left, count)
        ]
    )

    # Rename columns.
    DataFrames.rename!(adf, 2 => :total, 3 => :left)

    return adf, mdf
end

function terminate(model, step)
    if (step > 1000) || (length(allagents(model)) == 0)
        return true
    else
        return false
    end
end
