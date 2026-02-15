//
//  HighlightedText.swift
//  FieldGuide
//

import SwiftUI

// MARK: - Text Highlighting with Flow Layout

/// A text token - either plain text or a highlighted keyword
private enum TextToken: Identifiable, Equatable {
    case plain(String)
    case keyword(String)
    case space

    var id: String {
        switch self {
        case let .plain(str): return "p:\(str)"
        case let .keyword(str): return "k:\(str)"
        case .space: return "s:\(UUID().uuidString)"
        }
    }
}

/// Common standalone acronyms that shouldn't be highlighted as control names
/// (these are still highlighted when part of compound terms like "IF SHIFT")
private let excludedStandaloneTerms: Set<String> = [
    "DSP", "RF", "AF", "DC", "AC", "FM", "AM", "CW", "USB", "LSB",
    "SSB", "LED", "LCD", "BNC", "SMA", "RCA", "MHz", "KHz", "Hz", "mA",
    "dB", "mW",
]

/// Tokenizes text into plain words, keywords, and spaces
private func tokenizeText(_ text: String) -> [TextToken] {
    let pattern = #"\b[A-Z][A-Z0-9/\-]+\b"#

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
            let plainText = String(text[currentIndex ..< range.lowerBound])
            tokens.append(contentsOf: tokenizePlainText(plainText))
        }

        // Add as keyword (exclusion check happens after merging)
        tokens.append(.keyword(String(text[range])))
        currentIndex = range.upperBound
    }

    // Tokenize remaining text
    if currentIndex < text.endIndex {
        let remaining = String(text[currentIndex...])
        tokens.append(contentsOf: tokenizePlainText(remaining))
    }

    // First merge adjacent keywords, then exclude standalone terms
    let merged = mergeAdjacentKeywords(tokens)
    return applyExclusions(merged)
}

/// Merges consecutive keyword tokens (separated by single space) into one keyword
private func mergeAdjacentKeywords(_ tokens: [TextToken]) -> [TextToken] {
    var result: [TextToken] = []
    var idx = 0

    while idx < tokens.count {
        if case let .keyword(first) = tokens[idx] {
            // Look ahead for pattern: keyword, space, keyword
            var merged = first
            var nextIdx = idx + 1

            while nextIdx + 1 < tokens.count {
                if case .space = tokens[nextIdx], case let .keyword(next) = tokens[nextIdx + 1] {
                    merged += " " + next
                    nextIdx += 2
                } else {
                    break
                }
            }

            result.append(.keyword(merged))
            idx = nextIdx
        } else {
            result.append(tokens[idx])
            idx += 1
        }
    }

    return result
}

/// Converts excluded standalone keywords back to plain text
private func applyExclusions(_ tokens: [TextToken]) -> [TextToken] {
    tokens.map { token in
        if case let .keyword(word) = token, excludedStandaloneTerms.contains(word) {
            return .plain(word)
        }
        return token
    }
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

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout ()) {
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
        case let .plain(word):
            Text(word)
                .font(baseFont)

        case let .keyword(word):
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
