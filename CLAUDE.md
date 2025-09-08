# Claude Chess - Development Notes

## Build Commands
```bash
make                    # Compile chess game, fen_to_pgn utility, and micro_test framework
make run               # Compile and run the chess game
make test              # Run safe micro-testing framework
make debug             # Compile all debug programs for development testing
./chess                # Run chess game directly
./chess DEBUG          # Run chess game with debug output
./fen_to_pgn           # Run FEN to PGN conversion utility
./test_compile_only.sh  # Run safe compilation tests
make install-deps      # Install Stockfish dependency
make clean             # Clean build artifacts for all executables and debug programs
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
- `make_move()` - Execute move and update game state (chess.c)
- `is_in_check()` - Check detection (chess.c)
- `get_best_move()` - AI move request via Stockfish (stockfish.c)
- `board_to_fen()` - Convert board to FEN notation (stockfish.c)
- `validate_fen_string()` - FEN string format validation (chess.c)
- `setup_board_from_fen()` - Parse FEN and configure game state (chess.c)
- `reset_fen_log_for_setup()` - FEN log file management for SETUP command (main.c)
- `truncate_fen_log_for_undo()` - FEN file synchronization for undo operations (main.c)

## Current Development Status

### Recently Completed  
- ✅ **Comprehensive Makefile Enhancement**: Complete build system overhaul with debug program integration
  - Added all debug programs (debug_castle_input, debug_castling, debug_input, debug_move, debug_position, debug_queenside) to build system
  - Integrated debug programs into ALL target for complete project compilation
  - Added debug programs to CLEAN target for thorough artifact removal
  - Created individual targets for each debug program with proper dependencies
  - Optimized compilation with shared object files (chess.o, stockfish.o) for efficient builds
  - Enhanced make clean functionality to remove all executables and object files
  - Improved build performance by reusing compiled objects across all targets
  - Location: Completely restructured Makefile with comprehensive target management
- ✅ **FEN Log Synchronization for Undo**: Complete FEN file synchronization with undo functionality
  - Added `truncate_fen_log_for_undo()` function to remove last 2 FEN entries when undo is executed
  - Ensures FEN log file stays perfectly synchronized with game state after undo operations
  - Handles up to 1000 moves (500 move pairs) safely with memory-based truncation
  - Integrated seamlessly into existing undo command handler
  - Location: New function in main.c (lines 89-117), undo handler update (line 326)
- ✅ **Automatic PGN Generation on Game Exit**: Complete automatic conversion from FEN to PGN format
  - Added `convert_fen_to_pgn()` function for silent, automatic conversion
  - Triggers on all game exit points: quit command, checkmate, stalemate
  - Creates PGN file with matching base name as FEN log file
  - Uses existing fen_to_pgn utility logic to avoid code duplication
  - Silent operation - no user prompts or visible output during conversion
  - Location: New function in main.c (lines 89-115), exit point modifications (lines 224, 530, 536)
- ✅ **SETUP Command**: Complete custom board setup feature using FEN notation
  - Added FEN string validation with comprehensive format checking
  - Added FEN parsing to set board position, active player, castling rights
  - Added FEN log file management (deletes old, creates new timestamped file)
  - Added SETUP command to user interface with interactive FEN input
  - Added comprehensive micro-tests for all FEN functionality
  - Location: New functions in chess.c (lines 658-834), main.c (lines 73-82, 264-296)
- ✅ **FEN to PGN Utility**: Complete standalone conversion tool
  - Built separate `fen_to_pgn.c` utility for converting FEN position files to PGN format
  - Prompts user for input filename and creates corresponding .pgn output file
  - **Updated for new FEN logging**: Now correctly processes FEN files that include initial position
  - Uses first FEN line as starting position instead of hardcoded chess starting position
  - Integrated into Makefile build system alongside main chess executable
  - Location: `fen_to_pgn.c` with build target in Makefile
- ✅ **Castling Implementation**: Complete kingside and queenside castling support
  - Added castling moves to king move generation with proper rule validation
  - Cannot castle while in check, through check, or into check
  - Cannot castle if king or relevant rook has moved
  - Automatic rook movement during castling execution
  - Full integration with existing move validation system
  - Location: Enhanced `get_king_moves()` and `make_move()` functions in chess.c
  - Added `is_square_attacked()` function declaration to chess.h
- ✅ **Optimized Color Scheme for Cross-Platform Compatibility**: Complete color overhaul for terminal compatibility
  - Changed white pieces from bright white to bold magenta for visibility in Mac Light Mode
  - Changed black pieces from blue to bold cyan for better contrast
  - Updated capture labels to "Black Has Captured:" and "White Has Captured:" with color-coded labels (ordered to match board layout)
  - Captured pieces display in normal black text for clarity
  - Colors tested and optimized for both Mac Light Mode and Dark Mode terminals
- ✅ **Comprehensive Code Documentation**: Complete commenting of entire codebase
  - Added detailed file headers explaining purpose, features, and architecture for all source files
  - Function-level documentation with parameter descriptions and return values
  - Inline comments explaining complex algorithms, data structures, and design decisions
  - Professional documentation standards established for future development
  - Files documented: `chess.h`, `chess.c`, `main.c`, `stockfish.c`
  - **Going Forward**: All new code and features will include comprehensive comments
- ✅ **UNLIMITED UNDO Feature**: Complete FEN-based unlimited undo system
  - Unlimited undo capability - can undo any number of move pairs back to game start
  - FEN log-based restoration - uses existing FEN logging for accurate game state restoration
  - Interactive undo count selection - system asks how many move pairs to undo if multiple available
  - Automatic FEN file synchronization - removes appropriate number of FEN entries during undo
  - Completely replaced old GameState-based single-level system with cleaner FEN-based approach
  - Location: New functions in `main.c` (count_available_undos, truncate_fen_log_by_moves, restore_from_fen_log)
- ✅ **UI Cleanup - Single Board Interface**: Complete overhaul of user interface
  - Screen clears after each move/command showing only current game state
  - "Press Enter to continue" prompts added throughout for user control
  - Clean startup sequence with pauseable greeting screen
  - Location: Throughout `main.c`, primarily in game loop and command handlers
- ✅ **Enhanced Commands with Proper Display**:
  - `help` command now displays properly with pause
  - `hint` command shows Stockfish suggestions with pause
  - `fen` command displays FEN notation with pause  
  - `title` command added to re-display greeting screen (NEW)
  - `undo` command added to revert last move pair (NEW)
  - Piece position lookup (e.g., "e2") shows moves with pause (using * and highlighted pieces with inverted colors)
- ✅ **FEN Command**: Added `fen` command to display current board position in FEN notation
  - Location: `main.c:114-118`
  - Fixed malloc error by removing incorrect `free()` call on static buffer
  - Updated help text and README documentation

### Active Development Focus
- **Next Major Feature: Complete Chess Rules Implementation**
  - ✅ Priority 1: Castling (kingside and queenside) - COMPLETED
  - ✅ Priority 1b: FEN to PGN conversion utility - COMPLETED
  - ✅ Priority 2: Resign command - COMPLETED
  - Priority 3: 50-move rule implementation for automatic draw detection
  - Priority 4: En passant capture
  - Priority 5: Pawn promotion
- Testing against Stockfish v17 engine
- Using FEN command for position debugging

### Architecture Notes
- Board representation: `Piece board[8][8]` with `PieceType` and `Color` enums
- King tracking: Maintains `white_king_pos` and `black_king_pos` for efficient check detection
- Move validation: Two-phase validation (generate moves, then filter illegal moves)
- AI communication: Fork/pipe with Stockfish via UCI protocol
- Memory management: `board_to_fen()` returns static buffer (do NOT free!)
- **Code Documentation**: Comprehensive comments throughout all source files for maintainability

### Game Commands
- `help` - Show help message (with pause)
- `hint` - Get Stockfish's best move suggestion for White (with pause)
- `fen` - Display current board position in FEN notation (with pause)
- `title` - Re-display game title and startup information (with pause)
- `setup` - Setup custom board position from FEN string (NEW, with pause)
- `undo` - Unlimited undo of move pairs back to game start (with pause)
- `resign` - Resign the game (NEW - to be implemented)
- `quit` - Exit the game
- `e2 e4` - Move from e2 to e4 (with pause after move confirmation)
- `e2` - Show possible moves from e2 (with pause after display, using * and highlighted pieces with inverted colors)

### Known Issues
- **No current critical issues identified**
- **Minor testing notes:**
  - Queenside castling automated test may occasionally fail due to unpredictable AI moves (castling logic itself verified working)
  - Some test output parsing could be more robust for edge cases
- All previous issues resolved:
  - ✅ Castling implementation completed and verified
  - ✅ Input stream synchronization issues fixed  
  - ✅ UI display issues resolved (commands showing properly)
  - ✅ FEN command malloc error resolved

### Active Development Focus 
- **Current Priority**: Implement remaining core chess rules
  - ✅ **Castling**: Complete and verified working
  - ✅ **Resign**: Complete and verified working
  - **Next**: 50-move rule automatic draw detection
  - **Next**: En passant capture implementation
  - **Next**: Pawn promotion implementation

### Future Enhancement Opportunities

#### Immediate Priority (Core Chess Rules)
- ✅ **Castling support** (kingside and queenside) - **COMPLETE AND VERIFIED** 
- ✅ **Resign command** - **COMPLETE AND VERIFIED**
- **50-move rule implementation** - HIGH PRIORITY (automatic draw detection)
- **En passant capture support** - HIGH PRIORITY  
- **Pawn promotion handling** - HIGH PRIORITY

#### Major Features (After Core Rules)
- **PGN File Generation** - Analyzed and designed, ready for implementation
  - Move history tracking system
  - Algebraic notation conversion (e.g., e2→e4 becomes "e4", include O-O for castling)
  - PGN file writing with proper headers (Event, Date, Players, Result)
  - Disambiguation logic for multiple piece moves
  - Integration with `pgn` command in user interface

#### Additional Enhancements
- Multi-level undo functionality (undo multiple move pairs)
- Move history display/navigation
- Save/load game ability
- Difficulty level adjustment for AI
- Time controls implementation
- Multi-game tournament mode
- Time-based AI search (e.g., `go movetime 5000` for 5-second searches)
- Chess clock implementation with time controls (e.g., `go wtime/btime`)
- Infinite search with manual stop capability
- Dynamic search depth based on position complexity
- **Threefold repetition automatic draw** - LOW PRIORITY (automatic draw detection when same position occurs three times)

#### Implementation Order Rationale
**Why Core Chess Rules Before PGN:**
1. PGN notation must handle all chess moves (castling as "O-O", en passant notation)
2. Avoids implementing PGN twice (once now, again after adding special moves)
3. Core chess rules affect game quality; PGN is documentation feature
4. Complete chess implementation enables thorough PGN testing

### Testing Notes
- ✅ **New Safe Testing Framework**: Micro-testing prevents Claude session crashes
  - ✅ **Micro-Tests Available**: `make test` runs targeted function tests with minimal output
  - ✅ **Compilation Tests**: `test_compile_only.sh` verifies builds work correctly  
  - ✅ **Session Crash Issue Resolved**: No more crashes from excessive test output
  - ✅ **FEN Functionality Tests**: Added 3 micro-tests for FEN validation, parsing, and character conversion
- ✅ Compilation successful  
- ✅ Basic gameplay tested
- ✅ AI integration verified
- ✅ FEN command working correctly
- ✅ UNDO functionality tested and working
- ✅ All UI commands displaying properly with pause functionality
- ✅ Comprehensive code documentation added (all files compile successfully)
- **✅ CASTLING IMPLEMENTATION COMPLETE**: Full kingside and queenside castling verified working
  - ✅ **CASTLING LOGIC VERIFIED**: All castling rules properly implemented and tested
  - ✅ Kingside castling (e1 g1): **WORKING** - Verified through manual testing
  - ✅ Queenside castling (e1 c1): **WORKING** - Logic verified through manual testing  
  - ✅ Castling prevention: **WORKING** - Correctly blocks after king/rook moves
- ✅ Ready to proceed with next chess rules (en passant, pawn promotion)

### Game Features

#### FEN Position Logging
- **Automatic FEN logging**: Every game session creates a timestamped FEN log file
- **Filename format**: `CHESS_mmddyy_HHMMSS.fen` (e.g., `CHESS_090725_143022.fen`)
- **Complete game history**: Each board state is appended after every half-move
- **One position per line**: Easy to analyze game progression step-by-step
- **Always enabled**: No longer requires DEBUG mode - available in all games

### Debug Information
- Run with `DEBUG` flag to see:
  - Raw Stockfish move strings
  - Parsed move coordinates
  - AI communication details

## Technical Architecture Details

### Upcoming Feature Analysis: PGN Generation

**PGN (Portable Game Notation) Implementation Assessment:**
- **Complexity**: Medium - chess logic exists, need move history and notation conversion
- **Current Strengths**: Move tracking with `Move` struct, position conversion, board state management
- **Missing Components**: 
  - Move history storage (currently only `last_move`)
  - Algebraic notation conversion with disambiguation
  - Check/checkmate notation ("+", "#")
  - Special move notation (castling, en passant, promotion)
- **Implementation Strategy**:
  1. Expand move tracking to full history array
  2. Add algebraic notation conversion functions  
  3. Implement PGN file I/O with proper headers
  4. Add `pgn` command to user interface
- **Decision**: Implement after completing core chess rules to avoid double work

### Project Structure Details
- `chess.h` - Chess game data structures and function declarations
- `chess.c` - Core chess logic implementation (2050+ lines)
  - Board initialization and piece setup
  - Move generation for all piece types (pawn, rook, knight, bishop, queen, king)
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
  - **Compatible with new FEN logging**: Uses first FEN line as starting position
  - Properly processes complete game sessions including initial board state
  - Independent executable built alongside main chess game

### Key Features Implementation
1. **Board Representation**: 8x8 array with piece type and color
2. **Move Generation**: Individual functions for each piece type
3. **Check Detection**: Square attack analysis to determine check state
4. **Legal Move Filtering**: Prevents moves that would leave king in check
5. **UCI Integration**: Communicates with Stockfish via pipes and UCI protocol
6. **FEN Notation**: Converts board state to FEN for Stockfish analysis

### Stockfish Integration
The game communicates with Stockfish using the Universal Chess Interface (UCI) protocol:
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
- **FEN LOG SYNCHRONIZATION WITH UNDO**: Complete FEN file synchronization for undo operations
  - **Automatic truncation**: Removes last 2 FEN entries when undo command is executed
  - **Perfect synchronization**: FEN log file now matches game state exactly after undo operations
  - **Memory-safe implementation**: Handles up to 1000 moves with safe memory management
  - **Seamless integration**: Works transparently with existing undo functionality
  - **No user intervention**: Operates automatically without any additional user commands
  - Location: New truncate_fen_log_for_undo() function in main.c with undo handler integration
- **AUTOMATIC PGN GENERATION**: Complete automatic PGN conversion on game exit
  - **Silent operation**: Converts FEN logs to PGN format automatically when game ends
  - **Universal triggers**: Activates on quit command, checkmate, and stalemate
  - **Seamless integration**: Uses existing fen_to_pgn utility logic internally  
  - **Matching file names**: Creates PGN files with same base name as FEN logs
  - **No user intervention**: Operates completely in background without prompts
  - **Preserves both formats**: Users get both FEN logs and PGN files for complete game records
  - Location: New convert_fen_to_pgn() function in main.c with exit point integrations
- **COMPREHENSIVE CODE DOCUMENTATION**: Complete commenting effort across entire codebase
  - **chess.h**: Detailed API documentation with struct descriptions and function signatures
  - **chess.c**: Core chess engine with algorithmic explanations and move generation details
  - **main.c**: UI and game loop documentation with user interaction flow
  - **stockfish.c**: AI integration with UCI protocol and process management details
  - Established professional documentation standards for all future development
  - All new features and modifications will include comprehensive comments
- **UNLIMITED UNDO FUNCTIONALITY**: Complete FEN-based unlimited undo system implementation
  - Removed old GameState struct and related functions for cleaner codebase
  - Implemented FEN log-based restoration using existing setup_board_from_fen() function
  - Added count_available_undos() to determine available undo moves from FEN file
  - Added truncate_fen_log_by_moves() for flexible FEN file truncation
  - Added restore_from_fen_log() for game state restoration from FEN entries
  - Interactive undo system - asks user how many move pairs to undo if multiple available
  - Tested and verified: can undo unlimited move pairs back to game start
- **MAJOR UI OVERHAUL**: Complete redesign of user interface for clean, single-board experience
  - Added screen clearing after every move and command using existing `clear_screen()` function
  - Implemented "Press Enter to continue" prompts throughout the application
  - Fixed all command display issues: help, hint, fen, and piece position lookups now show properly
  - Added pauseable startup sequence so users can read game title and Stockfish version
  - Game loop now shows only current game state without scrolling history
  - Location: Multiple functions in main.c (handle_white_turn, handle_black_turn, main game loop)
- **Added TITLE command**: New `title` command to re-display the greeting screen and game information
  - Added to help text and command parsing in handle_white_turn()
  - Uses same pause mechanism as other commands
- Added screen clearing at game startup for cleaner presentation
- Enhanced startup title to display specific Stockfish version (e.g., "Chess Game with Stockfish 16 AI")
- Added `clear_screen()` function in main.c:4-7 using ANSI escape codes
- Added `get_stockfish_version()` function to extract version info via UCI protocol
- Fixed help text in main.c:19 to use "Type a piece position" instead of "Click on a piece" for proper command-line interface instructions
- **Optimized piece color scheme**: White pieces display in bold magenta, black pieces in bold cyan for excellent visibility in both Mac Light Mode and Dark Mode terminals
- **Added HINT command**: Players can now type `hint` to get Stockfish's best move suggestion for White during their turn
- **Fixed move display bug**: Resolved static buffer issue in `position_to_string()` that was causing AI moves and hints to display incorrect "to to to" format instead of proper "from to to" format
- **Added DEBUG mode**: Run with `./chess DEBUG` to enable diagnostic output showing raw Stockfish move strings, parsed coordinates, and other debugging information
- **Enhanced command line argument parsing**: Added support for command line options with initial DEBUG flag implementation
- **Added FEN command**: Players can now type `fen` to display the current board position in standard FEN (Forsyth-Edwards Notation) format, invaluable for debugging and testing specific positions
- **Fixed FEN malloc error**: Removed incorrect `free()` call on static buffer returned by `board_to_fen()`
- ✅ **FEN Position Logging**: Complete automatic FEN position logging after every half-move
  - Creates timestamped FEN log file for each game session: `CHESS_mmddyy_HHMMSS.fen`
  - Appends each board state to session log file automatically after every half-move
  - File contains complete game history with one FEN position per line for analysis
  - Always enabled for all game sessions to maintain comprehensive game records
  - No debug messages - operates silently in background for clean gameplay
  - FEN files are never deleted - each new game creates a new timestamped file
  - Enables precise analysis of board states and game progression
  - Location: `generate_fen_filename()` function in main.c:35-47, `save_fen_log()` function in main.c:56-64
- ✅ **FEN_TO_PGN Utility Correction**: Fixed compatibility with new FEN logging system
  - Removed hardcoded starting position that was compensating for missing initial position
  - Now uses first FEN line from file as starting position (proper behavior)
  - Correctly processes complete game sessions including initial board state
  - Generates accurate PGN files from timestamped FEN logs

### All Completed Features
- Full chess piece movement rules including castling (kingside and queenside)
- **FEN log synchronization with undo operations for accurate game history**
- **Automatic PGN generation on game exit (quit, checkmate, stalemate)**
- **Custom board setup using FEN notation with SETUP command**
- **Comprehensive code documentation across entire codebase**
- **Unlimited UNDO functionality using FEN log-based restoration**
- **Clean single-board UI with screen clearing after each action**
- **Interactive command system with proper pause/continue prompts**
- Visual board with move highlighting (`*` and highlighted pieces with inverted colors)
- Capture tracking for both sides
- Check detection and restricted movement during check
- Stockfish AI integration via UCI protocol
- Complete game loop with human vs AI
- Checkmate and stalemate detection
- Proper FEN notation for AI communication
- HINT command for getting Stockfish move suggestions (with proper display)
- FEN command for displaying current board position in FEN notation (with proper display)
- TITLE command for re-displaying game information
- SETUP command for custom board positions using FEN notation
- UNDO command for reverting last move pair
- DEBUG mode with diagnostic output
- Command line argument parsing
- **Pauseable startup sequence for reading game information**
- **Automatic FEN Position Logging for complete game history tracking**
- **FEN_TO_PGN utility with proper FEN file compatibility**

### Development Standards
- **Documentation Requirement**: All new code must include comprehensive comments
- **Function Documentation**: Parameter descriptions, return values, and purpose explanation
- **File Headers**: Complete description of file purpose, features, and architecture
- **Inline Comments**: Complex logic, algorithms, and design decisions explained
- **README.md Formatting**: All changes to README.md must maintain page width formatting (~80 characters per line) for printability - do not exceed normal page width
- **Git Repository Management**: Claude Code MUST NOT perform any git operations (commit, push, pull, branch, etc.). User maintains all local and remote repository management personally.

---
*Last updated: After implementing FEN log synchronization with undo operations*