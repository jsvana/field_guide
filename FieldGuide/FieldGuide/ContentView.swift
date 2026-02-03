//
//  ContentView.swift
//  FieldGuide
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Library", systemImage: "books.vertical") {
                LibraryTab()
            }

            Tab("Search", systemImage: "magnifyingglass") {
                SearchTab()
            }

            Tab("Settings", systemImage: "gear") {
                SettingsTab()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Radio.self, Section.self, ContentBlock.self], inMemory: true)
}
