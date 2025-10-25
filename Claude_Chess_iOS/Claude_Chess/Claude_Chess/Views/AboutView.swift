//
//  AboutView.swift
//  Claude_Chess
//
//  About view displaying app information, credits, and licenses
//  This view shows app version, credits, license information,
//  and attribution for third-party resources
//

import SwiftUI

/// About view displaying app credits, licenses, and attribution
/// - App version and build information
/// - Help & Feedback section with User Guide and Contact Developer
/// - Development credits
/// - Third-party license information (chess pieces, Stockfish, etc.)
struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    @State private var stockfishVersion: String = "Unknown"
    @State private var showingContactOptions = false

    var body: some View {
        List {
            Section(header: Text("App Information")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("AI Engine")
                    Spacer()
                    Text(stockfishVersion)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Design")
                    Spacer()
                    Text("Jeff Rosengarden")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Programmer")
                    Spacer()
                    Text("Jeff Rosengarden")
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Help & Feedback")) {
                // User Guide navigation button
                NavigationLink(destination: PDFViewerView(pdfName: "UserGuide")) {
                    Text("User Guide")
                }

                // Contact Developer button with action sheet
                Button(action: {
                    showingContactOptions = true
                }) {
                    Text("Contact Developer")
                }
            }

            Section(header: Text("Credits")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Claude Chess iOS")
                        .font(.headline)
                    Text("A native iOS port of the Claude Chess terminal application.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Development")
                        .font(.headline)
                    Text("Built in xCode with SwiftUI\n w/Assistance from Claude Code (v2.0.12)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section(header: Text("Third-Party Licenses")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cburnett Chess Pieces")
                        .font(.headline)
                    Text("License: CC-BY-SA 3.0 (Creative Commons Attribution-ShareAlike)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Creator: User:Cburnett")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Source: Wikimedia Commons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Stockfish License")
                        .font(.headline)

                    Text("Stockfish is free software licensed under the GNU General Public License version 3 (GPLv3).")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Copyright © 2004-2024 The Stockfish developers (see AUTHORS file)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Website: https://stockfishchess.org")
                        .font(.caption)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ChessKitEngine")
                        .font(.headline)

                    Text("ChessKitEngine is licensed under the MIT License.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Copyright © 2024 The ChessKit Authors")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("GitHub: https://github.com/chesskit-app/chesskit-engine")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
 
            Section(header: Text("Open Source")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("This app is based on the open-source Claude Chess terminal project.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .confirmationDialog("Contact Developer", isPresented: $showingContactOptions, titleVisibility: .visible) {
            Button("Feedback") {
                sendEmail(type: "Feedback")
            }
            Button("Bug Report") {
                sendEmail(type: "Bug Report")
            }
            Button("Feature Request") {
                sendEmail(type: "Feature Request")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("What would you like to send?")
        }
        .onAppear {
            // Get Stockfish version from shared engine instance
            Task {
                let engine = StockfishEngine.shared
                let currentVersion = engine.getEngineVersion()

                // If engine hasn't been initialized yet, initialize it just to detect version
                if currentVersion == "Unknown" {
                    do {
                        try await engine.initialize()
                        stockfishVersion = engine.getEngineVersion()
                        // Shutdown to free resources since we only needed the version
                        await engine.shutdown()
                    } catch {
                        // If initialization fails, fall back to known version
                        stockfishVersion = "Stockfish 17"
                    }
                } else {
                    // Engine already initialized, just use the version
                    stockfishVersion = currentVersion
                }
            }
        }
    }

    // MARK: - Helper Functions

    /// Open mail app with pre-filled recipient and subject based on feedback type
    private func sendEmail(type: String) {
        let email = "jrosengarden@mac.com"
        let subject = "Claude Chess - \(type)"
        let urlString = "mailto:\(email)?subject=\(subject)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AboutView()
    }
}
