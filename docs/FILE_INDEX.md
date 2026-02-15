# File Index

This index maps files to their purpose. Use it to locate files by feature instead of scanning the codebase.

**Maintenance:** When adding, removing, or renaming files, update this index.

## Entry Points
| File | Purpose |
|------|---------|
| `FieldGuide/FieldGuideApp.swift` | App entry point, SwiftData container setup, bundled content loading |
| `FieldGuide/ContentView.swift` | Root TabView (Library, Search, Checklists, Settings tabs) |

## Models (`FieldGuide/Models/`)
| File | Purpose |
|------|---------|
| `Radio.swift` | Radio model (manufacturer, model, revision, PDF path, download status) |
| `Section.swift` | Manual section model (title, sortOrder, searchableText, blocks relationship) |
| `ContentBlock.swift` | Content block model (paragraph, menuEntry, specification, specificationTable, note, warning) |
| `Checklist.swift` | Checklist and ChecklistItem models, ChecklistPhase enum |

## Services (`FieldGuide/Services/`)
| File | Purpose |
|------|---------|
| `ContentImporter.swift` | Actor that parses JSON content files into SwiftData models |
| `ChecklistImporter.swift` | Imports checklist templates from bundled JSON into SwiftData |

## Views - Tabs (`FieldGuide/Views/`)
| File | Purpose |
|------|---------|
| `LibraryTab.swift` | Radio grid display with RadioCard component |
| `SearchTab.swift` | Full-text search across all manuals with scope filtering |
| `ChecklistsTab.swift` | Checklist phase list with progress indicators |
| `SettingsTab.swift` | Settings, ManageDownloadsView for storage, AttributionsView for credits |

## Views - Detail (`FieldGuide/Views/`)
| File | Purpose |
|------|---------|
| `RadioDetailView.swift` | Radio sections list with SectionRow component |
| `ChecklistDetailView.swift` | Checklist items grouped by category with check toggling |
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
| `penntek-tr25/content.json` | Curated content for PennTek TR-25 |
| `bg2fx-fx4cr/content.json` | Curated content for BG2FX FX-4CR |
| `lnr-mtr4b-v2/content.json` | Curated content for LNR Precision MTR 4B V2 |
| `lnr-mtr3b-v4/content.json` | Curated content for LNR Precision MTR 3B V4 Currahee |
| `lnr-mtr5b/content.json` | Curated content for LNR Precision MTR 5B |
| `lnr-ld5/content.json` | Curated content for LNR Precision LD-5 |
| `norcal-20/content.json` | Curated content for NorCal QRP Club NorCal 20 |
| `norcal-40a/content.json` | Curated content for NorCal QRP Club NorCal 40A |
| `yaesu-ft891/content.json` | Curated content for Yaesu FT-891 |
| `xiegu-g90/content.json` | Curated content for Xiegu G90 |
| `xiegu-g106/content.json` | Curated content for Xiegu G106 |
| `xiegu-g1m/content.json` | Curated content for Xiegu G1M |
| `xiegu-x5105/content.json` | Curated content for Xiegu X5105 |
| `xiegu-x6100/content.json` | Curated content for Xiegu X6100 |
| `xiegu-x6200/content.json` | Curated content for Xiegu X6200 |
| `extracted/*_skeleton.json` | Raw extracted text skeletons (not curated) |

## Checklists (`FieldGuide/`)
| File | Purpose |
|------|---------|
| `checklists.json` | Bundled checklist template definitions (generic + radio-specific items) |

## Documentation (`docs/`)
| File | Purpose |
|------|---------|
| `FILE_INDEX.md` | This file - maps files to their purpose |
| `plans/2026-02-02-field-guide-design.md` | Design document |
| `plans/2026-02-02-field-guide-implementation.md` | Implementation plan |
| `plans/2026-02-15-outing-checklists.md` | Outing checklists design and implementation plan |

## Tests (`FieldGuideTests/`)
| File | Purpose |
|------|---------|
| `FieldGuideTests.swift` | Unit tests |

## UI Tests (`FieldGuideUITests/`)
| File | Purpose |
|------|---------|
| `FieldGuideUITests.swift` | UI tests |
| `FieldGuideUITestsLaunchTests.swift` | Launch performance tests |
