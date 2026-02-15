//
//  ChecklistImporter.swift
//  FieldGuide
//

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

            // Only import if no checklist exists for this phase.
            // This preserves user check state across app updates.
            let checklistId = checklistJSON.id
            let existing = try context.fetch(FetchDescriptor<Checklist>(
                predicate: #Predicate { $0.id == checklistId }
            ))
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
                        category: categoryJSON.category,
                        radioId: categoryJSON.radioId
                    )
                    item.checklist = checklist
                    context.insert(item)
                    itemIndex += 1
                }
            }
        }

        try context.save()
    }

    /// Delete all checklists and reimport from the bundled template.
    @MainActor
    func resetAllChecklists() throws {
        let context = modelContainer.mainContext
        let allChecklists = try context.fetch(FetchDescriptor<Checklist>())
        for checklist in allChecklists {
            context.delete(checklist)
        }
        try context.save()
        try importBundledChecklists()
    }
}

// MARK: - JSON Models

struct ChecklistsJSON: Codable, Sendable {
    let checklists: [ChecklistJSON]
}

struct ChecklistJSON: Codable, Sendable {
    let id: String
    let title: String
    let phase: String
    let sortOrder: Int
    let items: [ChecklistCategoryJSON]
}

struct ChecklistCategoryJSON: Codable, Sendable {
    let category: String
    let radioId: String?
    let entries: [String]

    enum CodingKeys: String, CodingKey {
        case category
        case radioId
        case entries
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        radioId = try container.decodeIfPresent(String.self, forKey: .radioId)
        entries = try container.decode([String].self, forKey: .entries)
    }
}
