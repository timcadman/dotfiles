---
name: unslop
description: "Cut AI tells from any text a person reads: a reply, a doc, a paper or grant draft, a commit body, a PR, a review comment, a code comment, slides."
---

# Unslop

Edit prose to remove AI patterns and add human voice. Rewrite prose, not code. A comment is prose,
so it is in scope; the identifiers and logic around it are not. What we write is R package
documentation, DataSHIELD guides, papers, grant proposals, slides and PR text, so the examples below
are drawn from those.

## Process

1. Scan for the patterns below.
2. Rewrite. Preserve meaning, match intended tone.
3. Add soul (see next section).
4. Self-audit: "What makes this obviously AI generated?" Fix remaining tells.

## Adding soul

Removing patterns is half the job. Sterile, voiceless writing is just as obvious.

- **Have a view where the mode allows it.** Explanation and a review weigh trade-offs, so say what you make of them instead of listing pros and cons. Reference docs stay dry.
- **Vary rhythm.** Short sentences. Then longer ones that take their time. Mix it up.
- **Acknowledge complexity.** "Fast, and it needs a server round trip per study" beats "fast".
- **Use "I" or "we" when it fits.** First person isn't unprofessional.
- **Let some mess in.** Perfect structure looks machine-made.
- **Be specific.** Not "the analysis can be slow" but "each `ds.glm` iteration is one round trip to every server".

## Patterns to detect and fix

### Content

1. **Puffery.** "pivotal moment", "testament to", "evolving landscape", "setting the stage for", "indelible mark", "deeply rooted". Cut puffery, state what happened.
2. **Name-dropping.** Listing institutions, consortia or papers without saying what each contributes. Pick one, say what it showed.
3. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete or expand with real sources.
4. **Promotional language.** "groundbreaking", "renowned", "world-class", "cutting-edge", "state-of-the-art", "seamless", "powerful", "robust". Say what it does and for whom.
5. **Vague attributions.** "Experts believe", "Studies suggest", "Some critics argue". Name the source or delete.
6. **Formulaic challenges.** "Despite challenges... continues to thrive", "while limitations remain, the approach shows promise". A grant-writing tell. Name the limitation and what it costs.

### Language

7. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant. Replace with plain words.
8. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Just say "is" or "has".
9. **"Not just X, but Y."** State the point directly instead.
10. **Rule of three.** Forcing ideas into groups of three. Use the natural number.
11. **Synonym cycling.** Cohort, study, dataset, source all meaning the same thing in one paragraph. Pick one, repeat it.
12. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale. List topics directly.

### Style

13. **Em dash overuse.** Avoid em dashes. Use periods or commas. Reaching for parentheses instead just trades one tell for another. If a thought needs separation, end the sentence or use a comma.
14. **Colon overuse.** Colons are fine before a list or example. Not as mid-sentence connectors.
15. **Boldface overuse.** Don't bold every proper noun or acronym.
16. **Inline-header lists.** The tell is a bold label and colon that restates the line: "**Performance:** Performance improved...". Convert those to prose. A bold lead-in that ends in a period, names the item, and is followed by genuinely new detail is fine.
17. **Title case headings.** Use sentence case.
18. **Decorative emojis.** Remove from headings and bullets.
19. **Curly quotes.** Replace with straight quotes.

### Communication artefacts

20. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!" Remove.
21. **Cutoff disclaimers.** "While specific details are limited..." Find sources or remove.
22. **Sycophantic tone.** "Great question! You're absolutely right!" Respond directly.

### Filler

23. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". "It is important to note that" gets deleted.
24. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
25. **Generic conclusions.** "The future looks bright." State specific plans or facts.

### Jargon

26. **Abstract metaphor nouns.** Substrate, wedge, vector, locus, vantage, nexus, harness (as metaphor), surface (as in "API surface"), bedrock, scaffolding (as metaphor), modality, paradigm, north star, flywheel, seam. Pick the concrete word: "substrate" becomes "base", "vector" becomes "way", "seam" names what actually divides.

### Plain speech

27. **Say what it does, not how it feels.** "seamless federated analysis" names a feeling. The fix names the mechanism or a number: "the client sends one call per server and pools the returned sums". If the sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.
28. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop clauses. One idea per sentence.
29. **Active voice.** Name the actor: "the data are filtered" becomes "the server filters the data". Passive is fine only when the actor is unknown or genuinely doesn't matter, as often in a methods section.
30. **Cut adverbs, or use a stronger verb.** "significantly improves" becomes the measured delta.
31. **Prefer the plain word.** "utilise" becomes "use", "leverage" becomes "use", "facilitate" becomes "help", "numerous" becomes "many", "in the event that" becomes "if".
