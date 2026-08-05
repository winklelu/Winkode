# Blog 四大分類頁面 + CV 下載 — 設計規格

日期：2026-08-05
狀態：使用者已核准，可進入實作規劃階段

## 目標

針對 WinSual 網站（`/Users/winkle/__Projects/R/Winkode`）進行兩項獨立、低風險的新增功能。這兩項是使用者看過一份「個人網站修改建議」PDF 之後，決定只採用的部分：

1. 讓瀏覽 Blog 頁面的訪客能更快找到合適的文章，把現有 29 篇文章依四個由上而下排列的分類標題分組呈現。
2. 在首頁的 LinkedIn / GitHub 旁邊加上一個 CV 下載連結。

**硬性限制：不能改變任何現有網址。** 不論是文章路由、檔名，或導覽列連結，都不應該被搬動。

## 明確排除的範圍（使用者確認不做的部分）

- 不重寫首頁的 Hero / About Me / Core Expertise 文案（雖然前面討論那份 PDF 時有提過，但使用者這次選擇先不動）。
- 不更動導覽列（`Home | Presentations | Blog | WinViz Lab` 維持原樣）。
- 不修改任何文章本身的 YAML。現有每篇文章的 `categories:` 欄位（目前混雜了工具、標準、主題等，例如 `categories: [R, CDISC, Define-XML, Clinical Data, xml2]`）維持不動——它仍然負責驅動每篇文章頁面上原有的標籤顯示。
- 不新增任何 frontmatter 欄位（例如不新增 `main-category:`）到任何文章。
- 不做「Category（大分類）vs Tags（細標籤）」的雙層系統——這是 PDF 裡提到的內容，但不在這次規劃範圍內；這份規格只涵蓋四個頂層分類分組。

## 設計

### 1. Blog 四大分類頁面（堆疊區塊）

只改一個檔案：`blog/index.qmd`。

把目前單一的自動 listing（`listing: contents: . / sort: date desc / categories: true`）換成**四個獨立的 Quarto listing 區塊**，每個區塊都用明確列出檔名的 `contents:` 清單（而不是自動掃描資料夾）。版面由上而下排列，每個區塊各自有一個 `##` 標題，讓訪客不需要點擊篩選，就能一次看到四個分類群組及各自的文章：

```
## Clinical Programming & Regulatory Delivery
[listing: contents: <2 個檔案>]

## Clinical Data Review & Visualization
[listing: contents: <11 個檔案>]

## Automation & Reproducible Workflows
[listing: contents: <13 個檔案>]

## Quality, Leadership & Industry Practice
[listing: contents: <3 個檔案>]
```

因為 `contents:` 是列出明確檔名，而不是掃描資料夾，所以不會有任何 `.qmd` 檔案被重新命名或搬移，每個 listing 區塊連到的仍然是每篇文章原本已經存在的那個網址。這就是為什麼「網址不變」這個限制在這個做法下很容易保證。

分類命名與每篇文章的分配方式：直接沿用 PDF 裡既有的 29 篇文章分配結果（2 / 11 / 13 / 3 = 29，已對照 `blog/` 資料夾裡實際的檔案清單確認過無誤）：

**Clinical Programming & Regulatory Delivery（2 篇）**
- `adamct-2014-09-26.qmd` — "You Need a Placebo Comparison"
- `17-MAR-2026 -define-xml-v21-walkthrough.qmd` — "From XPT to Define-XML v2.1"

**Clinical Data Review & Visualization（11 篇）**
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

**Automation & Reproducible Workflows（13 篇）**
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

**Quality, Leadership & Industry Practice（3 篇）**
- `21-APR-2026-Career-Git-Repository.qmd`
- `01-AUG-2025-Takeaways from Learning Programming and AI Tools.qmd`
- `06-JUL-2025-Statistical Programmer.qmd`

未來調整彈性：由於分類的分配完全存在於 `blog/index.qmd` 裡這四個 `contents:` 清單中，之後要把某篇文章換到別的分類，只需要在幾個 listing 區塊之間剪貼一行，不需要動到其他任何檔案。

每個 listing 區塊各自維持 `sort: "date desc"`（區塊內部依日期排序），並沿用 `type: default`（或目前 Blog 首頁既有的預設 listing 樣式），以維持與現有頁面一致的視覺風格。

### 2. CV 下載

- CV PDF 由使用者提供完成好的檔案，不在這個專案內製作內容。
- 檔案放在 `files/CV_Winkle_Lu.pdf`（新資料夾；實際檔名可在拿到檔案後再確認）。
- 在 `index.qmd` 的 `about.links` 新增一筆連結，跟現有的 LinkedIn / GitHub / Email 並列——只放首頁，不動導覽列。

### 網址不變的保證

兩項改動都屬於「新增／呈現層」的變更，不動既有結構：
- Blog 部分：還是同樣的 29 個檔案、同樣的輸出路徑，只有首頁的版面邏輯改變。
- CV 部分：新增一個靜態檔案與一個首頁連結，不動任何既有路由。

因為現有能被解析到的網址，解析結果完全不變，所以不需要任何轉址（redirect）。

## Spec 存放位置說明

這份 spec 放在 `.claude/specs/`，而不是技能預設的 `docs/superpowers/specs/`——因為在這個專案裡，`docs/` 是 Quarto 網站實際的建置輸出目錄（`_quarto.yml: output-dir: docs`，會發布到 GitHub Pages），所以並不適合放這種不對外發布的規劃文件。（這個做法跟 `.claude/specs/2026-07-19-patient-timeline-design.md` 裡已經確立的理由一致。）

## 實作前的待辦事項

CV PDF 檔案目前還沒有提供。`index.qmd` 的連結與檔案放置，可以在拿到檔案後隨時實作；Blog 四大分類的部分則沒有這個相依性，可以獨立先進行。
