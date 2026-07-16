#!/usr/bin/env Rscript
# Install a dsBase build on a local Opal or Armadillo R server.
#
# Usage:
#   Rscript ds-install.R <opal|armadillo> <tarball-path | github-ref>
#
# Examples:
#   Rscript ds-install.R armadillo ~/git-repos/ds-core/dsBaseClient/dsBase_6.3.6.9000.tar.gz
#   Rscript ds-install.R opal      ~/git-repos/ds-core/dsBaseClient/dsBase_6.3.6.9000.tar.gz
#   Rscript ds-install.R opal      refactor/perf-batch-3   # github ref on datashield/dsBase
#
# Armadillo accepts ONLY a local tarball. Opal accepts a tarball OR a github ref.
# Match the build to the client BRANCH, not just the major version (see note §0).
#
# Env overrides:
#   OPAL_URL  default http://localhost:8080/
#   ARMA_URL  default http://localhost:8081/
#   ARMA_USER/ARMA_PASS  default admin/admin
#   OPAL_USER/OPAL_PASS  default administrator/datashield_test&

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2)
  stop("usage: ds-install.R <opal|armadillo> <tarball-path | github-ref>", call. = FALSE)

backend <- tolower(args[[1]])
src     <- args[[2]]
is_tar  <- grepl("\\.tar\\.gz$", src)
if (is_tar) src <- path.expand(src)

opal_url <- Sys.getenv("OPAL_URL", "http://localhost:8080/")
arma_url <- Sys.getenv("ARMA_URL", "http://localhost:8081/")

if (backend == "armadillo") {
  if (!is_tar) stop("Armadillo install needs a local tarball, not a github ref.", call. = FALSE)
  suppressMessages(library(MolgenisArmadillo))
  url  <- sub("/+$", "", arma_url)
  user <- Sys.getenv("ARMA_USER", "admin"); pass <- Sys.getenv("ARMA_PASS", "admin")
  armadillo.login_basic(url, user, pass)
  cat(sprintf("[ds-install] Armadillo %s <- %s\n", url, basename(src)))
  armadillo.install_packages(paths = src, profile = "default")
  # whitelist dsBase via REST (no R wrapper) — 204 = success
  code <- system2("curl", c("-s", "-o", "/dev/null", "-w", "%{http_code}",
                            "-u", sprintf("%s:%s", user, pass),
                            "-X", "POST", sprintf("%s/whitelist/dsBase", url)),
                  stdout = TRUE)
  cat(sprintf("[ds-install] whitelist dsBase -> HTTP %s (204 = ok)\n", code))

} else if (backend == "opal") {
  suppressMessages(library(opalr))
  url  <- opal_url
  user <- Sys.getenv("OPAL_USER", "administrator")
  pass <- Sys.getenv("OPAL_PASS", "datashield_test&")
  opal <- opal.login(user, pass, url = url)
  on.exit(opal.logout(opal), add = TRUE)
  before <- tryCatch(dsadmin.package_description(opal, "dsBase")$Version, error = function(e) "none")
  cat(sprintf("[ds-install] Opal %s  dsBase before: %s\n", url, before))
  # Enable R package administration, else install_*_package returns 403 Forbidden
  # on a fresh Opal (mirrors the CI 'opal.put ... _rPackage' step).
  tryCatch(opal.put(opal, "system", "conf", "general", "_rPackage"),
           error = function(e) cat(sprintf("[ds-install] _rPackage enable warning: %s\n", conditionMessage(e))))
  if (is_tar) {
    cat(sprintf("[ds-install] installing local tarball %s\n", basename(src)))
    dsadmin.install_local_package(opal, src)
  } else {
    cat(sprintf("[ds-install] installing github ref datashield/dsBase@%s\n", src))
    dsadmin.install_github_package(opal, "dsBase", username = "datashield", ref = src)
  }
  dsadmin.profile_init(opal, name = "default", packages = c("dsBase", "resourcer"))
  dsadmin.set_option(opal, "default.datashield.privacyControlLevel", "permissive")
  Sys.sleep(5)
  after <- tryCatch(dsadmin.package_description(opal, "dsBase")$Version, error = function(e) "?")
  cat(sprintf("[ds-install] dsBase after: %s\n", after))

} else {
  stop("backend must be 'opal' or 'armadillo'", call. = FALSE)
}
cat("[ds-install] done\n")
