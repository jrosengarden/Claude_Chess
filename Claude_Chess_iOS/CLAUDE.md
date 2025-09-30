# Claude Chess iOS - Developer Reference

## Project Overview

**Platform:** iOS 17.0+, iPadOS 17.0+, macOS 14.0+ (Apple Silicon)
**Framework:** SwiftUI
**Language:** Swift 5.9+
**IDE:** Xcode 15+
**Parent Project:** Terminal-based Claude Chess (C implementation)

## Project Status

**Current Phase:** Initial Setup
**Created:** September 30, 2025
**Development Stage:** Planning and Architecture

## Build System

```bash
# Build from command line
xcodebuild -project Claude_Chess/Claude_Chess.xcodeproj \
  -scheme Claude_Chess -destination 'platform=iOS Simulator,name=iPhone 15'

# Run tests
xcodebuild test -project Claude_Chess/Claude_Chess.xcodeproj \
  -scheme Claude_Chess -destination 'platform=iOS Simulator,name=iPhone 15'

# Clean build
xcodebuild clean -project Claude_Chess/Claude_Chess.xcodeproj \
  -scheme Claude_Chess
```

## Project Architecture

### Core Files (Initial Structure)
- `Claude_ChessApp.swift` - App entry point and lifecycle
- `ContentView.swift` - Main UI entry point
- (More files to be added as development progresses)

### Planned Module Structure

**Game Logic Layer:**
- Chess rules and move validation (ported from C implementation)
- Game state management
- FEN/PGN parsing and generation

**UI Layer:**
- Board view and piece rendering
- Move input handling (drag & drop)
- Game controls and settings

**AI Integration Layer:**
- Stockfish engine integration or API-based opponent
- UCI protocol communication
- Position evaluation

**Persistence Layer:**
- Game save/load functionality
- Opening library storage
- User preferences

## Development Standards

### Mandatory Requirements
1. **SwiftUI Best Practices** - Modern declarative UI patterns
2. **MVVM Architecture** - Clear separation of concerns
3. **Comprehensive Testing** - Unit tests for game logic
4. **Documentation** - All public APIs documented
5. **Accessibility** - VoiceOver support for all features
6. **Performance** - 60fps animations, efficient state updates

### Code Style
- Swift API Design Guidelines compliance
- Clear, self-documenting function names
- Comprehensive inline comments for complex logic
- Organized file structure with clear module boundaries

### Testing Strategy
- Unit tests for chess logic (move validation, game rules)
- UI tests for critical user flows
- Performance tests for board rendering
- Integration tests for AI opponent

## Knowledge Transfer from Terminal Project

### Directly Portable Concepts
- Complete chess rules implementation
- Move validation algorithms
- FEN/PGN parsing logic
- Time control system architecture
- Opening library structure

### Requires iOS Adaptation
- Touch-based move input (vs text commands)
- Visual board representation (vs ASCII)
- Native iOS persistence (vs file-based)
- Platform-specific AI integration

## Key Features (Planned)

### Phase 1 - Core Game
- [ ] Visual chess board with piece rendering
- [ ] Touch-based move input (tap-to-select, tap-to-move)
- [ ] Complete chess rules (all variants from C version)
- [ ] Basic game state management

### Phase 2 - AI Integration
- [ ] AI opponent integration
- [ ] Difficulty level selection (0-20 like terminal version)
- [ ] Position evaluation display
- [ ] Move hints

### Phase 3 - Advanced Features
- [ ] Time controls (separate White/Black allocation)
- [ ] Game history and navigation
- [ ] FEN/PGN import/export
- [ ] Opening library integration
- [ ] Save/load game functionality

### Phase 4 - iOS Polish
- [ ] Drag-and-drop piece movement
- [ ] Move animations
- [ ] Haptic feedback
- [ ] Sound effects
- [ ] Share functionality
- [ ] iCloud sync
- [ ] Widgets
- [ ] Accessibility features

## Data Structures (Swift Translation)

### Core Game Types
```swift
// To be implemented - examples:

enum PieceType {
    case pawn, rook, knight, bishop, queen, king
}

enum Color {
    case white, black
}

struct Position {
    let row: Int
    let col: Int
}

struct Piece {
    let type: PieceType
    let color: Color
}

struct ChessGame {
    var board: [[Piece?]]
    var currentPlayer: Color
    var whiteKingPos: Position
    var blackKingPos: Position
    // ... additional game state
}
```

## Development Notes

### Session History
- **Sep 30, 2025**: Project created, initial documentation established

### Key Decisions
- (To be documented as development progresses)

### Technical Challenges
- (To be documented as encountered)

### Future Considerations
- App Store deployment strategy
- Monetization approach (if any)
- Multi-platform support (iOS, iPadOS, macOS)
- Online gameplay features

---
*Developer reference for Claude Chess iOS - Living documentation for
SwiftUI implementation*
