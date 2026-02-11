//
//  LibraryTab.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct LibraryTab: View {
    @Environment(AppState.self) private var appState

    @Query(sort: [SortDescriptor(\Radio.manufacturer), SortDescriptor(\Radio.model)]) private
        var radios: [Radio]

    @State private var path = NavigationPath()

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

    private var nonFavoriteRadios: [Radio] {
        downloadedRadios.filter { !$0.isFavorite }
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                if radios.isEmpty {
                    emptyState
                } else {
                    radioGrid
                }
            }
            .navigationTitle("Library")
            .navigationDestination(for: Radio.self) { radio in
                RadioDetailView(radio: radio)
            }
        }
        .onChange(of: appState.pendingRadioID) { _, radioID in
            guard let radioID else { return }
            if let radio = radios.first(where: { $0.id == radioID }) {
                path = NavigationPath()
                path.append(radio)
            }
            appState.pendingRadioID = nil
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
        VStack(alignment: .leading, spacing: 24) {
            if !favoriteRadios.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Favorites")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(favoriteRadios) { radio in
                            NavigationLink(value: radio) {
                                RadioCard(radio: radio)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                if !favoriteRadios.isEmpty {
                    Text("All Radios")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.horizontal)
                }

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(nonFavoriteRadios) { radio in
                        NavigationLink(value: radio) {
                            RadioCard(radio: radio)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct RadioCard: View {
    @Bindable var radio: Radio

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "radio")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)

                Button {
                    radio.isFavorite.toggle()
                } label: {
                    Image(systemName: radio.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 20))
                        .foregroundStyle(radio.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)
            }

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
        .environment(AppState())
        .modelContainer(for: Radio.self, inMemory: true)
}
