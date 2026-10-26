---
name: laziness
description: Bias to deletion and the smallest change. Apply when refactoring, sizing a diff, or tempted to add an abstraction, a layer or a piece of state.
---

# Laziness

Writing code is cheap for you, which makes over-engineering easy. Counter it by borrowing a human
maintainer's fatigue.

The cost you are cutting is not lines. It is the work a reader must do, and it has two independent
axes: **layers to trace** between a question and its answer, and **state to hold** in their head. LOC
and cyclomatic complexity are proxies for these two. Guard both, because **a flat file with 50 globals
is as hard to reason about as a six-layer adapter stack**.

## Cut layers

- **Keep the call hierarchy flat.** If answering a question means tracing more than 3 files or layers,
  flatten it. **A rich interface that hides substantial work is not a deep call chain.** The layer to
  cut is the one that adds a hop and compresses nothing.
- **Collapse what does not earn its keep:** a wrapper with one caller, an adapter with no second
  implementation, indirection added for a future that never came, a layer that repeats the same
  methods and arguments as the one below it. Inline them.
- **Consolidate decisions.** Never repeat the same choice in several places. Put it behind one source
  of truth and pass the result as a simple flag.
- **Question the threading.** When a task asks you to pass a new signal through functions, objects or
  pipelines, stop and look for the direct path. Grep for who would read the new argument first: if
  nothing consumes it, that is the answer.
- **Sweat the small leaks.** Tiny pass-throughs, representation leaks and duplicated choices compound
  into permanent coordination costs. Remove them before they spread.

## Cut state

- **Shrink the scope of anything mutable:** returns over mutations, locals over globals, function
  arguments over options and environment variables.
- **Derive instead of sync.** Two values kept in agreement are state. One computed from the other is
  not.
- **Name the invariant at the boundary**, not in every consumer, so the reader learns it once.

## Before you add

- **Prefer deletion.** Asked to refactor or improve, look for removals before additions.
- **Minimize the diff.** Make the smallest change that solves the problem. Fewer lines beat elegant
  boilerplate.
- **Price it against both axes.** Before adding a layer OR a piece of state, ask whether it cuts reader
  load somewhere else by at least as much. If it does not, it is cost with no buyer.
- **Document as little as possible.** In this order: enforce it, with a gitignore entry, a lint rule
  or a failing test, then one line where the decision is made, then docs. A doc is the weakest of the
  three because nothing makes anyone read it.

## The test

Can a new reader answer **"where does X come from?"** and **"what can change X?"** in under 30
seconds? One question per axis. If not, cut layers or cut state.

If a human developer would find the code exhausting to maintain, it is a bad solution.
