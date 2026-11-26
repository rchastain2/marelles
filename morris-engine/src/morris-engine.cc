#include "morris-engine.h"

#include "algo_alphabeta.hh"
#include "rules.hh"
#include "ttable.hh"

#include <condition_variable>
#include <memory>
#include <mutex>
#include <vector>


void IdleFunc::install(IdleFunc* func)
{
  delete func;
}


namespace {

class ResultTunnel : public ThreadTunnel
{
public:
  void prepare(int moveID)
  {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_expected = moveID;
    m_done = false;
  }

  void doMove(Move m, int moveID) override
  {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (moveID != m_expected) { return; }
    m_move = m;
    m_done = true;
    m_cond.notify_all();
  }

  Move wait()
  {
    std::unique_lock<std::mutex> lock(m_mutex);
    m_cond.wait(lock, [this] { return m_done; });
    return m_move;
  }

private:
  std::mutex              m_mutex;
  std::condition_variable m_cond;
  Move                    m_move;
  bool                    m_done = false;
  int                     m_expected = 0;
};


std::once_flag hashOnce;

bool toPlayer(int value, Player& player)
{
  switch (value)
    {
    case 0: player = PL_None;  return true;
    case 1: player = PL_White; return true;
    case 2: player = PL_Black; return true;
    default: return false;
    }
}

void writeResult(const Move& m, int* source, int* target, int* capture)
{
  *source  = (m.mode == Move::Mode_Move ? m.oldPos : -1);
  *target  = m.newPos;
  *capture = (m.takes.size() > 0 ? m.takes[0] : -1);
}

}


struct morris_engine
{
  rulespec_ptr  rules;
  ttable_ptr    ttable;
  ResultTunnel  tunnel;
  std::shared_ptr<PlayerIF_AlgoAB> player;

  std::mutex    callMutex;
  std::mutex    stopMutex;
  bool          searching = false;
  int           moveID = 0;
};


extern "C" {

const char* morris_name(void)
{
  return "Morris";
}

const char* morris_version(void)
{
  return "0.4";
}

morris_engine* morris_create(void)
{
  try
    {
      std::call_once(hashOnce, [] { Board::initHashValues(); });

      std::unique_ptr<morris_engine> engine(new morris_engine);
      engine->rules  = RuleSpec::createPresetRule(RuleSpec::Preset_Standard);
      engine->ttable = std::make_shared<TranspositionTable>(TRANSPOSITION_TABLE_SIZE);
      engine->player = std::make_shared<PlayerIF_AlgoAB>();
      engine->player->setRuleSpec(engine->rules);
      engine->player->registerTTable(engine->ttable);
      engine->player->registerThreadTunnel(engine->tunnel);
      engine->player->setMaxTime_msec(1000);
      return engine.release();
    }
  catch (...)
    {
      return nullptr;
    }
}

void morris_destroy(morris_engine* engine)
{
  if (engine == nullptr) { return; }
  morris_stop(engine);
  std::lock_guard<std::mutex> lock(engine->callMutex);
  engine->player.reset();
  delete engine;
}

void morris_new_game(morris_engine* engine)
{
  if (engine == nullptr) { return; }
  std::lock_guard<std::mutex> lock(engine->callMutex);
  engine->player->resetGame();
}

void morris_set_time(morris_engine* engine, int msec)
{
  if (engine == nullptr || msec <= 0) { return; }
  std::lock_guard<std::mutex> lock(engine->callMutex);
  engine->player->setMaxTime_msec(msec);
}

void morris_set_depth(morris_engine* engine, int depth)
{
  if (engine == nullptr || depth <= 0) { return; }
  if (depth > MAXSEARCHDEPTH - 1) { depth = MAXSEARCHDEPTH - 1; }
  std::lock_guard<std::mutex> lock(engine->callMutex);
  engine->player->setMaxDepth(depth);
}

void morris_stop(morris_engine* engine)
{
  if (engine == nullptr) { return; }
  std::lock_guard<std::mutex> lock(engine->stopMutex);
  if (engine->searching) { engine->player->forceMove(); }
}

int morris_choose(morris_engine* engine,
                  const int points[MORRIS_POINTS],
                  int hand_white, int hand_black, int side,
                  int* source, int* target, int* capture)
{
  if (engine == nullptr || points == nullptr ||
      source == nullptr || target == nullptr || capture == nullptr)
    { return MORRIS_INVALID; }

  *source = *target = *capture = -1;

  try
    {
      std::lock_guard<std::mutex> lock(engine->callMutex);

      const int nPositions = engine->rules->boardSpec->nPositions();
      if (nPositions != MORRIS_POINTS) { return MORRIS_ERROR; }

      Player current;
      if (!toPlayer(side, current) || current == PL_None) { return MORRIS_INVALID; }

      if (hand_white < 0 || hand_white > engine->rules->nPieces ||
          hand_black < 0 || hand_black > engine->rules->nPieces)
        { return MORRIS_INVALID; }

      Player positions[MORRIS_POINTS];
      for (int i = 0; i < MORRIS_POINTS; i++)
        {
          if (!toPlayer(points[i], positions[i])) { return MORRIS_INVALID; }
        }

      Board board;
      board.setup(positions, MORRIS_POINTS, current, hand_white, hand_black);

      if (board.getNPiecesLeft(current) < 3) { return MORRIS_NO_MOVE; }

      std::vector<Move> moves;
      engine->rules->generateMoves(moves, board);
      if (moves.empty()) { return MORRIS_NO_MOVE; }

      if (moves.size() == 1)
        {
          writeResult(moves[0], source, target, capture);
          return MORRIS_OK;
        }

      const int moveID = ++engine->moveID;
      engine->tunnel.prepare(moveID);
      engine->player->setPlayer(current);

      {
        std::lock_guard<std::mutex> stopLock(engine->stopMutex);
        engine->player->startMove(board, moveID);
        engine->searching = true;
      }

      const Move best = engine->tunnel.wait();

      {
        std::lock_guard<std::mutex> stopLock(engine->stopMutex);
        engine->searching = false;
      }

      if (best.newPos < 0) { return MORRIS_NO_MOVE; }

      writeResult(best, source, target, capture);
      return MORRIS_OK;
    }
  catch (...)
    {
      return MORRIS_ERROR;
    }
}

}
