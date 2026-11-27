#ifndef MORRIS_H
#define MORRIS_H

#if defined(_WIN32)
#  if defined(MORRIS_BUILD)
#    define MORRIS_API __declspec(dllexport)
#  else
#    define MORRIS_API __declspec(dllimport)
#  endif
#else
#  define MORRIS_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define MORRIS_POINTS 24

enum {
  MORRIS_OK      =  0,
  MORRIS_NO_MOVE = -1,
  MORRIS_INVALID = -2,
  MORRIS_ERROR   = -3
};

typedef struct morris_engine morris_engine;

MORRIS_API const char*    morris_name(void);
MORRIS_API const char*    morris_version(void);

MORRIS_API morris_engine* morris_create(void);
MORRIS_API void           morris_destroy(morris_engine* engine);

MORRIS_API void           morris_new_game(morris_engine* engine);
MORRIS_API void           morris_set_time(morris_engine* engine, int msec);
MORRIS_API void           morris_set_depth(morris_engine* engine, int depth);
MORRIS_API void           morris_stop(morris_engine* engine);

/* points: 0 to 23, row by row from the top left corner (diagram in README.md);
   0 empty, 1 white, 2 black. hand_*: pieces still to place. side: 1 or 2.
   source: -1 for a placement; capture: -1 if no piece is taken. */
MORRIS_API int            morris_choose(morris_engine* engine,
                                        const int points[MORRIS_POINTS],
                                        int hand_white, int hand_black, int side,
                                        int* source, int* target, int* capture);

#ifdef __cplusplus
}
#endif

#endif
