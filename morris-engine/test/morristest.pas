program morristest;

{$mode objfpc}{$h+}

uses
{$ifdef unix}
  cthreads,
{$endif}
  sysutils,
  classes,
  ctypes,
  game,
  morrisengine;

const
  maxplies = 300;
  piecechars: array[0..2] of char = ('.', 'W', 'B');
  sidenames: array[1..2] of string = ('Blancs', 'Noirs');

type
  tstopper = class(tthread)
  private
    fengine: pmorrisengine;
    fdelay: integer;
  protected
    procedure execute(); override;
  public
    constructor create(const aengine: pmorrisengine; const adelay: integer);
  end;

constructor tstopper.create(const aengine: pmorrisengine; const adelay: integer);
begin
  inherited create(true);
  fengine := aengine;
  fdelay := adelay;
  start();
end;

procedure tstopper.execute();
begin
  sleep(fdelay);
  morris_stop(fengine);
end;

procedure showboard(const agame: tgame);
  function c(const aindex: integer): char;
  begin
    result := piecechars[agame.points[aindex]];
  end;
begin
  writeln(format('  %s-----------%s-----------%s', [c(0), c(1), c(2)]));
  writeln('  |           |           |');
  writeln(format('  |   %s-------%s-------%s   |', [c(3), c(4), c(5)]));
  writeln('  |   |       |       |   |');
  writeln(format('  |   |   %s---%s---%s   |   |', [c(6), c(7), c(8)]));
  writeln('  |   |   |       |   |   |');
  writeln(format('  %s---%s---%s       %s---%s---%s', [c(9), c(10), c(11), c(12), c(13), c(14)]));
  writeln('  |   |   |       |   |   |');
  writeln(format('  |   |   %s---%s---%s   |   |', [c(15), c(16), c(17)]));
  writeln('  |   |       |       |   |');
  writeln(format('  |   %s-------%s-------%s   |', [c(18), c(19), c(20)]));
  writeln('  |           |           |');
  writeln(format('  %s-----------%s-----------%s', [c(21), c(22), c(23)]));
end;

function choose(const aengine: pmorrisengine; const agame: tgame; out asource, atarget, acapture: cint): cint;
var
  points: tmorrispoints;
  i: integer;
begin
  for i := 0 to morrispoints - 1 do
    points[i] := agame.points[i];
  result := morris_choose(aengine, @points[0], agame.hand[1], agame.hand[2], agame.player, asource, atarget, acapture);
end;

function movestr(const asource, atarget, acapture: cint): string;
begin
  if asource < 0 then
    result := format('@%d', [atarget])
  else
    result := format('%d-%d', [asource, atarget]);
  if acapture >= 0 then
    result := result + format('x%d', [acapture]);
end;

function playgame(const aengines: array of pmorrisengine): integer;
var
  start, g: tgame;
  ply, side: integer;
  r, source, target, capture: cint;
  ok: boolean;
  line: string;

  procedure fail(const amessage: string);
  begin
    if line <> '' then
      writeln(line);
    writeln(format('ERREUR au demi-coup %d (%s) : %s', [ply, sidenames[side], amessage]));
    writeln('  position ', g.positionstr(), format(', réserves %d/%d', [g.hand[1], g.hand[2]]));
    showboard(g);
  end;

begin
  start := tgame.create();
  g := tgame.createcopy(start);
  start.free;
  line := '';
  result := -1;
  try
    for ply := 1 to maxplies do
    begin
      side := g.player;
      r := choose(aengines[side - 1], g, source, target, capture);
      if r = morris_no_move then
      begin
        fail('le moteur ne trouve aucun coup alors que la partie continue');
        exit;
      end;
      if r <> morris_ok then
      begin
        fail(format('morris_choose a renvoyé %d', [r]));
        exit;
      end;
      if source < 0 then
        ok := g.place(target)
      else
        ok := g.move(source, target);
      if not ok then
      begin
        fail('coup refusé par tgame : ' + movestr(source, target, capture));
        exit;
      end;
      if g.phase = ph_remove then
      begin
        if capture < 0 then
        begin
          fail('moulin fermé sans prise : ' + movestr(source, target, capture));
          exit;
        end;
        if not g.remove(capture) then
        begin
          fail('prise refusée par tgame : ' + movestr(source, target, capture));
          exit;
        end;
      end
      else if capture >= 0 then
      begin
        fail('prise sans moulin : ' + movestr(source, target, capture));
        exit;
      end;
      line := line + format('%-9s', [movestr(source, target, capture)]);
      if ply mod 8 = 0 then
      begin
        writeln(line);
        line := '';
      end;
      if g.phase = ph_over then
      begin
        if line <> '' then
          writeln(line);
        line := '';
        side := g.player;
        r := choose(aengines[side - 1], g, source, target, capture);
        if r <> morris_no_move then
        begin
          fail(format('partie terminée pour tgame, mais morris_choose renvoie %d', [r]));
          exit;
        end;
        showboard(g);
        writeln(format('Les %s gagnent en %d demi-coups', [sidenames[g.winner], ply]));
        exit(g.winner);
      end;
    end;
    if line <> '' then
      writeln(line);
    showboard(g);
    writeln(format('Partie arrêtée après %d demi-coups', [maxplies]));
    result := 0;
  finally
    g.free;
  end;
end;

function testplay(const amsec, agames: integer): boolean;
var
  engines: array[0..1] of pmorrisengine;
  scores: array[-1..2] of integer;
  i, r: integer;
begin
  writeln(format('=== %d partie(s), %d ms par coup ===', [agames, amsec]));
  for i := 0 to 1 do
  begin
    engines[i] := morris_create();
    if engines[i] = nil then
    begin
      writeln('ERREUR : morris_create a échoué');
      exit(false);
    end;
    morris_set_time(engines[i], amsec);
  end;
  fillchar(scores, sizeof(scores), 0);
  for i := 1 to agames do
  begin
    writeln;
    writeln(format('--- Partie %d ---', [i]));
    morris_new_game(engines[0]);
    morris_new_game(engines[1]);
    r := playgame(engines);
    inc(scores[r]);
    if r < 0 then
      break;
  end;
  for i := 0 to 1 do
    morris_destroy(engines[i]);
  writeln;
  writeln(format('Blancs %d, Noirs %d, arrêtées %d, erreurs %d', [scores[1], scores[2], scores[0], scores[-1]]));
  result := scores[-1] = 0;
end;

function teststop(): boolean;
const
  delay = 300;
  thinking = 10000;
var
  engine: pmorrisengine;
  points: tmorrispoints;
  stopper: tstopper;
  t: qword;
  r, source, target, capture: cint;
begin
  writeln(format('=== Interruption par morris_stop après %d ms (temps accordé %d ms) ===', [delay, thinking]));
  engine := morris_create();
  if engine = nil then
  begin
    writeln('ERREUR : morris_create a échoué');
    exit(false);
  end;
  morris_set_time(engine, thinking);
  fillchar(points, sizeof(points), 0);
  points[0] := 1;
  points[1] := 1;
  points[3] := 2;
  points[4] := 2;
  points[5] := 2;
  stopper := tstopper.create(engine, delay);
  t := gettickcount64();
  r := morris_choose(engine, @points[0], 7, 6, 1, source, target, capture);
  t := gettickcount64() - t;
  stopper.waitfor();
  stopper.free;
  morris_destroy(engine);
  writeln(format('Résultat %d, coup %s, en %d ms', [r, movestr(source, target, capture), t]));
  result := (r = morris_ok) and (t < 2 * delay + 500);
  if not result then
    writeln('ERREUR : la recherche n''a pas été interrompue');
end;

var
  mode: string;
  msec, games: integer;
  ok: boolean;

begin
  if not loadmorrisengine() then
  begin
    writeln('Impossible de charger ', morrislibname);
    halt(2);
  end;
  writeln(morris_name(), ' ', morris_version());
  writeln;
  mode := lowercase(paramstr(1));
  if mode = '' then
    mode := 'all';
  msec := strtointdef(paramstr(2), 100);
  games := strtointdef(paramstr(3), 2);
  if mode = 'play' then
    ok := testplay(msec, games)
  else if mode = 'stop' then
    ok := teststop()
  else if mode = 'all' then
  begin
    ok := testplay(msec, games);
    writeln;
    ok := teststop() and ok;
  end
  else
  begin
    writeln('usage : ', extractfilename(paramstr(0)), ' [all|play|stop] [ms par coup] [parties]');
    halt(2);
  end;
  writeln;
  if ok then
    writeln('Tests réussis')
  else
    writeln('Tests échoués');
  if not ok then
    halt(1);
end.
