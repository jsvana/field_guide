//
//  FieldGuideApp.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

@main
struct FieldGuideApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Radio.self,
            Section.self,
            ContentBlock.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await loadBundledContentIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private static let bundledRadios = [
        // Elecraft
        "elecraft-k1",
        "elecraft-k2",
        "elecraft-kh1",
        "elecraft-kx1",
        "elecraft-kx2",
        "elecraft-kx3",
        // HamGadgets
        "hamgadgets-cft1",
        // LNR Precision
        "lnr-ld5",
        "lnr-mtr3b-v4",
        "lnr-mtr4b-v2",
        "lnr-mtr5b",
        // PennTek
        "penntek-tr35",
        "penntek-tr45l",
        // Yaesu
        "yaesu-ft891",
    ]

    @MainActor
    private func loadBundledContentIfNeeded() async {
        // Always import/refresh all bundled radios to ensure content is up to date
        let importer = ContentImporter(modelContainer: sharedModelContainer)
        for radioId in Self.bundledRadios {
            do {
                try await importer.importBundledContent(filename: radioId)
            } catch {
                print("Error loading \(radioId): \(error)")
            }
        }
    }
}
