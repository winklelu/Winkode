# Patient Timeline — Design Spec

Date: 2026-07-19
Status: Approved (see conversation history for iteration/validation)

## Goal

Complete the "Patient Timeline" card on `winviz.html`, which has been sitting
as `coming-soon` (originally planned around r2d3/D3.js). Replace that plan
with a ggplot2-based tool, matching the pattern already used by the other
available cards (KM Curve, Waterfall Plot, Spider Plot, Swimming Plot, Forest
Plot): one `tools/<name>/<name>_template.R` script + one `preview.png`,
linked from a card with a real "Code" button.

## Why ggplot2 (not D3.js)

The user pivoted away from the original r2d3/D3.js plan in favor of ggplot2,
to stay consistent with every other tool in `tools/`. The earlier D3.js
exploration (`blog/03-MAR-2026-Patient-Timeline-Visualization...qmd` and the
useR 2026 poster) is left untouched — it's a separate blog artifact, not
superseded by this work.

## Data model

Unlike the other tools (each built on a single ADaM dataset), Patient
Timeline's whole point is integrating **multiple raw/SDTM domains** into one
view — that's its distinguishing value versus the single-domain plots. The
design keeps the user-supplied approach:

1. Each source domain (AE, EX, CM, LB, ...) has its own anchor date variable
   (`AESTDAT`, `EXSTDAT`, `CMSTDAT`, `LBDAT`).
2. `prepare_timeline(data, form_label, time_var, display_vars)` standardizes
   any domain into a common shape: `USUBJID | Time | Form | tooltip`.
3. `bind_rows()` stacks the standardized domains.
4. Adding a new domain requires exactly one more `prepare_timeline()` call —
   no other section changes.

## Plot design

- x = Time (date), y = Form, one point per event.
- `facet_wrap(~USUBJID, ncol = 1)` — one panel per subject. Keep
  `selected_subjects` small (1–3); the plot grows tall fast otherwise.
- **Subject ID shown on the left of each panel**, not the default top strip.
  - PNG: `facet_wrap(..., strip.position = "left")` +
    `theme(strip.placement = "outside", strip.text.y.left = element_text(angle = 0))`.
  - plotly: `ggplotly()` does **not** honor `strip.position` — confirmed via
    a minimal repro (`ggplot_build`/`layout$annotations` inspection). Facet
    strip labels always render centered along the top, and the grey
    strip-background is a separate `rect` shape that's left empty if only
    the label is moved. Fix applied in the script: drop the leftover grey
    `rect` shapes (matched by `fillcolor`), then reposition + restyle the
    subject-ID annotations (`x`, `y` at panel vertical center via `yaxis`
    domains, `yanchor = "middle"`, bold text, grey `bgcolor` box) so the
    interactive version visually matches the PNG.
- **Domain encoding is redundant**: color AND shape both map to `Form`
  (`FORM_COLS` / `FORM_SHAPES`), so domains stay distinguishable in
  black-and-white or for colorblind readers.
- **AE connecting line**: a black `geom_line()` threads through each
  subject's AE markers in time order, drawn *before* `geom_point()` so
  markers render on top of the line.
- **Subject separator**: a grey `panel.border` box around each facet panel
  is the visual separator between subjects — deliberately a different grey
  from the black AE line so the two aren't confused.
- Gotcha already hit and fixed: adding the AE-only `geom_line()` layer
  *before* the full-range `geom_point()` layer throws off ggplot2's discrete
  y-scale training (whichever category a layer with a partial factor subset
  sees first gets sorted first, silently breaking the intended Form order).
  Fixed by pinning the axis explicitly with
  `scale_y_discrete(limits = rev(form_levels))` rather than relying on
  layer order.
- Theme matches the repo's existing visual convention
  (`theme_classic(base_size = 11, base_family = "serif")`, title/subtitle
  sizing consistent with `swimming_template.R`).

## Output

- `patient_timeline_plot.png` — 300dpi, height scales with subject count.
- `patient_timeline_demo.html` — self-contained plotly widget
  (`htmlwidgets::saveWidget(..., selfcontained = TRUE)`), only produced if
  `plotly`/`htmlwidgets` are installed (`requireNamespace()` guarded).
- `if (interactive()) print(p_timeline)` before the `png()` device opens, so
  the plot also shows in RStudio's Plots pane during interactive use.
  Guarded by `interactive()` — without the guard, a non-interactive run
  (`Rscript`, CI) falls back to opening a stray `Rplots.pdf`, confirmed by
  reproducing the issue directly.
- No RTF output (unlike `swimming_template.R`/`forest_template.R`) — scoped
  out by the user to keep this tool's output surface minimal.

## Repo changes

1. Add `tools/patient-timeline/patient_timeline_template.R` (the script
   described above) and `tools/patient-timeline/preview.png` (regenerated
   from the dummy data).
2. Update the Patient Timeline card in `winviz.html`:
   - `viz-card coming-soon` → `viz-card available`.
   - Replace the `coming-soon-overlay` block with a real `<img>` preview +
     lightbox `onclick`, matching the other available cards.
   - tech pills: r2d3 / D3.js / ADSL+ADAE → R Programming / ggplot2 / dplyr /
     plotly / AE+EX+CM+LB.
   - card description: rewritten to describe the multi-domain
     standardize-then-stack approach (not "D3.js powered swimmer plot").
   - card action: real `⌥ Code` link to
     `https://github.com/winklelu/WinSual/tree/main/tools/patient-timeline`,
     no disabled/"Soon" buttons.

## Spec location note

This spec lives in `.claude/specs/`, not the skill's usual
`docs/superpowers/specs/` default — in this repo, `docs/` is the Quarto
website's actual build output (`_quarto.yml: output-dir: docs`, published to
GitHub Pages), so it's the wrong place for a non-published planning
document.

## Out of scope

- RTF/reporter output.
- ADaM-only single-dataset variant (rejected in favor of the multi-domain
  SDTM approach, which is this tool's distinguishing feature).
- Any change to the existing D3.js blog post or useR 2026 poster.
