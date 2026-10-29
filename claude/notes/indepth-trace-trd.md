# INDEPTH TRACE-TRD — full-application feedback tracker

Project folder: `~/Library/CloudStorage/GoogleDrive-timcadman@gmail.com/Mi unidad/Work/funding/in-progress/INDEPTH/`. Full-application deadline: **2026-10-30 17:00 CET**. Session history and file layout: `STATUS.md` in that folder.

## Key files

- Budget (current): `Work/trace-trd-draft-budget_final.xlsx` (Google Drive, three levels above the project folder), sheet "Kosten en financiering". Older copies in `drafts/` and the `JK_11062027` copy are superseded.
- Submitted pre-application: `final/pre-submission/pre-application-submitted.md`
- Do not edit the xlsx programmatically (validations get stripped). Tim enters figures by hand; guidance is to enter figures, not new formulas (restoring the template's own formulas is fine).

## Pre-proposal feedback (INDEPTH, Aug 2026) — to address in full application

### Scientific and impact evaluation

| # | Point | Where to address | Status |
|---|---|---|---|
| S1 | Strengthen evidence supporting the Bayesian modelling strategy | A.1 §2, WP3 description | ✅ (Suresh 2020 in A1.2; four reasons in WP3; B1a) |
| S2 | Clarify how subgroup identification and treatment recommendations will improve outcomes | A.1 §3, WP3/WP4, C.1 | ✅ (WP4 predictions under alternative treatments, shared decision-making; C1) |
| S3 | Define measurable scientific, clinical and health-economic success criteria | A.1 §5b | ✅ Tim 2026-10-27: no 5b line (overkill); covered by B4a headroom + early HTA. Old note: health-economic criteria missing. HTA is an ineligible cost; option: one line in 5b "Overall project" saying an early HTA is planned after the project (B4b). Verbatim feedback: `Extended feedback TRACE_TRD (2).pdf` in project folder |
| F1 | Show available and planned datasets are detailed enough for predictive modelling | WP1, WP3 (T3.2, N0) | ✅ (WP1 assessments per patient, T3.2 + simulation, N0, Tables 2–3). NDTD numbers (Tim, 2026-10-27): 493 baseline, 274 completed baseline questionnaires, 144 completed at 3 months. Placed in WP1 Description after first sentence. Letter line still to write |
| F2 | Clarify workload distribution and partner contributions | WP roles, A.1 §7 | ✅ (roles per WP, A1.7, A.4 per WP; Compass hours to confirm, L3) |
| F3 | Better explain budget allocation and planned activities | A.4 §15 | ✅ (A.4 now organised per WP) |
| E1 | Quantify expected patient benefit, healthcare savings and implementation impact | B.4, B.6 | ✅ headroom paragraph added to end of B4a (2026-10-27; Beekman 2025 ref to add) |
| E2 | Estimate patient reach and value creation | B.4a | ✅ reach sentence (floor 493 NDTD, ceiling 33,000; Beekman 2025) in B4a §3 (2026-10-27). Value creation via headroom (E1); Evidencio revenue still absent (B4c) |
| E3 | Strengthen evidence for anticipated cost reductions and efficiencies | B.4, B.6 | ⚑ Waiting on colleague (100,000 / 80% / €2–3k). Fallback: Beekman 2025 (33,000; €209m; €6,000 absenteeism) |
| P1 | Explain how insights will improve patient care and treatment decisions | C.1, WP4 | ✅ |

### Eligibility assessment (must be met to proceed)

| # | Point | Fix | Status |
|---|---|---|---|
| L1 | Conflict of interest to be checked and approved by Health~Holland | Send separate COI document (Appendix F) to Health~Holland before submission | ☐ |
| L2 | UMCG counts as one institution | Merge UMCG (MGE) + UMCG (UCP) into `UMCG`: B15=`UMCG`, clear B16; B31–B34, B84, B85, B132, B133, B108 = `UMCG`; add department (GCC/UCP) in D column; B167=`UMCG`, W167=680,160; in-kind K/M/O/Q/S167 = 40,448 / 99,284 / 99,284 / 99,284 / 72,190; row 168 removed; partner list moved up (B16–B21) | ✅ |
| L3 | Compass's 60 h is not credible collaboration | Raised to 513 h (€80,028): I39=513, E175=80,028 (typed value), in-kind K/M/O/Q/S175 = 6,669 / 20,007 / 20,007 / 20,007 / 13,338. **Still to do:** activities from Compass in D39/D40 and A.4 §15 | ◐ |
| L4 | Wage costs confirmed by financial officers of each institute | Sign-off from UMCG, GGZ inGeest, Pro Persona, Parnassia; Evidencio to confirm €60/h. GGZ rates (€48/h for both roles) look like placeholders | ✅ |
| L5 | Tranches incorrect; must be calculated automatically | 187,500 in input row (now row 194); template formulas restored in "Totale PPS-subsidie" row (confirmed with Health~Holland that this row must be formulas) | ✅ |
| L6 | Confirm whether Evidencio platform licence (€30k, row 65) is in kind | Get Evidencio's confirmation; add sentence to A.4 §15 | ✅ |
| L7 | OIM check incomplete | Evidencio: signed "Verklaring geen onderneming in moeilijkheden" + decision tree + EU SME check | ✅ |
| L8 | Only R&D costs allowed; server and catalogue maintenance must be substantiated | Rows 84–85. Either justify in A.4 §15 (compute for Bayesian models, deployment/testing T2.4, catalogue entries for new variables T1.4) or cut. Option: take €15k data access fee from server maintenance (E84 15,000 → 11,250) | ☐ |

## Other open budget items

**Row numbers below row 167 have shifted up by one** since row 168 was deleted (e.g. tranche input row is now 194, funding-gap check V206).

- €15k data access fees: section 4 row 108 (B108 `UMCG`, replacing leftover `UMCG (UCP)`; D108 "External data sources (NESDA, EMBARC, GENDEP)"; E108 "Data access fees"; J108 15000). Must be offset by an equal UMCG cut — undecided: server maintenance E84 15,000 → 11,250 (recommended) or E84 → 13,125 plus research nurse I34 700 → 618 h. ☐
- Project end date C8: 9/1/2031 → 8/31/2031 (form requires last day of month; not in feedback). ✅
- Budget cross-check 2026-10-26: all A.4 WP totals, in-kind figures and research-type % match the form; Compass cash €150,000 = 10.3%. Open: Compass type "Nederlandse grote onderneming" but UK-registered — question for Compass, left as is; server line → "Virtual machines and storage for federated analysis, GCC" + A.4 WP2 sentence rewritten ✅ (L8); meetings/steering committee. ☐
- Project coordinator: none budgeted. Call allows only R&D-related project management (call description ~l.770 + footnote 5). Decide whether to budget (~0.05 FTE, offset by UMCG cut) or state in A.4 §15 that coordination is outside subsidised costs. Decided 2026-10-26: leave out (not raised by reviewers). ✅
- Application 5a: WP6 (and non-scientific part of WP5) should have 0% budget share if unbudgeted; non-scientific dissemination is ineligible. ✅ (WP6 gone; A.4 says non-scientific dissemination is outside the budget)

## Form text — parked items

- 4b coherence paragraph: "trajectory-class profiles" conflicts with WP3 (discrete classes only kept if they improve prediction); change to "trajectory patterns" as in WP5. Skipped (classes wording left as is).
- Pre-registration details for N0 fallback: separate discharge from loss to follow-up; response baseline per treatment step. ☐

### Inconsistencies found 2026-10-26 (outside WP descriptions unless noted)

- WP descriptions: WP1 milestone line "M1.6" → "M1.1 … (M6)"; WP2 milestone line M2.2 "(M12)" → "(M24)"; WP1 heading has "(M1–48)" twice; M3.1 "(trajectory or transition-based)" → "multi-state"; Table 3 N0 "If not met" → multi-state wording; WP2 description lacks the local-fitting fallback used in 5c. ✅ (also: WP2 extended to M1–36 with T2.5 Support & maintenance M25–36, to match the 3-year software developer; Table 1, Figure 1, Gantt updated)
- 5c go/no-go: WP1 and WP2 are long versions (WP1 still has synthetic-data clause); WP3 "transitions between clinical states" → multi-state wording; WP4 "(M4.1)" → "(M4.2)"; last line still cites WP6/T6.3. ✅ (WP4 and WP6 fixed; synthetic-data clause now correct since T3.5 starts M6; "transitions" → multi-state wording)
- Section 6 risks: "transition-based models"; external data access cites "T1.2, M3–12" and WP1 → T3.1 (M1–12), WP3; deployment "M18–30" → M18–24; staging-instrument risk says "prognostic model … usable output" vs Table 3; WP4 risks missing; "Table X" refs → Table 2 / Table 3. ✅ (new risk issues below)
- 5a: total row "5,8 %" comma; deliverables "14" but 13 codes listed (D1.2 twice). ✅ 5b names WP1 "data harmonisation and upload". ☐
- Classes framing: keywords ("Bayesian growth mixture models"), State-of-the-art (GMMs, latent subgroups), §8 ("patient subgroups"), B.1b ("latent-class inference", "trajectory-classification") vs WP3 (continuous first, classes only if they improve prediction). ☐
- GGZ inGeest ticked "Research organisation" + "Other"; budget treats it as GGZ partner. ✅

### Questions for partners (Tim to email each separately)

B2a part (ii) — "how will you continue building on the results?" (one concrete sentence each; ~150 words spare of 600):
- Clinical partners (UCP, GGZ inGeest, Pro Persona, Parnassia): what concrete next step — e.g. prospective validation via NDTD, use of staging results in care pathways? ☐
- Compass: what will you do with the trajectory models after the project? ☐
- Evidencio: part (ii) missing entirely; also B2b route to market, C3 dissemination placeholder. ☐
- Depressie Vereniging: how will you carry the results forward after the project? ☐
- Compass: registered as "Nederlandse grote onderneming" in budget form but UK company — correct? ☐
- Compass: consortium agreement/IP (Admin §5). ☐
- Compass: B2a text uses "our" (→ "its"); naming COMP360 + "support HTA submissions" sits next to the COI declaration — confirm wording with Compass. ☐
- Evidencio: B4c launch date + revenues; licence fee (for B4a headroom); B2b suggested text: CE marking as legal manufacturer, platform licences to specialist GGZ (B4b–c). ☐
- 4th clinical site: actual NDTD patient count (WP1 says "approximately 600"). ☐

### Figures check against Nuijen 2017 (PDF read 2026-10-27; no "therapieresistent" in report)

1. Summary EN/NL "800,000 annually (Nuijen)" — report: "ruim een half miljoen volwassenen (18–64)"; B4a uses 1.08m (Ten Have 2023). Checked: Ten Have 2023 Table 2, 12-month MDD (DSM-5, 18–75) = 8.5%; 3.3m = 26% → population ≈12.7m → 8.5% ≈ 1.08m (derived, not stated; paper gives no absolute counts). ✅ (summary EN/NL and B4a now "about 1.1 million (Ten Have et al. 2023)")
2. Background "largest contributor to disease burden (Nuijen)" — report: mood disorders 6th in disease burden. ✅
3. TRD cost share: "over half" (summary) / "largest share" (Background) / "around 80%" uncited (B6, C1); 80% sources in original NDTD grant: Greden 2001, Ivanova 2010 — both US, rejected as Dutch support. Flagged to colleague; come back. Option: replace 80% with "a disproportionate share of depression's costs (Pérez-Sola et al. 2021)". Flagged to colleague (re-confirmed 2026-10-27). ⚑
4. "100,000 TRD patients" (B6, C1, VWS I "Trimbos/RIVM 2019" = Nuijen 2017 with wrong year, but no TRD count in it); also inconsistent with 20–30% of 0.5–1.08m; original NDTD said 55,000. Flagged to colleague; come back. ☐
3b. **Pérez-Sola 2021 abstract (PubMed 34509073):** 21,630 MDD patients, 3,559 TRD (16.5%); mean total cost per patient over 18-month follow-up €6,096 TRD vs €3,846 non-TRD. Implied TRD share of costs ≈ 24% — does NOT support "over half" (summaries). Supports "disproportionate share". Tim: drop this (2026-10-27).
   E1 headroom inputs found 2026-10-27: NVvP 2024 algorithm — evaluate after ≥4 weeks at adequate dose, then every 4–6 weeks; Nuijen 2017 — 4.2% of workers have depression, absenteeism+presenteeism €240m per million workers (→ ≈ €5,700/worker with depression/yr, derived), 23 extra absent days/yr (30 incl. presenteeism), ambulant DBC ≈ 30 h treatment (2014, overestimate); STAR*D remission per step (Rush 2006). Still needed: TRD patients/yr at sites, cost per treatment step, licence fee.
   **Found: Beekman, Spijker, Kok, Blom, Stikkelbroek, Hoenders, van Bueren, Vinkers, Kamphuis 2025, "Consultatie voor patiënten met persisterende depressie: een verkennende impactanalyse", TvP 67(9) (Nov), p. 496–~503.** Vektis: 94,500 treated in sggz with depression main diagnosis (2015); 35% persistent >2 yr ≈ 33,000; sggz depression costs €595m/yr (Vektis 2019) → persistent group €209m/yr (≈ €6,300/patient/yr, derived); sequential treatment: ~30% don't recover; absenteeism ≈ €6,000/yr; disability benefit €16,500/yr; 2.4% employed, 14% disabled/unemployed; consultation €1,500/patient → saves €83m yr1, €127m later, €533m over 5 yr. Same-group model to cite/mirror for E1–E3; also a source for the 100,000 replacement (≈33,000 persistent in sggz). No Evidencio licence fee public (quote needed). NZa 2025 arts-specialist 60-min ≈ €433–516 (unverified sheet).
5. B6 "€2,000–3,000 per patient per month" — no source found anywhere. Flagged to colleague 2026-10-27. ⚑
6. B4a "€3.4bn (Nuijen)" — report gives €1.6bn + €1.8bn, not the total. ✅ (rephrased)

### External data sources (Table 2) — in progress 2026-10-27

Source report: `TRACE-TRD Possible Data Sources (1).xlsx` (59 candidates). EMBARC excludes TRD; GENDEP not TRD; OPTIMUM rejected (older adults only). Decided: external data serve half biology, half mitigation (supplement NDTD if too sparse). Final (3 rows): NESDA (biology) + European prospective TRD cohort (Heerlein 2021?, real-world, n=411, 6/12 months — confirm it's the Heerlein cohort) + LQD (TRD, weekly 52 wk, supplement from M24). CO-MED dropped. Edits needed: WP3 external-sources sentence (both purposes), Table 2 rows, Table 3 N0 "If not met" (add supplement), T3.6 sentence. ☐

**Scope (2026-10-26):** review only up to the end of A1.6 (risks). Sections after that (A1.7 on, B, C, E1–E3) on hold until Tim has merged track changes.

### Agreed today but not in the latest pasted text (check 2026-10-26)

- A1.2 "(Suresh 2020)" → "(Suresh et al. 2020)"; Background "(Rush, Trivedi et al. 2006, Pigott…)" → "(Rush et al. 2006; Pigott et al. 2023)". ✅
- A1.7 Evidencio still "personalised recommendations" → "personalised predictions of treatment response and relapse". ☐
- Depressie Vereniging: A1.7 body "The Depressievereniging", A.4 WP5 "Depressievereniging (60 hours…". ☐
- 4b panel sentence: add "and ethical evaluation of the decision-support workflow". ✅ (reworded: panel gives "input on the ethical aspects", not "ethical evaluation" — WP5 (iv), WP4, 4b; C2 same wording, parked)
- 5c WP3: "we model transitions between clinical states instead" → multi-state wording. ✅
- WP3 description: "once the analyses, additional data has been uploaded, and the federated extension is deployed" — "are pre-registered" dropped deliberately (too many clauses); leftover "the analyses," still dangles. ✅ (→ "fitted to the NDTD data from M24, once the analyses are pre-registered (M3.2) and the federated extension is deployed (D2.2)")
- Risks: deployment row risk text still "approving and installing … on their nodes" ✅; external-data row impact "<edium" (typo, leave for end). ☐
- References list: copy-paste truncation in Saelens, Ten Have, Uher 2010, Uher 2011, van de Schoot (merged with Voineskos). ☐

### Review of latest version up to A1.7 (2026-10-26)

Parked (come back later): word limits — summary EN 334/300, Background 370/350, State-of-the-art 284/250, Objective 205/200 (197 without subheadings); summary and SoA word-count fields blank. A1.7 paragraphs and Dutch summary within limits.

Must fix:
- References — come back to (web search 2026-10-26, not yet confirmed): Benrimoh et al. 2025 (AID-ME, J Clin Psychiatry 86(3): e218586 — title/article no. from repository listing only); European Commission 2020 (PReDicT, CORDIS article 415955, date unverified); Nuijen 2017, Vektis 2025, DepressieNet 2026 supplied by Jeanine ✅ — Nuijen 2017 replaces "Trimbos-instituut and RIVM 2018" (same report); in-text citations updated, full list pasted ✅; Benrimoh 2025, European Commission 2020, Evidencio n.d. (BLAST), Aifred Health n.d., full Cipriani supplied 2026-10-26 ✅; still missing: Trimbos/RIVM 2019 (VWS I, 100,000); Trimbos/RIVM 2019 "100,000 TRD" not found — figure appears on UMCG NDTD project page; alternative Veraart et al. 2021 TvP 63(4): 260–62 (">65,000", check PDF); same 100,000/80% uncited in B6, C1. Not found, ask B4/B5 authors: Vektis 2025 (600 providers, 77.6%, 93%), DepressieNet 2026 (website?), Evidencio n.d. (CE-marked antibiotic product page / EUDAMED). ADeSS was a failed feasibility trial (18/86 recruited) — don't present as evidence in B5. ☐
- References: Suresh 2020 (A1.2) and van de Schoot et al. 2017 (GRoLTS, WP3) missing from D; Hoijtink 2008, Klugkist 2007, Tervonen 2008, Milaneschi 2020 listed but uncited; "NVvP 2023" cited but listed as "Nederlandse Vereniging voor Psychiatrie". ✅ (full list given 2026-10-26 incl. Uher 2010, O'Brien 2023, Estrade 2023, Cipriani 2026, Harrison 2023; in-text: "Suresh et al. 2020", "Rush et al. 2006; Pigott et al. 2023")
- Admin §5 consortium agreement/IP still "[Argumentation]". Waiting on Compass. Draft given 2026-10-26 (standard template, 8.2.2/8.10 removed, ownership follows inventorship); open: template version, any amendments, owner of WP3 prediction algorithm, option right for Compass/Evidencio. ☐
- 5a "Time schedule" empty — check Gantt is pasted in. ✅ (also deliverables 14 → 13, "5,8 %" → "5.8 %")
- Section 6: risk "Available NDTD and partner data are insufficient … trajectory models" carries the external-data-access mitigation (T3.1, M3.2, T3.6); either give it the N0 multi-state fallback or restore a separate external-data-access risk. ✅ (split into two rows: NDTD data insufficient → N0 multi-state; external data access delayed, impact Low)
- Section 6: no risk for ethical review/governance delay (M1.1); no WP5 risk (form asks per WP). ✅ (added rows: ethics delay, patient panel participation, usability-testing participation D4.2)

Inconsistencies:
- Coordinator: main applicant is Tim (GCC) but 4b says "UMCG (UCP) coordinates the project". ✅ (decided GCC; 4b → "UMCG (GCC) coordinates the project")
- Classes framing (extends item above): also summary "distinct multi-modal recovery paths", A1.2 "class membership" / "distinguish absent subgroups", Aim 2 "distinct recovery trajectories". Skipped 2026-10-26 — Tim considers rewording overkill; leave as is.
- Hypothesis: "alternative diagnostic pathways … diagnostic re-evaluation" not followed up in any WP. ✅ (sentence deleted)
- Aim 2 lists "treatment history" as a trajectory domain (predictor, not outcome), omits personal recovery (I.ROC), and omits relapse. ✅
- Background "develop novel federated Bayesian modelling methods" vs B3b "does not develop new statistical theory". Skipped — leave as is.
- M12 timing: M3.1 / 5b WP3 need parameter recovery at observed density (N0) by M12, but models are developed on synthetic data from M18; T3.2 (M6–12) relies on retrospective data only available at M12 (M1.2). ✅ (5b WP3 first sentence: M12 decision now rests on counts from existing NDTD data + D1.1; parameter-recovery clause removed)
- 5b WP3 "temporal cross-validation" not in WP3 text. ✅ (added to last sentence of WP3 external-data paragraph, T3.7)
- 4b coherence: WP4 presented as sequential "Third" step though guideline prototype is ready at M24 independent of WP3; "training workshops" (also WP5) have no task/deliverable; patient panel role (iv) ethical evaluation omitted. ✅ (WP4 sentence reworded: first version M24, updated with WP3 findings, final algorithm from M42; "training workshops" deleted in 4b, WP5, §8; (iv) added)
- Node hosting: WP1 roles "UMCG (GCC) … maintains the servers" vs WP2 "system administrators at the clinical partners … install on their nodes". ✅ (GCC hosts all nodes, partners approve changes; WP2 roles + deployment risk row reworded)
- WP1 description mentions only data managers; roles add local research nurses. ✅
- WP5 name: "Communication and dissemination" (WP heading) vs "Communication, dissemination and patient panel" (5b, A.4). T5.4/D5.3 non-scientific dissemination classed 86% industrial in 5b (ineligible, see budget item). ✅ (name = "Communication, dissemination and patient panel" in Table 1, WP5 heading; check Figure 1 + Gantt labels; sentence "non-scientific dissemination at partners' own cost, not in budget" goes in A.4 §15 WP5 paragraph, not 5b)
- Synthetic modelling made a concrete step (2026-10-26): T3.2 adds N0 simulation; T3.5 → M6–36 (synthetic from M6, NDTD from M24); WP3 description sentence replaced (feeds T2.3 and M4.1); 5b WP3 parameter-recovery clause restored; risk row C → "WP3 continues model development on synthetic data (T3.5)"; 5c WP1 unchanged; 5c WP3 → "multi-state model of transitions between response, remission and non-response". Gantt regenerated (`figures/gantt.png`; script copied to session scratchpad `gantt.py`). ✅
- A.4 §15 (later): €5,000 meetings "including the steering committee" — call lists "escalation to a steering committee" as ineligible project management; reword. ✅ (deleted)
- A1.7 Evidencio "personalised recommendations" vs WP4 (what happened to similar patients, not recommendations). ✅ (→ "personalised predictions of treatment response and relapse")
- A1.7 Compass omits external data sources (T3.1/T3.6) and Bayesian analysis strategy, which WP3 and budget assign it. ✅
- A1.7 Depressie Vereniging doesn't mention running the patient panel. ✅ (also name → "Depressie Vereniging" in A1.7 heading/body and A.4 §15)
- Dutch summary omits GGZ inGeest, Parnassia, Pro Persona and the Domain 2 sentence. ✅ (partners added; Domain 2 left out, ~299 words)
- Cross-section: 800,000 (summary) vs 1.08 million (B4a); TRD cost share "over half" (summary) / "largest share" (Background) / "around 80%" (B6, C1); TRL 6 "demonstrated within the intended clinical context" (B3b) vs WP4 usability testing only. Prevalence + cost share skipped for now (come back; suggestion: NEMESIS-3 "over one million" in both summaries; B6/C1 "more than half … (Pérez-Sola et al. 2021)" unless 80% source found). TRL 6 wording left as is. ☐

Admin form:
- "GGZ InGeest" vs "GGZ inGeest" in partner table. ✅ (Pro Persona department, Oostelbos details, titles: dropped by Tim — don't raise again.)
- COI: "Health-Holland" → "Health~Holland"; double space "TRACE-TRD  project"; word count field says 199 (wc 195). ☐

Typos/style:
- Summary: "relapse risk ." space; "Network … federated network (NDTD)"; comma splice "symptoms), however"; "multi-modal" vs "multi-domain". ☐
- Background: stray leading space before "The Netherlands Network"; "Rush, Trivedi et al. 2006"; "However, without reliable methods" not a contrast. A1.2 "The NDTD network". ☐
- WP1 aim sentence broken ("…, and ethical approval of the research protocol"); "Directly from the start". ☐
- Hyphens vs en dashes in month ranges: WP2–5 headings, T1.2 "(M1-M6)", T3.7, T4.3. Table captions "Table 2:" vs "Table 3.". "meta-data" (4b) vs "metadata". "specialized" (A1.7 Evidencio); "Their"/"Its" mix. Depressie Vereniging / Depressievereniging / Depressie vereniging. ☐
- Citation comma style: A sections mostly "(Author et al. 2023)", B sections mostly "(Author et al., 2023)". Pick one for whole application (end pass). B5 has 7 with commas. ☐

## Submission checklist (2026-10-29)

- Application form: Word + PDF, sign and date, COI Appendix F doc sent before submission ☐
- Response letter ✅; budget + financial officer confirmation ✅; Evidencio SME check + Verklaring ✅ (already sent)
- Letters of commitment: all except Compass ✅; Compass missing (€150,000 cash, €40,320 in kind) ☐
- Consortium agreement: Standard template, no amendments (Compass wants none) → default Option Right (8.5–8.7); submit unsigned with parties/project filled in; optional 8.2.2/8.10 cleanup can wait until review ☐
- Form edits agreed 2026-10-29: section 10 ethics → Yes / not yet (non-WMO, T1.2); T1.2 "non-WMO ethical review" + WP1 Roles protocol writer (offset −11 words in WP3); B4a "(NVvP 2023)" → 2024 ☐

## Submission email: response to Program Group recommendations

Required with the submission: short description, by email to indepth@umcg.nl, of how the pre-proposal feedback (S/F/E/P and L items above) was addressed. Draft once the items above are closed; first draft with placeholders written 2026-10-22. ☐

## Budget justification text (A.4 §15) — rewrite to cover

Current A.4 §15 text predates these changes (still organised by Aim 1–3, describes UMCG GCC/UCP separately, Compass as "joins the project group"). Rewrite so it explains:

- UMCG as one partner, with GCC/UCP roles per line (L2) ✅
- Compass's 513 h: concrete activities and tasks (L3) ✅ (current: 288 h / €40,320, confirmed 2026-10-26; 513 h figures in L3 are superseded)
- Evidencio premium platform subscription (€30k) provided in kind — after Evidencio confirms (L6) ✅
- Server and catalogue maintenance: R&D-only justification, or note reduced amount (L8) ☐
- €15k data access fees for external data sources (T1.2, T3.6) ✅ (current: €20,000, confirmed 2026-10-26)
- Project coordination: budgeted R&D-related hours, or carried outside subsidised costs ✅ (left out)
- Budget allocation per WP/activity, to answer feasibility feedback F3 ✅
- After Compass increase: total budget €1,490,298; Compass cash = 10.07% of total (call encourages ≥10%), so further budget growth pushes it below.
- Open-access fees (€6k for 6 papers) likely too low; patient panel (Depressie Vereniging, 60 h) thin relative to WP5; no WP6 budget line.
