unit alea;

{$mode objfpc}{$h+}{$codepage utf8}

interface

uses
  game;

type
  actionty = record
    source: integer;
    target: integer;
  end;

function enginename(): unicodestring;
function engineversion(): unicodestring;
procedure setthinkingtime(const amsec: integer);
procedure newgame();
procedure preparethinking();
procedure abortthinking();
function chooseaction(const agame: tgame): actionty;
function chooseturn(const agame: tgame): turnty;

implementation

uses
  sysutils;

var
  fthinkingtime: integer = 1500;
  fstop: boolean = false;

function enginename(): unicodestring;
begin
  result := 'Aléa';
end;

function engineversion(): unicodestring;
begin
  result := '0.1';
end;

procedure setthinkingtime(const amsec: integer);
begin
  fthinkingtime := amsec;
end;

procedure newgame();
begin
end;

procedure preparethinking();
begin
  fstop := false;
end;

procedure abortthinking();
begin
  fstop := true;
end;

function chooseaction(const agame: tgame): actionty;
var
  candidates: array of actionty;
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

function chooseturn(const agame: tgame): turnty;
var
  a: actionty;
  p: integer;
begin
  result.source := -1;
  result.target := -1;
  result.capture := -1;
  if not thinkingdelay() then
    exit;
  p := agame.player;
  a := chooseaction(agame);
  result.source := a.source;
  result.target := a.target;
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

initialization
  randomize();
end.
