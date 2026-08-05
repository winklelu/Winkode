# Blog 五大分類篩選 + CV 下載 — 設計規格

日期：2026-08-05
狀態：使用者已核准最終版本，可進入實作規劃階段

> 本文件取代同名檔案較早的版本。設計過程中發現 Quarto 內建的分類篩選機制
> 比原本規劃的「手動堆疊區塊 + 自動化腳本」方案更簡單、更穩，因此整份設計
> 改採原生篩選機制。詳見下方「技術驗證」一節。

## 目標

兩項獨立、低風險的新增功能：

1. 讓瀏覽者能透過分類**精準篩選**出想看的文章（不是單純捲動瀏覽全部），
   類似目錄／篩選器的體驗。
2. 在首頁 LinkedIn / GitHub 旁邊加上 CV 下載連結。

**硬性限制：不能改變任何現有網址。** 文章路由、檔名、導覽列連結都不搬動。

## 明確排除的範圍

- 不重寫首頁 Hero / About Me / Core Expertise 文案。
- 不更動導覽列（`Home | Presentations | Blog | WinViz Lab` 維持原樣）。
- 不做「Category 大分類 vs Tags 細標籤」兩個獨立欄位的雙層系統——細標籤跟
  主分類共用同一個 `categories:` 欄位（見下方「YAML 改動方式」），不新增
  額外欄位，也不需要 `_pre-render.R` 自動化腳本。

## 設計

### 1. 分類命名與順序

5 個項目，固定顯示順序（不依文章數量排序，依「身分優先」邏輯排）：

1. **Clinical Programming & Regulatory Delivery**（固定放最前面，即使文章數最少）
2. **Data Review & Visualization**（拿掉原本 PDF 建議的「Clinical」字首——因為
   這一類底下含有 WBC 2026、NBA/F1 賽事分析等與臨床試驗無關的一般數據視覺化
   文章，硬加「Clinical」字首會讓內容跟標籤不符）
3. **Automation & Reproducible Workflows**
4. **Quality, Leadership & Industry Practice**
5. **All Articles**（顯示全部 29 篇，未篩選狀態）

### 2. 文章分類對應表

沿用 PDF 原本的 29 篇分配結果（2／11／13／3 = 29，已對照 `blog/` 資料夾
實際檔案確認無誤），只有分類 2 改名，文章內容不搬動：

**Clinical Programming & Regulatory Delivery（2）**
- `adamct-2014-09-26.qmd`
- `17-MAR-2026 -define-xml-v21-walkthrough.qmd`

**Data Review & Visualization（11）**
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

**Automation & Reproducible Workflows（13）**
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

**Quality, Leadership & Industry Practice（3）**
- `21-APR-2026-Career-Git-Repository.qmd`
- `01-AUG-2025-Takeaways from Learning Programming and AI Tools.qmd`
- `06-JUL-2025-Statistical Programmer.qmd`

### 3. YAML 改動方式

每篇文章既有的 `categories:` 欄位**附加**（不是取代）一項對應的主分類全名，
其餘既有的細標籤（R、CDISC、Git、ggplot2…）維持不動。例如：

```yaml
# 改動前
categories: [R, CDISC, Define-XML, Clinical Data, xml2]

# 改動後
categories: [R, CDISC, Define-XML, Clinical Data, xml2, "Clinical Programming & Regulatory Delivery"]
```

**已知的連帶影響（使用者已確認可接受）**：因為每篇文章自己頁面上方會把
`categories:` 全部內容顯示成標籤列，改動後那一列會混雜短標籤（如 `R`）跟
完整分類全名（如 `Clinical Programming & Regulatory Delivery`），長度不一致。

### 4. Blog 頁面實作

`blog/index.qmd` 把 Quarto 內建、會列出全部細標籤（目前約 30 個，字母排序、
命名也不一致，例如 "Clinical Trial" 與 "Clinical Trials" 並存）的自動側邊欄
關閉，換成只有這 5 個項目的自訂篩選按鈕列，沿用 Quarto 內建的篩選引擎
（`quarto-listing.js`）與 `#category=...` 網址機制（細節見下方技術驗證）。

每篇文章自己頁面上方的標籤列不受此項改動影響，仍會完整顯示（見第 3 節）。

### 5. 首頁改動

`index.qmd` 目前這一行：

```
📘 [Blog/Sharing](blog/)  |  👉 [Presentations](Speaker.qmd)
```

移除，原位置（`## Current Focus` 之前）改為 5 張分類卡片，每項前綴 👉：

```
👉 Clinical Programming & Regulatory Delivery → blog/#category=...
👉 Data Review & Visualization → blog/#category=...
👉 Automation & Reproducible Workflows → blog/#category=...
👉 Quality, Leadership & Industry Practice → blog/#category=...
👉 All Articles → blog/
```

原本連到 `Presentations` 的連結拿掉不補，因為導覽列本身已有 `Presentations`
入口，訪客仍找得到。

### 6. CV 下載

- CV PDF 由使用者提供，不在本專案內製作內容。
- 檔案放在 `files/CV_Winkle_Lu.pdf`（實際檔名待拿到檔案後確認）。
- `index.qmd` 的 `about.links` 新增一筆連結，跟 LinkedIn / GitHub / Email 並列。

### 7. 新文章的維護方式

新文章只要在自己的 `categories:` 欄位裡包含對應的主分類全名（連同想加的
細標籤），存檔後就會自動被首頁卡片與 Blog 篩選按鈕正確篩選到——**不需要
額外腳本，也不需要回頭手動改 `blog/index.qmd`**。

### 網址不變的保證

- 不搬移、不重新命名任何 `.qmd` 檔案。
- YAML 欄位是附加（append），不是取代，不影響既有內容。
- 首頁與 Blog 頁面的改動都是版面呈現層級，不新增/改變任何文章的輸出路徑。
- CV 是新增的靜態檔案連結，不影響既有網址。

## 技術驗證（設計過程中已實際確認，非推測）

直接檢查了目前已 render 好的 `docs/blog/index.html` 與
`docs/site_libs/quarto-listing/quarto-listing.js`，確認以下行為：

1. Quarto 的分類篩選會把目前選取的分類寫進網址 hash（`#category=<值>`），
   頁面載入時會讀取這個 hash 並自動套用篩選——可以直接從外部連結進來就是
   已篩選好的狀態，這是首頁卡片可行的技術依據。
2. `filterListingCategory()` 實際篩選邏輯是讀取每篇文章 `categories:` 欄位
   的資料，跟側邊欄 UI 是否顯示無關；`activateCategory()` 裡側邊欄高亮的
   那一步是有防呆判斷（找不到對應 DOM 元素就跳過），但篩選本身照常執行。
   這是「側邊欄可以換成自訂 5 項按鈕、篩選功能不受影響」的技術依據。
3. 檢查了實際 render 出來的 `docs/blog/17-MAR-2026 -define-xml-v21-walkthrough.html`，
   確認每篇文章自己頁面上的標籤列（`<div class="quarto-categories">`）是
   獨立渲染的，跟 Blog 列表頁的側邊欄設定無關——這是「側邊欄改自訂按鈕，
   不影響個別文章頁面標籤顯示」的技術依據。

自訂 5 項按鈕的實際 HTML/JS 寫法（是否直接呼叫 `quartoListingCategory()`，
或需要額外綁定），留到實作規劃階段再確認細節。

## Spec 存放位置說明

放在 `.claude/specs/`，不用技能預設的 `docs/superpowers/specs/`——因為
`docs/` 是 Quarto 網站實際的建置輸出目錄（`_quarto.yml: output-dir: docs`，
發布到 GitHub Pages），不適合放這種不對外發布的規劃文件。（與
`.claude/specs/2026-07-19-patient-timeline-design.md` 已確立的理由一致。）

## 實作前的待辦事項

CV PDF 檔案尚未提供。`index.qmd` 的 CV 連結與檔案放置，可在拿到檔案後隨時
實作；Blog 五大分類篩選與首頁卡片的部分沒有這個相依性，可以獨立先進行。
