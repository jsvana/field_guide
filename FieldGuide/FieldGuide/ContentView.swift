//
//  ContentView.swift
//  FieldGuide
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState
        TabView(selection: $appState.selectedTab) {
            LibraryTab()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .tag(0)

            SearchTab()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(for: [Radio.self, Section.self, ContentBlock.self], inMemory: true)
}
