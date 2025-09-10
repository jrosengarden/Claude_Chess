/**
 * MAIN.C - Chess Game User Interface and Game Loop
 * 
 * This file implements the main user interface for the chess game including:
 * - Game loop and turn management
 * - User input handling and command processing
 * - Screen management and display formatting
 * - Integration between chess engine and Stockfish AI
 * - Interactive commands (help, hint, undo, fen, etc.)
 * 
 * Features:
 * - Clean single-board UI with screen clearing
 * - Interactive command system with pause/continue prompts
 * - Human vs AI gameplay (White vs Stockfish)
 * - Move validation and possible move display
 * - Single-level undo functionality
 * - Debug mode for development
 */

#include "chess.h"
#include "stockfish.h"
#include <time.h>

// Global debug flag for diagnostic output
bool debug_mode = false;

// Global FEN log filename for current game session
char fen_log_filename[256];

// Global flag to track if gameplay has started (prevents skill level changes)
bool game_started = false;

// Global skill level tracking (default 20 = full strength)
int current_skill_level = 20;

/**
 * Generate timestamp-based FEN filename for current game session
 * Creates filename in format: CHESS_mmddyy_HHMMSS.fen
 * This allows multiple game sessions to maintain separate FEN logs
 */
void generate_fen_filename() {
    time_t now = time(NULL);
    struct tm *local = localtime(&now);
    
    snprintf(fen_log_filename, sizeof(fen_log_filename), 
             "CHESS_%02d%02d%02d_%02d%02d%02d.fen",
             local->tm_mon + 1,    // Month (1-12)
             local->tm_mday,       // Day (1-31)
             local->tm_year % 100, // Year (2-digit)
             local->tm_hour,       // Hour (0-23)
             local->tm_min,        // Minute (0-59)
             local->tm_sec);       // Second (0-59)
}

/**
 * Save current board position to FEN log file
 * Appends current board state to the session's FEN log file.
 * Called after every half-move to create complete game history.
 * 
 * @param game Current game state to save as FEN
 */
void save_fen_log(ChessGame *game) {
    char *fen = board_to_fen(game);
    FILE *fen_file = fopen(fen_log_filename, "a");
    if (fen_file) {
        fprintf(fen_file, "%s\n", fen);
        fclose(fen_file);
    }
    // Note: FEN logging is always enabled - no debug messages needed
}

/**
 * Reset FEN logging for SETUP command
 * Deletes the current FEN log file and creates a new timestamped file.
 * Then logs the new starting position from the SETUP command.
 * 
 * @param game Current game state to save as new starting position
 */
void reset_fen_log_for_setup(ChessGame *game) {
    // Delete the current FEN log file
    remove(fen_log_filename);
    
    // Generate a new FEN log filename for the setup position
    generate_fen_filename();
    
    // Log the new starting position 
    save_fen_log(game);
}

/**
 * Remove last two moves from FEN log file for undo functionality
 * When undo is executed, both White's move and AI's response are reverted,
 * so we need to remove the last 2 FEN entries to keep the file synchronized.
 */
/**
 * Count available undo moves from FEN log file
 * Returns number of move pairs that can be undone (each pair = White + AI move)
 */
int count_available_undos() {
    FILE *file = fopen(fen_log_filename, "r");
    if (!file) return 0;
    
    int line_count = 0;
    char buffer[256];
    
    while (fgets(buffer, sizeof(buffer), file)) {
        line_count++;
    }
    fclose(file);
    
    // Each move pair requires 2 FEN entries, but we need at least 1 entry to remain (starting position)
    return (line_count > 2) ? (line_count - 1) / 2 : 0;
}

/**
 * Truncate FEN log file by specified number of move pairs
 * Each move pair removes 2 FEN entries (White move + AI response)
 */
void truncate_fen_log_by_moves(int move_pairs_to_undo) {
    FILE *file = fopen(fen_log_filename, "r");
    if (!file) return;
    
    // Read all lines into memory
    char lines[1000][256];  // Support up to 1000 moves (500 move pairs)
    int line_count = 0;
    
    while (fgets(lines[line_count], sizeof(lines[line_count]), file) && line_count < 1000) {
        // Remove newline character for easier handling
        lines[line_count][strcspn(lines[line_count], "\n")] = '\0';
        line_count++;
    }
    fclose(file);
    
    // Remove 2 lines per move pair to undo
    int lines_to_remove = move_pairs_to_undo * 2;
    if (line_count > lines_to_remove) {
        line_count -= lines_to_remove;
        
        // Rewrite the file with the truncated content
        file = fopen(fen_log_filename, "w");
        if (file) {
            for (int i = 0; i < line_count; i++) {
                fprintf(file, "%s\n", lines[i]);
            }
            fclose(file);
        }
    }
}

/**
 * Restore game state from last FEN entry in log file
 * Reads the FEN file and uses the last entry to restore game state
 */
bool restore_from_fen_log(ChessGame *game) {
    FILE *file = fopen(fen_log_filename, "r");
    if (!file) return false;
    
    char last_fen[256] = "";
    char buffer[256];
    
    // Read all lines to find the last one
    while (fgets(buffer, sizeof(buffer), file)) {
        strcpy(last_fen, buffer);
    }
    fclose(file);
    
    // Remove newline character
    last_fen[strcspn(last_fen, "\n")] = '\0';
    
    if (strlen(last_fen) == 0) return false;
    
    // Restore game state from FEN
    return setup_board_from_fen(game, last_fen);
}

/**
 * Convert current session's FEN file to PGN format automatically
 * Creates a PGN file with the same base name as the FEN file.
 * This function performs the conversion silently without user prompts.
 */
void convert_fen_to_pgn() {
    // Create PGN filename from FEN filename
    char pgn_filename[256];
    char* base_name = strdup(fen_log_filename);
    
    // Remove .fen extension if present
    char* dot = strrchr(base_name, '.');
    if (dot) *dot = '\0';
    
    snprintf(pgn_filename, sizeof(pgn_filename), "%s.pgn", base_name);
    free(base_name);
    
    // Open FEN file for reading
    FILE* fen_file = fopen(fen_log_filename, "r");
    if (!fen_file) {
        // FEN file doesn't exist or can't be opened, exit silently
        return;
    }
    
    // Use system call to run fen_to_pgn utility with input redirection
    // This avoids duplicating the complex conversion logic
    char command[512];
    snprintf(command, sizeof(command), "echo '%s' | ./fen_to_pgn > /dev/null 2>&1", fen_log_filename);
    system(command);
    
    fclose(fen_file);
}

/**
 * Display the generated game files to inform the user
 * Shows both the FEN log file and the converted PGN file names
 */
void show_game_files() {
    // Create PGN filename from FEN filename
    char pgn_filename[256];
    char* base_name = strdup(fen_log_filename);
    
    // Remove .fen extension if present
    char* dot = strrchr(base_name, '.');
    if (dot) *dot = '\0';
    
    snprintf(pgn_filename, sizeof(pgn_filename), "%s.pgn", base_name);
    free(base_name);
    
    printf("\nGame files created:\n");
    printf("  FEN log: %s\n", fen_log_filename);
    printf("  PGN file: %s\n", pgn_filename);
}

/**
 * Clear the terminal screen using ANSI escape codes
 * Used throughout the UI to maintain clean single-board display
 */
void clear_screen() {
    printf("\033[2J\033[H");  // Clear screen and move cursor to top-left
    fflush(stdout);           // Ensure immediate display
}

/**
 * Convert centipawn evaluation to -9 to +9 scale
 * Stockfish returns evaluations in centipawns (hundredths of a pawn)
 * We map this to a visual scale from -9 (Black winning) to +9 (White winning)
 * 
 * @param centipawns Evaluation in centipawns from Stockfish
 * @return Evaluation on -9 to +9 scale
 */
int centipawns_to_scale(int centipawns) {
    // Typical centipawn ranges:
    // 0-50: roughly equal
    // 50-150: slight advantage
    // 150-300: moderate advantage  
    // 300-500: significant advantage
    // 500+: winning advantage
    
    if (centipawns <= -900) return -9;        // Black crushing
    else if (centipawns <= -500) return -8;   // Black winning big
    else if (centipawns <= -300) return -7;   // Black significant advantage
    else if (centipawns <= -200) return -6;   // Black moderate advantage
    else if (centipawns <= -100) return -5;   // Black small advantage
    else if (centipawns <= -50) return -4;    // Black slight advantage
    else if (centipawns <= -25) return -3;    // Black tiny advantage
    else if (centipawns <= -10) return -2;    // Black very slight edge
    else if (centipawns < 0) return -1;       // Black barely ahead
    else if (centipawns == 0) return 0;       // Perfectly equal
    else if (centipawns <= 10) return 1;      // White barely ahead
    else if (centipawns <= 25) return 2;      // White very slight edge
    else if (centipawns <= 50) return 3;      // White tiny advantage
    else if (centipawns <= 100) return 4;     // White slight advantage
    else if (centipawns <= 200) return 5;     // White small advantage
    else if (centipawns <= 300) return 6;     // White moderate advantage
    else if (centipawns <= 500) return 7;     // White significant advantage
    else if (centipawns <= 900) return 8;     // White winning big
    else return 9;                           // White crushing
}

/**
 * Display evaluation line showing game score from -9 (Black winning) to +9 (White winning)
 * 
 * @param evaluation Current game evaluation (-9 to +9, where 0 is even)
 */
void print_evaluation_line(int evaluation) {
    printf("\n");
    printf("Black winning -9       -6       -3         0        +3       +6       +9 White winning\n");
    printf("              ");
    
    // Draw the indicator line with position marker
    // Map evaluation (-9 to +9) to exact positions under the actual numbers
    // -9=1, -6=10, -3=19, 0=29, +3=39, +6=48, +9=56
    int position;
    if (evaluation == -9) position = 1;
    else if (evaluation == -6) position = 10;
    else if (evaluation == -3) position = 19;
    else if (evaluation == 0) position = 29;
    else if (evaluation == 3) position = 39;
    else if (evaluation == 6) position = 48;
    else if (evaluation == 9) position = 56;
    else position = (evaluation + 9) * 57 / 18;  // Approximate for other values
    
    // First line: tick marks and horizontal line
    for (int i = 0; i < 58; i++) {
        if (i == 29) {
            printf("┼");  // Center marker at 0 to match top line
        } else if (i == 10 || i == 19 || i == 39 || i == 48) {
            printf("│");  // Tick marks under the actual numbers 6, 3, 3, 6
        } else {
            printf("─");
        }
    }
    printf("\n");
    
    // Second line: caret indicator
    printf("              ");
    for (int i = 0; i < 58; i++) {
        if (i == position) {
            printf("^");
        } else {
            printf(" ");
        }
    }
    printf("\n");
}

/**
 * Display current game information including player turn and captured pieces
 * Shows game status header and captured piece summary for both players
 * 
 * @param game Current game state to display
 */
void print_game_info(ChessGame *game) {
    printf("\n=== CHESS GAME ===\n");
    printf("Current player: %s\n", game->current_player == WHITE ? "WHITE" : "BLACK");
    printf("Stockfish Skill Level: %d\n", current_skill_level);
    
    // Display captured pieces for both players
    printf("\n");
    print_captured_pieces(&game->black_captured, "\033[1;96m", "Black");
    print_captured_pieces(&game->white_captured, "\033[1;95m", "White");
}

/**
 * Display the score conversion chart showing centipawn ranges
 * Shows how Stockfish centipawn evaluations map to our -9 to +9 scale
 */
void print_scale_chart() {
    printf("\n=== SCORE CONVERSION CHART ===\n");
    printf("Stockfish Centipawns → Game Score Scale\n\n");
    
    printf("Black Advantage:\n");
    printf("  -900+ centipawns  →  -9  (Black crushing)\n");
    printf("  -500 to -900      →  -8  (Black winning big)\n");
    printf("  -300 to -500      →  -7  (Black significant advantage)\n");
    printf("  -200 to -300      →  -6  (Black moderate advantage)\n");
    printf("  -100 to -200      →  -5  (Black small advantage)\n");
    printf("   -50 to -100      →  -4  (Black slight advantage)\n");
    printf("   -25 to -50       →  -3  (Black tiny advantage)\n");
    printf("   -10 to -25       →  -2  (Black very slight edge)\n");
    printf("    -1 to -10       →  -1  (Black barely ahead)\n");
    
    printf("\nEven Game:\n");
    printf("     0 centipawns   →   0  (Perfectly equal)\n");
    
    printf("\nPress Enter to continue...");
    getchar();
    
    clear_screen();
    printf("\n=== SCORE CONVERSION CHART (continued) ===\n\n");
    printf("White Advantage:\n");
    printf("    +1 to +10       →  +1  (White barely ahead)\n");
    printf("   +10 to +25       →  +2  (White very slight edge)\n");
    printf("   +25 to +50       →  +3  (White tiny advantage)\n");
    printf("   +50 to +100      →  +4  (White slight advantage)\n");
    printf("  +100 to +200      →  +5  (White small advantage)\n");
    printf("  +200 to +300      →  +6  (White moderate advantage)\n");
    printf("  +300 to +500      →  +7  (White significant advantage)\n");
    printf("  +500 to +900      →  +8  (White winning big)\n");
    printf("  +900+ centipawns  →  +9  (White crushing)\n");
    
    printf("\nNote: 100 centipawns = 1 pawn advantage\n");
}

/**
 * Display help message with all available commands
 * Shows comprehensive list of user commands and their descriptions
 * Used by the help command and during game startup
 */
void print_help() {
    printf("\n=== COMMANDS ===\n");
    printf("Enter moves in format: e2 e4 (from to)\n");
    printf("Type 'help' for this help message\n");
    printf("Type 'hint' to get Stockfish's best move suggestion for White\n");
    printf("Type 'score' to display current game evaluation score\n");
    printf("Type 'scale' to view the score conversion chart (centipawns to -9/+9 scale)\n");
    printf("Type 'skill N' to set AI difficulty level (0=easiest, 20=strongest, only before first move)\n");
    printf("Type 'fen' to display current board position in FEN notation\n");
    printf("Type 'title' to re-display the game title and info screen\n");
    printf("Type 'setup' to setup a custom board position from FEN string\n");
    printf("Type 'undo' for unlimited undo (undo any number of move pairs)\n");
    printf("Type 'resign' to resign the game (with confirmation)\n");
    printf("Type 'quit' to exit the game\n");
    printf("Type a piece position to see its possible moves (marked with * or highlighted)\n");
    printf("* = empty square you can move to\n");
    printf("highlighted piece = piece you can capture\n\n");
}

bool has_legal_moves(ChessGame *game, Color color) {
    for (int row = 0; row < BOARD_SIZE; row++) {
        for (int col = 0; col < BOARD_SIZE; col++) {
            if (is_piece_at(game, row, col)) {
                Piece piece = get_piece_at(game, row, col);
                if (piece.color == color) {
                    Position moves[64];
                    Color original_player = game->current_player;
                    game->current_player = color;
                    
                    int move_count = get_possible_moves(game, (Position){row, col}, moves);
                    
                    for (int i = 0; i < move_count; i++) {
                        if (!would_be_in_check_after_move(game, (Position){row, col}, moves[i])) {
                            game->current_player = original_player;
                            return true;
                        }
                    }
                    
                    game->current_player = original_player;
                }
            }
        }
    }
    return false;
}

bool is_checkmate(ChessGame *game, Color color) {
    return is_in_check(game, color) && !has_legal_moves(game, color);
}

bool is_stalemate(ChessGame *game, Color color) {
    return !is_in_check(game, color) && !has_legal_moves(game, color);
}

/**
 * Handle human player's turn (White pieces)
 * Processes user input for moves and commands including:
 * - Standard chess moves (e.g., "e2 e4")
 * - Interactive commands (help, hint, fen, undo, title, quit)
 * - Piece position queries (e.g., "e2" to show possible moves)
 * 
 * @param game Current game state
 * @param engine Stockfish engine for hint generation
 */
void handle_white_turn(ChessGame *game, StockfishEngine *engine) {
    char input[100];
    printf("\nWhite's turn. Enter move (e.g., 'e2 e4') or 'help': ");
    
    if (!fgets(input, sizeof(input), stdin)) {
        return;
    }
    
    input[strcspn(input, "\n")] = '\0';
    
    // Skip empty input
    if (strlen(input) == 0) {
        return;
    }
    
    if (strcmp(input, "quit") == 0) {
        // Convert FEN log to PGN before exiting
        convert_fen_to_pgn();
        show_game_files();
        exit(0);
    }
    
    if (strcmp(input, "help") == 0) {
        clear_screen();
        print_help();
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "hint") == 0) {
        printf("\nGetting hint from Stockfish...");
        fflush(stdout);
        
        char hint_move[10];
        if (get_best_move(engine, game, hint_move)) {
            if (debug_mode) {
                printf("\nDebug: Stockfish returned hint: '%s'\n", hint_move);
            }
            Move suggested_move = parse_move_string(hint_move);
            if (debug_mode) {
                printf("Debug: Parsed hint from (%d,%d) to (%d,%d)\n", 
                       suggested_move.from.row, suggested_move.from.col, 
                       suggested_move.to.row, suggested_move.to.col);
            }
            char from_str[4], to_str[4];
            strcpy(from_str, position_to_string(suggested_move.from));
            strcpy(to_str, position_to_string(suggested_move.to));
            printf("\nStockfish suggests: %s to %s\n", from_str, to_str);
        } else {
            printf("\nSorry, couldn't get a hint from Stockfish.\n");
        }
        
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "scale") == 0 || strcmp(input, "SCALE") == 0) {
        clear_screen();
        print_scale_chart();
        printf("\nPress Enter to continue...");
        getchar();
        return;
    }
    
    if (strncmp(input, "skill ", 6) == 0 || strncmp(input, "SKILL ", 6) == 0) {
        if (game_started) {
            printf("\nSkill level cannot be changed after the game has started!\n");
            printf("Use this command only before making your first move.\n");
        } else {
            char *level_str = input + 6;  // Skip "skill "
            int skill_level = atoi(level_str);
            
            if (skill_level >= 0 && skill_level <= 20) {
                if (set_skill_level(engine, skill_level)) {
                    current_skill_level = skill_level;  // Update global tracking
                    printf("\nStockfish skill level set to %d (0=easiest, 20=strongest)\n", skill_level);
                } else {
                    printf("\nFailed to set skill level. Make sure Stockfish is ready.\n");
                }
            } else {
                printf("\nInvalid skill level. Please enter a number from 0 to 20.\n");
                printf("0 = easiest, 20 = strongest (default)\n");
            }
        }
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "fen") == 0 || strcmp(input, "FEN") == 0) {
        char *fen = board_to_fen(game);
        printf("\nCurrent FEN: %s\n", fen);
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "score") == 0 || strcmp(input, "SCORE") == 0) {
        printf("\nGetting evaluation from Stockfish...");
        fflush(stdout);
        
        int centipawn_score;
        if (get_position_evaluation(engine, game, &centipawn_score)) {
            int scale_score = centipawns_to_scale(centipawn_score);
            printf("\nCurrent Game Evaluation (Stockfish depth 15):\n");
            if (debug_mode) {
                printf("DEBUG: Raw centipawn score: %+d\n", centipawn_score);
            }
            print_evaluation_line(scale_score);
        } else {
            printf("\nSorry, couldn't get evaluation from Stockfish.\n");
            printf("Showing neutral position:\n");
            print_evaluation_line(0);
        }
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "title") == 0 || strcmp(input, "TITLE") == 0) {
        clear_screen();
        
        printf("=== Chess Game with Stockfish AI ===\n");
        printf("You play as White, AI plays as Black\n");
        printf("Stockfish engine is running successfully!\n");
        
        if (debug_mode) {
            printf("*** DEBUG MODE ENABLED ***\n");
        }
        
        printf("\nPress Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "undo") == 0 || strcmp(input, "UNDO") == 0) {
        int available_undos = count_available_undos();
        
        if (available_undos > 0) {
            // Ask how many move pairs to undo for unlimited undo
            if (available_undos > 1) {
                printf("\nYou can undo up to %d move pairs. How many would you like to undo? (1-%d): ", 
                       available_undos, available_undos);
                fflush(stdout);
                
                char undo_input[10];
                if (fgets(undo_input, sizeof(undo_input), stdin)) {
                    int undo_count = atoi(undo_input);
                    if (undo_count >= 1 && undo_count <= available_undos) {
                        truncate_fen_log_by_moves(undo_count);
                        if (restore_from_fen_log(game)) {
                            printf("\n%d move pair%s undone! Restored to previous position.\n", 
                                   undo_count, undo_count > 1 ? "s" : "");
                        } else {
                            printf("\nError restoring game state from FEN log.\n");
                        }
                    } else {
                        printf("\nInvalid undo count. Must be between 1 and %d.\n", available_undos);
                    }
                } else {
                    printf("\nFailed to read undo count.\n");
                }
            } else {
                // Single undo available
                truncate_fen_log_by_moves(1);
                if (restore_from_fen_log(game)) {
                    printf("\nMove pair undone! Restored to previous position.\n");
                } else {
                    printf("\nError restoring game state from FEN log.\n");
                }
            }
        } else {
            printf("\nNo moves to undo!\n");
        }
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strcmp(input, "resign") == 0 || strcmp(input, "RESIGN") == 0) {
        printf("\nYou are indicating that you are resigning the game. Are you sure?\n");
        printf("Type 'YES' to resign or 'NO' to cancel: ");
        fflush(stdout);
        
        char confirmation[10];
        if (!fgets(confirmation, sizeof(confirmation), stdin)) {
            printf("Failed to read confirmation.\n");
            printf("Press Enter to continue...");
            getchar();
            return;
        }
        
        // Remove newline character
        confirmation[strcspn(confirmation, "\n")] = '\0';
        
        if (strcmp(confirmation, "YES") == 0 || strcmp(confirmation, "yes") == 0) {
            printf("\n*** WHITE RESIGNS! BLACK WINS! ***\n");
            printf("Game ended by resignation.\n");
            
            // Convert FEN log to PGN before exiting
            convert_fen_to_pgn();
            show_game_files();
            
            printf("Press Enter to exit...");
            getchar();
            exit(0);
        } else {
            printf("\nResignation cancelled. Game continues.\n");
            printf("Press Enter to continue...");
            getchar();
            return;
        }
    }
    
    if (strcmp(input, "setup") == 0 || strcmp(input, "SETUP") == 0) {
        char fen_input[256];
        printf("\nEnter FEN string for board setup: ");
        fflush(stdout);
        
        if (!fgets(fen_input, sizeof(fen_input), stdin)) {
            printf("Failed to read FEN string.\n");
            printf("Press Enter to continue...");
            getchar();
            return;
        }
        
        // Remove newline character
        fen_input[strcspn(fen_input, "\n")] = '\0';
        
        // Validate and setup board from FEN
        if (setup_board_from_fen(game, fen_input)) {
            printf("\nBoard setup successful from FEN: %s\n", fen_input);
            
            // Reset FEN logging with new position
            reset_fen_log_for_setup(game);
            printf("New FEN log file created: %s\n", fen_log_filename);
            
            printf("\nGame will continue from this custom position.\n");
        } else {
            printf("\nInvalid FEN string! Board setup failed.\n");
            printf("Please check FEN format and try again.\n");
        }
        
        printf("Press Enter to continue...");
        getchar();
        return;
    }
    
    if (strlen(input) == 2) {
        Position from = char_to_position(input);
        if (is_valid_position(from.row, from.col) && is_piece_at(game, from.row, from.col)) {
            Piece piece = get_piece_at(game, from.row, from.col);
            if (piece.color == WHITE) {
                Position possible_moves[64];
                int move_count = 0;
                
                Position all_moves[64];
                int all_count = get_possible_moves(game, from, all_moves);
                
                for (int i = 0; i < all_count; i++) {
                    if (!would_be_in_check_after_move(game, from, all_moves[i])) {
                        possible_moves[move_count++] = all_moves[i];
                    }
                }
                
                clear_screen();
                printf("\n=== CHESS GAME ===\n");
                printf("Current player: %s\n", game->current_player == WHITE ? "WHITE" : "BLACK");
                
                printf("\n");
                print_captured_pieces(&game->black_captured, "\033[1;96m", "Black");
                print_captured_pieces(&game->white_captured, "\033[1;95m", "White");
                
                if (game->in_check[WHITE]) {
                    printf("\nYour king is in check! You can only make moves that get out of check.\n");
                }
                
                print_board(game, possible_moves, move_count);
                
                if (move_count > 0) {
                    printf("\nPossible moves from %s:\n", position_to_string(from));
                    for (int i = 0; i < move_count; i++) {
                        printf("%s ", position_to_string(possible_moves[i]));
                    }
                    printf("\n");
                } else {
                    printf("\nNo legal moves available from %s\n", position_to_string(from));
                }
                
                printf("Press Enter to continue...");
                getchar();
                return;
            }
        }
        printf("Invalid position or no piece at %s\n", input);
        return;
    }
    
    char from_str[3], to_str[3];
    if (sscanf(input, "%2s %2s", from_str, to_str) != 2) {
        printf("Invalid input format. Use: e2 e4\n");
        return;
    }
    
    Position from = char_to_position(from_str);
    Position to = char_to_position(to_str);
    
    if (!is_valid_position(from.row, from.col) || !is_valid_position(to.row, to.col)) {
        printf("Invalid positions\n");
        return;
    }
    
    
    if (make_move(game, from, to)) {
        game_started = true;  // Mark game as started after first move
        printf("Move made: %s to %s\n", from_str, to_str);
        save_fen_log(game);  // Save FEN after White's move
        printf("Press Enter to continue...");
        getchar();
        clear_screen();
    } else {
        printf("Invalid move\n");
    }
}

void handle_black_turn(ChessGame *game, StockfishEngine *engine) {
    printf("\nBlack's turn (AI thinking...)");
    fflush(stdout);
    
    char move_str[10];
    if (get_best_move(engine, game, move_str)) {
        if (debug_mode) {
            printf("\nDebug: Stockfish returned move: '%s'\n", move_str);
        }
        Move ai_move = parse_move_string(move_str);
        if (debug_mode) {
            printf("Debug: Parsed from (%d,%d) to (%d,%d)\n", 
                   ai_move.from.row, ai_move.from.col, ai_move.to.row, ai_move.to.col);
        }
        
        if (is_valid_position(ai_move.from.row, ai_move.from.col) && 
            is_valid_position(ai_move.to.row, ai_move.to.col)) {
            
            // Store the positions before making the move for display
            Position from_pos = ai_move.from;
            Position to_pos = ai_move.to;
            
            if (make_move(game, ai_move.from, ai_move.to)) {
                char from_str[4], to_str[4];
                strcpy(from_str, position_to_string(from_pos));
                strcpy(to_str, position_to_string(to_pos));
                printf("\nAI played: %s to %s\n", from_str, to_str);
                save_fen_log(game);  // Save FEN after AI's move
                printf("Press Enter to continue...");
                getchar();
                clear_screen();
            } else {
                printf("\nAI suggested invalid move, skipping turn\n");
                game->current_player = WHITE;
            }
        } else {
            printf("\nInvalid AI move format, skipping turn\n");
            game->current_player = WHITE;
        }
    } else {
        printf("\nAI couldn't find a move, skipping turn\n");
        game->current_player = WHITE;
    }
}

/**
 * Main entry point for chess game
 * Initializes the game, sets up Stockfish AI, and runs the main game loop
 * handling alternating turns between human (White) and AI (Black) players.
 * 
 * Command line arguments:
 * - "DEBUG" - Enable diagnostic output mode
 * 
 * @param argc Number of command line arguments
 * @param argv Array of command line argument strings
 * @return 0 on successful completion, 1 on initialization failure
 */
int main(int argc, char *argv[]) {
    ChessGame game;
    StockfishEngine engine = {0};
    
    // Check for DEBUG command line argument
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "DEBUG") == 0) {
            debug_mode = true;
            break;
        }
    }
    
    // Generate FEN log filename for this game session
    generate_fen_filename();
    
    // Clear screen at startup
    clear_screen();
    
    printf("=== Chess Game with Stockfish AI ===\n");
    printf("You play as White, AI plays as Black\n");
    if (debug_mode) {
        printf("*** DEBUG MODE ENABLED ***\n");
    }
    printf("Initializing Stockfish engine...\n");
    
    if (!init_stockfish(&engine)) {
        printf("Failed to initialize Stockfish engine!\n");
        printf("Make sure Stockfish is installed and in your PATH.\n");
        printf("You can install it with: brew install stockfish (macOS) or apt install stockfish (Ubuntu)\n");
        return 1;
    }
    
    // Get and display Stockfish version
    char version_str[256];
    if (get_stockfish_version(&engine, version_str, sizeof(version_str))) {
        clear_screen();
        printf("=== Chess Game with %s AI ===\n", version_str);
        printf("You play as White, AI plays as Black\n");
        printf("Stockfish initialized successfully!\n");
    } else {
        printf("Stockfish initialized successfully!\n");
    }
    
    printf("\nPress Enter to continue...");
    getchar();
    
    clear_screen();
    print_help();
    
    init_board(&game);
    
    // Log initial board position to FEN file
    save_fen_log(&game);
    
    while (true) {
        clear_screen();
        print_game_info(&game);
        
        // Check for game ending conditions
        if (is_checkmate(&game, game.current_player)) {
            print_board(&game, NULL, 0);
            Color winner = (game.current_player == WHITE) ? BLACK : WHITE;
            printf("\n*** CHECKMATE! %s WINS! ***\n", winner == WHITE ? "WHITE" : "BLACK");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            printf("Press Enter to exit...");
            getchar();
            break;
        }
        
        if (is_stalemate(&game, game.current_player)) {
            print_board(&game, NULL, 0);
            printf("\n*** STALEMATE! IT'S A DRAW! ***\n");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            printf("Press Enter to exit...");
            getchar();
            break;
        }
        
        if (is_fifty_move_rule_draw(&game)) {
            print_board(&game, NULL, 0);
            printf("\n*** 50-MOVE RULE DRAW! ***\n");
            printf("50 moves have passed without a pawn move or capture.\n");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            printf("Press Enter to exit...");
            getchar();
            break;
        }
        
        print_board(&game, NULL, 0);
        
        if (game.current_player == WHITE) {
            handle_white_turn(&game, &engine);
        } else {
            handle_black_turn(&game, &engine);
        }
    }
    
    close_stockfish(&engine);
    printf("Thanks for playing!\n");
    
    return 0;
}