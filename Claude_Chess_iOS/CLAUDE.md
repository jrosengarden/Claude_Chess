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

**Current Phase:** Phase 1 Complete - Ready for Phase 2
**Created:** September 30, 2025
**Last Updated:** October 8, 2025
**Development Stage:** Visual chess board complete with all pieces,
settings menu, and customizable board colors

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

### Core Files (Current Structure)
- `Claude_ChessApp.swift` - App entry point, lifecycle, and device-
    specific orientation control (iPhone portrait-only, iPad all
    orientations)
- `ContentView.swift` - Main UI with chess board, game menu, and
    settings access

### Models (Implemented)
- `Models/Color.swift` - Color enum (white/black) with opposite
    property and display formatting
- `Models/PieceType.swift` - PieceType enum (6 piece types) with
    asset name mapping for Cburnett SVG graphics
- `Models/Position.swift` - Position struct with row/col indices,
    algebraic notation parsing/generation, and validation
- `Models/Piece.swift` - Piece struct combining type and color with
    FEN parsing and asset name generation
- `Models/ChessGame.swift` - Complete game state management with
    board position, castling rights, en passant tracking, and move
    counters
- `Models/BoardColorTheme.swift` - Board color theme system with
    RGB color components, 6 preset themes, and custom color support
- `Models/MoveValidator.swift` - Complete move validation with check
    detection (Phase 2)
- `Models/GameStateChecker.swift` - Check/checkmate/stalemate
    detection system (Phase 2)

### Views (Implemented - Phase 1)
- `Views/ChessBoardView.swift` - Visual 8x8 chess board with
    dynamic color themes and piece rendering using Cburnett SVG graphics
- `Views/SettingsView.swift` - Settings menu with board color theme
    selection and custom color picker with live preview
- `Views/ChessPiecesView.swift` - Chess piece style selection
- `Views/GameMenuView.swift` - Game menu for chess-specific commands
- `Views/ScoreView.swift` - Position evaluation display with scale settings
- `Views/ScaleView.swift` - Evaluation scale format selection
- `Views/ScoreConversionChartView.swift` - Centipawn to scaled conversion table
- `Views/AboutView.swift` - App information and licenses
- `Views/OpponentView.swift` - AI engine selection (Stockfish/Lichess/Chess.com)
- `Views/StockfishSettingsView.swift` - Stockfish skill level configuration
- `Views/ChessComSettingsView.swift` - Chess.com settings (placeholder)
- `Views/LichessSettingsView.swift` - Lichess settings (placeholder)
- `Views/TimeControlsView.swift` - Time control configuration
- `ContentView.swift` - Main app view with captured pieces and time display

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
8. **TODO Management**: Actively monitor and remove TODO comments
   when functionality is implemented. Before marking any feature
   complete, search for related TODOs and remove them. See TODO
   Tracking section below for current inventory.

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

### Documentation Standards (Critical - Prevent Doc Sprawl)

**Lessons Learned from Terminal Project:**
The terminal project's CLAUDE.md grew to ~1400 lines with significant
redundancy requiring multiple refactoring sessions. iOS project
standards prevent this issue.

**Mandatory Documentation Practices:**

1. **Session History - Stay Concise**
   - Focus on KEY DECISIONS and ARCHITECTURE CHOICES only
   - Do NOT document every code change or file modification
   - Keep entries to 3-5 bullet points maximum per session
   - Bad: "Updated line 47 in FileX.swift to fix typo"
   - Good: "Implemented custom color picker with live preview"

2. **No Duplicate Feature Documentation**
   - Document each feature ONCE in its logical section
   - "Latest Progress" and "Implementation Progress" must stay
     synchronized
   - Do NOT replicate architecture details across sections
   - Cross-reference with "See Section X" when needed

3. **Implementation Progress Section**
   - Keep completed items as brief bullet points
   - Do NOT expand with implementation details (those go in
     dedicated sections)
   - Update status (✅/🔄/📋) without expanding text unnecessarily

4. **Avoid "Recently Completed" Lists**
   - Terminal project suffered from ever-growing "Recently
     Completed" sections
   - Move completed items to appropriate permanent sections
   - Session History captures temporal progression

5. **Architecture Documentation**
   - Document new systems ONCE in dedicated subsection
   - Example: "Board Color Theme System" documents entire feature
   - Do NOT repeat details in Session History or Implementation
     Progress

**Review Checkpoints:**
- Every 3-4 sessions: Scan for redundancy
- Before Phase transitions: Consolidate documentation
- Flag if CLAUDE.md approaches 1000+ lines

**Current Status:** ~900 lines (healthy), no redundancy detected

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

### TODO Tracking System

**Purpose:** Monitor in-code TODO comments to ensure completion and
prevent accumulation of technical debt.

**Current TODO Inventory (20 total as of Oct 11, 2025):**

**Phase 2 - Move Validation & Game Logic (2 TODOs):**
- `MoveValidator.swift` - Add check detection to prevent castling while in check
- `MoveValidator.swift` - Add is_square_attacked() checks for squares king moves through

**Phase 2 - UI & Display (4 TODOs):**
- `HintView.swift` - Implement actual hint functionality
- `ContentView.swift` - Implement captured pieces calculation
- `ScoreView.swift` - Display current position evaluation
- `ScoreView.swift` - Display game statistics

**Phase 3 - Game Management (12 TODOs):**
- `ChessGame.swift` - Track captured pieces for display
- `GameMenuView.swift` - Save game action
- `GameMenuView.swift` - Load game action
- `GameMenuView.swift` - Undo move action (2 locations: GameMenuView + QuickGameMenuView)
- `GameMenuView.swift` - Import FEN action
- `GameMenuView.swift` - Export FEN action
- `GameMenuView.swift` - Import PGN action
- `GameMenuView.swift` - Export PGN action
- `GameMenuView.swift` - Resign action (2 locations: GameMenuView + QuickGameMenuView)
- `QuickGameMenuView.swift` - FEN display implementation
- `QuickGameMenuView.swift` - PGN display implementation

**Future/Optional (1 TODO):**
- `AboutView.swift` - Add any other third-party libraries used
  (appropriate placeholder for future dependencies)

**Active Maintenance Protocol (MANDATORY):**

**When ADDING a TODO to code:**
1. Add the TODO comment to the code file
2. IMMEDIATELY update this TODO Tracking section
3. Categorize by phase (Phase 2/3/Future)
4. Update the total count at top of inventory

**When REMOVING a TODO from code:**
1. Remove the TODO comment from the code file
2. IMMEDIATELY remove from this TODO Tracking section
3. Update the total count at top of inventory
4. Mention removal in Session History if feature-significant

**Before marking ANY feature complete:**
1. Search: `grep -r "TODO" . | grep [feature_name]`
2. Remove ALL related TODOs from code
3. Remove ALL related TODOs from this tracking section
4. Verify with second grep search
5. Update total count

**Weekly audit during active development:**
- Run: `grep -r "TODO" Claude_Chess/Claude_Chess/` to verify
- Check for orphaned TODOs not in this tracking system
- Check for tracking entries without corresponding code TODOs
- Update inventory immediately if discrepancies found

**This tracking system is USELESS unless actively maintained!**

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

**Session 1: Sep 30, 2025** - Project created, initial documentation

**Session 2: Oct 1, 2025** - Added comprehensive cross-project
references and standards

**Session 3: Oct 2, 2025** - Implemented core foundation models
(Color, PieceType, Position, Piece) - all compile cleanly with zero
warnings

**Session 4: Oct 8, 2025** - Phase 1 Complete: Visual Chess Board
with Settings
- Created `ChessGame.swift` model with complete game state management
- Implemented `ChessBoardView.swift` with 8x8 grid and piece rendering
- Integrated chess board into `ContentView.swift`
- Resolved SwiftUI Color initializer issues using file-level constants
- Fixed property name mismatches (symbol vs displaySymbol, displayName
  vs description)
- **Replaced Unicode symbols with professional Cburnett SVG chess piece
  assets** from Wikimedia Commons
- Added 12 SVG chess piece images to Assets.xcassets (6 pieces × 2
  colors)
- Implemented `assetName(for:)` method in PieceType for image asset
  mapping
- Updated ChessBoardView to use Image() instead of Text() for piece
  rendering
- **Implemented comprehensive settings menu system**:
  - Created `BoardColorTheme.swift` model with 6 preset themes
  - Added custom color theme with RGB component storage
  - Built `SettingsView.swift` with navigation structure
  - Implemented `CustomColorPickerView` with live 4x4 board preview
  - Added gear icon settings button to ContentView
  - Theme persistence via @AppStorage/UserDefaults
- Successfully built and ran app in iPhone 17 Pro simulator
- **Result**: Fully functional visual chess board with professional-
  quality vector graphics pieces, customizable color themes, and
  persistent user preferences

**Session 5: Oct 8, 2025** - Orientation Support and Game Menu
- Implemented device-specific orientation locking via AppDelegate
- Fixed responsive layout issues in landscape mode
- Created GameMenuView for chess-specific commands
- Refined header layout with proper icon positioning

**Session 6: Oct 9, 2025** - Game Controls and Configuration System
- Implemented comprehensive menu system (Score, About, Opponent, Time Controls)
- Created opponent selection with Stockfish/Chess.com/Lichess engines
- Built time controls with separate White/Black settings and quick presets
- Added captured pieces display above board matching terminal layout
- Implemented chess piece style selection (Cburnett with future expansion)
- Fixed PGN import/export icon consistency issues

**Session 7: Oct 9, 2025** - UX Enhancements and Shortcuts
- Device-specific text scaling (iPad/macOS 1.5x larger fonts)
- Tappable opponent text shortcut to engine-specific settings
- Lightbulb hint shortcut icon in header (yellow, positioned before menu)
- Created HintView placeholder for Phase 2 implementation

**Session 8: Oct 10, 2025** - Phase 2 Move System and Bug Fixes
- Recovered from interrupted session (implemented Quick Game Menu, modal
  enforcement, move execution, New Game, castling)
- Fixed castling rights bug: king moved flag now set for ANY king move,
  not just castling moves
- Fixed fullmove counter: clarified FEN specification (counter is
  prospective, not retrospective)
- Verified halfmove clock working correctly (resets on pawn moves/captures)
- Verified castling working correctly (allowed/disallowed based on
  king/rook movement)
- All core move execution logic now validated and working

**Session 9: Oct 11, 2025** - UX Polish: Drag-and-Drop & Haptic Feedback
- Implemented device-adaptive button scaling (iPad/macOS 1.5x larger
  header buttons)
- Added comprehensive haptic feedback system (light/medium/heavy/warning
  types)
- Implemented drag-and-drop piece movement with ghost piece visual
  feedback
- Added user-controllable haptic toggle in Settings
- Fixed Custom Color theme selection bug (now sets theme on navigation)
- Refined haptic scope: enabled for board interactions, main screen
  shortcuts, Quick Menu; disabled for Settings and Game Menu
- Ghost piece offset optimization for visibility during drag

**Session 10: Oct 11, 2025** - Check/Checkmate/Stalemate Detection
- Created GameStateChecker.swift with complete game-ending detection
- Ported isSquareAttacked(), isInCheck(), hasLegalMoves(),
  isCheckmate(), isStalemate() from terminal project
- Added wouldBeInCheckAfterMove() validation to prevent illegal moves
- Integrated check/checkmate/stalemate alerts in ChessBoardView
- Implemented red border visual indicator for king in check
- Fixed legal move filtering to respect check conditions
- Resolved @Published update issues during move validation
- New Game button now properly resets all state including check
  indicators

### Key Decisions

**Oct 1, 2025**: Multi-engine AI architecture approved - Protocol-
based design supporting Stockfish (native), Lichess API, and
Chess.com API with phased implementation (Stockfish Phase 1/MVP,
Lichess Phase 2, Chess.com Phase 3)

**Oct 8, 2025**: Color definition strategy - Used file-level
fileprivate constants with fully-qualified SwiftUI.Color type to
avoid initializer ambiguity issues

**Oct 8, 2025**: Chess piece graphics - Adopted Cburnett SVG assets
from Wikimedia Commons for professional appearance, rejecting Unicode
symbols due to unprofessional "hollow/sketch" appearance of white
pieces

**Oct 8, 2025**: Settings architecture - Implemented extensible
navigation-based settings system early in Phase 1 to establish proper
architecture before Phase 2 complexity. Custom color feature added as
first user customization option with full persistence support.

**Oct 8, 2025**: Header layout - Decided against tab bar approach for
Settings/Game Menu icons. Keeping both as modal sheets accessed from
header maximizes board space and follows iOS conventions for action
menus vs navigation sections.

**Oct 9, 2025**: Dual access patterns - Retained features in both main
view shortcuts (time controls, opponent, hint) AND hamburger menu for
dual discovery mechanisms respecting different user interaction styles.

### Implementation Progress

**✅ Phase 1 Complete (Oct 9, 2025):**
- Core data structures (Color, PieceType, Position, Piece, ChessGame,
  BoardColorTheme)
- Professional chess piece graphics (Cburnett SVG assets)
- Visual 8x8 chess board with dynamic color themes
- Responsive piece sizing for all devices/orientations
- Device-specific orientation support (iPhone portrait, iPad all)
- Comprehensive menu system (Game, Settings, Score, About, Opponent)
- Opponent selection (Stockfish/Lichess/Chess.com with persistence)
- Stockfish skill level slider (0-20 with game-start lock warning)
- Time controls with separate White/Black settings and quick presets
- Captured pieces display above board
- Score evaluation format selection (Centipawns/Scaled/Win Probability)
- Conversion chart for scaled format (-9 to +9)
- Chess piece style selection (Cburnett, expandable)
- Complete license attribution (Stockfish GPL, Cburnett CC-BY-SA)
- Tappable time display shortcut to settings
- Tappable opponent text shortcut to engine-specific settings
- Lightbulb hint icon shortcut in header
- HintView placeholder (Phase 2 ready)
- Device-adaptive text scaling (iPhone/iPad/macOS)
- Theme persistence using @AppStorage/UserDefaults
- Zero-warning compilation

**🔄 Phase 2 (In Progress - ~85% Complete):**
- ✅ Touch input handling (tap to select/move pieces)
- ✅ Drag-and-drop piece movement with ghost piece feedback
- ✅ Haptic feedback system (user-controllable)
- ✅ Move validation logic (ported from terminal project)
- ✅ Legal move highlighting (respects check conditions)
- ✅ Piece movement with board state updates
- ✅ Check/checkmate/stalemate detection with visual indicators
- ✅ Game-start lock enforcement (time controls/skill level)
- 📋 Pawn promotion with piece selection UI
- 📋 En passant capture implementation

**📋 Phase 3 (Future):**
- AI integration (Stockfish framework)
- Move history and undo functionality
- FEN/PGN import/export
- Captured pieces calculation
- Game save/load

### Board Color Theme System

**Architecture Overview:**
Complete color customization system with 6 preset themes plus custom
color picker. Themes persist across app restarts using UserDefaults.

**Theme Model** (`BoardColorTheme.swift`):
```swift
struct BoardColorTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let lightSquare: ColorComponents
    let darkSquare: ColorComponents
}
```

**Preset Themes**:
1. **Classic** - Traditional tan/brown (default)
2. **Wooden** - Warm amber/dark brown with golden light squares
3. **Blue** - Cool blue tones
4. **Green** - Forest green with light squares
5. **Marble** - Elegant grey/white
6. **Tournament** - High contrast white/dark green
7. **Custom** - User-defined colors via color picker

**Persistence Implementation**:
- Theme selection: `@AppStorage("boardThemeId")`
- Custom colors: 6 separate `@AppStorage` properties for RGB
  components
  - `customLightRed`, `customLightGreen`, `customLightBlue`
  - `customDarkRed`, `customDarkGreen`, `customDarkBlue`
- Values persist in UserDefaults across app kills and device restarts

**Custom Color Picker Features**:
- Live 4x4 chess board preview showing actual color appearance
- Separate ColorPicker controls for light and dark squares
- Real-time preview updates as colors change
- Automatic theme switching to "custom" when colors modified
- RGB component extraction from SwiftUI.Color via UIColor bridge

**Technical Implementation**:
- `BoardColorTheme.componentsFrom(color:)` converts SwiftUI.Color to
  RGB using UIColor
- `BoardColorTheme.theme(withId:customLight:customDark:)` returns
  custom theme with user colors
- ChessBoardView reads both theme ID and custom colors from
  @AppStorage
- Dynamic theme resolution in `currentTheme` computed property

**User Experience Flow**:
1. Tap gear icon in ContentView
2. Navigate to "Board Colors" in SettingsView
3. Select preset theme (immediate preview) OR tap "Custom"
4. Custom picker shows live 4x4 board preview
5. Adjust light/dark square colors independently
6. Return to game - board reflects new colors
7. Colors persist even after app termination

### Chess Piece Assets

**Source**: Cburnett Chess Pieces from Wikimedia Commons
**License**: CC-BY-SA 3.0 (Creative Commons Attribution-ShareAlike)
**Creator**: User:Cburnett
**URL**: https://commons.wikimedia.org/wiki/Category:SVG_chess_pieces

**Assets Used** (12 SVG files):
- White pieces: `Chess_klt45.svg`, `Chess_qlt45.svg`, `Chess_rlt45.svg`,
  `Chess_blt45.svg`, `Chess_nlt45.svg`, `Chess_plt45.svg`
- Black pieces: `Chess_kdt45.svg`, `Chess_qdt45.svg`, `Chess_rdt45.svg`,
  `Chess_bdt45.svg`, `Chess_ndt45.svg`, `Chess_pdt45.svg`

**File Naming Convention**:
- Format: `Chess_XYZ45.svg`
- X = piece letter (k=king, q=queen, r=rook, b=bishop, n=knight,
  p=pawn)
- Y = color (l=light/white, d=dark/black)
- Z = background (t=transparent)
- 45 = size reference

**Implementation Details**:
- Assets stored in `Assets.xcassets` catalog
- `PieceType.assetName(for:)` method maps pieces to asset names
- `Piece.assetName` property provides convenient access
- ChessBoardView uses `Image()` with `.resizable()` and
  `.aspectRatio()` for proper scaling
- Vector graphics scale perfectly on all iOS devices

**Attribution**: These chess pieces are widely used across Wikipedia,
chess.com (early versions), and numerous chess applications. The
Cburnett style is considered a standard for digital chess
representation.

### Technical Challenges Resolved

**Oct 8, 2025**: SwiftUI Color initializer ambiguity
- **Problem**: Color(red:green:blue:) was being misinterpreted as
  Decodable initializer
- **Solution**: Moved color definitions to file-level constants with
  explicit SwiftUI.Color type qualification
- **Learning**: SwiftUI color initialization in struct properties can
  have type inference issues; file-level constants avoid this

**Oct 8, 2025**: Chess piece visual quality
- **Problem**: Unicode chess symbols (♔♕♖♗♘♙) rendered with
  unprofessional "hollow/sketch" appearance for white pieces
- **Attempted Solutions**: SF Symbols (not available), solid Unicode
  with white fill (foregroundColor doesn't work on emoji-style glyphs),
  white background circles (visually unappealing)
- **Final Solution**: Professional SVG assets from Wikimedia Commons
  (Cburnett pieces)
- **Result**: App Store-quality graphics matching professional chess
  applications
- **Learning**: Unicode chess symbols are inadequate for professional
  iOS apps; vector image assets are required for quality presentation

**Oct 8, 2025**: Responsive piece sizing across devices
- **Problem**: Hardcoded 50x50 piece size resulted in tiny pieces on
  iPad and layout issues in landscape orientation
- **Solution**: Replaced fixed size with GeometryReader-based
  responsive sizing (pieces scale to 90% of square size with 10%
  padding)
- **Result**: Perfect piece scaling across iPhone, iPad, macOS, and
  all orientations
- **Learning**: Always use GeometryReader for content that must adapt
  to varying container sizes

### Time Controls System

**Architecture:** iOS-native implementation with separate White/Black settings

**Features:**
- Dual slider interface (minutes 0-60, increment 0-60 seconds)
- Segmented status picker (Enabled/Disabled)
- Quick presets (Blitz 5/0, Rapid 10/5, Classical 30/10, Terminal Default 30/10 vs 5/0)
- Bidirectional sync (status picker ↔ slider values)
- Main screen display with tappable time shortcut
- Game-start lock (warning displayed, enforcement in Phase 2)

**Persistence:** `@AppStorage` for whiteMinutes, whiteIncrement, blackMinutes, blackIncrement

### Opponent Selection System

**Architecture:** Multi-engine with protocol-based design for future expansion

**Current Implementation:**
- Stockfish (offline): Skill level 0-20 with slider, GPL license attribution
- Chess.com (placeholder): Future Phase 3 implementation
- Lichess (placeholder): Future Phase 2 implementation

**Persistence:** `@AppStorage` for selectedEngine and stockfishSkillLevel (default 5)

**Features:**
- Engine selection with checkmarks
- Skill level descriptions (Beginner/Casual/Intermediate/Advanced/Expert/Maximum)
- Main screen display shows "Opponent: Stockfish (Level X)"
- Game-start lock warning for skill changes

### Score Evaluation System

**Scale Formats:**
- Centipawns (standard chess engine format)
- Scaled (-9 to +9) - terminal project parity with conversion chart
- Win Probability (percentage format)

**Features:**
- Scale selection with @AppStorage persistence (default: "scaled")
- Conversion chart view (appears only when Scaled format selected)
- Complete centipawn mapping from terminal project

### Future Considerations
- App Store deployment strategy
- Monetization approach (if any)
- Multi-platform support (iOS, iPadOS, macOS)
- Online gameplay features
- Additional chess piece styles (minimalist, Staunton, 3D rendered)

---
*Developer reference for Claude Chess iOS - Living documentation for
SwiftUI implementation*
