using Survey
using Test, Random

apisrs = load_data("apisrs")

@show names(apisrs)
@show first(apisrs, 3)

srs = SurveyDesign(apisrs; weights=:pw)
Random.seed!(1234)

try
    bsrs = bootweights(srs; replicates=1000)
catch e
    @error "bootweights failed" exception=e
    @test false  # Fail fast and explicitly
end

@testset "Design Effect" begin
    try
        d = deff(:api99, srs, bsrs)
        @test d > 0.5 && d < 3.0
    catch e
        @error "Design Effect test errored" exception=e
        @test false
    end
end

@testset "Different Replicates" begin
    try
        Random.seed!(1234)
        bsrs2 = bootweights(srs; replicates=500)
        d2 = deff(:api99, srs, bsrs2)
        d_ref = deff(:api99, srs, bsrs)
        @test abs(d2 - d_ref) > 1e-3
    catch e
        @error "Different Replicates test errored" exception=e
        @test false
    end
end

@testset "Different Weights" begin
    try
        apisrs_alt = deepcopy(apisrs)
        apisrs_alt[!, :pw_alt] .= apisrs_alt.pw .* 1.1
        srs_alt = SurveyDesign(apisrs_alt; weights=:pw_alt)
        bsrs_alt = bootweights(srs_alt; replicates=1000)
        d_alt = deff(:api99, srs_alt, bsrs_alt)
        d_ref = deff(:api99, srs, bsrs)
        @test abs(d_alt - d_ref) > 1e-3
    catch e
        @error "Different Weights test errored" exception=e
        @test false
    end
end

@testset "Different Variables" begin
    try
        d_api00 = deff(:api00, srs, bsrs)
        d_api99 = deff(:api99, srs, bsrs)
        @test abs(d_api00 - d_api99) > 1e-3
    catch e
        @error "Different Variables test errored" exception=e
        @test false
    end
end

@testset "Missing Values" begin
    try
        apisrs_missing = deepcopy(apisrs)
        apisrs_missing[1:10, :api99] .= missing
        srs_missing = SurveyDesign(apisrs_missing; weights=:pw)
        bsrs_missing = bootweights(srs_missing; replicates=1000)
        d_missing = deff(:api99, srs_missing, bsrs_missing)
        @test d_missing > 0  # assumes internal missing handling
    catch e
        @error "Missing Values test errored" exception=e
        @test false
    end
end

