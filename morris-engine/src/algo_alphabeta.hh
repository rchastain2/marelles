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

#ifndef ALGO_ALPHABETA_HH
#define ALGO_ALPHABETA_HH

#include "control.hh"
#include "ttable.hh"
#include "learn.hh"

#include <atomic>
#include <chrono>
#include <cstdlib>
#include <iostream>
#include <random>
#include <stop_token>
#include <thread>


/* A quite standard alpha-beta search algo with a quite basic evaluation function.
   Still, it is a quite competitive player.
   Features:
   - use of transposition table
   - PV display
   - learning of good/bad games and avoiding previous bad situations.
 */
class PlayerIF_AlgoAB : public PlayerIF
{
public:
  PlayerIF_AlgoAB();

  /* Stops and joins a running search. ~jthread would join it, but only after
     the members it is still using have been destroyed, and it would signal
     the jthread's own stop token rather than the m_stop this search polls. */
  ~PlayerIF_AlgoAB() override;

  using eval_t = float;
  using Variation = SmallVec<Move, MAXSEARCHDEPTH>;

  // --- configuration ---

  void registerTTable(ttable_ptr tt) { m_ttable=tt; }
  void registerThreadTunnel(ThreadTunnel& tunnel) override { m_tunnel=&tunnel; }
  void registerExperience(experience_ptr e) { m_experience=e; }

  // --- AI parameters ---

  void setMaxTime_msec(int msecs) { m_maxMSecs=msecs; }
  void setMaxDepth(int d) { m_maxDepth=d; }

  int  askMaxTime_msec() const { return m_maxMSecs; }
  int  askMaxDepth() const { return m_maxDepth; }

  enum Weight {
    Weight_Material,
    Weight_Freedom,
    Weight_Mills,
    Weight_Experience,
    Weight_NWEIGHTS
  };

  void  setEvalWeight(Weight w, float val) { m_weight[w] = val; }
  float askEvalWeight(Weight w) const { return m_weight[w]; }

  // --- standard methods ---

  bool isInteractivePlayer() const override { return false; }

  // start a new game
  void resetGame() override;

  void startMove(const Board& curr, int moveID) override;

  // Carry out the move as soon as possible.
  void forceMove() override;

  // Cancel the current move (do not send the currently computed move).
  void cancelMove() override;

  void notifyWinner(Player p, const class GameControl& control) override;

private:
  void doSearch();
  void iterativeDeepening();

  bool stopRequested() const { return m_stop.stop_requested(); }

  float NegaMax(const Board& board,float alpha,float beta,
		int currDepth, int levels_to_go,Variation&, bool useTT);

  float Eval(const Board& board, int levelsToGo) const;


  Board m_startBoard;
  Move  m_move;       // the move that is currently computed

  //PositionMemory m_posMemory;  // TODO: disabled, because not as effective as Experience
  experience_ptr m_experience;

  // multi-threading management

  /* Thrown deep inside NegaMax to abandon the search when the time budget
     runs out or the move is cancelled, and caught in doSearch(). */
  struct SearchAborted { };

  void installJoinThreadHandler();
  void joinThread();

  class ThreadTunnel* m_tunnel;

  /* Reassigning or destroying a jthread stops and joins the old search
     first, so a thread can never be left running behind our back. */
  std::jthread      m_thread;
  std::stop_source  m_stop;

  int  m_moveID;

  /* Written by the GUI thread and read by the search thread (and the other
     way round for m_computedSomeMove), so these must not be plain bools.
     Stopping itself goes through m_stop, which is already race-free. */
  std::atomic<bool> m_ignoreMove;
  std::atomic<bool> m_computedSomeMove;

  // time management

  std::chrono::steady_clock::time_point m_startTime; // when the move was started
  void checkTime();

  // configuration

  ttable_ptr m_ttable;
  int m_maxMSecs;
  int m_maxDepth;
  float m_weight[Weight_NWEIGHTS];

  // Randomises the move order at the root; used only by this player's search thread.
  std::mt19937 m_random;

  // visualization

  void logBestMove(const Variation&, eval_t, int depth, const char* suffix="") const;
  void logBestMove(const Move&, eval_t, int depth) const;
  void logBestMoveFromTable(const Board&, const Move&, eval_t, int depth) const;

  // statistics

  mutable int  m_nodesEvaluated;

  // debug
  int moveCnt;
};

#endif
