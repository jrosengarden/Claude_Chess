# TestFlight Release & Branch Management Guide

## Overview

This document describes the release management strategy for Claude Chess
iOS during the TestFlight beta phase while simultaneously developing
Chess.com and Lichess integrations.

**Created:** October 25, 2025
**Status:** Planning phase - to be implemented at first TestFlight release

## The Challenge

At the point of first TestFlight release, we face competing priorities:

1. **TestFlight users need stability** - Bug fixes, polish, user-requested
   features
2. **Development continues** - Chess.com and Lichess API integrations are
   complex, multi-week efforts
3. **Can't stop everything for bugs** - Need to maintain development
   momentum
4. **Can't ignore users** - Critical bugs must be fixed quickly

## The Solution: Two-Branch Strategy

**Professional release branch workflow** used by real development teams
worldwide.

```
main (development branch)
├─ Chess.com API integration
├─ Lichess API integration
├─ Complex new features
└─ Experimental work

testflight (stable release branch)
├─ Bug fixes from user reports
├─ User-requested features (quick wins)
├─ Polish and refinements
└─ TestFlight Build #1, #2, #3...
```

**Key Principle:** testflight branch is STABLE and PRODUCTION-READY at all
times. main branch is WHERE THE MAGIC HAPPENS.

## Branch Responsibilities

### main Branch
- **Purpose:** Active development, experimentation, major features
- **Quality:** Work-in-progress, may be unstable
- **Commits:** Integration milestones, new features, refactoring
- **Builds:** Developer testing only, NOT for TestFlight
- **Merge Direction:** Receives fixes FROM testflight periodically

### testflight Branch
- **Purpose:** Stable builds for TestFlight beta users
- **Quality:** Production-ready, thoroughly tested
- **Commits:** Bug fixes, polish, quick user-requested features
- **Builds:** ALL TestFlight releases come from this branch
- **Merge Direction:** Sends fixes TO main periodically

## Initial Setup (At First TestFlight Release)

**Timing:** When app is feature-complete for first beta (before
Chess.com/Lichess work begins)

**Prerequisites:**
- All planned features complete (except Chess.com/Lichess)
- Thorough testing on all devices
- User Guide updated
- Ready for external users

**Git Commands:**
```bash
# Ensure you're on main with latest code
git checkout main
git pull

# Create testflight branch from current main
git checkout -b testflight

# Push testflight branch to remote
git push -u origin testflight

# Verify both branches exist
git branch -a
# Should show:
#   main
# * testflight
#   remotes/origin/main
#   remotes/origin/testflight

# Switch back to main for development
git checkout main
```

**Result:** You now have two independent branches that can evolve separately.

## Common Workflows

### Workflow 1: Fixing a Bug Reported by TestFlight User

**Scenario:** User reports crash when offering draw with time controls
disabled

**Steps:**
```bash
# 1. Switch to testflight branch
git checkout testflight

# 2. Claude fixes the bug in ChessGame.swift
# (Edit files, test fix)

# 3. Commit the fix
git add .
git commit -m "Fix: Draw offer crash when time controls disabled"

# 4. Push to remote
git push

# 5. Build and upload to TestFlight from Xcode
# (App Store Connect will build from testflight branch)

# 6. Switch back to main for integration work
git checkout main
```

**Key Points:**
- Fix goes to testflight branch ONLY (for now)
- Users get the fix in next TestFlight build
- main branch continues integration work uninterrupted
- Will merge fix to main later (see Workflow 4)

### Workflow 2: User-Requested Feature (Quick Win)

**Scenario:** Multiple users request "Larger piece size option" in Settings

**Decision:** Is this quick (1 session) or complex (multi-session)?

**If Quick → Add to testflight:**
```bash
git checkout testflight
# Claude implements piece size slider in Settings
git add .
git commit -m "Feature: Adjustable piece size in Settings"
git push
# Build and upload to TestFlight
git checkout main
```

**If Complex → Add to main (after integrations):**
- Note in backlog
- Implement in main branch later
- Will reach TestFlight in next major release

**Rule of Thumb:** If it takes 1 session or less → testflight. If longer
→ main (after integrations).

### Workflow 3: Chess.com/Lichess Integration Work (main branch)

**Scenario:** Working on Chess.com API authentication system

**Steps:**
```bash
# Ensure you're on main
git checkout main

# Claude implements Chess.com OAuth flow
# Multiple sessions, complex code
# May be unstable, experimental

# Commit integration milestone
git add .
git commit -m "Chess.com: OAuth authentication flow complete"
git push

# Stay on main for continued integration work
```

**Key Points:**
- ALL integration work happens on main
- Don't worry about TestFlight users - they're on separate branch
- Can break things, experiment, refactor freely
- TestFlight branch remains stable

### Workflow 4: Merging testflight Fixes to main

**Timing:** Weekly or bi-weekly, OR when significant bugs fixed

**Purpose:** Keep main branch up-to-date with production bug fixes

**Steps:**
```bash
# 1. Ensure testflight is committed and pushed
git checkout testflight
git status  # Should be clean
git push

# 2. Switch to main
git checkout main

# 3. Merge testflight into main
git merge testflight

# 4. If conflicts occur, resolve them
# (See Conflict Resolution section below)

# 5. Test that merge didn't break anything
# Build in Xcode, run basic tests

# 6. Push merged main
git push
```

**When to Merge:**
- After fixing 3+ bugs on testflight
- Before starting major new feature on main
- Weekly maintenance (keeps branches from diverging too much)

### Workflow 5: Releasing Integration Work to TestFlight

**Scenario:** Chess.com and Lichess integrations are DONE and tested

**Steps:**
```bash
# 1. Ensure main is stable and tested
git checkout main
# Thorough testing of integrations

# 2. Merge main INTO testflight
git checkout testflight
git merge main

# 3. Resolve any conflicts carefully
# Integration code takes precedence

# 4. Test THOROUGHLY on testflight branch
# This is going to users!

# 5. Push testflight
git push

# 6. Build and upload to TestFlight
# Users get new major version

# 7. Continue development on main
git checkout main
```

## Git Commands Quick Reference

### Branch Operations
```bash
# See all branches
git branch -a

# Switch branches
git checkout main
git checkout testflight

# Create new branch
git checkout -b branch-name

# Delete branch (use with caution!)
git branch -d branch-name
```

### Checking Status
```bash
# What branch am I on?
git branch

# What's changed?
git status

# What's the difference between branches?
git diff main testflight
```

### Merging
```bash
# Merge testflight INTO main
git checkout main
git merge testflight

# Merge main INTO testflight
git checkout testflight
git merge main
```

### Undoing Mistakes
```bash
# Undo last commit (keeps changes)
git reset --soft HEAD~1

# Discard all uncommitted changes
git reset --hard

# Abort a merge in progress
git merge --abort
```

## Conflict Resolution Strategy

### When Conflicts Happen

**Common scenario:**
- testflight: Fixed bug in `ChessGame.swift` line 150
- main: Added Chess.com code in `ChessGame.swift` line 145
- Git can't auto-merge

**What you'll see:**
```bash
git merge testflight
Auto-merging ChessGame.swift
CONFLICT (content): Merge conflict in ChessGame.swift
Automatic merge failed; fix conflicts and then commit the result.
```

### Resolution Steps

**1. Open conflicted file in Xcode**

You'll see conflict markers:
```swift
<<<<<<< HEAD
// Chess.com integration code
func connectToChessCom() {
    // ...
}
=======
// Bug fix from testflight
func offerDraw() {
    // Fixed version
}
>>>>>>> testflight
```

**2. Decide what to keep**

Usually: Keep BOTH changes
- Remove conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`)
- Keep both the integration code AND the bug fix
- Test that both work together

**3. Mark as resolved**
```bash
git add ChessGame.swift
git commit -m "Merge testflight: Resolved conflicts in ChessGame"
git push
```

### Cherry-Pick Alternative

If merging is too painful, cherry-pick specific commits instead:

```bash
# On testflight, you fixed a critical bug
git commit -m "Fix: time forfeit crash"
# Note the commit hash: abc123

# Switch to main
git checkout main

# Bring JUST that commit to main
git cherry-pick abc123

# No full merge, no other conflicts
git push
```

**When to use:**
- Merging causes too many conflicts
- Only need 1-2 specific fixes in main
- Branches have diverged significantly

## TestFlight Build Process

**Note:** This section will be filled in when we do the first TestFlight
submission together.

**Placeholder steps:**
1. Ensure testflight branch is clean and tested
2. Archive in Xcode from testflight branch
3. Upload to App Store Connect
4. Configure TestFlight settings
5. Add beta testers
6. Submit for beta review
7. Distribute to testers

**To be documented:** Detailed walkthrough with screenshots and common
issues.

## App Store Submission Process

**Note:** This section will be filled in when we do the first App Store
submission.

**Placeholder steps:**
1. Final testing on testflight branch
2. Update version number and build number
3. Prepare App Store assets (screenshots, description, keywords)
4. Submit for App Store review
5. Handle review feedback
6. Release to App Store

**To be documented:** Complete submission checklist and requirements.

## Decision Matrix: Which Branch?

| Scenario | Branch | Why |
|----------|--------|-----|
| Critical crash reported by user | testflight | Urgent, affects production users |
| User requests small feature (<1 session) | testflight | Quick win, improves user experience |
| User requests complex feature (>1 session) | Backlog → main later | Don't interrupt integration work |
| Chess.com integration work | main | Complex, experimental, multi-week |
| Lichess integration work | main | Complex, experimental, multi-week |
| Bug found during integration work | main (fix), testflight (cherry-pick if critical) | Fix where found, propagate if needed |
| Refactoring existing code | main | Could be destabilizing, test thoroughly first |
| UI polish (colors, fonts, etc.) | testflight if minor, main if major redesign | Depends on scope |

## Best Practices

### 1. Commit Messages
**testflight branch:**
- `Fix: [bug description]` - Bug fixes
- `Feature: [user request]` - User-requested features
- `Polish: [improvement]` - UI/UX refinements

**main branch:**
- `Chess.com: [milestone]` - Chess.com integration work
- `Lichess: [milestone]` - Lichess integration work
- `Refactor: [description]` - Code improvements

### 2. Testing Before Push
**testflight branch - CRITICAL:**
- ✅ Test on iPhone Simulator
- ✅ Test on iPad Simulator
- ✅ Test on physical device if possible
- ✅ Verify fix doesn't break other features
- ✅ Check that change matches user request

**main branch - NORMAL:**
- ✅ Test that code compiles
- ✅ Basic functionality verification
- ✅ Deep testing before merging to testflight

### 3. Merge Frequency
**testflight → main:**
- Weekly or bi-weekly
- After significant bug fixes
- Keeps main branch current

**main → testflight:**
- Only when integration work is COMPLETE and TESTED
- Major version updates
- Don't rush this!

### 4. Communication
**TestFlight Release Notes:**
```
Version 1.1 (Build 5)
- Fixed crash when offering draw with time controls disabled
- Added adjustable piece size in Settings
- Improved evaluation display performance

Known Issues:
- Chess.com integration in development (coming soon!)
```

## Lessons Learned

**This section will be updated as we gain experience with the two-branch
workflow.**

### What Worked Well
(To be filled in after first few TestFlight releases)

### What Was Challenging
(To be filled in after first few TestFlight releases)

### What We'd Do Differently
(To be filled in after first few TestFlight releases)

## Resources

- [Git Branching Best Practices](https://git-scm.com/book/en/v2/Git-Branching-Branching-Workflows)
- [App Store Connect Documentation](https://developer.apple.com/app-store-connect/)
- [TestFlight Beta Testing Guide](https://developer.apple.com/testflight/)

---

**Next Steps:**
1. Complete remaining features before first TestFlight release
2. Create testflight branch at release point
3. Submit to TestFlight (document process here)
4. Continue Chess.com/Lichess work on main branch
5. Update this document with lessons learned

---

*This is a living document - update it as we learn and adapt our workflow.*
