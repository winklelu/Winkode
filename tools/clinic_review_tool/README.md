# Clinical Data Viewer

> ⚠️ **Demo Version Notice**
> 
> This is a demonstration version of the Clinical Data Viewer.
> All data used in this app are randomly generated dummy data
> for illustration purposes only. No real patient data is
> included or required to run this application.
>
> This tool is designed as a **proof of concept** to demonstrate
> how Shiny can improve clinical data review efficiency.
> It is not validated for use in regulated clinical trial environments
> without further customization and qualification.

---

An interactive Shiny application for clinical data review,
built to support medical reviewers in exploring multi-domain
CRF data in a single interface.

Originally presented at **ShinyConf 2025** — *Reviewing Clinical Data Efficiently with Shiny*.

---

## Features

**Two filter modes**
- Patient ID: Select one or multiple subjects directly
- Form & Variables: Filter subjects by CRF field values

**Interactive timeline**
- Multi-domain time points displayed on a shared axis
- Hover to view detailed record information
- Click a point to highlight the corresponding row in the listing below
- CRF filter mode highlights matching points in black

**Data listings**
- Each selected domain displayed as a separate sortable table
- Listings update automatically based on filter selections

**Excel export**
- Download all selected domain listings as a multi-sheet Excel file

---

## File Structure

```
clinical-data-viewer/
├── clinic_review.R   # Main app (UI + Server)
├── data_dummy.R      # Simulated CRF data (replace with real data)
└── calculate.R       # Utility functions
```

---

## Getting Started

**1. Install required packages**

```r
install.packages(c(
  "shiny", "dplyr", "ggplot2",
  "plotly", "DT", "openxlsx"
))
```

**2. Clone or download this repository**

**3. Run the app**

```r
shiny::runApp("clinic_review.R")
```

---

## Data Format

This app is designed to work with **raw CRF data directly** —
CDISC-compliant datasets (SDTM/ADaM) are **not required**.

The key requirements are simple:
- Each dataset must contain a `USUBJID` column to identify subjects
- At least one date column (column name ending in `DAT`) to serve
  as the timeline anchor
- All other columns are freely configurable by the programmer

This design choice intentionally lowers the barrier for teams
that are still in early data collection phases, or who prefer
to review data before CDISC mapping is complete.

---

## Using Real Data

To use real EDC data instead of simulated data:

1. Open `data_dummy.R`
2. Replace each `data_xx` object with your actual dataset
3. Ensure the following structure is maintained:
   - Each dataset must contain a `USUBJID` column
   - Date columns should follow the naming convention ending in `DAT`
4. Update `form_data` and `form_labels` to reflect your domains
5. No changes needed in `clinic_review.R` or `calculate.R`

---

## Supported Domains (Default Demo)

| Key | Label |
|-----|-------|
| AE | Adverse Events |
| EX | Exposure |
| CM | Concomitant Medications |
| LB_CHEM | Chemistry |
| SU_SMOKE | Tobacco Substance |

Additional domains can be added by updating `form_data` and
`form_labels` in `data_dummy.R`.

---

## Design Principles

- **Raw CRF data, no CDISC required**: Works directly on
  CRF-structured datasets. SDTM or ADaM transformation is
  not a prerequisite — reviewers can start exploring data
  at any stage of the trial.

- **Reviewer-friendly**: Designed for non-programmer medical
  reviewers. Once configured, no programming knowledge is needed
  to operate the tool.

- **Programmer-configured**: Initial domain setup is handled
  by programmers via `data_dummy.R`, keeping the reviewer
  experience simple and focused.

- **Modular architecture**: Data layer is fully separated from
  application logic. Swapping datasets requires no changes to
  the main app.

---

## Author

Winkle Lu | WinSual
Clinical Data Visualization & Shiny App Developer
[LinkedIn](https://www.linkedin.com/in/winkle-lu/) |
[WinSual](https://winklelu.github.io/WinSual/)

---

## Presented At

- **ShinyConf 2025** — *Reviewing Clinical Data Efficiently with Shiny*

---

## Disclaimer

This application was developed to explore and demonstrate the
concept of improving clinical data review efficiency using R Shiny.

All datasets included in `data_dummy.R` are randomly generated
and do not represent any real clinical trial or patient information.

Users who wish to apply this tool in a real clinical trial setting
are responsible for ensuring appropriate data validation, access
control, and regulatory compliance.
