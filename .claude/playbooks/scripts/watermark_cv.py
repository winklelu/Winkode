"""Overlay a diagonal watermark on every page of a PDF.

Usage:
    python watermark_cv.py <input.pdf> <output.pdf> ["watermark text"]

Requires pypdf + reportlab (see updating-cv.md for how to install them
into a throwaway venv without touching system Python).
"""

import sys
import io
from reportlab.pdfgen import canvas
from reportlab.lib.colors import Color
from pypdf import PdfReader, PdfWriter

DEFAULT_TEXT = "Downloaded from Winkle Lu's personal website — for reference only"


def watermark(src_path: str, out_path: str, text: str = DEFAULT_TEXT) -> None:
    reader = PdfReader(src_path)
    page0 = reader.pages[0]
    width = float(page0.mediabox.width)
    height = float(page0.mediabox.height)

    buf = io.BytesIO()
    c = canvas.Canvas(buf, pagesize=(width, height))
    c.saveState()
    c.translate(width / 2, height / 2)
    c.rotate(45)
    c.setFillColor(Color(0.6, 0.6, 0.6, alpha=0.35))
    c.setFont("Helvetica-Bold", 18)
    c.drawCentredString(0, 0, text)
    c.restoreState()
    c.save()
    buf.seek(0)

    watermark_page = PdfReader(buf).pages[0]

    writer = PdfWriter()
    for page in reader.pages:
        page.merge_page(watermark_page)
        writer.add_page(page)

    with open(out_path, "wb") as f:
        writer.write(f)

    print(f"done: {out_path} ({len(writer.pages)} pages)")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    src, out = sys.argv[1], sys.argv[2]
    watermark_text = sys.argv[3] if len(sys.argv) > 3 else DEFAULT_TEXT
    watermark(src, out, watermark_text)
