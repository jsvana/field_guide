//
//  SettingsTab.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct SettingsTab: View {
    @Query private var radios: [Radio]
    @State private var showingBugReport = false

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
                    .disabled(true)
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

                    Link(destination: URL(string: "https://discord.gg/PqubUxWW62")!) {
                        Label("Join Discord", systemImage: "bubble.left.and.bubble.right")
                    }

                    Link(destination: URL(string: "https://discord.gg/ksNb2jAeTR")!) {
                        Label("Request a Feature", systemImage: "lightbulb")
                    }

                    Button {
                        showingBugReport = true
                    } label: {
                        Label("Report a Bug", systemImage: "ant")
                    }

                    NavigationLink {
                        AttributionsView()
                    } label: {
                        Label("Attributions", systemImage: "heart")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingBugReport) {
                BugReportView()
            }
        }
    }
}

// MARK: - AttributionsView

struct AttributionsView: View {
    var body: some View {
        List {
            SwiftUI.Section {
                Text(
                    """
                    Field Guide includes content adapted from official manuals \
                    with permission or fair use for educational purposes.
                    """
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            SwiftUI.Section("Manufacturers") {
                manufacturerRow(
                    name: "Elecraft",
                    description: "High-performance amateur radio transceivers",
                    url: "https://elecraft.com"
                )

                manufacturerRow(
                    name: "PennTek",
                    description: "Compact QRP transceivers for portable operation",
                    url: "https://penntek.com"
                )

                manufacturerRow(
                    name: "LNR Precision",
                    description: "Mountain Topper series QRP radios",
                    url: "https://lnrprecision.com"
                )

                manufacturerRow(
                    name: "HamGadgets",
                    description: "Amateur radio accessories and kits",
                    url: "https://hamgadgets.com"
                )

                manufacturerRow(
                    name: "Yaesu",
                    description: "Amateur radio equipment manufacturer",
                    url: "https://www.yaesu.com"
                )
            }

            SwiftUI.Section("Frameworks") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Built with Apple Technologies")
                        .font(.headline)

                    Text(
                        """
                        Field Guide is built entirely with Apple's native frameworks, \
                        including SwiftUI, SwiftData, and PDFKit.
                        """
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            SwiftUI.Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Made with care for the amateur radio community.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("73 de the Carrier Wave team")
                        .font(.subheadline)
                        .italic()
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Attributions")
    }

    private func manufacturerRow(name: String, description: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
    }
}

#Preview("Attributions") {
    NavigationStack {
        AttributionsView()
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
