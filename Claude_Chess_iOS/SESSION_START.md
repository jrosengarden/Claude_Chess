# Claude Chess iOS - Session Starter

**Last Updated:** October 17, 2025 (Session 18)
**Current Phase:** Phase 3 IN PROGRESS 🔄

## Quick Status

**Platform:** iOS 17.0+, iPadOS 17.0+, macOS 14.0+ (Apple Silicon)
**Framework:** SwiftUI
**Parent Project:** Terminal-based Claude Chess (C) - located at `../`
**Development Stage:** Fully playable chess game with complete Stockfish AI
integration, position evaluation, and hint system

## Active TODO Inventory (9 total)

**Phase 3 - UI & Display (1 TODO):**
- `ScoreView.swift` (line 46) - Display game statistics

**Phase 3 - Game Management (8 TODOs):**
- `GameMenuView.swift` (line 76) - Import FEN action
- `GameMenuView.swift` (line 82) - Import PGN action
- `GameMenuView.swift` (line 88) - Share Game action
- `GameMenuView.swift` (line 96) - Resign action
- `GameMenuView.swift` (line 116) - Setup Game Board save prompt
- `QuickGameMenuView.swift` (line 99) - Resign action
- `QuickGameMenuView.swift` (line 207) - FEN display implementation
- `QuickGameMenuView.swift` (line 221) - PGN display implementation

## Recent Sessions (Last 3)

**Session 18: Oct 17, 2025** - Position Evaluation & Hint System Complete
- Priority 1: Position Evaluation Display (3 formats: centipawns, scaled,
  win probability)
- Priority 2: Hint System Implementation (UCI formatting, 4-state UI)
- Quick fixes: Haptic on AI moves, Integration Tests moved, ChessKitEngine
  license added
- TODO count: 12 → 9

**Session 17: Oct 16, 2025** - AI Gameplay Complete
- Board flipping, Human vs Human mode
- Opponent/skill locking after game starts
- Board move locking until Start Game tapped
- AI engine initialization bug fix (CRITICAL)
- Skill level depth mapping (0-20 → depth 1-15)

**Session 16: Oct 14, 2025** - Stockfish Engine Foundation
- ChessKitEngine Swift Package (v0.7.0)
- ChessEngine protocol + StockfishEngine implementation
- Stockfish 17 neural network files integrated
- Fixed process management bugs (SIGPIPE crashes)
- All 6 tests passing on all platforms

## Current Priorities

**Next Up:**
1. **Priority 3: Game Statistics Display** (IN PROGRESS)
   - Move count display
   - Captured pieces already done (Session 14)
   - Time remaining already done (Session 15)

2. **INVESTIGATE: Stockfish move time issue** (PENDING)
   - 37 seconds at skill level 5 (expected ~2-3 seconds)

**Future Phase 3:**
- FEN/PGN import with navigation
- Share Game feature
- Resign functionality
- Auto-save system

## Phase Completion Status

**✅ Phase 1 COMPLETE** (Oct 9, 2025)
- Visual chess board, themes, settings, menus

**✅ Phase 2 COMPLETE** (Oct 11, 2025)
- All chess rules, move validation, check/checkmate/stalemate, promotion,
  50-move rule

**🔄 Phase 3 IN PROGRESS** (Started Oct 13, 2025)
- ✅ Move history, undo, captured pieces (Session 14)
- ✅ Time controls enforcement (Session 15)
- ✅ Stockfish engine integration (Session 16)
- ✅ AI move automation (Session 17)
- ✅ Position evaluation & hints (Session 18)
- 📋 Game statistics display
- 📋 File management (import/export/share)

## Key Project Files

**Models:**
- `ChessGame.swift` - Game state, engine integration, hint/evaluation
- `StockfishEngine.swift` - UCI protocol, depth mapping, singleton pattern
- `MoveValidator.swift` - Move validation
- `GameStateChecker.swift` - Check/checkmate/stalemate

**Views:**
- `ContentView.swift` - Main UI with board, time, captured pieces
- `ChessBoardView.swift` - 8x8 board with drag-and-drop
- `HintView.swift` - 4-state hint UI
- `ScoreView.swift` - Position evaluation display
- `QuickGameMenuView.swift` - Quick actions (Start Game, Flip Board, Hint)

## Essential Standards

1. **Zero Warnings** - All code must compile cleanly
2. **TODO Management** - Remove TODOs when features complete, update
   inventory immediately
3. **Documentation** - Update CLAUDE.md and README.md after major features
4. **Testing** - Verify in simulator after changes
5. **User Handles Git** - Never perform git operations

## Terminal Project Reference

**Location:** `../CLAUDE.md` (parent directory)
**Use When:** Implementing features to verify behavior matches terminal version
**Don't Read:** Unless actively implementing feature requiring terminal parity

## Quick Commands

**TODO Scan:**
```bash
grep -r "TODO" Claude_Chess/Claude_Chess/ | wc -l
```

**Recent Commits:**
```bash
git log -3 --format="%h %s%n%b"
```

**Build Project:**
```bash
xcodebuild -project Claude_Chess/Claude_Chess.xcodeproj \
  -scheme Claude_Chess -destination 'platform=iOS Simulator,name=iPhone 15'
```

---
*Condensed session starter - Read full CLAUDE.md only when needed*
 
 Next Session Workflow:
  1. Read SESSION_START.md (~150 lines vs 1691) (this document)
  2. Run git log -5 to see recent commits
  3. Start working immediately

