#include "chess.h"
#include "stockfish.h"
#include <stdio.h>

int main() {
    ChessGame game;
    init_board(&game);

    if (setup_board_from_fen(&game, "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")) {
        printf("VALID\n");
        return 0;
    } else {
        printf("INVALID\n");
        return 1;
    }
}
