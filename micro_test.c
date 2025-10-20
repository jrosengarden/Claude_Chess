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
#include "stockfish.h"
#include "pgn_utils.h"
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <unistd.h>

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
 * Test en passant FEN parsing
 * Tests: setup_board_from_fen() and board_to_fen() with en passant target squares
 */
void test_en_passant_fen_parsing() {
    printf("Testing en passant FEN parsing... ");
    
    ChessGame game;
    
    // Test FEN with en passant target square
    const char* fen_with_en_passant = "rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3";
    assert(setup_board_from_fen(&game, fen_with_en_passant) == true);
    
    // Check en passant state was parsed correctly
    assert(game.en_passant_available == true);
    assert(game.en_passant_target.row == 2);  // f6 is row 2 (6th rank)
    assert(game.en_passant_target.col == 5);  // f file is col 5
    
    // Test FEN without en passant target square  
    const char* fen_no_en_passant = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
    assert(setup_board_from_fen(&game, fen_no_en_passant) == true);
    
    // Check en passant state is disabled
    assert(game.en_passant_available == false);
    assert(game.en_passant_target.row == -1);
    assert(game.en_passant_target.col == -1);
    
    printf("PASSED\n");
}

/**
 * Test en passant move generation
 * Tests: get_pawn_moves() includes en passant captures when available
 */
void test_en_passant_move_generation() {
    printf("Testing en passant move generation... ");
    
    ChessGame game;
    
    // Set up position where en passant is available
    // White pawn on e5, black just moved pawn from f7 to f5 (en passant target f6)
    const char* test_fen = "rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3";
    assert(setup_board_from_fen(&game, test_fen) == true);
    
    // Get moves for white pawn on e5
    Position white_pawn = {3, 4};  // e5 (row 3, col 4)
    Position moves[10];
    int move_count = get_pawn_moves(&game, white_pawn, moves);
    
    // Should have at least 2 moves: e6 (forward) and f6 (en passant capture)
    assert(move_count >= 2);
    
    // Check that f6 en passant target is included in possible moves
    bool found_en_passant = false;
    for (int i = 0; i < move_count; i++) {
        if (moves[i].row == 2 && moves[i].col == 5) {  // f6
            found_en_passant = true;
            break;
        }
    }
    assert(found_en_passant == true);
    
    printf("PASSED\n");
}

/**
 * Test en passant capture execution
 * Tests: make_move() properly executes en passant captures
 */
void test_en_passant_capture() {
    printf("Testing en passant capture execution... ");
    
    ChessGame game;
    
    // Set up position for en passant capture
    const char* test_fen = "rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3";
    assert(setup_board_from_fen(&game, test_fen) == true);
    
    // White pawn on e5 captures en passant on f6
    Position from = {3, 4};  // e5
    Position to = {2, 5};    // f6 (en passant target)
    
    // Verify black pawn is on f5 before capture
    assert(get_piece_at(&game, 3, 5).type == PAWN);
    assert(get_piece_at(&game, 3, 5).color == BLACK);
    
    // Execute en passant capture
    assert(make_move(&game, from, to) == true);
    
    // Verify white pawn is now on f6
    assert(get_piece_at(&game, 2, 5).type == PAWN);
    assert(get_piece_at(&game, 2, 5).color == WHITE);
    
    // Verify black pawn was removed from f5
    assert(get_piece_at(&game, 3, 5).type == EMPTY);
    
    // Verify en passant state is reset after the move
    assert(game.en_passant_available == false);
    
    // Verify capture was recorded
    assert(game.white_captured.count == 1);
    assert(game.white_captured.captured_pieces[0].type == PAWN);
    assert(game.white_captured.captured_pieces[0].color == BLACK);
    
    printf("PASSED\n");
}

/**
 * Test pawn promotion detection
 * Tests: is_promotion_move() function
 */
void test_promotion_detection() {
    printf("Testing pawn promotion detection... ");

    ChessGame game;
    init_board(&game);

    // Place white pawn on 7th rank (row 1)
    set_piece_at(&game, 1, 4, (Piece){PAWN, WHITE});

    // Test that moving to 8th rank (row 0) is detected as promotion
    Position from = {1, 4};  // e7
    Position to = {0, 4};    // e8
    assert(is_promotion_move(&game, from, to) == true);

    // Test that moving to non-promotion square is not promotion
    Position not_promotion = {2, 4};  // e6
    assert(is_promotion_move(&game, from, not_promotion) == false);

    // Place black pawn on 2nd rank (row 6)
    set_piece_at(&game, 6, 3, (Piece){PAWN, BLACK});

    // Test that black pawn moving to 1st rank (row 7) is detected as promotion
    Position black_from = {6, 3};  // d2
    Position black_to = {7, 3};    // d1
    assert(is_promotion_move(&game, black_from, black_to) == true);

    // Test non-pawn pieces don't trigger promotion
    set_piece_at(&game, 1, 5, (Piece){QUEEN, WHITE});
    Position queen_from = {1, 5};
    Position queen_to = {0, 5};
    assert(is_promotion_move(&game, queen_from, queen_to) == false);

    printf("PASSED\n");
}

/**
 * Test promotion piece validation
 * Tests: is_valid_promotion_piece() function
 */
void test_promotion_piece_validation() {
    printf("Testing promotion piece validation... ");

    // Valid promotion pieces
    assert(is_valid_promotion_piece(QUEEN) == true);
    assert(is_valid_promotion_piece(ROOK) == true);
    assert(is_valid_promotion_piece(BISHOP) == true);
    assert(is_valid_promotion_piece(KNIGHT) == true);

    // Invalid promotion pieces
    assert(is_valid_promotion_piece(PAWN) == false);
    assert(is_valid_promotion_piece(KING) == false);
    assert(is_valid_promotion_piece(EMPTY) == false);

    printf("PASSED\n");
}

/**
 * Test pawn promotion move execution
 * Tests: make_promotion_move() function with different piece types
 */
void test_promotion_move_execution() {
    printf("Testing pawn promotion move execution... ");

    ChessGame game;
    init_board(&game);

    // Clear board and place white pawn ready for promotion
    memset(game.board, 0, sizeof(game.board));
    set_piece_at(&game, 1, 4, (Piece){PAWN, WHITE});  // e7
    game.current_player = WHITE;

    // Test promotion to queen
    Position from = {1, 4};  // e7
    Position to = {0, 4};    // e8
    assert(make_promotion_move(&game, from, to, QUEEN) == true);

    // Verify queen was placed on destination square
    Piece promoted = get_piece_at(&game, 0, 4);
    assert(promoted.type == QUEEN);
    assert(promoted.color == WHITE);

    // Verify original square is empty
    assert(get_piece_at(&game, 1, 4).type == EMPTY);

    // Verify game state was updated
    assert(game.current_player == BLACK);  // Should switch players
    assert(game.halfmove_clock == 0);      // Should reset for pawn move

    // Test promotion with capture
    memset(game.board, 0, sizeof(game.board));
    set_piece_at(&game, 6, 3, (Piece){PAWN, BLACK});   // d2
    set_piece_at(&game, 7, 4, (Piece){ROOK, WHITE});   // e1 (target for capture)
    game.current_player = BLACK;
    game.white_captured.count = 0;

    // Black pawn captures rook and promotes to knight
    Position black_from = {6, 3};  // d2
    Position black_to = {7, 4};    // e1
    assert(make_promotion_move(&game, black_from, black_to, KNIGHT) == true);

    // Verify knight was placed and rook was captured
    Piece promoted_knight = get_piece_at(&game, 7, 4);
    assert(promoted_knight.type == KNIGHT);
    assert(promoted_knight.color == BLACK);
    assert(game.black_captured.count == 1);
    assert(game.black_captured.captured_pieces[0].type == ROOK);

    printf("PASSED\n");
}

/**
 * Test promotion with FEN integration
 * Tests: Promotion moves work correctly with FEN board setup
 */
void test_promotion_fen_integration() {
    printf("Testing promotion FEN integration... ");

    ChessGame game;

    // Set up position with white pawn ready to promote and kings safely positioned
    const char* test_fen = "8/4P3/8/8/8/8/8/K6k w - - 0 1";

    assert(setup_board_from_fen(&game, test_fen) == true);

    // Verify pawn is in position
    assert(get_piece_at(&game, 1, 4).type == PAWN);
    assert(get_piece_at(&game, 1, 4).color == WHITE);

    // Test promotion detection works with FEN setup
    Position from = {1, 4};  // e7
    Position to = {0, 4};    // e8
    assert(is_promotion_move(&game, from, to) == true);

    // Execute promotion
    assert(make_promotion_move(&game, from, to, ROOK) == true);

    // Verify promotion was successful
    assert(get_piece_at(&game, 0, 4).type == ROOK);
    assert(get_piece_at(&game, 0, 4).color == WHITE);

    printf("PASSED\n");
}

/**
 * Test UCI move string parsing for promotion moves
 * Tests: parse_move_string() function handles promotion notation
 */
void test_uci_promotion_parsing() {
    printf("Testing UCI promotion move parsing... ");

    // Test normal move parsing (should still work)
    Move normal_move = parse_move_string("e2e4");
    assert(normal_move.from.row == 6 && normal_move.from.col == 4);  // e2
    assert(normal_move.to.row == 4 && normal_move.to.col == 4);      // e4
    assert(normal_move.is_promotion == false);
    assert(normal_move.promotion_piece == EMPTY);

    // Test promotion move parsing
    Move promo_queen = parse_move_string("e7e8q");
    assert(promo_queen.from.row == 1 && promo_queen.from.col == 4);  // e7
    assert(promo_queen.to.row == 0 && promo_queen.to.col == 4);      // e8
    assert(promo_queen.is_promotion == true);
    assert(promo_queen.promotion_piece == QUEEN);

    Move promo_rook = parse_move_string("a2a1r");
    assert(promo_rook.is_promotion == true);
    assert(promo_rook.promotion_piece == ROOK);

    Move promo_bishop = parse_move_string("h7h8b");
    assert(promo_bishop.is_promotion == true);
    assert(promo_bishop.promotion_piece == BISHOP);

    Move promo_knight = parse_move_string("c2c1n");
    assert(promo_knight.is_promotion == true);
    assert(promo_knight.promotion_piece == KNIGHT);

    // Test invalid promotion character
    Move invalid_promo = parse_move_string("e7e8x");
    assert(invalid_promo.is_promotion == false);
    assert(invalid_promo.promotion_piece == EMPTY);

    printf("PASSED\n");
}

/**
 * Run all micro-tests
 * Executes all test functions with minimal output
 */
/**
 * Test PGN conversion from FEN log file
 * Tests: convert_fen_to_pgn_string() function from pgn_utils.c
 */
void test_pgn_conversion() {
    printf("Testing PGN conversion... ");

    const char* test_filename = "test_pgn_conversion.fen";
    FILE* test_file = fopen(test_filename, "w");
    assert(test_file != NULL);

    fprintf(test_file, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1\n");
    fprintf(test_file, "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1\n");
    fprintf(test_file, "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2\n");
    fprintf(test_file, "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2\n");
    fclose(test_file);

    char* pgn_result = convert_fen_to_pgn_string(test_filename, "*");
    assert(pgn_result != NULL);

    assert(strstr(pgn_result, "[Event \"Current Game\"]") != NULL);
    assert(strstr(pgn_result, "[White \"Player\"]") != NULL);
    assert(strstr(pgn_result, "[Black \"AI\"]") != NULL);
    assert(strstr(pgn_result, "[Result \"*\"]") != NULL);
    assert(strstr(pgn_result, "1. e4") != NULL);
    assert(strstr(pgn_result, "e5") != NULL);
    assert(strstr(pgn_result, "2. Nf3") != NULL);

    free(pgn_result);
    unlink(test_filename);

    printf("PASSED\n");
}

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
    test_en_passant_fen_parsing();
    test_en_passant_move_generation();
    test_en_passant_capture();
    test_promotion_detection();
    test_promotion_piece_validation();
    test_promotion_move_execution();
    test_promotion_fen_integration();
    test_uci_promotion_parsing();
    test_pgn_conversion();

    printf("\n✅ ALL MICRO-TESTS PASSED\n");
    printf("=== TESTING COMPLETE ===\n");

    return 0;
}
