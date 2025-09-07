CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g
TARGET = chess
FEN_TARGET = fen_to_pgn
SOURCES = main.c chess.c stockfish.c
OBJECTS = $(SOURCES:.c=.o)

all: $(TARGET) $(FEN_TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) -o $(TARGET)

$(FEN_TARGET): fen_to_pgn.c
	$(CC) $(CFLAGS) fen_to_pgn.c -o $(FEN_TARGET)

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET) $(FEN_TARGET)

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

.PHONY: clean install-deps run all