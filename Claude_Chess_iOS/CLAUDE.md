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

**Current Phase:** Phase 3 IN PROGRESS 🔄 - Game Features & Polish
**Created:** September 30, 2025
**Last Updated:** October 23, 2025 (Session 26)
**Development Stage:** Fully playable chess game with all core rules,
complete Stockfish AI integration with skill-aware draw offer system,
position evaluation, hint system, in-app PDF User Guide with share
functionality, and Contact Developer feature. Polished UX with
responsive design verified across all device sizes (iPhone 11 through
iPad Pro M4)

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
    FEN parsing and asset name generation, plus static
    `fromFENCharacter()` helper
- `Models/ChessGame.swift` - Complete game state management with
    board position, castling rights, en passant tracking, move
    counters, and `setupFromFEN()` method for FEN string parsing
- `Models/BoardColorTheme.swift` - Board color theme system with
    RGB color components, 6 preset themes, and custom color support
- `Models/MoveValidator.swift` - Complete move validation with check
    detection (Phase 2)
- `Models/GameStateChecker.swift` - Check/checkmate/stalemate
    detection system (Phase 2)
- `Models/ChessEngine.swift` - Protocol defining unified interface
    for chess engines (Phase 3)
- `Models/StockfishEngine.swift` - Stockfish UCI implementation via
    ChessKitEngine package (Phase 3)
- `Models/EngineTest.swift` - Test utilities for Stockfish
    verification (Phase 3)

### Views (Implemented)
- `Views/ChessBoardView.swift` - Visual 8x8 chess board with
    dynamic color themes and piece rendering using Cburnett SVG graphics
- `Views/PromotionPiecePickerView.swift` - Pawn promotion piece
    selection dialog (Phase 2)
- `Views/SettingsView.swift` - Settings menu with board color theme
    selection and custom color picker with live preview
- `Views/ChessPiecesView.swift` - Chess piece style selection
- `Views/GameMenuView.swift` - Game menu for chess-specific commands
- `Views/ScoreView.swift` - Position evaluation display with scale settings
- `Views/ScaleView.swift` - Evaluation scale format selection
- `Views/ScoreConversionChartView.swift` - Centipawn to scaled conversion table
- `Views/AboutView.swift` - App information, licenses, Help & Feedback section with User Guide and Contact Developer
- `Views/PDFViewerView.swift` - PDF document viewer using PDFKit for User Guide display with share functionality
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

**Current TODO Inventory (5 total as of Oct 23, 2025 - Session 26):**

**Phase 3 - Move Validation & Game Logic (0 TODOs):**
- ✅ All validation complete (2 castling TODOs removed in Session 15 post-session fixes)

**Phase 3 - UI & Display (1 TODO):**
- `ScoreView.swift` (line 58) - Display game statistics

**Phase 3 - Game Management (4 TODOs):**
- `GameMenuView.swift` (line 80) - Import FEN action (load .fen files with position navigation + save prompt)
- `GameMenuView.swift` (line 86) - Import PGN action (load .pgn files with move-by-move navigation + save prompt)
- `GameMenuView.swift` (line 92) - Share Game action (mid-game sharing via iOS share sheet)
- `GameMenuView.swift` (line 143) - Save current game to file (Setup Board Phase 3 placeholder)

**Future/Optional (0 TODOs):**
- ✅ All optional TODOs removed

**Changes in Session 26:**
- No TODO additions or removals - inventory remains stable at 5 TODOs
- Updated line numbers after code changes

**Changes in Session 23:**
- Removed 4 TODOs: Resign (completed in QuickGameMenuView), FEN display (completed), PGN display (completed)
- Total reduced from 9 to 5 TODOs

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

## Terminal Project Feature Parity Audit

**Goal**: Replicate ALL terminal project functionality in iOS
native format.

**Reference**: `../CLAUDE.md` for complete terminal project specifications

### Summary Status
- **✅ Fully Implemented:** 24 features (draw offer system complete in Session 22)
- **🔄 Partially Implemented:** 0 features
- **❌ Missing/Not Planned:** 12 features
- **📋 iOS-Specific Adaptations Needed:** 6 features

---

### 1. CORE CHESS RULES

**✅ Fully Implemented in iOS:**
- ✅ Move validation (all piece types)
- ✅ Check/checkmate/stalemate detection
- ✅ Castling (kingside/queenside with rights tracking)
- ✅ En passant capture with state tracking
- ✅ Pawn promotion with interactive piece selection UI (Q/R/B/N)
- ✅ 50-move rule draw detection with automatic alert
- ✅ FEN counter system (halfmove clock, fullmove number)
- ✅ Legal move highlighting
- ✅ King position tracking

**✅ Fully Implemented in iOS (Session 22):**
- ✅ **Draw offer system** - Skill-aware AI draw acceptance based on position evaluation

---

### 2. MOVE INPUT & DISPLAY

**✅ iOS Has (Better Than Terminal):**
- ✅ Touch input (tap-to-select, tap-to-move)
- ✅ Drag-and-drop with ghost piece feedback
- ✅ Haptic feedback (user-controllable)
- ✅ Visual legal move indicators (green circles, blinking captures)
- ✅ Red border for king in check

**❌ Missing from iOS (Terminal Has):**
- ❌ **Move history display** - Terminal shows full game notation
  in real-time
- ❌ **Move notation format** - Terminal displays algebraic notation
  (e2e4, Nf3, etc.)
- ❌ **Last move indicator** - Terminal highlights the last move made

---

### 3. AI OPPONENT INTEGRATION

**✅ Fully Implemented in iOS (Session 17):**
- ✅ Opponent selection menu (Human/Stockfish/Lichess/Chess.com)
- ✅ Skill level slider (0-20) with game-start lock
- ✅ **Stockfish UCI integration** - Complete via ChessKitEngine package
- ✅ **AI move automation** - Stockfish responds automatically after human moves
- ✅ **Skill level depth mapping** - Realistic strength (depth 1-15 for skill 0-20)
- ✅ **Human vs Human mode** - Local two-player games
- ✅ **Pondering prevention** - Disabled during initialization
- ✅ **Search mode selection** - Depth-based search (time-based pending time integration)

**✅ Completed in iOS (Session 18):**
- ✅ **Position evaluation** - Terminal has `get_position_evaluation()` showing centipawn scores
- ✅ **Evaluation scale conversion** - Terminal has `centipawns_to_scale()` (-9 to +9)
- ✅ **Hint system** - Terminal has `get_hint_move()` with fast depth-based search

**❌ Terminal Features Not Yet in iOS:**
- ❌ **Timer integration with AI** - Terminal uses 1/20th of remaining time for AI moves

---

### 4. TIME CONTROLS

**✅ Fully Implemented in iOS (Session 15):**
- ✅ Time control configuration UI (White/Black separate settings)
- ✅ Quick presets (Blitz, Rapid, Classical, Terminal Default)
- ✅ Time display in ContentView header with MM:SS formatting
- ✅ Enable/Disable toggle
- ✅ **Active timer countdown** - Live updates every second via Combine
- ✅ **Time increment system** - Adds seconds after each move (White/Black separate)
- ✅ **Time forfeit detection** - Automatic game-end alert when time expires
- ✅ **Undo disables time** - Time controls disabled for remainder of game after undo
- ✅ **Game-start lock enforcement** - Prevents changes after first move OR after undo
- ✅ **"Start Game" button** - User-controlled timer start (fixes terminal UX weakness)

**❌ Not Yet Implemented:**
- ❌ **Timer integration with AI** - Terminal uses 1/20th of remaining
  time for AI moves (requires AI integration first)

---

### 5. GAME MANAGEMENT

**✅ iOS Has:**
- ✅ New Game functionality
- ✅ Setup Game Board (FEN import for testing)
- ✅ Game state persistence in @Published properties
- ✅ **Undo system** - Full undo with move history stack (Session 14)

**❌ Terminal Features Not Yet in iOS:**
- ❌ **Resign functionality** - Terminal allows either player to
  resign
- ❌ **Save current game prompt** - Terminal asks before loading new
  position
- ❌ **Auto-save on game end** - Terminal creates FEN/PGN files
  automatically
- ❌ **Game result tracking** - Terminal records win/loss/draw
  outcomes

---

### 6. FEN/PGN FILE MANAGEMENT

**✅ iOS Has:**
- ✅ FEN parser (`setupFromFEN()`) - complete and working
- ✅ FEN import via Setup Game Board

**❌ Terminal Features Not Yet in iOS:**
- ❌ **FEN/PGN import with navigation** - Terminal has `LOAD FEN` and
  `LOAD PGN` with arrow key position browsing
- ❌ **FEN/PGN dual directory scanning** - Terminal scans current dir
  + configured FENDirectory/PGNDirectory
- ❌ **Position navigator** - Terminal has `FENNavigator` struct with
  positions array, count, current index
- ❌ **Smart filtering** - Terminal excludes current game's FEN from
  load list
- ❌ **Auto-save FEN on game end** - Terminal creates `.fen` files
  automatically (FENON/FENOFF)
- ❌ **Auto-save PGN on game end** - Terminal creates `.pgn` files
  automatically (PGNON/PGNOFF)
- ❌ **Share Game feature** - iOS planned but not implemented
- ❌ **PGN generation** - Terminal has `convert_fen_to_pgn()` with
  full move history

---

### 7. OPENING LIBRARY

**❌ Terminal Has (Completely Missing from iOS):**
- ❌ **24 validated FEN files** - 12 classical openings + 12 tactical
  demonstrations
- ❌ **Opening validation tools** - `validate_openings`,
  `verify_openings`, `regenerate_openings`
- ❌ **FEN file integration** - Terminal loads openings via LOAD FEN
  command
- ❌ **Opening metadata** - Move count, timestamp, source directory
  tracking

---

### 8. CONFIGURATION SYSTEM

**🔄 iOS Has (Different Approach):**
- 🔄 UserDefaults for persistence (@AppStorage)
- 🔄 Settings view with sections
- 🔄 Board color themes with custom picker
- 🔄 Piece style selection (Cburnett)

**❌ Terminal Features Not in iOS:**
- ❌ **CHESS.ini configuration file** - Terminal auto-creates with
  comprehensive settings
- ❌ **Default skill level** - Terminal loads from config
- ❌ **Default time control** - Terminal loads from config
  (e.g., "30/10/5/0")
- ❌ **FEN/PGN directory paths** - Terminal configures separate
  directories
- ❌ **Auto-create PGN toggle** - Terminal has config setting
- ❌ **Auto-delete FEN toggle** - Terminal has config setting
- ❌ **Path validation** - Terminal validates directories on startup
- ❌ **Tilde expansion** - Terminal supports `~/Documents` style paths

---

### 9. COMMAND LINE OPTIONS → iOS SETTINGS

**📋 iOS Adaptation Needed:**
Terminal command-line flags require iOS Settings equivalents:
- **DEBUG mode** → iOS: Developer settings or compile-time flag?
- **PGNOFF** → iOS: Settings toggle for "Auto-save PGN"
- **FENOFF** → iOS: Settings toggle for "Auto-delete FEN"
- **/HELP** → iOS: About/Help view (already planned)

---

### 10. CAPTURED PIECES TRACKING

**✅ iOS Has:**
- ✅ **UI ready** - ContentView has "Captured pieces" display area
- ✅ **Logic implemented** - Calculated from move history (Session 14)

---

### 11. GAME STATE DETECTION & ALERTS

**✅ iOS Has:**
- ✅ Check detection with visual indicator (red border)
- ✅ Checkmate alert with winner announcement
- ✅ Stalemate alert

**❌ Terminal Additional Features:**
- ❌ **50-move rule draw** - Automatic detection with user prompt
- ❌ **Threefold repetition** - (Not implemented in terminal either)
- ❌ **Insufficient material** - (Not implemented in terminal either)

---

### 12. DISPLAY & UI

**✅ iOS Advantages:**
- ✅ Professional SVG chess pieces (Cburnett)
- ✅ Customizable board colors (7 themes + custom)
- ✅ Device-adaptive scaling
- ✅ Responsive layout (iPhone/iPad/macOS)
- ✅ Haptic feedback
- ✅ **Board flipping** - Quick Menu toggle to flip perspective

**❌ Terminal Features Not in iOS:**
- ❌ **Move history display** - Terminal shows scrolling move list
- ❌ **Position evaluation display** - Terminal shows
  centipawn/scaled score
- ❌ **Live PGN display** - Terminal can show real-time PGN in
  separate terminal window

---

### 13. SPECIAL FUNCTIONS

**❌ Terminal Utilities Not Planned for iOS:**
- ❌ **FEN-to-PGN converter** - Terminal has `fen_to_pgn` standalone
  utility
- ❌ **PGN-to-FEN converter** - Terminal has `pgn_to_fen` with engine
  validation
- ❌ **Opening validation** - Terminal has bash scripts for FEN file
  validation
- ❌ **Testing framework** - Terminal has `micro_test.c` (not needed
  for iOS - use XCTest)

---

## 🎯 PRIORITY IMPLEMENTATION ROADMAP

### **Phase 2 COMPLETE ✅ (October 11, 2025):**
All core chess rules now fully implemented:
1. ✅ **Pawn promotion UI** - Interactive piece selection dialog (Q/R/B/N)
2. ✅ **50-move rule draw** - Automatic detection with alert

### **Phase 3 - Critical Missing Features (Terminal Parity):**

**Priority 1: AI Integration (Highest Priority)**
1. **Stockfish UCI Integration**
   - Port UCI protocol communication from terminal project
   - Implement `get_best_move()` equivalent
   - Add position evaluation display
   - Implement hint system with fast depth-based search
   - Distinguish AI vs human promotion handling
   - Prevent pondering during human turns
   - Search mode selection (depth vs time-based)

**Priority 2: Move History System ✅ COMPLETE (Session 14)**
2. **Move History & Undo**
   - ✅ Track all moves in array with notation
   - 📋 Display move history list (Phase 4)
   - ✅ Enable undo functionality with stack
   - 📋 Support PGN generation from history (requires algebraic notation)
   - 📋 Algebraic notation converter (Position → "e2e4", "Nf3", etc.)

**Priority 3: Core Game Features ✅ COMPLETE (Sessions 14-15)**
3. **Captured Pieces Calculation**
   - ✅ Compare current board to starting position
   - ✅ Display captured pieces for each side
   - ✅ Update display after each move

4. **Time Controls Enforcement**
   - ✅ Active timer countdown during turns
   - ✅ Time increment after each move
   - ✅ Time forfeit detection with automatic loss
   - ✅ MM:SS display formatting
   - ✅ Undo disables time controls
   - ✅ User-controlled game start (Start Game button)
   - 📋 Integration with AI move timing (1/20th remaining time) - requires AI first

**Priority 4: File Management**
5. **FEN/PGN Import with Navigation**
   - iOS document picker integration
   - Position navigator with swipe/buttons
   - Live board preview during navigation
   - "Save current game" prompt before loading
   - Support for multi-position .fen files
   - Move-by-move PGN navigation

6. **Auto-Save System**
   - Settings toggles for FEN/PGN auto-save (FENON/FENOFF,
     PGNON/PGNOFF parity)
   - Save location picker (Files/iCloud)
   - Automatic file creation on game end
   - iOS Files app integration
   - Timestamp-based filenames
   - PGN generation with headers and full move history

7. **Share Game Feature**
   - Mid-game sharing via iOS share sheet
   - Share FEN (current position)
   - Share PGN (full game to current point)
   - AirDrop, Messages, Email, Clipboard support

### **Phase 4 - Nice to Have:**
1. Opening library integration (24 FEN files from terminal project)
2. Move notation display format options
3. Configuration system parity (more default settings)
4. Resign functionality
5. Draw offer system

---

## 📊 PROJECT STATISTICS

**Terminal Project:**
- 2050+ lines of chess logic in C
- 24 validated opening FEN files
- Complete UCI protocol implementation
- Full configuration system (CHESS.ini)
- Comprehensive file management
- Time controls with separate White/Black allocations
- Position evaluation and hint system
- Move history and undo

**iOS Project (Current State - Session 17):**
- 100% of core chess rules implemented
- Complete Stockfish AI integration with realistic difficulty scaling
- Professional UI/UX with touch/drag controls and haptic feedback
- Human vs Human and Human vs AI gameplay modes
- Board flipping, time controls, undo, captured pieces tracking
- **Feature parity gap:** ~25% of terminal features remaining (mainly file management and evaluation display)

---

**Verification Protocol**: Before marking any feature complete, verify
behavior matches terminal project by consulting `../CLAUDE.md` and
testing terminal version for edge cases.

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
- [ ] Auto-save and file management (see Auto-Save & File Management System section)

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

**Session 11: Oct 11, 2025** - Setup Game Board (FEN Import for Testing)
- Implemented "Setup Game Board" feature replacing "Load Game" menu item
- Added complete FEN parser in ChessGame.setupFromFEN() method
- Parses all 6 FEN components: pieces, player, castling, en passant,
  halfmove, fullmove
- Text input alert for pasting FEN strings
- Automatic game state detection after FEN setup (checkmate/stalemate/check)
- Added .onAppear and .onChange triggers in ChessBoardView for
  non-move game state checks
- Critical testing tool matching terminal project's SETUP function

**Session 12: Oct 11, 2025** - Auto-Save System & Menu Cleanup
- Documented comprehensive Auto-Save & File Management System (Phase 3)
- Auto-save FEN/PGN toggles in Settings (matches terminal FENON/FENOFF,
  PGNON/PGNOFF)
- Save location picker for Files/iCloud destination
- Share Game feature replaces Export FEN/Export PGN buttons
- Removed "Load Game" menu item (redundant with Import FEN/Import PGN)
- Renamed section header: "Import/Export" → "Import Games"
- Updated TODO tracking (20 total with auto-save items)

**Session 13: Oct 11, 2025** - Phase 2 Complete: Pawn Promotion &
50-Move Rule
- Created PromotionPiecePickerView.swift with piece selection dialog
- Implemented isPromotionMove() and makePromotionMove() in ChessGame
- Integrated promotion for both tap and drag-and-drop move input
- Added 50-move rule detection: isFiftyMoveRuleDraw() in ChessGame
- Integrated 50-move rule alert in checkGameEnd()
- Fixed SwiftUI compilation error (optional binding on non-Optional String)
- User testing confirmed: promotion works for all 4 pieces (Q/R/B/N),
  both colors
- User testing confirmed: 50-move rule alert triggers correctly at
  halfmove clock 100
- Added 3 new FEN testing strings to documentation (promotion × 2,
  50-move rule)
- **Phase 2 milestone achieved**: All core chess rules now fully
  implemented!

**Session 14: Oct 13, 2025** - Move History, Undo, & Captured Pieces
- Created MoveRecord.swift with complete move and game state capture
- Implemented full undo system with perfect state restoration
- Added move history tracking to ChessGame with @Published array
- Updated makeMove() and makePromotionMove() to record all moves
- Implemented undoLastMove() handling castling, en passant, promotion
- Added capturedByWhite and capturedByBlack computed properties
- Updated ContentView to display captured pieces using SVG assets
- Moved undo button from menus to main header for instant visual feedback
- Implemented dynamic button colors matching board theme
- Fixed Unicode symbol sizing issues by using professional SVG pieces
- TODO count reduced from 18 to 15 (removed completed items)

**Session 15: Oct 13, 2025** - Time Controls Enforcement & Start Game UX
- Implemented complete time controls system with live countdown
- Added timer state properties to ChessGame (@Published for UI reactivity)
- Integrated Combine framework for Timer.publish() every-second updates
- Time increment system applies seconds after each move (White/Black separate)
- Time forfeit detection with automatic game-end alert
- Undo disables time controls for remainder of game (terminal parity)
- Game-start lock prevents time control changes after first move OR after undo
- **Major UX improvement:** Added "Start Game" button in Quick Menu
- Timer no longer starts automatically (fixes terminal app weakness)
- Updated captured pieces display to use tappable overlay (Session 14 refinement)
- Fixed iOS 17 onChange deprecation warning
- TODO count remains at 14 (no feature completion)
- **Post-Session Bug Fixes:**
  - Fixed time controls display not updating when settings changed (added 4 .onChange() observers)
  - Fixed castling validation missing two chess rules (cannot castle while in check, cannot castle through attacked squares)
  - Added !isInCheck() and !isSquareAttacked() checks to MoveValidator.swift castling logic
  - Removed 2 TODOs from MoveValidator.swift code
  - TODO count reduced from 14 to 12

**Session 16: Oct 14, 2025** - Stockfish Engine Integration Foundation
- Added ChessKitEngine Swift Package (v0.7.0) via Xcode SPM
- Created ChessEngine protocol defining unified interface for all engines
- Implemented StockfishEngine conforming to ChessEngine protocol
- Complete UCI protocol communication via ChessKitEngine wrapper
- Downloaded and integrated Stockfish 17 neural network files (71MB + 3.4MB)
- Created EngineTest.swift with comprehensive and quick test functions
- Added "Stockfish Integration Tests" button to Quick Menu
- Wired up test button with async/await and results display sheet
- **Critical bug fixes for process management:**
  - Fixed Stockfish process zombie/leak causing SIGPIPE crashes
  - Enhanced shutdown() with proper cleanup delays (quit + stop + waits)
  - Added Task.isCancelled check in response listener
  - Prevented multiple initializations with cleanup guards
  - Added deinit emergency cleanup
- **Testing validation:** All 6 engine tests passing on macOS/iOS
  simulators AND real iPhone 14 Pro
- **Repeatability confirmed:** Tests work multiple times, standalone
  mode, all platforms
- Zero-warning clean build maintained

**Session 17: Oct 16, 2025** - AI Gameplay Complete with Game Controls
- **Board flipping feature:** Added "Flip Board" button to Quick Game Menu
  with @AppStorage persistence and seamless coordinate transformation
- **Human vs Human mode:** Added "Human" opponent option in OpponentView
  for local two-player games
- **Opponent/skill locking:** Implemented game-start lock preventing
  opponent/engine/skill changes after gameplay begins
  - Updated OpponentView.swift with locking logic for all opponent selections
  - Updated StockfishSettingsView.swift with engine/skill level locks
  - Orange warning text with disabled controls (50% opacity)
  - Lock triggers: game.gameInProgress || !game.moveHistory.isEmpty
- **Board move locking:** Added guards in ChessBoardView preventing
  piece movement until "Start Game" button tapped
  - Guards added to handleDragChanged() and handleSingleTap()
- **AI engine initialization bug fix (CRITICAL):** Fixed Stockfish not
  making moves
  - Root cause: Engine wasn't being initialized when "Start Game" tapped
  - Solution: Added initializeEngine() call in QuickGameMenuView "Start Game"
  - Added @AppStorage properties to read selectedEngine and skillLevel
  - Debug logging confirmed proper engine initialization flow
- **Skill level depth mapping:** Implemented realistic strength scaling
  - Created calculateSearchDepth(for:) in StockfishEngine.swift
  - Maps skill 0-20 to search depth 1-15 plies
  - Skill 5 = depth 3, Skill 10 = depth 7, Skill 20 = depth 15
  - Prevents depth-10-for-all issue causing unrealistic strength
- **Testing validation:** User confirmed AI move quality matches reference
  Stockfish 17.1 engine at all skill levels
- **Phase 3 AI Gameplay milestone achieved:** Fully playable Stockfish
  integration with appropriate difficulty scaling

**Session 18: Oct 17, 2025** - Position Evaluation & Hint System Complete
- **Priority 0: Stockfish Version Verification** - Fixed engine lifecycle bug
  with singleton pattern (StockfishEngine.shared) to prevent multiple instances
- **Quick Fixes:** Haptic feedback on AI moves, moved Integration Tests to
  Stockfish Settings, removed redundant About from Settings, added ChessKitEngine
  license to About view
- **Priority 4: AI Time Controls Integration** - Confirmed already complete
  (Session 15)
- **Priority 1: Position Evaluation Display** - Implemented complete evaluation
  system with 3 display formats (centipawns, scaled -9 to +9, win probability)
  and live updates during gameplay. Added evaluatePosition() to StockfishEngine,
  integrated with ScoreView displaying color-coded evaluation with interpretation
  text. Score moved from hamburger menu to Quick Menu for better UX.
- **Priority 2: Hint System Implementation** - Complete hint system ported from
  terminal project with 4-state UI (game not started warning, loading indicator,
  hint display with UCI formatting, no engine warning). Added requestHint() to
  ChessGame, complete HintView rewrite with formatHintMove() and hintDescription()
  helpers. Fixed hint availability logic: checks game.engine != nil (not opponent
  setting) and game.gameInProgress (prevents hints before "Start Game"). User
  confirmed: "Hint system seems to be working fine."
- **TODO count reduced:** 12 → 9 total (removed HintView and ScoreView evaluation
  TODOs)

**Session 19: Oct 17, 2025** - Critical AI Gameplay Bug Fixes
- **Human move during AI turn bug** - Fixed human allowed to make Black's move
  when Stockfish playing Black (added guard in ChessBoardView move handlers)
- **AI double-move bug** - Fixed Stockfish making two moves on same turn
  (fixed race condition in getBestMove with proper async/await sequencing)
- **AI timeout/freeze bug** - Fixed Stockfish not responding to promotion or
  castling positions (enhanced UCI position command handling)
- **Promotion piece selection for AI** - Fixed human promotion picker appearing
  for AI moves (AI now auto-selects Queen for all promotions)
- **Setup Board captured pieces** - Fixed missing captured pieces after FEN
  import (added calculateCapturedPiecesFromFEN() method)
- **Setup Board game state reset** - Fixed timer continuing from previous game,
  added "Save Current Game?" prompt with full game reset workflow
- **Post-session testing validation:** All Stockfish AI gameplay bugs resolved,
  Setup Board workflow matches terminal project behavior
- **TODO count unchanged:** 8 total (1 removed from GameMenuView.swift line 149,
  tracking section will be updated)

**Session 20: Oct 18, 2025** - Performance Optimization & Race Condition Fix
- **Stockfish performance optimization** - Reduced delays: initialization
  900ms→150ms, polling 100ms→10ms, stop delay 200ms→100ms (AI responds much faster)
- **Generation counter system** - Implemented request/response tracking to prevent
  stale bestmove responses (fixed race condition causing double-moves and cached moves)
- **Skill level bug fix** - Changed from variable depth (1-15) to fixed depth 10
  matching terminal project; all skill levels were playing identically due to
  insufficient move diversity at shallow depths
- **Terminal project parity** - Verified UCI "Skill Level" option with fixed depth 10
  matches terminal DEFAULT_SEARCH_DEPTH behavior
- **Debug cleanup** - Removed NSLog statements after race condition resolved
- **User testing** - No double-moves at any skill level, subtle difficulty differences
  visible, fast AI response times maintained
- **TODO count:** 8 → 9 (Setup Board save TODO confirmed as correct Phase 3 placeholder)

**Session 21: Oct 18, 2025** - Critical UX Fixes & Last Move Highlighting
- **Fixed checkmate/stalemate alerts** - Now only trigger after "Start Game" tapped,
  not immediately when FEN loaded via Setup Board (ChessBoardView.swift)
- **Fixed captured pieces persistence** - Setup Board captured pieces now persist
  after first move; added initialCapturedByWhite/Black properties (ChessGame.swift)
- **Last move highlighting system** - Added corner triangle markers (black) + semi-
  transparent overlay to show from/to squares; destination=large triangles (25%),
  origin=small triangles (15%); user-toggleable in Settings → Board → "Highlight
  Last Move" (default ON)
- **Removed redundant HINT** - Deleted from GameMenuView hamburger menu, kept in
  Quick Game Menu only

**Session 22: Oct 19, 2025** - Code Cleanup, UX Polish & Offer Draw Feature
- **Code cleanup complete** - Removed all debug print/NSLog statements from 5 files
  while preserving user-facing error messages (ChessBoardView, ChessGame,
  StockfishEngine, QuickGameMenuView, PromotionPiecePickerView)
- **HINT system UX revamp** - Transformed from 4-tap navigation flow to 2-tap
  alert popup; added yellow lightbulb button in header with immediate feedback
- **Header layout fix** - Implemented horizontal ScrollView for action buttons,
  solving layout constraints on smaller devices (iPhone 14 Pro tested)
- **Settings relocation** - Moved gear icon from header to Game Menu (under "Game"
  section), reducing button count from 5 to 4
- **Hint button disabled state** - Button now dims when game not started or no
  engine available (matching undo button pattern); removed unnecessary error alerts
- **Button reordering** - Swapped Quick Menu and Hint icons for better logical
  grouping (Undo→Hint→QuickMenu→GameMenu)
- **Responsive design validation** - Verified UI scales properly across all
  supported devices (iPhone 11 through iPad Pro M4) with Dynamic Type support
- **Offer Draw implementation** - Complete skill-aware draw acceptance system
  - AI evaluates position and decides based on evaluation + skill level
  - Threshold formula: -(100 + skillLevel * 10) centipawns
  - Lower skill = more willing to accept draws when losing
  - UCI evaluation sign-flip fix (White perspective → Black perspective)
  - Disabled/dimmed until game starts (matches Hint/Resign UX)
- **Position evaluation fix** - Added 500ms delay after Start Game to allow engine
  initialization, fixes "Evaluation Unavailable" issue
- **UI refinements** - Moved Offer Draw and Resign to Quick Menu, removed from
  Game Menu hamburger; added disabled states with 0.3 opacity for Score/Offer
  Draw/Resign buttons
- **Testing FEN strings** - Documented 5 validated positions for draw offer testing
  (Queen endgames, opening positions, equal positions)
- **TODO count:** 9 total (no change)

**Session 23: Oct 19, 2025** - Stockfish Color Selection Feature
- **Stockfish plays color selection** - Added segmented picker in Stockfish
  Settings allowing user to choose which color AI plays (White or Black)
- **Default setting** - Stockfish plays Black (human plays White) matching
  traditional chess setup
- **Immediate board flip** - Board orientation updates instantly when user
  changes color selection (via .onChange modifier)
- **Automatic time control swap** - Time allocations swap when color changes
  so human always gets intended time (White time → Black time when playing Black)
- **Game-start lock** - Color selection disabled after game starts (matches
  skill level lock pattern)
- **AI turn logic updates** - ChessGame.isAITurn and isHumanTurn now respect
  selected color (aiColor computed property)
- **2-second delay** - When Stockfish plays White, 2-second delay before
  first move gives user time to return to main view
- **Model updates** - Added stockfishColor parameter to initializeEngine()
  and resetGame() methods
- **Settings integration** - StockfishSettingsView, QuickGameMenuView, and
  GameMenuView all read and pass stockfishPlaysColor setting
- **User feedback** - Settings show "You are playing White/Black" based on
  selection

**Session 24: Oct 19, 2025** - Game-Ending Alerts, FEN/PGN Display & PGN Standard Features
- **Resign functionality complete** - Full resign confirmation with custom alert overlay
  showing winner's pawn (Cburnett SVG), Cancel returns to main view
- **Custom game-ending alerts** - Replaced standard SwiftUI alerts with professional
  custom overlays for all game endings: Checkmate (winning king), Stalemate (both kings),
  50-Move Rule Draw (handshake icon), Resignation (winner's pawn)
- **FEN display implementation** - Custom alert overlay with horizontal scrolling,
  Copy button with 1-second confirmation auto-dismiss, Cancel button returns to main view
- **PGN display implementation** - Custom alert overlay with move history, Copy button
  with 1-second confirmation, proper game result tracking (1-0, 0-1, 1/2-1/2, *)
- **PGN result fix** - Added checkmateWinner property to distinguish checkmate from draws;
  generatePGN() now checks resignation, then checkmate, then draws for accurate results
- **PGN standard FEN headers** - Added `[SetUp "1"]` and `[FEN "..."]` headers when game
  started from Setup Board (PGN standard for custom positions, universally supported)
- **Setup Board bug fixes** - Fixed persistent last-move indicators and disabled "Start Game"
  button; setupFromFEN() now clears lastMoveFrom/To, gameInProgress, gameHasEnded, and timer state
- **startingFEN tracking** - Added property to store FEN when using Setup Board; cleared on
  New Game (standard position)
- **TODO count:** 9 → 5 total (removed Resign, FEN display, PGN display TODOs)

**Session 25: Oct 20, 2025** - Critical Bug Fix: Position Evaluation Consistency
- **Bug discovered:** Draw offer system showing inconsistent behavior - AI declined draw
  when losing badly (+639cp White advantage reported, but evaluation varied wildly on
  subsequent tests: -179cp, -377cp, -627cp for same position at Skill Level 5)
- **Root cause analysis:** Two compounding bugs in evaluation system:
  1. **Skill Level applied to evaluations** - iOS evaluated at configured Skill Level
     (0-20), causing unreliable results at low skills; terminal project always evaluates
     at full strength regardless of play skill
  2. **Random depth capture** - iOS captured evaluation from any depth that happened to
     arrive (depth 3, 7, 10, etc.); terminal project only uses deepest depth (depth 15)
- **Fix 1: Skill Level boost for evaluations** - `StockfishEngine.evaluatePosition()`
  now temporarily sets skill to 20 before evaluation, restores original skill after
  (matches terminal project behavior where evaluations are always full strength)
- **Fix 2: Depth-based filtering** - Added `currentEvaluationDepth` tracking; only
  accepts evaluation scores from deepest depth seen; waits for depth 15 before returning
  (matches terminal `max_depth_seen` logic)
- **Fix 3: Proper wait timing** - Modified while loop condition to wait until
  `currentEvaluationDepth >= 15` before restoring skill level (prevents premature
  skill restoration that was causing evaluations to complete at wrong skill)
- **Testing results:** Evaluations now consistent at -550cp to -620cp (±35cp variance
  is normal per terminal project comments), all map to scaled score -8 matching terminal
  app; draw offer correctly declines when AI winning; verified on iPhone 17 Pro simulator
  and iPhone 14 Pro physical device
- **Bug discovered during session:** Time forfeit alert only shows "OK" button which
  clears board; should match Resign pattern with "OK" (return to board for review) and
  "New Game" (immediate reset) - documented in SESSION_START.md for Session 26
- **Files modified:** `StockfishEngine.swift` (evaluation skill boost + depth tracking),
  `ChessGame.swift` (draw offer color handling), `SESSION_START.md` (time forfeit bug)
- **TODO count:** 5 (unchanged)

**Session 26: Oct 23, 2025** - User Guide & Contact Developer Features
- **PDF User Guide viewer** - Implemented in-app PDF viewer using native PDFKit
  - Created `PDFViewerView.swift` with SwiftUI/UIViewRepresentable wrapper
  - Native PDF rendering with automatic scaling, zoom, and scroll support
  - Share button in toolbar for AirDrop, email, save to Files, print
  - Easy updates: replace UserGuide.pdf file and rebuild
- **Contact Developer feature** - Email feedback system with categorization
  - Added "Help & Feedback" section in AboutView (between App Information and Credits)
  - Moved User Guide to new section for logical grouping
  - Action sheet with 3 options: Feedback, Bug Report, Feature Request
  - Uses `mailto:` URL to open user's mail app with pre-filled recipient and subject
  - Email address easily changeable for future Gmail migration
- **AboutView refactoring** - Reorganized structure for better UX
  - New section: "Help & Feedback" containing User Guide and Contact Developer
  - User Guide moved from App Information to new section
  - Professional help/support workflow matching App Store best practices
- **Files created:** `PDFViewerView.swift`
- **Files modified:** `AboutView.swift`
- **TODO count:** 5 (unchanged)

**Session 26 (continued): Oct 24, 2025** - PGN Notation, Evaluation Freeze Fix, Time Forfeit Improvements
- **PGN check/checkmate notation** - Added `+` and `#` symbols to move notation
  - Added `causedCheck` and `causedCheckmate` properties to MoveRecord
  - Detection logic in ChessGame after move execution
  - Updated notation property to append appropriate symbols
- **Evaluation freeze bug SOLVED** - Implemented on-demand evaluation (Occam's Razor victory!)
  - Root cause: Concurrent UCI requests to single Stockfish instance
  - Solution: Evaluation only when user opens ScoreView (`.onAppear` trigger)
  - Removed all automatic evaluation calls from game flow
  - Shows "Evaluating position..." spinner during 3-5 second calculation
  - **End of 4-5 session debugging saga** - simple solution was best all along
- **Time forfeit alert improvements** - Custom overlay matching resign pattern
  - Created TimeForfeitAlertView with winner's pawn icon
  - Two-button design: "OK" (review board) vs "New Game" (reset)
  - Fixed re-triggering bug with gameHasEnded flag
- **Time forfeit PGN fix** - Correct winner shown in game result
  - Added timeForfeitWinner property to ChessGame
  - Updated generatePGN() to check time forfeit before other conditions
- **Debug cleanup** - Removed all NSLog statements from StockfishEngine.swift
  - Kept ERROR print statements for production debugging
  - Clean console output during gameplay
- **Files modified:** `MoveRecord.swift`, `ChessGame.swift`, `ChessBoardView.swift`,
  `ContentView.swift`, `ScoreView.swift`, `StockfishEngine.swift`
- **TODO count:** 5 (unchanged)

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

**Oct 11, 2025**: Phase 2 promotion strategy - Both White AND Black use
the same interactive promotion picker UI for Phase 2 human testing. This
simplifies implementation and provides consistent UX. Phase 3 AI
integration will add conditional logic to distinguish human vs AI
promotion (AI will select piece automatically via UCI notation like
"e7e8q"). Protocol-based ChessEngine architecture ensures clean
refactoring for Stockfish/Lichess/Chess.com engines.

**Oct 16, 2025**: Skill level depth mapping - Stockfish's UCI "Skill
Level" option has limited effect at high search depths. Solution:
calculateSearchDepth(for:) maps skill 0-20 to search depth 1-15 plies,
providing realistic strength variation. Skill 5 = depth 3 (beginner
mistakes), Skill 10 = depth 7 (intermediate play), Skill 20 = depth 15
(maximum strength). This prevents the depth-10-for-all issue that caused
unrealistic AI difficulty. User testing confirmed move quality matches
reference Stockfish 17.1 engine.

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

**✅ Phase 2 COMPLETE (Oct 11, 2025):**
- ✅ Touch input handling (tap to select/move pieces)
- ✅ Drag-and-drop piece movement with ghost piece feedback
- ✅ Haptic feedback system (user-controllable)
- ✅ Move validation logic (ported from terminal project)
- ✅ Legal move highlighting (respects check conditions)
- ✅ Piece movement with board state updates
- ✅ Check/checkmate/stalemate detection with visual indicators
- ✅ Game-start lock enforcement (time controls/skill level)
- ✅ En passant capture (fully implemented and tested)
- ✅ FEN parser and Setup Game Board feature (testing tool)
- ✅ **Pawn promotion with piece selection UI** (Q/R/B/N for both colors)
- ✅ **50-move rule draw detection** (automatic alert at halfmove clock 100)

**🔄 Phase 3 IN PROGRESS (Started Oct 13, 2025):**
- ✅ **Move history tracking** (MoveRecord with complete state capture)
- ✅ **Undo functionality** (perfect state restoration including special moves)
- ✅ **Captured pieces display** (calculated from move history, tappable overlay)
- ✅ **Time controls enforcement** (live countdown, increment, forfeit detection)
- ✅ **Start Game UX** (user-controlled timer start, fixes terminal weakness)
- ✅ **Board flipping** (Quick Menu toggle with @AppStorage persistence)
- ✅ **Human vs Human mode** (local two-player games)
- ✅ **Stockfish engine foundation** (ChessEngine protocol + StockfishEngine + tests)
- ✅ **Engine integration** (initializeEngine() in ChessGame model)
- ✅ **AI move automation** (Stockfish makes moves in game flow)
- ✅ **Skill level depth mapping** (realistic strength scaling depth 1-15)
- ✅ **Opponent/skill locking** (prevents changes after game starts)
- ✅ **Board move locking** (prevents moves until "Start Game" tapped)
- ✅ **Position evaluation display** (3 formats with live updates - Session 18)
- ✅ **Hint system implementation** (UCI formatting, 4-state UI - Session 18)
- ✅ **Stockfish color selection** (choose White or Black, instant board flip - Session 23)
- ✅ **Resign functionality** (custom alert with winner's pawn, Cancel returns to main - Session 24)
- ✅ **Game-ending alerts** (custom overlays for checkmate/stalemate/draw/resignation - Session 24)
- ✅ **FEN display** (custom alert with horizontal scroll, copy with auto-dismiss - Session 24)
- ✅ **PGN display** (custom alert with move history, proper result tracking - Session 24)
- ✅ **PGN FEN headers** (SetUp/FEN tags for Setup Board positions - Session 24)
- ✅ **Draw offer system** (skill-aware AI acceptance based on evaluation - Session 22)
- 📋 **Game statistics display** (move count, captures, time remaining)
- 📋 **FEN/PGN import with position navigation** (matches terminal LOAD FEN/PGN)
- 📋 **"Save current game" prompts before loading positions**
- 📋 Game save/load (iOS document picker)
- 📋 Share Game feature (iOS share sheet)

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

### Offer Draw System

**Architecture:** Skill-aware AI draw acceptance based on position evaluation

**Implementation:**
```swift
func offerDraw() async -> Bool {
    // Evaluate position from Stockfish
    let evaluation = try await engine.evaluatePosition(position: fen)

    // UCI evals are from White's perspective, flip for Black (AI)
    let blackEvaluation = -evaluation

    // Skill-aware threshold (lower skill = more willing to accept)
    let acceptThreshold = -(100 + (skillLevel * 10))

    // Accept only if losing badly
    return blackEvaluation < acceptThreshold
}
```

**Thresholds by Skill Level:**
- **Skill 5:** -150cp (accepts when losing 1.5+ pawns)
- **Skill 10:** -200cp (accepts when losing 2+ pawns)
- **Skill 20:** -300cp (accepts when losing 3+ pawns)

**UI Integration:**
- Located in Quick Game Menu between Flip Board and Resign
- Disabled until game starts and when playing against human
- Shows "Evaluating..." spinner during position analysis
- Alert displays accept/decline decision with appropriate message
- Red text matching Resign button style

**Testing FEN Strings:**
1. **White winning** (Black accepts): `8/8/8/8/4k3/8/8/3QK3 w - - 0 1`
2. **Black winning** (Black declines): `7k/8/3K4/8/8/8/8/q7 w - - 0 1`
3. **White minor edge** (Black declines): `rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1`
4. **Equal position** (Black declines): `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1`

### FEN/PGN Navigation System (Phase 3 - Planned)

**Critical Feature:** Matches terminal project's LOAD FEN and LOAD PGN commands

**Terminal Project Reference (`../CLAUDE.md`):**
- LOAD FEN - Browse .fen files, 20-line pagination, arrow key navigation
- LOAD PGN - Browse .pgn files, move-by-move navigation with arrows
- FENNavigator structure with positions[], count, current index
- User navigates forward/backward, then cancels or continues from position

**iOS Implementation Plan:**

**UI Components:**
1. **File Picker** - iOS document picker for .fen/.pgn files
2. **PositionNavigatorView** - Modal view with:
   - Live chess board preview (updates as you navigate)
   - Position counter (e.g., "5 of 18")
   - Navigation controls (swipe gestures + buttons)
   - "Save Current Game" prompt before loading
   - "Play from Here" and "Cancel" buttons

**Navigation Controls:**
- Swipe right = Next position
- Swipe left = Previous position
- Slider = Jump to any position instantly
- Buttons = Prev/Next for non-swipe users

**User Flow:**
1. Tap "Import FEN" or "Import PGN" in Game Menu
2. iOS document picker appears → select file
3. **"Save current game?"** alert appears (Yes/No/Cancel)
4. PositionNavigatorView modal opens
5. User navigates through positions (board updates live)
6. User taps "Play from Here" → loads that position, dismisses
7. OR user taps "Cancel" → dismisses without changes

**Educational Value (Critical!):**
- Study master games move-by-move
- Analyze opening sequences position by position
- Review your own games
- Learn from tactical positions
- **Superior to terminal:** Graphical board vs ASCII art

**Data Structure:**
```swift
struct PositionNavigator {
    var positions: [String]    // FEN strings
    var count: Int              // Total positions
    var currentIndex: Int       // Current position
    var metadata: String?       // PGN headers, game info
}
```

### Setup Game Board System (FEN Import - Testing Tool)

**Architecture:** Complete FEN parser matching terminal project's SETUP command

**Purpose:** Critical testing tool for development - allows immediate setup
of any chess position without playing through moves to reach it.

**NOTE:** This is different from "Import FEN" - SETUP takes a single FEN
string for immediate testing, while Import FEN loads multi-position files
with navigation.

**Implementation:**
- `ChessGame.setupFromFEN(_ fen: String) -> Bool` method parses complete FEN strings
- Validates all 6 FEN components: pieces, active player, castling rights,
  en passant target, halfmove clock, fullmove number
- Text input alert in GameMenuView for pasting FEN strings
- Automatic game state detection after setup (check/checkmate/stalemate)
- `.onAppear` and `.onChange(of: game.currentPlayer)` triggers in
  ChessBoardView detect non-move game states

**FEN Components Parsed:**
1. **Piece Placement**: 8 ranks separated by slashes, numbers = empty squares
2. **Active Player**: 'w' = White, 'b' = Black
3. **Castling Rights**: KQkq or dash (K=White kingside, Q=White queenside,
   k=Black kingside, q=Black queenside)
4. **En Passant Target**: Algebraic square or dash
5. **Halfmove Clock**: Moves since last pawn move or capture (50-move rule)
6. **Fullmove Number**: Full move count (increments after Black's move)

**User Access:** Game Menu → "Setup Game Board" → paste FEN → immediate board update

**Future Enhancement (Phase 3):** Add "Save current game?" prompt before setup
if the current board position differs from the standard starting position. This
prevents accidental loss of in-progress games when testing new positions.

**Testing Value:** Essential for validating check/checkmate/stalemate, castling,
en passant, pawn promotion, 50-move rule, and complex positions without manual
move entry. Matches terminal project's SETUP function utility.

**Sample FEN Strings for Testing:**

See README.md for complete list. Key testing positions include:
- **Pawn Promotion (White)**: `8/4P3/8/8/8/8/8/4K2k w - - 0 1`
  - White pawn on e7, 2 moves from promotion to test all 4 pieces (Q/R/B/N)
- **Pawn Promotion (Black)**: `4k2K/8/8/8/8/8/4p3/8 b - - 0 1`
  - Black pawn on e2, 2 moves from promotion to test all 4 pieces
- **50-Move Rule Test**: `8/8/8/4k3/8/8/4K3/8 w - - 98 100`
  - Halfmove clock at 98, triggers draw alert after 2 more moves

### Auto-Save & File Management System (Phase 3 - Planned)

**Terminal Project Parity:**
- Terminal app auto-creates .fen and .pgn files on game exit
- User controls via PGNON/PGNOFF and FENON/FENOFF command line options
- Files saved to configured directories
- Filename format: `chess_game_YYYYMMDD_HHMMSS.fen/pgn`

**iOS Implementation Strategy:**

**Settings Configuration (SettingsView):**

1. **Auto-Save Toggles** (independent controls):
   ```
   Settings → File Management
     ☑ Auto-save FEN on game end (default: ON)
     ☑ Auto-save PGN on game end (default: ON)
   ```
   - Matches terminal FENON/FENOFF and PGNON/PGNOFF behavior
   - User can enable FEN only, PGN only, both, or neither
   - Persisted via @AppStorage

2. **Save Location Picker:**
   ```
   Settings → File Management → Save Location
     ○ On My iPhone
     ○ iCloud Drive
   ```
   - iOS document picker for selecting folder
   - Defaults to app's Documents directory
   - Persisted path via @AppStorage
   - Future: Allow user to browse and select any Files app location

**Auto-Save on Game End:**

**Trigger Points:**
- Checkmate detected
- Stalemate detected
- Player resigns
- 50-move rule draw accepted

**Behavior:**
1. Game ends with result determined
2. If "Auto-save FEN" enabled:
   - Generate FEN string for final position
   - Save to: `{location}/position_YYYYMMDD_HHMMSS.fen`
3. If "Auto-save PGN" enabled:
   - Generate PGN with headers and full move history
   - Save to: `{location}/game_YYYYMMDD_HHMMSS.pgn`
4. Show brief toast notification: "Game saved to Files" (or "Game saved to iCloud")
5. Continue with game-end alert (checkmate/stalemate message)

**PGN File Format:**
```
[Event "iPhone Game"]
[Site "Claude Chess iOS"]
[Date "2025.10.11"]
[Round "1"]
[White "Player"]
[Black "Stockfish Level 5"]
[Result "1-0"]

1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. Qxf7# 1-0
```

**Share Game Feature (Mid-Game Sharing):**

**Location:** Game Menu → "Share Game" (replaces Export FEN/Export PGN)

**Functionality:**
1. User taps "Share Game" during active game
2. Alert presents options:
   - Share FEN (current position only)
   - Share PGN (full game history to this point)
   - Share Both
3. iOS share sheet appears with:
   - AirDrop
   - Messages
   - Email
   - Copy to clipboard
   - Save to Files (manual save, not auto-save)
4. User selects destination

**Use Cases:**
- Send position to friend for analysis
- Share game-in-progress via email
- Copy FEN to paste into chess analysis tool
- AirDrop game to iPad for larger screen

**Implementation Requirements:**

**Data Tracking (New Requirements):**
- Move history array: `[(from: Position, to: Position, piece: Piece, captured: Piece?)]`
- Algebraic notation generator: Convert Position pairs to "e2e4", "Nf3", etc.
- Game metadata: start time, player names, result
- Move timestamps (for PGN comments)

**File Operations:**
```swift
// Settings persistence
@AppStorage("autoSaveFEN") var autoSaveFEN = true
@AppStorage("autoSavePGN") var autoSavePGN = true
@AppStorage("saveLocation") var saveLocation = "Documents"

// File generation
func generateFEN() -> String { /* ... */ }
func generatePGN() -> String { /* ... */ }

// Save to Files app
func saveFile(content: String, filename: String, location: URL) {
    // iOS FileManager operations
}

// Share sheet
func shareGame(fen: String?, pgn: String?) {
    let activityVC = UIActivityViewController(...)
}
```

**iOS Files App Integration:**
- Files appear in "On My iPhone" → "Claude Chess" folder
- Or in "iCloud Drive" → "Claude Chess" folder (if iCloud enabled)
- User can browse/manage saved games in Files app
- Files automatically available for Import FEN/Import PGN

**Error Handling:**
- Save location not accessible → alert user, fall back to Documents
- iCloud not enabled → alert user, offer Files alternative
- Disk space insufficient → alert user
- Write permission denied → alert user

**Phase 3 Implementation Order:**
1. Add move history tracking to ChessGame model
2. Implement algebraic notation generator
3. Create FEN/PGN string generation functions
4. Add Settings toggles and location picker
5. Implement auto-save on game end
6. Add "Share Game" button and iOS share sheet
7. Test file saving to Files app and iCloud
8. Verify round-trip (save → import → play)

### Future Considerations
- App Store deployment strategy
- Monetization approach (if any)
- Multi-platform support (iOS, iPadOS, macOS)
- Online gameplay features
- Additional chess piece styles (minimalist, Staunton, 3D rendered)

---
*Developer reference for Claude Chess iOS - Living documentation for
SwiftUI implementation*
