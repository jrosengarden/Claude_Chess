CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g
TARGET = chess
FEN_TARGET = fen_to_pgn
PGN_FEN_TARGET = pgn_to_fen
MICROTEST_TARGET = micro_test
DEBUG_TARGETS = debug_position debug_castling debug_input debug_move debug_castle_input debug_queenside
SOURCES = main.c chess.c stockfish.c
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET) $(FEN_TARGET) $(PGN_FEN_TARGET) $(MICROTEST_TARGET) $(DEBUG_TARGETS)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $(TARGET)

$(FEN_TARGET): fen_to_pgn.c
	$(CC) $(CFLAGS) fen_to_pgn.c -o $(FEN_TARGET)

$(PGN_FEN_TARGET): pgn_to_fen.c chess.o stockfish.o
	$(CC) $(CFLAGS) pgn_to_fen.c chess.o stockfish.o -o $(PGN_FEN_TARGET)

$(MICROTEST_TARGET): micro_test.c chess.o
	$(CC) $(CFLAGS) micro_test.c chess.o -o $(MICROTEST_TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET) $(FEN_TARGET) $(PGN_FEN_TARGET) $(MICROTEST_TARGET) $(DEBUG_TARGETS)
	rm -rf *.dSYM

install-deps:
	@echo "Installing Stockfish..."
	@if command -v brew >/dev/null 2>&1; then \
		echo "Using Homebrew to install Stockfish..."; \
		brew install stockfish; \
	elif command -v apt >/dev/null 2>&1; then \
		echo "Using apt to install Stockfish..."; \
		sudo apt update && sudo apt install -y stockfish; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "Using yum to install Stockfish..."; \
		sudo yum install -y stockfish; \
	else \
		echo "Please install Stockfish manually from https://stockfishchess.org/download/"; \
		echo "Or compile from source: https://github.com/official-stockfish/Stockfish"; \
	fi

run: $(TARGET)
	./$(TARGET)

test: $(MICROTEST_TARGET)
	./$(MICROTEST_TARGET)

# Debug programs compilation (cross-platform compatible)
debug: $(DEBUG_TARGETS)

debug_position: debug_position.c chess.o
	$(CC) $(CFLAGS) debug_position.c chess.o -o debug_position

debug_castling: debug_castling.c chess.o
	$(CC) $(CFLAGS) debug_castling.c chess.o -o debug_castling

debug_input: debug_input.c chess.o
	$(CC) $(CFLAGS) debug_input.c chess.o -o debug_input

debug_move: debug_move.c chess.o
	$(CC) $(CFLAGS) debug_move.c chess.o -o debug_move

debug_castle_input: debug_castle_input.c chess.o
	$(CC) $(CFLAGS) debug_castle_input.c chess.o -o debug_castle_input

debug_queenside: debug_queenside.c chess.o
	$(CC) $(CFLAGS) debug_queenside.c chess.o -o debug_queenside

clean-debug:
	rm -f $(DEBUG_TARGETS)

.PHONY: clean install-deps run all test debug clean-debug