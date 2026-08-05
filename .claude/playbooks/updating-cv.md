# 更新 CV 下載檔案

背景設計理由見 `.claude/specs/2026-08-05-blog-categories-cv-download-design.md`
第 6 節。這份文件只講「以後每次要換新版 CV，具體步驟是什麼」。

**這份文件故意不寫死本機 CV 資料夾的絕對路徑**（這個 repo 是公開的，見
`.claude/playbooks/README.md` 的提醒）——每次執行前，先跟使用者確認最新
版 Word 檔案在電腦上的完整路徑。

## 命名規則

- 來源 Word 檔通常長這樣：`CV_Winkle Lu_Statistical Programmer_<YYYYMMDD>_Origin.docx`
- 網站上放的下載檔命名規則：把 `_Origin` 換成 `_ForReferenceOnly`，日期
  照抄來源檔的日期：

  ```
  files/CV_Winkle Lu_Statistical Programmer_<YYYYMMDD>_ForReferenceOnly.pdf
  ```

## 步驟

### 1. Word → PDF（保留原始排版）

用 Microsoft Word 本身轉檔（比 pandoc/LaTeX 路線更能保留使用者在 Word
裡排好的版面），透過 AppleScript 自動化：

```bash
osascript <<'EOF'
tell application "Microsoft Word"
	activate
	set srcPath to "<使用者提供的 .docx 絕對路徑>"
	set outPath to "/tmp/cv_work/cv_raw.pdf"
	open srcPath
	set theDoc to active document
	save as theDoc file name outPath file format format PDF
	close theDoc saving no
end tell
EOF
```

### 2. 加浮水印

系統 Python（Homebrew 版）預設不給裝套件（PEP 668），要用暫用的 venv，
不要對系統 Python 用 `--break-system-packages`：

```bash
python3 -m venv /tmp/cv_work/venv
/tmp/cv_work/venv/bin/pip install --quiet pypdf reportlab
```

用 `.claude/playbooks/scripts/watermark_cv.py`（可重複使用，不用每次重寫）：

```bash
/tmp/cv_work/venv/bin/python \
  "<repo 路徑>/.claude/playbooks/scripts/watermark_cv.py" \
  /tmp/cv_work/cv_raw.pdf \
  /tmp/cv_work/cv_watermarked.pdf
```

浮水印文字預設是「Downloaded from Winkle Lu's personal website — for
reference only」，淡灰色、45 度斜對角、貫穿整頁。要換文字就加第三個
參數。

**做完務必用 Read 工具實際看過每一頁**（`pages: "1-4"` 之類），確認浮水印
沒有擋住內容、頁數跟預期一致——不要只看程式跑完沒有報錯就假設沒問題。

### 3. 換掉專案裡的檔案

```bash
cd "<repo 路徑>"
git rm --quiet "files/CV_Winkle Lu_Statistical Programmer_<舊日期>_ForReferenceOnly.pdf"
mkdir -p files   # git rm 把資料夾裡最後一個檔案刪掉後，資料夾本身也會消失，要重建
cp /tmp/cv_work/cv_watermarked.pdf "files/CV_Winkle Lu_Statistical Programmer_<新日期>_ForReferenceOnly.pdf"
```

### 4. 更新首頁連結

`index.qmd` 的 `about.links` 裡找 `Download CV` 那一筆，`href` 裡的日期
換成新的。**注意檔名裡的空白要用 `%20`**（`about.links` 的 `href` 不會
自動處理，用 raw 空白字元有機會在不同瀏覽器行為不一致）：

```yaml
    - icon: file-earmark-pdf
      text: Download CV
      href: "files/CV_Winkle%20Lu_Statistical%20Programmer_<新日期>_ForReferenceOnly.pdf"
```

### 5. Render 並確認 `docs/files/` 有更新

`files/` 不會被 Quarto 自動複製進 `docs/`，是 `_post-render.R` 裡手動加的
複製邏輯（比照 `winviz.html`／`tools/` 的既有做法），每次 render 都會自動
跑，不用額外做什麼，但要記得刪掉 `docs/files/` 裡的舊檔：

```bash
rm -f "docs/files/CV_Winkle Lu_Statistical Programmer_<舊日期>_ForReferenceOnly.pdf" docs/index.html
quarto render index.qmd
```

### 6. 實測下載連結

用瀏覽器打開首頁，點 Download CV，或直接用 fetch 確認網址回 200、
`content-type: application/pdf`：

```js
const href = Array.from(document.querySelectorAll('a'))
  .find(a => a.textContent.includes('Download CV')).href;
const r = await fetch(href);
({ status: r.status, contentType: r.headers.get('content-type') })
```

### 7. Commit

`files/` 跟 `docs/files/` 的舊檔用 `git rm`（步驟 3 已經做了），連同
`index.qmd`、`docs/index.html` 等 render 產物一起 commit。
