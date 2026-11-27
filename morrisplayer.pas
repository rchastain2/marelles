unit morrisplayer;

{$mode objfpc}{$h+}{$codepage utf8}

interface

uses
  game;

function loadengine(): boolean;
function enginename(): unicodestring;
function engineversion(): unicodestring;
procedure setthinkingtime(const amsec: integer);
procedure newgame();
procedure preparethinking();
procedure abortthinking();
function chooseturn(const agame: tgame): turnty;

implementation

uses
  ctypes,
  morrisengine;

var
  fengine: pmorrisengine = nil;
  fthinkingtime: integer = 1500;
  fstop: boolean = false;

function loadengine(): boolean;
begin
  if fengine = nil then
  begin
    if loadmorrisengine() then
      fengine := morris_create();
    if fengine <> nil then
      morris_set_time(fengine, fthinkingtime);
  end;
  result := fengine <> nil;
end;

function enginename(): unicodestring;
begin
  if fengine = nil then
    result := 'Morris'
  else
    result := unicodestring(utf8string(morris_name()));
end;

function engineversion(): unicodestring;
begin
  if fengine = nil then
    result := ''
  else
    result := unicodestring(utf8string(morris_version()));
end;

procedure setthinkingtime(const amsec: integer);
begin
  fthinkingtime := amsec;
  if fengine <> nil then
    morris_set_time(fengine, fthinkingtime);
end;

procedure newgame();
begin
  if fengine <> nil then
    morris_new_game(fengine);
end;

procedure preparethinking();
begin
  fstop := false;
end;

procedure abortthinking();
begin
  fstop := true;
  if fengine <> nil then
    morris_stop(fengine);
end;

function chooseturn(const agame: tgame): turnty;
var
  points: tmorrispoints;
  i: integer;
  source, target, capture: cint;
begin
  result.source := -1;
  result.target := -1;
  result.capture := -1;
  if (fengine = nil) or fstop or (agame.phase = ph_remove) then
    exit;
  for i := 0 to morrispoints - 1 do
    points[i] := agame.points[i];
  if morris_choose(fengine, @points[0], agame.hand[1], agame.hand[2], agame.player, source, target, capture) = morris_ok then
  begin
    result.source := source;
    result.target := target;
    result.capture := capture;
  end;
end;

finalization
  if fengine <> nil then
    morris_destroy(fengine);
end.
