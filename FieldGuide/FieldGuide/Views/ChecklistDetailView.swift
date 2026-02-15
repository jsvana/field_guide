//
//  ChecklistDetailView.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct ChecklistDetailView: View {
    @Bindable var checklist: Checklist
    let downloadedRadioIds: Set<String>

    @State private var showResetConfirmation = false

    private var visibleItems: [ChecklistItem] {
        checklist.items
            .filter { item in
                guard let radioId = item.radioId else { return true }
                return downloadedRadioIds.contains(radioId)
            }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var groupedItems: [(category: String, items: [ChecklistItem])] {
        var groups: [(category: String, items: [ChecklistItem])] = []
        var seen: Set<String> = []

        for item in visibleItems where !seen.contains(item.category) {
            seen.insert(item.category)
            groups.append((
                category: item.category,
                items: visibleItems.filter { $0.category == item.category }
            ))
        }
        return groups
    }

    private var isComplete: Bool {
        let visible = visibleItems
        return !visible.isEmpty && visible.allSatisfy(\.isChecked)
    }

    var body: some View {
        List {
            if isComplete {
                completionBanner
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            ForEach(groupedItems, id: \.category) { group in
                SwiftUI.Section {
                    ForEach(group.items) { item in
                        ChecklistItemRow(item: item)
                    }
                } header: {
                    Text(group.category)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle(checklist.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Reset") {
                    showResetConfirmation = true
                }
            }
        }
        .confirmationDialog(
            "Reset \(checklist.title)",
            isPresented: $showResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                resetChecklist()
            }
        } message: {
            Text("This will uncheck all items in this checklist.")
        }
    }

    private var completionBanner: some View {
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
    }

    private func resetChecklist() {
        for item in checklist.items {
            item.isChecked = false
        }
    }
}

struct ChecklistItemRow: View {
    @Bindable var item: ChecklistItem

    var body: some View {
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
    }
}

#Preview {
    NavigationStack {
        ChecklistDetailView(
            checklist: Checklist(id: "test", title: "Pre-Outing", phase: .preOuting, sortOrder: 1),
            downloadedRadioIds: []
        )
    }
    .modelContainer(for: [Checklist.self, ChecklistItem.self], inMemory: true)
}
