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
 * Display current game information including player turn and captured pieces
 * Shows game status header and captured piece summary for both players
 * 
 * @param game Current game state to display
 */
void print_game_info(ChessGame *game) {
    printf("\n=== CHESS GAME ===\n");
    printf("Current player: %s\n", game->current_player == WHITE ? "WHITE" : "BLACK");
    
    // Display captured pieces for both players
    printf("\n");
    print_captured_pieces(&game->black_captured, "\033[1;96m", "Black");
    print_captured_pieces(&game->white_captured, "\033[1;95m", "White");
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
    
    if (strcmp(input, "fen") == 0 || strcmp(input, "FEN") == 0) {
        char *fen = board_to_fen(game);
        printf("\nCurrent FEN: %s\n", fen);
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
        
        if (is_checkmate(&game, game.current_player)) {
            Color winner = (game.current_player == WHITE) ? BLACK : WHITE;
            printf("\n*** CHECKMATE! %s WINS! ***\n", winner == WHITE ? "WHITE" : "BLACK");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            break;
        }
        
        if (is_stalemate(&game, game.current_player)) {
            printf("\n*** STALEMATE! IT'S A DRAW! ***\n");
            convert_fen_to_pgn();  // Convert FEN log to PGN before exiting
            show_game_files();
            break;
        }
        
        Position empty_moves[0];
        print_board(&game, empty_moves, 0);
        
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