#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "morris-engine.h"

static const int mills[16][3] = {
  { 0,  1,  2}, { 3,  4,  5}, { 6,  7,  8}, { 9, 10, 11},
  {12, 13, 14}, {15, 16, 17}, {18, 19, 20}, {21, 22, 23},
  { 0,  9, 21}, { 3, 10, 18}, { 6, 11, 15}, { 1,  4,  7},
  {16, 19, 22}, { 8, 12, 17}, { 5, 13, 20}, { 2, 14, 23}
};

static char piece(int value)
{
  return value == 1 ? 'W' : value == 2 ? 'B' : '.';
}

static void show(const int* p)
{
  printf(" %c-----------%c-----------%c\n", piece(p[0]), piece(p[1]), piece(p[2]));
  printf(" |           |           |\n");
  printf(" |   %c-------%c-------%c   |\n", piece(p[3]), piece(p[4]), piece(p[5]));
  printf(" |   |       |       |   |\n");
  printf(" |   |   %c---%c---%c   |   |\n", piece(p[6]), piece(p[7]), piece(p[8]));
  printf(" |   |   |       |   |   |\n");
  printf(" %c---%c---%c       %c---%c---%c\n", piece(p[9]), piece(p[10]), piece(p[11]), piece(p[12]), piece(p[13]), piece(p[14]));
  printf(" |   |   |       |   |   |\n");
  printf(" |   |   %c---%c---%c   |   |\n", piece(p[15]), piece(p[16]), piece(p[17]));
  printf(" |   |       |       |   |\n");
  printf(" |   %c-------%c-------%c   |\n", piece(p[18]), piece(p[19]), piece(p[20]));
  printf(" |           |           |\n");
  printf(" %c-----------%c-----------%c\n\n", piece(p[21]), piece(p[22]), piece(p[23]));
}

static int closes_mill(const int* p, int target, int side)
{
  for (int i = 0; i < 16; i++)
    {
      const int* m = mills[i];
      if (m[0] != target && m[1] != target && m[2] != target) { continue; }
      if (p[m[0]] == side && p[m[1]] == side && p[m[2]] == side) { return 1; }
    }
  return 0;
}

static int count(const int* p, int side)
{
  int n = 0;
  for (int i = 0; i < MORRIS_POINTS; i++) { n += (p[i] == side); }
  return n;
}

static int selfplay(int msec, int maxplies)
{
  morris_engine* engine[2] = { morris_create(), morris_create() };
  if (!engine[0] || !engine[1]) { fprintf(stderr, "morris_create failed\n"); return 1; }

  for (int i = 0; i < 2; i++)
    {
      morris_set_time(engine[i], msec);
      morris_new_game(engine[i]);
    }

  int p[MORRIS_POINTS] = {0};
  int hand[3] = {0, 9, 9};
  int side = 1;

  for (int ply = 1; ply <= maxplies; ply++)
    {
      int source, target, capture;
      int r = morris_choose(engine[side - 1], p, hand[1], hand[2], side, &source, &target, &capture);
      if (r == MORRIS_NO_MOVE)
        {
          printf("%s cannot move: %s wins\n", side == 1 ? "White" : "Black", side == 1 ? "Black" : "White");
          break;
        }
      if (r != MORRIS_OK) { fprintf(stderr, "morris_choose returned %d\n", r); return 1; }

      if (source >= 0)
        {
          if (p[source] != side || p[target] != 0) { fprintf(stderr, "illegal move\n"); return 1; }
          p[source] = 0;
        }
      else
        {
          if (hand[side] == 0 || p[target] != 0) { fprintf(stderr, "illegal placement\n"); return 1; }
          hand[side]--;
        }
      p[target] = side;

      int mill = closes_mill(p, target, side);
      if (mill != (capture >= 0)) { fprintf(stderr, "capture inconsistent with mill\n"); return 1; }
      if (capture >= 0)
        {
          if (p[capture] != 3 - side) { fprintf(stderr, "illegal capture\n"); return 1; }
          p[capture] = 0;
        }

      printf("%3d. %s ", ply, side == 1 ? "White" : "Black");
      if (source >= 0) printf("%d-%d", source, target); else printf("@%d", target);
      if (capture >= 0) printf(" x%d", capture);
      printf("\n");
      show(p);

      side = 3 - side;
      if (count(p, side) + hand[side] < 3)
        {
          printf("%s has fewer than three pieces: %s wins\n", side == 1 ? "White" : "Black", side == 1 ? "Black" : "White");
          break;
        }
    }

  morris_destroy(engine[0]);
  morris_destroy(engine[1]);
  return 0;
}

static int analyse(const char* text, int hw, int hb, int side, int msec)
{
  int p[MORRIS_POINTS];
  if (strlen(text) != MORRIS_POINTS) { fprintf(stderr, "position must have 24 characters\n"); return 1; }
  for (int i = 0; i < MORRIS_POINTS; i++)
    {
      char c = text[i];
      p[i] = (c == 'W' || c == 'w' || c == '1') ? 1 : (c == 'B' || c == 'b' || c == '2') ? 2 : 0;
    }
  show(p);

  morris_engine* engine = morris_create();
  if (!engine) { fprintf(stderr, "morris_create failed\n"); return 1; }
  morris_set_time(engine, msec);

  int source, target, capture;
  int r = morris_choose(engine, p, hw, hb, side, &source, &target, &capture);
  printf("result %d: source %d target %d capture %d\n", r, source, target, capture);
  morris_destroy(engine);
  return r == MORRIS_OK ? 0 : 1;
}

int main(int argc, char** argv)
{
  printf("%s %s\n\n", morris_name(), morris_version());

  if (argc >= 2 && strcmp(argv[1], "play") == 0)
    {
      int msec = argc >= 3 ? atoi(argv[2]) : 200;
      int plies = argc >= 4 ? atoi(argv[3]) : 200;
      return selfplay(msec, plies);
    }

  if (argc >= 6 && strcmp(argv[1], "pos") == 0)
    {
      int msec = argc >= 7 ? atoi(argv[6]) : 1000;
      return analyse(argv[2], atoi(argv[3]), atoi(argv[4]), atoi(argv[5]), msec);
    }

  fprintf(stderr,
          "usage: %s play [msec] [plies]\n"
          "       %s pos <24 chars .WB> <hand white> <hand black> <side 1|2> [msec]\n",
          argv[0], argv[0]);
  return 2;
}
