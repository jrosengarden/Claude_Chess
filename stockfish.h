#ifndef STOCKFISH_H
#define STOCKFISH_H

#include "chess.h"
#include <unistd.h>
#include <sys/wait.h>

typedef struct {
    FILE *to_engine;
    FILE *from_engine;
    pid_t pid;
    bool is_ready;
} StockfishEngine;

bool init_stockfish(StockfishEngine *engine);
void close_stockfish(StockfishEngine *engine);
bool send_command(StockfishEngine *engine, const char *command);
bool read_response(StockfishEngine *engine, char *buffer, size_t buffer_size);
bool wait_for_ready(StockfishEngine *engine);
char* board_to_fen(ChessGame *game);
bool get_best_move(StockfishEngine *engine, ChessGame *game, char *move_str, bool debug);
bool get_hint_move(StockfishEngine *engine, ChessGame *game, char *move_str, bool debug);
bool get_position_evaluation(StockfishEngine *engine, ChessGame *game, int *centipawn_score);
bool set_skill_level(StockfishEngine *engine, int skill_level);
Move parse_move_string(const char *move_str);
bool get_stockfish_version(StockfishEngine *engine, char *version_str, size_t buffer_size);

#endif