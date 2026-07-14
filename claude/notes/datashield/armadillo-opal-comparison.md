# armadillo-opal-comparison — slide deck (separate repo)

Repo: `~/git-repos/armadillo-opal-comparison` (the benchmark). The presentation built
from it lives **outside** that repo, in the `presentations` repo:

- Deck: `~/git-repos/presentations/armadillo-opal-comparison/slides.md`
- A [Slidev](https://sli.dev) deck using the shared theme at
  `~/git-repos/presentations/theme` (CSS vars in `theme/styles/index.css`; layouts in
  `theme/layouts/`).
- Custom diagram components live in
  `presentations/armadillo-opal-comparison/components/` — e.g. `PollPenalty.vue`
  (DSI polling-sleep measurement caveat). The visual style mirrors `RoundTrips.vue` in
  the `eos/sprint-257` deck (the server round-trip diagram).

When asked to update "the slide deck" or add slides/diagrams about this benchmark, edit
files under `presentations/armadillo-opal-comparison/`, not the benchmark repo.

## Benchmark launch

Bringing up Opal + Armadillo for the benchmark: see
`launch-datashield-servers-sandbox.md`.
