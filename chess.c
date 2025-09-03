/**
 * CHESS.C - Core Chess Game Implementation
 * 
 * This file implements all the core chess game logic including:
 * - Board initialization and management
 * - Piece movement rules and validation
 * - Check/checkmate detection
 * - Move generation for all piece types
 * - Game state management and undo system
 * - Utility functions for position handling
 * 
 * The chess engine supports:
 * - Standard piece movements (pawn, rook, knight, bishop, queen, king)
 * - Check detection and prevention of illegal moves
 * - Capture tracking
 * - Single-level undo functionality
 * - Game state persistence
 * 
 * Future enhancements will add:
 * - Castling (kingside and queenside)
 * - En passant captures
 * - Pawn promotion
 */

#include "chess.h"

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
    
    // Initialize castling eligibility flags (for future castling implementation)
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
    game->can_undo = false;     // No moves to undo yet
    
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
            
            for (int i = 0; i < move_count; i++) {
                if (possible_moves[i].row == row && possible_moves[i].col == col) {
                    is_possible_move = true;
                    break;
                }
            }
            
            char piece_char = piece_to_char(game->board[row][col]);
            if (is_possible_move && piece_char == '.') {
                printf("* ");
            } else if (is_possible_move) {
                printf("[%c]", piece_char);
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

int get_king_moves(ChessGame *game, Position from, Position moves[]) {
    int count = 0;
    Piece piece = get_piece_at(game, from.row, from.col);
    
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
                    
                    int move_count = get_possible_moves(game, (Position){row, col}, moves);
                    
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
    
    Piece moving_piece = get_piece_at(game, from.row, from.col);
    Piece captured_piece = get_piece_at(game, to.row, to.col);
    
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
    
    game->current_player = (game->current_player == WHITE) ? BLACK : WHITE;
    
    game->in_check[WHITE] = is_in_check(game, WHITE);
    game->in_check[BLACK] = is_in_check(game, BLACK);
    
    return true;
}

void print_captured_pieces(CapturedPieces *captured, const char* color_code, const char* player_name) {
    printf("%s%s Has Captured:%s ", color_code, player_name, "\033[0m");
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

/**
 * Save current game state for undo functionality
 * Creates a complete snapshot of the game state including board position,
 * captured pieces, king positions, and all game flags. This enables
 * single-level undo of move pairs.
 * 
 * @param game Current game state to save
 */
void save_game_state(ChessGame *game) {
    // Copy the current board state
    for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
            game->saved_state.board[row][col] = game->board[row][col];
        }
    }
    
    // Save game state variables
    game->saved_state.current_player = game->current_player;
    game->saved_state.white_captured = game->white_captured;
    game->saved_state.black_captured = game->black_captured;
    game->saved_state.white_king_moved = game->white_king_moved;
    game->saved_state.black_king_moved = game->black_king_moved;
    game->saved_state.white_rook_a_moved = game->white_rook_a_moved;
    game->saved_state.white_rook_h_moved = game->white_rook_h_moved;
    game->saved_state.black_rook_a_moved = game->black_rook_a_moved;
    game->saved_state.black_rook_h_moved = game->black_rook_h_moved;
    game->saved_state.white_king_pos = game->white_king_pos;
    game->saved_state.black_king_pos = game->black_king_pos;
    game->saved_state.in_check[WHITE] = game->in_check[WHITE];
    game->saved_state.in_check[BLACK] = game->in_check[BLACK];
    
    // Mark that undo is now available
    game->can_undo = true;
}

/**
 * Restore previously saved game state for undo functionality
 * Restores the complete game state from the saved snapshot, effectively
 * undoing all moves made since the last save. Clears undo availability
 * after restoration (single-level undo).
 * 
 * @param game Current game state (will be overwritten with saved state)
 */
void restore_game_state(ChessGame *game) {
    if (!game->can_undo) return;
    
    // Restore the board state
    for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
            game->board[row][col] = game->saved_state.board[row][col];
        }
    }
    
    // Restore game state variables
    game->current_player = game->saved_state.current_player;
    game->white_captured = game->saved_state.white_captured;
    game->black_captured = game->saved_state.black_captured;
    game->white_king_moved = game->saved_state.white_king_moved;
    game->black_king_moved = game->saved_state.black_king_moved;
    game->white_rook_a_moved = game->saved_state.white_rook_a_moved;
    game->white_rook_h_moved = game->saved_state.white_rook_h_moved;
    game->black_rook_a_moved = game->saved_state.black_rook_a_moved;
    game->black_rook_h_moved = game->saved_state.black_rook_h_moved;
    game->white_king_pos = game->saved_state.white_king_pos;
    game->black_king_pos = game->saved_state.black_king_pos;
    game->in_check[WHITE] = game->saved_state.in_check[WHITE];
    game->in_check[BLACK] = game->saved_state.in_check[BLACK];
    
    // Clear undo availability (single level undo)
    game->can_undo = false;
}

bool can_undo_move(ChessGame *game) {
    return game->can_undo;
}