using Survey
using Test
using Random
using Missings: allowmissing
using DataFrames

apisrs = load_data("apisrs")
srs = SurveyDesign(apisrs; weights=:pw)
Random.seed!(1234)
bsrs = bootweights(srs; replicates=1000)

@testset "Design Effect" begin
    # Ensure column is accessed using symbol as column name
    x = srs.data[:, :api99]  # pre-check access
    d = deff(:api99, srs, bsrs)
    @test d > 0.5 && d < 3.0
end

@testset "Different Replicates" begin
    bsrs2 = bootweights(srs; replicates=500)
    d2 = deff(:api99, srs, bsrs2)
    d_ref = deff(:api99, srs, bsrs)
    @test abs(d2 - d_ref) > 1e-3
end

@testset "Different Weights" begin
    apisrs_alt = deepcopy(apisrs)

    # Introduce a non-uniform perturbation to weights
    perturbation = 1 .+ 0.1 .* randn(length(apisrs_alt.pw))
    apisrs_alt[!, :pw_alt] .= apisrs_alt.pw .* perturbation

    srs_alt = SurveyDesign(apisrs_alt; weights=:pw_alt)
    bsrs_alt = bootweights(srs_alt; replicates=1000)

    d_alt = deff(:api99, srs_alt, bsrs_alt)
    d_ref = deff(:api99, srs, bsrs)

    @test abs(d_alt - d_ref) > 1e-3
end

@testset "Different Variables" begin
    d_api00 = deff(:api00, srs, bsrs)
    d_api99 = deff(:api99, srs, bsrs)
    @test abs(d_api00 - d_api99) > 1e-3
end

@testset "Missing Values" begin
    apisrs_missing = deepcopy(apisrs)

    # Ensure column allows missing values and then inject missing data
    apisrs_missing[!, :api99] = allowmissing(apisrs_missing[!, :api99])
    apisrs_missing[1:10, :api99] .= missing

    # Drop rows with missing values
    apisrs_clean = dropmissing(apisrs_missing, :api99)

    srs_clean = SurveyDesign(apisrs_clean; weights=:pw)
    bsrs_clean = bootweights(srs_clean; replicates=1000)

    d_missing = deff(:api99, srs_clean, bsrs_clean)
    @test d_missing > 0
end
