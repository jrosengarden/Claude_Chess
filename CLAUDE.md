# Claude Chess - Developer Reference

## Build System
```bash
make                    # Build chess, fen_to_pgn, pgn_to_fen, micro_test
make run               # Build and run chess game
make test              # Run micro-testing framework
make debug             # Build all debug programs
make utilities		   # Build all utility programs
make clean             # Clean all build artifacts
make install-deps      # Install Stockfish dependency
./test_compile_only.sh # Cross-platform compilation tests
```

## Project Architecture

### Core Files
- `main.c` - Game loop, UI, command handling (contains configuration system and command line parsing)
- `chess.h/chess.c` - Chess logic, move validation (2050+ lines)
- `stockfish.h/stockfish.c` - AI engine integration via UCI protocol
- `fen_to_pgn.c` - Standalone FEN-to-PGN conversion utility
- `pgn_to_fen.c` - PGN-to-FEN converter with chess engine validation
- `micro_test.c` - Safe testing framework (prevents Claude session crashes)
- `CHESS.ini` - Configuration file (auto-created on first run)

### Opening Validation Tools
- `validate_openings` - Comprehensive FEN file validator using chess engine
- `verify_openings` - Chess opening authenticity verification script
- `regenerate_openings` - Authentic opening sequence and tactical position generator

### Key Entry Points
- `get_possible_moves()` - Main move generation (chess.c)
- `is_valid_move()` - Move validation with check prevention (chess.c)
- `make_move()` - Execute move, update state, handle FEN counters and human promotion (chess.c)
- `execute_move()` - Execute move from Move structure, handles AI promotion (chess.c)
- `make_promotion_move()` - Execute pawn promotion with piece selection (chess.c)
- `is_promotion_move()` - Detect pawn promotion moves (chess.c)
- `get_promotion_choice()` - Interactive UI for promotion piece selection (chess.c)
- `parse_move_string()` - Parse UCI moves including promotion notation (stockfish.c)
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
    bool auto_create_pgn;       // Create PGN files on exit (true=PGNON, false=PGNOFF)
    bool auto_delete_fen;       // Delete FEN files on exit (true=FENOFF, false=FENON)
} ChessConfig;

// Global configuration tracking
bool fen_directory_overridden = false;
bool skill_level_overridden = false;
```

**Functions:**
- `load_config()` - Parse CHESS.ini, validate paths/values, parse boolean settings
- `create_default_config()` - Auto-create config with defaults (PGNON/FENON)
- `is_valid_directory()` - Path validation using stat() and opendir()
- `expand_path()` - Tilde expansion for paths

**Configuration Integration with Command Line:**
- Config file settings used as defaults on startup
- Command line options (PGNOFF/FENOFF) override config settings
- Global flags initialized from config: `suppress_pgn_creation = !config.auto_create_pgn`

**Boolean Value Parsing:**
- Flexible case-insensitive parsing: `true/false`, `yes/no`, `on/off`, `1/0`
- Invalid values ignored, keeping defaults
- Comprehensive documentation in auto-created config file

**Debug Output:**
- Invalid FENDirectory → WARNING + fallback to current directory
- Invalid DefaultSkillLevel → WARNING + fallback to level 5
- Configuration loaded successfully → shows all values including new boolean settings in DEBUG mode
- Active flags displayed: `suppress_pgn_creation`, `delete_fen_on_exit`

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

### Command Line Options System
**Implementation Architecture:**
- Case-insensitive parsing using `strcasecmp()` from `strings.h`
- Global boolean flags for option state tracking
- Comprehensive help system with `/HELP` option
- Exit-on-error for invalid options (prevents user confusion)
- **Configuration integration**: Options override config file settings

**Available Options:**
- `DEBUG` - Enable diagnostic output and debug mode
- `PGNOFF` - Suppress automatic PGN file creation on exit (overrides config)
- `FENOFF` - Delete FEN log file on exit (overrides config)
- `/HELP` - Display help information and exit with code 0

**Global State Variables:**
```c
bool debug_mode = false;
bool suppress_pgn_creation = false;  // PGNOFF flag
bool delete_fen_on_exit = false;     // FENOFF flag
```

**Configuration Integration Flow:**
1. `load_config()` called first to read CHESS.ini settings
2. Global flags initialized from config:
   - `suppress_pgn_creation = !config.auto_create_pgn`
   - `delete_fen_on_exit = config.auto_delete_fen`
3. Command line options parsed and override config settings
4. User can set preferences in config file and occasionally override via command line

**Key Functions:**
- `show_command_line_help()` - Display comprehensive help with examples
- Command line parsing in `main()` - Validates and sets option flags (after config loading)
- Enhanced exit logic - Respects PGNOFF/FENOFF flags at all exit points

**Exit Point Modifications:**
All 5 exit points updated with consistent logic:
1. Check `!suppress_pgn_creation` before calling `convert_fen_to_pgn()`
2. Check `delete_fen_on_exit` before calling `unlink(fen_log_filename)`
3. Order preserved: PGN creation → FEN deletion
4. Enhanced `show_game_files()` provides user feedback about option effects

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
./validate_openings        # Validate all FEN files in FEN_FILES/
./validate_openings file   # Validate specific FEN file
./verify_openings          # Verify authenticity of opening sequences and tactical positions
./verify_openings file     # Verify specific FEN file against expected patterns
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

### Enhanced UCI Move Parsing
**Promotion Move Support:**
- Standard 4-character moves: "e2e4", "a7a8"
- 5-character promotion moves: "e7e8q", "a2a1r", "h7h8n", "b2b1b"
- Automatic promotion piece extraction: q=QUEEN, r=ROOK, b=BISHOP, n=KNIGHT
- Invalid promotion characters default to non-promotion move

**Implementation:**
```c
Move parse_move_string(const char *move_str) {
    // Handles both 4-char and 5-char UCI notation
    // Populates is_promotion and promotion_piece fields
    // Integrates seamlessly with existing move system
}
```

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

## Pawn Promotion Implementation

### Complete Promotion System
**Architecture:** Seamlessly integrated with existing move system
- `is_promotion_move()` - Detects when pawn reaches opposite end (row 0 for WHITE, 
      row 7 for BLACK)
- `get_promotion_choice()` - Interactive UI prompting for Q/R/B/N selection with 
      validation
- `make_promotion_move()` - Executes promotion including captures and game state updates
- `is_valid_promotion_piece()` - Validates piece selection (QUEEN, ROOK, BISHOP, 
      KNIGHT only)

**Integration Points:**
- `make_move()` handles human promotion moves with interactive piece selection
- `execute_move()` handles AI promotion moves without user prompts
- Move structure extended with `is_promotion` flag and `promotion_piece` field
- UCI protocol parsing enhanced to handle 5-character promotion moves (e.g., "e7e8q")
- FEN notation system fully compatible (uses existing `set_piece_at()` mechanism)
- Comprehensive micro-tests covering all promotion scenarios including UCI parsing

**AI vs Human Promotion Logic:**
- **Human moves**: Interactive menu prompts for piece selection (Q/R/B/N)
- **AI moves**: Stockfish selects promotion piece via UCI notation, no user prompts
- **UCI Enhancement**: `parse_move_string()` extracts promotion piece from 5-char moves
- **Smart Routing**: `execute_move()` distinguishes between AI and human promotion contexts

**Game State Management:**
- Proper capture tracking when promotion involves capturing opponent piece
- Halfmove clock reset (pawn moves always reset to 0)
- Player switching and check status updates
- En passant state clearing (promotion cannot create en passant opportunities)
- Enhanced move display shows AI promotion choices (e.g., "promoted to Queen")

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

### Complete Chess Implementation
All core chess rules now fully implemented:
- ✅ Castling (kingside/queenside)
- ✅ En passant capture with FEN integration
- ✅ 50-move rule automatic draw detection
- ✅ Check/checkmate/stalemate detection
- ✅ **Pawn promotion** - Complete with interactive piece selection

### Recently Completed Major Features
- **Enhanced Configuration System** - CHESS.ini support for PGNOFF/FENOFF settings with config/command-line integration, DefaultSkillLevel + path validation
- **Command Line Options System** - PGNOFF, FENOFF, /HELP with case-insensitive parsing and config override
- **Enhanced File Management** - User control over PGN creation and FEN retention via config file or command line
- **Comprehensive Help System** - Built-in command line help with examples and usage
- **Pawn Promotion System** - Complete implementation with interactive UI and validation
- **AI Promotion Bug Fix** - AI now selects promotion pieces automatically without user prompts
- **Feature Demonstration Library** - Educational FEN files with comprehensive documentation
- **Dual Directory LOAD System** - Pagination + section headers
- **Interactive Game Browser** - Arrow key navigation
- **Live PGN Display with Auto-Updates** - Side-by-side terminal with real-time move updates
- **Starting Position File Cleanup** - Auto-removal of meaningless games
- **Complete FEN Counter System** - Standards-compliant tracking
- **Captured Pieces Calculation** - FEN/LOAD positions show previously captured pieces
- **Opening Library Validation System** - Engine-validated authentic classical openings
- **PGN-to-FEN Conversion Tools** - Create verified opening sequences

## Opening Library Management

### FEN File Validation
**Engine-Based Validation:**
- All FEN positions validated using actual chess engine
- Detects illegal moves, impossible positions, malformed FEN
- Batch validation of entire opening library (24 files: 12 openings + 12 demonstrations)
- Position-by-position error reporting
- Cross-platform compatible (macOS bash 3.2 + Linux bash 4+)

**Tools:**
```bash
./validate_openings                    # Validate all FEN files
./validate_openings FEN_FILES/RUY_LOPEZ.fen  # Validate specific file
```

### FEN File Authenticity Verification
**Pattern-Based Verification:**
- Verifies opening sequences match expected classical opening theory
- Verifies demonstration positions match expected tactical scenarios
- Two verification modes:
  - **Opening sequence files** (UPPERCASE): Generated sequences vs expected move patterns
  - **Demonstration files** (mixed case): Exact position matching for tactical scenarios
- Comprehensive reporting with detailed diff output for mismatches

**Tools:**
```bash
./verify_openings                      # Verify all FEN files against expected patterns
./verify_openings FEN_FILES/RUY_LOPEZ.fen  # Verify specific file authenticity
```

### Opening Sequence Generation
**PGN-to-FEN Converter:**
- Converts standard PGN files (with headers) to clean FEN position files
- Validates each move using chess engine during conversion
- Supports castling, en passant, move disambiguation
- Output: clean FEN strings compatible with LOAD function
- Full compatibility with fen_to_pgn utility (round-trip conversion)

**Usage:**
```bash
./pgn_to_fen game.pgn > output.fen        # Standard PGN file input
./pgn_to_fen < game.pgn > output.fen      # Stdin input
```

### Complete Chess Library
**24 Engine-Validated FEN Files:**

**Classical Opening Sequences (12 files - UPPERCASE names):**
- Each opening generated from historically accurate move sequences
- All positions legal and reachable through proper gameplay
- Suitable for study, testing, and competitive play
- Contents: Ruy Lopez, Italian Game, Queen's Gambit, King's Gambit, French Defense, Caro-Kann, Sicilian Four Knights, Alekhine's Defense, Scandinavian, Nimzo-Indian, English Opening, King's Indian Defense

**Tactical Demonstration Positions (12 files - mixed case names):**
- Single-position scenarios showcasing specific chess tactics
- Educational value for tactical training and study
- Each position demonstrates a specific chess concept
- Contents: BackRank, Castling, Check, Checkmate, Discovery, EnPassant, FiftyMoveRule, Fork, Pin, Promotion, Sacrifice, Stalemate

**Regeneration:**
```bash
./regenerate_openings  # Regenerate all 24 files: opening sequences + tactical positions
```

### Memory Management for Opening Tools
- `parse_algebraic_move()` - Static candidate array (64 positions max)
- `clean_move_string()` - In-place string modification
- `validate_single_fen()` - Temporary file creation/cleanup
- All tools use chess engine's existing memory management

## Planned Features

### Time Controls System (Next Implementation)

**Feature Specification:**
- Command: `TIME xx/yy` (xx=minutes per side, yy=increment seconds)
- Special case: `TIME 0/0` disables time controls entirely
- Default: 30/10 (30 minutes + 10 second increment) in CHESS.ini
- Display: Remaining time on captured pieces line (only when time controls active)
- Format: `White: 29:45 | Captured: [pieces] | Black: 28:30 | Captured: [pieces]`
- No time display when disabled: `White Captured: [pieces] | Black Captured: [pieces]`

**Technical Complexity: Medium-High**

#### Core Components Required

**Data Structures:**
```c
typedef struct {
    int minutes_per_side;
    int increment_seconds;
    bool enabled;
} TimeControl;

typedef struct {
    int white_time_seconds;     // Seconds remaining
    int black_time_seconds;
    time_t move_start_time;
    bool timing_active;
} GameTimer;
```

**Implementation Requirements:**

1. **Configuration Integration** (Low complexity)
   - Add `DefaultTimeControl=30/10` to CHESS.ini parsing
   - Validate time control format parsing
   - Runtime override via TIME command

2. **Timer Management System** (Medium complexity)
   - Standard POSIX timing (time() function)
   - Second-precision tracking during moves
   - Coordinate with Stockfish AI thinking time
   - Handle increment application after moves

3. **Display Integration** (Medium complexity)
   - Real-time timer updates during gameplay
   - Format time as MM:SS with low-time warnings
   - Integrate with existing captured pieces display
   - Conditional display logic (show/hide time based on TIME 0/0)
   - Maintain consistency across all game states

4. **Game Logic Integration** (Medium complexity)
   - Timer start/stop coordination with move system
   - Time forfeit detection and game termination
   - Undo system integration (restore timer states)
   - Distinguish AI vs human move timing

**Key Functions Needed:**
- `parse_time_control()` - Parse TIME xx/yy command format (handle 0/0 disable case)
- `init_game_timer()` - Initialize timer system with config
- `start_move_timer()` - Begin timing a player's move
- `stop_move_timer()` - End timing and apply increment
- `get_remaining_time_string()` - Format time for display (MM:SS)
- `check_time_forfeit()` - Detect time expiration (flag fall)
- `save_timer_state()` - Store timer state for undo system
- `restore_timer_state()` - Restore timer state on undo
- `is_time_control_enabled()` - Check if time controls are active (not 0/0)

**Technical Challenges:**

1. **Threading/Timing Architecture**
   - Current single-threaded design needs real-time updates
   - Options: polling approach vs signal-based vs background thread
   - Must not interfere with Stockfish UCI communication

2. **Cross-Platform Timing**
   - Standard POSIX time() function (universally available)
   - Second precision requirements
   - No special linking requirements

3. **AI Integration Complexity**
   - AI thinking time must not consume human clock
   - Coordinate increment timing with move execution
   - Handle Stockfish response timing accurately

4. **Undo System Enhancement**
   - Store timer state with each move in history
   - Handle multiple undos with accurate time restoration
   - Prevent timer manipulation exploits

**Files Requiring Modification:**
- `main.c` - Command parsing, display updates, timer coordination
- `chess.h/chess.c` - Game state integration, undo system extension
- `stockfish.c` - AI move timing coordination
- Configuration system - CHESS.ini DefaultTimeControl parsing

**Estimated Implementation:**
- Core timer system: 200-300 lines
- Display integration: 100-150 lines
- Configuration updates: 50-75 lines
- Testing framework: 100+ lines
- **Total: ~500-600 lines** across multiple files

**Risk Assessment:**
- **Medium risk** - Timing precision and threading complexity
- **Platform compatibility testing essential**
- **Undo system integration requires careful state management**
- **Well-scoped and feasible** within existing architecture

**Testing Requirements:**
- Cross-platform timing verification (second precision)
- Time forfeit scenario testing
- Undo/redo with timer state validation
- AI vs human timing coordination tests
- Configuration parsing and validation tests

---
*Developer reference for Claude Chess - Focused technical documentation*