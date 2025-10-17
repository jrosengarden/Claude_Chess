# Claude Chess iOS

A native iOS chess application built with SwiftUI, featuring a complete
chess implementation with AI opponent integration.

## Important: Relationship to Terminal Project

This iOS app is a direct port of the terminal-based Claude Chess
project located in the parent directory (`../`).

**For Developers**: All feature specifications, chess logic, and
development standards are documented in `../CLAUDE.md`. The terminal
project is the authoritative source for how chess features should
behave.

**File Organization**:
```
Chess Stuff/
├── Claude_Chess/              # Terminal project (C)
│   ├── CLAUDE.md             # PRIMARY REFERENCE for features
│   ├── README.md
│   ├── chess.c               # Chess logic implementation
│   └── ...
└── Claude_Chess_iOS/          # This iOS project
    ├── CLAUDE.md             # iOS-specific dev notes
    ├── README.md             # This file
    └── ...
```

Always consult the terminal project documentation before implementing
any feature.

## Overview

Claude Chess iOS is a modern, touch-based chess application for
iPhone, iPad, and Apple Silicon Macs. It ports the complete feature
set from the terminal-based Claude Chess project to a native iOS
experience with SwiftUI.

## Features (Planned)

### Complete Chess Implementation
- All standard chess rules (castling, en passant, promotion, 50-move rule)
- Check, checkmate, and stalemate detection
- Visual board with intuitive touch controls
- Move validation and legal move highlighting

### AI Opponent ✅ (Sessions 16-18 Complete)
- ✅ Multiple difficulty levels (0-20 with depth mapping)
- ✅ Position evaluation and analysis (3 display formats)
- ✅ Move hints and suggestions (UCI formatting)
- ✅ Fast, responsive gameplay (Stockfish 17 integration)

### Game Management
- Save and load games
- Game history with move navigation
- FEN/PGN import and export
- Opening library integration

### Time Controls ✅ (Session 15 Complete)
- ✅ Configurable time limits (0-60 minutes, 0-60 second increment)
- ✅ Separate allocations for White and Black
- ✅ Visual timer display with live MM:SS countdown
- ✅ Time forfeit detection with automatic game-end alert
- ✅ Quick presets (Blitz, Rapid, Classical, Terminal Default)
- ✅ User-controlled game start ("Start Game" button)
- ✅ Game-start lock (prevents changes mid-game)
- ✅ Undo disables time controls for remainder of game

### iOS Features
- Drag-and-drop piece movement
- Smooth animations
- Haptic feedback
- Share functionality
- iCloud sync (planned)
- Accessibility support

## Requirements

- iOS 17.0+
- iPadOS 17.0+
- macOS 14.0+ (Apple Silicon)
- Xcode 15.0+

## Development Status

**Current Phase:** Phase 3 - IN PROGRESS 🔄 (October 17, 2025)

**Latest Progress (October 17, 2025 - Session 18):**

**✅ Position Evaluation & Hint System COMPLETE:**
- ✅ **Position evaluation display** - Real-time Stockfish analysis with 3
  formats (centipawns, scaled -9 to +9, win probability)
- ✅ **Evaluation interpretation** - Color-coded scores (green/red/primary)
  with text descriptions (overwhelming/significant/moderate/slight advantage,
  roughly equal)
- ✅ **Live evaluation updates** - Refreshes during gameplay via
  ScoreView integration
- ✅ **Hint system** - Complete terminal project parity with fast
  depth-based search
- ✅ **4-state hint UI** - Game not started warning, loading indicator, hint
  display with UCI formatting, no engine warning
- ✅ **UCI move formatting** - Converts "e2e4" to "e2 → e4", handles
  promotion moves like "e7e8q" → "e7 → e8 (=Queen)"
- ✅ **Smart hint availability** - Checks engine != nil (not opponent
  setting) and gameInProgress (prevents hints before "Start Game")
- ✅ **Score moved to Quick Menu** - Better UX (was in hamburger menu)
- ✅ **Quick fixes** - Haptic feedback on AI moves, Integration Tests moved
  to Stockfish Settings, ChessKitEngine license in About
- 📋 **Next:** Game statistics display, investigation of Stockfish move
  time issue

**Previous Session (October 14, 2025 - Session 16):**

**✅ Stockfish Engine Integration Foundation COMPLETE:**
- ✅ **ChessKitEngine Swift Package** - Added v0.7.0 via SPM
- ✅ **ChessEngine protocol** - Unified interface for all chess engines
- ✅ **StockfishEngine implementation** - Complete UCI protocol via wrapper
- ✅ **Neural network files** - Stockfish 17 NNUE files (71MB + 3.4MB)
  integrated
- ✅ **EngineTest utilities** - Comprehensive test functions ready
- ✅ **Test UI integration** - "Stockfish Integration Tests" button in Quick
  Menu
- ✅ **Critical process management fixes** - Resolved SIGPIPE crashes,
  process zombies, cleanup issues
- ✅ **Production-ready** - All 6 tests passing on macOS/iOS simulators AND
  real iPhone 14 Pro
- ✅ **Repeatability validated** - Works multiple times, standalone mode, all
  platforms
- 📋 **Next:** ChessGame integration, AI move automation

**Previous Session (October 13, 2025 - Session 15):**

**✅ Time Controls Enforcement (Terminal Parity):**
- ✅ **Live timer countdown** - Updates every second with MM:SS display
- ✅ **Time increment system** - Adds seconds after each move (White/Black
  separate)
- ✅ **Time forfeit detection** - Automatic game-end alert when time expires
- ✅ **Undo disables time** - Time controls disabled after undo (like
  terminal app)
- ✅ **Game-start lock** - Can't change time controls after first move OR
  after undo
- ✅ **"Start Game" button** - User controls when timer starts (fixes
  terminal weakness!)
- ✅ **Captured pieces overlay** - Tappable display showing captured pieces
  (Session 14 refinement)

**✅ Post-Session Bug Fixes:**
- ✅ **Time display refresh** - Fixed settings changes not updating display
  (added .onChange() observers)
- ✅ **Castling validation rules** - Cannot castle while in check or through
  attacked squares (terminal project parity)

**Previous Session (October 13, 2025 - Session 14):**

**✅ Move History & Undo System:**
- ✅ **MoveRecord structure** - Complete move and game state capture
- ✅ **Full undo functionality** - Perfect state restoration including
  castling, en passant, and promotion moves
- ✅ **Captured pieces display** - Calculated from move history
- ✅ **Undo button** - Always visible in header with dynamic board theme
  coloring
- ✅ **Move history tracking** - All moves recorded with complete game
  state snapshots

**Previous Session (October 11, 2025 - Session 13):**

**✅ Complete Game Logic:**
- ✅ **Check/checkmate/stalemate detection** - Fully working with visual
  indicators
- ✅ **Red border indicator** when king is in check
- ✅ **Game-ending alerts** with checkmate winner announcement
- ✅ **Legal move validation** respects check conditions
- ✅ **Comprehensive move validation** preventing illegal moves
- ✅ Touch input handling (tap-to-select, tap-to-move)
- ✅ **Drag-and-drop piece movement** with ghost piece visual feedback
- ✅ **Comprehensive haptic feedback** (light/medium/heavy/warning types)
- ✅ **Haptic toggle** in Settings for user control
- ✅ Device-adaptive button scaling (iPad/macOS larger touch targets)
- ✅ Legal move highlighting with blinking capture indicators
- ✅ Complete move validation using MoveValidator
- ✅ Full move execution with game state updates
- ✅ Castling (kingside and queenside) working correctly
- ✅ FEN counters (halfmove clock, fullmove number) validated
- ✅ Castling rights tracking (prevents illegal castling after king/rook
  moves)
- ✅ **Pawn promotion** - Complete with interactive piece selection dialog
- ✅ **50-move rule draw detection** - Automatic detection with alert
- ✅ New Game functionality
- ✅ Quick Game Menu with modal interaction enforcement

**Core Foundation:**
- ✅ Core data models: Color, PieceType, Position, Piece, ChessGame
- ✅ Professional Cburnett SVG chess pieces from Wikimedia Commons
- ✅ Board color theme system with 7 presets + custom picker
- ✅ Device-adaptive scaling and orientation control
- ✅ Zero-warning compilation verified

**Phase 2 Highlights:**
The app now features a FULLY playable chess experience with ALL core
rules implemented! Complete chess rule enforcement including check/
checkmate/stalemate detection, pawn promotion with piece selection UI,
and 50-move rule draw detection. Users can tap or drag pieces to move,
with visual indicators showing legal moves that respect check conditions.
When a king is in check, a red border appears and only moves that resolve
the check are allowed. Pawn promotion to any of 4 pieces (Q/R/B/N) works
for both colors. Haptic feedback provides tactile confirmation throughout
gameplay.

**Phase 3 Progress:**
- ✅ **Move history tracking** - All moves recorded with state snapshots
  (Session 14)
- ✅ **Undo functionality** - Complete state restoration (Session 14)
- ✅ **Captured pieces display** - Calculated from history, tappable overlay
  (Sessions 14-15)
- ✅ **Time controls enforcement** - Live countdown, increment, forfeit,
  game-start lock (Session 15)
- ✅ **Start Game UX** - User-controlled timer start (Session 15)
- ✅ **Stockfish engine foundation** - Protocol + implementation + tests
  (Session 16)
- ✅ **Engine integration into ChessGame model** - initializeEngine(),
  requestHint(), evaluatePosition() (Session 17)
- ✅ **AI move automation in game flow** - Stockfish responds automatically
  (Session 17)
- ✅ **Position evaluation display** - 3 formats with live updates (Session 18)
- ✅ **Hint system** - UCI formatting, 4-state UI (Session 18)
- 📋 **Game statistics display** - Move count, captures, time remaining
- 📋 PGN generation from move history
- 📋 FEN/PGN import with navigation

This project is in active development. Core features are being ported
from the proven terminal-based implementation.

## Setup Game Board Feature (Testing Tool)

The "Setup Game Board" feature allows you to set up any chess position
by pasting a FEN (Forsyth-Edwards Notation) string. This is invaluable
for testing specific scenarios, studying positions, or starting games
from non-standard positions.

### How to Use
1. Tap the hamburger menu (☰) in the top-left corner
2. Select "Game Menu"
3. Tap "Setup Game Board"
4. Paste a valid FEN string
5. Tap "Setup" - the board immediately updates to that position

The app automatically detects check, checkmate, and stalemate conditions
after setting up the position.

### Sample FEN Strings for Testing

#### 1. Scholar's Mate (Checkmate Position)
```
r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4
```
Black is in checkmate. Tests checkmate detection with immediate alert.

#### 2. Stalemate Position
```
7k/8/6Q1/8/8/8/8/K7 b - - 0 1
```
Black king on h8, White king on a1, White queen on g6. Black has no
legal moves but isn't in check = stalemate draw.

#### 3. En Passant Opportunity
```
rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3
```
White pawn on e5, Black pawn just moved to f5. White can capture en
passant on f6 by moving the e5 pawn diagonally to f6.

#### 4. Castling Rights Test (No Castling Available)
```
r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w - - 0 1
```
Kings and rooks in position but no castling rights (dash after w).
Tests that castling is properly disabled even when pieces are in
starting squares.

#### 5. Midgame Position with Castling Available
```
r1bqk2r/pppp1ppp/2n2n2/2b1p3/2B1P3/3P1N2/PPP2PPP/RNBQK2R w KQkq - 4 5
```
Italian Game opening position. Both sides can still castle kingside
and queenside. Tests castling availability mid-game.

#### 6. Endgame - King and Pawn vs King
```
8/8/8/4k3/8/8/4P3/4K3 w - - 0 1
```
Simple endgame: White king e1, White pawn e2, Black king e5. Tests
minimal piece setup and basic endgame scenarios.

#### 7. White Pawn Promotion (2 moves away)
```
8/4P3/8/8/8/8/8/4K2k w - - 0 1
```
White pawn on e7, two moves away from e8 promotion. White king on e1,
Black king on h1. Tests pawn promotion for all 4 piece types (Queen,
Rook, Bishop, Knight).

#### 8. Black Pawn Promotion (2 moves away)
```
4k2K/8/8/8/8/8/4p3/8 b - - 0 1
```
Black pawn on e2, two moves away from e1 promotion. Black king on e8,
White king on h8. Tests pawn promotion for Black with all 4 piece types.

#### 9. 50-Move Rule Test (2 moves away from draw)
```
8/8/8/4k3/8/8/4K3/8 w - - 98 100
```
Only kings remain, halfmove clock at 98. After 2 more moves (one by
White, one by Black), the clock reaches 100 and triggers the 50-move
rule draw alert.

### Testing Tips
- After setting up any position, try moving pieces to verify the board
  state is legal
- Check that castling rights are correctly set (try castling if available)
- Verify en passant works with position #3
- Confirm check/checkmate/stalemate detection with positions #1 and #2
- Test pawn promotion with positions #7 and #8 (all 4 piece types)
- Verify 50-move rule draw with position #9
- Use this feature during development to quickly test specific game
  situations
  
### Additional FEN Strings for Testing Castling Rules + King in Check Rules
	(after adding restrictions not allowing King to castle thru check)
	(or to move thru check)

 Test 1: White in Check - Should NOT Allow Castling

  r3k2r/8/8/8/8/8/8/R3K1qR w KQkq - 0 1
  White king on e1, Black queen on g1 puts White in check. Castling should be BLOCKED 
  (both kingside and queenside).

  Test 2: White Kingside - Square King Moves Through is Attacked

  r3k2r/8/8/8/8/5b2/8/R3K2R w KQkq - 0 1
  White king on e1, Black bishop on f3 attacks f1 (square king moves through). Only 
  kingside castling should be BLOCKED. Queenside should still work.
  
	Test #2 CORRECTED - Kingside blocked (f1 attacked):
  	r3k2r/8/8/8/8/8/5q2/R3K2R w KQkq - 0 1
  	Black queen on f2 attacks f1 (blocks kingside castling), but queenside should work!

  Test 3: White Queenside - Square King Moves Through is Attacked

  r3k2r/8/8/8/8/3b4/8/R3K2R w KQkq - 0 1
  White king on e1, Black bishop on d3 attacks d1 (square king moves through). 
  Only queenside castling should be BLOCKED. Kingside should still work.

  Test 4: Black in Check - Should NOT Allow Castling

  r3k2r/8/8/8/8/8/8/R3K1QR b KQkq - 0 1
  Black king on e8, White queen on g8 puts Black in check. Castling should be 
  BLOCKED (both sides).
  
	Test #4 CORRECTED - Black in Check (no castling at all):
	r3k2r/8/8/8/4Q3/8/8/R3K2R b KQkq - 0 1
  	White Queen on e4 puts Black king on e8 in check (vertical attack up column e). 
  	Both castling directions should be BLOCKED.

  Test 5: Both Sides Can Castle (Control Test)

  r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1
  No attacks, no check. BOTH players should be able to castle both directions. 
  This verifies we didn't break normal castling.

  Test in order - #5 first to confirm castling still works, then #1-4 to verify the 
  new restrictions!


## Xcode Project Structure

**Developer Note:** All development work occurs within the Xcode
project directory. User works in Xcode IDE with `Claude_Chess.xcodeproj`
loaded for builds, simulator testing, and visual verification.

```
Claude_Chess_iOS/                          # Project root
├── CLAUDE.md                             # Developer reference docs
├── README.md                             # This file
└── Claude_Chess/                         # Xcode project directory
    ├── Claude_Chess.xcodeproj/           # Xcode project file
    │   ├── project.pbxproj               # Project configuration
    │   ├── xcuserdata/                   # User-specific settings
    │   └── project.xcworkspace/          # Workspace settings
    │       ├── contents.xcworkspacedata
    │       └── xcshareddata/swiftpm/     # Swift Package Manager
    └── Claude_Chess/                     # Main source directory
        ├── Claude_ChessApp.swift         # App entry point
        ├── ContentView.swift             # Main UI view
        ├── Assets.xcassets/              # Asset catalog
        ├── Models/                       # Core data models
        │   ├── Color.swift               # Chess piece colors
        │   ├── PieceType.swift           # Chess piece types
        │   ├── Position.swift            # Board positions
        │   ├── Piece.swift               # Piece representation
        │   ├── ChessGame.swift           # Game state management
        │   └── BoardColorTheme.swift     # Board color themes
        └── Views/                        # UI components
            ├── ChessBoardView.swift      # Chess board visualization
            ├── GameMenuView.swift        # Game menu and commands
            └── SettingsView.swift        # Settings and preferences
```

**Workflow:**
- Claude edits Swift files in `Claude_Chess/Claude_Chess/` directory
- User builds/tests in Xcode with `Claude_Chess.xcodeproj` loaded
- User handles all git operations
- User verifies visual UI and interactive behavior in Simulator

## Parent Project

This iOS app is based on the terminal-based Claude Chess project, a
complete chess implementation in C with Stockfish integration. The
parent project features:

- 2000+ lines of chess logic
- Comprehensive move validation
- FEN/PGN conversion utilities
- Time control system
- Opening library (24 validated positions)
- Cross-platform compatibility (macOS/Linux)

## Development Progress

### Phase 1: Visual Chess Board ✅ (Complete - Oct 8, 2025)

**Implemented Features:**
- Complete data model architecture (Color, PieceType, Position, Piece,
  ChessGame, BoardColorTheme)
- Visual 8x8 chess board with alternating square colors
- All 32 chess pieces rendered with professional Cburnett SVG graphics
- Responsive piece sizing for all devices and orientations
- Device-specific orientation control (iPhone portrait-only, iPad all)
- Standard starting position setup
- Game state tracking (current player, king positions, castling rights,
  en passant)
- Game menu with chess-specific commands (placeholder actions)
- Settings menu with gear icon access
- Board color theme system (6 presets + custom)
- Custom color picker with real-time 4x4 board preview
- Theme persistence using @AppStorage/UserDefaults
- SwiftUI-based responsive layout
- Zero compilation warnings

**Technical Achievements:**
- Resolved SwiftUI Color initializer ambiguity issues
- Established clean separation between Models and Views
- Created reusable ChessBoardView component
- Integrated ObservableObject pattern for reactive UI updates
- Implemented professional chess piece graphics using Cburnett SVG
  assets from Wikimedia Commons (CC-BY-SA 3.0 license)
- GeometryReader-based responsive piece sizing eliminates hardcoded
  dimensions
- Device-specific orientation handling via AppDelegate
- Navigation-based settings architecture ready for future expansion
- RGB color component extraction from SwiftUI.Color via UIColor bridge
- Persistent user preferences across app termination and device restarts
- Perfect scaling across iPhone, iPad, and macOS in all orientations

### Phase 2: Move Validation & Input ✅ (COMPLETE - Oct 11, 2025)

**Implemented Features:**
- ✅ Touch input handling (tap-to-select, tap-to-move)
- ✅ Drag-and-drop piece movement with ghost piece feedback
- ✅ Haptic feedback system (user-controllable in Settings)
- ✅ Move validation logic ported from terminal project (MoveValidator)
- ✅ Legal move highlighting (green circles and blinking captures)
- ✅ Piece movement with full game state updates
- ✅ Castling (kingside/queenside with rights tracking)
- ✅ En passant capture (fully implemented)
- ✅ FEN counter system (halfmove clock, fullmove number)
- ✅ **Check/checkmate/stalemate detection** - Complete!
- ✅ **GameStateChecker** with all game-ending logic
- ✅ **Red border visual indicator** for king in check
- ✅ **Alert dialogs** for check, checkmate, and stalemate
- ✅ **Legal move filtering** respects check conditions
- ✅ **Pawn promotion** - Interactive piece selection dialog for all 4
  pieces (Q/R/B/N)
- ✅ **50-move rule draw detection** - Automatic alert when halfmove
  clock reaches 100
- ✅ New Game functionality
- ✅ Quick Game Menu with modal enforcement
- ✅ Setup Game Board feature (FEN import for testing)

### Phase 3: AI Integration & Advanced Features (IN PROGRESS - Oct 13, 2025)

**✅ Completed (Sessions 14-15):**
- ✅ **Move history tracking** - MoveRecord with complete state capture
  (Session 14)
- ✅ **Undo functionality** - Perfect restoration of all special moves
  (Session 14)
- ✅ **Captured pieces display** - Calculated from move history using SVG
  assets, tappable overlay (Sessions 14-15)
- ✅ **Time controls enforcement** - Live countdown every second, separate
  White/Black time and increment, forfeit detection, undo disables time,
  game-start lock (Session 15)
- ✅ **Start Game button** - User-controlled timer start in Quick Menu,
  fixes terminal app UX weakness (Session 15)

**✅ Completed (Sessions 16-18):**
- ✅ **Stockfish engine integration** - ChessKitEngine Swift Package, UCI
  protocol, neural network files (Session 16)
- ✅ **AI move automation** - Stockfish plays automatically after human
  moves (Session 17)
- ✅ **Multiple difficulty levels** - Skill 0-20 with depth mapping 1-15
  plies (Session 17)
- ✅ **Position evaluation** - Real-time analysis with 3 display formats
  (Session 18)
- ✅ **Move hints** - Fast depth-based search with UCI formatting (Session 18)

**📋 Next Priority:**
- Game statistics display (move count, captures, time remaining)
- PGN generation from move history (requires algebraic notation converter)

### Phase 4: Advanced Features (Future)

**Planned Features:**
- FEN/PGN import/export with navigation
- Game save/load
- Opening library integration
- Sound effects
- Move history display
- Algebraic notation display

## Documentation

- `CLAUDE.md` - Comprehensive developer reference
- `README.md` - This overview document

## Development Philosophy

- **Code Quality First** - Clean, well-documented, maintainable code
- **Comprehensive Testing** - Unit tests for all game logic
- **User Experience** - Intuitive, responsive, accessible interface
- **Performance** - Smooth 60fps animations and efficient state updates

## Credits & Attribution

### Chess Piece Graphics

This app uses the **Cburnett Chess Pieces** from Wikimedia Commons:

- **Source**: https://commons.wikimedia.org/wiki/Category:SVG_chess_pieces
- **Creator**: User:Cburnett
- **License**: CC-BY-SA 3.0 (Creative Commons Attribution-ShareAlike
  3.0 Unported)
- **Assets**: 12 SVG files (6 piece types × 2 colors)
- **Usage**: These professional-quality vector graphics are widely used
  by Wikipedia, chess.com (early versions), and numerous chess
  applications worldwide

The Cburnett chess pieces are considered a standard for digital chess
representation and provide App Store-quality graphics.

### License Compliance

The CC-BY-SA 3.0 license requires:
- **Attribution**: Credit given to User:Cburnett and Wikimedia Commons
  (provided above)
- **ShareAlike**: Any derivative works must be licensed under the same
  or compatible license
- **Commercial Use**: Permitted with proper attribution

## License

(To be determined - must be compatible with CC-BY-SA 3.0 for chess
piece assets)

## Contact

(To be added)

---
*Native iOS chess implementation with SwiftUI - Built with Claude Code*
