using Statistics
using Survey
using Survey: SurveyDesign, ReplicateDesign

"""
    var_srs(var::Symbol, srs::SurveyDesign)

Estimate the variance of a variable under simple random sampling (SRS).
Returns the estimated variance of the mean.
"""
function var_srs(var::Symbol, srs::SurveyDesign)
    x = srs.data[!, var]  # Proper indexing into DataFrame column

    # Handle missing values
    non_missing = .!ismissing.(x)
    x_clean = x[non_missing]

    # Get weights (if available) or use equal weights
    w = hasproperty(srs, :weights) ? srs.weights[non_missing] : ones(length(x_clean))

    # Weighted mean
    μ = sum(w .* x_clean) / sum(w)

    # Weighted variance
    v = sum(w .* (x_clean .- μ).^2) / sum(w)

    # Return variance of the mean
    return v / sum(w)
end

"""
    deff(var::Symbol, srs::SurveyDesign, reps::ReplicateDesign) -> Float64

Compute the design effect (Deff) for a variable in a complex survey.
"""
function deff(var::Symbol, srs::SurveyDesign, reps::ReplicateDesign)
    # Variance under actual (replicate) design
    mean_result = Survey.mean(var, reps)
    @assert nrow(mean_result) == 1 "Survey.mean must return a DataFrame with one row."

    se_actual = first(mean_result[!, :SE])
    var_actual = se_actual^2

    # Variance under SRS
    var_simple = var_srs(var, srs)

    return var_actual / var_simple
end
