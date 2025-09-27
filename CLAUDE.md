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
- `main.c` - Game loop, UI, command handling (contains configuration
    system and command line parsing)
- `chess.h/chess.c` - Chess logic, move validation (2050+ lines)
- `stockfish.h/stockfish.c` - AI engine integration via UCI protocol
- `pgn_utils.h/pgn_utils.c` - PGN conversion utilities (extracted from chess.c)
- `fen_to_pgn.c` - Standalone FEN-to-PGN conversion utility
- `pgn_to_fen.c` - PGN-to-FEN converter with chess engine validation
- `micro_test.c` - Safe testing framework (prevents Claude session crashes)
- `CHESS.ini` - Configuration file (auto-created on first run)

### Opening Validation Tools
- `validate_openings` - Comprehensive FEN file validator using chess engine
- `verify_openings` - Chess opening authenticity verification script
- `regenerate_openings` - Authentic opening sequence and tactical
    position generator

### Key Entry Points
- `get_possible_moves()` - Main move generation (chess.c)
- `is_valid_move()` - Move validation with check prevention (chess.c)
- `make_move()` - Execute move, update state, handle FEN counters and
    human promotion (chess.c)
- `execute_move()` - Execute move from Move structure, handles AI
    promotion (chess.c)
- `make_promotion_move()` - Execute pawn promotion with piece
    selection (chess.c)
- `is_promotion_move()` - Detect pawn promotion moves (chess.c)
- `get_promotion_choice()` - Interactive UI for promotion piece
    selection (chess.c)
- `parse_move_string()` - Parse UCI moves including promotion
    notation (stockfish.c)
- `is_in_check()` - Check detection (chess.c)
- `get_best_move()` - AI move request via Stockfish (stockfish.c)
- `get_hint_move()` - Fast hint request using depth-based search (stockfish.c)
- `board_to_fen()` - Convert board to FEN with accurate counters (stockfish.c)
- `setup_board_from_fen()` - Parse FEN, configure game state (chess.c)
- `get_king_moves_no_castling()` - King moves without castling (chess.c)

### Configuration System (CHESS.ini)
```c
typedef struct {
    char fen_directory[512];    // Path to directory containing FEN files
    char pgn_directory[512];    // Path to directory containing PGN files
    int default_skill_level;
    bool auto_create_pgn;       // Create PGN files on exit
                                 // (true=PGNON, false=PGNOFF)
    bool auto_delete_fen;       // Delete FEN files on exit
                                 // (true=FENOFF, false=FENON)
    char default_time_control[16]; // Default time control (e.g., "30/10")
} ChessConfig;

// Global configuration tracking
bool fen_directory_overridden = false;
bool skill_level_overridden = false;
```

**Functions:**
- `load_config()` - Parse CHESS.ini, validate paths/values, parse
    boolean settings
- `create_default_config()` - Auto-create config with defaults (PGNON/FENON)
- `is_valid_directory()` - Path validation using stat() and opendir()
- `expand_path()` - Tilde expansion for paths

**Configuration Integration with Command Line:**
- Config file settings used as defaults on startup
- Command line options (PGNOFF/FENOFF) override config settings
- Global flags initialized from config:
    `suppress_pgn_creation = !config.auto_create_pgn`

**Boolean Value Parsing:**
- Flexible case-insensitive parsing: `true/false`, `yes/no`, `on/off`, `1/0`
- Invalid values ignored, keeping defaults
- Comprehensive documentation in auto-created config file

**Debug Output:**
- Invalid FENDirectory → WARNING + fallback to current directory
- Invalid DefaultSkillLevel → WARNING + fallback to level 5
- Configuration loaded successfully → shows all values including new
    boolean settings in DEBUG mode
- Active flags displayed: `suppress_pgn_creation`, `delete_fen_on_exit`

### LOAD System Architecture
**Dual Command Structure:**
- `load` - Shows help for both LOAD FEN and LOAD PGN commands
- `load fen` - Browse and load FEN games (renamed from original `load`)
- `load pgn` - Browse and load PGN games with full move-by-move navigation

**FEN Loading Functions:**
- `scan_fen_files()` - Master function coordinating dual FEN scan
- `scan_single_directory()` - Helper for scanning individual
    directories for .fen files
- `handle_load_fen_command()` - FEN pagination and display logic
- **Smart filtering**: Excludes current game's FEN file from display

**PGN Loading Functions:**
- `scan_pgn_files()` - Master function coordinating dual PGN scan
- `scan_single_directory_pgn()` - Helper for scanning individual
    directories for .pgn files
- `handle_load_pgn_command()` - PGN pagination and display logic
- `load_pgn_positions()` - Converts PGN to FEN positions using
    `pgn_to_fen` utility

**Shared Features:**
- Dual directory scanning (current directory + configured directory)
- Duplicate detection (current dir takes precedence)
- Section headers: "Chess Program Directory" / "FEN Files Directory"
    or "PGN Files Directory"
- 20-line pagination with screen clearing
- **Save current game prompt**: User chooses whether to save current
    game before loading

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
4. User can set preferences in config file and occasionally override
    via command line

**Key Functions:**
- `show_command_line_help()` - Display comprehensive help with examples
- Command line parsing in `main()` - Validates and sets option flags
    (after config loading)
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

### LOAD System Data Structures

**File Information Structures:**
```c
typedef struct {
    char filename[256];
    char display_name[300];  // Larger buffer to accommodate filename +
                             // formatting
    int move_count;
    time_t timestamp;
    bool from_current_dir;  // true if from current directory, false if
                            // from FENDirectory
} FENGameInfo;

typedef struct {
    char filename[256];
    char display_name[300];  // Larger buffer to accommodate filename +
                             // formatting
    int move_count;
    time_t timestamp;
    bool from_current_dir;  // true if from current directory, false if
                            // from PGNDirectory
} PGNGameInfo;
```

**Navigation Structure:**
```c
typedef struct {
    char **positions;     // Array of FEN strings
    int count;           // Number of positions
    int current;         // Current position index
} FENNavigator;
```

**Key Features:**
- **FENGameInfo**: Used by `scan_fen_files()` and
    `scan_single_directory()` for FEN file metadata
- **PGNGameInfo**: Mirror structure for PGN files with identical functionality
- **FENNavigator**: Shared by both FEN and PGN systems for position navigation
- **Smart filtering**: FEN scanner excludes current game's file using
    `fen_log_filename`
- **Dual directory support**: Both structures track source directory
    for proper section headers

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
./verify_openings          # Verify authenticity of opening sequences
                            # and tactical positions
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
- `is_promotion_move()` - Detects when pawn reaches opposite end
    (row 0 for WHITE, row 7 for BLACK)
- `get_promotion_choice()` - Interactive UI prompting for Q/R/B/N
    selection with validation
- `make_promotion_move()` - Executes promotion including captures and
    game state updates
- `is_valid_promotion_piece()` - Validates piece selection (QUEEN,
    ROOK, BISHOP, KNIGHT only)

**Integration Points:**
- `make_move()` handles human promotion moves with interactive piece selection
- `execute_move()` handles AI promotion moves without user prompts
- Move structure extended with `is_promotion` flag and `promotion_piece` field
- UCI protocol parsing enhanced to handle 5-character promotion moves
    (e.g., "e7e8q")
- FEN notation system fully compatible (uses existing `set_piece_at()`
    mechanism)
- Comprehensive micro-tests covering all promotion scenarios including
    UCI parsing

**AI vs Human Promotion Logic:**
- **Human moves**: Interactive menu prompts for piece selection (Q/R/B/N)
- **AI moves**: Stockfish selects promotion piece via UCI notation, no
    user prompts
- **UCI Enhancement**: `parse_move_string()` extracts promotion piece
    from 5-char moves
- **Smart Routing**: `execute_move()` distinguishes between AI and
    human promotion contexts

**Game State Management:**
- Proper capture tracking when promotion involves capturing opponent piece
- Halfmove clock reset (pawn moves always reset to 0)
- Player switching and check status updates
- En passant state clearing (promotion cannot create en passant opportunities)
- Enhanced move display shows AI promotion choices (e.g., "promoted to Queen")

## Critical Bug Fixes Implemented

### Infinite Recursion Fix (Complex FEN Strings)
**Problem:** `is_in_check()` → `is_square_attacked()` →
`get_possible_moves()` → `get_king_moves()` → `is_square_attacked()`
(infinite loop)

**Solution:** Created `get_king_moves_no_castling()` for attack checking
- Modified `is_square_attacked()` to use non-castling king moves
- Prevents recursion while maintaining castling logic integrity

## Development Standards

### Mandatory Requirements
1. **Dual OS Compatibility** - macOS 15.6.1 + Ubuntu 22.04.2
2. **Clean Compilation** - Zero warnings on both platforms
3. **Testing Verification** - All changes tested on both OS
4. **Comprehensive Comments** - All new code fully documented
5. **Claude development rule**: If debugging approaches fail 2-3 times,
     especially for platform-specific issues, use web search to find
     documented solutions
6. **chess.c Organization Rule** (CRITICAL): When adding new functions to
     chess.c, they MUST be placed in the appropriate logical section AND
     the Table of Contents at the top of the file MUST be updated to
     include the new function with a brief description. The 8 sections are:
     Board Management, Position & Utility, Move Generation, Move Validation,
     Pawn Promotion, Move Execution, FEN System, and Time Control.

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
- **Enhanced Configuration System** - CHESS.ini support for
    PGNOFF/FENOFF settings with config/command-line integration,
    DefaultSkillLevel + path validation
- **Command Line Options System** - PGNOFF, FENOFF, /HELP with
    case-insensitive parsing and config override
- **Enhanced File Management** - User control over PGN creation and FEN
    retention via config file or command line
- **Comprehensive Help System** - Built-in command line help with
    examples and usage
- **Help Pagination System** - Generic 11-lines-per-page display with
    continuation headers
- **Pawn Promotion System** - Complete implementation with interactive
    UI and validation
- **AI Promotion Bug Fix** - AI now selects promotion pieces
    automatically without user prompts
- **Feature Demonstration Library** - Educational FEN files with
    comprehensive documentation
- **Dual Command LOAD System** - Separate `load fen` and `load pgn`
    commands with shared navigation
- **PGN File Loading System** - Complete PGN parsing and conversion to
    FEN positions for navigation
- **Smart FEN Filtering** - Current game's FEN file excluded from LOAD
    FEN display
- **Save Current Game Prompt** - User choice to save/discard current
    game when loading new position
- **Interactive Game Browser** - Arrow key navigation
- **Live PGN Display with Auto-Updates** - Side-by-side terminal with
    real-time move updates
- **Starting Position File Cleanup** - Auto-removal of meaningless games
- **Complete FEN Counter System** - Standards-compliant tracking
- **Captured Pieces Calculation** - FEN/LOAD positions show previously
    captured pieces
- **Opening Library Validation System** - Engine-validated authentic
    classical openings
- **PGN-to-FEN Conversion Tools** - Create verified opening sequences
- **TIME Command Lock** - Prevents changing time controls after game
    starts (like SKILL command)
- **HINT System Optimization** - Separated fast hint requests from
    time-controlled AI moves to prevent burning user's time during hints

## Opening Library Management

### FEN File Validation
**Engine-Based Validation:**
- All FEN positions validated using actual chess engine
- Detects illegal moves, impossible positions, malformed FEN
- Batch validation of entire opening library (24 files: 12 openings +
    12 demonstrations)
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
  - **Opening sequence files** (UPPERCASE): Generated sequences vs
      expected move patterns
  - **Demonstration files** (mixed case): Exact position matching for
      tactical scenarios
- Comprehensive reporting with detailed diff output for mismatches

**Tools:**
```bash
./verify_openings                      # Verify all FEN files against
                                        # expected patterns
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
- Contents: Ruy Lopez, Italian Game, Queen's Gambit, King's Gambit,
    French Defense, Caro-Kann, Sicilian Four Knights, Alekhine's Defense,
    Scandinavian, Nimzo-Indian, English Opening, King's Indian Defense

**Tactical Demonstration Positions (12 files - mixed case names):**
- Single-position scenarios showcasing specific chess tactics
- Educational value for tactical training and study
- Each position demonstrates a specific chess concept
- Contents: BackRank, Castling, Check, Checkmate, Discovery, EnPassant,
    FiftyMoveRule, Fork, Pin, Promotion, Sacrifice, Stalemate

**Regeneration:**
```bash
./regenerate_openings  # Regenerate all 24 files: opening sequences +
                        # tactical positions
```

### Memory Management for Opening Tools
- `parse_algebraic_move()` - Static candidate array (64 positions max)
- `clean_move_string()` - In-place string modification
- `validate_single_fen()` - Temporary file creation/cleanup
- All tools use chess engine's existing memory management

## Time Controls System (Complete Implementation)

### Overview
Complete time control system with separate White/Black time allocations
and intelligent Stockfish search mode selection.

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
- **Any other setting**: Time-based search, realistic time consumption,
    dynamic difficulty

#### 2. Separate White/Black Time Allocations
**Purpose:** Address Stockfish's minimal time usage vs human thinking time

**Examples:**
- `30/10/5/0` - White: 30min+10s increment, Black: 5min+0s increment
- `15/5/15/5` - Equal time for both players
- `60/0/1/0` - Tournament pressure: White 60min, Black 1min

#### 3. Timer Management System
**Core Functions:**
```c
bool parse_time_control(const char* time_str, TimeControl* tc);
    // Parse 2 or 4-value format
void init_game_timer(ChessGame* game, TimeControl* time_control);
    // Initialize timers
void start_move_timer(ChessGame* game);
    // Start timing (with player tracking)
void stop_move_timer(ChessGame* game);
    // Stop and apply increment
char* get_remaining_time_string(int seconds);
    // Format MM:SS display
bool check_time_forfeit(ChessGame* game);
    // Time expiration detection
bool is_time_control_enabled(ChessGame* game);
    // Check if active
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

**Real-time Updates:** Timer display shows live countdown during active
player's turn

#### 5. Undo System Integration
**Simple Solution:** Disable time controls for remainder of game after any undo
```c
// In undo logic
if (is_time_control_enabled(game)) {
    game->time_control.enabled = false;
    game->timer.timing_active = false;
    printf("Time controls have been disabled for the remainder of "
           "this game.\n");
}
```

**Rationale:** Avoids complex timer state restoration while maintaining
game integrity

#### 6. Time Forfeit Detection
**Integration with game loop:**
```c
// Check before other game-ending conditions
if (check_time_forfeit(&game)) {
    Color winner = (game.current_player == WHITE) ? BLACK : WHITE;
    printf("\n*** TIME FORFEIT! %s WINS! ***\n",
           winner == WHITE ? "WHITE" : "BLACK");
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
- `main.c` - Configuration parsing, TIME command, display updates, undo
    integration
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

### ✅ TIME Command Lock (IMPLEMENTED)

**Status:** ✅ **COMPLETED** - Simple flag-based protection successfully
implemented
**Implementation:** Uses existing `game_started` flag pattern identical
to SKILL command

#### Implementation Details:
```c
// In main.c, line 1656-1660:
if (strncmp(input, "time ", 5) == 0 || strncmp(input, "TIME ", 5) == 0) {
    if (game_started) {
        printf("\nTime controls cannot be changed after the game has "
               "started!\n");
        printf("Use this command only before making your first move.\n");
    } else {
        // Existing TIME parsing code...
    }
}
```

**Result:** TIME command now locked after first move, preventing
mid-game time control changes
**Files modified:** `main.c` only (6 lines added)
**Testing:** ✅ All micro-tests pass, zero compilation warnings

### ❌ Live Timer Display Updates (ABANDONED)

**Status:** ❌ **ABANDONED** - Incompatible with current terminal-based
architecture

**Analysis Summary:**
Multiple implementation approaches were attempted (signal-based, ANSI
cursor positioning, select() with timeouts), but all resulted in terminal
display issues including screen scrolling, input interference, and cursor
positioning problems.

**Technical Challenges Encountered:**
- Terminal display corruption during real-time updates
- Complex ANSI cursor positioning unreliable across different terminals
- Input blocking (`fgets()`) incompatible with live display updates
- Screen scrolling and line interference issues

**Decision:** The existing timer display (which shows real-time values on
screen refreshes between turns) is adequate for chess gameplay. The
complexity and display issues introduced by live updates during input are
not justified for this use case.

**Current Timer Behavior:** Timer values are dynamically calculated and
displayed whenever the screen refreshes (after moves, commands, etc.),
providing sufficient timing information for chess games.

## Code Cleanup & Refactoring (In Progress)

**Status:** 🚧 Active refactoring session - 7 of 12 items complete

### Forensic Analysis Summary

**Date:** September 23, 2025
**Scope:** Complete codebase audit (8 core files, 7,008 lines analyzed)
**Code Quality Score:** 7/10

**Key Findings:**
- ✅ **Strengths**: 70% documented, consistent style, comprehensive features
- ❌ **Weaknesses**: Long functions (>200 lines), code duplication
    (~200 lines), organizational issues

**Technical Debt Identified:** ~25-35 hours of refactoring work

### Priority 1 - CRITICAL (Affects Maintainability)

#### ✅ **COMPLETED**

1. **Removed Unused Function Declaration** ✅
   - **Issue**: `can_block_or_capture_threat()` declared in chess.h but
       never implemented
   - **Fix**: Removed orphaned declaration from chess.h:196
   - **Impact**: Fixed broken API contract
   - **Commit**: Sep 23, 2025

2. **Organized Debug Files** ✅
   - **Issue**: 6 debug_*.c files cluttering main directory (11KB)
   - **Fix**: Created debug/ subdirectory, moved all debug files, updated
       Makefile
   - **Impact**: Cleaner project structure, separated debug from production code
   - **Commit**: Sep 23, 2025

3. **Extracted PGN Conversion Module** ✅
   - **Issue**: 292-line `convert_fen_to_pgn_string()` embedded in chess.c
   - **Fix**: Created pgn_utils.c/h module, removed from chess.c
   - **Impact**: chess.c reduced 1,715 → 1,423 lines (292 lines removed)
   - **Added**: Micro-test for PGN conversion (19 tests total)
   - **Commit**: Sep 23, 2025

4. **Eliminated Duplicate Directory Scanning Code** ✅
   - **Issue**: ~90% duplicate code between FEN/PGN scanning (200+ lines)
   - **Fix**: Extracted 4 helper functions (`count_fen_moves()`,
       `count_pgn_moves()`, `format_fen_display_name()`,
       `format_pgn_display_name()`)
   - **Impact**: Removed ~100 lines of duplication, cleaner maintenance
   - **Commit**: Sep 23, 2025

5. **Refactored handle_white_turn() Function** ✅
   - **Issue**: Massive 480-line function doing input, commands, moves,
       and display
   - **Fix**: Extracted into 3 focused functions:
     - `handle_game_commands()` (376 lines) - All command processing
         (quit, help, hint, skill, time, fen, pgn, score, title, credits,
         load, undo, resign, setup)
     - `handle_show_possible_moves()` (48 lines) - Display legal moves
         for a square
     - `handle_move_execution()` (26 lines) - Parse and execute chess moves
   - **Impact**: `handle_white_turn()` reduced 480 → 25 lines (455 lines
       extracted)
   - **Bonus Fix**: Updated `char_to_position()` signature to accept
       `const char*` (chess.h & chess.c)
   - **Testing**: Fully tested on macOS 15.6.1 and Ubuntu 22.04, zero
       warnings, all 19 micro-tests pass
   - **Commit**: Sep 24, 2025

#### 🔲 **REMAINING** (Priority 1)
*None - All Priority 1 items complete!*

### Priority 2 - IMPORTANT (Affects Readability)

#### ✅ **COMPLETED**

6. **Refactored setup_board_from_fen() Function** ✅
   - **Issue**: 152-line function doing validation, parsing, and initialization
   - **Fix**: Extracted into 2 focused helper functions:
     - `parse_fen_board_position()` (34 lines) - Parse piece placement field
     - `parse_fen_metadata()` (85 lines) - Parse active color, castling,
         en passant, move counters
   - **Impact**: `setup_board_from_fen()` reduced 152 → 38 lines (114
       lines extracted)
   - **Benefits**: Clear separation of board parsing vs metadata parsing,
       easier to maintain
   - **Testing**: All 19 micro-tests pass (including FEN parsing tests),
       zero warnings
   - **Commit**: Sep 24, 2025

7. **Define Named Constants for Magic Numbers** ✅
   - **Issue**: Magic numbers scattered throughout code (100, 20, 500,
       10000, etc.)
   - **Fix**: Added 12 named constants to chess.h:
     - Game constants: `MAX_POSSIBLE_MOVES`, `FIFTY_MOVE_HALFMOVES`,
         `MAX_SKILL_LEVEL`, `MIN_SKILL_LEVEL`, `MAX_PGN_DISPLAY_MOVES`,
         `PAGINATION_LINES`
     - Engine timing: `DEFAULT_SEARCH_DEPTH`, `MOVE_TIME_DIVISOR`,
         `MIN_MOVE_TIME_MS`, `MAX_MOVE_TIME_MS`
     - Evaluation: `EVAL_WINNING_THRESHOLD`, `EVAL_SIGNIFICANT_THRESHOLD`,
         `EVAL_MODERATE_THRESHOLD`
   - **Impact**: Replaced 15+ magic numbers across chess.c, main.c, and
       stockfish.c
   - **Benefits**: Better code maintainability, self-documenting values,
       easier to adjust thresholds
   - **Bonus Fix**: Fixed Stockfish evaluation bug - now uses only
       deepest depth score (depth 15)
   - **Documentation**: Added comment explaining expected ±10-30 cp
       variation in stockfish.c
   - **Testing**: All 19 micro-tests pass, zero warnings, fully tested
       on macOS & Ubuntu
   - **Commit**: Sep 24, 2025

#### 🔲 **REMAINING** (Priority 2)

8. **Add Documentation to Undocumented Functions** 🔲
   - Target: 16 functions in chess.c, ~6 in main.c
   - Effort: 2-3 hours
   - Status: Tabled for later

### Priority 3 - NICE TO HAVE (Minor Improvements)

9. **Reorganize chess.c by Logical Subsystem** 🔲
   - Group: Board mgmt → Move generation → Validation → Execution →
     Display
   - Effort: 2 hours

10. **Encapsulate Global Variables in Context Structs** 🔲
    - Create `GameSession` and `RuntimeConfig` structures
    - Effort: 4-6 hours

11. **Standardize Naming Conventions** 🔲
    - Enforce: snake_case (functions), PascalCase (types),
      SCREAMING_SNAKE_CASE (constants)
    - Effort: 3-4 hours

12. **Clean Up Header Includes** ✅
    - **Issue**: Redundant includes, inconsistent organization
    - **Fix**: Removed 3 redundant `#include <time.h>` statements, organized
      headers consistently (project headers first, system headers alphabetized)
    - **Impact**: Cleaner compilation dependencies, improved maintainability
    - **Files modified**: chess.c, main.c, pgn_utils.c
    - **Testing**: All 19 micro-tests pass, zero compilation warnings
    - **Commit**: Sep 25, 2025

13. **Replace Magic ANSI Color Codes with Named Constants** ✅
    - **Issue**: Magic ANSI color codes scattered throughout codebase
      (13 instances), making color scheme changes difficult to locate and modify
    - **Fix**: Created 9 named constants in chess.h for all color and
      terminal control codes:
      - Terminal controls: `SCREEN_RESET`, `CLEAR_SCREEN`, `CURSOR_LINEUP_TOEND`
      - Piece colors: `COLOR_WHITE_PIECE`, `COLOR_BLACK_PIECE`
      - Inverted colors: `COLOR_WHITE_PIECE_INVERTED`, `COLOR_BLACK_PIECE_INVERTED`
      - Player status: `COLOR_WHITE_PLAYER`, `COLOR_BLACK_PLAYER`
    - **Impact**: Self-documenting code, easy color scheme changes,
      maintainable color system
    - **Files modified**: chess.h (9 constants added), chess.c (7 references),
      main.c (6 references)
    - **Bonus**: Colorized title screen "White" and "Black" text to match
      piece colors
    - **Testing**: All 19 micro-tests pass, zero compilation warnings,
      tested on macOS/Ubuntu/RPi5
    - **Commit**: Sep 26, 2025

14. **Reorganize chess.c by Logical Subsystem** ✅
    - **Issue**: chess.c functions scattered without logical organization,
      making navigation and maintenance difficult
    - **Fix**: Reorganized all functions into 8 logical subsections with
      clear visual separation using asterisk-boxed headers:
      - Board Management & Initialization
      - Position & Utility Functions
      - Move Generation (by Piece Type)
      - Move Validation & Game Rules
      - Pawn Promotion System
      - Move Execution
      - FEN System & Board Setup
      - Time Control System
    - **Impact**: Dramatically improved code navigation and maintainability
    - **Bonus**: Added comprehensive Table of Contents at top of file with
      all functions and descriptions for instant navigation
    - **Cleanup**: Removed all **JR** commented development artifacts for
      professional code quality
    - **Mandatory Rule Added**: New development standard requiring all future
      chess.c functions be placed in proper sections with TOC updates
    - **Testing**: All 19 micro-tests pass, zero compilation warnings,
      tested on macOS/Ubuntu/RPi5
    - **Commit**: Sep 26, 2025

### Progress Metrics

**Lines of Code Reduced:** ~961 lines removed so far
- PGN extraction: 292 lines
- Duplicate scanning: ~100 lines
- `handle_white_turn()` refactoring: 455 lines
- `setup_board_from_fen()` refactoring: 114 lines

**New Functions Created:** 5 focused functions
- `handle_game_commands()` - Command processing (main.c)
- `handle_show_possible_moves()` - Move display (main.c)
- `handle_move_execution()` - Move execution (main.c)
- `parse_fen_board_position()` - Board parsing (chess.c)
- `parse_fen_metadata()` - Metadata parsing (chess.c)

**New Modules Created:** 2
- `pgn_utils.c/h` - PGN conversion utilities
- `debug/` - Debug programs directory

**Files Organized:** 6 debug files moved to subdirectory

**Test Coverage:** All 19 micro-tests passing, zero compilation warnings

### Next Session Plan

**Current Status: 10 of 12 items complete - Excellent progress!**

**✅ COMPLETED:**
- Priority 1: ALL 5 items complete (critical maintainability)
- Priority 2: 2 of 3 items complete
  - Item 6: `setup_board_from_fen()` refactored ✅
  - Item 7: Named constants defined ✅
  - Item 8: Documentation (tabled for later)
- Priority 3: 3 of 4 items complete
  - Item 9: Reorganize chess.c by Logical Subsystem ✅
  - Item 12: Header includes cleanup ✅
  - Item 13: Magic ANSI color codes replaced with named constants ✅

**🔲 REMAINING WORK (Priority 3 - Optional improvements):**
1. **Item 10**: Encapsulate Global Variables in Context Structs (4-6 hours)
   - Create `GameSession` and `RuntimeConfig` structures
   - Reduce global state footprint

2. **Item 11**: Standardize Naming Conventions (3-4 hours)
   - Enforce: snake_case (functions), PascalCase (types),
     SCREAMING_SNAKE_CASE (constants)

**✅ CRITICAL FIRST TASK COMPLETED:**
- **Fixed CLAUDE.md line lengths** ✅ - All lines now under 80 characters
- **Fixed README.md line lengths** ✅ - All lines properly formatted
- **Fixed awkward line breaks** ✅ - Combined orphaned short continuations
- **Professional documentation formatting** ✅ - Both project docs complete

**Recommendation for Next Session:**
- Start with Item 9 (reorganize chess.c) - 2-hour medium complexity task
- Alternative: Item 8 (documentation) - methodical work
- Save Items 10 & 11 for when you have longer blocks

### Session Summary (Sep 23-24, 2025)

**Major Accomplishments:**
- Completed ALL Priority 1 critical items (5/5)
- Completed 2 of 3 Priority 2 important items
- Total: 7 of 12 refactoring items complete
- ~961 lines of code reduced/reorganized
- 5 new focused functions created
- 12 named constants defined
- Fixed Stockfish evaluation depth bug
- Zero compilation warnings, all tests passing

**Code Quality Improvement:**
- Long functions broken down (480→25 lines, 152→38 lines)
- Eliminated code duplication (~200 lines)
- Self-documenting constants replace magic numbers
- Clear separation of concerns
- Better maintainability for future development

**Status:** Solid stopping point. Project in excellent shape. Ready to
continue when you have a fresh 5-hour block.

### Notes for Future Sessions

- All refactoring tested on both macOS 15.6.1 and Ubuntu 22.04
- Zero compilation warnings maintained throughout
- All 19 micro-tests passing
- Incremental commits after each major change (safe approach)
- **USER handles all git/repo operations** (clearly documented)

## Proposed Next Project

### iOS SwiftUI Chess App

**Concept:** Port the complete Claude Chess implementation to a native
iOS app using SwiftUI, preserving all core functionality while adding
mobile-specific enhancements.

**Project Feasibility:** ✅ **HIGHLY VIABLE**
- Claude has demonstrated comprehensive SwiftUI/iOS development capabilities
- Complete understanding of existing chess logic and architecture
- Proven track record with UCI protocol integration and game state management
- Familiar with testing patterns and validation requirements

### Core Architecture Translation

**Swift Data Structures:**
```swift
struct ChessGame {
    var board: [[Piece]]
    var currentPlayer: Color
    var whiteKingPos: Position
    var blackKingPos: Position
    // ... existing logic translates directly
}

// SwiftUI View Hierarchy
ContentView -> GameBoardView -> ChessSquareView -> PieceView
```

**Preserved Functionality:**
- Complete chess rules (castling, en passant, promotion, 50-move rule)
- AI opponent integration (Stockfish or cloud-based APIs)
- Time controls with separate White/Black allocations
- FEN/PGN import/export capabilities
- Position evaluation and analysis
- Game history and loading system
- Opening library integration

### iOS-Specific Enhancements

**Enhanced User Experience:**
- Touch-based move input with drag-and-drop
- Haptic feedback for moves, captures, and check
- Native iOS animations for piece movements
- Adaptive layouts (portrait/landscape, iPad split-view)
- Share functionality for PGN/FEN positions

**Mobile Platform Features:**
- Background app support for timed games
- Push notifications for time warnings
- iOS widgets for quick game resume
- Document-based app architecture
- iCloud sync for game history
- Accessibility support (VoiceOver)

### Stockfish Integration Options

**Option 1: Native iOS Framework**
- Compile Stockfish as iOS framework/library
- Maintain existing UCI protocol communication
- Preserve current AI difficulty system
- Keep evaluation and hint systems intact

**Option 2: Cloud-Based AI**
- lichess.org API or Chess.com API integration
- Network-based position analysis
- Multiple AI opponent personalities
- Online game capabilities

### Development Approach

**Phase 1: Core Game Logic**
- Port chess rules and move validation to Swift
- Implement basic SwiftUI board display
- Touch-based move input system

**Phase 2: AI Integration**
- Stockfish framework integration or API setup
- UCI protocol communication layer
- AI difficulty and evaluation systems

**Phase 3: Advanced Features**
- Time controls and game state management
- FEN/PGN import/export functionality
- Game history and loading capabilities
- Opening library integration

**Phase 4: iOS Polish**
- Animations and haptic feedback
- Background processing and notifications
- Share functionality and document support
- App Store preparation and testing

### Technical Advantages

**Code Reusability:**
- Chess logic algorithms translate directly from C to Swift
- Existing validation and testing patterns applicable
- UCI protocol knowledge directly transferable
- File format handling (FEN/PGN) preservable

**Development Efficiency:**
- Complete requirements already established
- Testing methodology proven and documented
- User experience patterns validated
- Architecture decisions already made

### Project Timeline Estimate

**Conservative Estimate:** 6-8 weeks of development sessions
- Week 1-2: Project setup and core game logic
- Week 3-4: AI integration and advanced features
- Week 5-6: iOS-specific enhancements and polish
- Week 7-8: Testing, optimization, and App Store preparation

**Note:** Timeline assumes similar session frequency and scope as
current chess project.

### Benefits Over Terminal Version

**Accessibility:** Broader user base with intuitive touch interface
**Portability:** Native mobile app with offline capabilities
**Distribution:** App Store reach vs. command-line tool limitations
**Cross-Platform:** iOS app runs natively on Apple Silicon Macs -
significantly wider audience reach
**Features:** Platform-specific enhancements (haptic, notifications, etc.)
**Modernization:** Contemporary UI/UX standards and design patterns

### Discussion Notes

**User Interest Level:** High - proposed as natural evolution of current project
**Technical Feasibility:** Confirmed viable with Claude's demonstrated capabilities
**Knowledge Transfer:** Seamless transition leveraging existing chess expertise
**Innovation Opportunity:** Modern mobile interpretation of proven chess implementation

**Status:** Documented for future consideration when current terminal chess
project reaches completion milestone.

---
*Developer reference for Claude Chess - Focused technical documentation*