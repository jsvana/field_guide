# Carrier Wave Field Guide Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build an offline-first iOS app for Elecraft radio manuals with pre-curated, styled content and raw PDF access.

**Architecture:** Two-part project: (1) Python tooling to download PDFs and extract content into structured JSON, (2) SwiftUI app with SwiftData persistence, PDFKit viewing, and tab-based navigation following Carrier Wave design language.

**Tech Stack:**
- Content tooling: Python 3.11+, PyMuPDF (fitz), JSON
- iOS app: SwiftUI, SwiftData, PDFKit, iOS 17+

---

## Phase 1: Content Tooling

### Task 1: Set Up Python Project Structure

**Files:**
- Create: `tools/requirements.txt`
- Create: `tools/download_pdfs.py`
- Create: `tools/README.md`

**Step 1: Create tools directory and requirements**

```bash
mkdir -p tools
```

Create `tools/requirements.txt`:
```
pymupdf>=1.23.0
```

**Step 2: Create PDF download script**

Create `tools/download_pdfs.py`:
```python
#!/usr/bin/env python3
"""Download Elecraft PDF manuals."""

import urllib.request
import urllib.parse
from pathlib import Path

MANUALS = {
    "elecraft-k1": {
        "name": "K1",
        "url": "https://ftp.elecraft.com/K1/Manuals%20Downloads/E740016%20K1%20manual%20rev%20J.pdf",
        "filename": "E740016_K1_manual_rev_J.pdf",
        "revision": "J",
    },
    "elecraft-k2": {
        "name": "K2",
        "url": "https://ftp.elecraft.com/K2/Manuals%20Downloads/E740001_K2%20Owner's%20Manual%20Rev%20I.pdf",
        "filename": "E740001_K2_Owners_Manual_Rev_I.pdf",
        "revision": "I",
    },
    "elecraft-kx1": {
        "name": "KX1",
        "url": "https://ftp.elecraft.com/KX1/Manuals%20Downloads/KX1_Owner's_Manual_Rev_E.pdf",
        "filename": "KX1_Owners_Manual_Rev_E.pdf",
        "revision": "E",
    },
    "elecraft-kx2": {
        "name": "KX2",
        "url": "https://ftp.elecraft.com/KX2/Manuals%20Downloads/KX2%20owner's%20man%20B2.pdf",
        "filename": "KX2_owners_man_B2.pdf",
        "revision": "B2",
    },
}


def download_pdf(radio_id: str, output_dir: Path) -> Path:
    """Download a PDF manual."""
    manual = MANUALS[radio_id]
    output_path = output_dir / manual["filename"]

    if output_path.exists():
        print(f"  Already exists: {output_path}")
        return output_path

    print(f"  Downloading {manual['name']} manual...")
    urllib.request.urlretrieve(manual["url"], output_path)
    print(f"  Saved to: {output_path}")
    return output_path


def main():
    output_dir = Path(__file__).parent.parent / "content" / "pdfs"
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Downloading Elecraft manuals...")
    for radio_id in MANUALS:
        print(f"\n{MANUALS[radio_id]['name']}:")
        download_pdf(radio_id, output_dir)

    print("\nDone!")


if __name__ == "__main__":
    main()
```

**Step 3: Create README**

Create `tools/README.md`:
```markdown
# Field Guide Content Tools

Scripts to download and parse Elecraft manuals for Carrier Wave Field Guide.

## Setup

```bash
cd tools
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## Usage

### Download PDFs

```bash
python download_pdfs.py
```

Downloads all Elecraft manuals to `../content/pdfs/`.

### Extract Content

```bash
python extract_content.py elecraft-kx2
```

Extracts text from PDF and generates initial JSON structure.
```

**Step 4: Test the download script**

Run:
```bash
cd tools && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt && python download_pdfs.py
```

Expected: PDFs downloaded to `content/pdfs/`

**Step 5: Commit**

```bash
git add tools/ content/
git commit -m "feat: add PDF download tooling"
```

---

### Task 2: PDF Text Extraction Script

**Files:**
- Create: `tools/extract_content.py`

**Step 1: Create extraction script**

Create `tools/extract_content.py`:
```python
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
```

**Step 2: Test extraction on one radio**

Run:
```bash
cd tools && source venv/bin/activate && python extract_content.py elecraft-kx2
```

Expected: Creates `content/extracted/elecraft-kx2_skeleton.json` and `content/extracted/elecraft-kx2_raw_text.txt`

**Step 3: Extract all radios**

Run:
```bash
python extract_content.py --all elecraft-k1
```

Note: The `--all` flag processes all radios regardless of the positional argument.

**Step 4: Commit**

```bash
git add tools/extract_content.py content/extracted/
git commit -m "feat: add PDF text extraction script"
```

---

### Task 3: Content Curation Template

**Files:**
- Create: `content/elecraft-kx2/content.json` (template)
- Create: `content/CURATION_GUIDE.md`

**Step 1: Create curation guide**

Create `content/CURATION_GUIDE.md`:
```markdown
# Content Curation Guide

This guide explains how to curate manual content for Carrier Wave Field Guide.

## Workflow

1. Run `tools/extract_content.py <radio-id>` to generate skeleton and raw text
2. Open `content/extracted/<radio-id>_raw_text.txt` to find content
3. Copy the skeleton to `content/<radio-id>/content.json`
4. Fill in each section with content from the raw text
5. Copy the PDF to `content/<radio-id>/`

## Directory Structure

```
content/
├── elecraft-kx2/
│   ├── content.json      # Curated content
│   └── KX2_owners_man_B2.pdf
├── elecraft-k2/
│   ├── content.json
│   └── ...
```

## Block Types

### paragraph
Basic text content.
```json
{
  "type": "paragraph",
  "text": "The KX2 covers 80 through 10 meters with all-mode operation."
}
```

### menuEntry
Menu item with description. Use for menu reference sections.
```json
{
  "type": "menuEntry",
  "name": "KEYER SPD",
  "description": "Sets CW keyer speed from 8-50 WPM. Default: 20 WPM."
}
```

### specification
Single spec row. Use for specifications section.
```json
{
  "type": "specification",
  "label": "Frequency Range",
  "value": "80m - 10m"
}
```

### specificationTable
Table of specs. Use for grouped specifications.
```json
{
  "type": "specificationTable",
  "headers": ["Band", "Frequency", "Power"],
  "rows": [
    ["80m", "3.5-4.0 MHz", "10W"],
    ["40m", "7.0-7.3 MHz", "10W"]
  ]
}
```

### note
Informational callout (blue).
```json
{
  "type": "note",
  "text": "This setting is saved when you power off."
}
```

### warning
Warning callout (orange).
```json
{
  "type": "warning",
  "text": "Do not exceed 10W into internal ATU."
}
```

## Section Guidelines

### Operation Basics
- Band switching procedure
- Mode selection
- Basic tuning
- Key controls overview

### Menu System Reference
- One menuEntry per menu item
- Include default values where known
- Group related menus together

### CW/Keyer Settings
- Keyer speed, mode, sidetone
- Paddle settings
- CW-specific menus

### Filters & DSP
- Bandwidth settings
- Noise reduction
- Notch filter
- Audio settings

### Power & Battery
- Voltage display
- Battery operation
- Current draw
- Charging (if applicable)

### ATU Operation
- Tuning procedure
- Bypass mode
- Memory functions

### Specifications
- Use specification blocks for key specs
- Use specificationTable for frequency/power tables
- Include: frequency range, power output, current draw, dimensions, weight

### Quick Troubleshooting
- Common issues and solutions
- Error messages
- Reset procedures
```

**Step 2: Create template content.json**

Create directory and template:
```bash
mkdir -p content/elecraft-kx2
cp content/pdfs/KX2_owners_man_B2.pdf content/elecraft-kx2/
```

Create `content/elecraft-kx2/content.json`:
```json
{
  "radio": {
    "id": "elecraft-kx2",
    "manufacturer": "Elecraft",
    "model": "KX2",
    "revision": "B2",
    "pdfFilename": "KX2_owners_man_B2.pdf"
  },
  "sections": [
    {
      "id": "kx2-operation-basics",
      "title": "Operation Basics",
      "sortOrder": 1,
      "blocks": [
        {
          "type": "paragraph",
          "text": "The KX2 is a compact, high-performance HF transceiver covering 80 through 10 meters. It provides SSB, CW, DATA, and AM modes with up to 10 watts output."
        },
        {
          "type": "paragraph",
          "text": "To change bands, tap the BAND button. Each tap cycles to the next band. Hold BAND to reverse direction."
        },
        {
          "type": "paragraph",
          "text": "To change modes, tap the MODE button. The KX2 supports LSB, USB, CW, CW-REV, DATA, DATA-REV, and AM."
        },
        {
          "type": "note",
          "text": "The KX2 remembers your last frequency and mode for each band."
        }
      ]
    },
    {
      "id": "kx2-menu-reference",
      "title": "Menu System Reference",
      "sortOrder": 2,
      "blocks": [
        {
          "type": "paragraph",
          "text": "Access the menu by tapping MENU. Use the VFO knob to scroll through options. Tap MENU again to select, or tap any other button to exit."
        },
        {
          "type": "menuEntry",
          "name": "KEYER SPD",
          "description": "Sets CW keyer speed from 8-50 WPM. Default: 20 WPM."
        },
        {
          "type": "menuEntry",
          "name": "KEYER MD",
          "description": "Selects keyer mode: Iambic A, Iambic B, or Straight key (STR)."
        },
        {
          "type": "menuEntry",
          "name": "CW TONE",
          "description": "Sets CW sidetone frequency from 400-800 Hz. Default: 600 Hz."
        },
        {
          "type": "note",
          "text": "This is a partial menu reference. See the full PDF for all menu items."
        }
      ]
    },
    {
      "id": "kx2-cw-keyer-settings",
      "title": "CW/Keyer Settings",
      "sortOrder": 3,
      "blocks": [
        {
          "type": "paragraph",
          "text": "The KX2 includes a full-featured CW keyer with adjustable speed, multiple keyer modes, and built-in sidetone."
        },
        {
          "type": "menuEntry",
          "name": "KEYER SPD",
          "description": "Adjusts keyer speed from 8-50 WPM."
        },
        {
          "type": "menuEntry",
          "name": "KEYER MD",
          "description": "Sets keyer mode: Iambic A, Iambic B, or Straight."
        },
        {
          "type": "menuEntry",
          "name": "CW TONE",
          "description": "Sets sidetone pitch from 400-800 Hz."
        },
        {
          "type": "warning",
          "text": "Keyer speed changes take effect immediately."
        }
      ]
    },
    {
      "id": "kx2-filters-dsp",
      "title": "Filters & DSP",
      "sortOrder": 4,
      "blocks": [
        {
          "type": "paragraph",
          "text": "The KX2 provides variable bandwidth filtering and DSP noise reduction."
        },
        {
          "type": "paragraph",
          "text": "Rotate the AF/RF knob while holding it to adjust filter bandwidth. The display shows the current bandwidth in Hz."
        },
        {
          "type": "menuEntry",
          "name": "NR LEVEL",
          "description": "Noise reduction level from 0 (off) to 4 (maximum)."
        }
      ]
    },
    {
      "id": "kx2-power-battery",
      "title": "Power & Battery",
      "sortOrder": 5,
      "blocks": [
        {
          "type": "paragraph",
          "text": "The KX2 operates from 9-15V DC. With the internal battery option, it provides portable operation with built-in charging."
        },
        {
          "type": "specification",
          "label": "Operating Voltage",
          "value": "9-15V DC"
        },
        {
          "type": "specification",
          "label": "Current (RX)",
          "value": "150 mA typical"
        },
        {
          "type": "specification",
          "label": "Current (TX, 10W)",
          "value": "2.0 A typical"
        },
        {
          "type": "note",
          "text": "Power output is automatically reduced at lower supply voltages."
        }
      ]
    },
    {
      "id": "kx2-atu-operation",
      "title": "ATU Operation",
      "sortOrder": 6,
      "blocks": [
        {
          "type": "paragraph",
          "text": "The optional KXAT2 internal ATU provides automatic antenna matching for SWR up to 10:1."
        },
        {
          "type": "paragraph",
          "text": "To tune: Tap ATU. The radio will transmit a brief carrier and find the best match. 'TUN' appears during tuning."
        },
        {
          "type": "warning",
          "text": "Do not exceed 10W into the ATU. High SWR can damage the output stage."
        }
      ]
    },
    {
      "id": "kx2-specifications",
      "title": "Specifications",
      "sortOrder": 7,
      "blocks": [
        {
          "type": "specificationTable",
          "headers": ["Specification", "Value"],
          "rows": [
            ["Frequency Range", "80-10 meters"],
            ["Modes", "SSB, CW, DATA, AM"],
            ["Power Output", "10W (12V), 5W (9V)"],
            ["Receiver Type", "Superhet, high dynamic range"],
            ["Operating Voltage", "9-15V DC"],
            ["Current (RX)", "150 mA"],
            ["Current (TX)", "2.0 A at 10W"],
            ["Dimensions", "7.3 x 3.3 x 1.5 in"],
            ["Weight", "1.3 lb (with battery)"]
          ]
        }
      ]
    },
    {
      "id": "kx2-troubleshooting",
      "title": "Quick Troubleshooting",
      "sortOrder": 8,
      "blocks": [
        {
          "type": "paragraph",
          "text": "Common issues and quick fixes for field operation."
        },
        {
          "type": "menuEntry",
          "name": "No power on",
          "description": "Check battery charge or external power connection. Verify voltage is 9-15V."
        },
        {
          "type": "menuEntry",
          "name": "Low power output",
          "description": "Check supply voltage. Power is reduced below 11V. Also check ATU bypass if not using antenna tuner."
        },
        {
          "type": "menuEntry",
          "name": "CW keyer not working",
          "description": "Verify KEYER MD is not set to STR (straight key) if using paddles. Check paddle connections."
        },
        {
          "type": "menuEntry",
          "name": "High SWR",
          "description": "Retune ATU with ATU button. If SWR remains high, check antenna connections."
        }
      ]
    }
  ]
}
```

**Step 3: Commit**

```bash
git add content/
git commit -m "feat: add content curation guide and KX2 template"
```

---

### Task 4: Manifest Generator Script

**Files:**
- Create: `tools/generate_manifest.py`

**Step 1: Create manifest generator**

Create `tools/generate_manifest.py`:
```python
#!/usr/bin/env python3
"""Generate manifest.json from content directories."""

import json
import os
from datetime import date
from pathlib import Path


def get_file_size(path: Path) -> int:
    """Get file size in bytes."""
    return path.stat().st_size if path.exists() else 0


def generate_manifest(content_dir: Path, base_url: str) -> dict:
    """Generate manifest from content directories."""
    radios = []

    for radio_dir in sorted(content_dir.iterdir()):
        if not radio_dir.is_dir():
            continue
        if radio_dir.name in ["pdfs", "extracted"]:
            continue

        content_file = radio_dir / "content.json"
        if not content_file.exists():
            print(f"  Skipping {radio_dir.name}: no content.json")
            continue

        with open(content_file) as f:
            content = json.load(f)

        radio_info = content["radio"]
        pdf_path = radio_dir / radio_info["pdfFilename"]

        radios.append({
            "id": radio_info["id"],
            "manufacturer": radio_info["manufacturer"],
            "model": radio_info["model"],
            "revision": radio_info["revision"],
            "contentURL": f"{base_url}/{radio_dir.name}/content.json",
            "pdfURL": f"{base_url}/{radio_dir.name}/{radio_info['pdfFilename']}",
            "pdfSize": get_file_size(pdf_path),
            "contentSize": get_file_size(content_file),
        })

    return {
        "version": 1,
        "lastUpdated": date.today().isoformat(),
        "radios": radios,
    }


def main():
    content_dir = Path(__file__).parent.parent / "content"

    # Use placeholder URL - update when hosting is set up
    base_url = "https://example.com/field-guide-content"

    print("Generating manifest...")
    manifest = generate_manifest(content_dir, base_url)

    manifest_path = content_dir / "manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)

    print(f"Manifest saved to: {manifest_path}")
    print(f"Found {len(manifest['radios'])} radio(s):")
    for radio in manifest["radios"]:
        print(f"  - {radio['model']} (Rev {radio['revision']})")


if __name__ == "__main__":
    main()
```

**Step 2: Test manifest generation**

Run:
```bash
cd tools && source venv/bin/activate && python generate_manifest.py
```

Expected: Creates `content/manifest.json` with KX2 entry

**Step 3: Commit**

```bash
git add tools/generate_manifest.py content/manifest.json
git commit -m "feat: add manifest generator script"
```

---

## Phase 2: iOS App

### Task 5: Create Xcode Project

**Files:**
- Create: `FieldGuide/` Xcode project

**Step 1: Create Xcode project**

Use Xcode to create new project:
- Product Name: FieldGuide
- Team: (your team)
- Organization Identifier: com.carrierwave
- Interface: SwiftUI
- Language: Swift
- Storage: None (we'll add SwiftData manually)
- Include Tests: Yes

**Step 2: Configure project settings**

In Xcode:
- Set iOS Deployment Target: 17.0
- Add PDFKit framework (it's already available, no import needed)

**Step 3: Commit**

```bash
git add FieldGuide/
git commit -m "feat: create FieldGuide Xcode project"
```

---

### Task 6: SwiftData Models

**Files:**
- Create: `FieldGuide/Models/Radio.swift`
- Create: `FieldGuide/Models/Section.swift`
- Create: `FieldGuide/Models/ContentBlock.swift`

**Step 1: Create Radio model**

Create `FieldGuide/Models/Radio.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Radio {
    @Attribute(.unique) var id: String
    var manufacturer: String
    var model: String
    var manualRevision: String
    var pdfFilename: String
    var pdfLocalPath: String?
    var isDownloaded: Bool
    var downloadedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Section.radio)
    var sections: [Section] = []

    init(
        id: String,
        manufacturer: String,
        model: String,
        manualRevision: String,
        pdfFilename: String
    ) {
        self.id = id
        self.manufacturer = manufacturer
        self.model = model
        self.manualRevision = manualRevision
        self.pdfFilename = pdfFilename
        self.isDownloaded = false
    }
}
```

**Step 2: Create Section model**

Create `FieldGuide/Models/Section.swift`:
```swift
import Foundation
import SwiftData

@Model
final class Section {
    @Attribute(.unique) var id: String
    var title: String
    var sortOrder: Int
    var searchableText: String

    var radio: Radio?

    @Relationship(deleteRule: .cascade, inverse: \ContentBlock.section)
    var blocks: [ContentBlock] = []

    init(id: String, title: String, sortOrder: Int, searchableText: String = "") {
        self.id = id
        self.title = title
        self.sortOrder = sortOrder
        self.searchableText = searchableText
    }
}
```

**Step 3: Create ContentBlock model**

Create `FieldGuide/Models/ContentBlock.swift`:
```swift
import Foundation
import SwiftData

enum ContentBlockType: String, Codable {
    case paragraph
    case menuEntry
    case specification
    case specificationTable
    case note
    case warning
}

@Model
final class ContentBlock {
    @Attribute(.unique) var id: String
    var sortOrder: Int
    var blockType: ContentBlockType

    // Content fields (use appropriate ones based on blockType)
    var text: String?
    var menuName: String?
    var menuDescription: String?
    var specLabel: String?
    var specValue: String?
    var tableHeaders: [String]?
    var tableRows: [[String]]?

    var section: Section?

    init(id: String, sortOrder: Int, blockType: ContentBlockType) {
        self.id = id
        self.sortOrder = sortOrder
        self.blockType = blockType
    }
}
```

**Step 4: Commit**

```bash
git add FieldGuide/Models/
git commit -m "feat: add SwiftData models for Radio, Section, ContentBlock"
```

---

### Task 7: App Entry Point and Container

**Files:**
- Modify: `FieldGuide/FieldGuideApp.swift`

**Step 1: Configure SwiftData container**

Replace `FieldGuide/FieldGuideApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct FieldGuideApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Radio.self,
            Section.self,
            ContentBlock.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

**Step 2: Commit**

```bash
git add FieldGuide/FieldGuideApp.swift
git commit -m "feat: configure SwiftData container"
```

---

### Task 8: Tab-Based Navigation Structure

**Files:**
- Modify: `FieldGuide/ContentView.swift`
- Create: `FieldGuide/Views/LibraryTab.swift`
- Create: `FieldGuide/Views/SearchTab.swift`
- Create: `FieldGuide/Views/SettingsTab.swift`

**Step 1: Create tab views**

Create `FieldGuide/Views/LibraryTab.swift`:
```swift
import SwiftUI
import SwiftData

struct LibraryTab: View {
    @Query(sort: \Radio.model) private var radios: [Radio]
    @State private var showAddRadio = false

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if radios.isEmpty {
                    emptyState
                } else {
                    radioGrid
                }
            }
            .navigationTitle("Library")
            .sheet(isPresented: $showAddRadio) {
                AddRadioSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Download your first manual to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showAddRadio = true
            } label: {
                Label("Add Radio", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var radioGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(radios.filter { $0.isDownloaded }) { radio in
                NavigationLink(value: radio) {
                    RadioCard(radio: radio)
                }
                .buttonStyle(.plain)
            }

            // Add Radio card
            Button {
                showAddRadio = true
            } label: {
                AddRadioCard()
            }
            .buttonStyle(.plain)
        }
        .padding()
        .navigationDestination(for: Radio.self) { radio in
            RadioDetailView(radio: radio)
        }
    }
}

struct RadioCard: View {
    let radio: Radio

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "radio")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(height: 60)

            Text(radio.model)
                .font(.headline)

            HStack {
                Text(radio.manufacturer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(radio.manualRevision)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AddRadioCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .frame(height: 60)

            Text("Add Radio")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(.secondary)
        )
    }
}

#Preview {
    LibraryTab()
        .modelContainer(for: Radio.self, inMemory: true)
}
```

Create `FieldGuide/Views/SearchTab.swift`:
```swift
import SwiftUI
import SwiftData

struct SearchTab: View {
    @Query private var radios: [Radio]
    @Query private var sections: [Section]
    @State private var searchText = ""
    @State private var selectedRadioId: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        scopeChip("All", isSelected: selectedRadioId == nil) {
                            selectedRadioId = nil
                        }
                        ForEach(radios.filter { $0.isDownloaded }) { radio in
                            scopeChip(radio.model, isSelected: selectedRadioId == radio.id) {
                                selectedRadioId = radio.id
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // Results
                if searchText.count < 2 {
                    ContentUnavailableView(
                        "Search Manuals",
                        systemImage: "magnifyingglass",
                        description: Text("Enter at least 2 characters to search")
                    )
                } else if filteredSections.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filteredSections) { section in
                        NavigationLink(value: section) {
                            SearchResultRow(section: section, searchText: searchText)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search manuals...")
            .navigationDestination(for: Section.self) { section in
                SectionDetailView(section: section)
            }
        }
    }

    private var filteredSections: [Section] {
        guard searchText.count >= 2 else { return [] }
        let query = searchText.lowercased()

        return sections.filter { section in
            guard section.radio?.isDownloaded == true else { return false }

            if let radioId = selectedRadioId, section.radio?.id != radioId {
                return false
            }

            return section.title.lowercased().contains(query) ||
                   section.searchableText.lowercased().contains(query)
        }
    }

    private func scopeChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct SearchResultRow: View {
    let section: Section
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let radio = section.radio {
                    Text(radio.model)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
            }

            if let preview = findMatchPreview() {
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func findMatchPreview() -> String? {
        let text = section.searchableText
        guard let range = text.range(of: searchText, options: .caseInsensitive) else {
            return nil
        }

        let start = text.index(range.lowerBound, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex

        var preview = String(text[start..<end])
        if start != text.startIndex { preview = "..." + preview }
        if end != text.endIndex { preview = preview + "..." }

        return preview
    }
}

#Preview {
    SearchTab()
        .modelContainer(for: [Radio.self, Section.self], inMemory: true)
}
```

Create `FieldGuide/Views/SettingsTab.swift`:
```swift
import SwiftUI
import SwiftData

struct SettingsTab: View {
    @Query private var radios: [Radio]

    private var downloadedRadios: [Radio] {
        radios.filter { $0.isDownloaded }
    }

    private var totalSize: String {
        // Placeholder - would calculate actual size
        let count = downloadedRadios.count
        return "\(count) radio\(count == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationStack {
            List {
                SwiftUI.Section("Updates") {
                    Button {
                        // TODO: Implement update check
                    } label: {
                        Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                SwiftUI.Section("Storage") {
                    NavigationLink {
                        ManageDownloadsView()
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Manage Downloads")
                            Text(totalSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SwiftUI.Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("App", value: "Carrier Wave Field Guide")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ManageDownloadsView: View {
    @Query(filter: #Predicate<Radio> { $0.isDownloaded }, sort: \Radio.model)
    private var radios: [Radio]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(radios) { radio in
                HStack {
                    VStack(alignment: .leading) {
                        Text(radio.model)
                            .font(.headline)
                        Text(radio.manufacturer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(radio.manualRevision)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete(perform: deleteRadios)
        }
        .navigationTitle("Manage Downloads")
        .toolbar {
            EditButton()
        }
    }

    private func deleteRadios(at offsets: IndexSet) {
        for index in offsets {
            let radio = radios[index]
            // TODO: Also delete PDF file
            modelContext.delete(radio)
        }
    }
}

#Preview {
    SettingsTab()
        .modelContainer(for: Radio.self, inMemory: true)
}
```

**Step 2: Update ContentView with tabs**

Replace `FieldGuide/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Library", systemImage: "books.vertical") {
                LibraryTab()
            }

            Tab("Search", systemImage: "magnifyingglass") {
                SearchTab()
            }

            Tab("Settings", systemImage: "gear") {
                SettingsTab()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Radio.self, Section.self, ContentBlock.self], inMemory: true)
}
```

**Step 3: Commit**

```bash
git add FieldGuide/
git commit -m "feat: add tab-based navigation structure"
```

---

### Task 9: Radio Detail and Section Views

**Files:**
- Create: `FieldGuide/Views/RadioDetailView.swift`
- Create: `FieldGuide/Views/SectionDetailView.swift`
- Create: `FieldGuide/Views/AddRadioSheet.swift`

**Step 1: Create RadioDetailView**

Create `FieldGuide/Views/RadioDetailView.swift`:
```swift
import SwiftUI
import SwiftData

struct RadioDetailView: View {
    let radio: Radio
    @State private var showPDF = false

    private var sortedSections: [Section] {
        radio.sections.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            ForEach(sortedSections) { section in
                NavigationLink(value: section) {
                    SectionRow(section: section)
                }
            }
        }
        .navigationTitle(radio.model)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPDF = true
                } label: {
                    Label("PDF", systemImage: "doc.text")
                }
            }
        }
        .fullScreenCover(isPresented: $showPDF) {
            PDFViewerSheet(radio: radio)
        }
        .navigationDestination(for: Section.self) { section in
            SectionDetailView(section: section)
        }
    }
}

struct SectionRow: View {
    let section: Section

    private var iconName: String {
        switch section.title {
        case "Operation Basics": return "dial.medium"
        case "Menu System Reference": return "list.bullet.rectangle"
        case "CW/Keyer Settings": return "waveform"
        case "Filters & DSP": return "slider.horizontal.3"
        case "Power & Battery": return "battery.100"
        case "ATU Operation": return "antenna.radiowaves.left.and.right"
        case "Specifications": return "doc.text"
        case "Quick Troubleshooting": return "wrench.and.screwdriver"
        default: return "book"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            Text(section.title)
                .font(.subheadline)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RadioDetailView(radio: Radio(
            id: "test",
            manufacturer: "Elecraft",
            model: "KX2",
            manualRevision: "B2",
            pdfFilename: "test.pdf"
        ))
    }
    .modelContainer(for: Radio.self, inMemory: true)
}
```

**Step 2: Create SectionDetailView**

Create `FieldGuide/Views/SectionDetailView.swift`:
```swift
import SwiftUI
import SwiftData

struct SectionDetailView: View {
    let section: Section

    private var sortedBlocks: [ContentBlock] {
        section.blocks.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(sortedBlocks) { block in
                    ContentBlockView(block: block)
                }
            }
            .padding()
        }
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ContentBlockView: View {
    let block: ContentBlock

    var body: some View {
        switch block.blockType {
        case .paragraph:
            ParagraphBlock(text: block.text ?? "")

        case .menuEntry:
            MenuEntryBlock(name: block.menuName ?? "", description: block.menuDescription ?? "")

        case .specification:
            SpecificationBlock(label: block.specLabel ?? "", value: block.specValue ?? "")

        case .specificationTable:
            SpecificationTableBlock(headers: block.tableHeaders ?? [], rows: block.tableRows ?? [])

        case .note:
            NoteBlock(text: block.text ?? "", style: .info)

        case .warning:
            NoteBlock(text: block.text ?? "", style: .warning)
        }
    }
}

struct ParagraphBlock: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
    }
}

struct MenuEntryBlock: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline.weight(.semibold).monospaced())
            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SpecificationBlock: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

struct SpecificationTableBlock: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !headers.isEmpty {
                HStack {
                    ForEach(headers, id: \.self) { header in
                        Text(header)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    ForEach(Array(row.enumerated()), id: \.offset) { index, cell in
                        Text(cell)
                            .font(index == 0 ? .subheadline : .subheadline.monospaced())
                            .foregroundStyle(index == 0 ? .primary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

enum NoteStyle {
    case info, warning

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        }
    }
}

struct NoteBlock: View {
    let text: String
    let style: NoteStyle

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
            Text(text)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(section: Section(
            id: "test",
            title: "Menu System Reference",
            sortOrder: 1
        ))
    }
    .modelContainer(for: Section.self, inMemory: true)
}
```

**Step 3: Create AddRadioSheet placeholder**

Create `FieldGuide/Views/AddRadioSheet.swift`:
```swift
import SwiftUI

struct AddRadioSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Text("Available radios will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Add Radio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddRadioSheet()
}
```

**Step 4: Commit**

```bash
git add FieldGuide/Views/
git commit -m "feat: add RadioDetailView and SectionDetailView"
```

---

### Task 10: PDF Viewer

**Files:**
- Create: `FieldGuide/Views/PDFViewerSheet.swift`

**Step 1: Create PDF viewer**

Create `FieldGuide/Views/PDFViewerSheet.swift`:
```swift
import SwiftUI
import PDFKit

struct PDFViewerSheet: View {
    let radio: Radio
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(url: pdfURL)
                .navigationTitle(radio.model)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if let url = pdfURL {
                            ShareLink(item: url)
                        }
                    }
                }
        }
    }

    private var pdfURL: URL? {
        guard let path = radio.pdfLocalPath else { return nil }
        return URL(fileURLWithPath: path)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let url = url, let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if let url = url, let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}

#Preview {
    PDFViewerSheet(radio: Radio(
        id: "test",
        manufacturer: "Elecraft",
        model: "KX2",
        manualRevision: "B2",
        pdfFilename: "test.pdf"
    ))
}
```

**Step 2: Commit**

```bash
git add FieldGuide/Views/PDFViewerSheet.swift
git commit -m "feat: add PDF viewer with PDFKit"
```

---

### Task 11: Content Import Service

**Files:**
- Create: `FieldGuide/Services/ContentImporter.swift`

**Step 1: Create content importer**

Create `FieldGuide/Services/ContentImporter.swift`:
```swift
import Foundation
import SwiftData

/// Imports content from JSON into SwiftData
actor ContentImporter {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Import content from a JSON file bundled in the app (for testing)
    func importBundledContent(filename: String) async throws {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ContentImportError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)
        try await importContent(from: data)
    }

    /// Import content from JSON data
    @MainActor
    func importContent(from data: Data) async throws {
        let decoder = JSONDecoder()
        let content = try decoder.decode(ContentJSON.self, from: data)

        let context = modelContainer.mainContext

        // Create or update radio
        let radioDescriptor = FetchDescriptor<Radio>(
            predicate: #Predicate { $0.id == content.radio.id }
        )
        let existingRadios = try context.fetch(radioDescriptor)

        let radio: Radio
        if let existing = existingRadios.first {
            // Update existing
            existing.manufacturer = content.radio.manufacturer
            existing.model = content.radio.model
            existing.manualRevision = content.radio.revision
            existing.pdfFilename = content.radio.pdfFilename

            // Remove old sections
            for section in existing.sections {
                context.delete(section)
            }

            radio = existing
        } else {
            // Create new
            radio = Radio(
                id: content.radio.id,
                manufacturer: content.radio.manufacturer,
                model: content.radio.model,
                manualRevision: content.radio.revision,
                pdfFilename: content.radio.pdfFilename
            )
            context.insert(radio)
        }

        // Import sections
        for sectionJSON in content.sections {
            let section = Section(
                id: sectionJSON.id,
                title: sectionJSON.title,
                sortOrder: sectionJSON.sortOrder
            )
            section.radio = radio

            // Import blocks
            var searchableText = sectionJSON.title + " "

            for (index, blockJSON) in sectionJSON.blocks.enumerated() {
                let block = ContentBlock(
                    id: "\(sectionJSON.id)-block-\(index)",
                    sortOrder: index,
                    blockType: blockJSON.type
                )

                switch blockJSON.type {
                case .paragraph:
                    block.text = blockJSON.text
                    searchableText += (blockJSON.text ?? "") + " "

                case .menuEntry:
                    block.menuName = blockJSON.name
                    block.menuDescription = blockJSON.description
                    searchableText += (blockJSON.name ?? "") + " " + (blockJSON.description ?? "") + " "

                case .specification:
                    block.specLabel = blockJSON.label
                    block.specValue = blockJSON.value
                    searchableText += (blockJSON.label ?? "") + " " + (blockJSON.value ?? "") + " "

                case .specificationTable:
                    block.tableHeaders = blockJSON.headers
                    block.tableRows = blockJSON.rows
                    searchableText += (blockJSON.rows?.flatMap { $0 }.joined(separator: " ") ?? "") + " "

                case .note, .warning:
                    block.text = blockJSON.text
                    searchableText += (blockJSON.text ?? "") + " "
                }

                block.section = section
                context.insert(block)
            }

            section.searchableText = searchableText
            context.insert(section)
        }

        radio.isDownloaded = true
        radio.downloadedAt = Date()

        try context.save()
    }
}

enum ContentImportError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Content file not found: \(name)"
        }
    }
}

// MARK: - JSON Models

struct ContentJSON: Codable {
    let radio: RadioJSON
    let sections: [SectionJSON]
}

struct RadioJSON: Codable {
    let id: String
    let manufacturer: String
    let model: String
    let revision: String
    let pdfFilename: String
}

struct SectionJSON: Codable {
    let id: String
    let title: String
    let sortOrder: Int
    let blocks: [BlockJSON]
}

struct BlockJSON: Codable {
    let type: ContentBlockType

    // Paragraph, note, warning
    let text: String?

    // Menu entry
    let name: String?
    let description: String?

    // Specification
    let label: String?
    let value: String?

    // Table
    let headers: [String]?
    let rows: [[String]]?
}
```

**Step 2: Commit**

```bash
git add FieldGuide/Services/
git commit -m "feat: add ContentImporter service for JSON import"
```

---

### Task 12: Bundle Test Content

**Files:**
- Copy: `content/elecraft-kx2/content.json` to `FieldGuide/Resources/`
- Modify: `FieldGuide/FieldGuideApp.swift`

**Step 1: Copy test content to app bundle**

```bash
mkdir -p FieldGuide/Resources
cp content/elecraft-kx2/content.json FieldGuide/Resources/elecraft-kx2.json
```

Add the file to Xcode project (drag into Resources group, check "Copy if needed").

**Step 2: Add content loading on first launch**

Update `FieldGuide/FieldGuideApp.swift`:
```swift
import SwiftUI
import SwiftData

@main
struct FieldGuideApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Radio.self,
            Section.self,
            ContentBlock.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await loadBundledContentIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func loadBundledContentIfNeeded() async {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Radio>()

        do {
            let radios = try context.fetch(descriptor)
            if radios.isEmpty {
                // Load bundled content on first launch
                let importer = ContentImporter(modelContainer: sharedModelContainer)
                try await importer.importBundledContent(filename: "elecraft-kx2")
            }
        } catch {
            print("Error loading content: \(error)")
        }
    }
}
```

**Step 3: Commit**

```bash
git add FieldGuide/
git commit -m "feat: bundle test content and load on first launch"
```

---

## Summary

This plan covers:

**Phase 1 (Content Tooling):**
1. PDF download script
2. Text extraction script
3. Curation template and guide
4. Manifest generator

**Phase 2 (iOS App):**
5. Xcode project setup
6. SwiftData models
7. App entry point
8. Tab navigation
9. Radio detail and section views
10. PDF viewer
11. Content import service
12. Bundled test content

After completing these tasks, you'll have:
- Tools to extract and curate content from PDF manuals
- A working iOS app that displays curated content
- PDF viewing capability
- Search across all downloaded content

**Next steps after this plan:**
- Curate remaining radio content (K1, K2, KX1)
- Implement download from remote server
- Implement update checking
- Design app icon
- Submit to App Store
