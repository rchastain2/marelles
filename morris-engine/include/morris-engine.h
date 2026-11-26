#ifndef MORRIS_ENGINE_H
#define MORRIS_ENGINE_H

#if defined(_WIN32)
#  if defined(MORRIS_ENGINE_BUILD)
#    define MORRIS_ENGINE_API __declspec(dllexport)
#  else
#    define MORRIS_ENGINE_API __declspec(dllimport)
#  endif
#else
#  define MORRIS_ENGINE_API __attribute__((visibility("default")))
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

MORRIS_ENGINE_API const char*    morris_name(void);
MORRIS_ENGINE_API const char*    morris_version(void);

MORRIS_ENGINE_API morris_engine* morris_create(void);
MORRIS_ENGINE_API void           morris_destroy(morris_engine* engine);

MORRIS_ENGINE_API void           morris_new_game(morris_engine* engine);
MORRIS_ENGINE_API void           morris_set_time(morris_engine* engine, int msec);
MORRIS_ENGINE_API void           morris_set_depth(morris_engine* engine, int depth);
MORRIS_ENGINE_API void           morris_stop(morris_engine* engine);

MORRIS_ENGINE_API int            morris_choose(morris_engine* engine,
                                               const int points[MORRIS_POINTS],
                                               int hand_white, int hand_black, int side,
                                               int* source, int* target, int* capture);

#ifdef __cplusplus
}
#endif

#endif
