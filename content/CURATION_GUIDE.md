# Radio Manual Content Curation Guide

This guide documents the process for curating content from radio owner's manuals into structured JSON for the iOS app.

## Workflow

1. **Download PDF** - Use `scripts/download_manual.py` to download the official manual
2. **Extract Text** - Use `scripts/extract_pdf_text.py` to extract raw text for reference
3. **Create Directory** - Create `content/<manufacturer>-<model>/` directory
4. **Copy PDF** - Copy the PDF into the radio's directory
5. **Curate Content** - Create `content.json` with curated sections and blocks
6. **Validate** - Ensure JSON is valid and follows the schema

## Directory Structure

```
content/
  pdfs/                           # Original downloaded PDFs
    KX2_owners_man_B2.pdf
  extracted/                      # Extracted text for reference
    elecraft-kx2_raw_text.txt
    elecraft-kx2_skeleton.json
  elecraft-kx2/                   # Curated content directory
    KX2_owners_man_B2.pdf         # Copy of PDF for bundling
    content.json                  # Curated content
  elecraft-k3/                    # Another radio...
    ...
```

## content.json Schema

Each `content.json` file has this structure:

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
      "id": "section-id",
      "title": "Section Title",
      "blocks": [...]
    }
  ]
}
```

## Block Types

**CRITICAL: Use the exact field names shown below. The app will show empty content if field names are wrong.**

| Block Type | Required Fields | WRONG (will break) |
|------------|-----------------|-------------------|
| paragraph | `text` | ~~content~~ |
| note | `text` | ~~content~~ |
| warning | `text` | ~~content~~ |
| menuEntry | `name`, `description` | |
| specification | `name`, `value` | ~~label~~ |
| specificationTable | `rows` (array) | ~~entries~~ |

### paragraph

For explanatory text and descriptions.

```json
{
  "type": "paragraph",
  "text": "The Elecraft KX2 is a compact 80-10 m transceiver designed for portable operation."
}
```

**WRONG** - do NOT use `content`:
```json
{
  "type": "paragraph",
  "content": "..."  // WRONG! Use "text" instead
}
```

### menuEntry

For menu settings and controls with their descriptions.

```json
{
  "type": "menuEntry",
  "name": "VOX DLY",
  "description": "Sets the VOX delay time in seconds. A setting of about 0.5 seconds will keep the radio in transmit mode during typical continuous speech."
}
```

### specification

For individual technical specifications.

```json
{
  "type": "specification",
  "name": "Frequency Range",
  "value": "Receive: 500 kHz - 32 MHz; Transmit: 80-10 m ham bands"
}
```

### specificationTable

For a group of related specifications. Supports two row formats:

**Object format (preferred):**
```json
{
  "type": "specificationTable",
  "rows": [
    { "name": "Frequency Range", "value": "500 kHz - 32 MHz (RX)" },
    { "name": "Output Power", "value": "15W max (80-20m)" }
  ]
}
```

**Array format (also valid):**
```json
{
  "type": "specificationTable",
  "rows": [
    ["Frequency Range", "500 kHz - 32 MHz (RX)"],
    ["Output Power", "15W max (80-20m)"]
  ]
}
```

**WRONG** - do NOT use `entries` or `label`:
```json
{
  "type": "specificationTable",
  "entries": [...]  // WRONG! Use "rows" instead
}
```

### note

For helpful tips and additional information.

```json
{
  "type": "note",
  "text": "Headphones or external speakers will provide greater bass response than the internal speaker."
}
```

**WRONG** - do NOT use `content`:
```json
{
  "type": "note",
  "content": "..."  // WRONG! Use "text" instead
}
```

### warning

For safety warnings and cautions.

```json
{
  "type": "warning",
  "text": "Always turn the KX2 off before disconnecting the power source to ensure settings are saved."
}
```

**WRONG** - do NOT use `content`:
```json
{
  "type": "warning",
  "content": "..."  // WRONG! Use "text" instead
}
```

## Standard Sections

Each radio should have these 8 sections. Adjust content based on what's available in the manual.

### 1. Operation Basics

Core operating procedures: power on/off, band selection, mode selection, basic controls.

- Focus on getting started quickly
- Include essential control descriptions
- Keep explanations concise

### 2. Menu System Reference

Important menu entries and their settings.

- Include the most commonly used menu entries
- Provide clear descriptions of what each does
- Group related entries if helpful

### 3. CW/Keyer Settings

CW-specific configuration and operation.

- Keyer setup and configuration
- Speed, weight, and timing settings
- Sidetone and pitch configuration
- Message memory usage

### 4. Filters & DSP

Receiver filtering and DSP features.

- Filter passband adjustment
- Noise reduction settings
- Audio peaking filter (APF)
- Auto-notch and other DSP features

### 5. Power & Battery

Power supply requirements and battery operation.

- Supply voltage requirements
- Current consumption
- Battery installation and charging
- Power-saving features

### 6. ATU Operation

Automatic antenna tuner usage (if applicable).

- Basic ATU operation
- Manual vs automatic tuning
- Troubleshooting tips

### 7. Specifications

Technical specifications for quick reference.

- Use specificationTable for organized display
- Include key specs operators need
- Group by category (General, Receiver, Transmitter)

### 8. Quick Troubleshooting

Common problems and solutions.

- Format as menuEntry blocks (problem: solution)
- Focus on field-serviceable issues
- Include error message explanations

## Content Guidelines

### Writing Style

- Use clear, concise language
- Write in present tense
- Use active voice
- Avoid jargon unless explained
- Keep paragraphs focused on one topic

### What to Include

- Information needed during field operation
- Quick reference material
- Common procedures and settings
- Safety-critical warnings

### What to Exclude

- Lengthy theory sections
- Factory calibration procedures
- Circuit descriptions
- Assembly instructions
- Warranty and legal text

### Formatting

- Use proper capitalization for menu names (e.g., "VOX DLY")
- Include units with specifications (e.g., "150 mA")
- Use consistent terminology throughout
- Reference page numbers from original manual where helpful

## Validation Checklist

Before committing content:

- [ ] JSON is valid (use a JSON validator)
- [ ] All required fields are present
- [ ] IDs are unique within the file
- [ ] Block types are spelled correctly
- [ ] **paragraph/note/warning blocks use `text` (NOT `content`)**
- [ ] **specificationTable blocks use `rows` (NOT `entries`)**
- [ ] **specification rows use `name` (NOT `label`)**
- [ ] Text content is accurate to the manual
- [ ] No placeholder or sample text remains
- [ ] PDF file exists in the directory
- [ ] pdfFilename matches the actual file

## Common Mistakes

| Symptom | Cause | Fix |
|---------|-------|-----|
| Section shows but content is empty | Wrong field name (e.g., `content` instead of `text`) | Use `text` for paragraph/note/warning |
| Specification table is empty | Used `entries` instead of `rows` | Rename to `rows` |
| Specifications show empty labels | Used `label` instead of `name` | Rename to `name` |
| App shows old data after fixing JSON | SwiftData cache | Delete app and reinstall |

## Field Name Reference

Copy-paste these templates to avoid typos:

```json
// Paragraph
{ "type": "paragraph", "text": "" }

// Note  
{ "type": "note", "text": "" }

// Warning
{ "type": "warning", "text": "" }

// Menu Entry
{ "type": "menuEntry", "name": "", "description": "" }

// Specification (single)
{ "type": "specification", "name": "", "value": "" }

// Specification Table
{ "type": "specificationTable", "rows": [{ "name": "", "value": "" }] }
```
