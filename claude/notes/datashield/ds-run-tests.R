#!/usr/bin/env Rscript
# Run dsBaseClient test file(s) against a local Opal or Armadillo backend.
#
# Usage:
#   Rscript ds-run-tests.R <opal|armadillo> <filter> [pkg-path]
#
# Examples:
#   Rscript ds-run-tests.R armadillo smk-ds.var
#   Rscript ds-run-tests.R opal      standardiseDf  ~/git-repos/ds-core/dsBaseClient
#   Rscript ds-run-tests.R armadillo ""             # empty filter = whole suite (slow)
#
# <filter> is the testthat filter: matches test-<filter>.R (regex). Run FAILING
# files first; only run the whole suite once they pass.
#
# Env overrides:
#   PKG       default ~/git-repos/ds-core/dsBaseClient  (or pass as 3rd arg)
#   OPAL_URL  default http://localhost:8081/
#   ARMA_URL  default http://localhost:8080/
#
# What it does: picks the driver + URL, writes local_settings.csv in the form the
# checked-out branch expects (full-URL vs bare-host — auto-detected), then runs
# devtools::test(). It does NOT install dsBase (see ds-install.R) or edit
# login_details.R. local_settings.csv is gitignored, so it's left as written.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2)
  stop("usage: ds-run-tests.R <opal|armadillo> <filter> [pkg-path]", call. = FALSE)

backend <- tolower(args[[1]])
filter  <- args[[2]]
pkg <- if (length(args) >= 3 && nzchar(args[[3]])) args[[3]] else Sys.getenv("PKG", "~/git-repos/ds-core/dsBaseClient")
pkg <- path.expand(pkg)

opal_url <- Sys.getenv("OPAL_URL", "http://localhost:8081/")
arma_url <- Sys.getenv("ARMA_URL", "http://localhost:8080/")

cfg <- switch(backend,
  opal      = list(driver = "OpalDriver",      url = opal_url),
  armadillo = list(driver = "ArmadilloDriver", url = arma_url),
  stop("backend must be 'opal' or 'armadillo'", call. = FALSE))

conn_dir      <- file.path(pkg, "tests/testthat/connection_to_datasets")
settings_path <- file.path(conn_dir, "local_settings.csv")
login_path    <- file.path(conn_dir, "login_details.R")
if (!file.exists(login_path))
  stop("no login_details.R under ", conn_dir, " — is PKG a dsBaseClient checkout?", call. = FALSE)

# local_settings.csv semantics differ BY BRANCH:
#   init.server.url()  -> file holds a FULL URL (e.g. v6.3.6 standardise branch)
#   init.ip.address()  -> file holds a BARE HOST; login_details.R wraps it with :8080
login_src     <- paste(readLines(login_path, warn = FALSE), collapse = "\n")
uses_full_url <- grepl("init.server.url", login_src, fixed = TRUE)

host  <- sub("[:/].*$", "", sub("^https?://", "", cfg$url))
value <- if (uses_full_url) cfg$url else host
writeLines(value, settings_path)

cat(sprintf("[ds-run-tests] backend=%s  driver=%s  url=%s\n", backend, cfg$driver, cfg$url))
cat(sprintf("[ds-run-tests] local_settings.csv = %s  (%s form)\n",
            value, if (uses_full_url) "full-URL" else "bare-host"))
cat(sprintf("[ds-run-tests] pkg=%s  filter='%s'\n", pkg, filter))

# 8081 belongs to Opal. An Armadillo there is a setup error (it also swallows admin
# calls aimed at Opal) — stop it and run Armadillo on 8080, which is what
# login_details.R hardcodes for bare-host branches.
if (backend == "armadillo" && grepl(":8081", cfg$url, fixed = TRUE))
  cat("[ds-run-tests] WARNING: Armadillo on :8081 — that is Opal's port. Stop it and",
      "use :8080 (login_details.R hardcodes :8080).\n")

# Mirror CI: never stop early. devtools::test() otherwise honours TESTTHAT_MAX_FAILS=10
# and terminates before later files run, which looks like a clean pass. CI uses
# max_failures = 999999 + stop_on_failure = FALSE + datashield.return_errors = FALSE.
if (Sys.getenv("TESTTHAT_MAX_FAILS") == "") Sys.setenv(TESTTHAT_MAX_FAILS = "999999")
options(datashield.return_errors = FALSE)

options(default_driver = cfg$driver)
suppressMessages(library(devtools))
devtools::test(pkg = pkg, filter = filter, stop_on_failure = FALSE)
