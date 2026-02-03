//
//  RadioDetailView.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct RadioDetailView: View {
    let radio: Radio
    @State private var showPDF = false

    private var sortedSections: [Section] {
        radio.sections.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            ForEach(sortedSections) { section in
                NavigationLink(value: section) {
                    SectionRow(section: section)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(radio.manufacturer)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(radio.model)
                        .font(.headline)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showPDF = true
                } label: {
                    Label("PDF", systemImage: "doc.text")
                }
            }
        }
        .fullScreenCover(isPresented: $showPDF) {
            PDFViewerSheet(radio: radio)
        }
        .navigationDestination(for: Section.self) { section in
            SectionDetailView(section: section)
        }
    }
}

struct SectionRow: View {
    let section: Section

    private var iconName: String {
        switch section.title {
        case "Operation Basics": return "dial.medium"
        case "Menu System Reference": return "list.bullet.rectangle"
        case "CW/Keyer Settings": return "waveform"
        case "Filters & DSP": return "slider.horizontal.3"
        case "Power & Battery": return "battery.100"
        case "ATU Operation": return "antenna.radiowaves.left.and.right"
        case "Specifications": return "doc.text"
        case "Quick Troubleshooting": return "wrench.and.screwdriver"
        default: return "book"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 32)

            Text(section.title)
                .font(.subheadline)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RadioDetailView(radio: Radio(
            id: "test",
            manufacturer: "Elecraft",
            model: "KX2",
            manualRevision: "B2",
            pdfFilename: "test.pdf"
        ))
    }
    .modelContainer(for: Radio.self, inMemory: true)
}
