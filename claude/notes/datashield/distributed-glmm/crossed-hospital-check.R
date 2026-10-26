# Check: distributed GLMM with a grouping factor (hospital) that spans servers,
# random intercept + slope, Poisson / binomial / Gaussian, vs lme4 on pooled data.
# Servers only ever return per-hospital sums: log-likelihood, gradient, curvature.

suppressMessages(library(lme4))

# ---- family pieces (canonical links) ------------------------------------------
log1pexp <- function(x) ifelse(x > 0, x + log1p(exp(-x)), log1p(exp(x)))
families <- list(
  poisson  = list(ll = function(y, eta, s2) y * eta - exp(eta) - lgamma(y + 1),
                  mu = exp, var = function(mu, s2) mu, phi = function(s2) 1),
  binomial = list(ll = function(y, eta, s2) y * eta - log1pexp(eta),
                  mu = plogis, var = function(mu, s2) mu * (1 - mu), phi = function(s2) 1),
  gaussian = list(ll = function(y, eta, s2) -0.5 * log(2 * pi * s2) - (y - eta)^2 / (2 * s2),
                  mu = identity, var = function(mu, s2) rep(1, length(mu)), phi = function(s2) s2))

# ---- "server" side: one study's rows only ---------------------------------------
server_newton_pieces <- function(srv, fam, beta, s2, b) {
  lapply(setNames(nm = names(srv$rows)), function(h) {
    r <- srv$rows[[h]]; X <- srv$X[r, , drop = FALSE]; Z <- srv$Z[r, , drop = FALSE]; y <- srv$y[r]
    eta <- drop(X %*% beta + Z %*% b[[h]]); mu <- fam$mu(eta); phi <- fam$phi(s2)
    list(ll = sum(fam$ll(y, eta, s2)),
         grad = drop(crossprod(Z, (y - mu) / phi)),
         hess = -crossprod(Z * (fam$var(mu, s2) / phi), Z))
  })
}

server_loglik_at <- function(srv, fam, beta, s2, points) {
  lapply(setNames(nm = names(srv$rows)), function(h) {
    r <- srv$rows[[h]]; X <- srv$X[r, , drop = FALSE]; Z <- srv$Z[r, , drop = FALSE]; y <- srv$y[r]
    eta0 <- drop(X %*% beta)
    apply(points[[h]], 1, function(b) sum(fam$ll(y, eta0 + drop(Z %*% b), s2)))
  })
}

# ---- "client" side ------------------------------------------------------------------
rounds <- 0
sum_over_servers <- function(pieces, h, field) {
  Reduce(`+`, lapply(pieces, function(p) if (is.null(p[[h]])) 0 else p[[h]][[field]]))
}

# Random effects are parametrised as b = L u with u ~ N(0, I), as in lme4, so Sigma is
# never inverted and a variance can sit on its boundary (zero) without breaking the fit.
# Servers only see b = L u; gradients/curvatures come back w.r.t. b and are mapped to u.
to_b <- function(L, u) lapply(u, function(uh) drop(L %*% uh))

u_newton_parts <- function(pieces, h, L, uh) {
  list(obj  = sum_over_servers(pieces, h, "ll") - 0.5 * sum(uh^2),
       grad = drop(t(L) %*% sum_over_servers(pieces, h, "grad")) - uh,
       hess = t(L) %*% sum_over_servers(pieces, h, "hess") %*% L - diag(length(uh)))
}

# Newton on each hospital's concave objective in u; a step that lowers the objective
# is halved on the next round, since the objective at the new point is only known then.
find_modes <- function(servers, fam, beta, s2, L, u) {
  prev <- NULL
  for (it in 1:100) {
    rounds <<- rounds + 1
    pieces <- lapply(servers, server_newton_pieces, fam = fam, beta = beta, s2 = s2, b = to_b(L, u))
    parts <- lapply(setNames(nm = names(u)), function(h) u_newton_parts(pieces, h, L, u[[h]]))
    obj <- vapply(parts, `[[`, numeric(1), "obj")
    if (!is.null(prev) && any(worse <- obj < prev$obj - 1e-12)) {
      prev$steps[worse] <- lapply(prev$steps[worse], `/`, 2)
      u[worse] <- Map(`+`, prev$u[worse], prev$steps[worse])
      next
    }
    steps <- lapply(parts, function(pt) drop(-solve(pt$hess, pt$grad)))
    if (max(abs(unlist(steps))) < 1e-8) break
    prev <- list(obj = obj, u = u, steps = steps)
    u <- Map(`+`, u, steps)
  }
  list(u = u, parts = parts)
}

hospital_logliks <- function(servers, fam, beta, s2, L, modes, nAGQ) {
  q <- nrow(L); gh <- statmod::gauss.quad(nAGQ, kind = "hermite")
  grid_z <- as.matrix(expand.grid(rep(list(gh$nodes), q)))
  grid_w <- apply(as.matrix(expand.grid(rep(list(gh$weights), q))), 1, prod)
  A <- lapply(modes$parts, function(pt) t(chol(solve(-pt$hess))))
  u_pts <- lapply(setNames(nm = names(modes$u)), function(h)
    sweep(sqrt(2) * grid_z %*% t(A[[h]]), 2, modes$u[[h]], `+`))
  b_pts <- lapply(u_pts, function(up) up %*% t(L))
  rounds <<- rounds + 1
  ll <- lapply(servers, server_loglik_at, fam = fam, beta = beta, s2 = s2, points = b_pts)
  vapply(names(modes$u), function(h) {
    data_ll <- Reduce(`+`, lapply(ll, function(p) if (is.null(p[[h]])) 0 else p[[h]]))
    prior <- -0.5 * rowSums(u_pts[[h]]^2) - q / 2 * log(2 * pi)
    terms <- log(grid_w) + rowSums(grid_z^2) + data_ll + prior
    m <- max(terms)
    q / 2 * log(2) + sum(log(diag(A[[h]]))) + m + log(sum(exp(terms - m)))
  }, numeric(1))
}

unpack <- function(theta, p, q, fam_name) {
  L <- matrix(0, q, q); L[lower.tri(L, diag = TRUE)] <- theta[p + seq_len(q * (q + 1) / 2)]
  s2 <- if (fam_name == "gaussian") exp(theta[length(theta)]) else 1
  list(beta = theta[1:p], L = L, s2 = s2)
}

fit_distributed <- function(servers, fam_name, start_beta, hospitals, q, nAGQ = 1) {
  fam <- families[[fam_name]]; p <- length(start_beta)
  u_warm <- setNames(rep(list(rep(0, q)), length(hospitals)), hospitals)
  neg_loglik <- function(theta) {
    th <- unpack(theta, p, q, fam_name)
    modes <- find_modes(servers, fam, th$beta, th$s2, th$L, u_warm)
    u_warm <<- modes$u
    -sum(hospital_logliks(servers, fam, th$beta, th$s2, th$L, modes, nAGQ))
  }
  L0 <- diag(0.3, q); is_diag <- diag(q)[lower.tri(L0, diag = TRUE)] == 1
  extra <- if (fam_name == "gaussian") log(0.3)
  start <- c(start_beta, L0[lower.tri(L0, diag = TRUE)], extra)
  lower <- c(rep(-Inf, p), ifelse(is_diag, 0, -Inf), if (!is.null(extra)) -Inf)
  opt <- optim(start, neg_loglik, method = "L-BFGS-B", lower = lower,
               control = list(factr = 1e2, maxit = 1000))
  th <- unpack(opt$par, p, q, fam_name)
  final <- find_modes(servers, fam, th$beta, th$s2, th$L, u_warm)
  list(beta = th$beta, Sigma = th$L %*% t(th$L), s2 = th$s2, loglik = -opt$value,
       b = to_b(th$L, final$u), convergence = opt$convergence)
}

# ---- simulate: 7 hospitals spread unevenly over 4 studies -------------------------
simulate <- function(fam_name, seed) {
  set.seed(seed)
  n_hosp <- 7; hospitals <- paste0("H", 1:n_hosp)
  Sigma <- matrix(c(0.30, 0.05, 0.05, 0.10), 2)
  b <- MASS::mvrnorm(n_hosp, c(0, 0), Sigma); rownames(b) <- hospitals
  beta <- switch(fam_name, poisson = c(0.5, 0.3, -0.4), binomial = c(-0.3, 0.6, -0.5), gaussian = c(1, 0.5, -0.8))
  servers <- lapply(1:4, function(s) {
    hs <- sort(sample(hospitals, sample(3:6, 1)))
    hosp <- rep(hs, times = sample(40:120, length(hs), replace = TRUE))
    X <- cbind(inter = 1, x = rnorm(length(hosp)), treat = rbinom(length(hosp), 1, 0.5))
    Z <- X[, c("inter", "x")]
    eta <- drop(X %*% beta) + rowSums(Z * b[hosp, ])
    y <- switch(fam_name, poisson = rpois(length(eta), exp(eta)),
                binomial = rbinom(length(eta), 1, plogis(eta)), gaussian = rnorm(length(eta), eta, 1))
    list(X = X, Z = Z, y = y, hosp = hosp, rows = split(seq_along(hosp), hosp))
  })
  list(servers = servers, hospitals = sort(unique(unlist(lapply(servers, `[[`, "hosp")))))
}

pooled_frame <- function(servers) {
  do.call(rbind, lapply(servers, function(s) data.frame(s$X, y = s$y, hospital = s$hosp)))
}

fit_lme4 <- function(fam_name, d, nAGQ) {
  f <- if (nAGQ > 1) y ~ x + treat + (1 | hospital) else y ~ x + treat + (1 + x | hospital)
  if (fam_name == "gaussian") return(lmer(f, data = d, REML = FALSE))
  glmer(f, data = d, family = fam_name, nAGQ = nAGQ)
}

compare <- function(fam_name, nAGQ, seed) {
  sim <- simulate(fam_name, seed); d <- pooled_frame(sim$servers)
  q <- if (nAGQ > 1) 1 else 2
  if (q == 1) sim$servers <- lapply(sim$servers, function(s) { s$Z <- s$Z[, "inter", drop = FALSE]; s })
  start <- coef(glm(y ~ x + treat, family = fam_name, data = d))
  rounds <<- 0
  dist <- fit_distributed(sim$servers, fam_name, start, sim$hospitals, q, nAGQ)
  ref <- fit_lme4(fam_name, d, nAGQ)
  ref_Sigma <- as.matrix(VarCorr(ref)$hospital); attributes(ref_Sigma)[c("stddev", "correlation")] <- NULL
  ref_b <- as.matrix(ranef(ref)$hospital)[sim$hospitals, , drop = FALSE]
  dist_b <- do.call(rbind, dist$b[sim$hospitals])
  cat(sprintf("\n== %s, %s, nAGQ=%d | optim code %d | server rounds %d\n", fam_name,
              if (q == 2) "intercept+slope" else "intercept", nAGQ, dist$convergence, rounds))
  cat(sprintf("  max|diff| beta %.1e | Sigma %.1e | b %.1e | logLik %.4f vs %.4f\n",
              max(abs(dist$beta - fixef(ref))), max(abs(dist$Sigma - ref_Sigma)),
              max(abs(dist_b - ref_b)), dist$loglik, as.numeric(logLik(ref))))
  if (fam_name == "poisson") cat(sprintf("  logLik gap %.4f | sum(lgamma(y+1)) %.4f\n",
                                         as.numeric(logLik(ref)) - dist$loglik, sum(lgamma(d$y + 1))))
}

for (fam_name in c("poisson", "binomial", "gaussian")) compare(fam_name, 1, 11)
for (fam_name in c("poisson", "binomial")) compare(fam_name, 5, 12)
