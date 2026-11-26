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

#include "algo_alphabeta.hh"
#include <memory>
#include "ttable.hh"
#include "threadtunnel.hh"
#include "util.hh"

#include <cstdlib>
#include <iostream>
#include <sstream>
#include <sys/time.h>
#include <cmath>


#define RANDOMIZE true
#define LOGSEARCH false
#define ALGOTRACE 0

const PlayerIF_AlgoAB::eval_t EVAL_INFTY=10000;
const PlayerIF_AlgoAB::eval_t EVAL_WIN  = 9000;


inline void addPly(PlayerIF_AlgoAB::eval_t& e)
{
  /**/ if (e> EVAL_WIN) e--;
  else if (e<-EVAL_WIN) e++;
}

inline void subPly(PlayerIF_AlgoAB::eval_t& e)
{
  /**/ if (e> EVAL_WIN) e++;
  else if (e<-EVAL_WIN) e--;
}

int nPlysUntilEnd(PlayerIF_AlgoAB::eval_t e)
{
  e=fabs(e);
  return EVAL_INFTY-e;
}

// Milliseconds elapsed since the given point on the monotonic clock.
static int elapsedMS(std::chrono::steady_clock::time_point since)
{
  const std::chrono::steady_clock::duration d = std::chrono::steady_clock::now() - since;
  return int(std::chrono::duration_cast<std::chrono::milliseconds>(d).count());
}


PlayerIF_AlgoAB::PlayerIF_AlgoAB()
  : m_tunnel(nullptr),
    m_random(std::random_device{}())
{
  moveCnt=0;

  m_maxMSecs = 1000;
  m_maxDepth = 25;

  m_weight[Weight_Material] = 1.0;
  m_weight[Weight_Freedom]  = 0.2;
  m_weight[Weight_Mills]    = 0.8;
  m_weight[Weight_Experience] = 1.0;
}


PlayerIF_AlgoAB::~PlayerIF_AlgoAB()
{
  m_stop.request_stop();
  joinThread();
}


void PlayerIF_AlgoAB::resetGame()
{
 /* We have to clear the t-table to prevent that
    the computer always plays the same game. */

  m_ttable->clear();
}


void PlayerIF_AlgoAB::startMove(const Board& curr, int moveID)
{
  /*
  std::cout << "-------------------- ";
  if (curr.getCurrentPlayer()==PL_White) std::cout << "white";
  else std::cout << "black";
  std::cout << " (ply=" << curr.getPly() << ")\n";
  */

  moveCnt++;

  /* Every caller cancels a running search first, but make sure of it here:
     the search thread reads m_stop, so it must be gone before we replace it. */
  m_stop.request_stop();
  joinThread();

  m_ignoreMove=false;
  m_computedSomeMove=false;

  m_startBoard = curr;
  m_moveID = moveID;

  m_stop = std::stop_source();
  m_thread = std::jthread([this]() { doSearch(); });
}


// kicker
void PlayerIF_AlgoAB::doSearch()
{
  m_startTime = std::chrono::steady_clock::now();

  m_move.reset();
  m_ttable->resetStats();

  try
    {
      iterativeDeepening();
    }
  catch (const SearchAborted&)
    {
      /* Out of time, or cancelled: m_move holds the best move found so far. */
    }

  if (!m_ignoreMove) { m_tunnel->doMove(m_move, m_moveID); }

  installJoinThreadHandler();
}


/* Search to increasing depth until the time budget runs out (NegaMax then
   throws SearchAborted) or a forced win is found. */
void PlayerIF_AlgoAB::iterativeDeepening()
{
  float e;

  for (int depth=1; depth<=m_maxDepth;depth++)
    {
      m_nodesEvaluated=0;

      Variation var;
      e = NegaMax(m_startBoard, -EVAL_INFTY, EVAL_INFTY, 0, depth, var, true);

      // normalize evaluation for white
      if (m_startBoard.getCurrentPlayer()==PL_Black) { e = -e; }

      if (LOGSEARCH)
	std::cout << "STEP move " << m_move << " depth " << depth << " -> eval=" << e
		  << " nodes evaluated= " << m_nodesEvaluated
		  << "\n";

      if (fabs(e) >= EVAL_WIN)
	{
	  int overInPlys = nPlysUntilEnd(e);

	  if (overInPlys <= depth+1)
	    {
	      // we won't find a better winning line
	      break;
	    }
	}
    }
}


void PlayerIF_AlgoAB::installJoinThreadHandler()
{
  class IdleFunc_JoinAlgoThread : public IdleFunc
  {
  public:
    IdleFunc_JoinAlgoThread(PlayerIF_AlgoAB* algo) : obj(algo) { }

    void operator()() override { obj->joinThread(); }

  private:
    PlayerIF_AlgoAB* obj;
  };

  IdleFunc::install(new IdleFunc_JoinAlgoThread(this));
}


void PlayerIF_AlgoAB::forceMove()
{
  m_stop.request_stop();
}

void PlayerIF_AlgoAB::cancelMove()
{
  m_ignoreMove=true;
  m_stop.request_stop();

  joinThread();
}

void PlayerIF_AlgoAB::joinThread()
{
  if (m_thread.joinable())
    {
      m_thread.join();
    }
}


inline void PlayerIF_AlgoAB::checkTime()
{
  const int timeDiffMS = elapsedMS(m_startTime);

  // thinking time is over
  if (timeDiffMS >= m_maxMSecs)
    {
      m_stop.request_stop();
    }

  // update progress bar
  float perc = timeDiffMS;
  perc /= m_maxMSecs;
  if (perc>1.0) perc=1.0;

  m_tunnel->setProgress(perc);
}


// ----------------------------------------------------------------------------------------------------

#define INDENT std::cout << "-" << (&"| | | | | | | | | | "[20-currDepth*2]);


float PlayerIF_AlgoAB::NegaMax(const Board& board,float alpha,float beta,
			       int currDepth, int levels_to_go, Variation& variation, bool useTT)
{
  if (ALGOTRACE) { INDENT; std::cout << "--- NEGAMAX (" << alpha << ";" << beta << ") ---\n"; }


  const bool atRoot = (currDepth==0);

  // check thinking time and stop if we were thinking too long

  if (levels_to_go>5 || atRoot)
    {
      if (useTT) checkTime();
    }

  if (stopRequested() && m_computedSomeMove)
    {
      /* Unwind out of the recursion; doSearch() delivers the best move
	 found so far. */
      throw SearchAborted();
    }

  // check winning situations

  if (board.getNPiecesLeft( board.getCurrentPlayer() )<3) { return -EVAL_INFTY; }


  // check transposition-table

  const float oldAlpha = alpha;

  const TranspositionTable::Entry* entry = nullptr;
  if (useTT) entry = m_ttable->lookup(board.getHash(), board);
  if (entry)
    {
      if (entry->depth >= levels_to_go)
	{
	  if (ALGOTRACE) { INDENT; std::cout << "found table entry !\n"; }

	  if (entry->getBoundType() == TranspositionTable::AccurateValue)
	    {
	      if (atRoot)
		{
		  m_move = entry->bestMove;
		  m_computedSomeMove=true;
		  logBestMoveFromTable(board, m_move, entry->eval, entry->depth);
		}

	      if (ALGOTRACE) { INDENT; std::cout << "entry = " << *entry << "\n"; }
	      return entry->eval;
	    }
	  else if (entry->getBoundType() == TranspositionTable::LowerBound)
	    {
	      alpha = std::max(alpha, entry->eval);
	    }
	  else if (entry->getBoundType() == TranspositionTable::UpperBound)
	    {
	      beta = std::min(beta, entry->eval);
	    }

	  if (alpha >= beta)
	    {
	      if (atRoot)
		{
		  m_move = entry->bestMove;
		  m_computedSomeMove=true;
		}

	      if (ALGOTRACE) { std::cout << "  table-> " << entry->eval << "\n"; }

	      return entry->eval;
	    }
	}
    }

  // process leaves

  if (levels_to_go==0)
    {
      float eval = Eval(board, levels_to_go);

      /*
      float memeval = -m_posMemory.lookupHash(board);
      if (memeval!=0)
	{
	  subPly(memeval);
	  return memeval;
	}
      */

      if (ALGOTRACE) { INDENT; std::cout << "leaf. Eval=" << eval << "\n"; }
      return eval;
    }

  // try previous best-move first

  Board tmpBoard;
  float bestEval = -EVAL_INFTY;
  Move  bestMove;

  tmpBoard = board;


  // recurse

  std::vector<Move> moves;
  moves.reserve(100); // speed-up move generation
  m_ruleSpec->generateMoves(moves, board);

  if (moves.size()==0)
    { return -EVAL_INFTY; }

  // Move ordering: put most promising move to front

  if (entry)
    {
      for (int i=1;i<moves.size();i++)
	if (moves[i]==entry->bestMove)
	  {
	    std::swap(moves[0], moves[i]);
	    break;
	  }
    }

  // random move order to randomize play
  if (RANDOMIZE && atRoot)
    {
      for (int i=1;i<moves.size();i++)
	{
	  std::uniform_int_distribution<int> pick(i, int(moves.size())-1);

	  std::swap(moves[i], moves[pick(m_random)]);
	}
    }

  if (ALGOTRACE)
    { INDENT; std::cout << "list of moves: ";
      for (const Move& move : moves)
	{
	  std::cout << move << " ";
	}
      std::cout << "\n";
    }

  for (const Move& move : moves)
    {
      if (ALGOTRACE) { INDENT; std::cout << "try move: " << move << "  (" << alpha << "," << beta << ")\n"; }

      tmpBoard.doMove(move);

      Variation childVar;
      eval_t recBeta  = beta;  subPly(recBeta);
      eval_t recAlpha = alpha; subPly(recAlpha);
      float eval = -NegaMax(tmpBoard, -recBeta, -recAlpha, currDepth+1, levels_to_go-1, childVar, useTT);
      addPly(eval);

      if (currDepth==0 && m_experience!=nullptr)
	{
	  if (fabs(eval) < EVAL_WIN)
	    {
	      float offset = m_experience->getOffset( m_ruleSpec->getBoardID_Symmetric(tmpBoard), m_selfPlayer );
	      offset *= m_weight[Weight_Experience];
	      eval += offset;
	    }
	}

      /*
      if (abs(eval)>EVAL_WIN)
	m_posMemory.storeBoard(tmpBoard,eval);
      */

      tmpBoard.undoMove(move);

      if (eval>bestEval)
	{
	  bestEval=eval;
	  bestMove=move;

	  variation.clear();
	  variation.push_back(move);
	  variation.append(childVar);

	  if (atRoot)
	    {
	      logBestMove(variation, bestEval, levels_to_go);
	      m_move=bestMove;
	      m_computedSomeMove=true;
	    }

	  if (ALGOTRACE) { INDENT; std::cout << "set best move to " << move << " @eval=" << eval << "\n"; }

	  // alpha-beta pruning
	  if (bestEval>=beta)
	    {
	      if (ALGOTRACE) { INDENT; std::cout << "beta cut-off\n"; }
	      break;
	    }
	}

      // MAX
      if (bestEval>alpha)
	{
	  alpha = bestEval;
	  if (ALGOTRACE) { INDENT; std::cout << "adjust alpha to " << alpha << "\n"; }
	}
    }

  // insert into transposition-table
  m_ttable->insert(board.getHash(), bestEval, TranspositionTable::boundType(bestEval, oldAlpha, beta),
		   levels_to_go, bestMove, board);

  if (ALGOTRACE)
    {
      INDENT; std::cout << "bestEval= " << bestEval << "\n";
      INDENT; std::cout << "bestMove= " << bestMove << "\n";
    }

  return bestEval;
}


float PlayerIF_AlgoAB::Eval(const Board& board, int levelsToGo) const
{
  m_nodesEvaluated++;

  float eval = 0.0;

  const Player me    = board.getCurrentPlayer();
  const Player other = opponent(me);

  const RuleSpec& ruleSpec = *m_ruleSpec;
  const BoardSpec& boardSpec = *ruleSpec.boardSpec;

  // ========== material ==========

  eval += m_weight[Weight_Material]*(board.getNPiecesLeft( board.getCurrentPlayer() )   -
				     board.getNPiecesLeft( board.getOpponentPlayer() ));

  // ========== freedom ==========

  int myFreedom =0;
  int oppFreedom=0;
  for (int i=0;i<boardSpec.nPositions();i++)
    {
      /**/ if (board.getPosition(i) == me)    myFreedom  += ruleSpec.freedomAtPosition(board,i);
      else if (board.getPosition(i) == other) oppFreedom += ruleSpec.freedomAtPosition(board,i);
    }


  // Note: consider special case at start of game: no pieces on the board -> no freedom.

  if (myFreedom==0 &&
      board.getNPiecesOnBoard( board.getCurrentPlayer())>0)
    {
      if (ruleSpec.mayJump && board.getNPiecesLeft( board.getCurrentPlayer() )==3)
	{ }
      else if (board.getNPiecesToSet( board.getCurrentPlayer() )>0)
	{ }
      else
	{ return -EVAL_INFTY; }
    }

  eval += m_weight[Weight_Freedom] * (myFreedom - oppFreedom);


  // ========== mills ==========

  int myMills=0;
  int otherMills=0;
  for (int i=0;i< boardSpec.nMills(); i++)
    {
      const MillPosVector& mill=boardSpec.getMill(i);

      Player p0 = board.getPosition(mill[0]);
      if (p0 != PL_None &&
	  p0 == board.getPosition(mill[1]) &&
	  p0 == board.getPosition(mill[2]))
	{
	  if (p0 == me) myMills++;
	  else          otherMills++;
	}
    }

  eval += m_weight[Weight_Mills] * (myMills - otherMills);

#if 0
  // dummy weights for debugging ...

  for (int i=0;i<m_control->getBoardSpec().nPositions();i++)
    {
      /**/ if (board.getPosition(i) == me)    eval += 24-i;
      else if (board.getPosition(i) == other) eval -= 24-i;
    }
#endif

  return eval;
}


void PlayerIF_AlgoAB::logBestMoveFromTable(const Board& b, const Move& m, eval_t e, int depth) const
{
  Board board = b;
  Move  move = m;

  Variation v;

  for (int i=0;i<=depth;i++)
    {
      v.push_back(move);

      board.doMove(move);

      const TranspositionTable::Entry* entry;
      entry = m_ttable->lookup(board.getHash(), board);
      if (entry)
	{
	  move = entry->bestMove;
	}
      else
	break;
    }

  logBestMove(v,e,depth," <- from ttable");
}

void PlayerIF_AlgoAB::logBestMove(const Move& m, eval_t e, int depth) const
{
  Variation v;
  v.push_back(m);
  logBestMove(v,e,depth);
}


void PlayerIF_AlgoAB::logBestMove(const Variation& v, eval_t e, int depth, const char* suffix) const
{
  std::stringstream strstr;

  Player p = m_startBoard.getCurrentPlayer();
  for (int i=0;i<v.size();i++)
    {
      strstr << writeMove(v[i], m_ruleSpec->boardSpec) << " ";
      if (p==PL_Black && i<v.size()-1) strstr << "/ ";
      p = opponent(p);
    }

  strstr << "(";
  if (fabs(e) > EVAL_WIN)
    {
      strstr << e << " ";

      Player winner;
      if (m_startBoard.getCurrentPlayer() == PL_White) winner=PL_White;
      else winner=PL_Black;
      if (e<0) winner= opponent(winner);

      char* player;
      if (winner==PL_White) player=_("white");
      else                  player=_("black");

      int eInt = e;
      int eAbs = (eInt < 0 ? -eInt : eInt);
      int iInt = EVAL_INFTY;

      int winInMoves = (iInt-1-eAbs)/2+1;

      char buf[100];
      if (winInMoves>1) sprintf(buf, _("%s wins in %d moves)"), player, winInMoves);
      else              sprintf(buf, _("%s wins the next move)"), player);

      strstr << buf;
    }
  else
    {
      if (m_startBoard.getCurrentPlayer() == PL_Black) e = -e;
      strstr << e << ')';
    }

  strstr << " [" << depth << "]" << suffix;

  m_tunnel->showThinkingInfo(strstr.str());
}


void PlayerIF_AlgoAB::notifyWinner(Player p, const GameControl& control)
{
  if (p==PL_None)
    {
      return;
    }

  if (m_experience==nullptr)
    {
      return;
    }


  for (int i=0;i<control.getHistorySize()-1;i++)
    {
      std::shared_ptr<Board> board = control.getHistoryBoard(i);

      m_experience->addBoard( m_ruleSpec->getBoardID_Symmetric(*board), p);
    }
}
