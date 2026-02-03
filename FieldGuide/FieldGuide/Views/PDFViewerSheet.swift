//
//  PDFViewerSheet.swift
//  FieldGuide
//

import PDFKit
import SwiftUI

struct PDFViewerSheet: View {
    let radio: Radio
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            PDFKitView(url: pdfURL)
                .navigationTitle(radio.model)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        if let url = pdfURL {
                            ShareLink(item: url)
                        }
                    }
                }
        }
    }

    private var pdfURL: URL? {
        guard let path = radio.pdfLocalPath else { return nil }
        return URL(fileURLWithPath: path)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL?

    func makeUIView(context _: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        if let url, let document = PDFDocument(url: url) {
            pdfView.document = document
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context _: Context) {
        if let url, let document = PDFDocument(url: url) {
            uiView.document = document
        }
    }
}

#Preview {
    PDFViewerSheet(radio: Radio(
        id: "test",
        manufacturer: "Elecraft",
        model: "KX2",
        manualRevision: "B2",
        pdfFilename: "test.pdf"
    ))
}
