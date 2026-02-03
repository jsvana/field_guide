#!/usr/bin/env python3
"""Extract text from new radio PDFs."""

from pathlib import Path

import fitz

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


def main():
    output_dir = Path("content/extracted")
    output_dir.mkdir(parents=True, exist_ok=True)

    for radio_id, manufacturer, model, pdf_filename in NEW_RADIOS:
        pdf_path = Path(f"content/pdfs/{pdf_filename}")
        if not pdf_path.exists():
            print(f"Missing: {pdf_path}")
            continue

        print(f"Extracting {model}...")
        doc = fitz.open(pdf_path)

        separator = "=" * 60
        with open(output_dir / f"{radio_id}_raw_text.txt", "w") as f:
            for page_num, page in enumerate(doc):
                f.write(f"\n{separator}\n")
                f.write(f"PAGE {page_num + 1}\n")
                f.write(f"{separator}\n\n")
                f.write(page.get_text())

        doc.close()
        print(f"  Saved {radio_id}_raw_text.txt")

    print("\nDone extracting all PDFs!")


if __name__ == "__main__":
    main()
