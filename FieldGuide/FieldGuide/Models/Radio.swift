//
//  Radio.swift
//  FieldGuide
//

import Foundation
import SwiftData

@Model
final class Radio {
    @Attribute(.unique) var id: String
    var manufacturer: String
    var model: String
    var manualRevision: String
    var pdfFilename: String
    var pdfLocalPath: String?
    var isDownloaded: Bool
    var downloadedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \Section.radio)
    var sections: [Section] = []

    init(
        id: String,
        manufacturer: String,
        model: String,
        manualRevision: String,
        pdfFilename: String
    ) {
        self.id = id
        self.manufacturer = manufacturer
        self.model = model
        self.manualRevision = manualRevision
        self.pdfFilename = pdfFilename
        self.isDownloaded = false
    }
}
