# Claude Chess

A complete terminal chess game with AI opponent and comprehensive study features.

**Quick Start:** `make && make run`

## Features

### Core Gameplay
- Complete chess rules with all standard piece movements
- Castling (kingside/queenside), en passant, 50-move rule, and **pawn promotion**
- Clean ASCII board display with coordinates
- Move visualization with `*` and highlighted captures
- Unlimited undo functionality
- AI opponent powered by Stockfish (adjustable difficulty 0-20)
- **Command line options** for customizing file creation and debug output

### Game Analysis & Study
- Position evaluation with visual scoring scale (-9 to +9)
- **Live PGN display** in side-by-side terminal windows that updates automatically after 
   each move
- Custom board setup using FEN notation
- Interactive game loading with arrow key navigation
- **Verified classical opening library** (12 authenticated openings)
- **Verified demonstration opening library** (12 authenticated demo fen files)
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

## Command Line Options

The chess program supports several command line options for customizing behavior:

```bash
chess [options]
```

**Available options** (case-insensitive, can be used in any order):

- **`DEBUG`** - Enable debug mode with diagnostic output
- **`PGNOFF`** - Suppress automatic PGN file creation on game exit
- **`FENOFF`** - Delete FEN log file on game exit (after PGN creation)
- **`/HELP`** - Display detailed help information and exit

**Examples:**
```bash
chess                    # Start normal game
chess DEBUG              # Start with debug output
chess PGNOFF             # No PGN file created on exit
chess FENOFF             # FEN file deleted on exit
chess PGNOFF FENOFF      # No files saved on exit
chess debug pgnoff       # Mixed case works fine
chess /help              # Show detailed help
```

**Notes:**
- All options are case-insensitive (`DEBUG`, `debug`, `Debug` all work)
- Options can be combined in any order
- **Configuration integration**: Options override settings in CHESS.ini file
- **Set preferences in config**: Use CHESS.ini to avoid typing options repeatedly
- Use `chess /help` for detailed descriptions and more examples
- Invalid options will show an error and exit (won't start the game)

## How to Play

**Basic Controls:**
- Move: `e2 e4` (algebraic notation)
- Castling: `e1 g1` (move king two squares)
- **Pawn promotion**: Automatic when pawn reaches end - choose Q/R/B/N
	- Black (Stockfish) decides on it's promotion piece choice
- View moves: `e2` (show possible moves & captures from e2)
	[Captures appear in reverse text block]
- Undo: `undo` (unlimited)

**Game Flow:**
- You play White, AI (Stockfish) plays Black
- Clean single-board interface
- Automatic detection of checkmate, stalemate, draws
- **Interactive pawn promotion** with piece selection menu
- All games automatically saved as FEN and PGN files
- **File saving preferences**: Configure in CHESS.ini or use command line options

## Commands

### Gameplay
- `help` - Show help
- `hint` - Get AI's best move suggestion
- `skill N` - Set AI difficulty (0-20, before first move only)
- `undo` - Unlimited undo
- `resign` - Resign with confirmation
- `quit` - Exit game
- `title`- Redisplay game startup title screen

### Analysis & Study
- `score` - Position evaluation (-9 to +9 scale)
- `scale` - Shows conversion scale between Stockfish & Game
	-  Stockfish Centipawns score converted to Chess Game -9/+9 scale
- `pgn` - View game in standard notation (live-updating side-by-side window)
- `fen` - View Current position in FEN format
	- Can use OS copy cmd to copy current board in FEN format
- `setup` - Configure custom position from FEN
- `load` - Browse saved games with arrow key navigation

### Special Features
- **Verified classical opening library** accessible via `load` command
- **Verified demonstration tactical library** accessible via `load` command
- All games auto-saved as timestamped FEN and PGN files (customizable via config 
     file or command line)
- **Enhanced configuration system** via `CHESS.ini` file with file management preferences
- **Opening validation utilities** for study and analysis
- **Command line help system** with `/help` option for user guidance

## Configuration (CHESS.ini)

Auto-created configuration file with settings:

```ini
[Paths]
FENDirectory=.                    # Directory for saved games

[Settings]
DefaultSkillLevel=5               # AI difficulty (0-20)
AutoCreatePGN=true               # Create PGN files on exit (true=PGNON, false=PGNOFF)
AutoDeleteFEN=false              # Delete FEN files on exit (true=FENOFF, false=FENON)
```

**Customization:**
- Move FEN files to custom directory and update `FENDirectory`
- Set default AI skill level
- **Configure file management preferences**: Set `AutoCreatePGN=false` for PGNOFF 
     behavior, `AutoDeleteFEN=true` for FENOFF behavior
- **Boolean values**: Use `true/false`, `yes/no`, `on/off`, or `1/0` (case-insensitive)
- **Command line override**: Command line options (PGNOFF/FENOFF) override config file 
     settings
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

## Pawn Promotion

When a pawn reaches the opposite end of the board (8th rank for White, 1st rank for 
   Black), it **automatically promotes** as follows:

### Human Player (White)
You'll see this interactive menu when your pawn promotes:

```
Pawn promotion! Choose a piece to promote to:
Q - Queen (most powerful)
R - Rook
B - Bishop
N - Knight
Enter choice (Q/R/B/N):
```

Simply enter your choice (Q/R/B/N) and the pawn will transform into your selected piece.

### AI Player (Black)
The AI (Stockfish) **automatically selects** its preferred promotion piece without asking 
   you. The game will display the AI's choice:

```
AI played: e7 to e8 (promoted to Queen)
```

This works for both regular promotion moves and promotion captures.

## Classical Opening Library

**Authenticated 12 classic chess openings** plus **feature demonstration files** using 
  the `load` command:

**Classical Openings:**
- Italian Game, Ruy López, Queen's Gambit
- Sicilian Four Knights, French Defense, King's Indian
- English Opening, Caro-Kann, Alekhine's Defense
- Scandinavian, Nimzo-Indian, King's Gambit

**Feature Demonstrations:**
- Castling, En Passant, Pawn Promotion, Check, Checkmate, Stalemate
- Tactical concepts: Fork, Pin, Discovered Attack, Sacrifice, Back Rank

**All files are engine-validated and historically accurate!**

**Study workflow:**
1. Type `load` and select an opening or demonstration
2. Navigate through moves with ← → arrow keys (openings only)
3. Press ENTER at any position to resume play
	- New time stamped FEN file created containing all moves from
	  the original game up to the point selected to continue play.
	  At that point normal move/FEN loggin continues
4. Practice continuations against AI

**Feature Demonstrations:** Load any demo file to see chess rules and tactics in action. 
   See `DEMONSTRATIONS.md` in the FEN_FILES directory for detailed explanations and 
   suggested moves for each demonstration.

## Opening Validation Tools

**For advanced users and chess study:**

### Validate Opening Files
Verify that all FEN files contain legal chess positions:
```bash
./validate_openings                  # Check all 24 FEN files (openings + demonstrations)
./validate_openings FEN_FILES/RUY_LOPEZ.fen  # Check specific opening
```

### Verify Opening Authenticity
Confirm that opening files match expected patterns and tactical demonstrations are 
     correct:
```bash
./verify_openings                      # Verify all files against expected patterns
./verify_openings FEN_FILES/BackRank.fen  # Verify specific tactical position
```

### Convert Chess Moves to Positions (pgn_to_fen)
Generate clean FEN positions from standard PGN files:
```bash
./pgn_to_fen game.pgn > output.fen        # Convert PGN file to FEN
./pgn_to_fen < game.pgn > output.fen      # Pipe PGN file to converter
```

### Convert Chess Moves to Positions (fen_to_pgn)
Generate clean, standard,  PGN file from FEN files:
```bash
./fen_to_pgn 							  # Convert FEN to PGN
	(will request .fen file to convert)      
	(will output valid, standard, PGN file with same name as FEN file)
```

### Regenerate Complete Chess Library
Recreate all 24 FEN files from authentic sources:
```bash
./regenerate_openings  # Rebuild all openings + tactical demonstrations with 
     verified content
```

**Use cases:**
- Study opening theory with verified classical sequences (12 openings)
- Practice chess tactics with demonstration positions (12 tactical scenarios)
- Create custom opening collections from PGN files
- Validate downloaded FEN files for legal positions
- Verify authenticity of chess position libraries

## Building and Testing

```bash
make                   # Build chess and all utilities
make all			   # Build chess and all utilities
make debug			   # Build debug programs only
make utilities		   # Build utility programs only
make run               # Build and run chess game
make test              # Run micro-tests
make clean             # Clean build files
./test_compile_only.sh # Cross-platform compilation test
./validate_openings    # Verify chess library integrity (legal positions)
./verify_openings      # Verify library authenticity (opening theory + tactics)
```

## Troubleshooting

- **Stockfish not found**: Ensure Stockfish is installed and in PATH
- **Compilation errors**: Install GCC and development tools
- **macOS timeout issues**: Install `gtimeout` with `brew install coreutils`









**For developers:** See `CLAUDE.md` for technical details and architecture.

## License

This is a demonstration chess implementation. Stockfish is licensed under 
GPL v3.