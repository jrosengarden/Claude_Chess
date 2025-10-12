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

### AI Opponent
- Multiple difficulty levels (0-20)
- Position evaluation and analysis
- Move hints and suggestions
- Fast, responsive gameplay

### Game Management
- Save and load games
- Game history with move navigation
- FEN/PGN import and export
- Opening library integration

### Time Controls
- Configurable time limits
- Separate allocations for White and Black
- Visual timer display
- Time forfeit detection

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

**Current Phase:** Phase 2 - Nearly Complete (~85%)

**Latest Progress (October 11, 2025 - Session 10):**

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
- ✅ New Game functionality
- ✅ Quick Game Menu with modal interaction enforcement

**Core Foundation:**
- ✅ Core data models: Color, PieceType, Position, Piece, ChessGame
- ✅ Professional Cburnett SVG chess pieces from Wikimedia Commons
- ✅ Board color theme system with 7 presets + custom picker
- ✅ Device-adaptive scaling and orientation control
- ✅ Zero-warning compilation verified

**Phase 2 Highlights:**
The app now features a complete playable chess experience! All core
rules are enforced including check/checkmate/stalemate detection.
Users can tap or drag pieces to move, with visual indicators showing
legal moves that respect check conditions. When a king is in check,
a red border appears and only moves that resolve the check are allowed.
Haptic feedback provides tactile confirmation throughout gameplay.

**Next Steps (Complete Phase 2):**
- Pawn promotion with piece selection UI (final Phase 2 item)

**Then Phase 3:**
- AI opponent integration (Stockfish)

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

### Testing Tips
- After setting up any position, try moving pieces to verify the board
  state is legal
- Check that castling rights are correctly set (try castling if available)
- Verify en passant works with position #3
- Confirm check/checkmate/stalemate detection with positions #1 and #2
- Use this feature during development to quickly test specific game situations

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

### Phase 2: Move Validation & Input (85% Complete - Oct 11, 2025)

**Implemented Features:**
- ✅ Touch input handling (tap-to-select, tap-to-move)
- ✅ Drag-and-drop piece movement with ghost piece feedback
- ✅ Haptic feedback system (user-controllable in Settings)
- ✅ Move validation logic ported from terminal project (MoveValidator)
- ✅ Legal move highlighting (green circles and blinking captures)
- ✅ Piece movement with full game state updates
- ✅ Castling (kingside/queenside with rights tracking)
- ✅ FEN counter system (halfmove clock, fullmove number)
- ✅ **Check/checkmate/stalemate detection** - Complete!
- ✅ **GameStateChecker** with all game-ending logic
- ✅ **Red border visual indicator** for king in check
- ✅ **Alert dialogs** for check, checkmate, and stalemate
- ✅ **Legal move filtering** respects check conditions
- ✅ New Game functionality
- ✅ Quick Game Menu with modal enforcement

**Remaining Features (Phase 2):**
- Pawn promotion with UI
- En passant capture

### Phase 3: AI Integration (Future)

**Planned Features:**
- Stockfish engine integration or cloud-based AI
- Multiple difficulty levels
- Position evaluation
- Move hints
- Move history and undo

### Phase 4: Advanced Features (Future)

**Planned Features:**
- Time controls
- Check/checkmate/stalemate detection
- FEN/PGN import/export
- Game save/load
- Opening library integration
- Sound effects and haptic feedback

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
