/**
 * PGN_TO_FEN.C - PGN to FEN Conversion Utility
 *
 * Converts standard PGN files (with headers) to clean FEN position files
 * compatible with the chess game's LOAD function and fen_to_pgn utility.
 *
 * Usage: ./pgn_to_fen < game.pgn > output.fen
 *        ./pgn_to_fen game.pgn > output.fen
 *
 * Features:
 * - Accepts standard PGN files with headers (compatible with fen_to_pgn output)
 * - Skips PGN headers automatically ([Event "..."], [Site "..."], etc.)
 * - Outputs clean FEN strings only (one per line)
 * - Validates all moves using chess engine
 * - Compatible with chess game LOAD function
 * - Handles standard algebraic notation (SAN)
 */

#include "chess.h"
#include "stockfish.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/**
 * Convert algebraic notation (e.g., "e4") to Position structure
 * Returns true if successful, false if invalid notation
 */
bool parse_algebraic_move(const char* move_str, Position* from, Position* to, ChessGame* game) {
    if (!move_str || strlen(move_str) < 2) return false;

    // Handle castling
    if (strcmp(move_str, "O-O") == 0 || strcmp(move_str, "0-0") == 0) {
        // Kingside castling
        if (game->current_player == WHITE) {
            *from = (Position){7, 4}; // e1
            *to = (Position){7, 6};   // g1
        } else {
            *from = (Position){0, 4}; // e8
            *to = (Position){0, 6};   // g8
        }
        return true;
    }

    if (strcmp(move_str, "O-O-O") == 0 || strcmp(move_str, "0-0-0") == 0) {
        // Queenside castling
        if (game->current_player == WHITE) {
            *from = (Position){7, 4}; // e1
            *to = (Position){7, 2};   // c1
        } else {
            *from = (Position){0, 4}; // e8
            *to = (Position){0, 2};   // c8
        }
        return true;
    }

    // Find destination square (last two characters before annotations)
    int len = strlen(move_str);
    int dest_idx = -1;

    // Find the destination square (file + rank)
    for (int i = len - 1; i >= 1; i--) {
        if (move_str[i] >= '1' && move_str[i] <= '8' &&
            move_str[i-1] >= 'a' && move_str[i-1] <= 'h') {
            dest_idx = i - 1;
            break;
        }
    }

    // Handle simple cases like "d4", "e5"
    if (dest_idx == -1 && len >= 2) {
        if (move_str[len-1] >= '1' && move_str[len-1] <= '8' &&
            move_str[len-2] >= 'a' && move_str[len-2] <= 'h') {
            dest_idx = len - 2;
        }
    }

    if (dest_idx == -1) return false;

    // Parse destination
    to->col = move_str[dest_idx] - 'a';
    to->row = 8 - (move_str[dest_idx + 1] - '0');

    if (to->col < 0 || to->col > 7 || to->row < 0 || to->row > 7) return false;

    // Determine piece type
    PieceType piece_type = PAWN;
    if (dest_idx > 0 && move_str[0] >= 'A' && move_str[0] <= 'Z') {
        switch (move_str[0]) {
            case 'K': piece_type = KING; break;
            case 'Q': piece_type = QUEEN; break;
            case 'R': piece_type = ROOK; break;
            case 'B': piece_type = BISHOP; break;
            case 'N': piece_type = KNIGHT; break;
            default: return false;
        }
    }

    // Find the piece that can make this move
    Position candidates[64];
    int candidate_count = 0;

    // Collect all pieces that can make this move
    for (int row = 0; row < 8; row++) {
        for (int col = 0; col < 8; col++) {
            Position candidate = {row, col};
            if (game->board[row][col].type == piece_type &&
                game->board[row][col].color == game->current_player &&
                is_valid_move(game, candidate, *to)) {
                candidates[candidate_count++] = candidate;
            }
        }
    }

    if (candidate_count == 0) return false;

    if (candidate_count == 1) {
        *from = candidates[0];
        return true;
    }

    // Multiple candidates - need disambiguation
    for (int i = 0; i < candidate_count; i++) {
        bool found_match = true;
        Position candidate = candidates[i];

        // Check for file disambiguation (e.g., "Nbd2")
        if (dest_idx > 1 && move_str[1] >= 'a' && move_str[1] <= 'h') {
            if (candidate.col != (move_str[1] - 'a')) found_match = false;
        }

        // Check for rank disambiguation (e.g., "N1d2")
        if (dest_idx > 1 && move_str[1] >= '1' && move_str[1] <= '8') {
            if (candidate.row != (8 - (move_str[1] - '0'))) found_match = false;
        }

        if (found_match) {
            *from = candidate;
            return true;
        }
    }

    // If no disambiguation found, return the first candidate
    *from = candidates[0];
    return true;
}

/**
 * Clean up move string by removing annotations and extra characters
 */
void clean_move_string(char* move) {
    int len = strlen(move);
    int write_pos = 0;

    for (int i = 0; i < len; i++) {
        char c = move[i];
        if (c == '+' || c == '#' || c == '!' || c == '?' || c == '=' || c == ' ') {
            break; // Stop at annotations
        }
        if (isalnum(c) || c == '-' || c == 'O') {
            move[write_pos++] = c;
        }
    }
    move[write_pos] = '\0';
}

/**
 * Extract move sequence from PGN content, skipping headers
 * Returns allocated string with moves, or NULL on error
 */
char* extract_moves_from_pgn(FILE* input) {
    char line[1024];
    char* moves = malloc(4096);
    if (!moves) return NULL;

    moves[0] = '\0';
    int moves_len = 0;
    bool in_headers = true;

    while (fgets(line, sizeof(line), input)) {
        // Skip empty lines
        if (line[0] == '\n' || line[0] == '\r') {
            if (in_headers) {
                in_headers = false; // End of headers section
            }
            continue;
        }

        // Skip PGN header lines (start with '[')
        if (line[0] == '[') {
            continue;
        }

        // We've reached the moves section
        in_headers = false;

        // Append this line to moves string
        int line_len = strlen(line);
        if (moves_len + line_len + 1 < 4096) {
            strcat(moves, line);
            moves_len += line_len;
        }
    }

    return moves;
}

int main(int argc, char* argv[]) {
    ChessGame game;
    init_board(&game);
    FILE* input = stdin;

    // Handle file input if provided
    if (argc > 1) {
        input = fopen(argv[1], "r");
        if (!input) {
            fprintf(stderr, "Error: Cannot open file %s\n", argv[1]);
            return 1;
        }
    }

    // Extract moves from PGN, skipping headers
    char* moves_string = extract_moves_from_pgn(input);
    if (!moves_string) {
        fprintf(stderr, "Error: Failed to extract moves from PGN\n");
        if (input != stdin) fclose(input);
        return 1;
    }

    if (input != stdin) fclose(input);

    // Output starting position (clean FEN only)
    printf("%s\n", board_to_fen(&game));

    // Parse and process moves
    char* token = strtok(moves_string, " \t\n");

    while (token != NULL) {
        // Skip move numbers (e.g., "1.", "2.", etc.)
        if (strchr(token, '.') != NULL) {
            token = strtok(NULL, " \t\n");
            continue;
        }

        // Skip result markers
        if (strcmp(token, "*") == 0 || strcmp(token, "1-0") == 0 ||
            strcmp(token, "0-1") == 0 || strcmp(token, "1/2-1/2") == 0) {
            break;
        }

        // Clean the move string
        clean_move_string(token);

        if (strlen(token) == 0) {
            token = strtok(NULL, " \t\n");
            continue;
        }

        // Parse the move
        Position from, to;
        if (parse_algebraic_move(token, &from, &to, &game)) {
            if (is_valid_move(&game, from, to)) {
                make_move(&game, from, to);
                // Output clean FEN only (no descriptions)
                printf("%s\n", board_to_fen(&game));
            } else {
                fprintf(stderr, "Error: Invalid move %s (from %c%d to %c%d)\n",
                        token, 'a' + from.col, 8 - from.row, 'a' + to.col, 8 - to.row);
                free(moves_string);
                return 1;
            }
        } else {
            fprintf(stderr, "Error: Could not parse move %s\n", token);
            free(moves_string);
            return 1;
        }

        token = strtok(NULL, " \t\n");
    }

    free(moves_string);
    return 0;
}