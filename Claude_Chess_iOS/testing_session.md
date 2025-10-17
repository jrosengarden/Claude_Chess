The following issues/bugs were discovered during some serious testing/debugging time 
after our last Claude session ended:

### Receiving the following messages in the Debug Console when running the App on the
iPhone 14 Pro (Physical device).  
This might be relevant info: When starting the app from xCode it takes forever for the
App to load and then once the app loads it doesn't take any input for quite some time.
Eventually it does take input and then these are the messages I'm seeing in the Debug
Console.  NOTE:  This is not occuring from any of the Simulators.
This seems to only be happening when tapping on any of the mainview menus (QuickMenu,
GameMenu)

Requesting visual style in an implementation that has disabled it, returning nil. Behavior of caller is undefined.
Type: Error | Timestamp: 2025-10-17 11:01:23.249653-05:00 | Process: Claude_Chess | Library: UIKitCore | Subsystem: com.apple.UIKit | Category: Assert | TID: 0x178d9c
Requesting visual style in an implementation that has disabled it, returning nil. Behavior of caller is undefined.
Type: Error | Timestamp: 2025-10-17 11:01:23.249876-05:00 | Process: Claude_Chess | Library: UIKitCore | Subsystem: com.apple.UIKit | Category: Assert | TID: 0x178d9c
Requesting visual style in an implementation that has disabled it, returning nil. Behavior of caller is undefined.
Type: Error | Timestamp: 2025-10-17 11:01:23.250749-05:00 | Process: Claude_Chess | Library: UIKitCore | Subsystem: com.apple.UIKit | Category: Assert | TID: 0x178d9c
Requesting visual style in an implementation that has disabled it, returning nil. Behavior of caller is undefined.
Type: Error | Timestamp: 2025-10-17 11:01:23.250813-05:00 | Process: Claude_Chess | Library: UIKitCore | Subsystem: com.apple.UIKit | Category: Assert | TID: 0x178d9c
Requesting visual style in an implementation that has disabled it, returning nil. Behavior of caller is undefined.
Type: Error | Timestamp: 2025-10-17 11:01:23.251924-05:00 | Process: Claude_Chess | Library: UIKitCore | Subsystem: com.apple.UIKit | Category: Assert | TID: 0x178d9c
0.5
Type: stdio
Potential Structural Swift Concurrency Issue: unsafeForcedSync called from Swift Concurrent context.
Type: Fault | Timestamp: 2025-10-17 11:02:15.422245-05:00 | Process: Claude_Chess | Library: AXCoreUtilities | Subsystem: com.apple.Accessibility | Category: AXCommon | TID: 0x178f38

#### The following issues all point to serious, serious, serious, flaws when playing
using the Stockfish AI:

### When using Stockfish AI at level 0
 the human is allowed to make move for Black when it's Black's turn

### When using Stockfish AI at Level 0
after White's 1st move (E2E4) and then Stockfish's (Black)
response the next move for White (whatever that move might be) it seems the Stockfish
engine is making a 2nd move, immediately, for White so White made 2 moves on it's turn
(not occuring on a regular basis)  Example Game: 1. e2e4 d7d5 2. e4 x d5 & d2d4 and even
with both of these moves being made for white on it's 2nd turn....it's still White's
turn according to the game.  2nd Example Game:  1. e2e4 e7e6 2. g1f3 & d2d4 and it's still
white's turn.  I then moved b1c3 and the game crashed.  3rd example game:
1. e2e4 e7e5  2. d2d4 and then black forfeited on time after never making a 2nd move
(taking up almost 3 1/2 minutes of its time) 4th example game: 1 e2e4 d7d5 2. e4xd5 and 
then black forfeits on time using up all of it's remaining time (over 3+ minutes) making
no move at all.


### When using Stockfish AI at Level 0
Then using Setup Board with this FEN string:
rnbqk2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R b k - 0 1
It's black's turn with an obvious castle move but White win's due to black forfeiting 
on time (using up it's entire 5 minutes without making ANY move)

## When using Stockfish AI at Level 0
Then using Setup Board with this FEN string:
rnbqk1nr/p7/8/8/8/8/p7/RNBQKBNR b - - 0 1
It's black's turn with an obvious pawn promotion move to make but White win's due to 
black forfeiting on time (using up it's entire 5 minutes without making ANY move)

## Referring to the previous issue:  If the human makes the move for black the pawn
promotion sheet (Choose a piece) is appearing.  Shouldn't the Stockfish engine
automatically decide/pick the promotion piece?

#### The following issues deal with Setup Board problems:

### When using Setup Board when not all pieces remain on the board there are no 
captured pieces showing (or being displayed when tapping "Captured: 0")

### When a game is underway and Setup Board is used then when the user is returned to the
game board (mainview) the timer controls (if active) are still counting down from the
previous game.  Expected behavior: When using Setup board and user selects the "SETUP"
button from the Setup Game Board view, after entering a FEN string,  AND a game is 
underway the user should be prompted to "Save Current Game? Y/N" IF the FEN string is 
valid.  Then either way (Y or N) a new game should
be started with the board showing the FEN position that had been input.  It should
require a "Start Game" from the user to get things moving!!  For right now, since we 
don't have file operations completed (or even started) we can just let the "Save 
Current Game? Y/N" do nothing (as a placeholder) so the rest of the logic can be put in
place and tested.