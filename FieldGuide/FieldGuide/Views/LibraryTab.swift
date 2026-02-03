//
//  LibraryTab.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct LibraryTab: View {
    @Query(sort: \Radio.model) private var radios: [Radio]

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    private var downloadedRadios: [Radio] {
        radios.filter { $0.isDownloaded }
    }

    private var favoriteRadios: [Radio] {
        downloadedRadios.filter { $0.isFavorite }
    }

    private var otherRadios: [Radio] {
        downloadedRadios.filter { !$0.isFavorite }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if radios.isEmpty {
                    emptyState
                } else {
                    radioSections
                }
            }
            .navigationTitle("Library")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Loading manuals...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ProgressView()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private var radioSections: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !favoriteRadios.isEmpty {
                radioSection(title: "My Radios", radios: favoriteRadios)
            }

            if !otherRadios.isEmpty {
                radioSection(
                    title: favoriteRadios.isEmpty ? nil : "All Radios",
                    radios: otherRadios
                )
            }
        }
        .padding()
        .navigationDestination(for: Radio.self) { radio in
            RadioDetailView(radio: radio)
        }
    }

    private func radioSection(title: String?, radios: [Radio]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.title2.weight(.semibold))
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(radios) { radio in
                    NavigationLink(value: radio) {
                        RadioCard(radio: radio)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct RadioCard: View {
    @Bindable var radio: Radio

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "radio")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(height: 60)

            Text(radio.model)
                .font(.headline)

            Text(radio.manufacturer)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .topTrailing) {
            Button {
                radio.isFavorite.toggle()
            } label: {
                Image(systemName: radio.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 18))
                    .foregroundStyle(radio.isFavorite ? .yellow : .secondary)
                    .padding(8)
            }
        }
    }
}

#Preview {
    LibraryTab()
        .modelContainer(for: Radio.self, inMemory: true)
}
