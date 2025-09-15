# Chess Feature Demonstrations

This directory contains FEN files that demonstrate various chess rules and tactical concepts. Load any of these files using the `load` command to see the feature in action.

## Basic Chess Rules

### **Castling.fen**
- **Feature**: Castling (both kingside and queenside)
- **Setup**: King and rooks in starting positions with castling rights
- **Try**: `e1 g1` (kingside) or `e1 c1` (queenside)

### **EnPassant.fen**
- **Feature**: En passant capture
- **Setup**: White pawn on e5, Black just moved f7-f5
- **Try**: `e5 f6` to capture en passant

### **Promotion.fen**
- **Feature**: Pawn promotion
- **Setup**: White pawn on e7 ready to promote
- **Try**: `e7 e8` and choose your promotion piece (Q/R/B/N)

## Game Endings

### **Checkmate.fen**
- **Feature**: Checkmate in 1 move
- **Setup**: Back rank mate position
- **Try**: `a1 a8` for checkmate

### **Check.fen**
- **Feature**: Giving check
- **Setup**: Position after 1.e4 f6 (f7 pawn moved to f6, clearing diagonal)
- **Try**: `d1 h5` to give check to the Black king

### **Stalemate.fen**
- **Feature**: Stalemate (draw)
- **Setup**: Position where White can force stalemate
ba- **Try**: `b3 b1` to force stalemate (Black king has no legal moves)

### **FiftyMoveRule.fen**
- **Feature**: 50-move rule approach
- **Setup**: King vs King endgame near 50-move limit
- **Note**: Halfmove clock is at 98 (2 moves from draw)

## Tactical Concepts

### **Fork.fen**
- **Feature**: Knight fork (already in place)
- **Setup**: White knight on d5 forking Black queen on c7 and Black rook on f6
- **Try**: `d5 c7` or `d5 f6` to capture one of the forked pieces

### **Pin.fen**
- **Feature**: Pin tactic (already in place)
- **Setup**: White bishop on b5 pins Black pawn on d7 to Black king on e8
- **Note**: Black pawn on d7 cannot move due to pin - would expose king to check

### **Discovery.fen**
- **Feature**: Discovered attack
- **Setup**: White queen on e2 and knight on e3 blocking the file to Black king on e8 (e7 pawn removed)
- **Try**: Move knight from e3 (e.g., `e3 f5`) to discover queen attack on Black king

### **Sacrifice.fen**
- **Feature**: Tactical sacrifice
- **Setup**: Italian Game with tactical opportunity
- **Try**: Look for sacrificial attacks on f7

### **BackRank.fen**
- **Feature**: Back rank weakness
- **Setup**: Exposed king on back rank
- **Try**: `e1 e8` to exploit back rank weakness

## How to Use These Demonstrations

1. Start the chess program
2. Type `load` to see available files
3. Select any demonstration file using arrow keys
4. Press ENTER to load the position
5. Try the suggested moves to see the feature in action
6. Use `undo` to experiment with different moves

## Learning Tips

- **Study the positions** before making moves
- **Use the hint command** to see what the AI suggests
- **Try alternative moves** to understand why the demonstrated move is strong
- **Use undo freely** to experiment without consequence

These demonstrations showcase the complete chess rule implementation including all special moves, tactical patterns, and endgame concepts supported by the chess engine.