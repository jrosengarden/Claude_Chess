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

    var body: some View {
        VStack {
            Text("Claude Chess")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            // Chess board with current game state
            ChessBoardView(board: game.board)
                .aspectRatio(1, contentMode: .fit)
                .padding()

            // Game info
            Text("Current Player: \(game.currentPlayer.displayName)")
                .font(.headline)
                .padding(.top)
        }
    }
}

#Preview {
    ContentView()
}
