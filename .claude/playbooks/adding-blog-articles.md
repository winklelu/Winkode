# 新增部落格文章時，分類怎麼處理

背景設計理由見 `.claude/specs/2026-08-05-blog-categories-cv-download-design.md`。
這份文件只講「以後每次寫新文章，具體要做什麼」。

## 1. 判斷屬於哪個分類

固定 4 個主分類（順序固定，不依文章數量排）：

1. **Clinical Programming & Regulatory Delivery** — SAS、CDISC、SDTM/ADaM、
   Define-XML、法規交付、驗證/QC 文件
2. **Data Review & Visualization** — 資料檢閱工具、視覺化技巧（不限臨床，
   一般 R/資料視覺化技巧文章也算這類）
3. **Automation & Reproducible Workflows** — Quarto/YAML/Git 工作流程、
   一般 R 技巧、AI 工具協作、開發環境設定
4. **Quality Leadership & Industry Practice** — 職涯反思、團隊管理、產業
   觀察、學習心得類文章

**判斷原則**：看這篇文章「主要解決什麼專業問題」，不是看「用了什麼工具」。
用 R/Shiny/D3.js 寫的文章不會自動歸類到 Automation 或 Data Review——如果
內容本質是法規交付（例如用 R 重建 define.xml），還是要放
Clinical Programming & Regulatory Delivery。

**多個分類都適用時**：可以同時加兩三個分類值，不需要只選一個。已有先例
（`07-APR-2026-Forest-Plot-YAML-Quarto-Workflow.qmd` 同時屬於三類）。

## 2. 加進文章的 YAML

在文章自己的 `categories:` 陣列**後面加**選定的分類全名，不要動原本已有
的細標籤：

```yaml
# 原本
categories: [R, Shiny, Plotly, Clinical Trials, Safety]

# 加分類後
categories: [R, Shiny, Plotly, Clinical Trials, Safety, "Data Review & Visualization"]
```

**⚠️ 分類名稱一律不能包含逗號**（技術限制，見 spec「實作踩坑紀錄」第 1
點）。目前是 `Quality Leadership & Industry Practice`，故意沒有逗號——
Blog 頁面畫面上顯示的文字可以帶逗號（`Quality, Leadership & Industry
Practice`），但 YAML 這裡、以及任何用來比對篩選的地方，一律用不帶逗號的
版本。

四個分類的精確字串（複製貼上用，避免手動輸入打錯字）：

```
Clinical Programming & Regulatory Delivery
Data Review & Visualization
Automation & Reproducible Workflows
Quality Leadership & Industry Practice
```

## 3. 別忘記：Blog 頁面的分類篇數是手動維護的

`blog/index.qmd` 裡右側分類清單的 `(N)` 篇數是寫死的 HTML，**不會自動
更新**。新增文章後，記得手動把對應分類（以及 All Articles）的數字 +1：

```html
<div class="category" data-category="...">Data Review &amp; Visualization <span class="quarto-category-count">(13)</span></div>
```

目前（2026-08-06）的篇數：Clinical Programming & Regulatory Delivery
(5)、Data Review & Visualization (13)、Automation & Reproducible
Workflows (13)、Quality Leadership & Industry Practice (3)、All Articles
(29)。

如果文章同時加了兩個以上分類，每個相關分類的數字都要 +1（All Articles
只 +1，不管加了幾個分類）。

## 4. 完成後

- `quarto render blog/index.qmd` 確認沒有 render 錯誤
- 用瀏覽器（或 `quarto preview`）點一下該分類的篩選按鈕，確認新文章有
  出現、篇數正確
- 不需要改 `index.qmd` 首頁——首頁的 5 個分類連結是用網址 hash 篩選，
  不需要跟著文章數量更新
