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

**Current Phase:** Phase 1 Complete - Visual Chess Board ✅

**Latest Progress (October 8, 2025):**
- ✅ Core data models implemented and tested
- ✅ Foundation types: Color, PieceType, Position, Piece
- ✅ ChessGame model with complete game state management
- ✅ Visual 8x8 chess board with proper colors
- ✅ All pieces displayed in standard starting position
- ✅ Professional Cburnett SVG chess pieces from Wikimedia Commons
- ✅ Responsive piece sizing across all devices and orientations
- ✅ Device-specific orientation control (iPhone portrait, iPad all)
- ✅ Settings menu system with navigation structure
- ✅ Game menu with chess-specific commands (New Game, Time Controls, etc.)
- ✅ Board color theme system with 7 preset themes
- ✅ Custom color picker with live preview
- ✅ Theme persistence across app restarts
- ✅ Successfully running on iPhone, iPad, and macOS simulators
- ✅ Zero-warning compilation verified

**Phase 1 Highlights:**
The app displays a beautiful chess board with all 32 pieces in their
correct starting positions using professional Cburnett SVG graphics.
Responsive design ensures perfect piece scaling across iPhone, iPad,
and macOS in all orientations. Users can select from 6 preset color
themes (Classic, Wooden, Blue, Green, Marble, Tournament) or create
custom color schemes using the built-in color picker with real-time
preview. Game menu provides access to chess commands while settings
menu handles app preferences.

**Next Steps (Phase 2):**
- Touch input handling for piece selection and movement
- Move validation logic (ported from terminal project)
- Legal move highlighting
- Piece movement with board state updates

This project is in active development. Core features are being ported
from the proven terminal-based implementation.

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

### Phase 2: Move Validation & Input (Planned - Next)

**Upcoming Features:**
- Touch input handling for piece selection
- Tap-to-select and tap-to-move interaction
- Move validation logic ported from terminal project
- Legal move highlighting
- Piece movement with board state updates
- Check detection

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
