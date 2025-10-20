/**
 * pgn_utils.c - PGN (Portable Game Notation) Utility Functions
 *
 * Purpose:
 *   Provides utilities for converting FEN log files to PGN format.
 *   Extracted from chess.c (lines 1052-1333) to create a dedicated PGN module.
 *
 * Architecture:
 *   - Reads FEN positions from log file
 *   - Compares consecutive positions to detect moves
 *   - Converts moves to standard algebraic notation
 *   - Formats output as proper PGN with headers
 *
 * Dependencies:
 *   - chess.h: Core types (Piece, PieceType, Color, BOARD_SIZE)
 *   - char_to_piece_type() from chess.c for FEN parsing
 */

#include "pgn_utils.h"

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

    typedef struct {
        int row, col;
        PieceType type;
        Color color;
    } PieceChange;

    FILE* input_file = fopen(fen_filename, "r");
    if (!input_file) {
        return NULL;
    }

    char* pgn_string = malloc(MAX_PGN_SIZE);
    if (!pgn_string) {
        fclose(input_file);
        return NULL;
    }

    time_t now = time(NULL);
    struct tm* timeinfo = localtime(&now);
    char date_str[20];
    strftime(date_str, sizeof(date_str), "%Y.%m.%d", timeinfo);

    // Initial headers (FEN headers will be added later if needed)
    snprintf(pgn_string, MAX_PGN_SIZE,
        "[Event \"Current Game\"]\n"
        "[Site \"Claude Chess\"]\n"
        "[Date \"%s\"]\n"
        "[Round \"?\"]\n"
        "[White \"Player\"]\n"
        "[Black \"AI\"]\n"
        "[Result \"*\"]\n", date_str);

    Piece prev_board[BOARD_SIZE][BOARD_SIZE];
    Piece curr_board[BOARD_SIZE][BOARD_SIZE];
    PgnMove moves[MAX_MOVES];
    int move_count = 0;

    char line[MAX_LINE_LENGTH];
    char first_fen[MAX_LINE_LENGTH] = {0};
    bool first_position = true;

    while (fgets(line, sizeof(line), input_file) && move_count < MAX_MOVES) {
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) == 0) continue;

        memset(curr_board, 0, sizeof(curr_board));

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
            // Save the first FEN string for PGN headers
            strncpy(first_fen, line, sizeof(first_fen) - 1);
            memcpy(prev_board, curr_board, sizeof(curr_board));
            first_position = false;
            continue;
        }

        PgnMove move = {0};

        PieceChange disappeared[64], appeared[64];
        int disappeared_count = 0, appeared_count = 0;

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

        bool move_found = false;
        for (int i = 0; i < BOARD_SIZE && !move_found; i++) {
            for (int j = 0; j < BOARD_SIZE && !move_found; j++) {
                if (prev_board[i][j].type == KING && curr_board[i][j].type != KING) {
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

                        if (prev_board[appeared[a].row][appeared[a].col].type != EMPTY) {
                            move.captured_piece = prev_board[appeared[a].row][appeared[a].col].type;
                        }

                        if (move.piece_type == PAWN &&
                            move.from_col != move.to_col &&
                            prev_board[move.to_row][move.to_col].type == EMPTY) {
                            move.is_en_passant = 1;
                        }

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

        memcpy(prev_board, curr_board, sizeof(curr_board));
    }

    fclose(input_file);

    // Check if starting position is non-standard and add FEN headers if needed
    // Standard starting position FEN (first component only):
    // rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR
    const char* standard_position = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR";

    if (first_fen[0] != '\0') {
        // Extract just the piece placement part (before first space)
        char fen_pieces[MAX_LINE_LENGTH] = {0};
        const char* space_pos = strchr(first_fen, ' ');
        if (space_pos) {
            size_t len = space_pos - first_fen;
            if (len < sizeof(fen_pieces)) {
                strncpy(fen_pieces, first_fen, len);
                fen_pieces[len] = '\0';
            }
        } else {
            strncpy(fen_pieces, first_fen, sizeof(fen_pieces) - 1);
        }

        // Compare with standard position (case-insensitive)
        bool is_standard = (strcasecmp(fen_pieces, standard_position) == 0);

        if (!is_standard) {
            // Add PGN standard FEN headers for custom starting position
            size_t current_len = strlen(pgn_string);
            snprintf(pgn_string + current_len, MAX_PGN_SIZE - current_len,
                "[SetUp \"1\"]\n[FEN \"%s\"]\n", first_fen);
        }
    }

    // Add blank line before moves
    size_t current_len = strlen(pgn_string);
    if (current_len < MAX_PGN_SIZE - 2) {
        strcat(pgn_string, "\n");
        current_len++;
    }

    char* pos = pgn_string + current_len;
    size_t remaining = MAX_PGN_SIZE - current_len;

    for (int i = 0; i < move_count && remaining > 50; i++) {
        if (i % 2 == 0) {
            int written = snprintf(pos, remaining, "%d. ", (i / 2) + 1);
            pos += written;
            remaining -= written;
        }

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
            char piece_symbols[] = " PRNBQK";
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

        if ((i + 1) % 6 == 0 && remaining > 5) {
            strcpy(pos, "\n");
            pos++;
            remaining--;
        }
    }

    if (remaining > 5) {
        strcat(pos, "*\n");
    }

    return pgn_string;
}