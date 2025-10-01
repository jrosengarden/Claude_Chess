# Claude Chess iOS - Developer Reference

## CRITICAL REFERENCES - READ FIRST

**Parent Project Location:** `../` (one directory up)
**Terminal Project Documentation:** `../CLAUDE.md`
**Terminal Project README:** `../README.md`

⚠️ **MANDATORY**: Before any iOS development work, ALWAYS consult
the terminal project's CLAUDE.md for:
- Complete feature specifications and behavior
- Chess rule implementations to replicate
- Development standards to maintain
- Testing methodologies to follow
- Bug fixes and edge cases already solved

**The terminal project is the authoritative reference for ALL chess
logic, features, and behavior.**

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

## Development Standards (Inherited from Terminal Project)

### Mandatory Standards from Terminal Project

These standards are **NON-NEGOTIABLE** and carry over from the
terminal project:

1. **Documentation Line Length**: 80 characters maximum per line
   in ALL .md files
2. **Zero Warnings**: All code must compile with zero warnings
3. **Comprehensive Testing**: All features must have tests before
   completion
4. **Incremental Development**: Test after every significant change
5. **Professional Documentation**: All code fully documented with
   parameter descriptions
6. **No Session Crashes**: Never run full games during development
   sessions
7. **User Handles Git**: Developer never performs git operations

### Standards NOT Inherited (iOS-Specific Simplifications)

1. **Multi-Platform Testing**: Terminal project required testing on
   macOS, Ubuntu, and Raspberry Pi. iOS project targets single
   Apple ecosystem (iOS/iPadOS/macOS) via unified SwiftUI. Testing
   on iPhone Simulator validates all Apple platforms.

### iOS-Specific Additional Standards

1. **SwiftUI Best Practices** - Modern declarative UI patterns
2. **MVVM Architecture** - Clear separation of concerns
3. **Accessibility First** - VoiceOver support for all features
4. **60fps Performance** - Smooth animations, efficient updates
5. **Swift API Guidelines** - Follow Apple's naming conventions

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

## Terminal Project Feature Parity

**Goal**: Replicate ALL terminal project functionality in iOS
native format.

### Core Chess Features (from Terminal Project)
Reference: `../CLAUDE.md` sections on chess implementation

- [ ] Complete move validation (all piece types)
- [ ] Castling (kingside/queenside with full rule validation)
- [ ] En passant capture with state tracking
- [ ] Pawn promotion with piece selection
- [ ] Check/checkmate/stalemate detection
- [ ] 50-move rule automatic draw detection
- [ ] FEN counter implementation (halfmove/fullmove)

### Game Management Features
Reference: `../CLAUDE.md` sections on LOAD system, FEN/PGN

- [ ] FEN import/export with validation
- [ ] PGN import/export with full move history
- [ ] Game save/load with position navigation
- [ ] Opening library integration (24 validated positions)
- [ ] Captured pieces calculation and display
- [ ] Move history with undo functionality

### AI Integration Features
Reference: `../CLAUDE.md` sections on Stockfish integration

- [ ] Skill level control (0-20)
- [ ] Position evaluation display
- [ ] Hint system (fast depth-based search)
- [ ] UCI protocol support (if using Stockfish)
- [ ] Separate hint vs AI move time management

### Time Control Features
Reference: `../CLAUDE.md` Time Controls System section

- [ ] Separate White/Black time allocations
- [ ] Multiple time format support (xx/yy or xx/yy/zz/ww)
- [ ] Time forfeit detection
- [ ] Increment system after each move
- [ ] Command lock after game starts
- [ ] Disable on undo (or implement state restoration)

### Configuration System
Reference: `../CLAUDE.md` Configuration System section

- [ ] User preferences persistence
- [ ] Default skill level setting
- [ ] Time control defaults
- [ ] File management preferences (auto-save, etc.)

**Verification**: Before marking any feature complete, verify
behavior matches terminal project by consulting `../CLAUDE.md`
and testing terminal version.

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

## Multi-Engine AI Architecture

### Design Decision: Flexible Engine Selection

**Approved Architecture:** Protocol-based multi-engine system allowing
users to select their preferred AI opponent for each game session.

**Supported Engines:**
1. **Stockfish (Native)** - Offline play, UCI protocol, skill 0-20
2. **Lichess API** - Online play, cloud analysis, rating ~800-2800
3. **Chess.com API** - Online play, multiple skill levels

### Implementation Strategy: Protocol Pattern

```swift
// Core protocol defining chess engine behavior
protocol ChessEngine {
    func getBestMove(position: String, skillLevel: Int) async -> Move?
    func getHint(position: String) async -> Move?
    func evaluatePosition(position: String) async -> Int?
    func setSkillLevel(_ level: Int)
    var engineName: String { get }
    var requiresInternet: Bool { get }
}

// Three concrete implementations
class StockfishEngine: ChessEngine {
    // UCI protocol communication (terminal project parity)
}

class LichessEngine: ChessEngine {
    // REST/WebSocket API integration
}

class ChessComEngine: ChessEngine {
    // REST API integration
}

// Game uses selected engine
class ChessGame {
    var currentEngine: ChessEngine
    // All AI requests go through protocol methods
}
```

### User Experience

**Engine Selection UI:**
```
Settings → Opponent Selection
  ○ Stockfish (Offline, Skill 0-20)
  ○ Lichess (Online, Rating 800-2800)
  ○ Chess.com (Online, Beginner-Master)
```

**Per-Game Configuration:** Engine preference saved with each game,
not globally. Allows flexibility:
- Casual offline game → Stockfish level 5
- Serious study → Lichess 2000 rating
- Tournament prep → Chess.com Master

### Phased Implementation Plan

**Phase 1: Stockfish Native Integration (MVP)**
- Status: **PRIMARY FOCUS** for initial release
- Compile Stockfish as iOS framework/library
- Implement UCI protocol communication (terminal project parity)
- Establish ChessEngine protocol architecture
- Complete offline play capability
- Validate all chess logic ports correctly
- **Goal:** Feature parity with terminal version

**Phase 2: Lichess API Integration**
- Status: **POST-MVP ENHANCEMENT**
- Implement LichessEngine conforming to protocol
- Add OAuth authentication for user accounts
- Integrate opening explorer and cloud analysis
- Handle network connectivity and error cases
- Add engine selection UI
- **Goal:** Online play and cloud features

**Phase 3: Chess.com API Integration**
- Status: **FUTURE ENHANCEMENT**
- Implement ChessComEngine conforming to protocol
- Complete three-engine comparison features
- Polish UI for multi-engine system
- Add engine performance analytics
- **Goal:** Maximum flexibility and choice

### Technical Considerations

**Advantages:**
- Clean separation via protocol-based design
- Engine-agnostic chess logic (already true from C port)
- User flexibility for different play styles
- Offline capability maintained (Stockfish)
- Online features available when desired (APIs)

**Challenges:**
- API rate limits (Lichess/Chess.com usage restrictions)
- Skill level mapping (Stockfish 0-20 vs rating systems)
- Network error handling and offline detection
- Testing complexity (need to mock network engines)
- Feature parity (some features engine-specific)

**Mitigation:**
- Phased implementation manages complexity
- Protocol abstraction isolates engine differences
- Graceful degradation for network failures
- Comprehensive unit tests with mocked engines

### Integration Points

**Existing Systems:**
- Chess logic layer remains engine-agnostic
- FEN/PGN handling works with all engines
- Time control system applies to all engines
- Hint system uses same protocol method across engines

**New Requirements:**
- Network connectivity monitoring
- API authentication management (OAuth)
- Engine preference persistence
- Rate limit tracking and throttling

## Technical Advantages

### Code Reusability
- Chess logic algorithms translate directly from C to Swift
- Existing validation and testing patterns applicable
- UCI protocol knowledge directly transferable (if using
  Stockfish)
- File format handling (FEN/PGN) preservable
- All edge cases and bug fixes already documented

### Development Efficiency
- Complete requirements already established
- Testing methodology proven and documented
- User experience patterns validated in terminal version
- Architecture decisions already made
- 2000+ lines of reference implementation

### Risk Mitigation
- Terminal version proves all features work correctly
- Edge cases already identified and solved
- Performance characteristics understood
- User acceptance validated

## Project Timeline Estimate

### Conservative Estimate: 6-8 weeks of development sessions

**Week 1-2: Project setup and core game logic**
- Xcode project configuration
- SwiftUI board rendering
- Core data structures (Piece, Position, ChessGame)
- Basic move validation
- Touch input handling

**Week 3-4: AI integration and advanced features**
- Stockfish framework integration (or API setup)
- UCI protocol communication
- Difficulty level control
- Position evaluation
- Hint system
- Move history

**Week 5-6: iOS-specific enhancements and polish**
- Drag-and-drop animations
- Haptic feedback
- Time controls UI
- FEN/PGN import/export
- Save/load functionality
- Opening library integration

**Week 7-8: Testing, optimization, and App Store prep**
- Comprehensive testing on devices
- Performance optimization
- Accessibility features
- App Store assets and metadata
- Beta testing
- Final polish

**Note**: Timeline assumes similar session frequency and scope
as terminal chess project.

## Benefits Over Terminal Version

**Accessibility**: Broader user base with intuitive touch
interface vs command-line expertise

**Portability**: Native mobile app with offline capabilities,
play anywhere

**Distribution**: App Store reach and discoverability vs manual
installation

**Cross-Platform**: iOS app runs natively on iPhone, iPad, and
Apple Silicon Macs - significantly wider audience

**User Experience**: Touch gestures, animations, haptic feedback,
modern UI/UX standards

**Features**: Platform-specific enhancements (widgets, iCloud
sync, share, notifications)

**Modernization**: Contemporary design patterns vs terminal
aesthetics

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

## Cross-Project Workflow

### When Starting Development
1. ✅ Read `../CLAUDE.md` in its entirety
2. ✅ Identify the specific feature being implemented
3. ✅ Find corresponding implementation in terminal project
4. ✅ Review terminal project test cases
5. ✅ Understand edge cases and bug fixes already solved
6. ✅ Begin iOS implementation

### During Development
- Constantly reference `../CLAUDE.md` for specifications
- Check terminal project source code for algorithms
- Verify chess logic behavior matches terminal version
- Maintain development standards from both projects

### Before Marking Feature Complete
1. Feature works correctly in iOS
2. Behavior matches terminal project exactly
3. All edge cases from terminal project handled
4. Tests written and passing
5. Documentation updated
6. Zero warnings
7. User tested and approved

## Development Notes

### Session History
- **Sep 30, 2025**: Project created, initial documentation
- **Oct 1, 2025**: Added comprehensive cross-project references
  and standards

### Key Decisions
- **Oct 1, 2025**: Multi-engine AI architecture approved - Protocol-
  based design supporting Stockfish (native), Lichess API, and
  Chess.com API with phased implementation (Stockfish Phase 1/MVP,
  Lichess Phase 2, Chess.com Phase 3)

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
