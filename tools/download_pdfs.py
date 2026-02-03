#!/usr/bin/env python3
"""Download radio PDF manuals."""

import urllib.request
import urllib.parse
from pathlib import Path

MANUALS = {
    # Elecraft
    "elecraft-k1": {
        "manufacturer": "Elecraft",
        "name": "K1",
        "url": "https://ftp.elecraft.com/K1/Manuals%20Downloads/E740016%20K1%20manual%20rev%20J.pdf",
        "filename": "E740016_K1_manual_rev_J.pdf",
        "revision": "J",
    },
    "elecraft-k2": {
        "manufacturer": "Elecraft",
        "name": "K2",
        "url": "https://ftp.elecraft.com/K2/Manuals%20Downloads/E740001_K2%20Owner's%20Manual%20Rev%20I.pdf",
        "filename": "E740001_K2_Owners_Manual_Rev_I.pdf",
        "revision": "I",
    },
    "elecraft-kx1": {
        "manufacturer": "Elecraft",
        "name": "KX1",
        "url": "https://ftp.elecraft.com/KX1/Manuals%20Downloads/KX1_Owner's_Manual_Rev_E.pdf",
        "filename": "KX1_Owners_Manual_Rev_E.pdf",
        "revision": "E",
    },
    "elecraft-kx2": {
        "manufacturer": "Elecraft",
        "name": "KX2",
        "url": "https://ftp.elecraft.com/KX2/Manuals%20Downloads/KX2%20owner's%20man%20B2.pdf",
        "filename": "KX2_owners_man_B2.pdf",
        "revision": "B2",
    },
    "elecraft-kx3": {
        "manufacturer": "Elecraft",
        "name": "KX3",
        "url": "https://ftp.elecraft.com/KX3/Manuals%20Downloads/E740163%20KX3%20Owner's%20man%20Rev%20C5.pdf",
        "filename": "E740163_KX3_Owners_man_Rev_C5.pdf",
        "revision": "C5",
    },
    "elecraft-kh1": {
        "manufacturer": "Elecraft",
        "name": "KH1",
        "url": "https://ftp.elecraft.com/KH1/Manuals%20Downloads/KH1%20Owner's%20Manual,%20rev%20B4.pdf",
        "filename": "KH1_Owners_Manual_rev_B4.pdf",
        "revision": "B4",
    },
    # HamGadgets
    "hamgadgets-cft1": {
        "manufacturer": "HamGadgets",
        "name": "CFT1",
        "url": "https://hamgadgets.com/assets/images/Current_Documents/CFT1%20Assembly%20Manual%20RevC%20V12.pdf",
        "filename": "CFT1_Assembly_Manual_RevC_V12.pdf",
        "revision": "C V12",
    },
    # PennTek
    "penntek-tr45l": {
        "manufacturer": "PennTek",
        "name": "TR-45L",
        "url": "https://www.wa3rnc.com/documents/TR-45L%20Instructions%20V2.pdf",
        "filename": "TR-45L_Instructions_V2.pdf",
        "revision": "V2",
    },
    "penntek-tr35": {
        "manufacturer": "PennTek",
        "name": "TR-35",
        "url": "https://www.wa3rnc.com/documents/TR-35-Operating-Instructions.pdf",
        "filename": "TR-35_Operating_Instructions.pdf",
        "revision": "1",
    },
    # LNR Precision
    "lnr-mtr4b-v2": {
        "manufacturer": "LNR Precision",
        "name": "MTR 4B V2",
        "url": "https://www.lnrprecision.com/wp-content/uploads/2021/01/Mtr4BV2manual_1_12_21.pdf",
        "filename": "MTR_4B_V2_Manual.pdf",
        "revision": "2021-01-12",
    },
    "lnr-mtr3b-v4": {
        "manufacturer": "LNR Precision",
        "name": "MTR 3B V4 Currahee",
        "url": "https://www.lnrprecision.com/wp-content/uploads/2024/10/MTR3B-V4-Currahee-Version-Manual.pdf",
        "filename": "MTR_3B_V4_Currahee_Manual.pdf",
        "revision": "V4",
    },
    "lnr-mtr5b": {
        "manufacturer": "LNR Precision",
        "name": "MTR 5B",
        "url": "https://www.lnrprecision.com/wp-content/uploads/2017/06/MTR_5B-Manual_rev4-LNR.pdf",
        "filename": "MTR_5B_Manual_Rev4.pdf",
        "revision": "4",
    },
    "lnr-ld5": {
        "manufacturer": "LNR Precision",
        "name": "LD-5",
        "url": "https://www.lnrprecision.com/wp-content/uploads/2025/02/LD-5_Updated_Manual_7_13_15.pdf",
        "filename": "LD-5_Manual.pdf",
        "revision": "2015-07-13",
    },
    # Yaesu
    "yaesu-ft891": {
        "manufacturer": "Yaesu",
        "name": "FT-891",
        "url": "https://static.dxengineering.com/global/images/instructions/ysu-ft-891_it.pdf",
        "filename": "FT-891_Instruction_Manual.pdf",
        "revision": "1",
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

    # Use a proper User-Agent to avoid 403 errors from some servers
    request = urllib.request.Request(
        manual["url"],
        headers={"User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"}
    )
    with urllib.request.urlopen(request) as response:
        with open(output_path, "wb") as f:
            f.write(response.read())

    print(f"  Saved to: {output_path}")
    return output_path


def main():
    output_dir = Path(__file__).parent.parent / "content" / "pdfs"
    output_dir.mkdir(parents=True, exist_ok=True)

    print("Downloading radio manuals...")
    for radio_id in MANUALS:
        manual = MANUALS[radio_id]
        print(f"\n{manual['manufacturer']} {manual['name']}:")
        download_pdf(radio_id, output_dir)

    print("\nDone!")


if __name__ == "__main__":
    main()
