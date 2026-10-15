# datashieldWiki: Opal mentioned without Armadillo

Review of `~/git-repos/datashieldWiki` (branch `main`, 2026-10-13). Read-only; nothing has been changed.

Most of the wiki is already balanced: the `analysis-tutorials/` and `getting-started/researcher/` login pages pair every Opal block with an Armadillo one. The gaps are below.

## Opal-only pages with no Armadillo equivalent

- `getting-started/sys-op/installing-opal.md` ("Deploying Opal"): there is no `installing-armadillo` page.
- `getting-started/sys-op/profile-management.md`: titled generically but is "Profile Management in Opal" throughout (Rock, `ROCK_HOSTS`, `obiba/opal` compose).
- `opmanag/deployment_to_opal.html`
- `opmanag/opal_packages.html`
- `opmanag/opal_uploading_data.html`
- `opmanag/package_upload_opal.html`
- `opmanag.html:55,61,90`: the index links to three of those Opal pages and has no Armadillo entries.

## Tutorials and examples

- `education/user-tutorial-2023.md`: installs and loads only `DSOpal` (lines 32–44), and both login blocks (73–75, 607–609) use three `OpalDriver` servers on `opal-demo.obiba.org`.
- `opmanag/Trivy.html:18`: the scan example uses only `obiba/opal:latest`.
- `opmanag/indication_of_call_progress.html:12`: assumes the reader knows `opalr` progress output.

## Prose that names only Opal

- `statdev/disclosure-checks.md:12` and `opmanag/disclosure-control/dsBase-checks.md:12` (same sentence): thresholds "configurable by data controllers in Opal".
- `getting-started/data-manager.md:36`: resources are documented via "Opal resources" only.
- `getting-started/researcher/setup-r-studio.md:29`: a to-do note reads "Details for Opal".
- `opmanag/draft-policies/contributions-policy.md:167`: the issue template says "Server Platform (e.g. Opal version)".
- `opmanag/infra-guide.md:27`: the sample enquiry says "setting up the DataSHIELD with Opal".
- `opmanag/infra-guide/00-arch-tech.md:124`: "only Coral offers monitoring. Opal is working on it".
- `opmanag/infra-guide/deployment-documentation.md:57`: one consortium row is described as "Opal serverside"; this may simply be accurate.

## Listings that skew to Opal

- `opmanag/datashield-github-repos.html`: seven Opal repos (`opal`, `opaladmin`, `opaladdons`, `opal-datashield-vm`, `puppet-opal`, `DSOpal`, `datashield-opal-python`) against two Armadillo ones (`docker-armadillo-rserver-base`, `DSMolgenisArmadillo`).
- `opmanag/community_packages.md:48` and `opmanag/packages/dsQueryLibrary.html:22`: "remote datashield/opal servers".
- `opmanag/packages/dsMTL.html:42,44`, `dsBoltzmannMachines.html:42`, `dsSwissKnife.html:42`: list Opal or `DSOpal` as dependencies. These are third-party package facts, so probably leave them.

## Wording that ranks Opal above Armadillo

- `getting-started/data-manager/overview.md:24`: "DataSHIELD was originally developped using Opal, and Opal is still the reference implementation." This is the only page making the "reference implementation" claim.
- `analysis-tutorials/quick-start.md:17`: "Opal is the original implementation of DataSHIELD." The `quick-start.Rmd` source at line 21 no longer has this sentence, so the rendered `.md` is stale.
- `about.md:99`: Armadillo is described as "MOLGENIS's light-weight alternative DataSHIELD server backend", while Opal on the line above is simply the "DataSHIELD server backend".
- `getting-started/sys-op/overview.md:12`: gives "first released 2011" for Opal and "first released 2021" for Armadillo; factual, but it frames Opal as the senior option.

## Not counted as gaps

- `ds.listOpals` / `ds.setDefaultOpals` in `opmanag/release-notes_7-0-0.html`, `opmanag/releaseplans/dsbasedsbaseclient_6-4-0.html` and `statdev/performance_citests_status.md` are function names.
- `about.md`, `infrastructure-dev.html`, `opmanag/standard-profiles-and-platforms.html`, `opmanag/Running-dsBaseClient-tests.html` and `opmanag/demo_example_script.html` have an adjacent Armadillo row or line for each Opal one.
- 44 meeting-minute, comms and private files mention Opal; skipped as historical records.
