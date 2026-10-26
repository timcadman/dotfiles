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
| S1 | Strengthen evidence supporting the Bayesian modelling strategy | A.1 §2, WP3 description | ☐ |
| S2 | Clarify how subgroup identification and treatment recommendations will improve outcomes | A.1 §3, WP3/WP4, C.1 | ☐ |
| S3 | Define measurable scientific, clinical and health-economic success criteria | A.1 §5b | ☐ (health-economic criteria missing) |
| F1 | Show available and planned datasets are detailed enough for predictive modelling | WP1, WP3 (T3.2, N0) | ☐ |
| F2 | Clarify workload distribution and partner contributions | WP roles, A.1 §7 | ☐ |
| F3 | Better explain budget allocation and planned activities | A.4 §15 | ☐ |
| E1 | Quantify expected patient benefit, healthcare savings and implementation impact | B.4, B.6 | ☐ |
| E2 | Estimate patient reach and value creation | B.4a | ☐ |
| E3 | Strengthen evidence for anticipated cost reductions and efficiencies | B.4, B.6 | ☐ |
| P1 | Explain how insights will improve patient care and treatment decisions | C.1, WP4 | ☐ |

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
- Project end date C8: 9/1/2031 → 8/31/2031 (form requires last day of month; not in feedback). ☐
- Project coordinator: none budgeted. Call allows only R&D-related project management (call description ~l.770 + footnote 5). Decide whether to budget (~0.05 FTE, offset by UMCG cut) or state in A.4 §15 that coordination is outside subsidised costs. Decided 2026-10-26: leave out (not raised by reviewers). ✅
- Application 5a: WP6 (and non-scientific part of WP5) should have 0% budget share if unbudgeted; non-scientific dissemination is ineligible. ☐

## Form text — parked items

- 4b coherence paragraph: "trajectory-class profiles" conflicts with WP3 (discrete classes only kept if they improve prediction); change to "trajectory patterns" as in WP5. ☐
- Pre-registration details for N0 fallback: separate discharge from loss to follow-up; response baseline per treatment step. ☐

### Inconsistencies found 2026-10-26 (outside WP descriptions unless noted)

- WP descriptions: WP1 milestone line "M1.6" → "M1.1 … (M6)"; WP2 milestone line M2.2 "(M12)" → "(M24)"; WP1 heading has "(M1–48)" twice; M3.1 "(trajectory or transition-based)" → "multi-state"; Table 3 N0 "If not met" → multi-state wording; WP2 description lacks the local-fitting fallback used in 5c. ✅ (also: WP2 extended to M1–36 with T2.5 Support & maintenance M25–36, to match the 3-year software developer; Table 1, Figure 1, Gantt updated)
- 5c go/no-go: WP1 and WP2 are long versions (WP1 still has synthetic-data clause); WP3 "transitions between clinical states" → multi-state wording; WP4 "(M4.1)" → "(M4.2)"; last line still cites WP6/T6.3. ☐
- Section 6 risks: "transition-based models"; external data access cites "T1.2, M3–12" and WP1 → T3.1 (M1–12), WP3; deployment "M18–30" → M18–24; staging-instrument risk says "prognostic model … usable output" vs Table 3; WP4 risks missing; "Table X" refs → Table 2 / Table 3. ☐
- 5a: total row "5,8 %" comma; deliverables "14" but 13 codes listed (D1.2 twice). 5b names WP1 "data harmonisation and upload". ☐
- Classes framing: keywords ("Bayesian growth mixture models"), State-of-the-art (GMMs, latent subgroups), §8 ("patient subgroups"), B.1b ("latent-class inference", "trajectory-classification") vs WP3 (continuous first, classes only if they improve prediction). ☐
- GGZ inGeest ticked "Research organisation" + "Other"; budget treats it as GGZ partner. ☐

## Submission email: response to Program Group recommendations

Required with the submission: short description, by email to indepth@umcg.nl, of how the pre-proposal feedback (S/F/E/P and L items above) was addressed. Draft once the items above are closed; first draft with placeholders written 2026-10-22. ☐

## Budget justification text (A.4 §15) — rewrite to cover

Current A.4 §15 text predates these changes (still organised by Aim 1–3, describes UMCG GCC/UCP separately, Compass as "joins the project group"). Rewrite so it explains:

- UMCG as one partner, with GCC/UCP roles per line (L2) ☐
- Compass's 513 h: concrete activities and tasks (L3) ☐
- Evidencio premium platform subscription (€30k) provided in kind — after Evidencio confirms (L6) ✅
- Server and catalogue maintenance: R&D-only justification, or note reduced amount (L8) ☐
- €15k data access fees for external data sources (T1.2, T3.6) ☐
- Project coordination: budgeted R&D-related hours, or carried outside subsidised costs ☐
- Budget allocation per WP/activity, to answer feasibility feedback F3 ☐
- After Compass increase: total budget €1,490,298; Compass cash = 10.07% of total (call encourages ≥10%), so further budget growth pushes it below.
- Open-access fees (€6k for 6 papers) likely too low; patient panel (Depressie Vereniging, 60 h) thin relative to WP5; no WP6 budget line.
