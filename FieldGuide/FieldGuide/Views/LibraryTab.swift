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

    var body: some View {
        NavigationStack {
            ScrollView {
                if radios.isEmpty {
                    emptyState
                } else {
                    radioGrid
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

    private var radioGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(radios.filter { $0.isDownloaded }) { radio in
                NavigationLink(value: radio) {
                    RadioCard(radio: radio)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .navigationDestination(for: Radio.self) { radio in
            RadioDetailView(radio: radio)
        }
    }
}

struct RadioCard: View {
    let radio: Radio

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
    }
}

#Preview {
    LibraryTab()
        .modelContainer(for: Radio.self, inMemory: true)
}
