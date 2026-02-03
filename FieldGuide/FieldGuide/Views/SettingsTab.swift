//
//  SettingsTab.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct SettingsTab: View {
    @Query private var radios: [Radio]

    private var downloadedRadios: [Radio] {
        radios.filter { $0.isDownloaded }
    }

    private var totalSize: String {
        // Placeholder - would calculate actual size
        let count = downloadedRadios.count
        return "\(count) radio\(count == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationStack {
            List {
                SwiftUI.Section("Updates") {
                    Button {
                        // TODO: Implement update check
                    } label: {
                        Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                SwiftUI.Section("Storage") {
                    NavigationLink {
                        ManageDownloadsView()
                    } label: {
                        VStack(alignment: .leading) {
                            Text("Manage Downloads")
                            Text(totalSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SwiftUI.Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("App", value: "Carrier Wave Field Guide")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct ManageDownloadsView: View {
    @Query(filter: #Predicate<Radio> { $0.isDownloaded }, sort: \Radio.model)
    private var radios: [Radio]

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(radios) { radio in
                HStack {
                    VStack(alignment: .leading) {
                        Text(radio.model)
                            .font(.headline)
                        Text(radio.manufacturer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(radio.manualRevision)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete(perform: deleteRadios)
        }
        .navigationTitle("Manage Downloads")
        .toolbar {
            EditButton()
        }
    }

    private func deleteRadios(at offsets: IndexSet) {
        for index in offsets {
            let radio = radios[index]
            // TODO: Also delete PDF file
            modelContext.delete(radio)
        }
    }
}

#Preview {
    SettingsTab()
        .modelContainer(for: Radio.self, inMemory: true)
}
