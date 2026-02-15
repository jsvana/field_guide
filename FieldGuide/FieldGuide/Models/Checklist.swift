//
//  Checklist.swift
//  FieldGuide
//

import Foundation
import SwiftData

enum ChecklistPhase: String, Codable, CaseIterable, Sendable {
    case preOuting
    case duringOuting
    case debugging
    case cleanup
    case postOuting

    var title: String {
        switch self {
        case .preOuting: "Pre-Outing"
        case .duringOuting: "During Outing"
        case .debugging: "Debugging"
        case .cleanup: "Cleanup"
        case .postOuting: "Post-Outing"
        }
    }

    var icon: String {
        switch self {
        case .preOuting: "bag.fill"
        case .duringOuting: "antenna.radiowaves.left.and.right"
        case .debugging: "wrench.and.screwdriver"
        case .cleanup: "arrow.uturn.down.circle"
        case .postOuting: "house.fill"
        }
    }

    var pathComponent: String {
        switch self {
        case .preOuting: "pre-outing"
        case .duringOuting: "during-outing"
        case .debugging: "debugging"
        case .cleanup: "cleanup"
        case .postOuting: "post-outing"
        }
    }

    init?(pathComponent: String) {
        switch pathComponent {
        case "pre-outing": self = .preOuting
        case "during-outing": self = .duringOuting
        case "debugging": self = .debugging
        case "cleanup": self = .cleanup
        case "post-outing": self = .postOuting
        default: return nil
        }
    }
}

@Model
final class Checklist {
    @Attribute(.unique) var id: String
    var title: String
    var phase: ChecklistPhase
    var sortOrder: Int

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.checklist)
    var items: [ChecklistItem] = []

    init(id: String, title: String, phase: ChecklistPhase, sortOrder: Int) {
        self.id = id
        self.title = title
        self.phase = phase
        self.sortOrder = sortOrder
    }
}

@Model
final class ChecklistItem {
    @Attribute(.unique) var id: String
    var text: String
    var isChecked: Bool
    var sortOrder: Int
    var category: String
    var radioId: String?

    var checklist: Checklist?

    init(
        id: String,
        text: String,
        sortOrder: Int,
        category: String,
        radioId: String? = nil
    ) {
        self.id = id
        self.text = text
        self.isChecked = false
        self.sortOrder = sortOrder
        self.category = category
        self.radioId = radioId
    }
}
