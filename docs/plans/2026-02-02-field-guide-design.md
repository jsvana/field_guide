# Carrier Wave Field Guide — Design Document

**Date:** 2026-02-02
**Status:** Draft

## Overview

Carrier Wave Field Guide is an offline-first iOS app for amateur radio operators to reference equipment manuals in the field. It provides pre-curated, styled content for quick lookup during operation, with access to original PDFs for complete documentation.

### Goals

- **Field-ready reference** — Quick access to operational information while portable or at home
- **Offline-first** — All content available without network after initial download
- **Clean presentation** — Styled content following Carrier Wave design language, not raw PDF rendering
- **Complete access** — Original PDFs available for assembly, schematics, and deep reference

### Non-Goals

- Automated PDF parsing (quality too variable)
- Cloud sync or accounts
- In-app editing or annotations
- Assembly/construction guides in styled format (use PDF)

## Supported Radios (V1)

| Radio | Manufacturer | Manual Revision | PDF Source |
|-------|--------------|-----------------|------------|
| K1 | Elecraft | Rev J | ftp.elecraft.com |
| K2 | Elecraft | Rev I | ftp.elecraft.com |
| KX1 | Elecraft | Rev E | ftp.elecraft.com |
| KX2 | Elecraft | B2 | ftp.elecraft.com |

## Content Sections

Each radio includes these field-relevant sections:

1. **Operation Basics** — Band switching, mode selection, tuning
2. **Menu System Reference** — Full menu tree with explanations
3. **CW/Keyer Settings** — Speed, sidetone, keyer mode
4. **Filters & DSP** — Bandwidth, noise reduction, notch
5. **Power & Battery** — Voltage display, low-battery behavior
6. **ATU Operation** — Internal antenna tuner (if equipped)
7. **Specifications** — Frequency coverage, power output, current draw
8. **Quick Troubleshooting** — Common issues and solutions

Assembly, construction, and alignment sections are accessible via the original PDF only.

---

## Data Model

### Radio

Represents a supported radio model.

```swift
@Model
class Radio {
    @Attribute(.unique) var id: String          // "elecraft-kx2"
    var manufacturer: String                     // "Elecraft"
    var model: String                           // "KX2"
    var manualRevision: String                  // "B2"
    var pdfURL: URL                             // Remote URL
    var pdfLocalPath: String?                   // Local file path after download
    var isDownloaded: Bool
    var downloadedAt: Date?

    @Relationship(deleteRule: .cascade)
    var sections: [Section]
}
```

### Section

A chapter of field-relevant content.

```swift
@Model
class Section {
    @Attribute(.unique) var id: String          // "kx2-menu-reference"
    var title: String                           // "Menu System Reference"
    var sortOrder: Int
    var searchableText: String                  // Flattened text for search

    var radio: Radio?

    @Relationship(deleteRule: .cascade)
    var blocks: [ContentBlock]
}
```

### ContentBlock

Individual content pieces within a section.

```swift
@Model
class ContentBlock {
    @Attribute(.unique) var id: String
    var sortOrder: Int
    var blockType: ContentBlockType
    var content: ContentBlockData              // Encoded as JSON

    var section: Section?
}

enum ContentBlockType: String, Codable {
    case paragraph
    case menuEntry
    case specification
    case specificationTable
    case note
    case warning
}

// Content varies by type
struct ContentBlockData: Codable {
    // Paragraph
    var text: String?

    // Menu Entry
    var menuName: String?
    var menuDescription: String?

    // Specification
    var specLabel: String?
    var specValue: String?

    // Table
    var tableRows: [[String]]?
    var tableHeaders: [String]?

    // Note/Warning
    var noteText: String?
}
```

---

## Storage Strategy

Following iOS storage best practices:

| Data | Location | Backed Up | Purgeable |
|------|----------|-----------|-----------|
| SwiftData database | Application Support | Yes | No |
| Downloaded PDFs | Application Support | No (`isExcludedFromBackup`) | No |
| Cached manifest | Caches | No | Yes |

### Rationale

- **SwiftData in Application Support** — Persists across app updates, included in user backups
- **PDFs excluded from backup** — Large files that can be re-downloaded; keeps backups small
- **No Documents directory usage** — Content is app-managed, not user-created documents

---

## Navigation Architecture

### Tab Structure

```
TabView
├── Library Tab (house icon)
│   └── NavigationStack
│       ├── RadioListView
│       │   └── RadioDetailView
│       │       ├── SectionListView
│       │       │   └── SectionDetailView
│       │       └── PDFView (full-screen presentation)
│
├── Search Tab (magnifyingglass icon)
│   └── NavigationStack
│       ├── SearchView
│       │   └── SectionDetailView (scrolled to match)
│
└── Settings Tab (gear icon)
    └── NavigationStack
        └── SettingsView
            ├── Check for Updates
            ├── Manage Downloads
            └── About
```

### Navigation State

- Each tab has independent NavigationStack
- NavigationPath not needed (simple linear flows)
- No deep linking required for V1

---

## Screen Designs

### Library Tab — RadioListView

**Layout:** 2-column grid (iPhone), 3+ columns (iPad)

**Radio Card:**
```
┌─────────────────────────┐
│      [Radio Image]      │
│                         │
│  KX2                    │
│  Elecraft         [B2]  │
└─────────────────────────┘
```

- Card background: `Color(.systemGray6)`
- Corner radius: 12pt
- Model name: `.headline`
- Manufacturer: `.caption`, `.secondary`
- Revision badge: Capsule, `Color.blue.opacity(0.2)`

**Add Radio Card:**
```
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
│                         │
│      [plus.circle]      │
│                         │
│     Add Radio           │
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

- Dashed border: `.secondary`
- Icon and text: `.secondary`

**Empty State:**
```
┌─────────────────────────────────────┐
│                                     │
│         [book.closed.fill]          │
│                                     │
│   Download your first manual        │
│   to get started                    │
│                                     │
│      [Add Radio Button]             │
│                                     │
└─────────────────────────────────────┘
```

### Library Tab — RadioDetailView

**Layout:**
```
┌─────────────────────────────────────┐
│ ← KX2                        [PDF]  │  Navigation bar
├─────────────────────────────────────┤
│                                     │
│  [Section List - scrollable]        │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ 📖  Operation Basics      > │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 📋  Menu System Reference > │    │
│  └─────────────────────────────┘    │
│  ┌─────────────────────────────┐    │
│  │ 🎵  CW/Keyer Settings     > │    │
│  └─────────────────────────────┘    │
│  ...                                │
│                                     │
└─────────────────────────────────────┘
```

- "PDF" toolbar button opens full PDF
- Section rows follow Carrier Wave list row pattern
- Icons: SF Symbols, `.blue`

### Library Tab — SectionDetailView

**Layout:** ScrollView with content blocks

```
┌─────────────────────────────────────┐
│ ← Menu System Reference             │
├─────────────────────────────────────┤
│                                     │
│  Access the menu by tapping MENU.   │
│  Use the VFO knob to scroll...      │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ KEYER SPD                   │    │
│  │ Sets CW keyer speed from    │    │
│  │ 8-50 WPM. Default: 20 WPM.  │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ KEYER MD                    │    │
│  │ Selects keyer mode: A, B,   │    │
│  │ or Straight key.            │    │
│  └─────────────────────────────┘    │
│                                     │
│  ┌─────────────────────────────┐    │
│  │ ⚠️  Speed changes take      │    │
│  │    effect immediately.      │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

### Search Tab — SearchView

**Layout:**
```
┌─────────────────────────────────────┐
│ Search                              │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ 🔍  Search manuals...           │ │
│ └─────────────────────────────────┘ │
│                                     │
│  [All] [KX2] [K2] [K1] [KX1]       │  Scope chips
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  [KX2]  Menu System Reference       │
│  "...KEYER SPD sets CW keyer..."    │
│                                     │
│  [K2]   CW Operation                │
│  "...adjust keyer speed using..."   │
│                                     │
└─────────────────────────────────────┘
```

- Scope chips: only show downloaded radios
- Results grouped by radio
- Matching text shown as preview with highlight
- Minimum 2 characters to search

### Settings Tab

**Layout:** Standard iOS Settings style (grouped list)

```
┌─────────────────────────────────────┐
│ Settings                            │
├─────────────────────────────────────┤
│                                     │
│  UPDATES                            │
│  ┌─────────────────────────────┐    │
│  │ Check for Updates         > │    │
│  └─────────────────────────────┘    │
│                                     │
│  STORAGE                            │
│  ┌─────────────────────────────┐    │
│  │ Manage Downloads          > │    │
│  │ 4 radios • 12.4 MB          │    │
│  └─────────────────────────────┘    │
│                                     │
│  ABOUT                              │
│  ┌─────────────────────────────┐    │
│  │ Version 1.0 (Build 1)       │    │
│  │ Carrier Wave Field Guide    │    │
│  └─────────────────────────────┘    │
│                                     │
└─────────────────────────────────────┘
```

---

## Content Styling

Following Carrier Wave design language:

### Typography

| Element | Style |
|---------|-------|
| Section title | `.headline` |
| Subsection header | `.subheadline.weight(.semibold)` |
| Body text | `.body` |
| Menu item names | `.subheadline.weight(.semibold).monospaced()` |
| Frequencies/values | `.body.monospaced()` |
| Notes/captions | `.caption`, `.secondary` |

### Content Block Styling

**Paragraph:**
```swift
Text(block.text)
    .font(.body)
```

**Menu Entry:**
```swift
VStack(alignment: .leading, spacing: 4) {
    Text(block.menuName)
        .font(.subheadline.weight(.semibold).monospaced())
    Text(block.menuDescription)
        .font(.body)
        .foregroundStyle(.secondary)
}
.padding()
.background(Color(.systemGray6))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

**Specification Row:**
```swift
HStack {
    Text(block.specLabel)
        .font(.subheadline)
    Spacer()
    Text(block.specValue)
        .font(.subheadline.monospaced())
        .foregroundStyle(.secondary)
}
```

**Warning Callout:**
```swift
HStack(spacing: 8) {
    Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
    Text(block.noteText)
        .font(.subheadline)
}
.padding()
.background(Color.orange.opacity(0.15))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

**Note Callout:**
```swift
HStack(spacing: 8) {
    Image(systemName: "info.circle.fill")
        .foregroundStyle(.blue)
    Text(block.noteText)
        .font(.subheadline)
}
.padding()
.background(Color.blue.opacity(0.15))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

### Search Highlighting

```swift
Text(matchingText)
    .background(Color.yellow.opacity(0.3))
```

---

## Download & Update Flow

### Content Hosting

Static files hosted on GitHub Pages (or similar):

```
field-guide-content/
├── manifest.json
├── elecraft-k1/
│   ├── content.json
│   └── E740016_K1_manual_rev_J.pdf
├── elecraft-k2/
│   ├── content.json
│   └── E740001_K2_Owners_Manual_Rev_I.pdf
├── elecraft-kx1/
│   ├── content.json
│   └── KX1_Owners_Manual_Rev_E.pdf
└── elecraft-kx2/
    ├── content.json
    └── KX2_owners_man_B2.pdf
```

### Manifest Format

```json
{
  "version": 1,
  "lastUpdated": "2026-02-02",
  "radios": [
    {
      "id": "elecraft-kx2",
      "manufacturer": "Elecraft",
      "model": "KX2",
      "revision": "B2",
      "contentURL": "https://example.com/field-guide-content/elecraft-kx2/content.json",
      "pdfURL": "https://example.com/field-guide-content/elecraft-kx2/KX2_owners_man_B2.pdf",
      "pdfSize": 3200000,
      "contentSize": 45000
    }
  ]
}
```

### Download Flow

1. App fetches manifest on "Add Radio" tap
2. Displays available radios not yet downloaded
3. User selects radio
4. Downloads content.json and PDF in parallel
5. Parses JSON into SwiftData models
6. Saves PDF to Application Support
7. Marks radio as downloaded

### Update Flow

1. User taps "Check for Updates" in Settings
2. App fetches manifest
3. Compares revisions against downloaded radios
4. Shows list of available updates
5. User taps "Update" on individual radios
6. Re-downloads content and PDF
7. Replaces existing data

---

## Search Implementation

### Index Building

On download, flatten all content block text into `Section.searchableText`:

```swift
func buildSearchableText(for section: Section) -> String {
    section.blocks.map { block in
        switch block.blockType {
        case .paragraph:
            return block.content.text ?? ""
        case .menuEntry:
            return "\(block.content.menuName ?? "") \(block.content.menuDescription ?? "")"
        case .specification:
            return "\(block.content.specLabel ?? "") \(block.content.specValue ?? "")"
        case .note, .warning:
            return block.content.noteText ?? ""
        case .specificationTable:
            return block.content.tableRows?.flatMap { $0 }.joined(separator: " ") ?? ""
        }
    }.joined(separator: " ")
}
```

### Search Query

```swift
@Query var sections: [Section]

var searchResults: [Section] {
    guard query.count >= 2 else { return [] }
    let lowercased = query.lowercased()

    return sections.filter { section in
        // Filter by scope if not "All"
        if let scopeRadio = selectedRadio {
            guard section.radio?.id == scopeRadio.id else { return false }
        }

        return section.title.lowercased().contains(lowercased) ||
               section.searchableText.lowercased().contains(lowercased)
    }
}
```

---

## PDF Viewing

### Implementation

Using PDFKit's `PDFView`:

```swift
import PDFKit

struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {}
}
```

### Presentation

```swift
.fullScreenCover(isPresented: $showPDF) {
    NavigationStack {
        PDFViewer(url: pdfURL)
            .navigationTitle(radio.model)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { showPDF = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: pdfURL)
                }
            }
    }
}
```

---

## Content Curation Format

### JSON Structure

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
          "text": "The KX2 covers 80 through 10 meters..."
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
          "text": "Access the menu by tapping MENU..."
        },
        {
          "type": "menuEntry",
          "name": "KEYER SPD",
          "description": "Sets CW keyer speed from 8-50 WPM. Default: 20 WPM."
        },
        {
          "type": "menuEntry",
          "name": "KEYER MD",
          "description": "Selects keyer mode: Iambic A, Iambic B, or Straight."
        },
        {
          "type": "warning",
          "text": "Speed changes take effect immediately."
        }
      ]
    },
    {
      "id": "kx2-specifications",
      "title": "Specifications",
      "sortOrder": 7,
      "blocks": [
        {
          "type": "specification",
          "label": "Frequency Range",
          "value": "80m - 10m"
        },
        {
          "type": "specification",
          "label": "Power Output",
          "value": "10W (12V), 5W (9V)"
        },
        {
          "type": "specificationTable",
          "headers": ["Band", "Frequency", "Power"],
          "rows": [
            ["80m", "3.5-4.0 MHz", "10W"],
            ["40m", "7.0-7.3 MHz", "10W"]
          ]
        }
      ]
    }
  ]
}
```

---

## Technical Requirements

### iOS Version

- **Minimum:** iOS 17.0 (SwiftData requirement)
- **Recommended:** iOS 18.0+

### Frameworks

- SwiftUI
- SwiftData
- PDFKit

### Permissions

- None required (no camera, location, notifications)

### Network

- Required only for initial download and update checks
- All reading functionality works offline

---

## Future Considerations (Post-V1)

Not in scope for V1, but worth considering:

- **Additional manufacturers** — Yaesu, Icom, Kenwood
- **Bookmarks** — Save frequently-referenced sections
- **Notes** — User annotations on sections
- **iPad sidebar** — NavigationSplitView for larger screens
- **watchOS companion** — Quick specs lookup on Apple Watch
- **Widgets** — Quick access to recently viewed sections

---

## Open Questions

1. **Content hosting** — GitHub Pages? CloudFlare Pages? S3?
2. **Radio imagery** — Use photos or stylized icons?
3. **App icon** — Design direction?

---

## Appendix: Content Source URLs

| Radio | PDF URL |
|-------|---------|
| K1 | https://ftp.elecraft.com/K1/Manuals%20Downloads/E740016%20K1%20manual%20rev%20J.pdf |
| K2 | https://ftp.elecraft.com/K2/Manuals%20Downloads/E740001_K2%20Owner's%20Manual%20Rev%20I.pdf |
| KX1 | https://ftp.elecraft.com/KX1/Manuals%20Downloads/KX1_Owner's_Manual_Rev_E.pdf |
| KX2 | https://ftp.elecraft.com/KX2/Manuals%20Downloads/KX2%20owner's%20man%20B2.pdf |
