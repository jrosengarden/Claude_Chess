# Claude Chess

A complete terminal chess game with AI opponent and comprehensive study features.

**Quick Start:** `make && make run`

## Features

### Core Gameplay
- Complete chess rules with all standard piece movements
- Castling (kingside/queenside), en passant, and 50-move rule
- Clean ASCII board display with coordinates
- Move visualization with `*` and highlighted captures
- Unlimited undo functionality
- AI opponent powered by Stockfish (adjustable difficulty 0-20)

### Game Analysis & Study
- Position evaluation with visual scoring scale (-9 to +9)
- Real-time PGN display in side-by-side terminal windows
- Custom board setup using FEN notation
- Interactive game loading with arrow key navigation
- **Verified classical opening library** (12 authenticated openings)
- Automatic game recording in FEN and PGN formats
- Captured pieces display shows complete capture history for loaded positions
- **Opening validation tools** ensure legal positions and authentic sequences

## Requirements

- C compiler (GCC or compatible)
- Stockfish chess engine
- POSIX system (macOS, Linux)

**Tested on:** macOS 15.6.1, Ubuntu 22.04

## Installation

```bash
# Install Stockfish
brew install stockfish          # macOS
sudo apt install stockfish      # Ubuntu/Debian
# or: make install-deps

# Build and run
make && make run
```

## How to Play

**Basic Controls:**
- Move: `e2 e4` (algebraic notation)
- Castling: `e1 g1` (move king two squares)
- View moves: `e2` (show possible moves from e2)
- Undo: `undo` (unlimited)

**Game Flow:**
- You play White, AI plays Black
- Clean single-board interface
- Automatic detection of checkmate, stalemate, draws
- All games automatically saved as FEN and PGN files

## Commands

### Gameplay
- `help` - Show help
- `hint` - Get AI's best move suggestion
- `skill N` - Set AI difficulty (0-20, before first move only)
- `undo` - Unlimited undo
- `resign` - Resign with confirmation
- `quit` - Exit game

### Analysis & Study
- `score` - Position evaluation (-9 to +9 scale)
- `pgn` - View game in standard notation (side-by-side window)
- `fen` - Current position in FEN format
- `setup` - Configure custom position from FEN
- `load` - Browse saved games with arrow key navigation

### Special Features
- **Verified classical opening library** accessible via `load` command
- All games auto-saved as timestamped FEN and PGN files
- Configuration via `CHESS.ini` file
- **Opening validation utilities** for study and analysis

## Configuration (CHESS.ini)

Auto-created configuration file with settings:

```ini
[Paths]
FENDirectory=.                    # Directory for saved games

[Settings]
DefaultSkillLevel=5               # AI difficulty (0-20)
```

**Customization:**
- Move FEN files to custom directory and update `FENDirectory`
- Set default AI skill level
- Cross-platform path support

## Board Display

```
    a b c d e f g h
  +----------------+
8 | r n b q k b n r | 8
7 | p p p p p p p p | 7
6 | . . . . . . . . | 6
5 | . . . . . . . . | 5
4 | . . . . . . . . | 4
3 | . . . . . . . . | 3
2 | P P P P P P P P | 2
1 | R N B Q K B N R | 1
  +----------------+
    a b c d e f g h
```

- **Uppercase** = White pieces (bold magenta)
- **Lowercase** = Black pieces (bold cyan)
- `*` = Available move
- Highlighted piece = Capturable

## Classical Opening Library

**Authenticated 12 classic chess openings** using the `load` command:
- Italian Game, Ruy López, Queen's Gambit
- Sicilian Four Knights, French Defense, King's Indian
- English Opening, Caro-Kann, Alekhine's Defense
- Scandinavian, Nimzo-Indian, King's Gambit

**All openings are engine-validated and historically accurate!**

**Study workflow:**
1. Type `load` and select an opening
2. Navigate through moves with ← → arrow keys
3. Press ENTER at any position to resume play
4. Practice continuations against AI

## Opening Validation Tools

**For advanced users and chess study:**

### Validate Opening Files
Verify that all FEN files contain legal positions:
```bash
./validate_openings                    # Check all opening files
./validate_openings FEN_FILES/RUY_LOPEZ.fen  # Check specific opening
```

### Convert Chess Moves to Positions
Generate clean FEN positions from standard PGN files:
```bash
./pgn_to_fen game.pgn > output.fen        # Convert PGN file to FEN
./pgn_to_fen < game.pgn > output.fen      # Pipe PGN file to converter
```

### Regenerate Opening Library
Recreate all openings from authentic move sequences:
```bash
./regenerate_openings  # Rebuild entire library with verified moves
```

**Use cases:**
- Study opening theory with verified positions
- Create custom opening collections
- Validate downloaded FEN files
- Generate training positions for analysis

## Building and Testing

```bash
make                    # Build chess and all utilities
make run               # Build and run chess game
make test              # Run micro-tests
make clean             # Clean build files
./test_compile_only.sh # Cross-platform compilation test
./validate_openings    # Verify opening library integrity
```

## Troubleshooting

- **Stockfish not found**: Ensure Stockfish is installed and in PATH
- **Compilation errors**: Install GCC and development tools
- **macOS timeout issues**: Install `gtimeout` with `brew install coreutils`









**For developers:** See `CLAUDE.md` for technical details and architecture.

## License

This is a demonstration chess implementation. Stockfish is licensed under 
GPL v3.