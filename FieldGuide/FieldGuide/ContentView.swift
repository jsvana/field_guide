//
//  ContentView.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LibraryTab()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }

            SearchTab()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Radio.self, Section.self, ContentBlock.self], inMemory: true)
}
