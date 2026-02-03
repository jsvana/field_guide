#!/usr/bin/env python3
"""Extract text content from image-based PDFs using OCR.

This script handles PDFs where text is embedded as images (e.g., scanned documents
or PDFs created with CorelDRAW). It uses PyMuPDF to extract images and pytesseract
for OCR.

Requirements:
    - tesseract: brew install tesseract
    - Python packages: pip install pytesseract pillow

Usage:
    python extract_content_ocr.py <radio_id>
    python extract_content_ocr.py --all
    python extract_content_ocr.py --check  # Check which PDFs need OCR
"""

import argparse
import io
import json
from pathlib import Path

import fitz  # PyMuPDF

try:
    import pytesseract
    from PIL import Image

    OCR_AVAILABLE = True
except ImportError:
    OCR_AVAILABLE = False

from download_pdfs import MANUALS


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


def extract_text_ocr(pdf_path: Path) -> list[dict]:
    """Extract text from PDF using OCR on rendered pages."""
    if not OCR_AVAILABLE:
        raise RuntimeError(
            "OCR dependencies not available. Install with:\n"
            "  brew install tesseract\n"
            "  pip install pytesseract pillow"
        )

    doc = fitz.open(pdf_path)
    pages = []

    for page_num, page in enumerate(doc):
        # Render page to image at high DPI for better OCR
        # Using 150 DPI as a balance between quality and speed
        mat = fitz.Matrix(150 / 72, 150 / 72)  # 150 DPI
        pix = page.get_pixmap(matrix=mat)

        # Convert to PIL Image
        img_data = pix.tobytes("png")
        img = Image.open(io.BytesIO(img_data))

        # Run OCR
        text = pytesseract.image_to_string(img, lang="eng")

        pages.append(
            {
                "page": page_num + 1,
                "text": text,
            }
        )

        print(f"  Page {page_num + 1}/{len(doc)}: {len(text)} chars")

    doc.close()
    return pages


def extract_text_native(pdf_path: Path) -> list[dict]:
    """Extract text from PDF using native text extraction."""
    doc = fitz.open(pdf_path)
    pages = []

    for page_num, page in enumerate(doc):
        text = page.get_text()
        pages.append(
            {
                "page": page_num + 1,
                "text": text,
            }
        )

    doc.close()
    return pages


def save_raw_text(radio_id: str, pages: list[dict], output_dir: Path, suffix: str = ""):
    """Save raw extracted text for manual review."""
    filename = f"{radio_id}_raw_text{suffix}.txt"
    text_file = output_dir / filename

    with open(text_file, "w") as f:
        for page in pages:
            f.write(f"\n{'=' * 60}\n")
            f.write(f"PAGE {page['page']}\n")
            f.write(f"{'=' * 60}\n\n")
            f.write(page["text"])

    print(f"  Raw text saved to: {text_file}")
    return text_file


def generate_skeleton(radio_id: str, pages: list[dict]) -> dict:
    """Generate a skeleton JSON structure for manual curation."""
    manual = MANUALS[radio_id]

    # Combine all text for reference
    all_text = "\n".join(p["text"] for p in pages)

    # Predefined sections we want to extract
    target_sections = [
        "Operation Basics",
        "Menu System Reference",
        "CW/Keyer Settings",
        "Filters & DSP",
        "Power & Battery",
        "ATU Operation",
        "Specifications",
        "Quick Troubleshooting",
    ]

    sections = []
    for i, title in enumerate(target_sections):
        sections.append(
            {
                "id": f"{radio_id}-{title.lower().replace(' ', '-').replace('/', '-').replace('&', 'and')}",
                "title": title,
                "sortOrder": i + 1,
                "blocks": [
                    {
                        "type": "paragraph",
                        "text": f"[TODO: Extract {title} content from OCR text]",
                    }
                ],
                "_sourcePages": "[TODO: Add relevant page numbers]",
            }
        )

    return {
        "radio": {
            "id": radio_id,
            "manufacturer": manual.get("manufacturer", "Unknown"),
            "model": manual["name"],
            "revision": manual["revision"],
            "pdfFilename": manual["filename"],
        },
        "sections": sections,
        "_pageCount": len(pages),
        "_extractionMethod": "ocr",
    }


def check_pdfs():
    """Check which PDFs need OCR vs native extraction."""
    content_dir = Path(__file__).parent.parent / "content"
    pdf_dir = content_dir / "pdfs"

    print("Checking PDFs for extraction method...\n")
    print(f"{'Radio ID':<25} {'PDF Size':>10} {'Method':<10} {'Notes'}")
    print("-" * 70)

    for radio_id, manual in MANUALS.items():
        pdf_path = pdf_dir / manual["filename"]

        if not pdf_path.exists():
            print(f"{radio_id:<25} {'N/A':>10} {'missing':<10} PDF not downloaded")
            continue

        size_mb = pdf_path.stat().st_size / (1024 * 1024)

        try:
            ocr_needed = needs_ocr(pdf_path)
            method = "OCR" if ocr_needed else "native"
            notes = "image-based" if ocr_needed else "text-based"
        except Exception as e:
            method = "error"
            notes = str(e)[:30]

        print(f"{radio_id:<25} {size_mb:>9.1f}M {method:<10} {notes}")


def main():
    parser = argparse.ArgumentParser(description="Extract content from PDFs using OCR")
    parser.add_argument(
        "radio_id", nargs="?", choices=list(MANUALS.keys()), help="Radio ID to extract"
    )
    parser.add_argument(
        "--all", action="store_true", help="Extract all radios that need OCR"
    )
    parser.add_argument(
        "--check", action="store_true", help="Check which PDFs need OCR"
    )
    parser.add_argument(
        "--force-ocr",
        action="store_true",
        help="Force OCR even if native text extraction works",
    )
    args = parser.parse_args()

    if args.check:
        check_pdfs()
        return

    if not args.all and not args.radio_id:
        parser.error("Either provide a radio_id, use --all, or use --check")

    content_dir = Path(__file__).parent.parent / "content"
    pdf_dir = content_dir / "pdfs"
    output_dir = content_dir / "extracted"
    output_dir.mkdir(parents=True, exist_ok=True)

    radios_to_process = list(MANUALS.keys()) if args.all else [args.radio_id]

    for radio_id in radios_to_process:
        manual = MANUALS[radio_id]
        pdf_path = pdf_dir / manual["filename"]

        if not pdf_path.exists():
            print(f"PDF not found: {pdf_path}")
            print("Run download_pdfs.py first.")
            continue

        print(f"\nProcessing {manual['name']}...")

        # Check if OCR is needed
        ocr_needed = needs_ocr(pdf_path) or args.force_ocr

        if ocr_needed:
            if not OCR_AVAILABLE:
                print("  ERROR: OCR required but dependencies not installed.")
                print("  Install with:")
                print("    brew install tesseract")
                print("    pip install pytesseract pillow")
                continue

            print("  Using OCR extraction (image-based PDF)...")
            pages = extract_text_ocr(pdf_path)
            suffix = "_ocr"
        else:
            print("  Using native text extraction...")
            pages = extract_text_native(pdf_path)
            suffix = ""

        # Save raw text
        save_raw_text(radio_id, pages, output_dir, suffix)

        # Generate skeleton
        print("  Generating skeleton JSON...")
        skeleton = generate_skeleton(radio_id, pages)

        json_file = output_dir / f"{radio_id}_skeleton{suffix}.json"
        with open(json_file, "w") as f:
            json.dump(skeleton, f, indent=2)
        print(f"  Skeleton saved to: {json_file}")

    print(
        "\nDone! Review the extracted files and manually curate content.json for each radio."
    )


if __name__ == "__main__":
    main()
