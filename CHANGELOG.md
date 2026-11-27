# Changelog

## 1.1 (2026-11-27)

- Second computer opponent, *Morris 0.4* (alpha-beta search, engine by Dirk Farin), through the optional *morris* library, built by `make engine`. If the library cannot be loaded, *Aléa* is used instead and the status line says so.
- Command line options `--engine=builtin|morris` to choose the opponent and `--time=<ms>` to set its thinking time.

## 1.0 (2026-09-27)

- First version: game of nine men's morris against a computer opponent that plays random legal actions.
