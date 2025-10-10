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
/// - Development credits
/// - Third-party license information (chess pieces, Stockfish, etc.)
struct AboutView: View {
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

                // TODO: Add any other third-party libraries used
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
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AboutView()
    }
}
