# Blog Four-Category Landing + CV Download — Design Spec

Date: 2026-08-05
Status: Approved by user, ready for implementation planning

## Goal

Two independent, low-risk additions to the WinSual site (`/Users/winkle/__Projects/R/Winkode`), both driven by a "個人網站修改建議" PDF the user reviewed but only wanted to act on in part:

1. Let visitors on the Blog page find the right article faster by grouping
   the 29 existing posts under four top-down category headings.
2. Add a CV download link next to LinkedIn / GitHub on the homepage.

**Hard constraint: no existing URL may change.** Nothing about article
routing, filenames, or navbar links should move.

## Non-goals (explicitly ruled out by the user)

- No rewrite of the homepage Hero/About Me/Core Expertise text (covered by
  the earlier PDF review conversation, but the user chose not to act on it
  now).
- No navbar changes (`Home | Presentations | Blog | WinViz Lab` stays as-is).
- No per-article YAML changes. The existing `categories:` field on each post
  (a mixed bag of tools/standards/topics, e.g.
  `categories: [R, CDISC, Define-XML, Clinical Data, xml2]`) is untouched —
  it keeps driving the tag display on each individual post page.
- No new frontmatter field (e.g. no `main-category:`) added to any post.
- No tag/category two-tier system (Category vs Tags) — that was in the PDF
  but is out of scope; this spec only covers the four top-level groupings.

## Design

### 1. Blog four-category landing (stacked blocks)

Single file changed: `blog/index.qmd`.

Replace the current single auto-listing (`listing: contents: . / sort: date
desc / categories: true`) with **four separate Quarto listing blocks**, each
using an explicit `contents:` file list (not folder auto-discovery). Layout
top-to-bottom, each with its own `##` heading, so a visitor sees all four
groups and their articles on one page without needing to click a filter:

```
## Clinical Programming & Regulatory Delivery
[listing: contents: <2 files>]

## Clinical Data Review & Visualization
[listing: contents: <11 files>]

## Automation & Reproducible Workflows
[listing: contents: <13 files>]

## Quality, Leadership & Industry Practice
[listing: contents: <3 files>]
```

Because `contents:` lists exact filenames rather than scanning the folder,
no `.qmd` file is renamed or moved, and each listing block still links to
the exact same rendered URL each post already has. This is the reason the
"no URL changes" constraint is easy to guarantee here.

Category taxonomy and per-article assignment: taken as-is from the PDF's
existing 29-article breakdown (2 / 11 / 13 / 3 = 29, confirmed against the
actual files in `blog/`):

**Clinical Programming & Regulatory Delivery (2)**
- `adamct-2014-09-26.qmd` — "You Need a Placebo Comparison"
- `17-MAR-2026 -define-xml-v21-walkthrough.qmd` — "From XPT to Define-XML v2.1"

**Clinical Data Review & Visualization (11)**
- `useR-Poster-JUL-2026-Patient-Timeline-Visualization.qmd`
- `29-APR-2026-Clinical-Data-Viewer-ShinyConf2025.qmd`
- `28-APR-2026-Shiny-Hepatotoxicity-Safety-Monitor.qmd`
- `24-MAR-2026-RECIST-Clinical-Visualization.qmd`
- `03-MAR-2026-Patient-Timeline-Visualization- Bringing-Clinical-Data-to-Life-with-R-and-D3.qmd`
- `30-MAR-2026-R-Tips-Clinical-Data-Visualization.qmd`
- `04-MAY-2025-Plot-Table Highlighting in Shiny.qmd`
- `17-Jul-2026-Analyzing Sports Data with R at useR 2026.qmd`
- `09-MAR-2026-WBC2026-Advancement-Chart-with-R.qmd`
- `15-OCT-2025-A Journey into Data Visualization - From ggplot2 Techniques to Visual Design.qmd`
- `13-Sep-2025-Exploring cols4all for Better Data Visualization.qmd`

**Automation & Reproducible Workflows (13)**
- `04-Aug-2026-Quarto-and-AI-for-Reproducible-Reports-at-useR-2026.qmd`
- `28-Jul-2026-Git-Based-Workflow-for-R-Package-Validation-at-useR-2026_1.qmd`
- `useR-Lightning-Talk-JUL-2026-Reproducible-Clinical-Data-Review.qmd`
- `14-APR-2026-Local-LLM-Clinical-Trial-Workflow.qmd`
- `07-APR-2026-Forest-Plot-YAML-Quarto-Workflow.qmd`
- `02-JUN-2026-Git-Version-Control-Clinical-Perspective_1.qmd`
- `21-Jul-2026-ggplot2-helpers-notes at useR 2026.qmd`
- `12-Nov-2025-Two Simple Ways to Fill Dummy Data into the Right Rows.qmd`
- `02-JAN-2025-Generate Dynamic Text Results with glue.qmd`
- `23-JUN-2024-lapply_gsub.qmd`
- `05-APR-2025-Collaborating with ChatGPT.qmd`
- `25-FEB-2026-New-MacBook-Setup-and-WinSual-Relaunch.qmd`
- `01-FEB-2025-Lets Code the Zodiac in R.qmd`

**Quality, Leadership & Industry Practice (3)**
- `21-APR-2026-Career-Git-Repository.qmd`
- `01-AUG-2025-Takeaways from Learning Programming and AI Tools.qmd`
- `06-JUL-2025-Statistical Programmer.qmd`

Future flexibility: since assignment lives entirely in `blog/index.qmd`'s
four `contents:` lists, moving an article to a different category later is a
one-line cut-and-paste between listing blocks — no other file touched.

Each listing block keeps `sort: "date desc"` within its own group, and
`type: default` (or whichever default listing style the current blog index
already renders with) for visual consistency with the current page.

### 2. CV download

- User will supply a finished CV PDF (not created by this project).
- File placed at `files/CV_Winkle_Lu.pdf` (new folder; naming can be
  finalized once the actual file arrives).
- One new entry added to `about.links` in `index.qmd`, alongside the
  existing LinkedIn / GitHub / Email entries — homepage only, no navbar
  change.

### URL-safety guarantee

Both changes are additive/presentational:
- Blog change: same 29 files, same output paths, only the index page's
  layout logic changes.
- CV change: adds one new static file + one new homepage link; touches no
  existing route.

No redirects are needed because nothing that currently resolves changes
where it resolves to.

## Spec location note

This spec lives in `.claude/specs/`, not the skill's usual
`docs/superpowers/specs/` default — in this repo, `docs/` is the Quarto
website's actual build output (`_quarto.yml: output-dir: docs`, published to
GitHub Pages), so it's the wrong place for a non-published planning
document. (Same reasoning already established in
`.claude/specs/2026-07-19-patient-timeline-design.md`.)

## Open item before implementation

CV PDF file itself has not been provided yet. The `index.qmd` link and file
placement can be implemented as soon as it's supplied; the blog
four-category change has no such dependency and can proceed independently.
