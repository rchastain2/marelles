
program factory;

{$mode objfpc}{$h+}

uses
  sysutils;

{
  Génère tables.inc : coordonnées, moulins et voisins des 24 points du plateau.
  Représentation du plateau en cube 3×3×3 proposée par Philippe Guesset.
  https://www.developpez.net/forums/showthread.php?t=2089226#post11949548
}

const
  pointcount = 24;

{ Un point est repéré par (x, y, z) : x, y = direction depuis le centre, z = carré (-1 intérieur, 1 extérieur). }
type
  axisty = (ax_x, ax_y, ax_z);
  cubety = array[-1..1, -1..1, -1..1] of integer;

var
  cube: cubety;
  px, py, pz: array[0..pointcount - 1] of integer;
  count: integer;

{ Le cube 3x3x3 privé de sa colonne centrale (x = y = 0). }
function valid(const x, y, z: integer): boolean;
begin
  result := (abs(x) <= 1) and (abs(y) <= 1) and (abs(z) <= 1) and ((x <> 0) or (y <> 0));
end;

{ Vrai pour les milieux de côté, seuls points reliés d'un carré à l'autre. }
function crossing(const x, y: integer): boolean;
begin
  result := (x and y) = 0;
 {result := (x = 0) or (y = 0);}
end;

{ Numérote les points ligne par ligne sur une grille 7x7 et remplit cube, px, py, pz. }
procedure build();
var
  gx, gy, x, y, z, d: integer;
begin
  for x := -1 to 1 do
    for y := -1 to 1 do
      for z := -1 to 1 do
        cube[x, y, z] := -1;
  
  count := 0;
  for gy := 1 to 7 do
    for gx := 1 to 7 do
    begin
      d := abs(gx - 4);
      if abs(gy - 4) > d then
        d := abs(gy - 4);
      if d = 0 then
        continue;
      x := (gx - 4) div d;
      y := (gy - 4) div d;
      if abs(gx - 4) mod d + abs(gy - 4) mod d <> 0 then
        continue;
      z := d - 2;
      cube[x, y, z] := count;
      px[count] := x;
      py[count] := y;
      pz[count] := z;
      inc(count);
    end;
end;

{ Voisin de i le long d'un axe, ou -1. }
function shift(const i: integer; const axis: axisty; const delta: integer): integer;
var
  x, y, z: integer;
begin
  x := px[i];
  y := py[i];
  z := pz[i];
  case axis of
    ax_x: inc(x, delta);
    ax_y: inc(y, delta);
    ax_z: inc(z, delta);
  end;
  if valid(x, y, z) then
    result := cube[x, y, z]
  else
    result := -1;
end;

{ Les déplacements selon z ne sont possibles qu'aux milieux de côté. }
function linked(const i: integer; const axis: axisty): boolean;
begin
  result := (axis <> ax_z) or crossing(px[i], py[i]);
end;

{ Voisins de i, triés et complétés par -1. }
function neighbourrow(const i: integer): string;
var
  list: array[0..3] of integer;
  axis: axisty;
  n, j, k, t, delta: integer;
begin
  for j := 0 to 3 do
    list[j] := -1;
  n := 0;
  for axis := low(axisty) to high(axisty) do
    if linked(i, axis) then
    begin
      delta := -1;
      while delta <= 1 do
      begin
        k := shift(i, axis, delta);
        if k >= 0 then
        begin
          list[n] := k;
          inc(n);
        end;
        inc(delta, 2);
      end;
    end;
  for j := 1 to n - 1 do
    for k := n - 1 downto j do
      if list[k - 1] > list[k] then
      begin
        t := list[k - 1];
        list[k - 1] := list[k];
        list[k] := t;
      end;
  result := format('(%2d, %2d, %2d, %2d)', [list[0], list[1], list[2], list[3]]);
end;

{ Les deux autres points de la ligne de trois passant par i selon un axe. }
function millpair(const i: integer; const axis: axisty; out a, b: integer): boolean;
var
  c, k: integer;
begin
  result := linked(i, axis);
  if not result then
    exit;
  a := -1;
  b := -1;
  for c := -1 to 1 do
  begin
    case axis of
      ax_x: if not valid(c, py[i], pz[i]) then exit(false) else k := cube[c, py[i], pz[i]];
      ax_y: if not valid(px[i], c, pz[i]) then exit(false) else k := cube[px[i], c, pz[i]];
      ax_z: k := cube[px[i], py[i], c];
    end;
    if k = i then
      continue;
    if a < 0 then
      a := k
    else
      b := k;
  end;
  if a > b then
  begin
    k := a;
    a := b;
    b := k;
  end;
end;

{ Les deux moulins de i, celui contenant le plus petit numéro en premier. }
function linerow(const i: integer): string;
var
  axis: axisty;
  pairs: array[0..1, 0..1] of integer;
  n, a, b: integer;
begin
  n := 0;
  for axis := low(axisty) to high(axisty) do
    if millpair(i, axis, a, b) then
    begin
      pairs[n, 0] := a;
      pairs[n, 1] := b;
      inc(n);
    end;
  if pairs[0, 0] > pairs[1, 0] then
  begin
    a := pairs[0, 0];
    b := pairs[0, 1];
    pairs[0, 0] := pairs[1, 0];
    pairs[0, 1] := pairs[1, 1];
    pairs[1, 0] := a;
    pairs[1, 1] := b;
  end;
  result := format('(%2d, %2d, %2d, %2d)', [pairs[0, 0], pairs[0, 1], pairs[1, 0], pairs[1, 1]]);
end;

{ Position du point sur la grille 7x7. }
function coordrow(const i: integer): string;
begin
  result := format('(%d, %d)', [4 + px[i] * (pz[i] + 2), 4 + py[i] * (pz[i] + 2)]);
end;

{ Écrit une table de constantes, trois entrées par ligne. }
procedure writetable(const aname, atype: string; const arow: integer);
var
  i: integer;
  s: string;
begin
  writeln('  ', aname, ': array[0..pointcount - 1', atype, ' of integer = (');
  for i := 0 to count - 1 do
  begin
    if i mod 3 = 0 then
      write('    ');
    case arow of
      0: s := coordrow(i);
      1: s := linerow(i);
      2: s := neighbourrow(i);
    end;
    write(s);
    if i < count - 1 then
      write(',');
    if (i mod 3 = 2) or (i = count - 1) then
      writeln()
    else
      write(' ');
  end;
  writeln('  );');
end;

begin
  build();
  if count <> pointcount then
  begin
    writeln(stderr, 'erreur : ', count, ' points');
    halt(1);
  end;
  writeln('const');
  writetable('coords', ', 0..1]', 0);
  writeln();
  writetable('lines', ', 0..3]', 1);
  writeln();
  writetable('neighbours', ', 0..3]', 2);
end.
