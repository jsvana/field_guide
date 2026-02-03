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
    "elecraft-kx3": {
        "name": "KX3",
        "url": "https://ftp.elecraft.com/KX3/Manuals%20Downloads/E740163%20KX3%20Owner's%20man%20Rev%20C5.pdf",
        "filename": "E740163_KX3_Owners_man_Rev_C5.pdf",
        "revision": "C5",
    },
    "elecraft-kh1": {
        "name": "KH1",
        "url": "https://ftp.elecraft.com/KH1/Manuals%20Downloads/KH1%20Owner's%20Manual,%20rev%20B4.pdf",
        "filename": "KH1_Owners_Manual_rev_B4.pdf",
        "revision": "B4",
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
