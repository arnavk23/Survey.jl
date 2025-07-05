using Survey
using Test
using Random
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

@testset "Match R: SRS vs Cluster" begin
    using Survey

    apiclus1 = load_data("apiclus1")
    clus = SurveyDesign(apiclus1; weights=:pw, ids=:dnum, fpc=:fpc)
    rclus = bootweights(clus; replicates=1000)

    dclus = deff(:api00, clus, rclus)
    dsrs = deff(:api00, srs, bsrs)

    @test isapprox(dsrs, 1.03, atol=0.2)   # SRS from R
    @test dclus > 5.0                      # DEFF in cluster sample is large
end
