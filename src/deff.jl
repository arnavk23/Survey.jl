using Statistics
using Survey
using Survey: SurveyDesign, ReplicateDesign

"""
    var_srs(var::Symbol, srs::SurveyDesign)
Estimate the variance of a variable under simple random sampling (SRS).
This function assumes unweighted SRS unless weights are provided in the `SurveyDesign`.
Returns the estimated variance of the mean.
"""
function var_srs(var::Symbol, srs::SurveyDesign)
    col_data = srs.data[!, var]
    non_missing = .!ismissing.(col_data)
    x_clean = col_data[non_missing]

    # get the actual weight column using the symbol stored in srs.weights
    weight_col = srs.data[!, srs.weights]
    w_clean = weight_col[non_missing]

    # fallback to equal weights if weights aren't provided
    w = isnothing(w_clean) ? ones(length(x_clean)) : w_clean

    # Calculate weighted mean
    weighted_sum = sum(w .* x_clean)
    sum_weights = sum(w)
    μ = weighted_sum / sum_weights

    # Weighted variance
    squared_deviations = (x_clean .- μ).^2
    v = sum(w .* squared_deviations) / sum_weights

    return v / length(x_clean)
end

"""
    deff(var::Symbol, srs::SurveyDesign, reps::ReplicateDesign) -> Float64

Compute the **design effect (Deff)** for a given variable in a complex survey.

Deff is defined as:
    Deff = Var_actual / Var_srs

Where:
- `Var_actual` is the variance estimated from the replicate-based design (`ReplicateDesign`)
- `Var_srs` is the closed-form variance under a simple random sample (`SurveyDesign`)

# Arguments
- `var::Symbol`: The variable for which the design effect is to be calculated.
- `srs::SurveyDesign`: The base survey design assuming simple random sampling.
- `reps::ReplicateDesign`: The replicate design used to estimate actual variance.

# Returns
- `Float64`: The computed design effect.

# Example
```julia
apisrs = load_data("apisrs")
srs = SurveyDesign(apisrs; weights=:pw)
bsrs = bootweights(srs; replicates=1000)
deff(:api99, srs, bsrs)
```
"""
function deff(var::Symbol, srs::SurveyDesign, reps::ReplicateDesign)
    # Using Survey.mean to extract the standard error (SE) is efficient because it directly
    # computes the mean and associated SE from the replicate design, avoiding manual calculations.
    mean_result = Survey.mean(var, reps)
    @assert nrow(mean_result) == 1 "Survey.mean must return a DataFrame with exactly one row."
    se_actual = mean_result[!, :SE]
    var_actual = first(se_actual)^2

    # Variance under SRS (from AnalyticSolution branch or replicate formula)
    var_srs_val = Survey.var_srs(var, srs)

    return var_actual / var_srs_val
end
