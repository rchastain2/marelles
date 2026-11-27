/***************************************************************************
  This file is part of Morris.
  Copyright (C) 2026 Dirk Farin <dirk.farin@gmail.com>

  Morris is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************************************************************/

#ifndef GAMEHISTORY_HH
#define GAMEHISTORY_HH

#include "board.hh"

#include <memory>
#include <vector>


/* The boards a game has passed through, the moves between them, and where in
   that line we currently stand. Undo and redo only move the current position;
   the boards ahead of it are kept until a new move replaces them.

   There is always at least one board, so currentBoard() is always valid.
   Each board is chained to the one before it, which is how the rules detect
   a draw by repetition.
*/
class GameHistory
{
public:
  GameHistory() { clear(); }

  // Back to a single, empty board at position zero.
  void clear();

  /* Appends a copy of the current board, reached by the given move, and makes
     it current. Anything that had been undone is discarded. The returned
     board is the copy, on which the caller then performs the move. */
  Board& appendCopyOfCurrent(const Move& move);

  // --- moving through the line ---

  bool canUndo() const { return m_position > 0; }
  bool canRedo() const { return m_position + 1 < int(m_boards.size()); }

  void undo();
  void redo();

  // --- looking at it ---

  int  position() const { return m_position; }
  int  size() const     { return int(m_boards.size()); }

  Move                   move(int ply) const  { return m_moves[ply]; }
  std::shared_ptr<Board> board(int ply) const { return m_boards[ply]; }

  /* */ Board& currentBoard()       { return *m_boards[m_position]; }
  const Board& currentBoard() const { return *m_boards[m_position]; }

private:
  std::vector<Move>                   m_moves;   // m_moves[i] leads to m_boards[i+1]
  std::vector<std::shared_ptr<Board>> m_boards;
  int                                 m_position = 0;
};

#endif
