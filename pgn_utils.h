#ifndef PGN_UTILS_H
#define PGN_UTILS_H

/**
 * pgn_utils.h - PGN (Portable Game Notation) Utility Functions
 *
 * Purpose:
 *   Provides utilities for converting FEN log files to PGN format.
 *   Extracted from chess.c to create a dedicated PGN handling module.
 *
 * Features:
 *   - FEN-to-PGN string conversion for real-time display
 *   - Proper PGN formatting with headers and algebraic notation
 *   - Support for all chess moves (castling, en passant, captures, promotions)
 *
 * Dependencies:
 *   - chess.h for core data types (Piece, PieceType, Color, BOARD_SIZE)
 */

#include "chess.h"

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
 * - Handles all chess moves including castling, en passant, captures, and promotions
 * - Creates properly formatted PGN with headers and algebraic notation
 * - Memory management: Returns malloc'd string that caller must free
 * - Error handling: Returns NULL if file cannot be opened or memory allocation fails
 */
char* convert_fen_to_pgn_string(const char* fen_filename);

#endif // PGN_UTILS_H