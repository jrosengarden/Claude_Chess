Testing Session 03 10/18/25

NOTE: This testing session was to confirm everything is working properly after fixing
      the race condition issue AND the depth vs time issue.
      
      
1.  When pasting in this FEN string (Scholars Mate - Checkmate position): 
		r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR b KQkq - 0 4
	The Checkmate alert appeared immediately after being returned to the mainview 
	(game board).  The game had never been started after pasting in the FEN string.
	Shouldn't the Checkmate alert NOT occur until after tapping "Start Game" in the
	Quick menu?
	
2.	When pasting in this FEN string (7k/8/6Q1/8/8/8/8/K7 b - - 0 1) which is a 
	stalemate position the same thing as above is occuring: The Stalemate Alert
	panel is showing before the game has been started.  Shouldn't the Stalemate
	alert NOT occur until after tapping "Start Game" in the Quick menu?
	
3.	When pasting in this FEN string (r3k2r/pppppppp/8/8/8/8/PPPPPPPP/R3K2R w - - 0 1) 
	which is testing Castling rights the Captured: pieces for both White and Black
	are not populated with the pieces missing off the board.  I THINK we had checked
	this once before and you indicated since it's really an illegal board (the pieces)
	in the back rows of White & Black could not have possibly moved, or been captured,
	since ALL the pawns (both black and white) are still in their starting positions.
	
4.	When pasting in this FEN string (8/8/8/4k3/8/8/4P3/4K3 w - - 0 1) the Captured: for
	both sides is properly populated but after White makes it's move (e2e3) the 
	Captured: for both black and white disappear and the count goes to 0 with the
	display of captured pieces showing "No Pieces Captured"
	
	NOTE:  It looks like the above behavior of Captured: pieces when using the
		   SETUP GAME BOARD is always occuring after setting up the board with a 
		   valid FEN string.  THe count, and display, is always correct until the
		   1st move is made (either by black or white) and the count goes to 0 with
		   the display no longer showing any captured pieces.
		   
Testing Per Test Plan:
  Edge Cases:
  -  ✅ Pawn promotion (all 4 pieces: Q/R/B/N, both colors)
  -  ✅ Castling (kingside/queenside, both colors, blocked scenarios)
  -  ✅ En passant capture
  -  ✅ Complex positions (multiple pieces under attack, pins, forks)
  -  ✅ 50-move rule triggering
  
	Game Play:
	Skill Level 0: 1.e2e4 c7c5 2.d2d4 c5xd4 3.d1xd4 d7d6 4.g1f3 b8d7 5.b1c3 e7e5
	Skill Level 5: 1.e2e4 c7c5 2.d2d4 c5xd4 3.d1xd4 g8f6 4.b1c3 d7d6 5.f1b5 c8d7
	Skill Level 10:1.e2e4 c7c5 2.d2d4 c5xd4 3.d1xd4 b8c6 4.d4d3 d7d6 5.b1c3 e7e6
	Skill Level 15:1.e2e4 e7e5 2.g1f3 b8c6  3.d2d4 e5xd4 4.f3d4 f8c5 5.d4b3 c5e7
	Skill Level 20:1.e2e4 c7c5 2.d2d4 c5xd4 3.d1xd4 b8c6 4.d4a4 e7e6 5.g1f3 d8c7
	
	Conclusion On Game Play: AI Engine making subtly different moves at the different
							 levels and seems to be thinking a little more at each
							 successive level.  Also the moves, at higher levels, are
							 more competitive moves (I think!)
							 
	Hint System:
		Requested hint(s) at various times at various skill levels (in the above games).
		The hints were accurate, especially when a White piece was in danger, and
		seemed to be more aggressive at the higher levels.
		
	Conclusion On Hint System: It seems to be working properly, even taking a little
							   more time (the whirlygig spins) at higher levels.
							   
	Position Evaluation:
		Requested the Score (Position Evaluation) at during most of the above games.
		The score (all 3 methods) seemed correct for the current position.  I even
		"cheated" and utilized the Hint system (basically letting the AI Engine play
		against itself) and the score changed appropriately as the game(s) progressed.
		
	Conclusion on Position Evaluation: It seems to be working, and calculating, properly.
	
	Testing after today's major bug fixes complete and gameplay seems to be fully
								functional.
		