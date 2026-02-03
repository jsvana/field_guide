//
//  ContentBlock.swift
//  FieldGuide
//

import Foundation
import SwiftData

enum ContentBlockType: String, Codable, Sendable {
    case paragraph
    case menuEntry
    case specification
    case specificationTable
    case note
    case warning
}

@Model
final class ContentBlock {
    @Attribute(.unique) var id: String
    var sortOrder: Int
    var blockType: ContentBlockType

    // Content fields (use appropriate ones based on blockType)
    var text: String?
    var menuName: String?
    var menuDescription: String?
    var specLabel: String?
    var specValue: String?
    var tableHeaders: [String]?
    var tableRows: [[String]]?

    var section: Section?

    init(id: String, sortOrder: Int, blockType: ContentBlockType) {
        self.id = id
        self.sortOrder = sortOrder
        self.blockType = blockType
    }
}
