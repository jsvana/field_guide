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
        // BG2FX
        "bg2fx-fx4cr",
        // Elecraft
        "elecraft-k1",
        "elecraft-k2",
        "elecraft-kh1",
        "elecraft-kx1",
        "elecraft-kx2",
        "elecraft-kx3",
        // HamGadgets
        "hamgadgets-cft1",
        // ICOM
        "icom-ic705",
        "icom-ic7100",
        "icom-ic7300",
        "icom-ic7300mk2",
        // LNR Precision
        "lnr-ld5",
        "lnr-mtr3b-v4",
        "lnr-mtr4b-v2",
        "lnr-mtr5b",
        // PennTek
        "penntek-tr25",
        "penntek-tr35",
        "penntek-tr45l",
        // Venus
        "venus-sw3b",
        "venus-sw6b",
        // Xiegu
        "xiegu-g1m",
        "xiegu-g90",
        "xiegu-g106",
        "xiegu-x5105",
        "xiegu-x6100",
        "xiegu-x6200",
        // Yaesu
        "yaesu-ft710",
        "yaesu-ft891",
        "yaesu-ft991a",
        "yaesu-ftdx101mp",
        "yaesu-ftx1",
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
