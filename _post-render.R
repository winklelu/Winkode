# _post-render.R
# 每次 quarto render 後自動執行
# 從根目錄複製 winviz.html、tools/、files/ 到 docs/

# --- 1. winviz.html ---
if (file.exists("winviz.html")) {
  file.copy("winviz.html", "docs/winviz.html", overwrite = TRUE)
  cat("✅ docs/winviz.html restored from root\n")
} else {
  cat("⚠️  winviz.html not found in root directory\n")
}

# --- 2. tools/ ---
if (dir.exists("tools")) {
  tool_dirs <- list.dirs("tools", recursive = FALSE)
  for (d in tool_dirs) {
    dest <- file.path("docs", d)
    if (!dir.exists(dest)) dir.create(dest, recursive = TRUE)
    files <- list.files(d, full.names = TRUE)
    if (length(files) > 0) {
      file.copy(files, dest, overwrite = TRUE)
    }
  }
  cat("✅ docs/tools/ restored from root\n")
} else {
  cat("⚠️  tools/ not found in root directory\n")
}

# --- 3. files/ ---
if (dir.exists("files")) {
  if (!dir.exists("docs/files")) dir.create("docs/files", recursive = TRUE)
  files <- list.files("files", full.names = TRUE)
  if (length(files) > 0) {
    file.copy(files, "docs/files", overwrite = TRUE)
  }
  cat("✅ docs/files/ restored from root\n")
} else {
  cat("⚠️  files/ not found in root directory\n")
}
