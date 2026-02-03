# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Building and Testing

**NEVER build, run tests, or use the iOS simulator yourself. Always prompt the user to do so.**

When you need to verify changes compile or tests pass, ask the user to run the appropriate command and report back the results.

## Make Commands

```bash
make build              # Build iOS app (Debug, uses -target for reliable CLI builds)
make test               # Run unit tests
make clean              # Clean build artifacts and DerivedData
make download-pdfs      # Download Elecraft PDF manuals
make extract-content    # Extract text from PDFs
make generate-manifest  # Generate content manifest.json
```

## Architecture

**iOS App** (`FieldGuide/`): SwiftUI + SwiftData app for offline viewing of amateur radio manuals.

- **Models**: `Radio`, `Section`, `ContentBlock` - SwiftData models with relationships (Radio → Sections → ContentBlocks)
- **ContentImporter**: Actor that parses JSON content files into SwiftData models
- **Views**: Tab-based navigation (Library, Search, Settings) with NavigationStack for drill-down

**Content Pipeline** (`tools/` + `content/`):
1. `download_pdfs.py` fetches PDFs from Elecraft FTP
2. `extract_content.py` extracts raw text and generates skeleton JSON
3. Human curates content into `content/<radio-id>/content.json`
4. `generate_manifest.py` creates `manifest.json` listing all radios
5. JSON files bundled in app or downloaded at runtime

**Content Format**: JSON with `radio` metadata and `sections` array containing typed `blocks`:
- `paragraph`, `menuEntry`, `specification`, `specificationTable`, `note`, `warning`

## Code Standards

- Swift 6 with strict concurrency
- iOS 17+ deployment target (SwiftData requirement)
- Follow [Carrier Wave Design Language](~/projects/carrier_wave/docs/design-language.md)
- Offline-first: all content works without network after download

## Key References

| Purpose | Location |
|---------|----------|
| Content curation guide | `content/CURATION_GUIDE.md` |
| Design document | `docs/plans/2026-02-02-field-guide-design.md` |
| Implementation plan | `docs/plans/2026-02-02-field-guide-implementation.md` |

## Python Tooling Setup

```bash
cd tools && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
```
