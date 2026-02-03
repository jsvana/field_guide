#!/usr/bin/env python3
"""Extract text content from Elecraft PDF manuals."""

import argparse
import json
import re
from pathlib import Path

import fitz  # PyMuPDF

from download_pdfs import MANUALS


def extract_text_by_page(pdf_path: Path) -> list[dict]:
    """Extract text from each page of a PDF."""
    doc = fitz.open(pdf_path)
    pages = []

    for page_num, page in enumerate(doc):
        text = page.get_text()
        pages.append({
            "page": page_num + 1,
            "text": text,
        })

    doc.close()
    return pages


def find_toc_entries(pages: list[dict]) -> list[dict]:
    """Attempt to identify table of contents entries."""
    toc_entries = []

    # Look for common TOC patterns
    toc_pattern = re.compile(
        r'^([A-Z][A-Za-z\s&/-]+?)\.{2,}\s*(\d+)\s*$',
        re.MULTILINE
    )

    for page_data in pages[:10]:  # TOC usually in first 10 pages
        matches = toc_pattern.findall(page_data["text"])
        for title, page_num in matches:
            toc_entries.append({
                "title": title.strip(),
                "page": int(page_num),
            })

    return toc_entries


def extract_menu_entries(text: str) -> list[dict]:
    """Extract menu entries from text."""
    entries = []

    # Common Elecraft menu patterns: "MENU NAME - description" or "MENU NAME: description"
    menu_pattern = re.compile(
        r'^([A-Z][A-Z0-9\s]{2,20})\s*[-:–]\s*(.+?)(?=\n[A-Z][A-Z0-9\s]{2,20}\s*[-:–]|\n\n|\Z)',
        re.MULTILINE | re.DOTALL
    )

    matches = menu_pattern.findall(text)
    for name, description in matches:
        name = name.strip()
        description = ' '.join(description.split())  # Normalize whitespace
        if len(name) <= 20 and len(description) > 10:
            entries.append({
                "type": "menuEntry",
                "name": name,
                "description": description[:500],  # Limit length
            })

    return entries


def generate_skeleton(radio_id: str, pages: list[dict], toc: list[dict]) -> dict:
    """Generate a skeleton JSON structure for manual curation."""
    manual = MANUALS[radio_id]

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
        sections.append({
            "id": f"{radio_id}-{title.lower().replace(' ', '-').replace('/', '-').replace('&', 'and')}",
            "title": title,
            "sortOrder": i + 1,
            "blocks": [
                {
                    "type": "paragraph",
                    "text": f"[TODO: Extract {title} content from PDF]"
                }
            ],
            "_sourcePages": "[TODO: Add relevant page numbers from PDF]",
        })

    return {
        "radio": {
            "id": radio_id,
            "manufacturer": "Elecraft",
            "model": manual["name"],
            "revision": manual["revision"],
            "pdfFilename": manual["filename"],
        },
        "sections": sections,
        "_extractedTOC": toc,
        "_pageCount": len(pages),
    }


def save_raw_text(radio_id: str, pages: list[dict], output_dir: Path):
    """Save raw extracted text for manual review."""
    text_file = output_dir / f"{radio_id}_raw_text.txt"

    with open(text_file, "w") as f:
        for page in pages:
            f.write(f"\n{'='*60}\n")
            f.write(f"PAGE {page['page']}\n")
            f.write(f"{'='*60}\n\n")
            f.write(page["text"])

    print(f"  Raw text saved to: {text_file}")


def main():
    parser = argparse.ArgumentParser(description="Extract content from Elecraft PDFs")
    parser.add_argument("radio_id", choices=list(MANUALS.keys()),
                        help="Radio ID to extract")
    parser.add_argument("--all", action="store_true",
                        help="Extract all radios")
    args = parser.parse_args()

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

        # Extract text
        print("  Extracting text...")
        pages = extract_text_by_page(pdf_path)

        # Save raw text for review
        save_raw_text(radio_id, pages, output_dir)

        # Find TOC
        print("  Looking for TOC entries...")
        toc = find_toc_entries(pages)
        print(f"  Found {len(toc)} TOC entries")

        # Generate skeleton
        print("  Generating skeleton JSON...")
        skeleton = generate_skeleton(radio_id, pages, toc)

        # Save skeleton
        json_file = output_dir / f"{radio_id}_skeleton.json"
        with open(json_file, "w") as f:
            json.dump(skeleton, f, indent=2)
        print(f"  Skeleton saved to: {json_file}")

    print("\nDone! Review the extracted files and manually curate content.json for each radio.")


if __name__ == "__main__":
    main()
