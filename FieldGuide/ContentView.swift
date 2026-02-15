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

            ChecklistsTab()
                .tabItem {
                    Label("Checklists", systemImage: "checklist")
                }
                .tag(2)

            SettingsTab()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .modelContainer(
            for: [Radio.self, Section.self, ContentBlock.self, Checklist.self, ChecklistItem.self],
            inMemory: true
        )
}
