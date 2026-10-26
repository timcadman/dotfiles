# Check: distributed Poisson random-intercept GLMM (one random intercept per study)
# fitted by summing per-study adaptive Gauss-Hermite log-likelihoods, vs lme4::glmer
# on the pooled data with the same nAGQ.

suppressMessages(library(lme4))

# ---- "server" side: sees only its own study's data -------------------------
find_mode <- function(eta0, y, psi) {
  objective <- function(b) sum(y * b - exp(eta0 + b)) - b^2 / (2 * psi)
  b <- 0
  for (it in 1:100) {
    mu <- exp(eta0 + b)
    step <- (sum(y - mu) - b / psi) / (sum(mu) + 1 / psi)
    while (objective(b + step) < objective(b) && abs(step) > 1e-12) step <- step / 2
    b <- b + step
    if (abs(step) < 1e-10) break
  }
  b
}

log_integrand <- function(b, eta0, y, psi) {
  sum(y * (eta0 + b) - exp(eta0 + b) - lgamma(y + 1)) - b^2 / (2 * psi) - 0.5 * log(2 * pi * psi)
}

study_loglik <- function(X, y, beta, log_psi, z, w) {
  psi <- exp(log_psi)
  eta0 <- drop(X %*% beta)
  b_hat <- find_mode(eta0, y, psi)
  sigma <- 1 / sqrt(sum(exp(eta0 + b_hat)) + 1 / psi)
  nodes <- b_hat + sqrt(2) * sigma * z
  terms <- log(w) + z^2 + vapply(nodes, log_integrand, numeric(1), eta0 = eta0, y = y, psi = psi)
  m <- max(terms)
  list(loglik = log(sqrt(2) * sigma) + m + log(sum(exp(terms - m))), b_hat = b_hat)
}

# ---- "client" side: only ever sees per-study log-likelihoods and b_hat -----
fit_distributed <- function(studies, nAGQ) {
  gh <- statmod::gauss.quad(nAGQ, kind = "hermite")
  neg_loglik <- function(theta) {
    p <- length(theta) - 1
    -sum(vapply(studies, function(s)
      study_loglik(s$X, s$y, theta[1:p], theta[p + 1], gh$nodes, gh$weights)$loglik, numeric(1)))
  }
  pooled <- do.call(rbind, lapply(studies, function(s) data.frame(s$X, y = s$y)))
  start_beta <- coef(glm(y ~ . - 1, family = poisson, data = pooled))
  opt <- optim(c(start_beta, log(0.1)), neg_loglik, method = "BFGS",
               hessian = TRUE, control = list(reltol = 1e-12, maxit = 500))
  p <- length(start_beta)
  b_hat <- vapply(studies, function(s)
    study_loglik(s$X, s$y, opt$par[1:p], opt$par[p + 1], gh$nodes, gh$weights)$b_hat, numeric(1))
  list(beta = opt$par[1:p], psi = exp(opt$par[p + 1]), loglik = -opt$value,
       se = sqrt(diag(solve(opt$hessian)))[1:p], b_hat = b_hat, convergence = opt$convergence)
}

# ---- simulate ----------------------------------------------------------------
set.seed(2026)
n_studies <- 8
true_beta <- c(0.5, 0.3, -0.4)
true_psi <- 0.25
studies <- lapply(seq_len(n_studies), function(k) {
  n <- sample(150:400, 1)
  X <- cbind(inter = 1, X = rnorm(n), Treat = rbinom(n, 1, 0.5))
  b <- rnorm(1, 0, sqrt(true_psi))
  list(X = X, y = rpois(n, exp(drop(X %*% true_beta) + b)))
})
pooled <- do.call(rbind, lapply(seq_along(studies), function(k)
  data.frame(studies[[k]]$X, y = studies[[k]]$y, study = factor(k))))

# ---- compare -------------------------------------------------------------------
for (q in c(1, 5, 10)) {
  d <- fit_distributed(studies, q)
  g <- glmer(y ~ X + Treat + (1 | study), family = poisson, data = pooled, nAGQ = q)
  cmp <- rbind(
    distributed = c(d$beta, psi = d$psi, logLik = d$loglik),
    glmer       = c(fixef(g), psi = VarCorr(g)$study[1], logLik = as.numeric(logLik(g))))
  cat(sprintf("\n== nAGQ = %d (optim convergence code %d)\n", q, d$convergence))
  print(signif(cmp, 7))
  cat("max |diff| fixed effects:", signif(max(abs(d$beta - fixef(g))), 3),
      "| SE diff:", signif(max(abs(d$se - sqrt(diag(vcov(g))))), 3),
      "| max |diff| b_hat vs ranef:", signif(max(abs(d$b_hat - ranef(g)$study[, 1])), 3), "\n")
}
