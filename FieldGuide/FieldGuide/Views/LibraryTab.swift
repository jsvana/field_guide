//
//  LibraryTab.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct LibraryTab: View {
    @Query(sort: \Radio.model) private var radios: [Radio]
    @State private var showAddRadio = false

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
            .sheet(isPresented: $showAddRadio) {
                AddRadioSheet()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Download your first manual to get started")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showAddRadio = true
            } label: {
                Label("Add Radio", systemImage: "plus")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
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

            // Add Radio card
            Button {
                showAddRadio = true
            } label: {
                AddRadioCard()
            }
            .buttonStyle(.plain)
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
        VStack(spacing: 8) {
            Image(systemName: "radio")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(height: 60)

            Text(radio.model)
                .font(.headline)

            HStack {
                Text(radio.manufacturer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(radio.manualRevision)
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AddRadioCard: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .frame(height: 60)

            Text("Add Radio")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(.secondary)
        )
    }
}

#Preview {
    LibraryTab()
        .modelContainer(for: Radio.self, inMemory: true)
}
