//
//  ContentView.swift
//  Claude_Chess
//
//  Created by Jeff Rosengarden on 9/28/25.
//

import SwiftUI

struct ContentView: View {
    // Game state
    @StateObject private var game = ChessGame()

    // Settings sheet presentation
    @State private var showingSettings = false

    var body: some View {
        VStack {
            // Header with title and settings button
            HStack {
                Text("Claude Chess")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal)
            .padding(.top)

            // Chess board with current game state
            ChessBoardView(board: game.board)
                .aspectRatio(1, contentMode: .fit)
                .padding()

            // Game info
            Text("Current Player: \(game.currentPlayer.displayName)")
                .font(.headline)
                .padding(.top)

            Spacer()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
}
