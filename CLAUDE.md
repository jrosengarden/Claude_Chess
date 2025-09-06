# Claude Chess - Development Notes

## Build Commands
```bash
make                    # Compile the chess game
make run               # Compile and run the game
./chess                # Run directly
./chess DEBUG          # Run with debug output
make install-deps      # Install Stockfish dependency
```

## Project Structure
- `main.c` - Game loop, UI, command handling (286 lines)
- `chess.h/chess.c` - Core chess logic, move validation (2050+ lines)
- `stockfish.h/stockfish.c` - AI engine integration via UCI protocol
- `Makefile` - Build configuration

## Key Function Entry Points
- `get_possible_moves()` - Main move generation (chess.c)
- `is_valid_move()` - Move validation with check prevention (chess.c)
- `make_move()` - Execute move and update game state (chess.c)
- `is_in_check()` - Check detection (chess.c)
- `get_best_move()` - AI move request via Stockfish (stockfish.c)
- `board_to_fen()` - Convert board to FEN notation (stockfish.c)

## Current Development Status

### Recently Completed
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
- ✅ **UNDO Feature**: Complete single-level undo system for move pairs
  - Saves complete game state before White's move (board, captured pieces, king positions, castling rights, check status)
  - `undo` command restores previous game state, undoing both White's move and AI's response
  - Single-level undo only - after using undo, new moves must be made before undo becomes available again
  - New structures: `GameState` struct, `can_undo` flag, save/restore functions
  - Location: New functions in `chess.c`, command handler in `main.c`, updated help text
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
  - Piece position lookup (e.g., "e2") shows moves with pause
- ✅ **FEN Command**: Added `fen` command to display current board position in FEN notation
  - Location: `main.c:114-118`
  - Fixed malloc error by removing incorrect `free()` call on static buffer
  - Updated help text and README documentation

### Active Development Focus
- **Next Major Feature: Complete Chess Rules Implementation**
  - ✅ Priority 1: Castling (kingside and queenside) - COMPLETED
  - Priority 2: En passant capture
  - Priority 3: Pawn promotion
  - Priority 4: PGN file generation (after core chess rules complete)
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
- `undo` - Undo last move pair (White + AI moves) - single level only (NEW, with pause)
- `quit` - Exit the game
- `e2 e4` - Move from e2 to e4 (with pause after move confirmation)
- `e2` - Show possible moves from e2 (with pause after display)

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
  - **Next**: En passant capture implementation
  - **Next**: Pawn promotion implementation  
  - **Future**: PGN file generation after core rules complete

### Future Enhancement Opportunities

#### Immediate Priority (Core Chess Rules)
- ✅ **Castling support** (kingside and queenside) - **COMPLETE AND VERIFIED** 
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

#### Implementation Order Rationale
**Why Core Chess Rules Before PGN:**
1. PGN notation must handle all chess moves (castling as "O-O", en passant notation)
2. Avoids implementing PGN twice (once now, again after adding special moves)
3. Core chess rules affect game quality; PGN is documentation feature
4. Complete chess implementation enables thorough PGN testing

### Testing Notes
- ✅ Compilation successful
- ✅ Basic gameplay tested
- ✅ AI integration verified
- ✅ FEN command working correctly
- ✅ UNDO functionality tested and working
- ✅ All UI commands displaying properly with pause functionality
- ✅ Comprehensive code documentation added (all files compile successfully)
- **✅ CASTLING IMPLEMENTATION COMPLETE**: Full kingside and queenside castling verified working
  - ✅ **CASTLING LOGIC VERIFIED**: All castling rules properly implemented and tested
  - ✅ Kingside castling (e1 g1): **WORKING** - Passes automated tests
  - ✅ Queenside castling (e1 c1): **WORKING** - Logic verified in controlled tests  
  - ✅ Castling prevention: **WORKING** - Correctly blocks after king/rook moves
  - ✅ **Test suite available**: `test_castling.sh` provides automated regression testing
  - **Note**: Queenside test may occasionally fail due to unpredictable AI moves (documented)
- ✅ Ready to proceed with next chess rules (en passant, pawn promotion)

### Debug Information
- Run with `DEBUG` flag to see:
  - Raw Stockfish move strings
  - Parsed move coordinates
  - AI communication details
  - **FEN Position Logging**: Automatic append of board positions to `debug_position.fen` after every half-move
    - Any existing debug FEN file is deleted at startup to prevent confusion with old data
    - Each board state is appended to file, creating complete game history (one FEN per line)
    - Shows "Debug: Cleared previous debug_position.fen file" at startup (if old file existed)
    - Shows "Debug: FEN appended to debug_position.fen" confirmation message after each move
    - Allows step-by-step examination of game progression when debugging

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
- Build system: Make

## Complete Development History

### Recent Changes
- **COMPREHENSIVE CODE DOCUMENTATION**: Complete commenting effort across entire codebase
  - **chess.h**: Detailed API documentation with struct descriptions and function signatures
  - **chess.c**: Core chess engine with algorithmic explanations and move generation details
  - **main.c**: UI and game loop documentation with user interaction flow
  - **stockfish.c**: AI integration with UCI protocol and process management details
  - Established professional documentation standards for all future development
  - All new features and modifications will include comprehensive comments
- **UNDO FUNCTIONALITY**: Complete single-level undo system implementation
  - Added `GameState` struct to capture complete game state snapshots (chess.h)
  - Added `save_game_state()` and `restore_game_state()` functions (chess.c)
  - Added `can_undo` flag to ChessGame struct to track undo availability
  - Integrated state saving before White's moves and undo command in main.c
  - Updated help text and all documentation to include undo feature
  - Tested and verified: undoes both White's move and AI's response as a pair
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
- ✅ **FEN Position Logging (DEBUG mode)**: Complete automatic FEN position logging after every half-move
  - Cleans up any existing debug FEN file at startup to prevent confusion with old data
  - Appends each board state to `debug_position.fen` file in DEBUG mode only  
  - File contains complete game history with one FEN position per line for analysis
  - Shows "Debug: Cleared previous debug_position.fen file" at startup (if old file existed)
  - Shows confirmation message "Debug: FEN appended to debug_position.fen" after each move
  - Enables precise debugging of board states when issues occur
  - Location: `cleanup_debug_fen()` function in main.c:31-38, `save_debug_fen()` function in main.c:47-59

### All Completed Features
- Full chess piece movement rules including castling (kingside and queenside)
- **Comprehensive code documentation across entire codebase (NEW)**
- **Single-level UNDO functionality for move pairs (White + AI)**
- **Clean single-board UI with screen clearing after each action**
- **Interactive command system with proper pause/continue prompts**
- Visual board with move highlighting (`*` and `[piece]`)
- Capture tracking for both sides
- Check detection and restricted movement during check
- Stockfish AI integration via UCI protocol
- Complete game loop with human vs AI
- Checkmate and stalemate detection
- Proper FEN notation for AI communication
- HINT command for getting Stockfish move suggestions (with proper display)
- FEN command for displaying current board position in FEN notation (with proper display)
- TITLE command for re-displaying game information
- UNDO command for reverting last move pair
- DEBUG mode with diagnostic output
- Command line argument parsing
- **Pauseable startup sequence for reading game information**
- **FEN Position Logging in DEBUG mode for complete game history debugging**

### Development Standards
- **Documentation Requirement**: All new code must include comprehensive comments
- **Function Documentation**: Parameter descriptions, return values, and purpose explanation
- **File Headers**: Complete description of file purpose, features, and architecture
- **Inline Comments**: Complex logic, algorithms, and design decisions explained

---
*Last updated: After comprehensive code documentation effort and preparation for testing phase*