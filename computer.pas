unit computer;

{$mode objfpc}{$h+}{$codepage utf8}

interface

uses
  game;

const
  defaultthinkingtime = 1500;
  minthinkingtime = 10;
  maxthinkingtime = 600000;

type
  enginety = (en_builtin, en_morris);

  computeractionty = record
    source: integer;
    target: integer;
  end;

  computerturnty = record
    source: integer;
    target: integer;
    capture: integer;
  end;

function setengine(const aengine: enginety): boolean;
function currentengine(): enginety;
procedure setthinkingtime(const amsec: integer);
function thinkingtime(): integer;
function enginename(): unicodestring;
function enginefullname(): unicodestring;
function enginedescription(): unicodestring;
procedure newgame();
procedure preparethinking();
procedure abortthinking();
function chooseaction(const agame: tgame): computeractionty;
function chooseturn(const agame: tgame): computerturnty;

implementation

uses
  sysutils,
  ctypes,
  morrisengine;

const
  builtinname = 'Aléa';
  builtinversion = '0.1';

var
  fengine: enginety = en_builtin;
  fthinkingtime: integer = defaultthinkingtime;
  fmorris: pmorrisengine = nil;
  fstop: boolean = false;

function setengine(const aengine: enginety): boolean;
begin
  result := true;
  if aengine = en_morris then
  begin
    if fmorris = nil then
    begin
      if loadmorrisengine() then
        fmorris := morris_create();
      if fmorris = nil then
        exit(false);
      morris_set_time(fmorris, fthinkingtime);
    end;
  end;
  fengine := aengine;
end;

function currentengine(): enginety;
begin
  result := fengine;
end;

procedure setthinkingtime(const amsec: integer);
begin
  if amsec < minthinkingtime then
    fthinkingtime := minthinkingtime
  else if amsec > maxthinkingtime then
    fthinkingtime := maxthinkingtime
  else
    fthinkingtime := amsec;
  if fmorris <> nil then
    morris_set_time(fmorris, fthinkingtime);
end;

function thinkingtime(): integer;
begin
  result := fthinkingtime;
end;

function enginename(): unicodestring;
begin
  case fengine of
    en_morris:
      result := unicodestring(utf8string(morris_name()));
  else
    result := builtinname;
  end;
end;

function enginefullname(): unicodestring;
begin
  case fengine of
    en_morris:
      result := enginename() + ' ' + unicodestring(utf8string(morris_version()));
  else
    result := builtinname + ' ' + builtinversion;
  end;
end;

function enginedescription(): unicodestring;
begin
  case fengine of
    en_morris:
      result := 'cherche son coup par une recherche alpha-bêta limitée à ' + unicodestring(inttostr(fthinkingtime)) + ' ms';
  else
    result := 'joue une action légale au hasard après une pause de ' + unicodestring(inttostr(fthinkingtime)) + ' ms simulant la réflexion';
  end;
end;

procedure newgame();
begin
  if fmorris <> nil then
    morris_new_game(fmorris);
end;

procedure preparethinking();
begin
  fstop := false;
end;

procedure abortthinking();
begin
  fstop := true;
  if fmorris <> nil then
    morris_stop(fmorris);
end;

function chooseaction(const agame: tgame): computeractionty;
var
  candidates: array of computeractionty;
  count, i, j: integer;

  procedure add(const asource, atarget: integer);
  begin
    if count = length(candidates) then
      setlength(candidates, 2 * count + 16);
    candidates[count].source := asource;
    candidates[count].target := atarget;
    inc(count);
  end;

begin
  count := 0;
  case agame.phase of
    ph_place:
      for i := 0 to pointcount - 1 do
        if agame.points[i] = 0 then
          add(-1, i);
    ph_move:
      for i := 0 to pointcount - 1 do
        if agame.points[i] = agame.player then
          for j := 0 to pointcount - 1 do
            if agame.maymove(i, j) then
              add(i, j);
    ph_remove:
      for i := 0 to pointcount - 1 do
        if agame.maytake(i) then
          add(-1, i);
  end;
  if count = 0 then
  begin
    result.source := -1;
    result.target := -1;
  end
  else
    result := candidates[random(count)];
end;

function thinkingdelay(): boolean;
var
  t: qword;
begin
  t := gettickcount64() + qword(fthinkingtime);
  while (gettickcount64() < t) and not fstop do
    sleep(20);
  result := not fstop;
end;

function choosebuiltin(const agame: tgame): computerturnty;
var
  a: computeractionty;
  p: integer;
begin
  p := agame.player;
  a := chooseaction(agame);
  result.source := a.source;
  result.target := a.target;
  result.capture := -1;
  if a.target < 0 then
    exit;
  case agame.phase of
    ph_place:
      agame.place(a.target);
    ph_move:
      agame.move(a.source, a.target);
  end;
  if (agame.phase = ph_remove) and (agame.player = p) then
    result.capture := chooseaction(agame).target;
end;

function choosemorris(const agame: tgame): computerturnty;
var
  points: tmorrispoints;
  i: integer;
  source, target, capture: cint;
begin
  result.source := -1;
  result.target := -1;
  result.capture := -1;
  if fstop then
    exit;
  for i := 0 to morrispoints - 1 do
    points[i] := agame.points[i];
  if morris_choose(fmorris, @points[0], agame.hand[1], agame.hand[2], agame.player, source, target, capture) = morris_ok then
  begin
    result.source := source;
    result.target := target;
    result.capture := capture;
  end;
end;

function chooseturn(const agame: tgame): computerturnty;
begin
  if (fengine = en_morris) and (agame.phase <> ph_remove) then
    result := choosemorris(agame)
  else
  begin
    result.source := -1;
    result.target := -1;
    result.capture := -1;
    if thinkingdelay() then
      result := choosebuiltin(agame);
  end;
end;

initialization
  randomize();

finalization
  if fmorris <> nil then
    morris_destroy(fmorris);
end.
