//
//  AddRadioSheet.swift
//  FieldGuide
//

import SwiftUI

struct AddRadioSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Text("Available radios will appear here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Add Radio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AddRadioSheet()
}
