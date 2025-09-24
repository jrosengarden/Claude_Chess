/**
 * CHESS.H - Chess Game Header File
 * 
 * Core data structures and function declarations for a complete chess game
 * implementation with Stockfish AI integration and full game state management.
 * 
 * Features:
 * - Complete chess piece movement and validation including castling and en passant
 * - Check/checkmate/stalemate detection with 50-move rule draws
 * - Unlimited undo functionality using FEN log-based restoration
 * - Move highlighting and possible move display
 * - Capture tracking with visual display
 * - AI difficulty control and position evaluation system
 * - Automatic FEN logging and PGN generation
 * - Custom board setup via FEN notation
 */

#ifndef CHESS_H
#define CHESS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <time.h>

#define BOARD_SIZE 8  // Standard 8x8 chess board

/**
 * PieceType - All possible chess piece types
 * EMPTY is used for vacant squares on the board
 * Values correspond to standard chess piece hierarchy
 */
typedef enum {
    EMPTY = 0,   // Empty square (no piece)
    PAWN = 1,    // Pawn piece
    ROOK = 2,    // Rook piece (castle)
    KNIGHT = 3,  // Knight piece (horse)
    BISHOP = 4,  // Bishop piece
    QUEEN = 5,   // Queen piece
    KING = 6     // King piece
} PieceType;

/**
 * Color - Player colors in chess
 * WHITE = 0 allows easy array indexing for player-specific data
 */
typedef enum {
    WHITE = 0,   // White player (human)
    BLACK = 1    // Black player (AI)
} Color;

/**
 * Piece - Represents a single chess piece
 * Combines piece type and color information
 */
typedef struct {
    PieceType type;  // What kind of piece (pawn, rook, etc.)
    Color color;     // Which player owns this piece
} Piece;

/**
 * Position - Represents a square on the chess board
 * Uses 0-based indexing: row 0 = rank 8, col 0 = file 'a'
 */
typedef struct {
    int row;  // Board row (0-7, where 0 is top of displayed board)
    int col;  // Board column (0-7, where 0 is leftmost column)
} Position;

/**
 * Move - Represents a chess move with all associated information
 * Stores both the move coordinates and metadata about the move
 */
typedef struct {
    Position from;      // Starting position of the move
    Position to;        // Ending position of the move
    Piece captured;     // Piece that was captured (if any)
    bool is_capture;    // True if this move captures an opponent piece
    bool is_check;      // True if this move puts opponent in check
    bool is_checkmate;  // True if this move results in checkmate
    bool is_promotion;  // True if this move involves pawn promotion
    PieceType promotion_piece; // Type of piece to promote to (QUEEN, ROOK, BISHOP, KNIGHT)
} Move;

/**
 * CapturedPieces - Tracks pieces captured by each player
 * Used for display and game state management
 */
typedef struct {
    Piece captured_pieces[16];  // Array of captured pieces (max 16 per player)
    int count;                  // Number of pieces currently captured
} CapturedPieces;

/**
 * TimeControl - Time control settings for the game
 * Configures timing rules for both players (can be different)
 */
typedef struct {
    int white_minutes;          // Minutes allocated to White player
    int white_increment;        // Seconds added after each White move
    int black_minutes;          // Minutes allocated to Black player
    int black_increment;        // Seconds added after each Black move
    bool enabled;              // Whether time controls are active
} TimeControl;

/**
 * GameTimer - Tracks time remaining for both players
 * Manages actual timing during gameplay
 */
typedef struct {
    int white_time_seconds;     // Seconds remaining for White player
    int black_time_seconds;     // Seconds remaining for Black player
    time_t move_start_time;     // When current player's move started
    bool timing_active;         // Whether timer is currently running
    Color timer_player;         // Which player the active timer belongs to
} GameTimer;


/**
 * ChessGame - Main game state structure
 * Contains the complete current state of the chess game including board,
 * player information, move history, and undo functionality
 */
typedef struct {
    // Core game state
    Piece board[BOARD_SIZE][BOARD_SIZE];  // The 8x8 chess board
    Color current_player;                 // Whose turn it is (WHITE/BLACK)
    
    // Capture tracking for display
    CapturedPieces white_captured;        // Pieces captured by White player
    CapturedPieces black_captured;        // Pieces captured by Black player
    
    // Castling eligibility tracking (fully implemented)
    bool white_king_moved;     // Has White king moved (disables castling)
    bool black_king_moved;     // Has Black king moved (disables castling)  
    bool white_rook_a_moved;   // Has White queenside rook moved
    bool white_rook_h_moved;   // Has White kingside rook moved
    bool black_rook_a_moved;   // Has Black queenside rook moved
    bool black_rook_h_moved;   // Has Black kingside rook moved
    
    // Efficient game state tracking
    Position white_king_pos;   // White king position (for fast check detection)
    Position black_king_pos;   // Black king position (for fast check detection)
    Move last_move;           // Most recent move made (for move validation)
    bool in_check[2];         // Check status [WHITE, BLACK]
    
    // FEN move counters
    int halfmove_clock;       // Number of halfmoves since last pawn move or capture
    int fullmove_number;      // Number of completed move pairs (increments after Black's move)
    
    // En passant state tracking
    Position en_passant_target; // Target square for en passant capture (-1,-1 if none available)
    bool en_passant_available;  // True if en passant capture is currently available

    // Time control system
    TimeControl time_control;   // Current time control settings
    GameTimer timer;           // Current timer state

} ChessGame;

/* ========================================================================
 * FUNCTION DECLARATIONS
 * Core chess game functions for board management, move validation,
 * game state operations, and utility functions
 * ======================================================================== */

// Board initialization and display
void init_board(ChessGame *game);  // Initialize new game with starting positions
void print_board(ChessGame *game, Position possible_moves[], int move_count);  // Display board with optional move highlighting

// Board state queries  
bool is_valid_position(int row, int col);  // Check if coordinates are within board bounds
bool is_piece_at(ChessGame *game, int row, int col);  // Check if a piece exists at position
Piece get_piece_at(ChessGame *game, int row, int col);  // Get piece at position (returns EMPTY if none)
void set_piece_at(ChessGame *game, int row, int col, Piece piece);  // Place piece at position
void clear_position(ChessGame *game, int row, int col);  // Remove piece from position

// Move generation and validation
int get_possible_moves(ChessGame *game, Position from, Position moves[]);  // Get all possible moves for piece at position
int get_pawn_moves(ChessGame *game, Position from, Position moves[]);  // Get all possible pawn moves including en passant
bool is_valid_move(ChessGame *game, Position from, Position to);  // Check if move is legal
bool make_move(ChessGame *game, Position from, Position to);  // Execute move and update game state
bool make_promotion_move(ChessGame *game, Position from, Position to, PieceType promotion_type);  // Execute pawn promotion move
bool execute_move(ChessGame *game, Move move);  // Execute move from Move structure (handles AI promotion)

// Pawn promotion functions
bool is_promotion_move(ChessGame *game, Position from, Position to);  // Check if move requires pawn promotion
PieceType get_promotion_choice();  // Interactive UI for promotion piece selection
bool is_valid_promotion_piece(PieceType piece_type);  // Validate promotion piece type

// Check and game state analysis
bool is_in_check(ChessGame *game, Color color);  // Determine if player is in check
bool would_be_in_check_after_move(ChessGame *game, Position from, Position to);  // Test if move would leave king in check
bool is_square_attacked(ChessGame *game, Position pos, Color by_color);  // Check if square is attacked by given color
int get_king_moves_no_castling(ChessGame *game, Position from, Position moves[]);  // Get king moves without castling (for attack checking)

// Display and formatting utilities
void print_captured_pieces(CapturedPieces *captured, const char* color_code, const char* player_name, ChessGame* game);  // Display captured pieces for UI
char piece_to_char(Piece piece);  // Convert piece to display character
Position char_to_position(const char *input);  // Convert algebraic notation (e.g. "e4") to Position
char *position_to_string(Position pos);  // Convert Position to algebraic notation string


// Captured pieces calculation
void calculate_captured_pieces(ChessGame *game);  // Calculate captured pieces from current board position

// FEN parsing and board setup functions
bool validate_fen_string(const char* fen);  // Validate FEN string format
bool setup_board_from_fen(ChessGame *game, const char* fen);  // Parse FEN and set board position
PieceType char_to_piece_type(char c);  // Convert character to piece type (helper function)

// Draw conditions
bool is_fifty_move_rule_draw(ChessGame *game);  // Check if 50-move rule draw condition is met

// Time control functions
bool parse_time_control(const char* time_str, TimeControl* tc);  // Parse TIME xx/yy command format
void init_game_timer(ChessGame* game, TimeControl* time_control);  // Initialize timer system
void start_move_timer(ChessGame* game);  // Begin timing current player's move
void stop_move_timer(ChessGame* game);  // End timing and apply increment
char* get_remaining_time_string(int seconds);  // Format time as MM:SS string
bool check_time_forfeit(ChessGame* game);  // Check for time expiration
bool is_time_control_enabled(ChessGame* game);  // Check if time controls are active

#endif