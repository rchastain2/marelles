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

#include "gamehistory.hh"

#include <assert.h>


void GameHistory::clear()
{
  m_moves.clear();
  m_boards.clear();

  m_boards.push_back(std::make_shared<Board>());
  m_position = 0;
}


Board& GameHistory::appendCopyOfCurrent(const Move& move)
{
  // Whatever had been undone is now replaced by this move.
  m_boards.resize(m_position + 1);
  m_moves.resize(m_position);

  m_moves.push_back(move);
  m_boards.push_back(std::make_shared<Board>(currentBoard()));

  m_position++;

  // Chain to the board before it, so repetitions can be found.
  m_boards[m_position]->setPrevBoard(m_boards[m_position - 1]);

  return currentBoard();
}


void GameHistory::undo()
{
  assert(canUndo());

  m_position--;
}


void GameHistory::redo()
{
  assert(canRedo());

  m_position++;
}
