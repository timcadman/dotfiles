# DataSHIELD recipe drafts

Drafts extracted from past analysis projects (LMedC, exp-mh, lc-bmi-poc, lc-env-pnd), to become
wiki tutorials first and then be regenerated into the `datashield` skill. All function calls
were checked against DSI 1.7.1, dsBaseClient 6.3.5, dsTidyverseClient 1.1.1 and dsHelper 1.7.0
(references and source); dsHelper 1.7.5 has identical signatures. Code is generic: no credentials, servers, table paths or cohort names.

- `organising-analysis-code.md`: section for SKILL.md
- Analysis: `model-specification.md`, `running-models.md`, `mixed-models.md`,
  `sensitivity-analyses.md`, `collecting-results.md`
- Preparation: `prep-workflow.md`, `assign-and-check-availability.md`,
  `harmonise-classes-and-factor-levels.md`, `recode-and-categorise.md`, `derive-variables.md`,
  `repeated-measures.md`, `transformations-zscores-iqr.md`, `merge-datasets.md`,
  `exclusions-and-analysis-samples.md`, `explore-missingness.md`
- Imputation: `multiple-imputation.md`, `analyse-imputed-data.md`
- Output (plots, forest plots, tables, meta-analysis, reports): pending
