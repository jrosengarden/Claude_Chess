#include "chess.h"
#include <stdio.h>

int main() {
    ChessGame game;
    init_board(&game);
    
    printf("=== Queenside Castling Debug ===\n");
    
    // Make the setup moves for queenside castling test
    printf("Making setup moves for queenside castling:\n");
    
    // 1. d2 d4
    Position d2 = {6, 3}, d4 = {4, 3};
    if (make_move(&game, d2, d4)) {
        printf("✅ d2 d4 successful\n");
    } else {
        printf("❌ d2 d4 failed\n");
    }
    
    // AI move 
    Position d7 = {1, 3}, d5 = {3, 3};
    game.current_player = BLACK;
    if (make_move(&game, d7, d5)) {
        printf("✅ d7 d5 (AI) successful\n");
    } else {
        printf("❌ d7 d5 (AI) failed\n");
    }
    
    // 2. b1 c3
    game.current_player = WHITE;
    Position b1 = {7, 1}, c3 = {5, 2};
    if (make_move(&game, b1, c3)) {
        printf("✅ b1 c3 successful\n");
    } else {
        printf("❌ b1 c3 failed\n");
    }
    
    // AI move
    Position b8 = {0, 1}, c6 = {2, 2};
    game.current_player = BLACK;
    if (make_move(&game, b8, c6)) {
        printf("✅ b8 c6 (AI) successful\n");
    } else {
        printf("❌ b8 c6 (AI) failed\n");
    }
    
    // 3. c1 f4
    game.current_player = WHITE;
    Position c1 = {7, 2}, f4 = {4, 5};
    if (make_move(&game, c1, f4)) {
        printf("✅ c1 f4 successful\n");
    } else {
        printf("❌ c1 f4 failed\n");
    }
    
    // AI move
    Position c8 = {0, 2}, f5 = {3, 5};
    game.current_player = BLACK;
    if (make_move(&game, c8, f5)) {
        printf("✅ c8 f5 (AI) successful\n");
    } else {
        printf("❌ c8 f5 (AI) failed\n");
    }
    
    // 4. d1 d3
    game.current_player = WHITE;
    Position d1 = {7, 3}, d3 = {5, 3};
    if (make_move(&game, d1, d3)) {
        printf("✅ d1 d3 successful\n");
    } else {
        printf("❌ d1 d3 failed\n");
    }
    
    printf("\n=== After setup moves ===\n");
    printf("White king moved: %s\n", game.white_king_moved ? "true" : "false");
    printf("White rook A moved: %s\n", game.white_rook_a_moved ? "true" : "false");
    printf("White in check: %s\n", game.in_check[WHITE] ? "true" : "false");
    
    // Check if queenside castling path is clear
    printf("b1 empty: %s\n", !is_piece_at(&game, 7, 1) ? "true" : "false");
    printf("c1 empty: %s\n", !is_piece_at(&game, 7, 2) ? "true" : "false");
    printf("d1 empty: %s\n", !is_piece_at(&game, 7, 3) ? "true" : "false");
    printf("c1 attacked by black: %s\n", is_square_attacked(&game, (Position){7, 2}, BLACK) ? "true" : "false");
    printf("d1 attacked by black: %s\n", is_square_attacked(&game, (Position){7, 3}, BLACK) ? "true" : "false");
    
    // Set current player to WHITE for castling test
    game.current_player = WHITE;
    
    // Test getting king moves
    printf("\n=== Testing king move generation ===\n");
    Position e1 = {7, 4};
    Position moves[64];
    int move_count = get_possible_moves(&game, e1, moves);
    printf("King at e1 has %d possible moves:\n", move_count);
    for (int i = 0; i < move_count; i++) {
        printf("  Move %d: row=%d, col=%d (which is %c%d)\n", 
               i, moves[i].row, moves[i].col, 
               'a' + moves[i].col, 8 - moves[i].row);
    }
    
    // Test if e1 c1 is valid
    printf("\n=== Testing queenside castling move validation ===\n");
    Position c1_dest = {7, 2};
    if (is_valid_move(&game, e1, c1_dest)) {
        printf("✅ e1 c1 is valid\n");
    } else {
        printf("❌ e1 c1 is NOT valid\n");
    }
    
    return 0;
}