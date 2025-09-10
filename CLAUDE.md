# Claude Chess - Development Notes

## Build Commands
```bash
make                    # Compile chess game, fen_to_pgn utility, and micro_test 
                        # framework
make run               # Compile and run the chess game
make test              # Run safe micro-testing framework
make debug             # Compile all debug programs for development testing
./chess                # Run chess game directly
./chess DEBUG          # Run chess game with debug output
./fen_to_pgn           # Run FEN to PGN conversion utility
./test_compile_only.sh  # Run safe compilation tests
make install-deps      # Install Stockfish dependency
make clean             # Clean build artifacts for all executables and debug 
                        # programs
```

## Project Structure
- `main.c` - Game loop, UI, command handling (286 lines)
- `chess.h/chess.c` - Core chess logic, move validation (2050+ lines)
- `stockfish.h/stockfish.c` - AI engine integration via UCI protocol
- `fen_to_pgn.c` - Standalone FEN to PGN conversion utility
- `micro_test.c` - Safe micro-testing framework for development
- `test_compile_only.sh` - Safe compilation and basic functionality tests
- `Makefile` - Build configuration (builds chess, fen_to_pgn, and micro_test)

## Key Function Entry Points
- `get_possible_moves()` - Main move generation (chess.c)
- `is_valid_move()` - Move validation with check prevention (chess.c)
- `make_move()` - Execute move and update game state with FEN counter 
  tracking (chess.c)
- `is_in_check()` - Check detection (chess.c)
- `get_best_move()` - AI move request via Stockfish (stockfish.c)
- `board_to_fen()` - Convert board to FEN notation with accurate counters 
  (stockfish.c)
- `validate_fen_string()` - FEN string format validation (chess.c)
- `setup_board_from_fen()` - Parse FEN and configure game state preserving 
  counters (chess.c)
- `reset_fen_log_for_setup()` - FEN log file management for SETUP command 
  (main.c)
- `truncate_fen_log_for_undo()` - FEN file synchronization for undo 
  operations (main.c)
- `is_fifty_move_rule_draw()` - 50-move rule draw detection (chess.c)
- `get_king_moves_no_castling()` - King moves without castling for attack 
  checking (chess.c)

## Current Development Status

### Recently Completed  
- ✅ **Position Evaluation System**: Complete on-demand Stockfish evaluation 
  with visual scoring scale
  - Added `get_position_evaluation()` function in stockfish.c for UCI 
    communication
  - Created `centipawns_to_scale()` conversion function mapping centipawns 
    to -9/+9 scale
  - Implemented SCORE command for real-time position analysis using 
    Stockfish depth 15
  - Added visual evaluation line with tick marks, labels, and position 
    indicator
  - Created SCALE command showing complete centipawn conversion chart
  - Designed two-page scale display for terminal compatibility
  - Integrated DEBUG mode centipawn display for development
  - On-demand analysis maintains clean board interface during gameplay
  - Location: Functions in main.c (print_evaluation_line, centipawns_to_scale, 
    print_scale_chart), stockfish.c (get_position_evaluation), command 
    handlers in main.c handle_white_turn
- ✅ **Game Ending Board Display Fix**: Complete fix for board disappearing 
  during game endings
  - Fixed board display for checkmate, stalemate, and 50-move rule endings
  - Board now remains visible showing final position when game ends
  - Game ending message displays after board with "Press Enter to continue"
  - Eliminates jarring experience of board disappearing immediately
  - Allows players to see final board state that caused game to end
  - Location: Enhanced game ending conditions in main.c (lines 703, 714, 723)
- ✅ **50-Move Rule Implementation**: Complete automatic draw detection after 
  50 moves without pawn moves or captures
  - Added `is_fifty_move_rule_draw()` function to chess.c for draw detection
  - **FIXED**: Integrated 50-move rule checking into main game loop in main.c 
    (was missing from original implementation)
  - Automatic game termination with clear notification to users
  - Uses existing halfmove_clock counter which resets on pawn moves/captures
  - Added comprehensive micro-test for 50-move rule functionality
  - Enhanced testing with complex FEN strings including high halfmove clocks
  - Follows chess standards: 50 full moves = 100 halfmoves triggers draw
  - **Verified working**: Manual testing with complex FEN strings confirms 
    automatic draw detection
  - Location: Function in chess.c (lines 855-857), game loop integration 
    in main.c (lines 721-729), comprehensive tests in micro_test.c
- ✅ **File Notification on Game Exit**: Complete user notification system 
  for generated files
  - Added `show_game_files()` function to display FEN and PGN filenames 
    on game exit
  - Integrated notification into all exit points: quit, resign, checkmate, 
    stalemate
  - Users now see "Game files created:" message with both FEN log and PGN 
    file paths
  - Improves user awareness of automatically generated game records
  - Location: New function in main.c with calls at all exit points 
    (lines 311, 440, 681, 687)
- ✅ **FEN Counter Implementation**: Complete halfmove clock and fullmove 
  number tracking
  - Added `halfmove_clock` and `fullmove_number` fields to ChessGame struct
  - Implemented proper FEN counter logic in `make_move()` function following 
    chess standards
  - Halfmove clock resets to 0 on pawn moves or captures, increments on 
    piece moves
  - Fullmove number increments after Black's move (standard chess move pair 
    counting)
  - Updated `setup_board_from_fen()` to parse and preserve original 
    halfmove/fullmove values from input FEN
  - Updated `board_to_fen()` to use stored counters instead of hardcoded 
    "0 1"
  - Fixed SETUP command bug where custom FEN strings had counters reset to 
    "0 1"
  - Prepares foundation for future 50-move rule automatic draw detection
  - Location: ChessGame struct in chess.h, make_move() in chess.c 
    (lines 546-561), setup_board_from_fen() in chess.c (lines 757-776), 
    board_to_fen() in stockfish.c (line 200)
- ✅ **Comprehensive Makefile Enhancement**: Complete build system overhaul 
  with debug program integration
  - Added all debug programs (debug_castle_input, debug_castling, 
    debug_input, debug_move, debug_position, debug_queenside) to build 
    system
  - Integrated debug programs into ALL target for complete project 
    compilation
  - Added debug programs to CLEAN target for thorough artifact removal
  - Created individual targets for each debug program with proper 
    dependencies
  - Optimized compilation with shared object files (chess.o, stockfish.o) 
    for efficient builds
  - Enhanced make clean functionality to remove all executables and object 
    files
  - Improved build performance by reusing compiled objects across all 
    targets
  - Location: Completely restructured Makefile with comprehensive target 
    management
- ✅ **FEN Log Synchronization for Undo**: Complete FEN file synchronization 
  with undo functionality
  - Added `truncate_fen_log_for_undo()` function to remove last 2 FEN 
    entries when undo is executed
  - Ensures FEN log file stays perfectly synchronized with game state after 
    undo operations
  - Handles up to 1000 moves (500 move pairs) safely with memory-based 
    truncation
  - Integrated seamlessly into existing undo command handler
  - Location: New function in main.c (lines 89-117), undo handler update 
    (line 326)
- ✅ **Automatic PGN Generation on Game Exit**: Complete automatic 
  conversion from FEN to PGN format
  - Added `convert_fen_to_pgn()` function for silent, automatic conversion
  - Triggers on all game exit points: quit command, checkmate, stalemate
  - Creates PGN file with matching base name as FEN log file
  - Uses existing fen_to_pgn utility logic to avoid code duplication
  - Silent operation - no user prompts or visible output during conversion
  - Location: New function in main.c (lines 89-115), exit point 
    modifications (lines 224, 530, 536)
- ✅ **SETUP Command**: Complete custom board setup feature using FEN 
  notation
  - Added FEN string validation with comprehensive format checking
  - Added FEN parsing to set board position, active player, castling rights
  - Added FEN log file management (deletes old, creates new timestamped 
    file)
  - Added SETUP command to user interface with interactive FEN input
  - Added comprehensive micro-tests for all FEN functionality
  - Location: New functions in chess.c (lines 658-834), main.c 
    (lines 73-82, 264-296)
- ✅ **FEN to PGN Utility**: Complete standalone conversion tool
  - Built separate `fen_to_pgn.c` utility for converting FEN position files 
    to PGN format
  - Prompts user for input filename and creates corresponding .pgn output 
    file
  - **Updated for new FEN logging**: Now correctly processes FEN files that 
    include initial position
  - Uses first FEN line as starting position instead of hardcoded chess 
    starting position
  - Integrated into Makefile build system alongside main chess executable
  - Location: `fen_to_pgn.c` with build target in Makefile
- ✅ **Castling Implementation**: Complete kingside and queenside castling 
  support
  - Added castling moves to king move generation with proper rule validation
  - Cannot castle while in check, through check, or into check
  - Cannot castle if king or relevant rook has moved
  - Automatic rook movement during castling execution
  - Full integration with existing move validation system
  - Location: Enhanced `get_king_moves()` and `make_move()` functions in 
    chess.c
  - Added `is_square_attacked()` function declaration to chess.h
- ✅ **Optimized Color Scheme for Cross-Platform Compatibility**: Complete 
  color overhaul for terminal compatibility
  - Changed white pieces from bright white to bold magenta for visibility 
    in Mac Light Mode
  - Changed black pieces from blue to bold cyan for better contrast
  - Updated capture labels to "Black Has Captured:" and "White Has 
    Captured:" with color-coded labels (ordered to match board layout)
  - Captured pieces display in normal black text for clarity
  - Colors tested and optimized for both Mac Light Mode and Dark Mode 
    terminals
- ✅ **Comprehensive Code Documentation**: Complete commenting of entire 
  codebase
  - Added detailed file headers explaining purpose, features, and 
    architecture for all source files
  - Function-level documentation with parameter descriptions and return 
    values
  - Inline comments explaining complex algorithms, data structures, and 
    design decisions
  - Professional documentation standards established for future development
  - Files documented: `chess.h`, `chess.c`, `main.c`, `stockfish.c`
  - **Going Forward**: All new code and features will include comprehensive 
    comments
- ✅ **UNLIMITED UNDO Feature**: Complete FEN-based unlimited undo system
  - Unlimited undo capability - can undo any number of move pairs back to 
    game start
  - FEN log-based restoration - uses existing FEN logging for accurate 
    game state restoration
  - Interactive undo count selection - system asks how many move pairs to 
    undo if multiple available
  - Automatic FEN file synchronization - removes appropriate number of FEN 
    entries during undo
  - Completely replaced old GameState-based single-level system with 
    cleaner FEN-based approach
  - Location: New functions in `main.c` (count_available_undos, 
    truncate_fen_log_by_moves, restore_from_fen_log)
- ✅ **UI Cleanup - Single Board Interface**: Complete overhaul of user 
  interface
  - Screen clears after each move/command showing only current game state
  - "Press Enter to continue" prompts added throughout for user control
  - Clean startup sequence with pauseable greeting screen
  - Location: Throughout `main.c`, primarily in game loop and command 
    handlers
- ✅ **Enhanced Commands with Proper Display**:
  - `help` command now displays properly with pause
  - `hint` command shows Stockfish suggestions with pause
  - `score` command displays real-time position evaluation with visual scale (NEW)
  - `scale` command shows centipawn conversion chart in two-page format (NEW)
  - `fen` command displays FEN notation with pause  
  - `title` command added to re-display greeting screen (NEW)
  - `undo` command added to revert last move pair (NEW)
  - Piece position lookup (e.g., "e2") shows moves with pause (using * and 
    highlighted pieces with inverted colors)
- ✅ **FEN Command**: Added `fen` command to display current board position 
  in FEN notation
  - Location: `main.c:114-118`
  - Fixed malloc error by removing incorrect `free()` call on static buffer
  - Updated help text and README documentation

### Active Development Focus
- **Next Major Feature: Complete Chess Rules Implementation**
  - ✅ Priority 1: Castling (kingside and queenside) - COMPLETED
  - ✅ Priority 1b: FEN to PGN conversion utility - COMPLETED
  - ✅ Priority 2: Resign command - COMPLETED
  - ✅ Priority 3: 50-move rule implementation for automatic draw detection - COMPLETED
  - Priority 4: En passant capture
  - Priority 5: Pawn promotion
- Testing against Stockfish v17 engine
- Using FEN command for position debugging

### Architecture Notes
- Board representation: `Piece board[8][8]` with `PieceType` and `Color` 
  enums
- King tracking: Maintains `white_king_pos` and `black_king_pos` for 
  efficient check detection
- Move validation: Two-phase validation (generate moves, then filter 
  illegal moves)
- AI communication: Fork/pipe with Stockfish via UCI protocol
- Memory management: `board_to_fen()` returns static buffer (do NOT free!)
- **FEN Counter Tracking**: `halfmove_clock` and `fullmove_number` fields 
  maintain accurate chess notation
- **Code Documentation**: Comprehensive comments throughout all source files 
  for maintainability

### Game Rules (Automatic Detection)
- **50-Move Rule**: Automatically draws game after 50 moves without pawn 
  moves or captures
- **Checkmate Detection**: Automatically ends game when player has no legal 
  moves and king is in check
- **Stalemate Detection**: Automatically draws game when player has no legal 
  moves but king is not in check

### Known Issues
- **No current critical issues identified**
- **Minor testing notes:**
  - Queenside castling automated test may occasionally fail due to 
    unpredictable AI moves (castling logic itself verified working)
  - Some test output parsing could be more robust for edge cases
- Previously resolved issues:
  - ✅ Castling implementation completed and verified
  - ✅ Input stream synchronization issues fixed  
  - ✅ UI display issues resolved (commands showing properly)
  - ✅ FEN command malloc error resolved
  - ✅ SETUP command FEN counter bug resolved (halfmove/fullmove 
    preservation)
  - ✅ FEN parsing pointer advancement bug fixed (setup_board_from_fen)
  - ✅ **CRITICAL BUG FIXED: is_in_check() Infinite Recursion with Complex 
    FEN Strings**
    - **Root Cause**: Infinite recursion between `is_in_check()` → 
      `is_square_attacked()` → `get_possible_moves()` → `get_king_moves()` 
      → `is_square_attacked()`
    - **Solution**: Created `get_king_moves_no_castling()` function and 
      modified `is_square_attacked()` to use it for kings
    - **Trigger FEN**: `rnbqk2r/pppp1ppp/5n2/2b1p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 98 5`
    - **Status**: FULLY RESOLVED - checkmate/stalemate detection re-enabled
    - **Location**: Fixed in chess.c (new function lines 293-317, 
      is_square_attacked modification lines 410-416), main.c workaround 
      removed (lines 701-719)

### Active Development Focus 
- **Current Priority**: Implement remaining core chess rules
  - ✅ **Castling**: Complete and verified working
  - ✅ **Resign**: Complete and verified working
  - ✅ **FEN Counter Tracking**: Complete and verified working
  - ✅ **50-Move Rule**: **FULLY COMPLETE** - Automatic draw detection 
    working with game loop integration and complex FEN support
  - ✅ **Complex FEN String Bug**: **FULLY RESOLVED** - Infinite recursion 
    fixed with proper king move handling
  - **Next**: En passant capture implementation
  - **Next**: Pawn promotion implementation

### Future Enhancement Opportunities

#### Immediate Priority (Core Chess Rules)
- ✅ **Castling support** (kingside and queenside) - **COMPLETE AND 
  VERIFIED** 
- ✅ **Resign command** - **COMPLETE AND VERIFIED**
- ✅ **50-move rule implementation** - **COMPLETE AND VERIFIED** 
  (automatic draw detection)
- **En passant capture support** - HIGH PRIORITY  
- **Pawn promotion handling** - HIGH PRIORITY

#### Major Features (After Core Rules)
- ✅ **PGN File Generation** - **COMPLETE AND VERIFIED**
  - ✅ Automatic PGN generation on game exit (quit, checkmate, stalemate)
  - ✅ Silent conversion from FEN logs to PGN format
  - ✅ Proper PGN file creation with matching base names
  - ✅ Integration with existing fen_to_pgn utility logic
  - ✅ No user intervention required - operates in background

#### Additional Enhancements
- ✅ **Multi-level undo functionality** - **COMPLETE AND VERIFIED** (unlimited undo of move pairs using FEN log-based restoration)
- Move history display/navigation
- Save/load game ability
- Difficulty level adjustment for AI
- Time controls implementation
- Multi-game tournament mode
- Time-based AI search (e.g., `go movetime 5000` for 5-second searches)
- Chess clock implementation with time controls (e.g., `go wtime/btime`)
- Infinite search with manual stop capability
- Dynamic search depth based on position complexity
- **Threefold repetition automatic draw** - LOW PRIORITY (automatic draw 
  detection when same position occurs three times)

#### Implementation Order Rationale
**Why Core Chess Rules Before Advanced PGN Features:**
1. Advanced PGN notation must handle all chess moves (castling as "O-O", en 
   passant notation)
2. Basic automatic PGN generation is now complete and working
3. Core chess rules affect game quality more than advanced PGN features
4. Complete chess implementation enables thorough testing of all PGN features

### Testing Notes
- **CRITICAL: Claude Session Crash Prevention**
  - **NEVER run full games during internal testing** - Claude sessions ALWAYS 
    crash when testing games with 100+ moves/lines of output
  - **ALWAYS use micro_test.c for internal testing** - Safe, targeted function 
    tests only
  - **NEVER use ./chess directly for testing** - Only for user demonstration 
    after fixes are complete
  - **If testing is needed**: Use micro_test.c to create specific, limited 
    tests for the exact function/feature being debugged
  - **User can manually test full games** - User opens separate terminal 
    sessions to test full games without crashing Claude session
  - **Session crashes are the #1 cause of lost development progress** - 
    These restrictions are mandatory
- ✅ **New Safe Testing Framework**: Micro-testing prevents Claude session 
  crashes
  - ✅ **Micro-Tests Available**: `make test` runs targeted function tests 
    with minimal output
  - ✅ **Compilation Tests**: `test_compile_only.sh` verifies builds work 
    correctly  
  - ✅ **Session Crash Issue Resolved**: No more crashes from excessive test 
    output
  - ✅ **FEN Functionality Tests**: Added 3 micro-tests for FEN validation, 
    parsing, and character conversion
  - ✅ **macOS Compatibility Fix**: `test_compile_only.sh` uses `gtimeout` 
    instead of `timeout` for cross-platform compatibility (both Intel and 
    ARM Macs). Linux systems typically use `timeout`, while macOS requires 
    `gtimeout` from GNU coreutils.
- ✅ Compilation successful  
- ✅ Basic gameplay tested
- ✅ AI integration verified
- ✅ FEN command working correctly
- ✅ UNDO functionality tested and working
- ✅ All UI commands displaying properly with pause functionality
- ✅ Comprehensive code documentation added (all files compile successfully)
- **✅ CASTLING IMPLEMENTATION COMPLETE**: Full kingside and queenside 
  castling verified working
  - ✅ **CASTLING LOGIC VERIFIED**: All castling rules properly implemented 
    and tested
  - ✅ Kingside castling (e1 g1): **WORKING** - Verified through manual 
    testing
  - ✅ Queenside castling (e1 c1): **WORKING** - Logic verified through 
    manual testing  
  - ✅ Castling prevention: **WORKING** - Correctly blocks after king/rook 
    moves
- ✅ Ready to proceed with next chess rules (en passant, pawn promotion)

### Game Features

#### FEN Position Logging
- **Automatic FEN logging**: Every game session creates a timestamped FEN 
  log file
- **Filename format**: `CHESS_mmddyy_HHMMSS.fen` 
  (e.g., `CHESS_090725_143022.fen`)
- **Complete game history**: Each board state is appended after every 
  half-move
- **One position per line**: Easy to analyze game progression step-by-step
- **Always enabled**: No longer requires DEBUG mode - available in all games

### Debug Information
- Run with `DEBUG` flag to see:
  - Raw Stockfish move strings
  - Parsed move coordinates
  - AI communication details

## Technical Architecture Details

### Completed Feature: Position Evaluation System

**Position Evaluation Implementation Status:**
- ✅ **COMPLETE**: On-demand Stockfish evaluation with visual display
- ✅ **UCI Integration**: Real-time communication with Stockfish for evaluation
- ✅ **Visual Scale**: Clean -9 to +9 display with tick marks and indicators
- ✅ **Conversion System**: Intelligent centipawn to scale mapping
- ✅ **User Documentation**: Complete scale reference chart
- ✅ **Debug Integration**: Raw centipawn display in DEBUG mode

**Technical Implementation Details:**
- **UCI Protocol**: Uses "go depth 15" command for thorough analysis
- **Response Parsing**: Extracts centipawn values from "info score cp" lines
- **Scale Mapping**: Maps centipawns to intuitive -9/+9 range with logical 
  breakpoints
- **Visual Design**: Two-line display with tick marks and position indicator
- **Terminal Compatibility**: Two-page scale display works on any screen size
- **Performance**: On-demand only - no performance impact during normal gameplay
- **Error Handling**: Graceful fallback to neutral display if Stockfish fails

**Scale Conversion Logic:**
- **Even positions**: 0 centipawns → 0 scale
- **Slight advantages**: ±10-50 centipawns → ±1-3 scale  
- **Moderate advantages**: ±50-300 centipawns → ±4-6 scale
- **Winning positions**: ±300+ centipawns → ±7-9 scale
- **Reference point**: 100 centipawns ≈ 1 pawn material advantage

### Completed Feature: PGN Generation

**PGN (Portable Game Notation) Implementation Status:**
- ✅ **COMPLETE**: Basic automatic PGN generation is fully implemented and working
- ✅ **Automatic conversion**: FEN logs automatically convert to PGN on game exit
- ✅ **Silent operation**: No user intervention required - works in background
- ✅ **File management**: Creates matching PGN files with same base names as FEN logs
- ✅ **Integration**: Uses existing fen_to_pgn utility logic to avoid code duplication
- **Future Enhancement Opportunities**: 
  - Advanced algebraic notation with disambiguation
  - Check/checkmate notation ("+", "#")  
  - Enhanced special move notation (en passant, promotion)
  - Live PGN command for viewing current game notation

### Project Structure Details
- `chess.h` - Chess game data structures and function declarations
- `chess.c` - Core chess logic implementation (2050+ lines)
  - Board initialization and piece setup
  - Move generation for all piece types (pawn, rook, knight, bishop, queen, 
    king)
  - Move validation and legal move checking
  - Check detection and prevention of moves that leave king in check
  - Game state management (castling rights, king positions)
- `stockfish.h` - Stockfish engine interface declarations
- `stockfish.c` - Stockfish UCI protocol implementation
  - Process management for Stockfish engine
  - UCI command sending/receiving
  - FEN notation conversion
  - Move string parsing
- `main.c` - Main game loop and user interface (286 lines)
  - Human player input handling
  - AI move processing
  - Board display with move highlighting
  - Game end detection (checkmate/stalemate)
- `fen_to_pgn.c` - Standalone FEN to PGN conversion utility
  - Reads FEN position files and converts to PGN format
  - Creates output files with .pgn extension matching input filename
  - **Compatible with new FEN logging**: Uses first FEN line as starting 
    position
  - Properly processes complete game sessions including initial board state
  - Independent executable built alongside main chess game

### Key Features Implementation
1. **Board Representation**: 8x8 array with piece type and color
2. **Move Generation**: Individual functions for each piece type
3. **Check Detection**: Square attack analysis to determine check state
4. **Legal Move Filtering**: Prevents moves that would leave king in check
5. **UCI Integration**: Communicates with Stockfish via pipes and UCI 
   protocol
6. **FEN Notation**: Converts board state to FEN for Stockfish analysis

### Stockfish Integration
The game communicates with Stockfish using the Universal Chess Interface 
(UCI) protocol:
- Launches Stockfish as a separate process
- Sends position in FEN format
- Requests best move with specified depth
- Parses and executes AI moves

### Development Environment
- Compiler: GCC with C99 standard
- Dependencies: Stockfish chess engine
- Platform: POSIX-compatible (macOS/Linux)
- Build system: Make (builds both chess game and fen_to_pgn utility)
- Executables: `chess` (main game), `fen_to_pgn` (conversion utility)

## Complete Development History

### Recent Changes
- **FEN TO PGN CONVERSION BUG FIX**: Fixed critical bug in capture move 
  detection for PGN generation
  - **Problem**: FEN to PGN conversion was missing moves, specifically 
    capture moves, resulting in incomplete PGN files
  - **Symptom**: Example game showed "8. Be6 *" instead of correct 
    "8. dxe5 Be6 *", and reported 15 moves instead of actual 16 moves
  - **Root Cause**: Flawed logic in `compare_boards()` function in 
    fen_to_pgn.c that couldn't properly match disappeared/appeared pieces 
    during captures
  - **Original Logic Issue**: Sequential "from/to" square detection failed 
    when multiple pieces changed positions simultaneously (piece moves + 
    piece captured)
  - **Solution**: Completely rewrote `compare_boards()` function with 
    improved two-phase algorithm:
    1. Collect ALL pieces that disappeared and appeared between positions
    2. Systematically match disappeared pieces with appeared pieces of 
       same type/color
  - **Result**: FEN to PGN conversion now correctly detects all moves 
    including captures, pawn advances, and piece movements
  - **Verification**: Fixed game now shows correct "8. dxe5 Be6" and 
    proper 16-move count
  - **Impact**: Automatic PGN generation on game exit now produces 
    accurate, complete PGN files
  - Location: fen_to_pgn.c compare_boards() function (lines 208-303)
- **FEN COUNTER IMPLEMENTATION**: Complete halfmove clock and fullmove 
  number tracking system
  - **ChessGame struct enhancement**: Added `halfmove_clock` and 
    `fullmove_number` fields to maintain accurate FEN notation
  - **make_move() function update**: Implemented proper FEN counter logic 
    following chess standards
  - **Halfmove clock logic**: Resets to 0 on pawn moves or captures, 
    increments on piece moves
  - **Fullmove number logic**: Increments after Black's move (standard 
    chess move pair counting)
  - **setup_board_from_fen() enhancement**: Now parses and preserves 
    original halfmove/fullmove values from input FEN strings
  - **board_to_fen() correction**: Uses stored counter values instead of 
    hardcoded "0 1"
  - **SETUP command bug fix**: Custom FEN strings now preserve exact 
    halfmove clock and fullmove numbers from input
  - **50-move rule preparation**: Halfmove clock tracking provides 
    foundation for future automatic draw detection
  - **Standards compliance**: All generated FEN strings now follow official 
    Forsyth-Edwards Notation specification
  - Location: ChessGame struct (chess.h:121-122), make_move() 
    (chess.c:546-561), setup_board_from_fen() (chess.c:757-776), 
    board_to_fen() (stockfish.c:200), init_board() (chess.c:61-63)
- **FEN LOG SYNCHRONIZATION WITH UNDO**: Complete FEN file synchronization 
  for undo operations
  - **Automatic truncation**: Removes last 2 FEN entries when undo command 
    is executed
  - **Perfect synchronization**: FEN log file now matches game state 
    exactly after undo operations
  - **Memory-safe implementation**: Handles up to 1000 moves with safe 
    memory management
  - **Seamless integration**: Works transparently with existing undo 
    functionality
  - **No user intervention**: Operates automatically without any additional 
    user commands
  - Location: New truncate_fen_log_for_undo() function in main.c with undo 
    handler integration
- **AUTOMATIC PGN GENERATION**: Complete automatic PGN conversion on game 
  exit
  - **Silent operation**: Converts FEN logs to PGN format automatically 
    when game ends
  - **Universal triggers**: Activates on quit command, checkmate, and 
    stalemate
  - **Seamless integration**: Uses existing fen_to_pgn utility logic 
    internally  
  - **Matching file names**: Creates PGN files with same base name as FEN 
    logs
  - **No user intervention**: Operates completely in background without 
    prompts
  - **Preserves both formats**: Users get both FEN logs and PGN files for 
    complete game records
  - Location: New convert_fen_to_pgn() function in main.c with exit point 
    integrations
- **COMPREHENSIVE CODE DOCUMENTATION**: Complete commenting effort across 
  entire codebase
  - **chess.h**: Detailed API documentation with struct descriptions and 
    function signatures
  - **chess.c**: Core chess engine with algorithmic explanations and move 
    generation details
  - **main.c**: UI and game loop documentation with user interaction flow
  - **stockfish.c**: AI integration with UCI protocol and process 
    management details
  - Established professional documentation standards for all future 
    development
  - All new features and modifications will include comprehensive comments
- **UNLIMITED UNDO FUNCTIONALITY**: Complete FEN-based unlimited undo 
  system implementation
  - Removed old GameState struct and related functions for cleaner codebase
  - Implemented FEN log-based restoration using existing 
    setup_board_from_fen() function
  - Added count_available_undos() to determine available undo moves from 
    FEN file
  - Added truncate_fen_log_by_moves() for flexible FEN file truncation
  - Added restore_from_fen_log() for game state restoration from FEN entries
  - Interactive undo system - asks user how many move pairs to undo if 
    multiple available
  - Tested and verified: can undo unlimited move pairs back to game start
- **MAJOR UI OVERHAUL**: Complete redesign of user interface for clean, 
  single-board experience
  - Added screen clearing after every move and command using existing 
    `clear_screen()` function
  - Implemented "Press Enter to continue" prompts throughout the application
  - Fixed all command display issues: help, hint, fen, and piece position 
    lookups now show properly
  - Added pauseable startup sequence so users can read game title and 
    Stockfish version
  - Game loop now shows only current game state without scrolling history
  - Location: Multiple functions in main.c (handle_white_turn, 
    handle_black_turn, main game loop)
- **Added TITLE command**: New `title` command to re-display the greeting 
  screen and game information
  - Added to help text and command parsing in handle_white_turn()
  - Uses same pause mechanism as other commands
- Added screen clearing at game startup for cleaner presentation
- Enhanced startup title to display specific Stockfish version 
  (e.g., "Chess Game with Stockfish 16 AI")
- Added `clear_screen()` function in main.c:4-7 using ANSI escape codes
- Added `get_stockfish_version()` function to extract version info via UCI 
  protocol
- Fixed help text in main.c:19 to use "Type a piece position" instead of 
  "Click on a piece" for proper command-line interface instructions
- **Optimized piece color scheme**: White pieces display in bold magenta, 
  black pieces in bold cyan for excellent visibility in both Mac Light Mode 
  and Dark Mode terminals
- **Added HINT command**: Players can now type `hint` to get Stockfish's 
  best move suggestion for White during their turn
- **Fixed move display bug**: Resolved static buffer issue in 
  `position_to_string()` that was causing AI moves and hints to display 
  incorrect "to to to" format instead of proper "from to to" format
- **Added DEBUG mode**: Run with `./chess DEBUG` to enable diagnostic output 
  showing raw Stockfish move strings, parsed coordinates, and other 
  debugging information
- **Enhanced command line argument parsing**: Added support for command line 
  options with initial DEBUG flag implementation
- **Added FEN command**: Players can now type `fen` to display the current 
  board position in standard FEN (Forsyth-Edwards Notation) format, 
  invaluable for debugging and testing specific positions
- **Fixed FEN malloc error**: Removed incorrect `free()` call on static 
  buffer returned by `board_to_fen()`
- ✅ **FEN Position Logging**: Complete automatic FEN position logging after 
  every half-move
  - Creates timestamped FEN log file for each game session: 
    `CHESS_mmddyy_HHMMSS.fen`
  - Appends each board state to session log file automatically after every 
    half-move
  - File contains complete game history with one FEN position per line for 
    analysis
  - Always enabled for all game sessions to maintain comprehensive game 
    records
  - No debug messages - operates silently in background for clean gameplay
  - FEN files are never deleted - each new game creates a new timestamped 
    file
  - Enables precise analysis of board states and game progression
  - Location: `generate_fen_filename()` function in main.c:35-47, 
    `save_fen_log()` function in main.c:56-64
- ✅ **FEN_TO_PGN Utility Correction**: Fixed compatibility with new FEN 
  logging system
  - Removed hardcoded starting position that was compensating for missing 
    initial position
  - Now uses first FEN line from file as starting position (proper behavior)
  - Correctly processes complete game sessions including initial board state
  - Generates accurate PGN files from timestamped FEN logs

### All Completed Features
- Full chess piece movement rules including castling (kingside and 
  queenside)
- **Game ending board display with final position visibility for checkmate, 
  stalemate, and 50-move rule draws**
- **50-move rule automatic draw detection after 50 moves without pawn 
  moves or captures**
- **File notification system showing generated FEN and PGN filenames on 
  game exit**
- **FEN log synchronization with undo operations for accurate game history**
- **Automatic PGN generation on game exit (quit, checkmate, stalemate)**
- **Custom board setup using FEN notation with SETUP command**
- **Comprehensive code documentation across entire codebase**
- **Unlimited UNDO functionality using FEN log-based restoration**
- **Clean single-board UI with screen clearing after each action**
- **Interactive command system with proper pause/continue prompts**
- Visual board with move highlighting (`*` and highlighted pieces with 
  inverted colors)
- Capture tracking for both sides
- Check detection and restricted movement during check
- Stockfish AI integration via UCI protocol
- Complete game loop with human vs AI
- Checkmate and stalemate detection
- Proper FEN notation for AI communication
- HINT command for getting Stockfish move suggestions (with proper display)
- SCORE command for real-time position evaluation with visual scale (with 
  proper display)
- SCALE command for viewing centipawn conversion chart (with proper display)
- FEN command for displaying current board position in FEN notation (with 
  proper display)
- TITLE command for re-displaying game information
- SETUP command for custom board positions using FEN notation
- UNDO command for reverting last move pair
- DEBUG mode with diagnostic output
- Command line argument parsing
- **Pauseable startup sequence for reading game information**
- **Automatic FEN Position Logging for complete game history tracking**
- **FEN_TO_PGN utility with proper FEN file compatibility**

### Development Standards
- **Documentation Requirement**: All new code must include comprehensive 
  comments
- **Function Documentation**: Parameter descriptions, return values, and 
  purpose explanation
- **File Headers**: Complete description of file purpose, features, and 
  architecture
- **Inline Comments**: Complex logic, algorithms, and design decisions 
  explained
- **Documentation Formatting**: All changes to CLAUDE.md and README.md must 
  maintain 80-character line width formatting for printability - do not 
  exceed normal page width while keeping content legible and readable
- **Git Repository Management**: Claude Code MUST NOT perform any git 
  operations (commit, push, pull, branch, etc.). User maintains all local 
  and remote repository management personally.

---
*Last updated: After adding file notification system for game exit*