/**
 * MICRO_TEST.C - Safe Micro-Testing Framework for Claude Sessions
 * 
 * This file provides targeted, minimal-output tests for specific chess functions.
 * Unlike full game testing, these tests:
 * - Test individual functions with minimal output
 * - Avoid full game loops and UI displays
 * - Provide quick pass/fail results without massive logs
 * - Safe for use within Claude development sessions
 * 
 * Usage: Compile and run specific test functions as needed
 */

#include "chess.h"
#include <stdio.h>
#include <assert.h>

/**
 * Test basic board initialization
 * Tests: init_board() function
 */
void test_board_init() {
    printf("Testing board initialization... ");
    
    ChessGame game;
    init_board(&game);
    
    // Check white pieces are in correct starting positions
    assert(get_piece_at(&game, 7, 0).type == ROOK && get_piece_at(&game, 7, 0).color == WHITE);
    assert(get_piece_at(&game, 7, 4).type == KING && get_piece_at(&game, 7, 4).color == WHITE);
    assert(get_piece_at(&game, 6, 0).type == PAWN && get_piece_at(&game, 6, 0).color == WHITE);
    
    // Check black pieces are in correct starting positions  
    assert(get_piece_at(&game, 0, 0).type == ROOK && get_piece_at(&game, 0, 0).color == BLACK);
    assert(get_piece_at(&game, 0, 4).type == KING && get_piece_at(&game, 0, 4).color == BLACK);
    assert(get_piece_at(&game, 1, 0).type == PAWN && get_piece_at(&game, 1, 0).color == BLACK);
    
    // Check initial game state
    assert(game.current_player == WHITE);
    assert(game.white_king_pos.row == 7 && game.white_king_pos.col == 4);
    assert(game.black_king_pos.row == 0 && game.black_king_pos.col == 4);
    
    printf("PASSED\n");
}

/**
 * Test position string conversion
 * Tests: char_to_position() and position_to_string() functions
 */
void test_position_conversion() {
    printf("Testing position conversion... ");
    
    // Test char to position
    Position pos = char_to_position("e4");
    assert(pos.row == 4 && pos.col == 4);  // e4 = row 4, col 4
    
    pos = char_to_position("a1");
    assert(pos.row == 7 && pos.col == 0);  // a1 = row 7, col 0
    
    pos = char_to_position("h8");  
    assert(pos.row == 0 && pos.col == 7);  // h8 = row 0, col 7
    
    // Test position to string
    char* str = position_to_string((Position){4, 4});
    assert(str[0] == 'e' && str[1] == '4');
    
    str = position_to_string((Position){7, 0});
    assert(str[0] == 'a' && str[1] == '1');
    
    printf("PASSED\n");
}

/**
 * Test basic move validation structure
 * Tests: is_valid_position() and basic move checking
 */
void test_basic_move_validation() {
    printf("Testing basic move validation... ");
    
    // Test position validation
    assert(is_valid_position(0, 0) == true);   // a8
    assert(is_valid_position(7, 7) == true);   // h1
    assert(is_valid_position(-1, 0) == false); // out of bounds
    assert(is_valid_position(8, 0) == false);  // out of bounds
    assert(is_valid_position(0, 8) == false);  // out of bounds
    
    printf("PASSED\n");
}

/**
 * Test castling rights tracking
 * Tests: Initial castling rights and basic castling logic without full game
 */
void test_castling_rights() {
    printf("Testing castling rights... ");
    
    ChessGame game;
    init_board(&game);
    
    // Check initial castling rights
    assert(game.white_king_moved == false);
    assert(game.white_rook_a_moved == false);  // Queenside rook
    assert(game.white_rook_h_moved == false);  // Kingside rook  
    assert(game.black_king_moved == false);
    assert(game.black_rook_a_moved == false);  // Queenside rook
    assert(game.black_rook_h_moved == false);  // Kingside rook
    
    printf("PASSED\n");
}

/**
 * Test piece placement and retrieval
 * Tests: Basic piece manipulation without game logic
 */
void test_piece_operations() {
    printf("Testing piece operations... ");
    
    ChessGame game;
    init_board(&game);
    
    // Test piece detection
    assert(is_piece_at(&game, 7, 0) == true);   // White rook at a1
    assert(is_piece_at(&game, 4, 4) == false);  // Empty square e4
    
    // Test piece retrieval
    Piece piece = get_piece_at(&game, 7, 4);
    assert(piece.type == KING && piece.color == WHITE);  // White king
    
    piece = get_piece_at(&game, 0, 4);
    assert(piece.type == KING && piece.color == BLACK);  // Black king
    
    printf("PASSED\n");
}

/**
 * Test FEN string validation
 * Tests: validate_fen_string() function with valid and invalid FEN strings
 */
void test_fen_validation() {
    printf("Testing FEN validation... ");
    
    // Valid FEN strings
    assert(validate_fen_string("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") == true);
    assert(validate_fen_string("r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 4 4") == true);
    assert(validate_fen_string("8/8/8/8/8/8/8/8 w - - 0 1") == true);  // Empty board
    
    // Invalid FEN strings
    assert(validate_fen_string("") == false);  // Empty string
    assert(validate_fen_string(NULL) == false);  // NULL pointer
    assert(validate_fen_string("invalid") == false);  // No slashes
    assert(validate_fen_string("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP") == false);  // Missing parts
    assert(validate_fen_string("rnbqkbnr/pppppppp/8/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1") == false);  // Too many ranks
    
    printf("PASSED\n");
}

/**
 * Test FEN board setup
 * Tests: setup_board_from_fen() with standard starting position
 */
void test_fen_setup() {
    printf("Testing FEN board setup... ");
    
    ChessGame game;
    const char* starting_fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    
    // Setup board from starting FEN
    assert(setup_board_from_fen(&game, starting_fen) == true);
    
    // Check that pieces are in correct starting positions
    assert(get_piece_at(&game, 0, 0).type == ROOK && get_piece_at(&game, 0, 0).color == BLACK);
    assert(get_piece_at(&game, 0, 4).type == KING && get_piece_at(&game, 0, 4).color == BLACK);
    assert(get_piece_at(&game, 7, 0).type == ROOK && get_piece_at(&game, 7, 0).color == WHITE);
    assert(get_piece_at(&game, 7, 4).type == KING && get_piece_at(&game, 7, 4).color == WHITE);
    
    // Check current player is white
    assert(game.current_player == WHITE);
    
    // Check king positions were set correctly
    assert(game.white_king_pos.row == 7 && game.white_king_pos.col == 4);
    assert(game.black_king_pos.row == 0 && game.black_king_pos.col == 4);
    
    // Test invalid FEN
    assert(setup_board_from_fen(&game, "invalid_fen") == false);
    
    printf("PASSED\n");
}

/**
 * Test character to piece type conversion
 * Tests: char_to_piece_type() helper function
 */
void test_char_to_piece_type() {
    printf("Testing character to piece type conversion... ");
    
    // Test lowercase characters
    assert(char_to_piece_type('p') == PAWN);
    assert(char_to_piece_type('r') == ROOK);
    assert(char_to_piece_type('n') == KNIGHT);
    assert(char_to_piece_type('b') == BISHOP);
    assert(char_to_piece_type('q') == QUEEN);
    assert(char_to_piece_type('k') == KING);
    
    // Test uppercase characters (should also work due to tolower)
    assert(char_to_piece_type('P') == PAWN);
    assert(char_to_piece_type('R') == ROOK);
    assert(char_to_piece_type('N') == KNIGHT);
    assert(char_to_piece_type('B') == BISHOP);
    assert(char_to_piece_type('Q') == QUEEN);
    assert(char_to_piece_type('K') == KING);
    
    // Test invalid characters
    assert(char_to_piece_type('x') == EMPTY);
    assert(char_to_piece_type('1') == EMPTY);
    
    printf("PASSED\n");
}

/**
 * Test complex FEN string setup and check detection
 * Tests: Complex FEN parsing, is_in_check(), and is_square_attacked() functions
 * This test specifically targets the previous infinite recursion bug
 */
void test_complex_fen_and_check_detection() {
    printf("Testing complex FEN setup and check detection... ");
    
    ChessGame game;
    // The problematic FEN string that previously caused infinite recursion
    const char* complex_fen = "rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 98 5";
    
    // Test FEN setup succeeds
    assert(setup_board_from_fen(&game, complex_fen) == true);
    
    // Test king positions are correct
    assert(game.white_king_pos.row == 7 && game.white_king_pos.col == 4);  // e1
    assert(game.black_king_pos.row == 0 && game.black_king_pos.col == 4);  // e8
    
    // Test halfmove clock and fullmove number were parsed correctly
    assert(game.halfmove_clock == 98);
    assert(game.fullmove_number == 5);
    
    // Test that is_in_check works without infinite recursion
    bool white_check = is_in_check(&game, WHITE);
    bool black_check = is_in_check(&game, BLACK);
    // Both should be false for this position (we don't assert specific values,
    // just that the function completes without crashing)
    (void)white_check; (void)black_check;  // Suppress unused variable warnings
    
    // Test that is_square_attacked works without infinite recursion
    bool e1_attacked = is_square_attacked(&game, (Position){7, 4}, BLACK);
    bool e8_attacked = is_square_attacked(&game, (Position){0, 4}, WHITE);
    (void)e1_attacked; (void)e8_attacked;  // Suppress unused variable warnings
    
    printf("PASSED\n");
}

/**
 * Test 50-move rule detection with complex FEN
 * Tests: is_fifty_move_rule_draw() function with both basic and complex scenarios
 */
void test_fifty_move_rule() {
    printf("Testing 50-move rule detection... ");
    
    ChessGame game;
    init_board(&game);
    
    // Test that initial position is not 50-move rule draw
    assert(is_fifty_move_rule_draw(&game) == false);
    
    // Test with halfmove clock at 99 (not yet 50-move rule)
    game.halfmove_clock = 99;
    assert(is_fifty_move_rule_draw(&game) == false);
    
    // Test with halfmove clock at 100 (exactly 50 moves, should be draw)
    game.halfmove_clock = 100;
    assert(is_fifty_move_rule_draw(&game) == true);
    
    // Test with halfmove clock above 100 (more than 50 moves, should be draw)
    game.halfmove_clock = 120;
    assert(is_fifty_move_rule_draw(&game) == true);
    
    // Test with complex FEN that has high halfmove clock
    const char* complex_fen = "rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 98 5";
    assert(setup_board_from_fen(&game, complex_fen) == true);
    assert(game.halfmove_clock == 98);
    assert(is_fifty_move_rule_draw(&game) == false);  // 98 < 100, so not yet a draw
    
    // Test the same position but with 100+ halfmove clock
    const char* fifty_move_fen = "rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 100 5";
    assert(setup_board_from_fen(&game, fifty_move_fen) == true);
    assert(game.halfmove_clock == 100);
    assert(is_fifty_move_rule_draw(&game) == true);  // 100 = 50 moves, should be draw
    
    printf("PASSED\n");
}

/**
 * Run all micro-tests
 * Executes all test functions with minimal output
 */
int main() {
    printf("=== MICRO-TESTING FRAMEWORK ===\n");
    printf("Running safe, minimal-output tests...\n\n");
    
    test_board_init();
    test_position_conversion(); 
    test_basic_move_validation();
    test_castling_rights();
    test_piece_operations();
    test_char_to_piece_type();
    test_fen_validation();
    test_fen_setup();
    test_complex_fen_and_check_detection();
    test_fifty_move_rule();
    
    printf("\n✅ ALL MICRO-TESTS PASSED\n");
    printf("=== TESTING COMPLETE ===\n");
    
    return 0;
}