/***************************************************************************
  This file is part of Morris.
  Copyright (C) 2009 Dirk Farin <dirk.farin@gmail.com>

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

#ifndef LEARN_HH
#define LEARN_HH

#include "board.hh"
#include <memory>


class Experience
{
public:
  enum { SIGNIFICANT_BITS=8 };

  Experience()  = default;

  void reset()
  {
    for (std::vector<MemEntry>& list : memory)
      list.clear();
  }

  void addBoard(BoardID b, Player winner)
  {
    int list = b & ((1<<SIGNIFICANT_BITS)-1);
    float offset = (winner==PL_White ? 1.0 : -1.0);

    for (MemEntry& entry : memory[list])
      {
	if (entry.id == b)
	  {
	    entry.offset += offset;
	    return;
	  }
      }

    MemEntry mem;
    mem.id = b;
    mem.offset = offset;
    memory[list].push_back(mem);
    nEntries++;
  }

  float getOffset(BoardID b, Player self) const
  {
    int list = b & ((1<<SIGNIFICANT_BITS)-1);
    for (const MemEntry& entry : memory[list])
      {
	if (entry.id == b)
	  {
	    return entry.offset * (self==PL_White ? 1 : -1);
	  }
      }

    return 0.0;
  }

private:
  struct MemEntry
  {
    BoardHash id;
    float offset;
  };

  std::vector<MemEntry> memory[1<<SIGNIFICANT_BITS];
  int nEntries = 0;
};

using experience_ptr = std::shared_ptr<Experience>;


// ---------------------------------------------------------------------------

class PositionMemory
{
public:
  enum { SIGNIFICANT_BITS=12 };

  PositionMemory() { nEntries=0; }

  void storeBoard(const Board& b, float e)
  {
    return;

    int list = b.getHash() & ((1<<SIGNIFICANT_BITS)-1);
    for (const MemEntry& entry : memory[list])
      {
	if (entry.hash == b.getHash())
	  {
	    return;
	  }
      }

    MemEntry mem;
    mem.hash = b.getHash();
    mem.e = e;
    memory[list].push_back(mem);
    nEntries++;

    //std::cout << "position memory entries: " << nEntries << "\n";
  }

  float lookupHash(const Board& b) const
  {
    return 0.0;

    BoardHash hash=b.getHash();

    int list = b.getHash() & ((1<<SIGNIFICANT_BITS)-1);
    for (const MemEntry& entry : memory[list])
      {
	if (entry.hash == b.getHash())
	  {
	    return entry.e;
	  }
      }

    return 0.0;
  }

private:
  struct MemEntry
  {
    BoardHash hash;
    float e;
  };

  std::vector<MemEntry> memory[1<<SIGNIFICANT_BITS];
  int nEntries;
};

#endif
