---
name: grant-writing
description: Plan, draft and review research grant proposals and their sections (aims, excellence, impact, implementation, work plan, budget justification, resubmission responses). Use when the user works on a grant proposal, funding application or reviewer critique, for any funder (Horizon Europe, ERC, NWO/ZonMw, UKRI, Wellcome, NIH, NSF, foundations).
---

# Grant writing

## 1. The call is the source of truth

Before drafting, get the call text or funder template from the user, or a URL to it. From it, write a
checklist of:
- every evaluation criterion and its weight or threshold,
- every required section, with page or character limits,
- formatting rules and mandatory annexes,
- eligibility conditions that shape the content (consortium size, career stage, open science).

Do not rely on memory for a funder's criteria. Criteria change between calls. If the call is not to
hand, say so and mark every funder-specific claim as unverified.

Two well-known shapes, still to be checked against the call:
- **Horizon Europe** collaborative calls are scored on Excellence, Impact, and Quality and efficiency
  of the implementation.
- **ERC** scores scientific excellence alone, of the project and of the PI.

## 2. Aims before prose

Draft the aims on one page before any other section:
1. The problem and why it matters now.
2. What is known and what is missing: the gap this proposal closes.
3. Two to four aims or objectives, each with its hypothesis or deliverable and its method. Each aim
   survives the failure of another.
4. The expected result and who uses it.

Get the user's agreement on the aims page before drafting the rest. Use the `grilling` skill when an
aim has more than one reading.

## 3. Sections, mapped to criteria

Draft each section under the funder's own headings. For every criterion on the checklist, point at
the paragraph that answers it. A criterion with no paragraph is a gap; report it.

- **Approach / methods:** per aim give the rationale, methods, preliminary data, expected outcome,
  risks with a concrete fallback, and timing.
- **Impact:** name the users of the results, the route to them, and how uptake is measured.
- **Implementation:** work packages, deliverables, milestones, who does what, and a risk table.
- **Budget justification:** tie every line (staff effort, equipment, travel, open access) to a work
  package or aim.

## 4. Review pass

- Score the draft against the checklist as a reviewer would, criterion by criterion.
- Check every limit (pages, characters, figures) and every mandatory section.
- For a resubmission, build a table: critique, response, where the text changed.
- Run the `unslop` skill over the prose. Funding panels read AI tells as low effort.
- British English, unless the funder requires otherwise.
- Work in two phases: first list every issue (read-only), then work through them one at a time
  with the user. Number them, give the location (section + opening words of the sentence) and
  the proposed replacement text, and wait for a decision before moving on.
- Only flag what matters: factual or citation errors, contradictions between sections, form
  questions left unanswered, and claims a reviewer could challenge. Do not flag wording
  preferences or tiny style points; it is fine for a review to find nothing.
- Order: substance first (cross-section consistency, missing content, task/milestone timing,
  claims not backed by the work plan), then typos and style, then word limits last — the text
  is still moving until then.
- Keep a tracker file of issues with status (done / skipped / waiting on whom), and update it
  after each decision.
- Cross-checks that catch most errors: milestone/deliverable counts vs lists; months in tables
  vs text vs Gantt; budget shares vs WP amounts; every in-text citation in the reference list
  and vice versa; partner roles in WPs vs expertise section vs budget.
- References: take details from the project's .bib or a verified source; mark anything
  unconfirmed and never fill gaps from memory.
- When cutting for word limits, check each cut against the reviewer feedback and the
  evaluation criteria first. Never cut text that answers a reviewer comment or signals a
  criterion (state of the art, novelty, impact), even if it repeats another section.
- When rewriting or restructuring a section, report the before/after word count and list every
  removal (figures, citations, phrases), not only the deliberate cuts. Never describe a rewrite
  as "no content cut" without checking it against the word-count change.
- Don't cut text a partner wrote (e.g. their route to market) until they have replied; trim it
  later if their additions push the section over the limit.

## Output

- Section drafts under the funder's headings, in Markdown unless asked otherwise.
- Work plan as a table of work packages, deliverables and months.
- Never invent preliminary data, citations, budgets or partner commitments. Leave a marked
  placeholder and list them for the user.
