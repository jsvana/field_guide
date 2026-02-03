//
//  SearchTab.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct SearchTab: View {
    @Query private var radios: [Radio]
    @Query private var sections: [Section]
    @State private var searchText = ""
    @State private var selectedRadioId: String?
    @State private var favoritesOnly = false

    private var downloadedRadios: [Radio] {
        radios.filter { $0.isDownloaded }
    }

    private var favoriteRadios: [Radio] {
        downloadedRadios.filter { $0.isFavorite }
    }

    private var hasFavorites: Bool {
        !favoriteRadios.isEmpty
    }

    private var scopeRadios: [Radio] {
        favoritesOnly ? favoriteRadios : downloadedRadios
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scope picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if hasFavorites {
                            filterChip(
                                "My Radios",
                                systemImage: "star.fill",
                                isSelected: favoritesOnly
                            ) {
                                favoritesOnly.toggle()
                                if favoritesOnly && selectedRadioId != nil {
                                    // Reset selection if current radio is not a favorite
                                    if !favoriteRadios.contains(where: { $0.id == selectedRadioId }) {
                                        selectedRadioId = nil
                                    }
                                }
                            }

                            Divider()
                                .frame(height: 20)
                        }

                        scopeChip("All", isSelected: selectedRadioId == nil) {
                            selectedRadioId = nil
                        }
                        ForEach(scopeRadios) { radio in
                            scopeChip(radio.model, isSelected: selectedRadioId == radio.id) {
                                selectedRadioId = radio.id
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }

                Divider()

                // Results
                if searchText.count < 2 {
                    ContentUnavailableView(
                        "Search Manuals",
                        systemImage: "magnifyingglass",
                        description: Text("Enter at least 2 characters to search")
                    )
                } else if filteredSections.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                } else {
                    List(filteredSections) { section in
                        NavigationLink(value: section) {
                            SearchResultRow(section: section, searchText: searchText)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search manuals...")
            .navigationDestination(for: Section.self) { section in
                SectionDetailView(section: section)
            }
        }
    }

    private var filteredSections: [Section] {
        guard searchText.count >= 2 else { return [] }
        let query = searchText.lowercased()

        return sections.filter { section in
            guard let radio = section.radio, radio.isDownloaded else { return false }

            // Filter by favorites if enabled
            if favoritesOnly && !radio.isFavorite {
                return false
            }

            // Filter by specific radio if selected
            if let radioId = selectedRadioId, radio.id != radioId {
                return false
            }

            return section.title.lowercased().contains(query) ||
                section.searchableText.lowercased().contains(query)
        }
    }

    private func filterChip(
        _ title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption)
                Text(title)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.yellow : Color(.systemGray5))
            .foregroundStyle(isSelected ? .black : .primary)
            .clipShape(Capsule())
        }
    }

    private func scopeChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

struct SearchResultRow: View {
    let section: Section
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let radio = section.radio {
                    Text(radio.model)
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Capsule())
                }
                Text(section.title)
                    .font(.subheadline.weight(.semibold))
            }

            if let preview = findMatchPreview() {
                Text(preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func findMatchPreview() -> String? {
        let text = section.searchableText
        guard let range = text.range(of: searchText, options: .caseInsensitive) else {
            return nil
        }

        let start = text.index(range.lowerBound, offsetBy: -30, limitedBy: text.startIndex) ?? text.startIndex
        let end = text.index(range.upperBound, offsetBy: 50, limitedBy: text.endIndex) ?? text.endIndex

        var preview = String(text[start ..< end])
        if start != text.startIndex { preview = "..." + preview }
        if end != text.endIndex { preview = preview + "..." }

        return preview
    }
}

#Preview {
    SearchTab()
        .modelContainer(for: [Radio.self, Section.self], inMemory: true)
}
