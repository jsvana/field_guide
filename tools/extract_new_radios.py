#!/usr/bin/env python3
"""Extract text from new radio PDFs.

Supports both native text extraction and OCR for image-based PDFs.

Requirements for OCR:
    brew install tesseract
    pip install pytesseract pillow
"""

import argparse
import io
from pathlib import Path

import fitz

try:
    import pytesseract
    from PIL import Image

    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

NEW_RADIOS = [
    ("icom-ic705", "ICOM", "IC-705", "IC-705_Basic_Manual.pdf"),
    ("icom-ic7100", "ICOM", "IC-7100", "IC-7100_Manual.pdf"),
    ("icom-ic7300", "ICOM", "IC-7300", "IC-7300_Full_Manual.pdf"),
    ("icom-ic7300mk2", "ICOM", "IC-7300MK2", "IC-7300MK2_Manual.pdf"),
    ("yaesu-ftdx101mp", "Yaesu", "FT-DX101MP", "FT-DX101MP_Manual.pdf"),
    ("yaesu-ft991a", "Yaesu", "FT-991A", "FT-991A_Manual.pdf"),
    ("yaesu-ft710", "Yaesu", "FT-710", "FT-710_Manual.pdf"),
    ("yaesu-ftx1", "Yaesu", "FTX-1", "FTX-1_Manual.pdf"),
    ("venus-sw3b", "Venus", "SW-3B", "SW-3B_Manual.pdf"),
    ("venus-sw6b", "Venus", "SW-6B", "SW-6B_Manual.pdf"),
    ("penntek-tr25", "PennTek", "TR-25", "TR-25_Manual.pdf"),
    ("bg2fx-fx4cr", "BG2FX", "FX-4CR", "FX-4CR_Manual.pdf"),
]

# PDFs that need OCR (image-based, no extractable text)
NEEDS_OCR = {"venus-sw6b"}


def needs_ocr(pdf_path: Path) -> bool:
    """Check if a PDF needs OCR (has images but no text)."""
    doc = fitz.open(pdf_path)

    total_text = 0
    total_images = 0

    for page in doc:
        total_text += len(page.get_text().strip())
        total_images += len(page.get_images())

    doc.close()

    # If there's very little text but images exist, OCR is needed
    return total_text < 500 and total_images > 0


def extract_with_ocr(pdf_path: Path) -> list[str]:
    """Extract text using OCR."""
    if not OCR_AVAILABLE:
        raise RuntimeError(
            "OCR dependencies not available. Install with:\n"
            "  brew install tesseract\n"
            "  pip install pytesseract pillow"
        )

    doc = fitz.open(pdf_path)
    pages = []

    for page_num, page in enumerate(doc):
        # Render page to image at 150 DPI
        mat = fitz.Matrix(150 / 72, 150 / 72)
        pix = page.get_pixmap(matrix=mat)

        # Convert to PIL Image
        img_data = pix.tobytes("png")
        img = Image.open(io.BytesIO(img_data))

        # Run OCR
        text = pytesseract.image_to_string(img, lang="eng")
        pages.append(text)

        print(f"    Page {page_num + 1}/{len(doc)}: {len(text)} chars (OCR)")

    doc.close()
    return pages


def extract_native(pdf_path: Path) -> list[str]:
    """Extract text using native PDF text extraction."""
    doc = fitz.open(pdf_path)
    pages = []

    for page in doc:
        pages.append(page.get_text())

    doc.close()
    return pages


def main():
    parser = argparse.ArgumentParser(description="Extract text from radio PDFs")
    parser.add_argument("radio_id", nargs="?", help="Specific radio to extract")
    parser.add_argument(
        "--check", action="store_true", help="Check which PDFs need OCR"
    )
    args = parser.parse_args()

    output_dir = Path("content/extracted")
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.check:
        print("Checking PDFs for extraction method...\n")
        for radio_id, manufacturer, model, pdf_filename in NEW_RADIOS:
            pdf_path = Path(f"content/pdfs/{pdf_filename}")
            if not pdf_path.exists():
                print(f"{radio_id}: MISSING")
                continue

            ocr_needed = needs_ocr(pdf_path)
            method = "OCR" if ocr_needed else "native"
            print(f"{radio_id}: {method}")
        return

    radios_to_process = NEW_RADIOS
    if args.radio_id:
        radios_to_process = [r for r in NEW_RADIOS if r[0] == args.radio_id]
        if not radios_to_process:
            print(f"Unknown radio: {args.radio_id}")
            print(f"Available: {', '.join(r[0] for r in NEW_RADIOS)}")
            return

    for radio_id, manufacturer, model, pdf_filename in radios_to_process:
        pdf_path = Path(f"content/pdfs/{pdf_filename}")
        if not pdf_path.exists():
            print(f"Missing: {pdf_path}")
            continue

        print(f"Extracting {model}...")

        # Check if OCR is needed
        use_ocr = radio_id in NEEDS_OCR or needs_ocr(pdf_path)

        if use_ocr:
            if not OCR_AVAILABLE:
                print(f"  SKIPPED: {radio_id} needs OCR but dependencies not installed")
                print(
                    "  Install with: brew install tesseract && pip install pytesseract pillow"
                )
                continue
            print(f"  Using OCR (image-based PDF)...")
            pages = extract_with_ocr(pdf_path)
        else:
            print(f"  Using native text extraction...")
            pages = extract_native(pdf_path)

        separator = "=" * 60
        with open(output_dir / f"{radio_id}_raw_text.txt", "w") as f:
            for page_num, text in enumerate(pages):
                f.write(f"\n{separator}\n")
                f.write(f"PAGE {page_num + 1}\n")
                f.write(f"{separator}\n\n")
                f.write(text)

        print(f"  Saved {radio_id}_raw_text.txt")

    print("\nDone extracting PDFs!")


if __name__ == "__main__":
    main()
