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
