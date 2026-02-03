# Carrier Wave Field Guide

## Building and Testing

**NEVER build, run tests, or use the iOS simulator yourself. Always prompt the user to do so.**

When you need to verify changes compile or tests pass, ask the user to run the appropriate command (e.g., `make build`, `make test`) and report back the results.

## Overview

Carrier Wave Field Guide is a SwiftUI/SwiftData iOS app for viewing amateur radio equipment manuals offline. It provides pre-curated, styled content for field use with access to original PDFs.

## Project Structure

```
manuals/
├── FieldGuide/              # iOS app (SwiftUI, SwiftData, iOS 17+)
│   ├── Models/              # SwiftData models (Radio, Section, ContentBlock)
│   ├── Views/               # SwiftUI views
│   ├── Services/            # Content import, etc.
│   └── Resources/           # Bundled content for testing
├── tools/                   # Python content tooling
│   ├── download_pdfs.py     # Download Elecraft manuals
│   ├── extract_content.py   # Extract text from PDFs
│   └── generate_manifest.py # Generate manifest.json
├── content/                 # Curated content
│   ├── elecraft-kx2/        # Per-radio content + PDF
│   ├── manifest.json        # Radio listing for app
│   └── CURATION_GUIDE.md    # How to curate content
└── docs/plans/              # Design and implementation plans
```

## Code Standards

- Follow [Carrier Wave Design Language](/Users/jsvana/projects/carrier_wave/docs/design-language.md)
- iOS 17+ deployment target (SwiftData requirement)
- Use SwiftData for persistence
- Use PDFKit for PDF viewing
- Offline-first: all content works without network after download

## Key Files

| Purpose | File |
|---------|------|
| Design document | docs/plans/2026-02-02-field-guide-design.md |
| Implementation plan | docs/plans/2026-02-02-field-guide-implementation.md |
| Design language | ~/projects/carrier_wave/docs/design-language.md |
| Content curation | content/CURATION_GUIDE.md |

## Make Commands

```bash
make build              # Build for simulator
make test               # Run tests
make clean              # Clean build artifacts
make download-pdfs      # Download Elecraft PDF manuals
make extract-content    # Extract text from all PDFs
make generate-manifest  # Generate content manifest
```

## Python Tooling Setup

```bash
cd tools
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```
