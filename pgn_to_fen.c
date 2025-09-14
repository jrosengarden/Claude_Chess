/**
 * PGN_TO_FEN.C - PGN to FEN Conversion Utility
 *
 * Converts PGN (Portable Game Notation) moves to FEN (Forsyth-Edwards Notation)
 * positions for validation and verification of chess opening sequences.
 *
 * Usage: ./pgn_to_fen "1.d4 Nf6 2.c4 g6 3.Nc3 Bg7"
 *        ./pgn_to_fen < moves.txt
 *        echo "1.e4 e5 2.Nf3 Nc6" | ./pgn_to_fen
 *
 * Features:
 * - Accepts PGN move sequences as command line argument or stdin
 * - Outputs FEN position after each move
 * - Validates all moves using chess engine
 * - Reports invalid moves with position context
 * - Handles standard algebraic notation (SAN)
 */

#include "chess.h"
#include "stockfish.h"
#include <stdio.h>
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

int main(int argc, char* argv[]) {
    ChessGame game;
    init_board(&game);

    char input[4096] = {0};

    // Get input from command line argument or stdin
    if (argc > 1) {
        strncpy(input, argv[1], sizeof(input) - 1);
    } else {
        if (!fgets(input, sizeof(input), stdin)) {
            fprintf(stderr, "Error reading input\n");
            return 1;
        }
    }

    printf("Starting position:\n");
    printf("%s\n", board_to_fen(&game));

    // Parse and process moves
    char* token = strtok(input, " \t\n");
    int move_count = 0;

    while (token != NULL) {
        // Skip move numbers (e.g., "1.", "2.", etc.)
        if (strchr(token, '.') != NULL) {
            token = strtok(NULL, " \t\n");
            continue;
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
                move_count++;
                printf("After %d. %s:\n", (move_count + 1) / 2, token);
                printf("%s\n", board_to_fen(&game));
            } else {
                fprintf(stderr, "Invalid move: %s (from %c%d to %c%d)\n",
                        token, 'a' + from.col, 8 - from.row, 'a' + to.col, 8 - to.row);
                return 1;
            }
        } else {
            fprintf(stderr, "Could not parse move: %s\n", token);
            return 1;
        }

        token = strtok(NULL, " \t\n");
    }

    printf("\nConversion complete! Processed %d moves.\n", move_count);
    return 0;
}