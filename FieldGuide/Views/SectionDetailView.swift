//
//  SectionDetailView.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct SectionDetailView: View {
    let section: Section

    private var sortedBlocks: [ContentBlock] {
        section.blocks.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Radio context at top
                if let radio = section.radio {
                    Text("\(radio.manufacturer) \(radio.model)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Custom header that wraps instead of truncating
                Text(section.title)
                    .font(.largeTitle.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                ForEach(sortedBlocks) { block in
                    ContentBlockView(block: block)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContentBlockView: View {
    let block: ContentBlock

    var body: some View {
        switch block.blockType {
        case .paragraph:
            ParagraphBlock(text: block.text ?? "")

        case .menuEntry:
            MenuEntryBlock(name: block.menuName ?? "", description: block.menuDescription ?? "")

        case .specification:
            SpecificationBlock(label: block.specLabel ?? "", value: block.specValue ?? "")

        case .specificationTable:
            SpecificationTableBlock(headers: block.tableHeaders ?? [], rows: block.tableRows ?? [])

        case .note:
            NoteBlock(text: block.text ?? "", style: .info)

        case .warning:
            NoteBlock(text: block.text ?? "", style: .warning)
        }
    }
}

struct ParagraphBlock: View {
    let text: String

    var body: some View {
        HighlightedText(text, baseFont: .body)
    }
}

struct MenuEntryBlock: View {
    let name: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.subheadline.weight(.semibold).monospaced())
            HighlightedText(description, baseFont: .body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SpecificationBlock: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}

struct SpecificationTableBlock: View {
    let headers: [String]
    let rows: [[String]]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !headers.isEmpty {
                HStack {
                    ForEach(headers, id: \.self) { header in
                        Text(header)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
            }

            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    ForEach(Array(row.enumerated()), id: \.offset) { index, cell in
                        Text(cell)
                            .font(index == 0 ? .subheadline : .subheadline.monospaced())
                            .foregroundStyle(index == 0 ? .primary : .secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
        }
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

enum NoteStyle {
    case info, warning

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        }
    }
}

struct NoteBlock: View {
    let text: String
    let style: NoteStyle

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: style.icon)
                .foregroundStyle(style.color)
            HighlightedText(text, baseFont: .subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(style.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(section: Section(
            id: "test",
            title: "Menu System Reference",
            sortOrder: 1
        ))
    }
    .modelContainer(for: Section.self, inMemory: true)
}
