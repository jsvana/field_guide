//
//  Section.swift
//  FieldGuide
//

import Foundation
import SwiftData

@Model
final class Section {
    @Attribute(.unique) var id: String
    var title: String
    var sortOrder: Int
    var searchableText: String

    var radio: Radio?

    @Relationship(deleteRule: .cascade, inverse: \ContentBlock.section)
    var blocks: [ContentBlock] = []

    init(id: String, title: String, sortOrder: Int, searchableText: String = "") {
        self.id = id
        self.title = title
        self.sortOrder = sortOrder
        self.searchableText = searchableText
    }
}
