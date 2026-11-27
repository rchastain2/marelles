
# Marelles

*MSEgui* implementation of Nine Men's Morris.

The game logic comes from [Mérelles](https://codeberg.org/rchastain/merelles), a C/SDL program by [paul-maxime](https://github.com/paul-maxime/merreles).

The rule about taking pieces from mills comes from [Morris](https://github.com/farindk/morris) by Dirk Farin.

## Screenshot

![Screenshot](screenshot.png)

## Rules

### Board and pieces

The board is made of three nested squares joined by four lines at the middle of their sides. The pieces stand on the 24 points where lines meet or end. Two points are neighbours when a line joins them without passing through another point.

Each player has nine pieces: White and Black. White plays first, then the players take turns.

### Mills

A mill is a row of three pieces of the same colour along a line: one side of a square, or one of the four lines joining the squares. There are 16 possible mills.

Each time a player forms a mill, by placing or moving a piece, they remove one opponent piece from the board. The removed piece is out of the game for good. A mill can be opened and closed again later: every new closing counts.

A piece belonging to a mill cannot be taken, unless all the opponent pieces belong to mills. In that case, any of them can be taken.

A move closing two mills at once only allows one piece to be taken.

### Placing

At first, the players place their pieces one at a time on any free point. This phase ends when both players have placed their nine pieces.

### Moving

Then, on each turn, the player moves one of their pieces along a line to a neighbouring free point. Pieces cannot jump over other pieces.

### Flying

A player left with three pieces may move a piece to any free point of the board, not only to a neighbouring one.

### End of the game

A player loses the game when, at their turn to move:

- they have fewer than three pieces, so they can no longer form a mill;
- or none of their pieces can move, all of them being blocked.

The program does not detect draws: when the game goes around in circles, start a new game.

## Usage

Click a free point to place a piece. To move a piece, drag it to its destination, or click it (it gets a green circle and its possible destinations are marked with green dots), then click the destination. After a mill, the pieces that can be taken have a red circle: click one of them.

The status line shows whose turn it is, what to do and how many pieces are left to place.

Two computer opponents are available, selected on the command line:

| Option | Effect |
|---|---|
| `--engine=builtin` | *Aléa 0.1* (default): plays a random legal action after a pause that simulates thinking |
| `--engine=morris` | *Morris 0.4*, through the *morris-engine* library: alpha-beta search |
| `--time=<ms>` | thinking time, from 10 to 600000 ms (1500 by default): the pause of *Aléa*, the search time of *Morris* |

If the *morris-engine* library cannot be loaded, *Aléa* is used instead and the status line says so.

## Building

You need Free Pascal and [MSEgui](https://github.com/mse-org/mseide-msegui):

```Bash
git clone https://github.com/rchastain2/marelles.git
cd marelles
git clone https://github.com/mse-org/mseide-msegui.git --single-branch --depth 1
make
```

Or provide the path to an existing MSEgui repository:

```Bash
make MSEDIR=/path/to/mseide-msegui/
```

Or open *marelles.prj* in MSEide.

To use the *Morris* opponent, build the *morris-engine* library (C++20 compiler required) and copy it next to the executable:

```Bash
make engine
```

The library is looked for in the folder of the executable first, then in the system paths.

## Credits

- Wood texture from [Wood Texture Tiles](https://opengameart.org/content/wood-texture-tiles)
