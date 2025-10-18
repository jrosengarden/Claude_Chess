# Claude Chess iOS - Session Starter

**Last Updated:** October 17, 2025 (Session 19)
**Current Phase:** Phase 3 IN PROGRESS 🔄

## Quick Status

**Platform:** iOS 17.0+, iPadOS 17.0+, macOS 14.0+ (Apple Silicon)
**Framework:** SwiftUI
**Parent Project:** Terminal-based Claude Chess (C) - located at `../`
**Development Stage:** Fully playable chess game with complete Stockfish AI
integration, position evaluation, hint system, and all critical gameplay
bugs resolved

## Active TODO Inventory (9 total)

**Phase 3 - UI & Display (1 TODO):**
- `ScoreView.swift` (line 46) - Display game statistics

**Phase 3 - Game Management (8 TODOs):**
- `GameMenuView.swift` (line 79) - Import FEN action
- `GameMenuView.swift` (line 85) - Import PGN action
- `GameMenuView.swift` (line 91) - Share Game action
- `GameMenuView.swift` (line 99) - Resign action
- `GameMenuView.swift` (line 149) - Save current game to file (Setup Board)
- `QuickGameMenuView.swift` (line 110) - Resign action
- `QuickGameMenuView.swift` (line 214) - FEN display implementation
- `QuickGameMenuView.swift` (line 228) - PGN display implementation

## Recent Sessions (Last 3)

**Session 20: Oct 18, 2025** - Performance Optimization & Race Condition Fix
- Fixed Stockfish AI slow response times (reduced delays: 900ms→150ms init, 100ms polling→10ms)
- Implemented generation counter system to prevent stale bestmove responses (race condition fix)
- Fixed skill level implementation (variable depth→fixed depth 10, proper UCI Skill Level usage)
- Removed NSLog debug statements after race condition resolved
- TODO count: 8 → 9 (Setup Board save TODO confirmed correct)

**Session 19: Oct 17, 2025** - Critical AI Gameplay Bug Fixes
- Fixed human move during AI turn (added turn validation guards)
- Fixed AI double-move bug (resolved async race condition)
- Fixed AI timeout on promotion/castling (enhanced UCI handling)
- Fixed AI promotion piece selection (AI auto-selects Queen)
- Fixed Setup Board captured pieces (added calculateCapturedPiecesFromFEN)
- Fixed Setup Board game state reset (Save Current Game? prompt added)
- TODO count: 9 → 8 (Setup Board save prompt implemented)

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

## Current Priorities

**Next Up:**
1. **File Management System** (HIGH PRIORITY)
   - FEN/PGN import with position navigation
   - Share Game feature (iOS share sheet)
   - Auto-save system with toggles

2. **Game Statistics Display** (MEDIUM PRIORITY)
   - Move count display in ScoreView
   - Captured pieces already done (Session 14)
   - Time remaining already done (Session 15)

3. **Resign Functionality** (LOW PRIORITY)
   - Implement in both GameMenuView and QuickGameMenuView
   - Game-ending alert with winner announcement

## Known Issues

**RESOLVED (Session 19):**
- ✅ Human allowed to move during AI turn
- ✅ AI making two moves on same turn
- ✅ AI timeout on promotion/castling positions
- ✅ Human promotion picker appearing for AI moves
- ✅ Missing captured pieces after Setup Board
- ✅ Timer continuing after Setup Board
- ✅ No Save Current Game? prompt before Setup Board

**NONE CURRENTLY OUTSTANDING**

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
- ✅ Critical AI gameplay bugs fixed (Session 19)
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
- `GameMenuView.swift` - Setup Board, Import/Share (placeholders)

## Essential Standards

1. **Zero Warnings** - All code must compile cleanly
2. **TODO Management** - Remove TODOs when features complete, update
   inventory immediately
3. **Documentation** - Update CLAUDE.md and README.md after major features
4. **Testing** - Verify in simulator AND physical device after AI changes
5. **User Handles Git** - Never perform git operations

## Terminal Project Reference

**Location:** `../CLAUDE.md` (parent directory)
**Use When:** Implementing features to verify behavior matches terminal version
**Don't Read:** Unless actively implementing feature requiring terminal parity

## Quick Commands

**TODO Scan:**
```bash
grep -r "TODO" Claude_Chess/Claude_Chess/ --include="*.swift" | wc -l
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
 1. Read SESSION_START.md (~180 lines vs 1700+) (this document)
 2. Run git log -5 to see recent commits
 3. Start working immediately
 4. THIS IS HIGHEST PRIORITY BEFORE ANYTHING ELSE:  The Stockfish AI seems to be taking
    way too much time to make it's moves.  For example at Skill Level 0 with me making
    an opening move of e2e4 the Stockfish AI should come back almost instantly with it's
    move but it isn't.  It's even worse at Skill Level 5 and I haven't even dared to try
    skill level 20.  You had started investigating this and found a 200ms delay that you
    had put in (I can't remember where) for debugging purposes that was still in the code
    but this STILL wasn't/isn't the main cause of the AI Engine taking too long.  We need
    to CAREFULLY investigate this issue and then PROPERLY RESOLVE IT..not 'patch' it.