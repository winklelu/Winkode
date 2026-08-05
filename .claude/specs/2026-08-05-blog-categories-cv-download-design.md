# Blog 五大分類篩選 + CV 下載 — 設計規格

日期：2026-08-05
狀態：已實作完成並在本機驗證通過（`quarto preview` + 瀏覽器實測）

> 本文件取代同名檔案較早的版本。設計過程中發現 Quarto 內建的分類篩選機制
> 比原本規劃的「手動堆疊區塊 + 自動化腳本」方案更簡單、更穩，因此整份設計
> 改採原生篩選機制。詳見下方「技術驗證」一節。實作過程中又發現兩個原生
> 機制的細節坑（分類名稱不能含逗號、Pandoc 會重新編碼 markdown 連結網址），
> 修正方式見第 4、5 節與「實作踩坑紀錄」。

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
4. **Quality Leadership & Industry Practice**
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

**Quality Leadership & Industry Practice（3）**
- `21-APR-2026-Career-Git-Repository.qmd`
- `01-AUG-2025-Takeaways from Learning Programming and AI Tools.qmd`
- `06-JUL-2025-Statistical Programmer.qmd`

### 2b. 跨分類文章（額外歸類）

以上對應表是每篇文章的**主分類**。逐篇看過標題、既有標籤與描述後，判斷
以下 4 篇內容確實橫跨兩個以上專業領域，額外加入第二（或第三）分類，讓它
們在對應的篩選結果裡都會出現：

| 文章 | 主分類 | 額外加入的分類 | 理由 |
|---|---|---|---|
| `07-APR-2026-Forest-Plot-YAML-Quarto-Workflow.qmd` | Automation & Reproducible Workflows | **Data Review & Visualization**、**Clinical Programming & Regulatory Delivery** | 可重複的參數化工作流程是核心，但產出的是法規/臨床常用的 Forest Plot，且該工作流程本身就是為了產出法規交付成果而設計 |
| `14-APR-2026-Local-LLM-Clinical-Trial-Workflow.qmd` | Automation & Reproducible Workflows | **Clinical Programming & Regulatory Delivery** | LLM 自動化的對象是 CRF-to-SDTM mapping，本身就是核心法規交付工作，不只是工具展示 |
| `28-Jul-2026-Git-Based-Workflow-for-R-Package-Validation-at-useR-2026_1.qmd` | Automation & Reproducible Workflows | **Clinical Programming & Regulatory Delivery** | 主題是把 unit test 轉成正式的 validation 文件，屬於法規/QC 交付的一環 |
| `useR-Lightning-Talk-JUL-2026-Reproducible-Clinical-Data-Review.qmd` | Automation & Reproducible Workflows | **Data Review & Visualization** | 標題本身就是「Reproducible *Clinical Data Review*」——架構是自動化議題，但目的明確是資料檢閱 |

其餘 25 篇維持單一分類（包含 `From XPT to Define-XML v2.1` 仍只放
Clinical Programming 一類——沿用 PDF 自己的判斷：雖然用了 R，但真正解決
的是法規交付問題）。

**加入額外分類後，各分類篩選出來的實際文章數**（同一篇文章可能被算在
多個分類裡，總篇數仍是 29）：

- Clinical Programming & Regulatory Delivery：2 → **5**
  （原本 2 篇 + Forest-Plot + Local-LLM + Git-Package-Validation）
- Data Review & Visualization：11 → **13**
  （原本 11 篇 + Forest-Plot + useR-Lightning-Talk）
- Automation & Reproducible Workflows：13（不變，4 篇跨分類文章本來就都
  屬於這一類）
- Quality Leadership & Industry Practice：3（不變）

這個調整順帶緩解了先前討論過的「核心身分展示篇數太少」問題——不用另外
寫新文章，Clinical Programming 分類篩選出來就從 2 篇變成 5 篇。

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

第 2b 節列出的 4 篇跨分類文章，附加的是兩個（`07-APR-2026-Forest-Plot-YAML-Quarto-Workflow.qmd`
是三個）分類全名，其餘做法相同——都是附加到既有陣列裡，不取代任何內容。

### 4. Blog 頁面實作

`blog/index.qmd` 把 Quarto 內建、會列出全部細標籤（目前約 30 個，字母排序、
命名也不一致，例如 "Clinical Trial" 與 "Clinical Trials" 並存）的自動側邊欄
關閉（`categories: false`），但**沿用 Quarto 原生的側邊欄 CSS/JS 結構**，而
不是完全自訂的按鈕列：在頁面內容裡放一個 `:::{.column-margin}` 區塊，內含
跟 Quarto 原本產生的 HTML 一模一樣的結構（`<h5 class="quarto-listing-category-title">`
+ `<div class="quarto-listing-category category-default">` + 5 個
`<div class="category" data-category="...">`，`data-category` 是
`base64(encodeURIComponent(分類名))`）。

這樣做的好處：
- Quarto 的 `DOMContentLoaded` handler 會自動掃描 `.quarto-listing-category .category`
  這個 selector 並掛上點擊事件，**不需要自己寫 onclick**。
- 位置沿用 `#quarto-margin-sidebar` 的既有 CSS（`quarto-listing.scss`），畫面
  一樣是右側欄位，跟改版前視覺一致。
- `.category.active { font-weight: 600 }` 這個既有樣式跟 `activateCategory()`
  的高亮邏輯直接生效，不管是從 Blog 頁面本身點擊、還是從首頁卡片連結帶著
  `#category=...` 進來，目前選中的分類都會自動反黑——不需要額外寫程式。

每篇文章自己頁面上方的標籤列不受此項改動影響，仍會完整顯示（見第 3 節）。

### 5. 首頁改動（最終版本，經多輪版面調整）

**簡介文案**：`:::{#hero-heading}` 裡原本「With over a decade... Feel free to
connect...」那兩段，換成使用者提供的三段新文案（強調 SAS/CDISC/法規交付
為核心身分，R/Python/Shiny/Quarto/D3.js 為延伸能力）。開頭刻意寫
「over a decade」而不是寫死「12 years」，避免每年要手動更新。

**「Explore by Topic」區塊**：取代原本的「📘 Blog/Sharing \| 👉 Presentations」
那一行。**這幾個連結是手寫的 raw HTML `<a>`，不是 markdown `[text](url)`
語法**（原因見下方「實作踩坑紀錄」）。版面經過使用者反饋調整：拿掉項目
符號（不用 `<ul>/<li>`，改用 `display:block` 的 `<a>`）、拿掉 👉 emoji、
每個項目改成文字後綴 → 箭頭、行距加大：

```html
## Explore by Topic

<div class="wh-topic-links" style="margin: 0.5em 0 1.25em 0;">
<a href="#" style="display:block; padding: 0.45em 0; text-decoration:none;" onclick="location.href = 'blog/#category=' + encodeURIComponent('Clinical Programming & Regulatory Delivery'); return false;">Clinical Programming &amp; Regulatory Delivery →</a>
<a href="#" style="display:block; padding: 0.45em 0; text-decoration:none;" onclick="location.href = 'blog/#category=' + encodeURIComponent('Data Review & Visualization'); return false;">Data Review &amp; Visualization →</a>
<a href="#" style="display:block; padding: 0.45em 0; text-decoration:none;" onclick="location.href = 'blog/#category=' + encodeURIComponent('Automation & Reproducible Workflows'); return false;">Automation &amp; Reproducible Workflows →</a>
<a href="#" style="display:block; padding: 0.45em 0; text-decoration:none;" onclick="location.href = 'blog/#category=' + encodeURIComponent('Quality Leadership & Industry Practice'); return false;">Quality, Leadership &amp; Industry Practice →</a>
</div>
```

（顯示文字用帶逗號的 `Quality, Leadership & Industry Practice`——可讀性
較好；`onclick` 裡實際比對用的是不含逗號的技術值，兩者故意不同，見「實作
踩坑紀錄」第 1 點。）

**「瀏覽全部」區塊**：跟上面 4 個主題連結明顯用間距分開，兩個入口——
`All Blog Articles →`（連到 `blog/`，取代原本的「View all articles」，
更明確強調是部落格文章）與 `Conference Talks & Posters →`（連到
`Speaker.qmd`，取代原本規劃裡完全拿掉的 Presentations 連結；下方另外加一行
斜體小字列出實際參與過的研討會：`useR!, R/Pharma, ShinyConf, PharmaSUG`）：

```html
<div style="margin-top: 1em;">
<a href="blog/" style="display:block; padding: 0.2em 0; text-decoration:none;">All Blog Articles →</a>
<a href="Speaker.qmd" style="display:block; padding: 0.2em 0; text-decoration:none;">Conference Talks &amp; Posters →</a>
<div style="font-size: 0.85em; color: #6c757d; padding-left: 0.05em; font-style: italic;">useR!, R/Pharma, ShinyConf, PharmaSUG</div>
</div>
```

導覽列本身的 `Presentations` 入口維持不動，這裡的命名調整只影響首頁連結
文字，不影響導覽列。

### 6. CV 下載（已完成實作）

- 使用者提供原始 Word 檔（`__Career/CV/CV_202607/CV_Winkle Lu_Statistical Programmer_20260712_Origin.docx`），本機用 Microsoft Word（AppleScript 自動化）轉成 PDF，保留原始排版與格式。
- 用 Python（`pypdf` + `reportlab`，裝在暫用的 venv 裡，不動系統 Python）在每一頁疊加浮水印：文字
  `Downloaded from Winkle Lu's personal website — for reference only`，淡灰色、45 度斜對角、貫穿整頁、半透明，不擋內容閱讀。
- 最終檔案放在 `files/CV_Winkle Lu_Statistical Programmer_20260712_ForReferenceOnly.pdf`——比原始檔名拿掉 `_Origin`，改成 `_ForReferenceOnly`，讓下載後的檔名本身就標示這是公開參考版本。
- `index.qmd` 的 `about.links` 新增一筆 `Download CV` 連結（`icon: file-earmark-pdf`），跟 LinkedIn / GitHub 並列，Email 放在最後。
- `files/` 資料夾不會被 Quarto 自動複製進 `docs/` 輸出目錄，因此在 `_post-render.R` 裡新增第三段邏輯，比照專案裡既有的 `winviz.html`／`tools/` 複製方式，把 `files/` 也複製進 `docs/files/`。
- 已用 `fetch()` 實測連結：HTTP 200、`content-type: application/pdf`、檔案大小與來源一致。

### 7. 新文章的維護方式

新文章只要在自己的 `categories:` 欄位裡包含對應的主分類全名（連同想加的
細標籤），存檔後就會自動被首頁卡片與 Blog 篩選按鈕正確篩選到——**不需要
額外腳本，也不需要回頭手動改 `blog/index.qmd`**。唯一要注意的規則：分類
名稱本身不能包含逗號（見「實作踩坑紀錄」第 1 點）。

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

## 實作踩坑紀錄

實作並在 `quarto preview` + 瀏覽器實測後，發現兩個原生機制沒有事先預期到
的細節，記錄下來避免以後重踩：

1. **分類名稱不能包含逗號。** Quarto 把一篇文章的多個 `categories:` 值，
   內部用逗號 join 成一個字串存進 `data-categories` 屬性，篩選時再用逗號
   `split(',')` 拆回陣列。如果分類名稱本身含有逗號（一開始選的
   `"Quality, Leadership & Industry Practice"` 就是），會被自己的逗號從
   中間拆成兩截，導致這個分類永遠篩不到任何文章（`filterListingCategory`
   比對不到完整字串）。已改名為 `Quality Leadership & Industry Practice`
   （拿掉逗號）解決。**以後新增分類或幫文章加分類時，分類名稱一律不能有
   逗號。**
2. **首頁的動態分類連結不能用 markdown `[text](url)` 語法。** 一開始用
   `[Clinical Programming & Regulatory Delivery](blog/#category=Clinical%20Programming%20%26%20Regulatory%20Delivery)`
   這種寫法，Pandoc 在轉成 HTML 時會「部分解碼」網址——把 `%20` 還原成
   真正的空白字元，但 `%26`、`%2C` 這種符號的編碼留著不動，產生一個不乾淨、
   容易在不同瀏覽器行為不一致的網址。改成手寫 raw HTML `<a>` 標籤，
   `href` 用 `onclick` + `encodeURIComponent()` 在點擊當下即時組出來，
   完全繞過 Pandoc 的網址處理，才穩定可靠。
3. **「顯示文字」跟「比對用的技術值」可以刻意不同。** `Quality, Leadership
   & Industry Practice`（有逗號，可讀性好）只用在畫面上顯示的文字；實際
   `onclick`／`data-category` 用來比對篩選的字串一律是拿掉逗號的
   `Quality Leadership & Industry Practice`。兩者是分開的，改其中一個不會
   影響另一個，但**如果以後要改分類的顯示文字，記得同時檢查 onclick 裡的
   技術值有沒有需要一起改**。
4. **Quarto 原生機制在「網址沒有指定分類」時，不會自動把 All Articles
   標成選中狀態。** 不管是新鮮進入 `blog/`（完全無 hash），還是進入
   `blog/#category=`（空值 hash），Quarto 自己的 `quarto-listing-loaded`
   初始化邏輯裡 `if (hash.category)` 這個判斷式會把空字串當成 falsy 略過，
   導致兩種情況都不會呼叫 `activateCategory("")`。這是 Quarto 原生機制
   本身的行為（不是這次改版才有的新問題，理論上原本的內建側邊欄也有一樣的
   限制），修法是在 `blog/index.qmd` 額外包一層 `window["quarto-listing-loaded"]`
   ——保留原本的行為，再補一個判斷：如果沒有任何分類是 `.active`，就手動
   把 All Articles 標成選中。
5. **自訂側邊欄要自己補分類文章數。** 原生 `categories: true` 側邊欄會
   自動在每個分類後面顯示 `(N)` 篇數，改成手寫的 5 個項目後，這個數字
   不會自動出現，要照第 2b 節算好的篩選後篇數（5／13／13／3／29）手動寫進
   `<span class="quarto-category-count">(N)</span>`。

## Spec 存放位置說明

放在 `.claude/specs/`，不用技能預設的 `docs/superpowers/specs/`——因為
`docs/` 是 Quarto 網站實際的建置輸出目錄（`_quarto.yml: output-dir: docs`，
發布到 GitHub Pages），不適合放這種不對外發布的規劃文件。（與
`.claude/specs/2026-07-19-patient-timeline-design.md` 已確立的理由一致。）

## 待辦事項

全部項目（Blog 五大分類篩選、首頁改版、CV 下載）已實作完成並在本機
`quarto preview` + 瀏覽器實測驗證通過。目前沒有已知的待辦事項。
