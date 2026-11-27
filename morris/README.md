# morris

Bibliothèque dynamique exposant, sous une interface C, le moteur de jeu de [Morris 0.4](https://github.com/farindk/morris) de Dirk Farin (recherche alpha-bêta NegaMax, approfondissement itératif, table de transposition). Règles du jeu de marelle standard à neuf pièces : vol à trois pièces, une seule prise par coup, prise dans un moulin seulement si toutes les pièces adverses sont dans des moulins.

Licence : GPL v3 (voir `COPYING`), comme Morris.

## Compilation

```
make
```

Produit `build/libmorris.so` et le programme de test `build/morristest-c`. Nécessite un compilateur C++20 (GCC 10 ou plus récent). `make clean` supprime le dossier `build`.

## Interface

Voir `include/morris.h`. Convention de *Marelles* : points numérotés de 0 à 23 ligne par ligne, `0` vide, `1` Blancs, `2` Noirs.

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

| Fonction | Rôle |
|---|---|
| `morris_create` / `morris_destroy` | crée / détruit un moteur (chacun a sa table de transposition) |
| `morris_new_game` | vide la table de transposition |
| `morris_set_time` | temps de réflexion en millisecondes (1000 par défaut) |
| `morris_set_depth` | profondeur maximale (25 par défaut) |
| `morris_choose` | calcule un coup complet : `source` (-1 pour une pose), `target`, `capture` (-1 sans prise) |
| `morris_stop` | appelable depuis un autre thread : `morris_choose` rend au plus tôt le meilleur coup trouvé |

`morris_choose` renvoie `MORRIS_OK`, `MORRIS_NO_MOVE` (aucun coup possible ou moins de trois pièces), `MORRIS_INVALID` (paramètres incorrects) ou `MORRIS_ERROR`. L'appel est bloquant ; un seul calcul à la fois par moteur.

## Liaison Pascal

L'unité `morrislib.pas` charge la bibliothèque dynamiquement (`loadmorrisengine`), d'abord dans le dossier de l'exécutable, puis dans les chemins du système. Elle renvoie `false` si la bibliothèque est absente ou incomplète.

## Tests

Deux programmes de test parallèles : `test/morristest.c` et `test/morristest.pas`.

| Cible | Effet |
|---|---|
| `make test-c` | compile et lance `build/morristest-c` (une partie du moteur contre lui-même) |
| `make test-pas` | compile et lance `build/morristest-pas` (nécessite Free Pascal) |
| `make test` | lance les deux |

```
build/morristest-c play [msec] [demi-coups]
build/morristest-c pos <24 caractères .WB> <main blancs> <main noirs> <trait 1|2> [msec]
```

La version C ne dépend que de la bibliothèque, avec un contrôle minimal des coups ; `pos` affiche le coup choisi dans une position donnée.

```
build/morristest-pas [all|play|stop] [msec] [parties]
```

`play` fait jouer le moteur contre lui-même en soumettant chaque coup à la classe `tgame` de *Marelles* (`../game.pas`), qui sert d'arbitre ; `stop` vérifie qu'un appel à `morris_stop` depuis un autre thread interrompt la recherche.
