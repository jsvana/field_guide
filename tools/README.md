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
