# Design Effect (`deff`)

The **Design Effect (Deff)** is a key metric in survey sampling that quantifies how much more (or less) variable an estimate is under a complex sampling design compared to a simple random sample (SRS) of the same size.

Formally:

```math
\text{Deff} = \frac{\text{Var}_{\text{complex}}}{\text{Var}_{\text{SRS}}}
````

Where:

* `Var_complex` is the variance under the actual survey design (usually estimated via bootstrap or replication).
* `Var_SRS` is the variance assuming simple random sampling.

A `Deff` greater than 1 means that the complex design results in greater variance (less efficiency), typically due to clustering. A `Deff` less than 1 suggests gains in precision, e.g., from stratification.

---

## Usage

```julia
deff(var::Symbol, srs::SurveyDesign, reps::ReplicateDesign) -> Float64
```

### Arguments:

* `var`: The variable to compute the design effect for.
* `srs`: A [`SurveyDesign`](@ref) object representing a simple random sample design.
* `reps`: A [`ReplicateDesign`](@ref) object, e.g. produced via `bootweights(...)`.

```@example
using Survey

# Load sample dataset and construct designs
apisrs = load_data("apisrs")
srs = SurveyDesign(apisrs; weights=:pw)
bsrs = bootweights(srs; replicates=500)

# Compute Deff for api99
deff(:api99, srs, bsrs)
```

## Interpretation

If:

* `Deff ≈ 1`: Your sampling design behaves like an SRS.
* `Deff > 1`: Loss of precision due to clustering or unequal weights.
* `Deff < 1`: Gain in precision due to stratification or post-stratification.

## References

* Lohr, S. (2010). *Sampling: Design and Analysis*, 2nd Ed., Section 7.5.
* Rust, K. F., & Rao, J. N. K. (1996). [Variance estimation for complex surveys using replication techniques](https://journals.sagepub.com/doi/abs/10.1177/096228029600500305). *Statistical Methods in Medical Research*, 5(3), 283–310.