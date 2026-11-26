unit game;

{$mode objfpc}{$h+}{$codepage utf8}

interface

const
  pointcount = 24;
  piecesperplayer = 9;

{$i tables.inc}

type
  phasety = (ph_place, ph_move, ph_remove, ph_over);

  tgame = class
  private
    fpoints: array[0..pointcount - 1] of integer;
    fplayer: integer;
    fphase: phasety;
    fhand: array[1..2] of integer;
    fwinner: integer;
    fquiet: boolean;
    procedure writelog(const aline: string);
    procedure endturn();
    function getpoint(const aindex: integer): integer;
    function gethand(const aplayer: integer): integer;
  public
    constructor create();
    constructor createcopy(const asource: tgame);
    procedure init();
    function place(const aindex: integer): boolean;
    function move(const afrom, ato: integer): boolean;
    function remove(const aindex: integer): boolean;
    function countpieces(const aplayer: integer): integer;
    function isinmill(const aindex: integer): boolean;
    function maytake(const aindex: integer): boolean;
    function mayjump(const aplayer: integer): boolean;
    function maymove(const afrom, ato: integer): boolean;
    function canmove(const aplayer: integer): boolean;
    function positionstr(): string;
    property points[const aindex: integer]: integer read getpoint;
    property hand[const aplayer: integer]: integer read gethand;
    property player: integer read fplayer;
    property phase: phasety read fphase;
    property winner: integer read fwinner;
  end;

implementation

uses
  sysutils,
  log;

const
  playernames: array[1..2] of string = ('Blancs', 'Noirs');
  phasenames: array[phasety] of string = ('pose', 'déplacement', 'prise', 'terminée');
  piecechars: array[0..2] of char = ('.', 'b', 'n');

constructor tgame.create();
begin
  inherited create();
  init();
end;

constructor tgame.createcopy(const asource: tgame);
begin
  inherited create();
  fpoints := asource.fpoints;
  fplayer := asource.fplayer;
  fphase := asource.fphase;
  fhand := asource.fhand;
  fwinner := asource.fwinner;
  fquiet := true;
end;

procedure tgame.writelog(const aline: string);
begin
  if not fquiet then
    log.writelog(aline);
end;

procedure tgame.init();
var
  i: integer;
begin
  for i := 0 to pointcount - 1 do
    fpoints[i] := 0;
  fplayer := 1;
  fphase := ph_place;
  fhand[1] := piecesperplayer;
  fhand[2] := piecesperplayer;
  fwinner := 0;
end;

function tgame.positionstr(): string;
var
  i: integer;
begin
  setlength(result, pointcount);
  for i := 0 to pointcount - 1 do
    result[i + 1] := piecechars[fpoints[i]];
end;

function tgame.getpoint(const aindex: integer): integer;
begin
  result := fpoints[aindex];
end;

function tgame.gethand(const aplayer: integer): integer;
begin
  result := fhand[aplayer];
end;

function tgame.countpieces(const aplayer: integer): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to pointcount - 1 do
    if fpoints[i] = aplayer then
      inc(result);
end;

function tgame.isinmill(const aindex: integer): boolean;
var
  p: integer;
begin
  p := fpoints[aindex];
  result := (p <> 0) and (
    (fpoints[lines[aindex, 0]] = p) and (fpoints[lines[aindex, 1]] = p) or
    (fpoints[lines[aindex, 2]] = p) and (fpoints[lines[aindex, 3]] = p));
end;

function tgame.maytake(const aindex: integer): boolean;
var
  i, p: integer;
begin
  p := fpoints[aindex];
  if (p = 0) or (p = fplayer) then
    exit(false);
  if not isinmill(aindex) then
    exit(true);
  for i := 0 to pointcount - 1 do
    if (fpoints[i] = p) and not isinmill(i) then
      exit(false);
  result := true;
end;

function tgame.mayjump(const aplayer: integer): boolean;
begin
  result := countpieces(aplayer) = 3;
end;

function tgame.maymove(const afrom, ato: integer): boolean;
var
  i: integer;
begin
  if fpoints[ato] <> 0 then
    exit(false);
  if mayjump(fpoints[afrom]) then
    exit(true);
  for i := 0 to 3 do
    if neighbours[afrom, i] = ato then
      exit(true);
  result := false;
end;

function tgame.canmove(const aplayer: integer): boolean;
var
  i, j, n: integer;
begin
  if mayjump(aplayer) then
    exit(true);
  for i := 0 to pointcount - 1 do
    if fpoints[i] = aplayer then
      for j := 0 to 3 do
      begin
        n := neighbours[i, j];
        if (n >= 0) and (fpoints[n] = 0) then
          exit(true);
      end;
  result := false;
end;

procedure tgame.endturn();
begin
  fplayer := 3 - fplayer;
  if fhand[fplayer] > 0 then
    fphase := ph_place
  else
  begin
    fphase := ph_move;
    if (countpieces(fplayer) < 3) or not canmove(fplayer) then
    begin
      if countpieces(fplayer) < 3 then
        writelog(format('Les %s n''ont plus que %d pions', [playernames[fplayer], countpieces(fplayer)]))
      else
        writelog(format('Les %s ne peuvent plus bouger', [playernames[fplayer]]));
      fwinner := 3 - fplayer;
      fphase := ph_over;
    end;
  end;
  writelog(format('Position %s, réserves %d/%d, pions %d/%d', [positionstr(), fhand[1], fhand[2], countpieces(1), countpieces(2)]));
  if fphase = ph_over then
    writelog(format('Partie terminée, les %s ont gagné', [playernames[fwinner]]))
  else
    writelog(format('Au tour des %s (%s)', [playernames[fplayer], phasenames[fphase]]));
end;

function tgame.place(const aindex: integer): boolean;
begin
  result := (fphase = ph_place) and (fpoints[aindex] = 0);
  if not result then
  begin
    writelog(format('%s : pose en %d refusée', [playernames[fplayer], aindex]));
    exit;
  end;
  writelog(format('%s : pose en %d', [playernames[fplayer], aindex]));
  fpoints[aindex] := fplayer;
  dec(fhand[fplayer]);
  if isinmill(aindex) then
  begin
    writelog(format('Moulin des %s en %d', [playernames[fplayer], aindex]));
    fphase := ph_remove;
  end
  else
    endturn();
end;

function tgame.move(const afrom, ato: integer): boolean;
begin
  result := (fphase = ph_move) and (fpoints[afrom] = fplayer) and maymove(afrom, ato);
  if not result then
  begin
    writelog(format('%s : déplacement %d-%d refusé', [playernames[fplayer], afrom, ato]));
    exit;
  end;
  if mayjump(fplayer) then
    writelog(format('%s : déplacement %d-%d (3 pions, vol autorisé)', [playernames[fplayer], afrom, ato]))
  else
    writelog(format('%s : déplacement %d-%d', [playernames[fplayer], afrom, ato]));
  fpoints[ato] := fplayer;
  fpoints[afrom] := 0;
  if isinmill(ato) then
  begin
    writelog(format('Moulin des %s en %d', [playernames[fplayer], ato]));
    fphase := ph_remove;
  end
  else
    endturn();
end;

function tgame.remove(const aindex: integer): boolean;
begin
  result := (fphase = ph_remove) and maytake(aindex);
  if not result then
  begin
    writelog(format('%s : prise en %d refusée', [playernames[fplayer], aindex]));
    exit;
  end;
  writelog(format('%s : prise en %d', [playernames[fplayer], aindex]));
  fpoints[aindex] := 0;
  endturn();
end;

end.
