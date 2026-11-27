
# Marelles

Jeu de la marelle (ou des mérelles, ou des moulins) pour *MSEide+MSEgui*.

La logique du jeu est empruntée au programme [Mérelles](https://codeberg.org/rchastain/merelles) de [paul-maxime](https://github.com/paul-maxime/merreles).

La règle pour la capture des pions compris dans des moulins provient du programme  [Morris](https://github.com/farindk/morris) de Dirk Farin.

## Représentation du plateau

Le plateau est représenté dans `game.pas`.

### Les 24 intersections dans un tableau à une dimension

```pascal
fpoints: array[0..pointcount - 1] of integer; // pointcount = 24
```

Chaque case contient **0** si l'intersection est vide, **1** pour un pion des Blancs et **2** pour un pion des Noirs. Les numéros de joueur sont les mêmes que dans `fplayer`, ce qui permet d'écrire `3 - fplayer` pour passer d'un joueur à l'autre.

Les points sont numérotés de 0 à 23, ligne par ligne, de haut en bas et de gauche à droite :

```
 0-----------1-----------2
 |           |           |
 |   3-------4-------5   |
 |   |       |       |   |
 |   |   6---7---8   |   |
 |   |   |       |   |   |
 9--10--11      12--13--14
 |   |   |       |   |   |
 |   |  15--16--17   |   |
 |   |       |       |   |
 |  18------19------20   |
 |           |           |
21----------22----------23
```

### La géométrie dans deux tables constantes

Le tableau `fpoints` ne sait rien de la forme du plateau. La géométrie est décrite séparément par deux tables :

- **`neighbours[24, 0..3]`** : les points adjacents à chaque point, pour les déplacements. Un point a de 2 à 4 voisins, et les places inutilisées valent `-1` (par exemple `(1, 9, -1, -1)` pour le point 0). `maymove` et `canmove` utilisent cette table.
- **`lines[24, 0..3]`** : les deux alignements qui passent par chaque point. Ce sont deux paires : les indices 0-1 forment une ligne, les indices 2-3 forment l'autre. Pour le point 0, `(1, 2, 9, 21)` correspond à la ligne 0-1-2 et à la ligne 0-9-21. `isinmill` teste ainsi un moulin en deux comparaisons, sans parcourir de liste de moulins.

### Le reste de l'état de la partie

- `fhand[1..2]` : le nombre de pions encore en réserve pour chaque joueur (9 au départ).
- `fplayer` : le joueur dont c'est le tour.
- `fphase` : la phase en cours (`ph_place`, `ph_move`, `ph_remove`, `ph_over`).
- `fwinner` : le gagnant.

### Représentation cubique

Une autre façon de voir le plateau a été proposée par [Philippe Guesset](https://www.developpez.net/forums/d2089226/autres-langages/pascal/representation-jeu-moulin/#post11949548) : les trois carrés sont les trois couches d'un cube de 3 × 3 × 3 cases, vu de dessus. Chaque point reçoit trois coordonnées comprises entre -1 et 1 : `z` désigne le carré (-1 intérieur, 0 milieu, 1 extérieur), `x` et `y` la position sur ce carré. Les trois centres (`x = y = 0`) ne sont pas utilisés, ce qui laisse les 24 points.

La géométrie se déduit alors des coordonnées :

- **voisins** : deux points dont les coordonnées diffèrent de 1 sur un seul axe ; on ne change de carré (axe `z`) qu'au milieu d'un côté, c'est-à-dire quand `(x and y) = 0` ;
- **moulins** : les trois points d'une ligne du cube, sauf les lignes qui passent par un centre et les lignes selon `z` qui passent par les coins. On retrouve les 16 moulins ;
- **position à l'écran**, sur la grille 7 × 7 : `4 + x * (z + 2)`, `4 + y * (z + 2)`.

Le programme du dossier `factory` calcule ainsi les tables `neighbours` et `lines` de `game.pas`, et la table `coords` de `main.pas`.

## Implémenter un adversaire artificiel

Deux adversaires sont disponibles, au choix sur la ligne de commande :

| Option | Effet |
|---|---|
| `--engine=builtin` | *Aléa 0.1* (par défaut) : joue une action légale au hasard, après une pause qui simule la réflexion |
| `--engine=morris` | *Morris 0.4*, par la bibliothèque *morris-engine* : recherche alpha-bêta |
| `--time=<ms>` | temps de réflexion, de 10 à 600000 ms (1500 par défaut) : la pause d'*Aléa*, le temps de recherche de *Morris* |

Si la bibliothèque *morris-engine* ne peut pas être chargée, *Aléa* la remplace, et la ligne d'état le signale. `make engine` compile la bibliothèque et la copie à côté de l'exécutable, où elle est cherchée en premier (puis dans les chemins du système).

Chaque adversaire est une classe qui descend de la classe abstraite `tengine`, déclarée dans `engine.pas` :

```pascal
tengine = class
protected
  fthinkingtime: integer;
  fstop: boolean;
public
  function name(): unicodestring; virtual; abstract;
  function version(): unicodestring; virtual; abstract;
  procedure setthinkingtime(const amsec: integer); virtual;
  procedure newgame(); virtual;
  procedure preparethinking(); virtual;
  procedure abortthinking(); virtual;
  function chooseturn(const agame: tgame): turnty; virtual; abstract;
end;
```

La classe de base garde le temps de réflexion et l'indicateur d'arrêt. Un moteur doit au moins définir `name`, `version` et `chooseturn` :

- `taleaengine`, dans `alea.pas`, pour *Aléa*, ne définit que ces trois méthodes ;
- `tmorrisplayer`, dans `morrisplayer.pas`, pour *Morris*, redéfinit aussi `setthinkingtime`, `newgame` et `abortthinking` pour appeler la bibliothèque, par la liaison `morris-engine/morrisengine.pas`. On le crée par `createengine`, qui renvoie `nil` si la bibliothèque est absente.

L'unité `computer.pas` ne fait qu'aiguiller : `setengine` crée le moteur choisi, et les autres fonctions transmettent chaque appel à l'objet en place. C'est la seule unité que connaissent la fenêtre et le thread de calcul. Pour ajouter un adversaire, il suffit d'écrire une classe qui descend de `tengine`, d'ajouter une valeur à `enginety` et sa création dans `setengine`. Le nom et la version de l'adversaire apparaissent dans le journal, dans la ligne d'état et dans la boîte « À propos ». Le reste (menus, thread de calcul, enchaînement du tour, journal) n'a pas à changer.

### Le contrat de `chooseturn`

```pascal
type
  turnty = record
    source: integer;
    target: integer;
    capture: integer;
  end;

function chooseturn(const agame: tgame): turnty;
```

Le type `turnty` est déclaré dans `game.pas`. La fonction reçoit une copie de la partie et renvoie **le tour complet** de l'ordinateur :

| Phase au début du tour | `source` | `target` | `capture` |
|---|---|---|---|
| `ph_place` | inutilisé (-1) | point libre où poser | pion à prendre si la pose ferme un moulin, sinon -1 |
| `ph_move` | pion à déplacer | point d'arrivée | pion à prendre si le déplacement ferme un moulin, sinon -1 |

La fonction n'est jamais appelée en phase `ph_remove` : le joueur qui ferme un moulin choisit lui-même la prise, et la commande « Jouer » est désactivée pendant cette phase.

Quelques règles :

- la copie appartient au thread : `chooseturn` peut y jouer des coups, comme le fait l'adversaire actuel ;
- les actions renvoyées doivent être **légales**. Une action refusée par `tgame` laisse le tour inachevé ; en réponse automatique, l'ordinateur relance alors son calcul, ce qui peut tourner en rond ;
- `target = -1` signifie « aucune action possible ». Cela ne devrait pas arriver, puisque la partie se termine dès qu'un joueur ne peut plus bouger.

La fonction `chooseaction` d'`alea.pas`, qui choisit une seule action au hasard, sert au `chooseturn` d'*Aléa* et au programme de test.

### Ce que `tgame` met à disposition

En lecture : `points[i]` (0, 1 ou 2), `player`, `phase`, `hand[joueur]`, `winner`, et les fonctions `maymove`, `maytake`, `isinmill`, `countpieces`, `canmove`, `mayjump`, `positionstr`.

Le constructeur `createcopy` crée une copie **silencieuse** de la partie : ses actions n'écrivent pas dans le journal. C'est une copie de ce genre que reçoit `chooseturn`.

Deux limites à connaître :

- **`tgame` ne sait pas annuler un coup.** Une recherche doit donc créer une copie par position explorée, ce qui reste lent pour une recherche profonde.
- **Les tables `neighbours` et `lines` sont privées** : elles sont déclarées dans la partie `implementation` de `game.pas`.

Pour une recherche sérieuse, il vaut donc mieux que le moteur ait **sa propre représentation**, légère : les 24 points, le joueur qui a le trait, la phase, les réserves. Pour les tables, on peut les déplacer dans la partie `interface` de `game.pas`, ou inclure celles que produit `factory` (`make tables.inc`).

Sans recherche, on obtient déjà un adversaire nettement meilleur que le hasard :

- **pose et déplacement** : fermer un moulin si c'est possible ; sinon empêcher l'adversaire de fermer le sien au coup suivant ; sinon préparer un moulin (deux pions alignés avec une case libre) ; sinon jouer au hasard ;
- **prise** : retirer de préférence un pion qui menace de fermer un moulin, ou qui en bloque un.

### Le thread de calcul

Le calcul se fait dans un thread, défini dans `computerthread.pas`, pour que la fenêtre reste réactive :

1. `startthinking` (dans `main.pas`) crée le thread avec une copie silencieuse de la partie. La ligne d'état affiche « L'ordinateur réfléchit... », et les clics sur le plateau et la commande « Jouer » sont ignorés ;
2. le thread appelle `chooseturn`, puis prévient la fenêtre par un événement asynchrone ;
3. `finishturn` joue le tour dans le fil principal, avec `tgame`, ce qui l'écrit dans le journal.

Une nouvelle partie, un changement de la réponse automatique ou la fermeture de la fenêtre interrompent le calcul (`stopthinking`) : `abortthinking` (transmis par `computer.pas` au moteur choisi) arrête la pause d'*Aléa* ou la recherche de *Morris* (`morris_stop`), le thread est prévenu par `terminate`, et la fenêtre attend sa fin. L'indicateur d'arrêt est remis à zéro par `preparethinking`, à la création du thread.

Trois points à respecter dans le moteur :

- **ne pas écrire dans le journal** : `writelog` n'est pas prévu pour être appelé depuis plusieurs threads ;
- **ne toucher ni à la fenêtre, ni à la vraie partie** : tout passe par la copie reçue et par le résultat renvoyé ;
- **savoir s'interrompre** : une longue recherche doit tester régulièrement l'indicateur d'arrêt positionné par `abortthinking`, sans quoi la fenêtre reste bloquée jusqu'à la fin du calcul quand on l'interrompt.

La méthode `thinkingdelay` de `taleaengine` fait la pause d'*Aléa*, de la durée donnée par `--time`, en s'interrompant dès que `abortthinking` est appelé.

### Mesurer la force du nouvel adversaire

Le dossier `test` contient `logtest`, qui fait jouer une partie entière à l'ordinateur contre lui-même, avec une graine du hasard fixe. Sur ce modèle, un programme de match peut faire jouer le nouvel adversaire contre l'ancien (le hasard) sur une centaine de parties, en alternant les couleurs, et compter les victoires, les défaites et les parties arrêtées au bout d'un nombre maximal de coups. Pour que ce soit rapide, il suffit de jouer ces parties sur une copie silencieuse (`createcopy`), qui n'écrit pas dans le journal.

Avec la graine fixe, `logtest.log` sert aussi de référence : un `diff` entre deux versions (en ignorant l'horodatage, par exemple avec `cut -c14-`) montre tout de suite si le déroulement d'une partie a changé.
