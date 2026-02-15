//
//  ChecklistsTab.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct ChecklistsTab: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Checklist.sortOrder) private var checklists: [Checklist]
    @Query private var radios: [Radio]

    @State private var path = NavigationPath()
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(checklists) { checklist in
                    NavigationLink(value: checklist) {
                        ChecklistRow(checklist: checklist, downloadedRadioIds: downloadedRadioIds)
                    }
                }

                SwiftUI.Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Reset All Checklists")
                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Checklists")
            .navigationDestination(for: Checklist.self) { checklist in
                ChecklistDetailView(checklist: checklist, downloadedRadioIds: downloadedRadioIds)
            }
            .confirmationDialog(
                "Reset All Checklists",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset", role: .destructive) {
                    resetAllChecklists()
                }
            } message: {
                Text("This will uncheck all items across all checklists.")
            }
        }
        .onChange(of: appState.pendingChecklistPhase) { _, phase in
            guard let phase else { return }
            if let checklist = checklists.first(where: { $0.phase.pathComponent == phase }) {
                path = NavigationPath()
                path.append(checklist)
            }
            appState.pendingChecklistPhase = nil
        }
    }

    private var downloadedRadioIds: Set<String> {
        Set(radios.filter(\.isDownloaded).map(\.id))
    }

    private func resetAllChecklists() {
        for checklist in checklists {
            for item in checklist.items {
                item.isChecked = false
            }
        }
    }
}

struct ChecklistRow: View {
    let checklist: Checklist
    let downloadedRadioIds: Set<String>

    private var visibleItems: [ChecklistItem] {
        checklist.items.filter { item in
            guard let radioId = item.radioId else { return true }
            return downloadedRadioIds.contains(radioId)
        }
    }

    private var checkedCount: Int {
        visibleItems.filter(\.isChecked).count
    }

    private var totalCount: Int {
        visibleItems.count
    }

    private var isComplete: Bool {
        totalCount > 0 && checkedCount == totalCount
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: checklist.phase.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            Text(checklist.title)
                .font(.subheadline)

            Spacer()

            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("\(checkedCount)/\(totalCount)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChecklistsTab()
        .environment(AppState())
        .modelContainer(for: [Checklist.self, ChecklistItem.self, Radio.self], inMemory: true)
}
