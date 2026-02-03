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

    @MainActor
    private func loadBundledContentIfNeeded() async {
        let context = sharedModelContainer.mainContext
        let descriptor = FetchDescriptor<Radio>()

        do {
            let radios = try context.fetch(descriptor)
            if radios.isEmpty {
                // Load bundled content on first launch
                let importer = ContentImporter(modelContainer: sharedModelContainer)
                try await importer.importBundledContent(filename: "elecraft-kx2")
            }
        } catch {
            print("Error loading content: \(error)")
        }
    }
}
