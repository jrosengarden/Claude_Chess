/**
 * CHESS.C - Core Chess Game Implementation
 * 
 * This file implements all the core chess game logic including:
 * - Board initialization and management
 * - Complete piece movement rules and validation
 * - Check/checkmate/stalemate detection
 * - Move generation for all piece types
 * - Game state management with unlimited undo system
 * - Utility functions for position handling and FEN notation
 * 
 * The chess engine supports:
 * - All standard piece movements (pawn, rook, knight, bishop, queen, king)
 * - Castling (kingside and queenside) with full rule validation
 * - En passant captures with proper state tracking
 * - Check detection and prevention of illegal moves
 * - Capture tracking with visual display
 * - 50-move rule automatic draw detection
 * - Unlimited undo functionality using FEN log restoration
 * - Custom board setup via FEN notation parsing
 * 
 * Remaining enhancements to implement:
 * - Pawn promotion
 */

#include "chess.h"
#include <time.h>

/**
 * Initialize a new chess game with standard starting positions
 * Sets up the board, initializes game state variables, and places pieces
 * in their starting positions according to chess rules.
 * 
 * @param game Pointer to ChessGame structure to initialize
 */
void init_board(ChessGame *game) {
    // Clear the entire board to empty squares
    memset(game->board, 0, sizeof(game->board));
    
    // Initialize game state - White always moves first
    game->current_player = WHITE;
    
    // Initialize capture tracking
    game->white_captured.count = 0;
    game->black_captured.count = 0;
    
    // Initialize castling eligibility flags (castling fully implemented)
    game->white_king_moved = false;
    game->black_king_moved = false;
    game->white_rook_a_moved = false;  // Queenside rook
    game->white_rook_h_moved = false;  // Kingside rook
    game->black_rook_a_moved = false;  // Queenside rook
    game->black_rook_h_moved = false;  // Kingside rook
    
    // Set initial king positions for efficient check detection
    game->white_king_pos = (Position){7, 4};  // e1 in chess notation
    game->black_king_pos = (Position){0, 4};  // e8 in chess notation
    
    // Initialize check status and undo system
    game->in_check[0] = false;  // White not in check
    game->in_check[1] = false;  // Black not in check
    
    // Initialize FEN move counters to standard starting values
    game->halfmove_clock = 0;    // No halfmoves since start
    game->fullmove_number = 1;   // First move pair  
    
    // Initialize en passant state
    game->en_passant_available = false;
    game->en_passant_target.row = -1;
    game->en_passant_target.col = -1;
    
    // Define starting piece arrangements for back ranks
    // Standard chess setup: Rook, Knight, Bishop, Queen, King, Bishop, Knight, Rook
    Piece white_pieces[] = {
        {ROOK, WHITE}, {KNIGHT, WHITE}, {BISHOP, WHITE}, {QUEEN, WHITE},
        {KING, WHITE}, {BISHOP, WHITE}, {KNIGHT, WHITE}, {ROOK, WHITE}
    };
    
    Piece black_pieces[] = {
        {ROOK, BLACK}, {KNIGHT, BLACK}, {BISHOP, BLACK}, {QUEEN, BLACK},
        {KING, BLACK}, {BISHOP, BLACK}, {KNIGHT, BLACK}, {ROOK, BLACK}
    };
    
    // Place pieces in standard chess starting positions
    for (int i = 0; i < 8; i++) {
        game->board[0][i] = black_pieces[i];        // Black back rank (8th rank)
        game->board[1][i] = (Piece){PAWN, BLACK};   // Black pawns (7th rank)
        game->board[6][i] = (Piece){PAWN, WHITE};   // White pawns (2nd rank)
        game->board[7][i] = white_pieces[i];        // White back rank (1st rank)
    }
}

char piece_to_char(Piece piece) {
    if (piece.type == EMPTY) return '.';
    
    // Bounds check to prevent segfault
    if (piece.type < 0 || piece.type > KING) return '?';
    
    char symbols[] = {' ', 'P', 'R', 'N', 'B', 'Q', 'K'};
    char c = symbols[piece.type];
    
    return piece.color == WHITE ? c : c + 32;
}

void print_board(ChessGame *game, Position possible_moves[], int move_count) {
    printf("\n    a b c d e f g h\n");
    printf("  +----------------+\n");
    
    for (int row = 0; row < BOARD_SIZE; row++) {
        printf("%d | ", 8 - row);
        
        for (int col = 0; col < BOARD_SIZE; col++) {
            bool is_possible_move = false;
            bool is_en_passant_capture = false;

            if (possible_moves != NULL) {
                for (int i = 0; i < move_count; i++) {
                    if (possible_moves[i].row == row && possible_moves[i].col == col) {
                        is_possible_move = true;
                        break;
                    }
                }

                // Check for en passant captured pawn highlighting
                if (game->en_passant_available && !is_possible_move) {
                    // Check if this position contains the pawn that would be captured by en passant
                    Position en_passant_target = game->en_passant_target;
                    int captured_pawn_row = (game->current_player == WHITE) ? en_passant_target.row + 1 : en_passant_target.row - 1;

                    if (row == captured_pawn_row && col == en_passant_target.col) {
                        // Check if any of the possible moves is the en passant target square
                        for (int j = 0; j < move_count; j++) {
                            if (possible_moves[j].row == en_passant_target.row &&
                                possible_moves[j].col == en_passant_target.col) {
                                is_en_passant_capture = true;
                                break;
                            }
                        }
                    }
                }
            }

            char piece_char = piece_to_char(game->board[row][col]);
            if (is_possible_move && piece_char == '.') {
                printf("* ");
            } else if (is_possible_move || is_en_passant_capture) {
                // Capturable piece - use reverse/inverted colors for highlighting
                if (piece_char >= 'A' && piece_char <= 'Z') {
                    printf("\033[7;1;95m%c\033[0m ", piece_char); // Inverted bold magenta for white pieces
                } else {
                    printf("\033[7;1;96m%c\033[0m ", piece_char); // Inverted bold cyan for black pieces
                }
            } else {
                if (piece_char != '.') {
                    if (piece_char >= 'A' && piece_char <= 'Z') {
                        printf("\033[1;95m%c\033[0m ", piece_char); // White pieces in bold magenta
                    } else {
                        printf("\033[1;96m%c\033[0m ", piece_char); // Black pieces in bold cyan
                    }
                } else {
                    printf("%c ", piece_char);
                }
            }
        }
        
        printf("| %d\n", 8 - row);
    }
    
    printf("  +----------------+\n");
    printf("    a b c d e f g h\n");
    
    if (game->in_check[game->current_player]) {
        printf("\n*** %s KING IS IN CHECK! ***\n", 
               game->current_player == WHITE ? "WHITE" : "BLACK");
    }
}

bool is_valid_position(int row, int col) {
    return row >= 0 && row < BOARD_SIZE && col >= 0 && col < BOARD_SIZE;
}

bool is_piece_at(ChessGame *game, int row, int col) {
    return game->board[row][col].type != EMPTY;
}

Piece get_piece_at(ChessGame *game, int row, int col) {
    return game->board[row][col];
}

void set_piece_at(ChessGame *game, int row, int col, Piece piece) {
    game->board[row][col] = piece;
}

void clear_position(ChessGame *game, int row, int col) {
    game->board[row][col] = (Piece){EMPTY, WHITE};
}

int get_pawn_moves(ChessGame *game, Position from, Position moves[]) {
    int count = 0;
    Piece piece = get_piece_at(game, from.row, from.col);
    int direction = (piece.color == WHITE) ? -1 : 1;
    int start_row = (piece.color == WHITE) ? 6 : 1;
    
    int new_row = from.row + direction;
    if (is_valid_position(new_row, from.col) && !is_piece_at(game, new_row, from.col)) {
        moves[count++] = (Position){new_row, from.col};
        
        if (from.row == start_row) {
            new_row = from.row + 2 * direction;
            if (is_valid_position(new_row, from.col) && !is_piece_at(game, new_row, from.col)) {
                moves[count++] = (Position){new_row, from.col};
            }
        }
    }
    
    int capture_cols[] = {from.col - 1, from.col + 1};
    for (int i = 0; i < 2; i++) {
        int new_col = capture_cols[i];
        new_row = from.row + direction;
        
        if (is_valid_position(new_row, new_col) && is_piece_at(game, new_row, new_col)) {
            Piece target = get_piece_at(game, new_row, new_col);
            if (target.color != piece.color) {
                moves[count++] = (Position){new_row, new_col};
            }
        }
    }
    
    // Check for en passant capture
    if (game->en_passant_available) {
        // En passant is possible if:
        // 1. Pawn is on the correct rank (5th rank for White, 4th rank for Black)
        // 2. Pawn is adjacent to the en passant target square
        int en_passant_rank = (piece.color == WHITE) ? 3 : 4;  // 5th rank for White (row 3), 4th rank for Black (row 4)
        
        if (from.row == en_passant_rank) {
            // Check if pawn is adjacent to en passant target square
            if (abs(from.col - game->en_passant_target.col) == 1 && 
                game->en_passant_target.row == from.row + direction) {
                moves[count++] = game->en_passant_target;
            }
        }
    }
    
    return count;
}

int get_rook_moves(ChessGame *game, Position from, Position moves[]) {
    int count = 0;
    Piece piece = get_piece_at(game, from.row, from.col);
    
    int directions[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
    
    for (int d = 0; d < 4; d++) {
        for (int i = 1; i < BOARD_SIZE; i++) {
            int new_row = from.row + directions[d][0] * i;
            int new_col = from.col + directions[d][1] * i;
            
            if (!is_valid_position(new_row, new_col)) break;
            
            if (is_piece_at(game, new_row, new_col)) {
                Piece target = get_piece_at(game, new_row, new_col);
                if (target.color != piece.color) {
                    moves[count++] = (Position){new_row, new_col};
                }
                break;
            }
            
            moves[count++] = (Position){new_row, new_col};
        }
    }
    
    return count;
}

int get_bishop_moves(ChessGame *game, Position from, Position moves[]) {
    int count = 0;
    Piece piece = get_piece_at(game, from.row, from.col);
    
    int directions[4][2] = {{-1, -1}, {-1, 1}, {1, -1}, {1, 1}};
    
    for (int d = 0; d < 4; d++) {
        for (int i = 1; i < BOARD_SIZE; i++) {
            int new_row = from.row + directions[d][0] * i;
            int new_col = from.col + directions[d][1] * i;
            
            if (!is_valid_position(new_row, new_col)) break;
            
            if (is_piece_at(game, new_row, new_col)) {
                Piece target = get_piece_at(game, new_row, new_col);
                if (target.color != piece.color) {
                    moves[count++] = (Position){new_row, new_col};
                }
                break;
            }
            
            moves[count++] = (Position){new_row, new_col};
        }
    }
    
    return count;
}

int get_knight_moves(ChessGame *game, Position from, Position moves[]) {
    int count = 0;
    Piece piece = get_piece_at(game, from.row, from.col);
    
    int knight_moves[8][2] = {
        {-2, -1}, {-2, 1}, {-1, -2}, {-1, 2},
        {1, -2}, {1, 2}, {2, -1}, {2, 1}
    };
    
    for (int i = 0; i < 8; i++) {
        int new_row = from.row + knight_moves[i][0];
        int new_col = from.col + knight_moves[i][1];
        
        if (is_valid_position(new_row, new_col)) {
            if (!is_piece_at(game, new_row, new_col) || 
                get_piece_at(game, new_row, new_col).color != piece.color) {
                moves[count++] = (Position){new_row, new_col};
            }
        }
    }
    
    return count;
}

int get_queen_moves(ChessGame *game, Position from, Position moves[]) {
    int count = 0;
    count += get_rook_moves(game, from, moves);
    count += get_bishop_moves(game, from, moves + count);
    return count;
}

int get_king_moves_no_castling(ChessGame *game, Position from, Position moves[]) {
    int count = 0;
    Piece piece = get_piece_at(game, from.row, from.col);
    
    // Standard king moves (one square in any direction)
    int directions[8][2] = {
        {-1, -1}, {-1, 0}, {-1, 1},
        {0, -1},           {0, 1},
        {1, -1},  {1, 0},  {1, 1}
    };
    
    for (int i = 0; i < 8; i++) {
        int new_row = from.row + directions[i][0];
        int new_col = from.col + directions[i][1];
        
        if (is_valid_position(new_row, new_col)) {
            if (!is_piece_at(game, new_row, new_col) || 
                get_piece_at(game, new_row, new_col).color != piece.color) {
                moves[count++] = (Position){new_row, new_col};
            }
        }
    }
    
    return count;
}

int get_king_moves(ChessGame *game, Position from, Position moves[]) {
    // Get standard moves first
    int count = get_king_moves_no_castling(game, from, moves);
    Piece piece = get_piece_at(game, from.row, from.col);
    
    // Castling moves
    if (!game->in_check[piece.color]) { // Cannot castle while in check
        if (piece.color == WHITE) {
            // White kingside castling (king moves to g1)
            if (!game->white_king_moved && !game->white_rook_h_moved &&
                from.row == 7 && from.col == 4 && // King is on e1
                !is_piece_at(game, 7, 5) && !is_piece_at(game, 7, 6) && // f1 and g1 are empty
                !is_square_attacked(game, (Position){7, 5}, BLACK) && // f1 not attacked
                !is_square_attacked(game, (Position){7, 6}, BLACK)) { // g1 not attacked
                moves[count++] = (Position){7, 6}; // g1
            }
            
            // White queenside castling (king moves to c1)
            if (!game->white_king_moved && !game->white_rook_a_moved &&
                from.row == 7 && from.col == 4 && // King is on e1
                !is_piece_at(game, 7, 1) && !is_piece_at(game, 7, 2) && !is_piece_at(game, 7, 3) && // b1, c1, d1 are empty
                !is_square_attacked(game, (Position){7, 2}, BLACK) && // c1 not attacked
                !is_square_attacked(game, (Position){7, 3}, BLACK)) { // d1 not attacked
                moves[count++] = (Position){7, 2}; // c1
            }
        } else { // BLACK
            // Black kingside castling (king moves to g8)
            if (!game->black_king_moved && !game->black_rook_h_moved &&
                from.row == 0 && from.col == 4 && // King is on e8
                !is_piece_at(game, 0, 5) && !is_piece_at(game, 0, 6) && // f8 and g8 are empty
                !is_square_attacked(game, (Position){0, 5}, WHITE) && // f8 not attacked
                !is_square_attacked(game, (Position){0, 6}, WHITE)) { // g8 not attacked
                moves[count++] = (Position){0, 6}; // g8
            }
            
            // Black queenside castling (king moves to c8)
            if (!game->black_king_moved && !game->black_rook_a_moved &&
                from.row == 0 && from.col == 4 && // King is on e8
                !is_piece_at(game, 0, 1) && !is_piece_at(game, 0, 2) && !is_piece_at(game, 0, 3) && // b8, c8, d8 are empty
                !is_square_attacked(game, (Position){0, 2}, WHITE) && // c8 not attacked
                !is_square_attacked(game, (Position){0, 3}, WHITE)) { // d8 not attacked
                moves[count++] = (Position){0, 2}; // c8
            }
        }
    }
    
    return count;
}

/**
 * Generate all possible moves for a piece at the specified position
 * This is the main move generation function that delegates to piece-specific
 * movement functions. It validates the piece exists and belongs to the current player.
 * 
 * @param game Current game state
 * @param from Position of piece to generate moves for
 * @param moves Array to store generated moves (caller must provide sufficient space)
 * @return Number of possible moves found (0 if piece invalid or no moves available)
 */
int get_possible_moves(ChessGame *game, Position from, Position moves[]) {
    if (!is_valid_position(from.row, from.col) || !is_piece_at(game, from.row, from.col)) {
        return 0;
    }
    
    Piece piece = get_piece_at(game, from.row, from.col);
    
    if (piece.color != game->current_player) {
        return 0;
    }
    
    switch (piece.type) {
        case PAWN:   return get_pawn_moves(game, from, moves);
        case ROOK:   return get_rook_moves(game, from, moves);
        case KNIGHT: return get_knight_moves(game, from, moves);
        case BISHOP: return get_bishop_moves(game, from, moves);
        case QUEEN:  return get_queen_moves(game, from, moves);
        case KING:   return get_king_moves(game, from, moves);
        default:     return 0;
    }
}

bool is_square_attacked(ChessGame *game, Position pos, Color by_color) {
    for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
            if (is_piece_at(game, row, col)) {
                Piece piece = get_piece_at(game, row, col);
                if (piece.color == by_color) {
                    Position moves[64];
                    Color original_player = game->current_player;
                    game->current_player = by_color;
                    
                    int move_count;
                    // Use special king function to avoid infinite recursion
                    if (piece.type == KING) {
                        move_count = get_king_moves_no_castling(game, (Position){row, col}, moves);
                    } else {
                        move_count = get_possible_moves(game, (Position){row, col}, moves);
                    }
                    
                    game->current_player = original_player;
                    
                    for (int i = 0; i < move_count; i++) {
                        if (moves[i].row == pos.row && moves[i].col == pos.col) {
                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}

bool is_in_check(ChessGame *game, Color color) {
    Position king_pos = (color == WHITE) ? game->white_king_pos : game->black_king_pos;
    return is_square_attacked(game, king_pos, (color == WHITE) ? BLACK : WHITE);
}

bool would_be_in_check_after_move(ChessGame *game, Position from, Position to) {
    Piece moving_piece = get_piece_at(game, from.row, from.col);
    Piece captured_piece = get_piece_at(game, to.row, to.col);
    
    set_piece_at(game, to.row, to.col, moving_piece);
    clear_position(game, from.row, from.col);
    
    if (moving_piece.type == KING) {
        if (moving_piece.color == WHITE) {
            game->white_king_pos = to;
        } else {
            game->black_king_pos = to;
        }
    }
    
    bool in_check = is_in_check(game, moving_piece.color);
    
    set_piece_at(game, from.row, from.col, moving_piece);
    set_piece_at(game, to.row, to.col, captured_piece);
    
    if (moving_piece.type == KING) {
        if (moving_piece.color == WHITE) {
            game->white_king_pos = from;
        } else {
            game->black_king_pos = from;
        }
    }
    
    return in_check;
}

bool is_valid_move(ChessGame *game, Position from, Position to) {
    Position possible_moves[64];
    int move_count = get_possible_moves(game, from, possible_moves);
    
    for (int i = 0; i < move_count; i++) {
        if (possible_moves[i].row == to.row && possible_moves[i].col == to.col) {
            return !would_be_in_check_after_move(game, from, to);
        }
    }
    
    return false;
}

/**
 * Execute a chess move after validation
 * Handles piece movement, capture tracking, king position updates,
 * turn switching, and check status updates. This is the main function
 * for actually executing moves on the board.
 * 
 * @param game Current game state (will be modified)
 * @param from Starting position of the move
 * @param to Destination position of the move
 * @return true if move was executed successfully, false if move is invalid
 */
bool make_move(ChessGame *game, Position from, Position to) {
    if (!is_valid_move(game, from, to)) {
        return false;
    }

    // Check if this is a pawn promotion move
    if (is_promotion_move(game, from, to)) {
        PieceType promotion_choice = get_promotion_choice();
        return make_promotion_move(game, from, to, promotion_choice);
    }

    Piece moving_piece = get_piece_at(game, from.row, from.col);
    Piece captured_piece = get_piece_at(game, to.row, to.col);
    bool is_en_passant_capture = false;
    
    // Check if this is an en passant capture
    if (moving_piece.type == PAWN && game->en_passant_available &&
        to.row == game->en_passant_target.row && to.col == game->en_passant_target.col &&
        captured_piece.type == EMPTY) {
        // This is an en passant capture - remove the captured pawn
        int captured_pawn_row = (moving_piece.color == WHITE) ? to.row + 1 : to.row - 1;
        captured_piece = get_piece_at(game, captured_pawn_row, to.col);
        clear_position(game, captured_pawn_row, to.col);
        is_en_passant_capture = true;
    }
    
    if (captured_piece.type != EMPTY) {
        if (captured_piece.color == WHITE) {
            game->black_captured.captured_pieces[game->black_captured.count++] = captured_piece;
        } else {
            game->white_captured.captured_pieces[game->white_captured.count++] = captured_piece;
        }
    }
    
    set_piece_at(game, to.row, to.col, moving_piece);
    clear_position(game, from.row, from.col);
    
    if (moving_piece.type == KING) {
        // Check if this is a castling move (king moves 2 squares horizontally)
        if (abs(to.col - from.col) == 2) {
            // This is castling - also move the rook
            if (moving_piece.color == WHITE) {
                if (to.col == 6) {
                    // White kingside castling: move rook from h1 to f1
                    Piece rook = get_piece_at(game, 7, 7);
                    set_piece_at(game, 7, 5, rook);
                    clear_position(game, 7, 7);
                    game->white_rook_h_moved = true;
                } else if (to.col == 2) {
                    // White queenside castling: move rook from a1 to d1
                    Piece rook = get_piece_at(game, 7, 0);
                    set_piece_at(game, 7, 3, rook);
                    clear_position(game, 7, 0);
                    game->white_rook_a_moved = true;
                }
            } else { // BLACK
                if (to.col == 6) {
                    // Black kingside castling: move rook from h8 to f8
                    Piece rook = get_piece_at(game, 0, 7);
                    set_piece_at(game, 0, 5, rook);
                    clear_position(game, 0, 7);
                    game->black_rook_h_moved = true;
                } else if (to.col == 2) {
                    // Black queenside castling: move rook from a8 to d8
                    Piece rook = get_piece_at(game, 0, 0);
                    set_piece_at(game, 0, 3, rook);
                    clear_position(game, 0, 0);
                    game->black_rook_a_moved = true;
                }
            }
        }
        
        if (moving_piece.color == WHITE) {
            game->white_king_pos = to;
            game->white_king_moved = true;
        } else {
            game->black_king_pos = to;
            game->black_king_moved = true;
        }
    }
    
    if (moving_piece.type == ROOK) {
        if (moving_piece.color == WHITE) {
            if (from.row == 7 && from.col == 0) game->white_rook_a_moved = true;
            if (from.row == 7 && from.col == 7) game->white_rook_h_moved = true;
        } else {
            if (from.row == 0 && from.col == 0) game->black_rook_a_moved = true;
            if (from.row == 0 && from.col == 7) game->black_rook_h_moved = true;
        }
    }
    
    // Update FEN move counters according to chess rules
    bool was_capture = (captured_piece.type != EMPTY || is_en_passant_capture);
    bool was_pawn_move = (moving_piece.type == PAWN);
    
    if (was_pawn_move || was_capture) {
        // Halfmove clock resets to 0 on pawn moves or captures
        game->halfmove_clock = 0;
    } else {
        // Otherwise increment halfmove clock
        game->halfmove_clock++;
    }
    
    // Fullmove number increments after Black's move (when switching from BLACK to WHITE)
    if (game->current_player == BLACK) {
        game->fullmove_number++;
    }
    
    // Update en passant state
    game->en_passant_available = false;
    game->en_passant_target.row = -1;
    game->en_passant_target.col = -1;
    
    // Check if this pawn move creates an en passant opportunity
    if (moving_piece.type == PAWN && abs(to.row - from.row) == 2) {
        // Pawn moved two squares, set en passant target square
        game->en_passant_available = true;
        game->en_passant_target.row = (from.row + to.row) / 2;  // Square between from and to
        game->en_passant_target.col = to.col;
    }
    
    game->current_player = (game->current_player == WHITE) ? BLACK : WHITE;
    
    game->in_check[WHITE] = is_in_check(game, WHITE);
    game->in_check[BLACK] = is_in_check(game, BLACK);
    
    return true;
}

void print_captured_pieces(CapturedPieces *captured, const char* color_code, const char* player_name, ChessGame* game) {
    // Determine if this is White or Black based on player name
    bool is_white = (strcmp(player_name, "White") == 0);

    // Display time if time controls are enabled
    if (is_time_control_enabled(game)) {
        int current_time;
        if (is_white) {
            current_time = game->timer.white_time_seconds;
            // If White is currently moving and timer is active, subtract elapsed time
            if (game->current_player == WHITE && game->timer.timing_active) {
                time_t now = time(NULL);
                int elapsed = (int)(now - game->timer.move_start_time);
                current_time -= elapsed;
                if (current_time < 0) current_time = 0;
            }
        } else {
            current_time = game->timer.black_time_seconds;
            // If Black is currently moving and timer is active, subtract elapsed time
            if (game->current_player == BLACK && game->timer.timing_active) {
                time_t now = time(NULL);
                int elapsed = (int)(now - game->timer.move_start_time);
                current_time -= elapsed;
                if (current_time < 0) current_time = 0;
            }
        }

        printf("%s%s: %s%s | Captured: ", color_code, player_name,
               get_remaining_time_string(current_time), "\033[0m");
    } else {
        printf("%s%s Captured:%s ", color_code, player_name, "\033[0m");
    }

    if (captured->count == 0) {
        printf("%sNone%s", color_code, "\033[0m");
    } else {
        for (int i = 0; i < captured->count; i++) {
            printf("%c ", piece_to_char(captured->captured_pieces[i]));  // All captured pieces in normal black text
        }
    }
    printf("\n");
}

Position char_to_position(char *input) {
    Position pos = {-1, -1};
    
    if (strlen(input) != 2) return pos;
    
    char col_char = input[0];
    char row_char = input[1];
    
    if (col_char >= 'a' && col_char <= 'h' && row_char >= '1' && row_char <= '8') {
        pos.col = col_char - 'a';
        pos.row = '8' - row_char;
    }
    
    return pos;
}

char *position_to_string(Position pos) {
    static char str[3];
    str[0] = 'a' + pos.col;
    str[1] = '8' - pos.row;
    str[2] = '\0';
    return str;
}




/* ========================================================================
 * FEN PARSING AND BOARD SETUP FUNCTIONS
 * Functions for parsing FEN (Forsyth-Edwards Notation) strings and
 * setting up custom board positions for the SETUP command
 * ======================================================================== */

/**
 * Convert character to piece type (helper function for FEN parsing)
 * 
 * @param c Character representing piece (lowercase)
 * @return PieceType corresponding to character
 */
PieceType char_to_piece_type(char c) {
    switch (tolower(c)) {
        case 'p': return PAWN;
        case 'r': return ROOK;
        case 'n': return KNIGHT;
        case 'b': return BISHOP;
        case 'q': return QUEEN;
        case 'k': return KING;
        default:  return EMPTY;
    }
}

/**
 * Validate FEN string format
 * Performs basic validation of FEN string structure and content
 * 
 * @param fen FEN string to validate
 * @return true if FEN appears valid, false otherwise
 */
bool validate_fen_string(const char* fen) {
    if (!fen || strlen(fen) == 0) return false;
    
    // Count slashes (should be 7 for 8 ranks)
    int slash_count = 0;
    int board_chars = 0;
    const char* ptr = fen;
    
    // Parse board section (until first space)
    while (*ptr && *ptr != ' ') {
        if (*ptr == '/') {
            slash_count++;
        } else if (isdigit(*ptr)) {
            int empty_squares = *ptr - '0';
            if (empty_squares < 1 || empty_squares > 8) return false;
            board_chars += empty_squares;
        } else if (strchr("rnbqkpRNBQKP", *ptr)) {
            board_chars++;
        } else {
            return false; // Invalid character
        }
        ptr++;
    }
    
    // Should have exactly 7 slashes and 64 board positions
    if (slash_count != 7 || board_chars != 64) return false;
    
    // Should have at least one space (separating board from other FEN components)
    if (*ptr != ' ') return false;
    
    return true;
}

/**
 * Calculate captured pieces by comparing current board to starting position
 * Determines which pieces are missing from their starting positions
 * and populates the captured pieces arrays accordingly
 *
 * @param game Game state with current board position
 */
void calculate_captured_pieces(ChessGame *game) {
    // Standard starting pieces count for each type and color
    int starting_counts[2][7] = {
        // WHITE: EMPTY, PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING
        {0, 8, 2, 2, 2, 1, 1},
        // BLACK: EMPTY, PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING
        {0, 8, 2, 2, 2, 1, 1}
    };

    // Count current pieces on board
    int current_counts[2][7] = {{0}};

    for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
            Piece piece = game->board[row][col];
            if (piece.type != EMPTY) {
                current_counts[piece.color][piece.type]++;
            }
        }
    }

    // Clear captured pieces arrays
    game->white_captured.count = 0;
    game->black_captured.count = 0;

    // Calculate captured pieces for each color
    for (int color = 0; color < 2; color++) {
        for (int piece_type = PAWN; piece_type <= KING; piece_type++) {
            int captured = starting_counts[color][piece_type] - current_counts[color][piece_type];

            // Add captured pieces to the appropriate array
            for (int i = 0; i < captured; i++) {
                Piece captured_piece = {piece_type, color};

                if (color == WHITE) {
                    // White piece was captured by Black
                    game->black_captured.captured_pieces[game->black_captured.count++] = captured_piece;
                } else {
                    // Black piece was captured by White
                    game->white_captured.captured_pieces[game->white_captured.count++] = captured_piece;
                }
            }
        }
    }
}

/**
 * Setup board from FEN string
 * Parses FEN string and configures game state accordingly
 * Updates board position, current player, king positions, and castling rights
 *
 * @param game Game state to modify
 * @param fen Valid FEN string
 * @return true if successful, false if parsing failed
 */
bool setup_board_from_fen(ChessGame *game, const char* fen) {
    if (!validate_fen_string(fen)) {
        return false;
    }
    
    // Initialize king positions to invalid values
    game->white_king_pos.row = -1;
    game->white_king_pos.col = -1;
    game->black_king_pos.row = -1;
    game->black_king_pos.col = -1;
    
    // Clear the board
    for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
            game->board[row][col].type = EMPTY;
            game->board[row][col].color = WHITE;
        }
    }
    
    // Parse board position
    int row = 0, col = 0;
    const char* ptr = fen;
    
    while (*ptr && *ptr != ' ' && row < BOARD_SIZE) {
        if (*ptr == '/') {
            row++;
            col = 0;
        } else if (isdigit(*ptr)) {
            col += (*ptr - '0');
        } else {
            PieceType piece_type = char_to_piece_type(tolower(*ptr));
            Color piece_color = isupper(*ptr) ? WHITE : BLACK;
            
            if (row < BOARD_SIZE && col < BOARD_SIZE) {
                game->board[row][col].type = piece_type;
                game->board[row][col].color = piece_color;
                
                // Track king positions for efficient check detection
                if (piece_type == KING) {
                    if (piece_color == WHITE) {
                        game->white_king_pos.row = row;
                        game->white_king_pos.col = col;
                    } else {
                        game->black_king_pos.row = row;
                        game->black_king_pos.col = col;
                    }
                }
            }
            col++;
        }
        ptr++;
    }
    
    // Parse active color (whose turn it is)
    if (*ptr == ' ') ptr++;
    if (*ptr == 'w' || *ptr == 'W') {
        game->current_player = WHITE;
    } else if (*ptr == 'b' || *ptr == 'B') {
        game->current_player = BLACK;
    } else {
        game->current_player = WHITE; // Default to white
    }
    
    // Skip to castling rights
    while (*ptr && *ptr != ' ') ptr++;
    if (*ptr == ' ') ptr++;
    
    // Parse castling rights and set movement flags accordingly
    game->white_king_moved = true;   // Assume moved unless castling available
    game->black_king_moved = true;   // Assume moved unless castling available
    game->white_rook_a_moved = true;
    game->white_rook_h_moved = true;
    game->black_rook_a_moved = true;
    game->black_rook_h_moved = true;
    
    while (*ptr && *ptr != ' ') {
        switch (*ptr) {
            case 'K': 
                game->white_king_moved = false;
                game->white_rook_h_moved = false;
                break;
            case 'Q':
                game->white_king_moved = false;
                game->white_rook_a_moved = false;
                break;
            case 'k':
                game->black_king_moved = false;
                game->black_rook_h_moved = false;
                break;
            case 'q':
                game->black_king_moved = false;
                game->black_rook_a_moved = false;
                break;
        }
        ptr++;
    }
    
    // Parse en passant target square
    while (*ptr && *ptr == ' ') ptr++;  // Skip spaces
    game->en_passant_available = false;
    game->en_passant_target.row = -1;
    game->en_passant_target.col = -1;
    
    if (*ptr && *ptr != '-' && *ptr != ' ') {
        // Parse en passant square (e.g., "e3" or "d6")
        if (*ptr >= 'a' && *ptr <= 'h') {
            char file = *ptr;
            ptr++;
            if (*ptr >= '1' && *ptr <= '8') {
                char rank = *ptr;
                game->en_passant_target.col = file - 'a';
                game->en_passant_target.row = '8' - rank;
                game->en_passant_available = true;
                ptr++;
            }
        }
    }
    // Skip any remaining characters in the en passant field
    while (*ptr && *ptr != ' ') ptr++;
    
    // Parse halfmove clock
    while (*ptr && *ptr == ' ') ptr++;  // Skip spaces
    if (*ptr && isdigit(*ptr)) {
        game->halfmove_clock = atoi(ptr);
        while (*ptr && isdigit(*ptr)) ptr++;  // Skip past the number
    } else {
        game->halfmove_clock = 0;  // Default value
    }
    
    // Parse fullmove number
    while (*ptr && *ptr == ' ') ptr++;  // Skip spaces
    if (*ptr && isdigit(*ptr)) {
        game->fullmove_number = atoi(ptr);
        while (*ptr && isdigit(*ptr)) ptr++;  // Skip past the number
    } else {
        game->fullmove_number = 1;  // Default value
    }
    
    // Calculate captured pieces based on current board position
    calculate_captured_pieces(game);
    
    // Verify both kings were found during parsing
    if (game->white_king_pos.row == -1 || game->black_king_pos.row == -1) {
        return false;  // Invalid FEN - missing king(s)
    }
    
    // Update check status  
    game->in_check[WHITE] = is_in_check(game, WHITE);
    game->in_check[BLACK] = is_in_check(game, BLACK);
    
    
    return true;
}

/**
 * is_fifty_move_rule_draw() - Check if 50-move rule draw condition is met
 *
 * The 50-move rule states that a player can claim a draw if 50 moves have been
 * made without a pawn move or capture. Since halfmove_clock counts halfmoves,
 * the draw condition is met when halfmove_clock reaches 100 (50 full moves).
 *
 * @param game: Pointer to ChessGame structure containing current game state
 * @return: true if 50-move rule draw condition is met, false otherwise
 *
 * Implementation notes:
 * - Uses the existing halfmove_clock field which is automatically maintained
 *   by the make_move() function according to chess rules
 * - Halfmove clock resets to 0 on any pawn move or capture
 * - Increments by 1 on all other moves
 * - 50 full moves without pawn move/capture = 100 halfmoves
 */
bool is_fifty_move_rule_draw(ChessGame *game) {
    return game->halfmove_clock >= 100;
}

/**
 * convert_fen_to_pgn_string() - Convert FEN log file to PGN format string
 *
 * This function reads a FEN log file (containing one FEN position per line)
 * and converts it to PGN (Portable Game Notation) format as a string.
 * Used for real-time PGN display during gameplay.
 *
 * @param fen_filename: Path to the FEN log file to convert
 * @return: Dynamically allocated string containing PGN notation, or NULL on error
 *          Caller must free() the returned string
 *
 * Implementation notes:
 * - Reuses core logic from fen_to_pgn.c utility but returns string instead of writing file
 * - Handles all chess moves including castling, en passant, captures, and promotions
 * - Creates properly formatted PGN with headers and algebraic notation
 * - Memory management: Returns malloc'd string that caller must free
 * - Error handling: Returns NULL if file cannot be opened or memory allocation fails
 */
char* convert_fen_to_pgn_string(const char* fen_filename) {
    #define MAX_LINE_LENGTH 256
    #define MAX_MOVES 1000
    #define MAX_PGN_SIZE 8192

    // PGN move structure - simplified version of fen_to_pgn.c structure
    typedef struct {
        int from_row, from_col, to_row, to_col;
        PieceType piece_type;
        Color piece_color;
        PieceType captured_piece;
        int is_castle;
        int is_en_passant;
        PieceType promotion_piece;
        int is_check;
        int is_checkmate;
    } PgnMove;

    // Helper structure for board comparison
    typedef struct {
        int row, col;
        PieceType type;
        Color color;
    } PieceChange;

    FILE* input_file = fopen(fen_filename, "r");
    if (!input_file) {
        return NULL;  // Cannot open file
    }

    // Allocate string buffer for PGN output
    char* pgn_string = malloc(MAX_PGN_SIZE);
    if (!pgn_string) {
        fclose(input_file);
        return NULL;  // Memory allocation failed
    }

    // Initialize PGN string with headers
    time_t now = time(NULL);
    struct tm* timeinfo = localtime(&now);
    char date_str[20];
    strftime(date_str, sizeof(date_str), "%Y.%m.%d", timeinfo);

    snprintf(pgn_string, MAX_PGN_SIZE,
        "[Event \"Current Game\"]\n"
        "[Site \"Chess Game\"]\n"
        "[Date \"%s\"]\n"
        "[Round \"?\"]\n"
        "[White \"Player\"]\n"
        "[Black \"AI\"]\n"
        "[Result \"*\"]\n\n", date_str);

    // Initialize board arrays and move tracking
    Piece prev_board[BOARD_SIZE][BOARD_SIZE];
    Piece curr_board[BOARD_SIZE][BOARD_SIZE];
    PgnMove moves[MAX_MOVES];
    int move_count = 0;

    char line[MAX_LINE_LENGTH];
    bool first_position = true;

    // Read FEN positions and convert to moves
    while (fgets(line, sizeof(line), input_file) && move_count < MAX_MOVES) {
        // Remove newline and skip empty lines
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) == 0) continue;

        // Parse FEN position into current board
        memset(curr_board, 0, sizeof(curr_board));

        // Simple FEN parsing (board position only - sufficient for move detection)
        int row = 0, col = 0;
        const char* ptr = line;

        while (*ptr && *ptr != ' ') {
            if (*ptr == '/') {
                row++;
                col = 0;
            } else if (isdigit(*ptr)) {
                col += (*ptr - '0');
            } else {
                curr_board[row][col].type = char_to_piece_type(tolower(*ptr));
                curr_board[row][col].color = isupper(*ptr) ? WHITE : BLACK;
                col++;
            }
            ptr++;
        }

        if (first_position) {
            // First position is starting point
            memcpy(prev_board, curr_board, sizeof(curr_board));
            first_position = false;
            continue;
        }

        // Compare boards to find the move
        PgnMove move = {0};

        // Find all pieces that disappeared and appeared (reusing fen_to_pgn.c logic)
        PieceChange disappeared[64], appeared[64];
        int disappeared_count = 0, appeared_count = 0;

        // Find pieces that disappeared from prev_board
        for (int i = 0; i < BOARD_SIZE; i++) {
            for (int j = 0; j < BOARD_SIZE; j++) {
                if (prev_board[i][j].type != EMPTY &&
                    (curr_board[i][j].type != prev_board[i][j].type ||
                     curr_board[i][j].color != prev_board[i][j].color)) {
                    disappeared[disappeared_count].row = i;
                    disappeared[disappeared_count].col = j;
                    disappeared[disappeared_count].type = prev_board[i][j].type;
                    disappeared[disappeared_count].color = prev_board[i][j].color;
                    disappeared_count++;
                }
            }
        }

        // Find pieces that appeared on curr_board
        for (int i = 0; i < BOARD_SIZE; i++) {
            for (int j = 0; j < BOARD_SIZE; j++) {
                if (curr_board[i][j].type != EMPTY &&
                    (prev_board[i][j].type != curr_board[i][j].type ||
                     prev_board[i][j].color != curr_board[i][j].color)) {
                    appeared[appeared_count].row = i;
                    appeared[appeared_count].col = j;
                    appeared[appeared_count].type = curr_board[i][j].type;
                    appeared[appeared_count].color = curr_board[i][j].color;
                    appeared_count++;
                }
            }
        }

        // Check for castling first
        bool move_found = false;
        for (int i = 0; i < BOARD_SIZE && !move_found; i++) {
            for (int j = 0; j < BOARD_SIZE && !move_found; j++) {
                if (prev_board[i][j].type == KING && curr_board[i][j].type != KING) {
                    // King disappeared - look for it 2 squares away (castling)
                    for (int ni = 0; ni < BOARD_SIZE; ni++) {
                        for (int nj = 0; nj < BOARD_SIZE; nj++) {
                            if (curr_board[ni][nj].type == KING &&
                                curr_board[ni][nj].color == prev_board[i][j].color &&
                                prev_board[ni][nj].type != KING &&
                                ni == i && abs(nj - j) == 2) {

                                move.from_row = i; move.from_col = j;
                                move.to_row = ni; move.to_col = nj;
                                move.piece_type = KING;
                                move.piece_color = prev_board[i][j].color;
                                move.is_castle = 1;
                                moves[move_count++] = move;
                                move_found = true;
                                break;
                            }
                        }
                    }
                }
            }
        }

        // If not castling, find normal move
        if (!move_found) {
            for (int d = 0; d < disappeared_count && !move_found; d++) {
                for (int a = 0; a < appeared_count && !move_found; a++) {
                    if (disappeared[d].type == appeared[a].type &&
                        disappeared[d].color == appeared[a].color) {

                        move.from_row = disappeared[d].row;
                        move.from_col = disappeared[d].col;
                        move.to_row = appeared[a].row;
                        move.to_col = appeared[a].col;
                        move.piece_type = disappeared[d].type;
                        move.piece_color = disappeared[d].color;

                        // Check for capture
                        if (prev_board[appeared[a].row][appeared[a].col].type != EMPTY) {
                            move.captured_piece = prev_board[appeared[a].row][appeared[a].col].type;
                        }

                        // Check for en passant
                        if (move.piece_type == PAWN &&
                            move.from_col != move.to_col &&
                            prev_board[move.to_row][move.to_col].type == EMPTY) {
                            move.is_en_passant = 1;
                        }

                        // Check for promotion
                        if (move.piece_type == PAWN &&
                            ((move.piece_color == WHITE && move.to_row == 0) ||
                             (move.piece_color == BLACK && move.to_row == 7)) &&
                            curr_board[move.to_row][move.to_col].type != PAWN) {
                            move.promotion_piece = curr_board[move.to_row][move.to_col].type;
                        }

                        moves[move_count++] = move;
                        move_found = true;
                    }
                }
            }
        }

        // Copy current board to previous for next iteration
        memcpy(prev_board, curr_board, sizeof(curr_board));
    }

    fclose(input_file);

    // Convert moves to algebraic notation and append to PGN string
    size_t current_len = strlen(pgn_string);
    char* pos = pgn_string + current_len;
    size_t remaining = MAX_PGN_SIZE - current_len;

    for (int i = 0; i < move_count && remaining > 50; i++) {
        if (i % 2 == 0) {
            int written = snprintf(pos, remaining, "%d. ", (i / 2) + 1);
            pos += written;
            remaining -= written;
        }

        // Convert move to algebraic notation
        char algebraic[10] = "";

        if (moves[i].is_castle) {
            strcpy(algebraic, moves[i].to_col > moves[i].from_col ? "O-O" : "O-O-O");
        } else if (moves[i].piece_type == PAWN) {
            char from_file = 'a' + moves[i].from_col;
            char to_file = 'a' + moves[i].to_col;
            char to_rank = '8' - moves[i].to_row;

            if (moves[i].captured_piece != EMPTY || moves[i].is_en_passant) {
                if (moves[i].promotion_piece != EMPTY) {
                    char promo_symbols[] = " PRNBQK";
                    snprintf(algebraic, sizeof(algebraic), "%cx%c%c=%c",
                            from_file, to_file, to_rank, promo_symbols[moves[i].promotion_piece]);
                } else {
                    snprintf(algebraic, sizeof(algebraic), "%cx%c%c",
                            from_file, to_file, to_rank);
                }
            } else {
                if (moves[i].promotion_piece != EMPTY) {
                    char promo_symbols[] = " PRNBQK";
                    snprintf(algebraic, sizeof(algebraic), "%c%c=%c",
                            to_file, to_rank, promo_symbols[moves[i].promotion_piece]);
                } else {
                    snprintf(algebraic, sizeof(algebraic), "%c%c", to_file, to_rank);
                }
            }
        } else {
            // Piece move
            char piece_symbols[] = " PRNBQK";  // Fixed: EMPTY=0, PAWN=1, ROOK=2, KNIGHT=3, BISHOP=4, QUEEN=5, KING=6
            char piece_symbol = piece_symbols[moves[i].piece_type];
            char to_file = 'a' + moves[i].to_col;
            char to_rank = '8' - moves[i].to_row;

            if (moves[i].captured_piece != EMPTY) {
                snprintf(algebraic, sizeof(algebraic), "%cx%c%c",
                        piece_symbol, to_file, to_rank);
            } else {
                snprintf(algebraic, sizeof(algebraic), "%c%c%c",
                        piece_symbol, to_file, to_rank);
            }
        }

        int written = snprintf(pos, remaining, "%s ", algebraic);
        pos += written;
        remaining -= written;

        // Line break every 6 moves for readability
        if ((i + 1) % 6 == 0 && remaining > 5) {
            strcpy(pos, "\n");
            pos++;
            remaining--;
        }
    }

    // Add game result
    if (remaining > 5) {
        strcat(pos, "*\n");
    }

    return pgn_string;
}

/**
 * Check if a pawn move requires promotion
 * Promotion occurs when a pawn reaches the opposite end of the board
 *
 * @param game Current game state
 * @param from Starting position of the move
 * @param to Destination position of the move
 * @return true if this move requires pawn promotion
 */
bool is_promotion_move(ChessGame *game, Position from, Position to) {
    Piece moving_piece = get_piece_at(game, from.row, from.col);

    if (moving_piece.type != PAWN) {
        return false;
    }

    // White pawns promote on row 0 (8th rank), Black pawns promote on row 7 (1st rank)
    int promotion_row = (moving_piece.color == WHITE) ? 0 : 7;

    return (to.row == promotion_row);
}

/**
 * Validate that a piece type is legal for promotion
 * Pawns can only promote to QUEEN, ROOK, BISHOP, or KNIGHT
 *
 * @param piece_type The piece type to validate
 * @return true if the piece type is valid for promotion
 */
bool is_valid_promotion_piece(PieceType piece_type) {
    return (piece_type == QUEEN || piece_type == ROOK ||
            piece_type == BISHOP || piece_type == KNIGHT);
}

/**
 * Interactive UI for selecting promotion piece
 * Prompts the user to choose which piece to promote the pawn to
 *
 * @return The selected piece type (QUEEN, ROOK, BISHOP, or KNIGHT)
 */
PieceType get_promotion_choice() {
    char input[10];
    PieceType choice;

    printf("\nPawn promotion! Choose a piece to promote to:\n");
    printf("Q - Queen (most powerful)\n");
    printf("R - Rook\n");
    printf("B - Bishop\n");
    printf("N - Knight\n");
    printf("Enter choice (Q/R/B/N): ");

    while (true) {
        if (fgets(input, sizeof(input), stdin) != NULL) {
            char c = toupper(input[0]);

            switch (c) {
                case 'Q':
                    choice = QUEEN;
                    printf("Promoting to Queen!\n");
                    return choice;
                case 'R':
                    choice = ROOK;
                    printf("Promoting to Rook!\n");
                    return choice;
                case 'B':
                    choice = BISHOP;
                    printf("Promoting to Bishop!\n");
                    return choice;
                case 'N':
                    choice = KNIGHT;
                    printf("Promoting to Knight!\n");
                    return choice;
                default:
                    printf("Invalid choice. Please enter Q, R, B, or N: ");
                    break;
            }
        }
    }
}

/**
 * Execute a pawn promotion move
 * Performs the move and promotes the pawn to the specified piece type
 *
 * @param game Current game state
 * @param from Starting position of the move
 * @param to Destination position of the move
 * @param promotion_type Type of piece to promote to
 * @return true if the move was successful
 */
bool make_promotion_move(ChessGame *game, Position from, Position to, PieceType promotion_type) {
    if (!is_promotion_move(game, from, to)) {
        return false;
    }

    if (!is_valid_promotion_piece(promotion_type)) {
        return false;
    }

    if (!is_valid_move(game, from, to)) {
        return false;
    }

    Piece moving_piece = get_piece_at(game, from.row, from.col);
    Piece captured_piece = get_piece_at(game, to.row, to.col);

    // Handle capture if there's a piece at destination
    if (captured_piece.type != EMPTY) {
        if (captured_piece.color == WHITE) {
            game->black_captured.captured_pieces[game->black_captured.count++] = captured_piece;
        } else {
            game->white_captured.captured_pieces[game->white_captured.count++] = captured_piece;
        }
    }

    // Create the promoted piece
    Piece promoted_piece = {promotion_type, moving_piece.color};

    // Place promoted piece at destination and clear original position
    set_piece_at(game, to.row, to.col, promoted_piece);
    clear_position(game, from.row, from.col);

    // Update FEN move counters - pawn move resets halfmove clock
    game->halfmove_clock = 0;

    // Fullmove number increments after Black's move
    if (game->current_player == BLACK) {
        game->fullmove_number++;
    }

    // Clear en passant state (promotion can't create en passant)
    game->en_passant_available = false;
    game->en_passant_target.row = -1;
    game->en_passant_target.col = -1;

    // Switch players
    game->current_player = (game->current_player == WHITE) ? BLACK : WHITE;

    // Update check status
    game->in_check[WHITE] = is_in_check(game, WHITE);
    game->in_check[BLACK] = is_in_check(game, BLACK);

    return true;
}

/**
 * Execute a move from a Move structure
 * Handles both regular moves and AI promotion moves without user prompts
 *
 * @param game Current game state
 * @param move Move structure containing all move information
 * @return true if the move was successful
 */
bool execute_move(ChessGame *game, Move move) {
    // If this is a promotion move with a predetermined piece (from AI)
    if (move.is_promotion && move.promotion_piece != EMPTY) {
        return make_promotion_move(game, move.from, move.to, move.promotion_piece);
    }

    // For regular moves (including human promotions handled by make_move)
    return make_move(game, move.from, move.to);
}

/**
 * Parse time control string format (xx/yy or xx/yy/zz/ww)
 *
 * @param time_str String in format "minutes/increment" or "white_min/white_inc/black_min/black_inc"
 * @param tc TimeControl structure to populate
 * @return true if parsing was successful, false if invalid format
 */
bool parse_time_control(const char* time_str, TimeControl* tc) {
    if (!time_str || !tc) {
        return false;
    }

    // Count slashes to determine format
    int slash_count = 0;
    for (const char* p = time_str; *p; p++) {
        if (*p == '/') slash_count++;
    }

    if (slash_count == 1) {
        // Format: xx/yy (same time controls for both players)
        const char* slash = strchr(time_str, '/');
        int minutes = atoi(time_str);
        int increment = atoi(slash + 1);

        // Validate ranges
        if (minutes < 0 || increment < 0 || minutes > 999 || increment > 999) {
            return false;
        }

        // Set same time controls for both players
        tc->white_minutes = minutes;
        tc->white_increment = increment;
        tc->black_minutes = minutes;
        tc->black_increment = increment;
        tc->enabled = (minutes > 0 || increment > 0);

    } else if (slash_count == 3) {
        // Format: xx/yy/zz/ww (different time controls for each player)
        char temp_str[64];
        strncpy(temp_str, time_str, sizeof(temp_str) - 1);
        temp_str[sizeof(temp_str) - 1] = '\0';

        char* token = strtok(temp_str, "/");
        if (!token) return false;
        int white_minutes = atoi(token);

        token = strtok(NULL, "/");
        if (!token) return false;
        int white_increment = atoi(token);

        token = strtok(NULL, "/");
        if (!token) return false;
        int black_minutes = atoi(token);

        token = strtok(NULL, "/");
        if (!token) return false;
        int black_increment = atoi(token);

        // Validate ranges
        if (white_minutes < 0 || white_increment < 0 || black_minutes < 0 || black_increment < 0 ||
            white_minutes > 999 || white_increment > 999 || black_minutes > 999 || black_increment > 999) {
            return false;
        }

        // Set different time controls for each player
        tc->white_minutes = white_minutes;
        tc->white_increment = white_increment;
        tc->black_minutes = black_minutes;
        tc->black_increment = black_increment;
        tc->enabled = (white_minutes > 0 || white_increment > 0 || black_minutes > 0 || black_increment > 0);

    } else {
        // Invalid format
        return false;
    }

    return true;
}

/**
 * Initialize game timer with given time control settings
 *
 * @param game Game state to initialize
 * @param time_control Time control settings
 */
void init_game_timer(ChessGame* game, TimeControl* time_control) {
    if (!game || !time_control) {
        return;
    }

    game->time_control = *time_control;

    if (time_control->enabled) {
        // Convert minutes to seconds for both players (can be different now)
        game->timer.white_time_seconds = time_control->white_minutes * 60;
        game->timer.black_time_seconds = time_control->black_minutes * 60;
        game->timer.timing_active = false;
        game->timer.move_start_time = 0;
        game->timer.timer_player = WHITE; // Initialize to WHITE (will be set properly on first start)
    } else {
        // Disabled time controls
        game->timer.white_time_seconds = 0;
        game->timer.black_time_seconds = 0;
        game->timer.timing_active = false;
        game->timer.move_start_time = 0;
        game->timer.timer_player = WHITE;
    }
}

/**
 * Start timing the current player's move
 *
 * @param game Game state
 */
void start_move_timer(ChessGame* game) {
    if (!game || !game->time_control.enabled) {
        return;
    }

    // Only start timer if not already active for this player
    if (!game->timer.timing_active || game->timer.timer_player != game->current_player) {
        game->timer.timing_active = true;
        game->timer.timer_player = game->current_player;
        game->timer.move_start_time = time(NULL);
    }
}

/**
 * Stop timing and apply increment to current player
 *
 * @param game Game state
 */
void stop_move_timer(ChessGame* game) {
    if (!game || !game->time_control.enabled || !game->timer.timing_active) {
        return;
    }

    time_t now = time(NULL);
    int elapsed = (int)(now - game->timer.move_start_time);

    // Subtract elapsed time from the player who was being timed (timer_player)
    if (game->timer.timer_player == WHITE) {
        game->timer.white_time_seconds -= elapsed;
        // Add White's increment
        game->timer.white_time_seconds += game->time_control.white_increment;
        // Ensure time doesn't go below 0
        if (game->timer.white_time_seconds < 0) {
            game->timer.white_time_seconds = 0;
        }
    } else {
        game->timer.black_time_seconds -= elapsed;
        // Add Black's increment
        game->timer.black_time_seconds += game->time_control.black_increment;
        // Ensure time doesn't go below 0
        if (game->timer.black_time_seconds < 0) {
            game->timer.black_time_seconds = 0;
        }
    }

    game->timer.timing_active = false;
    game->timer.move_start_time = 0;
}

/**
 * Format remaining time as MM:SS string
 *
 * @param seconds Time in seconds
 * @return Static string with formatted time (do not free)
 */
char* get_remaining_time_string(int seconds) {
    static char time_str[16];

    if (seconds < 0) {
        seconds = 0;
    }

    int minutes = seconds / 60;
    int secs = seconds % 60;
    snprintf(time_str, sizeof(time_str), "%d:%02d", minutes, secs);

    return time_str;
}

/**
 * Check if either player has run out of time (time forfeit)
 *
 * @param game Game state
 * @return true if a player has forfeited on time
 */
bool check_time_forfeit(ChessGame* game) {
    if (!game || !game->time_control.enabled) {
        return false;
    }

    // Update active timer player's time if timer is active
    if (game->timer.timing_active) {
        time_t now = time(NULL);
        int elapsed = (int)(now - game->timer.move_start_time);

        if (game->timer.timer_player == WHITE) {
            return (game->timer.white_time_seconds - elapsed) <= 0;
        } else {
            return (game->timer.black_time_seconds - elapsed) <= 0;
        }
    }

    // Check stored times
    return (game->timer.white_time_seconds <= 0 || game->timer.black_time_seconds <= 0);
}

/**
 * Check if time controls are currently enabled
 *
 * @param game Game state
 * @return true if time controls are active
 */
bool is_time_control_enabled(ChessGame* game) {
    return (game && game->time_control.enabled);
}