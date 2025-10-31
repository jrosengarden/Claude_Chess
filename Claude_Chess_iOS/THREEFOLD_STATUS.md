# Session 31-32 Status - Board Flip Fix + Threefold Repetition

**Date:** October 29-30, 2025
**Status:**
- ✅ Board Flip Coordinate System - COMPLETE (Session 31)
- 🔴 Threefold Repetition - STILL INCOMPLETE (Session 32: concurrent evaluation bug remains)

## COMPLETED: Board Flip Coordinate System Fix (Session 31 Part 1)

**Problem:** Coordinate labels appearing on wrong edges when board flipped
- Before: Labels on TOP and RIGHT when flipped (double transformation issue)
- After: Labels stay on LEFT and BOTTOM always (correct behavior)

**Root Cause:** Entire container (board + labels) was being rotated 180°
- Coordinate labels were part of rotated view
- Labels ended up on opposite edges after rotation

**Solution:** Separated board rotation from label positioning
- Only the 8x8 chess board grid rotates 180° when flipped
- Coordinate labels stay in fixed positions (left edge and bottom edge)
- Label content order reverses when flipped (8-1 becomes 1-8, a-h becomes h-a)
- Labels maintain absolute chess coordinates regardless of board orientation

**Implementation Details (ChessBoardView.swift):**
- Moved `.rotationEffect()` from entire container to board grid only
- Rank labels: `boardFlipped ? (row + 1) : (8 - row)` for reversed order
- File labels: `boardFlipped ? (104 - col) : (97 + col)` for reversed order
- Labels always stay on LEFT (ranks) and BOTTOM (files) edges

**PGN Notation Verified:** Already correct, always uses absolute coordinates
- Position.swift `algebraic` property independent of board flip
- MoveRecord.swift notation generation uses Position.algebraic
- No references to boardFlipped in move recording logic

**Result:** Professional board flip matching Shredder iOS reference app
- Unflipped: LEFT = 8,7,6,5,4,3,2,1, BOTTOM = a,b,c,d,e,f,g,h
- Flipped: LEFT = 1,2,3,4,5,6,7,8, BOTTOM = h,g,f,e,d,c,b,a
- Board pieces rotate, labels stay on same edges with reversed order
- All move input/output uses absolute coordinates (e2e4 always means e2e4)

**Files Modified:** ChessBoardView.swift (restructured layout, fixed coordinate system)

---

## INCOMPLETE: Threefold Repetition Implementation (Session 31-32)

### Session 32 Progress (Oct 30, 2025)

**Major fixes completed:**
1. ✅ Fixed alert tracking to use position WITHOUT active player color
2. ✅ Human vs AI: Human gets max 1 alert per unique position
3. ✅ Human vs Human: Each player gets max 1 alert per unique position (2 total)
4. ✅ AI evaluates every threefold occurrence (equality with human's button)
5. ✅ "Claim Draw" button now shows proper ThreefoldDrawResultAlertView
6. ✅ 1-second minimum AI move time implemented system-wide
7. ✅ Spinner overlay shows during AI threefold evaluation (with "Evaluating draw claim..." text)
8. ✅ AI evaluation is "on the clock" (timer keeps running during AI's thinking)
9. ✅ Removed temporary AI override code

### CRITICAL BUG STILL UNRESOLVED

**Symptom:** Duplicate threefold alerts appearing
- First alert appears instantly with brief spinner flash
- User taps OK, returns to board
- 3-5 seconds later, second identical alert appears (no spinner during wait)

**Root Cause:** TWO concurrent calls to `handleAIThreefoldRepetition()` within microseconds
- Console log evidence from iPhone 17 Pro Simulator:
  ```
  2025-10-30 13:43:22.765707 handleAIThreefoldRepetition() started
  2025-10-30 13:43:22.765792 handleAIThreefoldRepetition() started (85 microseconds later!)
  ```
- First evaluation completes in 167ms → shows first alert
- Second evaluation completes 20 seconds later → shows duplicate alert
- Both evaluations appear to run to completion despite guards

**Attempted Fix (FAILED):** Added guard checking `!game.evaluatingThreefoldClaim`
- Guard placed at line 1095 in ChessBoardView.swift
- Flag set at line 1103 BEFORE Task starts
- Guard still not preventing second concurrent call from proceeding
- Second call likely slipping through before flag gets set (race condition at Task boundary)

## Code Changes Made (Sessions 31-32)

### Session 31 Changes (Board Flip)
**ChessBoardView.swift:**
- Restructured layout to separate board rotation from coordinate labels
- Fixed coordinate system so labels stay on LEFT and BOTTOM edges always

### Session 32 Changes (Threefold Repetition)

**ChessGame.swift (Model):**
1. ✅ Added `evaluatingThreefoldClaim: Bool` - @Published flag for spinner and concurrent guard
2. ✅ Created `generateAlertTrackingKey()` - position key WITHOUT active player color (lines 990-1043)
3. ✅ Updated `checkThreefoldRepetition()` - opponent type checking for alert limits (lines 1045-1097)
4. ✅ Updated `handleAIThreefoldRepetition()` - spinner control with MainActor (lines 1134-1201)
5. ✅ Removed temporary AI override code (clean)

**Key insight on alert tracking:**
- Alert tracking uses position WITHOUT active player (generateAlertTrackingKey)
- Each UNIQUE board snapshot gets its own alert counter
- Position 1 (Queen f7/King h8) and Position 2 (Queen f8/King h7) are DIFFERENT positions
- Each gets its own 1-alert limit (Human vs AI) or 2-alert limit (Human vs Human)

**ChessBoardView.swift (View):**
1. ✅ Added spinner overlay for AI threefold evaluation (lines 478-496)
2. ✅ Added `.onChange(of: game.threefoldDrawClaimed)` watcher for "Claim Draw" button (lines 221-226)
3. ✅ Updated `triggerAIMove()` with 1-second minimum timing (lines 967-991)
4. ✅ Updated threefold handling to keep timer running during AI evaluation (lines 1092-1136)
5. ✅ Added concurrent evaluation guard at line 1095 (FAILED to prevent duplicates)
6. ✅ Set `evaluatingThreefoldClaim = true` at line 1103 BEFORE Task starts (STILL FAILING)

**QuickGameMenuView.swift:**
1. ✅ Updated "Claim Draw" button comment to clarify it shows ThreefoldDrawResultAlertView (line 145)

**Code Cleanup (Session 32):**
1. ✅ Removed temporary AI override code that was returning early
2. ✅ Fixed Character to String conversion in generateAlertTrackingKey
3. ✅ Added explicit return statements to avoid unreachable code warnings

## Known Issues (Session 32)

### CRITICAL BUG - Concurrent Threefold Evaluations
**Status:** UNRESOLVED after Session 32 (out of session resources)

**Problem:** Two concurrent evaluations happen within 85 microseconds
- checkGameEnd() being called twice in rapid succession
- Both calls enter AI threefold evaluation block
- Guard checking `!game.evaluatingThreefoldClaim` not preventing second call
- Second call completes 20 seconds after first, shows duplicate alert

**Why guards are failing:**
- Flag is set BEFORE Task starts (line 1103)
- But both calls check the guard (line 1095) before either sets the flag
- Race condition at synchronous/asynchronous boundary
- Need different approach - perhaps single-use flag or debouncing

### User Concerns About Code Quality

**User is VERY worried about "house of cards" code:**
- Multiple debugging iterations leaving dangling code
- Potentially unused variables or incomplete cleanup
- Guards that may be redundant or incorrectly placed
- Overall code stability from extended debugging sessions

**Post-completion audit required:**
- Search for all `threefold*` references
- Verify no dead code remains
- Check for redundant guards
- Remove all debug NSLog statements
- Document final architecture

## Working Correctly (Session 32)

### ✅ Alert Tracking System
- generateAlertTrackingKey() excludes active player color
- Each unique board snapshot gets separate alert counter
- Human vs AI: 1 alert per position
- Human vs Human: 2 alerts per position (one per player)
- Alert limits respected correctly

### ✅ UI Components Working
- "Claim Draw" button shows ThreefoldDrawResultAlertView correctly
- Spinner overlay displays (but too briefly due to concurrent bug)
- "Evaluating draw claim..." text shows
- All alerts styled properly with custom overlays

### ✅ Chess Logic Working
- Position key generation (pieces + castling + en passant)
- Threefold detection (3+ repetitions)
- AI decision logic (skill-aware thresholds)
- AI evaluates every threefold (equality with human button)
- Human gets alert with "Continue Playing" / "Claim Draw" choice

### ✅ Timer Management
- 1-second minimum AI move time implemented system-wide
- AI threefold evaluation is "on the clock" (timer keeps running)
- Timer stops only if AI claims draw, not during evaluation

## Testing Scenario

**FEN String:** `5Q2/7k/8/5PPP/8/8/8/6K1 w - - 0 0`
- Black king can only move h8↔h7
- White queen moves f8↔f7
- Repeats quickly for threefold testing

**Move sequence that triggers threefold:**
1. f8f7 h7h8
2. f7f8 h8h7
3. f8f7 h7h8
4. f7f8 h8h7
5. f8f7 h7h8 ← **3rd repetition, alert triggers**

**Expected behavior:**
1. White moves Qf7 → 3rd repetition
2. Threefold alert shows
3. **AI should NOT move until alert dismissed**
4. User clicks "Continue Playing"
5. THEN AI moves

**Actual behavior:**
1. White moves Qf7 → 3rd repetition
2. Threefold alert shows
3. **AI immediately moves (visible through alert)** ❌
4. Alert still showing after AI moved

## Next Session TODO (Session 33)

### PRIORITY 1: Fix Concurrent Evaluation Bug

**Investigate root cause:**
1. Why is checkGameEnd() being called twice within 85 microseconds?
2. Add NSLog at checkGameEnd() entry to see call frequency
3. Identify which code paths trigger the duplicate calls

**Possible solutions to try:**
1. **Debouncing**: Ignore checkGameEnd() calls within 100ms of last call
2. **Actor isolation**: Move threefold evaluation to @MainActor isolated function
3. **Single-use flag**: Use boolean that gets set permanently until game state changes
4. **Early return**: Check threefoldAlertShowing at checkGameEnd() entry (before threefold check)
5. **Task cancellation**: Cancel any existing threefold evaluation Task before starting new one

### PRIORITY 2: Code Audit (Once Bug Fixed)

**Cleanup tasks:**
1. Remove ALL debug NSLog statements
2. Search for all `threefold*` references - verify each is necessary
3. Verify no unused variables (evaluatingThreefoldClaim used for both spinner and guard)
4. Check for redundant guards
5. Document final architecture in comments

### PRIORITY 3: Full System Testing

**Test scenarios:**
- Human vs Human (both players get alerts for same position)
- Human vs AI (human gets 1 alert, AI evaluates every time)
- "Claim Draw" button (shows ThreefoldDrawResultAlertView)
- State clearing on New Game/Setup Board/Undo
- Multiple unique threefold positions in same game

### PRIORITY 4: Return to SESSION_START.md Agenda

Once threefold is complete, verified, and audited, return to planned features.

## Files Modified (Sessions 31-32)

**Session 31 - Board Flip Fix:**
1. `ChessBoardView.swift` - Coordinate system restructure (complete)

**Session 32 - Threefold Repetition:**
2. `ChessGame.swift` - Added evaluatingThreefoldClaim flag, generateAlertTrackingKey(), updated checkThreefoldRepetition() with opponent type checking, updated handleAIThreefoldRepetition() with spinner control
3. `ChessBoardView.swift` - Added spinner overlay, onChange watcher for Claim Draw, 1-second minimum AI timing, concurrent evaluation guard (FAILING)
4. `QuickGameMenuView.swift` - Updated comment for Claim Draw button

**Documentation (Sessions 31-32):**
5. `THREEFOLD_STATUS.md` - This file (updated with Session 32 progress and remaining bug)

## Session Resource Warning

**Session 31:** ~3% remaining after board flip fix and initial threefold work
**Session 32:** ~9% remaining after extensive threefold debugging

Sessions 31-32 consumed significantly more resources than expected due to:
1. ✅ Board flip coordinate fix (completed Session 31)
2. 🔴 Threefold repetition concurrent evaluation bug (still unresolved after Session 32)
3. 🔴 Multiple failed approaches to guard concurrent async Tasks
4. 🔴 User frustration with premature coding and "house of cards" concerns

**Status:** Feature ~95% complete but blocked by critical concurrent evaluation bug.
Will export conversation and resume Session 33.

---

## SESSION_START.md Context

Threefold repetition was the #1 priority in SESSION_START.md (Session 27 agenda).

**Other SESSION_START.md priorities still pending:**
- File Management Features (auto-save, import FEN/PGN, share)
- Opening Library Integration
- Game Statistics Display
- Online Opponents (Lichess/Chess.com)

**Once threefold is complete and audited**, return to SESSION_START.md agenda.

---

## Summary for Next Session (Session 33)

**What works:**
- Alert tracking per unique position (excludes active player)
- Human vs AI alert limits (1 per position)
- Human vs Human alert limits (2 per position)
- AI evaluates every threefold (equality with human)
- Spinner overlay displays
- Timer runs during AI evaluation
- 1-second minimum AI move time

**What's broken:**
- Two concurrent evaluations within 85 microseconds
- Guard not preventing second evaluation
- Duplicate alert after 20 seconds
- Spinner appears too briefly (first eval completes in 167ms)

**Next steps:**
1. Investigate why checkGameEnd() called twice
2. Try debouncing or other concurrency control
3. Remove all debug NSLog statements
4. Comprehensive code audit
5. Full system testing

**CRITICAL:** Feature ~95% complete but blocked by concurrent evaluation bug. Must resolve before moving to other SESSION_START.md priorities.


  ## USER NOTE: Post-Fix Code Audit Requirement
    After a multi-session debugging marathon like this, a comprehensive code audit is mandatory, not optional. Here's
  why:

  Evidence from Session 32 alone:
  - Temporary override code that needed removal
  - Character to String conversion bug (dangling from earlier attempt)
  - Multiple guard attempts that didn't work but might still be in code
  - Debug NSLog statements throughout multiple files
  - Flag variables added for different approaches

  What the audit needs to find:
  1. Unused variables - Did we add flags that aren't being used anymore?
  2. Redundant guards - Multiple guard attempts, are all still needed?
  3. Dead code paths - Logic that never executes
  4. Debug logging - All NSLog statements that need removal
  5. Commented-out code - Failed approaches we left behind
  6. Inconsistent patterns - Where we tried different approaches in different places

  Audit timing:
  - AFTER the concurrent bug is fixed and tested
  - BEFORE marking threefold complete
  - BEFORE moving to next SESSION_START.md feature

  Suggested audit process:
  1. Search entire codebase for "threefold" - review every reference
  2. Search for "NSLog" - remove all debug statements
  3. Review ChessGame.swift properties - verify each is used
  4. Review ChessBoardView.swift guards - verify each is necessary
  5. Build with zero warnings
  6. Run comprehensive tests

  Your "house of cards" concern is 100% valid after this kind of extended debugging. The audit will restore
  confidence in code quality.
