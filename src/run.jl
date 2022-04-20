# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Function to run the simulation.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function monte_carlo(number_of_runs::Int, number_of_epochs::Int; kwargs...)
    results = Vector{DataFrame}(undef, number_of_runs)

    for k in 1:number_of_runs
        @info "Run #$k..."
        model = initialize_model(; kwargs...)

        adata = nothing
        mdata = nothing

        for _ in 1:number_of_epochs
            adata, mdata = run_simulation(model)
        end

        results[k] = adata
    end

    # Compute the values.
    step  = vcat(map(x -> x.step,  results)...)
    total = vcat(map(x -> x.total, results)...)
    left  = vcat(map(x -> x.left,  results)...)
    run   = vcat([ones(Int, length(results[k].step)) * k for k in 1:number_of_runs]...)

    # Compute the DataFrame with the result.
    df = DataFrame(
        step  = step,
        total = total,
        left  = left,
        run   = run,
    )

    return df
end

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
    if (step ≥ model.properties.number_of_steps) || (length(allagents(model)) == 0)
        return true
    else
        return false
    end
end
