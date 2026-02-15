# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## File Discovery Rules

**FORBIDDEN:**
- Scanning all `.swift` files (e.g., `Glob **/*.swift`, `Grep` across entire repo)
- Using Task/Explore agents to "find all files" or "explore the codebase structure"
- Any broad file discovery that reads more than 5 files at once

**REQUIRED:**
- Use the File Index below to locate files by feature/purpose
- Read specific files by path from the index
- When editing files, update this index if adding/removing/renaming files

## File Index

See [docs/FILE_INDEX.md](docs/FILE_INDEX.md) for the complete file-to-purpose mapping.

## Building and Testing

Use the **xcode-build** skill (`~/.claude/skills/xcode-build/scripts/xc`) for all builds and tests. This wraps xcodebuild with `-quiet` and `xcresulttool` for minimal token output. Device name is configured in `CLAUDE.local.md`.

```bash
xc build        # Build for device
xc test-unit    # Run unit tests
xc lint          # SwiftLint with JSON output
xc format        # SwiftFormat
xc quality       # format → lint → build (pre-commit gate)
xc deploy        # Build + install + launch on device
xc crashes [filter]  # List crash logs on device
xc crash <file.ips>  # Pull and display a crash log
xc logs [filter]     # Stream live device logs (requires idevicesyslog)
```

The Makefile is still available for simulator-based builds/tests (`make build`, `make test`) when needed.

**Deploying to device:** When you need to test on-device, run `xc deploy` yourself. Do not ask the user to build or deploy — just do it.

### Make Commands

```bash
make build              # Build iOS app (Debug, uses -target for reliable CLI builds)
make test               # Run unit tests
make clean              # Clean build artifacts and DerivedData
make download-pdfs      # Download Elecraft PDF manuals
make extract-content    # Extract text from PDFs
make generate-manifest  # Generate content manifest.json
```

## Architecture

**iOS App**: SwiftUI + SwiftData app for offline viewing of amateur radio manuals. Source in `FieldGuide/`, project at root (`FieldGuide.xcodeproj`).

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

## Content JSON Field Requirements

**CRITICAL: Wrong field names cause empty content in the app.**

| Block Type | Required Fields | WRONG (breaks display) |
|------------|-----------------|------------------------|
| paragraph | `text` | ~~content~~ |
| note | `text` | ~~content~~ |
| warning | `text` | ~~content~~ |
| menuEntry | `name`, `description` | |
| specification | `name`, `value` | ~~label~~ |
| specificationTable | `rows` | ~~entries~~ |

**IMPORTANT: The app loads JSON from `FieldGuide/*.json`, NOT from `content/*/content.json`.** When fixing content issues, edit the files in the app bundle directory.

See `content/CURATION_GUIDE.md` for full documentation and copy-paste templates.

## Adding a New Radio to the App

To add a new radio to the Library, complete ALL of these steps:

1. **Add to download script** (`tools/download_pdfs.py`):
   - Add entry to `MANUALS` dict with manufacturer, name, url, filename, revision

2. **Download PDF**: `make download-pdfs`

3. **Extract content**: `cd tools && source venv/bin/activate && python extract_content.py <radio-id>`

4. **Create content JSON** in `FieldGuide/<radio-id>.json`:
   - Use the extracted raw text and skeleton as reference
   - Follow field requirements above (use `text` not `content`, etc.)

5. **Register in app** (`FieldGuide/FieldGuideApp.swift`):
   - Add radio ID to `bundledRadios` array (alphabetical within manufacturer)

6. **Copy to content directory**: `cp FieldGuide/<radio-id>.json content/<radio-id>/content.json`

7. **Update FILE_INDEX.md**: Add entry to Content section

**Missing any step will cause the radio to not appear in the Library tab.**

## Code Standards

- Swift 6 with strict concurrency
- iOS 17+ deployment target (SwiftData requirement)
- Follow [Carrier Wave Design Language](~/projects/carrier_wave/docs/design-language.md)
- Offline-first: all content works without network after download

## Version and Changelog

When making user-facing changes:

1. **Update version** in `FieldGuide.xcodeproj/project.pbxproj`:
   - `MARKETING_VERSION` = user-visible version (e.g., 1.1)
   - `CURRENT_PROJECT_VERSION` = build number (increment for each build)

2. **Update CHANGELOG.md** following [Keep a Changelog](https://keepachangelog.com/) format:
   - Add entries under `## [Unreleased]` during development
   - Move to versioned section (e.g., `## [1.1] - 2026-02-03`) on release
   - Categories: Added, Changed, Deprecated, Removed, Fixed, Security

## Key References

| Purpose | Location |
|---------|----------|
| Changelog | `CHANGELOG.md` |
| Content curation guide | `content/CURATION_GUIDE.md` |
| Design document | `docs/plans/2026-02-02-field-guide-design.md` |
| Implementation plan | `docs/plans/2026-02-02-field-guide-implementation.md` |

## Python Tooling Setup

```bash
cd tools && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt
```
