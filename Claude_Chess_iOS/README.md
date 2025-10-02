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

**Current Phase:** Core Development - Phase 1

**Latest Progress (October 2, 2025):**
- ✅ Core data models implemented and tested
- ✅ Foundation types: Color, PieceType, Position, Piece
- ✅ FEN character parsing and algebraic notation support
- ✅ Zero-warning compilation verified

**Next Steps:**
- Build basic chess board UI (8x8 grid)
- Visual piece rendering with Unicode symbols
- Initial game display in simulator

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
    ├── .git/                             # Separate git repo (iOS)
    └── Claude_Chess/                     # Main source directory
        ├── Claude_ChessApp.swift         # App entry point
        ├── ContentView.swift             # Main UI view
        ├── Assets.xcassets/              # Asset catalog
        └── Models/                       # Core data models
            ├── Color.swift               # Chess piece colors
            ├── PieceType.swift           # Chess piece types
            ├── Position.swift            # Board positions
            └── Piece.swift               # Piece representation
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

## Documentation

- `CLAUDE.md` - Comprehensive developer reference
- `README.md` - This overview document

## Development Philosophy

- **Code Quality First** - Clean, well-documented, maintainable code
- **Comprehensive Testing** - Unit tests for all game logic
- **User Experience** - Intuitive, responsive, accessible interface
- **Performance** - Smooth 60fps animations and efficient state updates

## License

(To be determined)

## Contact

(To be added)

---
*Native iOS chess implementation with SwiftUI - Built with Claude Code*
