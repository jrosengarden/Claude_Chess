#include "chess.h"
#include <stdio.h>

int main() {
    ChessGame game;
    init_board(&game);
    
    printf("Initial game state:\n");
    printf("White king moved: %s\n", game.white_king_moved ? "true" : "false");
    printf("White rook H moved: %s\n", game.white_rook_h_moved ? "true" : "false");
    printf("White in check: %s\n", game.in_check[WHITE] ? "true" : "false");
    
    // Make the setup moves for castling test
    printf("\n=== Making setup moves ===\n");
    
    // 1. e2 e4
    Position e2 = {6, 4}, e4 = {4, 4};
    if (make_move(&game, e2, e4)) {
        printf("✅ e2 e4 successful\n");
    } else {
        printf("❌ e2 e4 failed\n");
    }
    
    // AI move - let's simulate d7 d5
    Position d7 = {1, 3}, d5 = {3, 3};
    game.current_player = BLACK;
    if (make_move(&game, d7, d5)) {
        printf("✅ d7 d5 (AI) successful\n");
    } else {
        printf("❌ d7 d5 (AI) failed\n");
    }
    
    // 2. g1 f3
    game.current_player = WHITE;
    Position g1 = {7, 6}, f3 = {5, 5};
    if (make_move(&game, g1, f3)) {
        printf("✅ g1 f3 successful\n");
    } else {
        printf("❌ g1 f3 failed\n");
    }
    
    // AI move - let's simulate another move
    Position g8 = {0, 6}, f6 = {2, 5};
    game.current_player = BLACK;
    if (make_move(&game, g8, f6)) {
        printf("✅ g8 f6 (AI) successful\n");
    } else {
        printf("❌ g8 f6 (AI) failed\n");
    }
    
    // 3. f1 c4
    game.current_player = WHITE;
    Position f1 = {7, 5}, c4 = {4, 2};
    if (make_move(&game, f1, c4)) {
        printf("✅ f1 c4 successful\n");
    } else {
        printf("❌ f1 c4 failed\n");
    }
    
    printf("\n=== After setup moves ===\n");
    printf("White king moved: %s\n", game.white_king_moved ? "true" : "false");
    printf("White rook H moved: %s\n", game.white_rook_h_moved ? "true" : "false");
    printf("White in check: %s\n", game.in_check[WHITE] ? "true" : "false");
    
    // Check if castling path is clear
    printf("f1 empty: %s\n", !is_piece_at(&game, 7, 5) ? "true" : "false");
    printf("g1 empty: %s\n", !is_piece_at(&game, 7, 6) ? "true" : "false");
    printf("f1 attacked by black: %s\n", is_square_attacked(&game, (Position){7, 5}, BLACK) ? "true" : "false");
    printf("g1 attacked by black: %s\n", is_square_attacked(&game, (Position){7, 6}, BLACK) ? "true" : "false");
    
    // Set current player to WHITE for castling test
    game.current_player = WHITE;
    
    // Test getting king moves
    printf("\n=== Testing king move generation ===\n");
    printf("Current player: %s\n", game.current_player == WHITE ? "WHITE" : "BLACK");
    Position e1 = {7, 4};
    printf("Piece at e1: type=%d, color=%d\n", 
           get_piece_at(&game, e1.row, e1.col).type,
           get_piece_at(&game, e1.row, e1.col).color);
    Position moves[64];
    int move_count = get_possible_moves(&game, e1, moves);
    printf("King at e1 has %d possible moves:\n", move_count);
    for (int i = 0; i < move_count; i++) {
        printf("  Move %d: row=%d, col=%d (which is %c%d)\n", 
               i, moves[i].row, moves[i].col, 
               'a' + moves[i].col, 8 - moves[i].row);
    }
    
    // Test if e1 g1 is valid
    printf("\n=== Testing castling move validation ===\n");
    Position g1_dest = {7, 6};
    if (is_valid_move(&game, e1, g1_dest)) {
        printf("✅ e1 g1 is valid\n");
    } else {
        printf("❌ e1 g1 is NOT valid\n");
    }
    
    return 0;
}