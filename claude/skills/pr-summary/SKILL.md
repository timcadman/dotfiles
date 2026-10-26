---
name: pr-summary
description: The required shape for a pull request summary or description (Background, What's changed, How to test). Use whenever asked to write or update a PR summary, PR description or PR body.
---

# PR summaries

Keep it concise and always use these three sections, in this order:

- **Background** — why the change is needed (the problem/context), in 1-3 sentences.
- **What's changed** — the concrete changes, as a short bullet list.
- **How to test** — comprehensive and copy-pasteable: exact commands for the automated checks, plus any sample input a reviewer needs (e.g. an inline CSV/JSON/code block) so they can reproduce end-to-end without constructing test data themselves.

Write the whole description in raw Markdown (headings, bullet lists, code fences) so it can be pasted straight into GitHub. No filler, no restating the diff line by line.
