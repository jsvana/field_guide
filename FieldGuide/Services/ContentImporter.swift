//
//  ContentImporter.swift
//  FieldGuide
//

import Foundation
import SwiftData

/// Imports content from JSON into SwiftData
actor ContentImporter {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    /// Import content from a JSON file bundled in the app (for testing)
    func importBundledContent(filename: String) async throws {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "json") else {
            throw ContentImportError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)
        try await importContent(from: data)
    }

    /// Import content from JSON data
    @MainActor
    func importContent(from data: Data) async throws {
        let decoder = JSONDecoder()
        let content = try decoder.decode(ContentJSON.self, from: data)

        let context = modelContainer.mainContext

        let radio = try findOrCreateRadio(from: content.radio, context: context)

        // Import sections
        for (sectionIndex, sectionJSON) in content.sections.enumerated() {
            let sectionId = "\(content.radio.id)-\(sectionJSON.id)"
            let section = Section(
                id: sectionId,
                title: sectionJSON.title,
                sortOrder: sectionJSON.sortOrder ?? sectionIndex
            )
            section.radio = radio
            section.searchableText = importBlocks(
                from: sectionJSON, sectionId: sectionId, into: section, context: context
            )
            context.insert(section)
        }

        radio.isDownloaded = true
        radio.downloadedAt = Date()

        try context.save()
    }

    @MainActor
    private func findOrCreateRadio(from radioJSON: RadioJSON, context: ModelContext) throws -> Radio {
        let radioId = radioJSON.id
        let descriptor = FetchDescriptor<Radio>(
            predicate: #Predicate { $0.id == radioId }
        )
        let existingRadios = try context.fetch(descriptor)

        if let existing = existingRadios.first {
            existing.manufacturer = radioJSON.manufacturer
            existing.model = radioJSON.model
            existing.manualRevision = radioJSON.revision
            existing.pdfFilename = radioJSON.pdfFilename
            for section in existing.sections {
                context.delete(section)
            }
            return existing
        }

        let radio = Radio(
            id: radioJSON.id,
            manufacturer: radioJSON.manufacturer,
            model: radioJSON.model,
            manualRevision: radioJSON.revision,
            pdfFilename: radioJSON.pdfFilename
        )
        context.insert(radio)
        return radio
    }

    @MainActor
    @discardableResult
    private func importBlocks(
        from sectionJSON: SectionJSON,
        sectionId: String,
        into section: Section,
        context: ModelContext
    ) -> String {
        var searchableText = sectionJSON.title + " "

        for (index, blockJSON) in sectionJSON.blocks.enumerated() {
            let block = ContentBlock(
                id: "\(sectionId)-block-\(index)",
                sortOrder: index,
                blockType: blockJSON.type
            )
            populateBlock(block, from: blockJSON, searchableText: &searchableText)
            block.section = section
            context.insert(block)
        }

        return searchableText
    }

    @MainActor
    private func populateBlock(_ block: ContentBlock, from blockJSON: BlockJSON, searchableText: inout String) {
        switch blockJSON.type {
        case .paragraph, .note, .warning:
            block.text = blockJSON.text
            searchableText += (blockJSON.text ?? "") + " "
        case .menuEntry:
            block.menuName = blockJSON.name
            block.menuDescription = blockJSON.description
            searchableText += (blockJSON.name ?? "") + " " + (blockJSON.description ?? "") + " "
        case .specification:
            block.specLabel = blockJSON.name
            block.specValue = blockJSON.value
            searchableText += (blockJSON.name ?? "") + " " + (blockJSON.value ?? "") + " "
        case .specificationTable:
            block.tableHeaders = blockJSON.headers
            block.tableRows = blockJSON.rows?.map { $0.cells }
            searchableText += (blockJSON.rows?.flatMap { $0.cells }.joined(separator: " ") ?? "") + " "
        }
    }
}

enum ContentImportError: LocalizedError {
    case fileNotFound(String)

    var errorDescription: String? {
        switch self {
        case let .fileNotFound(name):
            return "Content file not found: \(name)"
        }
    }
}

// MARK: - JSON Models

struct ContentJSON: Codable, Sendable {
    let radio: RadioJSON
    let sections: [SectionJSON]
}

struct RadioJSON: Codable, Sendable {
    let id: String
    let manufacturer: String
    let model: String
    let revision: String
    let pdfFilename: String
}

struct SectionJSON: Codable, Sendable {
    let id: String
    let title: String
    let sortOrder: Int?
    let blocks: [BlockJSON]
}

struct BlockJSON: Codable, Sendable {
    let type: ContentBlockType

    /// Paragraph, note, warning
    let text: String?

    // Menu entry
    let name: String?
    let description: String?

    // Specification
    let label: String?
    let value: String?

    // Table
    let headers: [String]?
    let rows: [TableRow]?
}

/// Represents a table row that can be decoded from either:
/// - Array format: `["Name", "Value"]`
/// - Object format: `{"name": "Name", "value": "Value"}`
struct TableRow: Codable, Sendable {
    let cells: [String]

    init(from decoder: Decoder) throws {
        // Try array format first
        if let container = try? decoder.singleValueContainer(),
           let array = try? container.decode([String].self)
        {
            cells = array
        }
        // Try object format
        else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let name = try container.decode(String.self, forKey: .name)
            let value = try container.decode(String.self, forKey: .value)
            cells = [name, value]
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(cells)
    }

    private enum CodingKeys: String, CodingKey {
        case name
        case value
    }
}
