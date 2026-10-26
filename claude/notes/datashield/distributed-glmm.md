# Distributed GLMM (pooled mixed models across DataSHIELD nodes)

Goal: pool mixed-effects models across servers like `ds.glm` does for GLMs, estimating
fixed effects, random-effect (co)variances and the random effects themselves.
Requirements (2026-10-15): Poisson, binomial, Gaussian; random intercept + slope; the
grouping factor (hospital) **spans studies** — the same hospital appears on several
servers. Typically 6–7 groups, sometimes many.

Scripts (both run locally, no servers — each "study" is a separate data frame):
- `distributed-glmm/study-intercept-check.R` — random intercept per study (grouping = study).
- `distributed-glmm/crossed-hospital-check.R` — hospital spans studies, intercept + slope,
  all three families. **This is the design to build on.**

Run: `Rscript ~/dotfiles/claude/notes/datashield/distributed-glmm/crossed-hospital-check.R`
(needs lme4, statmod, MASS).

## Original user code (ds.glmm / glmmDS) — problems found
- Simplex loop removes the vertex with the **smallest** `lq` (= −2·loglik, i.e. the best)
  and adds the centroid with no reflection/expansion — it shrinks, it does not optimise.
- ψ fixed at 13, never estimated. `bMatrix` drawn from `mvrnorm` with a random `G` and never
  updated — adaptive quadrature centred on a random point, not the mode.
- Server: nodes need `b̂ + √2·z/R` for `fastGHQuad` (e^{−x²}) nodes; code had `b̂ + z/R`.
  (Client already applies `exp(z²)` in W, `1/R` and `−½ log ψ` in `lq`.) Overflow: work on
  log scale. Hard-coded columns `inter`, `X`, `Treat`, `Y`; Poisson hard-coded; `G`, `q`
  unused; `eval(parse())` on inputs.

## Why the grouping-spans-studies case needs a different design
If each random effect's data sits on one server, total loglik = Σ per-server terms and each
server can return one number. A hospital on servers A and B contributes
`log ∫ f_A(y_A|b) f_B(y_B|b) φ(b) db` — the log of an integral of a product, which does not
split into per-server terms. It is still fittable without sharing raw data, because
everything the client needs **per hospital** is a sum over servers.

## Design (validated)
Per candidate θ = (β, L, σ² for Gaussian), with `b = L·u`, `u ~ N(0, I)` (lme4's
parametrisation — Σ never inverted, a variance can hit 0; diag(L) ≥ 0 via L-BFGS-B):
1. **Mode rounds** (~5–10): client sends each hospital's current `b`; each server returns per
   hospital `Σ ll`, gradient `Z'(y−μ)/φ`, curvature `−Z'VZ/φ` (canonical links). Client sums
   over servers, maps to u (`g_u = L'g_b − u`, `H_u = L'H_bL − I`), damped Newton step
   (halve a step that lowered the objective).
2. **Quadrature round**: client sends AGQ points per hospital (`û + √2·A·z`, `A = chol((−H_u)⁻¹)`,
   product grid of `nAGQ^q` points, mapped to b); servers return per-hospital loglik at each.
   Client: `log L_h = (q/2)log2 + log|A| + logsumexp(log w + z'z + ll + log φ_q(u))`.
3. Client optimises `−Σ_h log L_h` over θ (L-BFGS-B). Recompute modes at the final θ for b̂.
For Gaussian, Laplace (`nAGQ=1`) is exact, so the same code gives the exact LMM.

## Results vs lme4 on pooled data (seed 11/12, 7 hospitals over 4 studies)
| Case | max Δβ | max ΔΣ | max Δb̂ | logLik dist / lme4 | server rounds |
|---|---|---|---|---|---|
| Poisson, int+slope, Laplace | 2.8e-6 | 2.9e-6 | 4.2e-6 | −1529.795 / −1529.795 | 2107 |
| Binomial, int+slope, Laplace | 3.4e-5 | 2.8e-5 | 3.9e-5 | −862.613 / −862.613 | 1420 |
| Gaussian, int+slope (exact) | 6.2e-6 | 2.6e-4 | 3.0e-5 | −1900.052 / −1900.052 | 1892 |
| Poisson, intercept, nAGQ=5 | 2.7e-6 | 6.1e-6 | 2.8e-6 | −3002.839 / −1064.006 | 896 |
| Binomial, intercept, nAGQ=5 | 4.9e-6 | 1.3e-6 | 5.3e-6 | −890.279 / −890.279 | 803 |

Per-study random intercept (study-intercept-check.R, 8 studies, Poisson): matches glmer to
~1e-5 (Laplace) / ~2e-6 (nAGQ 5, 10), SEs from `optim(hessian=TRUE)` match too.

glmer's reported logLik for **Poisson at nAGQ>1** differs from ours by a parameter-free
constant (estimates match); it is NOT `Σ lgamma(y+1)` (checked). Binomial nAGQ>1 matches
exactly, so our AGQ is right. Cause not traced. lme4 itself only allows nAGQ>1 for a single
scalar random effect, so comparisons with slopes are Laplace only.

## Open
- **Communication cost**: 800–2100 server rounds per fit — too many for real DataSHIELD.
  Driver: finite-difference gradients in L-BFGS-B × Newton rounds per evaluation. Next step:
  servers also return the sums needed for analytic gradients w.r.t. β and L. Not built.
- **Disclosure**: servers release per-hospital sums at client-chosen β and b; the client learns
  which hospitals each study holds. Need a minimum-size rule per (study, hospital) cell and a
  policy for cells below it (suppressing biases the fit). Repeated queries at chosen β can in
  principle reveal the distribution of individual x (same exposure class as `glmDS2`).
- Hospital identifiers must be harmonised across studies.
- Not yet turned into `glmmDS` / `ds.glmm` (formula parsing, `.loadServersideObject`,
  `nfilter` checks).
