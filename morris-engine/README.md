# morris-engine

Bibliothèque dynamique exposant, sous une interface C, le moteur de jeu de [Morris 0.4](https://github.com/farindk/morris) de Dirk Farin (recherche alpha-bêta NegaMax, approfondissement itératif, table de transposition). Règles du jeu de marelle standard à neuf pièces : vol à trois pièces, une seule prise par coup, prise dans un moulin seulement si toutes les pièces adverses sont dans des moulins.

Licence : GPL v3 (voir `COPYING`), comme Morris.

## Compilation

```
make
```

Produit `build/libmorris-engine.so` et le programme de test `build/morris-cli`. Nécessite un compilateur C++20 (GCC 10 ou plus récent). `make test` lance une partie du moteur contre lui-même, `make clean` supprime le dossier `build`.

## Interface

Voir `include/morris-engine.h`. Convention de *Marelles* : points numérotés de 0 à 23 ligne par ligne, `0` vide, `1` Blancs, `2` Noirs.

| Fonction | Rôle |
|---|---|
| `morris_create` / `morris_destroy` | crée / détruit un moteur (chacun a sa table de transposition) |
| `morris_new_game` | vide la table de transposition |
| `morris_set_time` | temps de réflexion en millisecondes (1000 par défaut) |
| `morris_set_depth` | profondeur maximale (25 par défaut) |
| `morris_choose` | calcule un coup complet : `source` (-1 pour une pose), `target`, `capture` (-1 sans prise) |
| `morris_stop` | appelable depuis un autre thread : `morris_choose` rend au plus tôt le meilleur coup trouvé |

`morris_choose` renvoie `MORRIS_OK`, `MORRIS_NO_MOVE` (aucun coup possible ou moins de trois pièces), `MORRIS_INVALID` (paramètres incorrects) ou `MORRIS_ERROR`. L'appel est bloquant ; un seul calcul à la fois par moteur.

## Test

```
build/morris-cli play [msec] [demi-coups]
build/morris-cli pos <24 caractères .WB> <main blancs> <main noirs> <trait 1|2> [msec]
```
