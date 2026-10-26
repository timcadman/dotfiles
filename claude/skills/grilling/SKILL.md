---
name: grilling
description: Interview the user relentlessly about a plan, design, analysis or decision until there is one shared reading of it, before anything is built. Use when the user asks to be grilled, wants to stress-test their thinking, or when a request has more than one sensible reading.
---

# Grilling

Interview the user until you reach a shared understanding. Map it as a **design tree**: every
decision branches into the decisions that hang off it.

## Facts or decisions

- A **fact** is anything the code, the files, git, a note or a tool can answer. Finding it is your
  job, never the user's. Read the file, or send a subagent for a wide search.
- A **decision** is what only the user can settle: intent, trade-offs, scope, priority. Only these
  become questions.
- A lookup still running is an unsettled prerequisite. Only the questions downstream of it wait; ask
  the rest now.

## Rounds

The **frontier** is every decision whose prerequisites are already settled, so it can be answered
without guessing at an answer you have not heard yet. Each round:

1. Ask the frontier with `AskUserQuestion`, at most 4 questions. Never dump the whole tree.
2. Put your recommended answer first, labelled `(Recommended)`.
3. Batch only independent questions. If answering A changes whether B applies, B waits.
4. Settled answers push the frontier outward. Recompute it and ask again.

## Probe

- A vague answer earns a sharper follow-up next round.
- Name the assumptions the user is making without saying so.
- Push back when a choice has a real drawback.

## The end

Two conditions, both required: the frontier is empty, and the user says the understanding is shared.
Before you claim the frontier is empty, name what you are still assuming and put it on the frontier.
Build nothing until the user confirms.
