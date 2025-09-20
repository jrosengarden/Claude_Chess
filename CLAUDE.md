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
5. **Claude development rule**: If debugging approaches fail 2-3 times, especially for
     platform-specific issues, use web search to find documented solutions

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
- **TIME Command Lock** - Prevents changing time controls after game starts (like SKILL command)

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

## Time Controls System (Complete Implementation)

### Overview
Complete time control system with separate White/Black time allocations and intelligent Stockfish search mode selection.

### Format Support
```
TIME xx/yy          # Same time controls for both players
TIME xx/yy/zz/ww    # White: xx/yy, Black: zz/ww
TIME 0/0            # Disable time controls (switches to depth-based search)
```

### Data Structures
```c
typedef struct {
    int white_minutes;          // Minutes allocated to White player
    int white_increment;        // Seconds added after each White move
    int black_minutes;          // Minutes allocated to Black player
    int black_increment;        // Seconds added after each Black move
    bool enabled;              // Whether time controls are active
} TimeControl;

typedef struct {
    int white_time_seconds;     // Seconds remaining for White player
    int black_time_seconds;     // Seconds remaining for Black player
    time_t move_start_time;     // When current player's move started
    bool timing_active;         // Whether timer is currently running
    Color timer_player;         // Which player the active timer belongs to
} GameTimer;
```

### Configuration Integration
**CHESS.ini DefaultTimeControl Setting:**
```ini
# Format: white_min/white_inc/black_min/black_inc OR min/inc (same for both)
# Examples: 30/10 (both get 30min+10sec), 30/10/5/0 (White 30/10, Black 5/0)
DefaultTimeControl=30/10/5/0
```

**Runtime Override:** `TIME` command during gameplay overrides config settings

### Key Implementation Features

#### 1. Intelligent Stockfish Search Mode Selection
**Automatic switching based on time controls:**

```c
// In get_best_move() - stockfish.c
if (is_time_control_enabled(game)) {
    // TIME-BASED SEARCH: Use actual time allocation
    int time_remaining = (game->current_player == WHITE) ?
                       game->timer.white_time_seconds :
                       game->timer.black_time_seconds;

    // Use ~1/20th of remaining time (min 500ms, max 10s)
    int move_time = (time_remaining * 1000) / 20;
    if (move_time < 500) move_time = 500;
    if (move_time > 10000) move_time = 10000;

    sprintf(go_command, "go movetime %d", move_time);
    send_command(engine, go_command);
} else {
    // DEPTH-BASED SEARCH: Fast, consistent difficulty
    send_command(engine, "go depth 10");
}
```

**Benefits:**
- **0/0 (disabled)**: Fast depth-10 search, instant moves, consistent difficulty
- **Any other setting**: Time-based search, realistic time consumption, dynamic difficulty

#### 2. Separate White/Black Time Allocations
**Purpose:** Address Stockfish's minimal time usage vs human thinking time

**Examples:**
- `30/10/5/0` - White: 30min+10s increment, Black: 5min+0s increment
- `15/5/15/5` - Equal time for both players
- `60/0/1/0` - Tournament pressure: White 60min, Black 1min

#### 3. Timer Management System
**Core Functions:**
```c
bool parse_time_control(const char* time_str, TimeControl* tc);     // Parse 2 or 4-value format
void init_game_timer(ChessGame* game, TimeControl* time_control);   // Initialize timers
void start_move_timer(ChessGame* game);                            // Start timing (with player tracking)
void stop_move_timer(ChessGame* game);                             // Stop and apply increment
char* get_remaining_time_string(int seconds);                     // Format MM:SS display
bool check_time_forfeit(ChessGame* game);                         // Time expiration detection
bool is_time_control_enabled(ChessGame* game);                    // Check if active
```

#### 4. Display Integration
**Format when time controls enabled:**
```
White: 29:45 | Captured: [pieces] | Black: 28:30 | Captured: [pieces]
```

**Format when disabled:**
```
White Captured: [pieces] | Black Captured: [pieces]
```

**Real-time Updates:** Timer display shows live countdown during active player's turn

#### 5. Undo System Integration
**Simple Solution:** Disable time controls for remainder of game after any undo
```c
// In undo logic
if (is_time_control_enabled(game)) {
    game->time_control.enabled = false;
    game->timer.timing_active = false;
    printf("Time controls have been disabled for the remainder of this game.\n");
}
```

**Rationale:** Avoids complex timer state restoration while maintaining game integrity

#### 6. Time Forfeit Detection
**Integration with game loop:**
```c
// Check before other game-ending conditions
if (check_time_forfeit(&game)) {
    Color winner = (game.current_player == WHITE) ? BLACK : WHITE;
    printf("\n*** TIME FORFEIT! %s WINS! ***\n", winner == WHITE ? "WHITE" : "BLACK");
    // Handle game termination
}
```

#### 7. Pondering Prevention
**Fair Play Enforcement:**
```c
// Disable pondering during Stockfish initialization
send_command(engine, "setoption name Ponder value false");
```
Prevents Stockfish from thinking during human player's time

### Usage Examples

#### Configuration Examples
```bash
# CHESS.ini settings
DefaultTimeControl=30/10        # Both players: 30min + 10s increment
DefaultTimeControl=30/10/5/0    # White: 30/10, Black: 5/0
DefaultTimeControl=0/0          # Time controls disabled
```

#### Runtime Commands
```bash
TIME 15/5           # Both get 15min + 5s increment
TIME 30/10/1/0      # White: 30/10, Black: 1min no increment
TIME 45/15/10/2     # White: 45/15, Black: 10/2
TIME 0/0            # Disable time controls (depth-10 search)
```

### Technical Implementation Details

#### Files Modified
- `chess.h` - Data structures, function declarations
- `chess.c` - Core timer functions, time parsing, display integration
- `main.c` - Configuration parsing, TIME command, display updates, undo integration
- `stockfish.h/stockfish.c` - Search mode selection, time-based thinking

#### Cross-Platform Compatibility
- Uses standard POSIX `time()` function
- Second-precision timing
- No special threading or linking requirements
- Tested on macOS 15.6.1 and Ubuntu 22.04

#### Memory Management
- Static time formatting buffer (no dynamic allocation)
- Automatic timer state cleanup
- No memory leaks in timer system

### Configuration File Auto-Generation
```ini
# Default time control setting
# Format: white_min/white_inc/black_min/black_inc OR min/inc (same for both)
# Examples: 30/10 (both get 30min+10sec), 30/10/5/0 (White 30/10, Black 5/0)
# Use 0/0 to disable time controls
# Can be overridden with 'TIME' command during gameplay
DefaultTimeControl=30/10/5/0
```

### Testing Coverage
- ✅ Time control parsing (2-value and 4-value formats)
- ✅ Timer state management and player tracking
- ✅ Search mode switching (depth vs time-based)
- ✅ Time forfeit detection
- ✅ Display integration and formatting
- ✅ Configuration file integration
- ✅ Undo system integration
- ✅ Cross-platform compatibility

### Performance Impact
- **Minimal overhead** when time controls disabled
- **Real-time display updates** without performance degradation
- **Efficient time calculations** using integer arithmetic
- **No impact** on existing chess logic or move generation

## Timer Control Features

### ✅ Feature 1: TIME Command Lock (IMPLEMENTED)

**Status:** ✅ **COMPLETED** - Simple flag-based protection successfully implemented
**Implementation:** Uses existing `game_started` flag pattern identical to SKILL command

#### Implementation Details:
```c
// In main.c, line 1656-1660:
if (strncmp(input, "time ", 5) == 0 || strncmp(input, "TIME ", 5) == 0) {
    if (game_started) {
        printf("\nTime controls cannot be changed after the game has started!\n");
        printf("Use this command only before making your first move.\n");
    } else {
        // Existing TIME parsing code...
    }
}
```

**Result:** TIME command now locked after first move, preventing mid-game time control changes
**Files modified:** `main.c` only (6 lines added)
**Testing:** ✅ All micro-tests pass, zero compilation warnings

### Feature 2: Live Timer Display Updates

**Possibility:** 🟡 **Medium-High** - Requires architecture changes
**Difficulty:** 🟠 **Medium-High** - Threading/signal complexity

#### Technical Challenges:
**Current Architecture:** Single-threaded, turn-based updates
**Required:** Real-time updates during player thinking time

#### Implementation Options:

**Option A: Polling Approach (Easier)**
```c
// In get_user_input() - check timer every second during input wait
while (!input_ready) {
    if (timer_needs_update()) {
        update_timer_display();
    }
    usleep(100000); // 100ms polling
}
```
**Pros:** No threading, simpler
**Cons:** Busy waiting, less responsive

**Option B: Signal-Based (Better)**
```c
// Set up SIGALRM for 1-second intervals
signal(SIGALRM, timer_update_handler);
alarm(1);
```
**Pros:** Efficient, precise timing
**Cons:** Signal handling complexity

**Option C: Background Thread (Most Complex)**
```c
pthread_t timer_thread;
pthread_create(&timer_thread, NULL, timer_update_function, &game);
```
**Pros:** True real-time updates
**Cons:** Threading complexity, platform compatibility

#### Key Technical Issues:
1. **Input handling coordination** - Timer updates during `fgets()` calls
2. **Display refresh** - Screen positioning and cursor management
3. **Thread safety** - Protecting shared game state
4. **Platform compatibility** - POSIX signals vs threading

#### Estimated Implementation:
- **Option A (Polling):** 100-150 lines, Medium complexity
- **Option B (Signals):** 150-200 lines, Medium-High complexity
- **Option C (Threading):** 200-300 lines, High complexity

#### Recommendation:
**Option B (Signal-based)** offers the best balance of functionality and complexity for the current codebase architecture.

#### Screen Flicker Analysis for Option B:

**Flicker Risk:** 🟡 **Potential but preventable** - depends on implementation approach

**Flicker Prevention Strategy (Recommended):**
```c
// Signal handler - minimal work only
void timer_signal_handler(int sig) {
    timer_update_needed = true;  // Just set flag
    alarm(1);  // Reset for next second
}

// In main game loop - targeted updates only
if (timer_update_needed && is_time_control_enabled(&game)) {
    // Save cursor position
    printf("\033[s");

    // Move to timer line only (no board redraw)
    printf("\033[%d;1H", TIMER_LINE_NUMBER);

    // Update just the timer portion
    print_captured_pieces(game);

    // Restore cursor position
    printf("\033[u");
    fflush(stdout);

    timer_update_needed = false;
}
```

**Key Flicker Prevention:**
- **ANSI escape sequences** for precise cursor control
- **Line-specific updates** instead of full screen redraws
- **Buffered output** with strategic `fflush()` calls
- **Signal safety** - minimal work in signal handler

**Expected Result:** No visible flicker - only timer numbers change, board remains static. This approach is used successfully in terminal applications like `htop` and `top`.

**Both features are implementable, with TIME lock being trivial and live timer updates requiring moderate architectural changes.**

---
*Developer reference for Claude Chess - Focused technical documentation*