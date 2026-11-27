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

function setengine(const aengine: enginety): boolean;
function currentengine(): enginety;
procedure setthinkingtime(const amsec: integer);
function thinkingtime(): integer;
function enginename(): unicodestring;
function enginefullname(): unicodestring;
procedure newgame();
procedure preparethinking();
procedure abortthinking();
function chooseturn(const agame: tgame): turnty;

implementation

uses
  alea,
  morrisplayer;

var
  fengine: enginety = en_builtin;
  fthinkingtime: integer = defaultthinkingtime;

function setengine(const aengine: enginety): boolean;
begin
  if (aengine = en_morris) and not morrisplayer.loadengine() then
    exit(false);
  fengine := aengine;
  result := true;
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
  alea.setthinkingtime(fthinkingtime);
  morrisplayer.setthinkingtime(fthinkingtime);
end;

function thinkingtime(): integer;
begin
  result := fthinkingtime;
end;

function enginename(): unicodestring;
begin
  case fengine of
    en_morris:
      result := morrisplayer.enginename();
  else
    result := alea.enginename();
  end;
end;

function enginefullname(): unicodestring;
begin
  case fengine of
    en_morris:
      result := morrisplayer.enginename() + ' ' + morrisplayer.engineversion();
  else
    result := alea.enginename() + ' ' + alea.engineversion();
  end;
end;

procedure newgame();
begin
  alea.newgame();
  morrisplayer.newgame();
end;

procedure preparethinking();
begin
  alea.preparethinking();
  morrisplayer.preparethinking();
end;

procedure abortthinking();
begin
  alea.abortthinking();
  morrisplayer.abortthinking();
end;

function chooseturn(const agame: tgame): turnty;
begin
  if (fengine = en_morris) and (agame.phase <> ph_remove) then
    result := morrisplayer.chooseturn(agame)
  else
    result := alea.chooseturn(agame);
end;

end.
