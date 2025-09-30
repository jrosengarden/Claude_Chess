# Claude Chess iOS

A native iOS chess application built with SwiftUI, featuring a complete
chess implementation with AI opponent integration.

## Overview

Claude Chess iOS is a modern, touch-based chess application for iPhone,
iPad, and Apple Silicon Macs. It ports the complete feature set from
the terminal-based Claude Chess project to a native iOS experience with
SwiftUI.

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

**Current Phase:** Initial Setup and Planning

This project is in active development. Core features are being ported
from the proven terminal-based implementation.

## Project Structure

```
Claude_Chess_iOS/
├── Claude_Chess/
│   ├── Claude_Chess.xcodeproj/
│   └── Claude_Chess/
│       ├── Claude_ChessApp.swift
│       ├── ContentView.swift
│       └── (Additional files to be added)
├── CLAUDE.md    # Developer reference documentation
└── README.md    # This file
```

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
