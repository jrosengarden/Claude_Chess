/**
 * STOCKFISH.C - Chess AI Integration via UCI Protocol
 * 
 * This file implements integration with the Stockfish chess engine using
 * the Universal Chess Interface (UCI) protocol. It handles:
 * - Process management for the Stockfish engine
 * - UCI command communication and parsing
 * - FEN notation conversion for position analysis
 * - Move string parsing and validation
 * - Engine setup and configuration
 * 
 * The UCI protocol allows communication with any UCI-compatible chess engine,
 * with Stockfish being one of the strongest open-source engines available.
 * 
 * Key functions:
 * - Engine initialization and process management
 * - Position setup via FEN notation
 * - Move request and response handling
 * - Engine cleanup and termination
 */

#define _GNU_SOURCE  // Enable GNU/Linux extensions like fdopen
#include "stockfish.h"

/**
 * Initialize Stockfish chess engine via UCI protocol
 * Creates pipes for communication, forks Stockfish process, and establishes
 * UCI communication. This sets up the AI opponent for the chess game.
 * 
 * @param engine Pointer to StockfishEngine structure to initialize
 * @return true if initialization successful, false on failure
 */
bool init_stockfish(StockfishEngine *engine) {
    int to_engine_pipe[2];    // Pipe for sending commands to Stockfish
    int from_engine_pipe[2];  // Pipe for receiving responses from Stockfish
    
    // Create communication pipes
    if (pipe(to_engine_pipe) == -1 || pipe(from_engine_pipe) == -1) {
        return false;
    }
    
    // Fork process to run Stockfish
    engine->pid = fork();
    if (engine->pid == -1) {
        return false;
    }
    
    if (engine->pid == 0) {
        // Child process: set up Stockfish with pipe communication
        dup2(to_engine_pipe[0], STDIN_FILENO);    // Stockfish reads from our output
        dup2(from_engine_pipe[1], STDOUT_FILENO); // Stockfish writes to our input
        
        // Close unused pipe ends in child process
        close(to_engine_pipe[0]);
        close(to_engine_pipe[1]);
        close(from_engine_pipe[0]);
        close(from_engine_pipe[1]);
        
        // Execute Stockfish engine
        execlp("stockfish", "stockfish", NULL);
        exit(1);  // Exit if Stockfish launch fails
    }
    
    // Parent process: close unused pipe ends and set up file streams
    close(to_engine_pipe[0]);   // Don't need to read from our output pipe
    close(from_engine_pipe[1]); // Don't need to write to our input pipe
    
    // Convert pipe file descriptors to FILE streams for easier I/O
    engine->to_engine = fdopen(to_engine_pipe[1], "w");   // Stream to send commands
    engine->from_engine = fdopen(from_engine_pipe[0], "r"); // Stream to read responses
    
    if (!engine->to_engine || !engine->from_engine) {
        return false;
    }
    
    // Initialize UCI communication with Stockfish
    send_command(engine, "uci");    // Request UCI mode
    if (!wait_for_ready(engine)) {  // Wait for Stockfish to be ready
        return false;
    }
    
    send_command(engine, "isready");
    char buffer[1024];
    while (read_response(engine, buffer, sizeof(buffer))) {
        if (strstr(buffer, "readyok")) {
            engine->is_ready = true;
            break;
        }
    }
    
    return engine->is_ready;
}

void close_stockfish(StockfishEngine *engine) {
    if (engine->to_engine) {
        send_command(engine, "quit");
        fclose(engine->to_engine);
    }
    if (engine->from_engine) {
        fclose(engine->from_engine);
    }
    if (engine->pid > 0) {
        waitpid(engine->pid, NULL, 0);
    }
}

bool send_command(StockfishEngine *engine, const char *command) {
    if (!engine->to_engine) return false;
    
    fprintf(engine->to_engine, "%s\n", command);
    fflush(engine->to_engine);
    return true;
}

bool read_response(StockfishEngine *engine, char *buffer, size_t buffer_size) {
    if (!engine->from_engine) return false;
    
    if (fgets(buffer, buffer_size, engine->from_engine)) {
        buffer[strcspn(buffer, "\n")] = '\0';
        return true;
    }
    return false;
}

bool wait_for_ready(StockfishEngine *engine) {
    char buffer[1024];
    while (read_response(engine, buffer, sizeof(buffer))) {
        if (strstr(buffer, "uciok")) {
            return true;
        }
    }
    return false;
}

char piece_to_fen_char(Piece piece) {
    if (piece.type == EMPTY) return '1';
    
    char symbols[] = {' ', 'P', 'R', 'N', 'B', 'Q', 'K'};
    char c = symbols[piece.type];
    
    return piece.color == WHITE ? c : (c + 32);
}

/**
 * Convert chess board to FEN (Forsyth-Edwards Notation) string
 * FEN is the standard notation for describing chess positions and is
 * required for communicating positions to UCI-compatible chess engines.
 * 
 * @param game Current game state to convert
 * @return Static buffer containing FEN string (do NOT free this!)
 */
char* board_to_fen(ChessGame *game) {
    static char fen[256];
    char board_str[128] = "";
    
    for (int row = 0; row < BOARD_SIZE; row++) {
        int empty_count = 0;
        
        for (int col = 0; col < BOARD_SIZE; col++) {
            Piece piece = game->board[row][col];
            
            if (piece.type == EMPTY) {
                empty_count++;
            } else {
                if (empty_count > 0) {
                    char count_str[2];
                    sprintf(count_str, "%d", empty_count);
                    strcat(board_str, count_str);
                    empty_count = 0;
                }
                
                char piece_char = piece_to_fen_char(piece);
                strncat(board_str, &piece_char, 1);
            }
        }
        
        if (empty_count > 0) {
            char count_str[2];
            sprintf(count_str, "%d", empty_count);
            strcat(board_str, count_str);
        }
        
        if (row < BOARD_SIZE - 1) {
            strcat(board_str, "/");
        }
    }
    
    char active_color = game->current_player == WHITE ? 'w' : 'b';
    
    char castling[5] = "";
    if (!game->white_king_moved) {
        if (!game->white_rook_h_moved) strcat(castling, "K");
        if (!game->white_rook_a_moved) strcat(castling, "Q");
    }
    if (!game->black_king_moved) {
        if (!game->black_rook_h_moved) strcat(castling, "k");
        if (!game->black_rook_a_moved) strcat(castling, "q");
    }
    if (strlen(castling) == 0) strcpy(castling, "-");
    
    // En passant target square
    char en_passant[4] = "-";
    if (game->en_passant_available && 
        game->en_passant_target.row >= 0 && game->en_passant_target.row < 8 &&
        game->en_passant_target.col >= 0 && game->en_passant_target.col < 8) {
        char file = 'a' + game->en_passant_target.col;
        char rank = '8' - game->en_passant_target.row;
        sprintf(en_passant, "%c%c", file, rank);
    }
    
    sprintf(fen, "%s %c %s %s %d %d", board_str, active_color, castling, en_passant,
            game->halfmove_clock, game->fullmove_number);
    return fen;
}

/**
 * Request best move from Stockfish for current position
 * Converts game state to FEN notation, sends position to Stockfish,
 * requests analysis, and returns the recommended move.
 * 
 * @param engine Initialized Stockfish engine
 * @param game Current game state to analyze
 * @param move_str Buffer to store the returned move (e.g., "e2e4")
 * @return true if move obtained successfully, false on error
 */
bool get_best_move(StockfishEngine *engine, ChessGame *game, char *move_str) {
    if (!engine->is_ready) return false;
    
    char *fen = board_to_fen(game);
    char position_command[512];
    sprintf(position_command, "position fen %s", fen);
    
    send_command(engine, position_command);
    send_command(engine, "go depth 10");
    
    char buffer[1024];
    while (read_response(engine, buffer, sizeof(buffer))) {
        if (strncmp(buffer, "bestmove", 8) == 0) {
            char *move_start = buffer + 9;
            char *space_pos = strchr(move_start, ' ');
            
            if (space_pos) {
                *space_pos = '\0';
            }
            
            strcpy(move_str, move_start);
            return true;
        }
    }
    
    return false;
}

Move parse_move_string(const char *move_str) {
    Move move = {{-1, -1}, {-1, -1}, {EMPTY, WHITE}, false, false, false};
    
    if (strlen(move_str) < 4) return move;
    
    move.from.col = move_str[0] - 'a';
    move.from.row = '8' - move_str[1];
    move.to.col = move_str[2] - 'a';
    move.to.row = '8' - move_str[3];
    
    return move;
}

/**
 * Get position evaluation from Stockfish in centipawns
 * Sends position to Stockfish and requests evaluation analysis.
 * 
 * @param engine Pointer to initialized StockfishEngine
 * @param game Current game state to evaluate
 * @param centipawn_score Pointer to store the evaluation result
 * @return true if evaluation successful, false on failure
 */
bool get_position_evaluation(StockfishEngine *engine, ChessGame *game, int *centipawn_score) {
    if (!engine->is_ready) return false;
    
    char *fen = board_to_fen(game);
    char position_command[512];
    sprintf(position_command, "position fen %s", fen);
    
    send_command(engine, position_command);
    send_command(engine, "go depth 15");  // Use deeper analysis for evaluation
    
    char buffer[1024];
    *centipawn_score = 0;  // Default to even position
    
    while (read_response(engine, buffer, sizeof(buffer))) {
        // Look for evaluation info lines like "info depth 15 score cp 142"
        if (strncmp(buffer, "info", 4) == 0 && strstr(buffer, "score cp")) {
            char *score_pos = strstr(buffer, "score cp");
            if (score_pos) {
                score_pos += 9;  // Skip "score cp "
                *centipawn_score = atoi(score_pos);
            }
        }
        // Stop when we get the best move (analysis complete)
        if (strncmp(buffer, "bestmove", 8) == 0) {
            return true;
        }
    }
    
    return false;
}

/**
 * Set Stockfish skill level (0-20)
 * Uses UCI protocol to set the engine's playing strength.
 * 
 * @param engine Pointer to initialized StockfishEngine
 * @param skill_level Skill level from 0 (weakest) to 20 (strongest)
 * @return true if command sent successfully, false on failure
 */
bool set_skill_level(StockfishEngine *engine, int skill_level) {
    if (!engine->is_ready || skill_level < 0 || skill_level > 20) {
        return false;
    }
    
    char command[64];
    sprintf(command, "setoption name Skill Level value %d", skill_level);
    
    return send_command(engine, command);
}

bool get_stockfish_version(StockfishEngine *engine, char *version_str, size_t buffer_size) {
    if (!engine->to_engine || !engine->from_engine) return false;
    
    send_command(engine, "uci");
    
    char buffer[1024];
    while (read_response(engine, buffer, sizeof(buffer))) {
        if (strncmp(buffer, "id name", 7) == 0) {
            // Extract version from "id name Stockfish 16" or similar
            char *name_start = buffer + 8; // Skip "id name "
            strncpy(version_str, name_start, buffer_size - 1);
            version_str[buffer_size - 1] = '\0';
            return true;
        }
        if (strstr(buffer, "uciok")) {
            break;
        }
    }
    
    // If we couldn't get version info, set a default
    strncpy(version_str, "Unknown Version", buffer_size - 1);
    version_str[buffer_size - 1] = '\0';
    return false;
}