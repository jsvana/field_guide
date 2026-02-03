# File Index

This index maps files to their purpose. Use it to locate files by feature instead of scanning the codebase.

**Maintenance:** When adding, removing, or renaming files, update this index.

## Entry Points
| File | Purpose |
|------|---------|
| `FieldGuide/FieldGuide/FieldGuideApp.swift` | App entry point, SwiftData container setup, bundled content loading |
| `FieldGuide/FieldGuide/ContentView.swift` | Root TabView (Library, Search, Settings tabs) |

## Models (`FieldGuide/FieldGuide/Models/`)
| File | Purpose |
|------|---------|
| `Radio.swift` | Radio model (manufacturer, model, revision, PDF path, download status) |
| `Section.swift` | Manual section model (title, sortOrder, searchableText, blocks relationship) |
| `ContentBlock.swift` | Content block model (paragraph, menuEntry, specification, specificationTable, note, warning) |

## Services (`FieldGuide/FieldGuide/Services/`)
| File | Purpose |
|------|---------|
| `ContentImporter.swift` | Actor that parses JSON content files into SwiftData models |

## Views - Tabs (`FieldGuide/FieldGuide/Views/`)
| File | Purpose |
|------|---------|
| `LibraryTab.swift` | Radio grid display with RadioCard component |
| `SearchTab.swift` | Full-text search across all manuals with scope filtering |
| `SettingsTab.swift` | Settings, ManageDownloadsView for storage, AttributionsView for credits |

## Views - Detail (`FieldGuide/FieldGuide/Views/`)
| File | Purpose |
|------|---------|
| `RadioDetailView.swift` | Radio sections list with SectionRow component |
| `SectionDetailView.swift` | Section content display with block renderers (ParagraphBlock, MenuEntryBlock, SpecificationBlock, SpecificationTableBlock, NoteBlock) |
| `PDFViewerSheet.swift` | PDFKit-based PDF viewer sheet |
| `BugReportView.swift` | Bug report form that copies report to clipboard and opens Discord |

## Content Pipeline (`tools/`)
| File | Purpose |
|------|---------|
| `download_pdfs.py` | Download PDF manuals from various vendors |
| `extract_content.py` | Extract raw text from PDFs and generate skeleton JSON |
| `generate_manifest.py` | Generate manifest.json listing all available radios |

## Content (`content/`)
| File | Purpose |
|------|---------|
| `manifest.json` | Index of all available radio manuals |
| `CURATION_GUIDE.md` | Guide for curating content JSON files |
| `elecraft-k1/content.json` | Curated content for Elecraft K1 |
| `elecraft-k2/content.json` | Curated content for Elecraft K2 |
| `elecraft-kh1/content.json` | Curated content for Elecraft KH1 |
| `elecraft-kx1/content.json` | Curated content for Elecraft KX1 |
| `elecraft-kx2/content.json` | Curated content for Elecraft KX2 |
| `elecraft-kx3/content.json` | Curated content for Elecraft KX3 |
| `hamgadgets-cft1/content.json` | Curated content for HamGadgets CFT1 |
| `penntek-tr45l/content.json` | Curated content for PennTek TR-45L |
| `penntek-tr35/content.json` | Curated content for PennTek TR-35 |
| `lnr-mtr4b-v2/content.json` | Curated content for LNR Precision MTR 4B V2 |
| `lnr-mtr3b-v4/content.json` | Curated content for LNR Precision MTR 3B V4 Currahee |
| `lnr-mtr5b/content.json` | Curated content for LNR Precision MTR 5B |
| `lnr-ld5/content.json` | Curated content for LNR Precision LD-5 |
| `yaesu-ft891/content.json` | Curated content for Yaesu FT-891 |
| `extracted/*_skeleton.json` | Raw extracted text skeletons (not curated) |

## Documentation (`docs/`)
| File | Purpose |
|------|---------|
| `FILE_INDEX.md` | This file - maps files to their purpose |
| `plans/2026-02-02-field-guide-design.md` | Design document |
| `plans/2026-02-02-field-guide-implementation.md` | Implementation plan |

## Tests (`FieldGuide/FieldGuideTests/`)
| File | Purpose |
|------|---------|
| `FieldGuideTests.swift` | Unit tests |

## UI Tests (`FieldGuide/FieldGuideUITests/`)
| File | Purpose |
|------|---------|
| `FieldGuideUITests.swift` | UI tests |
| `FieldGuideUITestsLaunchTests.swift` | Launch performance tests |
