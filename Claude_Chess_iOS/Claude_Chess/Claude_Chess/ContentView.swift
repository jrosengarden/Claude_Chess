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

    // Sheet presentation states
    @State private var showingGameMenu = false
    @State private var showingSettings = false

    var body: some View {
        VStack {
            // Header with title and action buttons
            HStack {
                Text("Claude Chess")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()

                // Game menu button
                Button {
                    showingGameMenu = true
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .padding(.trailing, 8)

                // Settings button
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
        .sheet(isPresented: $showingGameMenu) {
            GameMenuView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
}
