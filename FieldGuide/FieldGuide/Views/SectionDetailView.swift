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

// MARK: - Text Highlighting with Flow Layout

/// A text token - either plain text or a highlighted keyword
private enum TextToken: Identifiable, Equatable {
    case plain(String)
    case keyword(String)
    case space

    var id: String {
        switch self {
        case .plain(let s): return "p:\(s)"
        case .keyword(let s): return "k:\(s)"
        case .space: return "s:\(UUID().uuidString)"
        }
    }
}

/// Tokenizes text into plain words, keywords, and spaces
private func tokenizeText(_ text: String) -> [TextToken] {
    let pattern = #"\b[A-Z][A-Z0-9/\-]+(?:\s+[A-Z]\b)?"#

    guard let regex = try? NSRegularExpression(pattern: pattern) else {
        return tokenizePlainText(text)
    }

    let nsRange = NSRange(text.startIndex..., in: text)
    let matches = regex.matches(in: text, range: nsRange)

    if matches.isEmpty {
        return tokenizePlainText(text)
    }

    var tokens: [TextToken] = []
    var currentIndex = text.startIndex

    for match in matches {
        guard let range = Range(match.range, in: text) else { continue }

        // Tokenize plain text before the match
        if currentIndex < range.lowerBound {
            let plainText = String(text[currentIndex..<range.lowerBound])
            tokens.append(contentsOf: tokenizePlainText(plainText))
        }

        // Add the keyword
        tokens.append(.keyword(String(text[range])))
        currentIndex = range.upperBound
    }

    // Tokenize remaining text
    if currentIndex < text.endIndex {
        let remaining = String(text[currentIndex...])
        tokens.append(contentsOf: tokenizePlainText(remaining))
    }

    return tokens
}

/// Splits plain text into word and space tokens
private func tokenizePlainText(_ text: String) -> [TextToken] {
    var tokens: [TextToken] = []
    var currentWord = ""

    for char in text {
        if char == " " {
            if !currentWord.isEmpty {
                tokens.append(.plain(currentWord))
                currentWord = ""
            }
            tokens.append(.space)
        } else {
            currentWord.append(char)
        }
    }

    if !currentWord.isEmpty {
        tokens.append(.plain(currentWord))
    }

    return tokens
}

/// Flow layout that wraps content horizontally
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)

        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> LayoutResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            sizes.append(size)

            if currentX + size.width > maxWidth && currentX > 0 {
                // Wrap to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width
            lineHeight = max(lineHeight, size.height)
        }

        let totalHeight = currentY + lineHeight
        let totalWidth = maxWidth.isFinite ? maxWidth : currentX

        return LayoutResult(
            size: CGSize(width: totalWidth, height: totalHeight),
            positions: positions,
            sizes: sizes
        )
    }

    private struct LayoutResult {
        let size: CGSize
        let positions: [CGPoint]
        let sizes: [CGSize]
    }
}

/// View that displays text with highlighted keywords as rounded pills
struct HighlightedText: View {
    let text: String
    let baseFont: Font

    init(_ text: String, baseFont: Font = .body) {
        self.text = text
        self.baseFont = baseFont
    }

    private var tokens: [TextToken] {
        tokenizeText(text)
    }

    var body: some View {
        FlowLayout(spacing: 0) {
            ForEach(Array(tokens.enumerated()), id: \.offset) { _, token in
                tokenView(token)
            }
        }
    }

    @ViewBuilder
    private func tokenView(_ token: TextToken) -> some View {
        switch token {
        case .plain(let word):
            Text(word)
                .font(baseFont)

        case .keyword(let word):
            Text(word)
                .font(.system(baseFont == .subheadline ? .subheadline : .body, design: .monospaced))
                .foregroundStyle(.blue)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4))

        case .space:
            Text(" ")
                .font(baseFont)
        }
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
