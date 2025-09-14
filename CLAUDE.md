# Claude Chess - Developer Reference

## Build System
```bash
make                    # Build chess, fen_to_pgn, micro_test
make run               # Build and run chess game
make test              # Run micro-testing framework
make debug             # Build all debug programs
make clean             # Clean all build artifacts
make install-deps      # Install Stockfish dependency
./test_compile_only.sh # Cross-platform compilation tests
```

## Project Architecture

### Core Files
- `main.c` - Game loop, UI, command handling (contains configuration system)
- `chess.h/chess.c` - Chess logic, move validation (2050+ lines)
- `stockfish.h/stockfish.c` - AI engine integration via UCI protocol
- `fen_to_pgn.c` - Standalone FEN-to-PGN conversion utility
- `micro_test.c` - Safe testing framework (prevents Claude session crashes)
- `CHESS.ini` - Configuration file (auto-created on first run)

### Key Entry Points
- `get_possible_moves()` - Main move generation (chess.c)
- `is_valid_move()` - Move validation with check prevention (chess.c)
- `make_move()` - Execute move, update state, handle FEN counters (chess.c)
- `is_in_check()` - Check detection (chess.c)
- `get_best_move()` - AI move request via Stockfish (stockfish.c)
- `board_to_fen()` - Convert board to FEN with accurate counters (stockfish.c)
- `setup_board_from_fen()` - Parse FEN, configure game state (chess.c)
- `get_king_moves_no_castling()` - King moves without castling (chess.c)

### Configuration System (CHESS.ini)
```c
typedef struct {
    char fen_directory[512];
    int default_skill_level;
} ChessConfig;

// Global configuration tracking
bool fen_directory_overridden = false;
bool skill_level_overridden = false;
```

**Functions:**
- `load_config()` - Parse CHESS.ini, validate paths/values
- `create_default_config()` - Auto-create config with defaults
- `is_valid_directory()` - Path validation using stat() and opendir()
- `expand_path()` - Tilde expansion for paths

**Debug Output:**
- Invalid FENDirectory → WARNING + fallback to current directory
- Invalid DefaultSkillLevel → WARNING + fallback to level 5
- Configuration loaded successfully → shows values in DEBUG mode

### LOAD System Architecture
**Dual Directory Scanning:**
- `scan_fen_files()` - Master function coordinating dual scan
- `scan_single_directory()` - Helper for scanning individual directories
- `handle_load_command()` - Pagination and display logic

**Features:**
- Scans current directory AND FENDirectory
- Duplicate detection (current dir takes precedence)
- Section headers: "Chess Program Directory" / "FEN Files Directory"
- 20-line pagination with screen clearing

## Core Data Structures

### ChessGame Struct
```c
typedef struct {
    Piece board[8][8];
    Color current_player;
    Position white_king_pos, black_king_pos;
    bool white_king_moved, black_king_moved;
    bool white_rook_kingside_moved, white_rook_queenside_moved;
    bool black_rook_kingside_moved, black_rook_queenside_moved;
    char en_passant_target;
    bool en_passant_available;
    int halfmove_clock;      // For 50-move rule
    int fullmove_number;     // Chess move pair counter
} ChessGame;
```

### Memory Management Critical Notes
- `board_to_fen()` returns **static buffer** - DO NOT free()
- Always use proper cleanup in dynamic allocations
- FEN log file handles require explicit closure

## Testing Framework

### Session Crash Prevention (CRITICAL)
**NEVER run full games during development - Claude sessions ALWAYS crash**
- Use `make test` for safe micro-testing only
- NEVER use `./chess` directly for internal testing
- User tests full games in separate terminal sessions
- Session crashes are #1 cause of lost development progress

### Available Tests
```bash
make test                  # Safe micro-tests
./test_compile_only.sh    # Cross-platform compilation
```

## Platform Compatibility

### Required Feature Test Macros
```c
#define _GNU_SOURCE        // Required for Linux (strdup, fdopen)
```

### Cross-Platform Build Detection
```bash
# test_compile_only.sh automatically detects:
timeout    # Linux systems
gtimeout   # macOS systems
```

## UCI Protocol Integration

### AI Difficulty System
```c
// Stockfish skill level control (0-20)
set_skill_level(int level)  // stockfish.c
```

**Game State Protection:**
- `game_started` flag prevents mid-game skill changes
- Range validation (0-20)
- UCI command: "setoption name Skill Level value N"

### Position Evaluation
```c
get_position_evaluation()   // Real-time Stockfish analysis
centipawns_to_scale()      // Convert to -9/+9 visual scale
```

## FEN Counter Implementation

### Counter Logic (chess standards compliant)
```c
// In make_move():
if (pawn_move || capture) {
    game->halfmove_clock = 0;
} else {
    game->halfmove_clock++;
}
if (game->current_player == BLACK) {
    game->fullmove_number++;
}
```

### 50-Move Rule
```c
is_fifty_move_rule_draw()  // Automatic draw detection
// Triggers at halfmove_clock >= 100 (50 full moves)
```

## Critical Bug Fixes Implemented

### Infinite Recursion Fix (Complex FEN Strings)
**Problem:** `is_in_check()` → `is_square_attacked()` → `get_possible_moves()`
→ `get_king_moves()` → `is_square_attacked()` (infinite loop)

**Solution:** Created `get_king_moves_no_castling()` for attack checking
- Modified `is_square_attacked()` to use non-castling king moves
- Prevents recursion while maintaining castling logic integrity

## Development Standards

### Mandatory Requirements
1. **Dual OS Compatibility** - macOS 15.6.1 + Ubuntu 22.04.2
2. **Clean Compilation** - Zero warnings on both platforms
3. **Testing Verification** - All changes tested on both OS
4. **Comprehensive Comments** - All new code fully documented

### Development Workflow (CRITICAL)
**After ANY code changes, ALWAYS:**
1. **Test Clean Compilation** - `make clean && make` (zero warnings required)
2. **Run Micro Tests** - `make test` (all tests must pass)
3. **Verify Functionality** - Ensure no regressions introduced

### Code Documentation Standards
- File headers with purpose, features, architecture
- Function-level docs with parameters/return values
- Inline comments for complex algorithms
- Professional standards established for future development

## Active Development Status

### Next Priority: Pawn Promotion
All core chess rules implemented except pawn promotion:
- ✅ Castling (kingside/queenside)
- ✅ En passant capture with FEN integration
- ✅ 50-move rule automatic draw detection
- ✅ Check/checkmate/stalemate detection
- 🔄 **Pawn promotion** - Next implementation target

### Recently Completed Major Features
- **Enhanced Configuration System** - DefaultSkillLevel + path validation
- **Dual Directory LOAD System** - Pagination + section headers
- **Interactive Game Browser** - Arrow key navigation
- **Side-by-Side PGN Display** - Cross-platform terminal detection
- **Starting Position File Cleanup** - Auto-removal of meaningless games
- **Complete FEN Counter System** - Standards-compliant tracking
- **Captured Pieces Calculation** - FEN/LOAD positions show previously captured pieces

---
*Developer reference for Claude Chess - Focused technical documentation*