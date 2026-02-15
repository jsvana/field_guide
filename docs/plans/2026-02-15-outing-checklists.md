# Outing Checklists — Implementation Plan

**Date:** 2026-02-15
**Status:** Draft

**Goal:** Add activity-oriented outing checklists (pre-outing, during outing, debugging, cleanup, post-outing) as a new top-level tab, with resettable check state, radio-specific items, categorized groups, deep linking, and Carrier Wave styling.

**Architecture:** New SwiftData models for persistent check state. Checklist templates defined in bundled JSON. A new Checklists tab (4th tab, between Search and Settings). Deep links via `cwfieldguide://checklist/{phase}`.

---

## Phase 1: Data Model

### Task 1: Add Checklist SwiftData Models

**Files:**
- Create: `FieldGuide/FieldGuide/Models/Checklist.swift`

**Step 1: Create checklist models**

Create `FieldGuide/FieldGuide/Models/Checklist.swift`:
```swift
import Foundation
import SwiftData

enum ChecklistPhase: String, Codable, CaseIterable, Sendable {
    case preOuting
    case duringOuting
    case debugging
    case cleanup
    case postOuting

    var title: String {
        switch self {
        case .preOuting: "Pre-Outing"
        case .duringOuting: "During Outing"
        case .debugging: "Debugging"
        case .cleanup: "Cleanup"
        case .postOuting: "Post-Outing"
        }
    }

    var icon: String {
        switch self {
        case .preOuting: "bag.fill"
        case .duringOuting: "antenna.radiowaves.left.and.right"
        case .debugging: "wrench.and.screwdriver"
        case .cleanup: "arrow.uturn.down.circle"
        case .postOuting: "house.fill"
        }
    }

    /// URL path component for deep linking
    var pathComponent: String {
        switch self {
        case .preOuting: "pre-outing"
        case .duringOuting: "during-outing"
        case .debugging: "debugging"
        case .cleanup: "cleanup"
        case .postOuting: "post-outing"
        }
    }

    /// Init from deep link path component
    init?(pathComponent: String) {
        switch pathComponent {
        case "pre-outing": self = .preOuting
        case "during-outing": self = .duringOuting
        case "debugging": self = .debugging
        case "cleanup": self = .cleanup
        case "post-outing": self = .postOuting
        default: return nil
        }
    }
}

@Model
final class Checklist {
    @Attribute(.unique) var id: String
    var title: String
    var phase: ChecklistPhase
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.checklist)
    var items: [ChecklistItem] = []

    init(id: String, title: String, phase: ChecklistPhase, sortOrder: Int) {
        self.id = id
        self.title = title
        self.phase = phase
        self.sortOrder = sortOrder
    }
}

@Model
final class ChecklistItem {
    @Attribute(.unique) var id: String
    var text: String
    var isChecked: Bool
    var sortOrder: Int
    var category: String
    var radioId: String?

    var checklist: Checklist?

    init(
        id: String,
        text: String,
        sortOrder: Int,
        category: String,
        radioId: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isChecked = false
        self.sortOrder = sortOrder
        self.category = category
        self.radioId = radioId
    }
}
```

Design notes:
- `Checklist` is one per phase (5 total). Owns its items via cascade delete.
- `ChecklistItem` stores persistent check state. `category` groups items visually (e.g. "Radio & Accessories", "Power"). `radioId` is nil for generic items, or a radio ID string for radio-specific items.
- `ChecklistPhase` is a simple enum with display properties and deep link path mapping.
- No outing history in V1 — just a single resettable state per checklist.

**Step 2: Register new models in SwiftData schema**

Edit `FieldGuide/FieldGuide/FieldGuideApp.swift` — add `Checklist.self` and `ChecklistItem.self` to the schema array:

```swift
let schema = Schema([
    Radio.self,
    Section.self,
    ContentBlock.self,
    Checklist.self,
    ChecklistItem.self,
])
```

**Step 3: Commit**

```
feat: add Checklist and ChecklistItem SwiftData models
```

---

## Phase 2: Checklist Content

### Task 2: Create Bundled Checklist Template JSON

**Files:**
- Create: `FieldGuide/FieldGuide/checklists.json`

**Step 1: Create the checklist template file**

This JSON defines all generic checklist items. Radio-specific items will be added in a later phase.

Create `FieldGuide/FieldGuide/checklists.json`:
```json
{
  "checklists": [
    {
      "id": "pre-outing",
      "title": "Pre-Outing",
      "phase": "preOuting",
      "sortOrder": 1,
      "items": [
        {
          "category": "Radio & Accessories",
          "entries": [
            "Radio (powered on check before packing)",
            "Key / paddle / microphone",
            "Headphones",
            "Logging device or paper log",
            "Pen or pencil"
          ]
        },
        {
          "category": "Antenna & Feedline",
          "entries": [
            "Antenna",
            "Feedline / coax",
            "Antenna support (mast, throw line, etc.)",
            "Connectors and adapters",
            "SWR meter (if external)"
          ]
        },
        {
          "category": "Power",
          "entries": [
            "Battery (charged)",
            "Charging cable / power supply",
            "Backup battery or power source",
            "DC power cable / Anderson connectors"
          ]
        },
        {
          "category": "Personal & Safety",
          "entries": [
            "Copy of amateur radio license",
            "Water and snacks",
            "Sun protection",
            "First aid kit",
            "Weather forecast checked"
          ]
        },
        {
          "category": "Planning",
          "entries": [
            "Operating frequencies / band plan noted",
            "Site permission confirmed (if needed)",
            "Expected propagation checked"
          ]
        }
      ]
    },
    {
      "id": "during-outing",
      "title": "During Outing",
      "phase": "duringOuting",
      "sortOrder": 2,
      "items": [
        {
          "category": "Station Setup",
          "entries": [
            "Antenna deployed and secured",
            "Feedline connected",
            "Radio powered on",
            "SWR checked on operating frequency",
            "Power level set appropriately"
          ]
        },
        {
          "category": "On Air",
          "entries": [
            "Band and mode selected",
            "Verify transmitted audio / signal (if possible)",
            "Begin logging (time, frequency, callsign, RST)",
            "Announce spot if activating (POTA, SOTA, etc.)"
          ]
        }
      ]
    },
    {
      "id": "debugging",
      "title": "Debugging",
      "phase": "debugging",
      "sortOrder": 3,
      "items": [
        {
          "category": "No Transmit Power",
          "entries": [
            "Check antenna connection is secure",
            "Verify radio is not in receive-only mode",
            "Check power supply voltage",
            "Confirm correct band/mode selected",
            "Check for ATU bypass if not using tuner"
          ]
        },
        {
          "category": "High SWR",
          "entries": [
            "Retune ATU",
            "Check coax connections for corrosion or looseness",
            "Verify antenna is fully deployed / correct length",
            "Try a different frequency on the same band",
            "Inspect feedline for damage"
          ]
        },
        {
          "category": "No Receive / Weak Signals",
          "entries": [
            "Check headphone or speaker connection",
            "Verify volume and RF gain settings",
            "Confirm correct mode for signals (SSB vs CW vs FM)",
            "Check for noise blanker or DSP over-filtering",
            "Try a different band"
          ]
        },
        {
          "category": "Audio / Decode Issues",
          "entries": [
            "Check audio cable connections (for digital modes)",
            "Verify sound card or interface levels",
            "Confirm correct baud rate / mode in software",
            "Check for RFI on USB or audio cables"
          ]
        }
      ]
    },
    {
      "id": "cleanup",
      "title": "Cleanup",
      "phase": "cleanup",
      "sortOrder": 4,
      "items": [
        {
          "category": "Station Teardown",
          "entries": [
            "Log final QSO time",
            "QRT — announce sign-off",
            "Power off radio",
            "Disconnect antenna from radio",
            "Retract / take down antenna"
          ]
        },
        {
          "category": "Pack Up",
          "entries": [
            "Coil feedline properly (no kinks)",
            "Secure all connectors and adapters",
            "Pack radio with protection",
            "Collect all equipment — nothing left behind",
            "Pack out all trash"
          ]
        }
      ]
    },
    {
      "id": "post-outing",
      "title": "Post-Outing",
      "phase": "postOuting",
      "sortOrder": 5,
      "items": [
        {
          "category": "Logging",
          "entries": [
            "Transfer paper log to digital (if needed)",
            "Upload log to LoTW / QRZ / Club Log",
            "Submit POTA / SOTA activation (if applicable)"
          ]
        },
        {
          "category": "Equipment Care",
          "entries": [
            "Charge batteries",
            "Inspect antenna and feedline for damage",
            "Clean connectors if needed",
            "Store radio and accessories properly"
          ]
        },
        {
          "category": "Review",
          "entries": [
            "Note any equipment issues for next time",
            "Review what worked well and what didn't"
          ]
        }
      ]
    }
  ]
}
```

**Step 2: Commit**

```
feat: add bundled checklist template JSON
```

---

### Task 3: Create ChecklistImporter Service

**Files:**
- Create: `FieldGuide/FieldGuide/Services/ChecklistImporter.swift`

**Step 1: Create the importer**

Create `FieldGuide/FieldGuide/Services/ChecklistImporter.swift`:
```swift
import Foundation
import SwiftData

actor ChecklistImporter {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    @MainActor
    func importBundledChecklists() throws {
        guard let url = Bundle.main.url(forResource: "checklists", withExtension: "json") else {
            return
        }

        let data = try Data(contentsOf: url)
        let decoded = try JSONDecoder().decode(ChecklistsJSON.self, from: data)
        let context = modelContainer.mainContext

        for checklistJSON in decoded.checklists {
            guard let phase = ChecklistPhase(rawValue: checklistJSON.phase) else { continue }

            // Delete existing checklist for this phase (template update)
            let phaseRaw = checklistJSON.phase
            let existing = try context.fetch(FetchDescriptor<Checklist>(
                predicate: #Predicate { $0.id == phaseRaw }
            ))
            // Only import if no checklist exists for this phase.
            // This preserves user check state across app updates.
            if !existing.isEmpty { continue }

            let checklist = Checklist(
                id: checklistJSON.id,
                title: checklistJSON.title,
                phase: phase,
                sortOrder: checklistJSON.sortOrder
            )
            context.insert(checklist)

            var itemIndex = 0
            for categoryJSON in checklistJSON.items {
                for entry in categoryJSON.entries {
                    let item = ChecklistItem(
                        id: "\(checklistJSON.id)-\(itemIndex)",
                        text: entry,
                        sortOrder: itemIndex,
                        category: categoryJSON.category
                    )
                    item.checklist = checklist
                    context.insert(item)
                    itemIndex += 1
                }
            }
        }

        try context.save()
    }
}

// MARK: - JSON Models

struct ChecklistsJSON: Codable {
    let checklists: [ChecklistJSON]
}

struct ChecklistJSON: Codable {
    let id: String
    let title: String
    let phase: String
    let sortOrder: Int
    let items: [ChecklistCategoryJSON]
}

struct ChecklistCategoryJSON: Codable {
    let category: String
    let entries: [String]
}
```

Design notes:
- Imports only if no checklist exists for that phase — this preserves user check state across app updates. If we need to update templates, a "Reset" action deletes and reimports.
- Items get sequential `sortOrder` across categories so they display in template order.
- Uses `id: "\(checklistJSON.id)-\(itemIndex)"` for stable unique IDs.

**Step 2: Call importer from FieldGuideApp**

Edit `FieldGuide/FieldGuide/FieldGuideApp.swift` — add a call to `ChecklistImporter` in `loadBundledContentIfNeeded()`:

```swift
// At end of loadBundledContentIfNeeded():
let checklistImporter = ChecklistImporter(modelContainer: sharedModelContainer)
try? await checklistImporter.importBundledChecklists()
```

**Step 3: Commit**

```
feat: add ChecklistImporter service with bundled JSON loading
```

---

## Phase 3: Checklists Tab

### Task 4: Create ChecklistsTab View

**Files:**
- Create: `FieldGuide/FieldGuide/Views/ChecklistsTab.swift`

**Step 1: Create the tab view**

Create `FieldGuide/FieldGuide/Views/ChecklistsTab.swift`:

The view shows all 5 checklists in a list with:
- Phase icon (SF Symbol, `.blue`, consistent with RadioDetailView `SectionRow`)
- Phase title (`.subheadline`, matching `SectionRow`)
- Progress indicator (e.g. "3/12" in `.caption.monospacedDigit()`, `.secondary`)
- Chevron disclosure (via `NavigationLink`)
- A "Reset All Checklists" button at the bottom

Carrier Wave styling:
- `.listStyle(.plain)` (matching RadioDetailView)
- HStack spacing: 12pt
- Icon frame width: 32pt
- Vertical padding: 4pt on rows
- These values match the existing `SectionRow` component exactly

Navigation:
- `NavigationStack` with `NavigationLink` to `ChecklistDetailView`
- `@Environment(AppState.self)` to react to deep link pending state

State management:
- `@Query(sort: \Checklist.sortOrder)` for checklist list
- Pass the `Checklist` model object to detail view

Reset action:
- Button at bottom of list, `.foregroundStyle(.red)`, centered
- Presents confirmation dialog
- On confirm: sets all items' `isChecked = false` across all checklists

**Step 2: Commit**

```
feat: add ChecklistsTab with phase list and reset
```

---

### Task 5: Add Checklists Tab to ContentView

**Files:**
- Edit: `FieldGuide/FieldGuide/ContentView.swift`

**Step 1: Insert new tab**

Add the Checklists tab between Search (tag 1) and Settings (tag 2). Shift Settings to tag 3:

```swift
TabView(selection: $appState.selectedTab) {
    LibraryTab()
        .tabItem { Label("Library", systemImage: "books.vertical") }
        .tag(0)

    SearchTab()
        .tabItem { Label("Search", systemImage: "magnifyingglass") }
        .tag(1)

    ChecklistsTab()
        .tabItem { Label("Checklists", systemImage: "checklist") }
        .tag(2)

    SettingsTab()
        .tabItem { Label("Settings", systemImage: "gear") }
        .tag(3)
}
```

**Step 2: Commit**

```
feat: add Checklists as fourth tab in tab bar
```

---

## Phase 4: Checklist Detail View

### Task 6: Create ChecklistDetailView

**Files:**
- Create: `FieldGuide/FieldGuide/Views/ChecklistDetailView.swift`

**Step 1: Create the detail view**

The detail view shows items grouped by category with toggleable check state.

Layout:
```
┌─────────────────────────────────────┐
│ ← Pre-Outing              [Reset]  │
├─────────────────────────────────────┤
│                                     │
│  RADIO & ACCESSORIES                │   ← section header, .caption.weight(.semibold), .secondary
│  ☑ Radio (powered on check)        │
│  ☐ Key / paddle / microphone       │
│  ☐ Headphones                      │
│                                     │
│  POWER                              │
│  ☐ Battery (charged)               │
│  ☐ Charging cable                  │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  ✓ All items complete!             │   ← shown when all checked
│                                     │
└─────────────────────────────────────┘
```

Checklist item row (Carrier Wave styling):
```swift
Button {
    item.isChecked.toggle()
} label: {
    HStack(spacing: 12) {
        Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
            .font(.title3)
            .foregroundStyle(item.isChecked ? .green : .secondary)
        Text(item.text)
            .font(.subheadline)
            .strikethrough(item.isChecked)
            .foregroundStyle(item.isChecked ? .secondary : .primary)
    }
    .padding(.vertical, 4)
    .contentShape(Rectangle())
}
.buttonStyle(.plain)
```

Design notes:
- Green checkmark follows the established pattern of semantic color (blue=info, orange=warning, green=complete)
- `.strikethrough` on checked items gives immediate visual feedback without removing them
- `contentShape(Rectangle())` makes the full row tappable
- Category headers use the standard SwiftUI `Section` header style (`.caption.weight(.semibold)`)
- Use `List` with sections for grouped display

All-complete state:
- When every item is checked, show a completion banner at the top
- Use the note callout pattern: `HStack` with icon + text, padded, with green background at `0.15` opacity, rounded 12pt corners
- Icon: `checkmark.seal.fill`, green
- Text: "All items complete!"

Toolbar:
- "Reset" button in `.topBarTrailing` that unchecks all items in this checklist
- Confirmation dialog before resetting

Data:
- `@Bindable var checklist: Checklist` passed from ChecklistsTab
- Computed property groups items by category, maintaining sort order
- Direct `@Bindable` on items allows toggling `isChecked` with automatic SwiftData persistence

**Step 2: Commit**

```
feat: add ChecklistDetailView with grouped items and check toggling
```

---

## Phase 5: Deep Linking

### Task 7: Extend Deep Linking for Checklists

**Files:**
- Edit: `FieldGuide/FieldGuide/Models/AppState.swift`
- Edit: `FieldGuide/FieldGuide/FieldGuideApp.swift`
- Edit: `FieldGuide/FieldGuide/Views/ChecklistsTab.swift`

**Step 1: Add pending checklist state to AppState**

Edit `FieldGuide/FieldGuide/Models/AppState.swift`:
```swift
@Observable final class AppState {
    var selectedTab: Int = 0
    var pendingRadioID: String?
    var pendingChecklistPhase: String?
}
```

**Step 2: Handle checklist deep links in FieldGuideApp**

Edit `handleDeepLink` in `FieldGuide/FieldGuide/FieldGuideApp.swift` to handle `cwfieldguide://checklist/{phase}`:

```swift
private func handleDeepLink(_ url: URL) {
    guard url.scheme == "cwfieldguide" else { return }

    switch url.host {
    case "radio":
        let radioID = url.pathComponents
            .filter { $0 != "/" }
            .joined(separator: "/")
        guard !radioID.isEmpty else { return }
        appState.pendingRadioID = radioID
        appState.selectedTab = 0

    case "checklist":
        let phase = url.pathComponents
            .filter { $0 != "/" }
            .first
        appState.pendingChecklistPhase = phase
        appState.selectedTab = 2  // Checklists tab

    default:
        break
    }
}
```

Deep link URL scheme:
| URL | Destination |
|-----|-------------|
| `cwfieldguide://checklist` | Checklists tab (list view) |
| `cwfieldguide://checklist/pre-outing` | Pre-Outing checklist detail |
| `cwfieldguide://checklist/during-outing` | During Outing checklist detail |
| `cwfieldguide://checklist/debugging` | Debugging checklist detail |
| `cwfieldguide://checklist/cleanup` | Cleanup checklist detail |
| `cwfieldguide://checklist/post-outing` | Post-Outing checklist detail |

**Step 3: React to deep link in ChecklistsTab**

In `ChecklistsTab`, add an `onChange` handler for `appState.pendingChecklistPhase` that navigates to the matching checklist (same pattern as `LibraryTab.onChange(of: appState.pendingRadioID)`).

**Step 4: Commit**

```
feat: add deep linking for checklists (cwfieldguide://checklist/{phase})
```

---

## Phase 6: Radio-Specific Checklist Items

### Task 8: Add Radio-Specific Items to Checklist JSON

**Files:**
- Edit: `FieldGuide/FieldGuide/checklists.json`
- Edit: `FieldGuide/FieldGuide/Services/ChecklistImporter.swift`

**Step 1: Extend JSON format for radio-specific items**

Add a `radioId` field to category entries. When present, items are only shown if the user has that radio downloaded. Example additions to the pre-outing checklist:

```json
{
  "category": "KX2-Specific",
  "radioId": "elecraft-kx2",
  "entries": [
    "KX2 internal battery charged (check voltage on display)",
    "Verify ATU setting matches planned antenna"
  ]
}
```

Similar entries for other popular radios (G90, IC-705, FT-891, etc.). Keep these minimal — 2-3 items per radio for the most operationally relevant tips.

**Step 2: Update ChecklistImporter to handle radioId**

Pass `categoryJSON.radioId` through to `ChecklistItem.radioId` during import.

**Step 3: Update ChecklistDetailView filtering**

In `ChecklistDetailView`, filter out items where `radioId != nil` unless a radio with that ID exists and is downloaded. This means radio-specific items automatically appear/disappear as radios are added/removed.

No "radio picker" needed — if you have the radio downloaded, you see its items. This avoids UI complexity and leverages existing state.

**Step 4: Commit**

```
feat: add radio-specific checklist items for downloaded radios
```

---

## Phase 7: Polish

### Task 9: Progress Badge and Completion State

**Files:**
- Edit: `FieldGuide/FieldGuide/Views/ChecklistsTab.swift`
- Edit: `FieldGuide/FieldGuide/Views/ChecklistDetailView.swift`

**Step 1: Progress display on ChecklistsTab rows**

Show checked/total count on each row:
```swift
Text("\(checkedCount)/\(totalCount)")
    .font(.caption.monospacedDigit())
    .foregroundStyle(.secondary)
```

When a phase is fully complete, swap the count for a green checkmark:
```swift
Image(systemName: "checkmark.circle.fill")
    .foregroundStyle(.green)
```

**Step 2: Completion banner in ChecklistDetailView**

When all visible items are checked, show a completion note at the top of the list using the existing Carrier Wave note callout pattern (green variant):

```swift
HStack(alignment: .center, spacing: 8) {
    Image(systemName: "checkmark.seal.fill")
        .foregroundStyle(.green)
    Text("All items complete!")
        .font(.subheadline)
}
.padding()
.frame(maxWidth: .infinity, alignment: .leading)
.background(Color.green.opacity(0.15))
.clipShape(RoundedRectangle(cornerRadius: 12))
```

**Step 3: Commit**

```
feat: add progress indicators and completion state to checklists
```

---

### Task 10: Version Bump, Changelog, and File Index

**Files:**
- Edit: `CHANGELOG.md`
- Edit: `docs/FILE_INDEX.md`
- Edit: `FieldGuide/FieldGuide.xcodeproj/project.pbxproj`

**Step 1: Update CHANGELOG.md**

Add under `## [Unreleased]`:
```markdown
### Added
- Outing checklists — five-phase workflow (Pre-Outing, During Outing, Debugging, Cleanup, Post-Outing) with resettable check state
- Checklists tab in main navigation
- Radio-specific checklist items appear automatically for downloaded radios
- Deep linking support for checklists (`cwfieldguide://checklist/{phase}`)
```

**Step 2: Update FILE_INDEX.md**

Add to Models section:
```
| `Checklist.swift` | Checklist and ChecklistItem models, ChecklistPhase enum |
```

Add to Services section:
```
| `ChecklistImporter.swift` | Imports checklist templates from bundled JSON into SwiftData |
```

Add to Views - Tabs section:
```
| `ChecklistsTab.swift` | Checklist phase list with progress indicators |
```

Add to Views - Detail section:
```
| `ChecklistDetailView.swift` | Checklist items grouped by category with check toggling |
```

Add to Content section:
```
| `FieldGuide/FieldGuide/checklists.json` | Bundled checklist template definitions |
```

**Step 3: Bump version**

Increment `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.pbxproj`.

**Step 4: Commit**

```
chore: update changelog, file index, and version for checklists feature
```

---

## Summary

| Phase | Tasks | New Files |
|-------|-------|-----------|
| 1. Data Model | 1 | `Models/Checklist.swift` |
| 2. Content | 2-3 | `checklists.json`, `Services/ChecklistImporter.swift` |
| 3. Tab | 4-5 | `Views/ChecklistsTab.swift`, edit `ContentView.swift` |
| 4. Detail View | 6 | `Views/ChecklistDetailView.swift` |
| 5. Deep Linking | 7 | Edit `AppState.swift`, `FieldGuideApp.swift` |
| 6. Radio-Specific | 8 | Edit `checklists.json`, `ChecklistImporter.swift` |
| 7. Polish | 9-10 | Edit existing files, `CHANGELOG.md`, `FILE_INDEX.md` |

**New SwiftData models:** 2 (`Checklist`, `ChecklistItem`)
**New views:** 2 (`ChecklistsTab`, `ChecklistDetailView`)
**New services:** 1 (`ChecklistImporter`)
**New content files:** 1 (`checklists.json`)
**Edited existing files:** 4 (`FieldGuideApp.swift`, `ContentView.swift`, `AppState.swift`, `project.pbxproj`)

### What's Deferred to Post-V1

- Custom user-added checklist items
- Outing history / logging (dates, locations, QSO counts)
- Sharing or exporting checklists
- Printable checklist format
- Tab badge showing incomplete item count
- Weather / propagation integration
- Ordering enforcement between phases (all freeform in V1)
