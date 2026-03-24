# _post-render.R
# 每次 quarto render 後自動執行
# 從根目錄的 winviz.html 複製到 docs/

if (file.exists("winviz.html")) {
  file.copy("winviz.html", "docs/winviz.html", overwrite = TRUE)
  cat("✅ docs/winviz.html restored from root\n")
} else {
  cat("⚠️  winviz.html not found in root directory\n")
}
