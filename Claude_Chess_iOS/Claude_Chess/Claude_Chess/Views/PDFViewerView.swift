//
//  PDFViewerView.swift
//  Claude_Chess
//
//  PDF document viewer using native iOS PDFKit framework
//  Displays PDF files bundled with the app (e.g., User Guide)
//  with native zoom, scroll, and search capabilities
//

import SwiftUI
import PDFKit

/// SwiftUI wrapper for displaying PDF documents using PDFKit
/// - parameter pdfName: Name of PDF file in bundle (without .pdf extension)
struct PDFViewerView: View {
    let pdfName: String
    @State private var showShareSheet = false

    var body: some View {
        PDFKitView(pdfName: pdfName)
            .navigationTitle("User Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let pdfURL = getPDFURL() {
                    ShareSheet(items: [pdfURL])
                }
            }
    }

    /// Get URL to PDF file in app bundle
    private func getPDFURL() -> URL? {
        guard let path = Bundle.main.path(forResource: pdfName, ofType: "pdf") else {
            return nil
        }
        return URL(fileURLWithPath: path)
    }
}

/// UIKit share sheet wrapper for SwiftUI
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

/// UIViewRepresentable wrapper for PDFKit's PDFView
/// Provides native iOS PDF viewing experience with:
/// - Automatic scaling to fit screen
/// - Pinch-to-zoom support
/// - Smooth scrolling through pages
/// - Built-in page navigation
struct PDFKitView: UIViewRepresentable {
    let pdfName: String

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical

        // Load PDF from app bundle
        if let path = Bundle.main.path(forResource: pdfName, ofType: "pdf"),
           let pdfDocument = PDFDocument(url: URL(fileURLWithPath: path)) {
            pdfView.document = pdfDocument
        }

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        // No updates needed - PDF is static
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        PDFViewerView(pdfName: "UserGuide")
    }
}
