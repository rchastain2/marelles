unit computer;

{$mode objfpc}{$h+}

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
  engine,
  alea,
  morrisplayer;

var
  fengine: tengine = nil;
  fthinkingtime: integer = defaultthinkingtime;

function setengine(const aengine: enginety): boolean;
var
  e: tengine;
begin
  case aengine of
    en_morris:
      e := tmorrisplayer.createengine();
  else
    e := taleaengine.create();
  end;
  result := e <> nil;
  if result then
  begin
    fengine.free;
    fengine := e;
    fengine.setthinkingtime(fthinkingtime);
  end;
end;

procedure setthinkingtime(const amsec: integer);
begin
  if amsec < minthinkingtime then
    fthinkingtime := minthinkingtime
  else if amsec > maxthinkingtime then
    fthinkingtime := maxthinkingtime
  else
    fthinkingtime := amsec;
  fengine.setthinkingtime(fthinkingtime);
end;

function thinkingtime(): integer;
begin
  result := fthinkingtime;
end;

function enginename(): unicodestring;
begin
  result := fengine.name();
end;

function enginefullname(): unicodestring;
begin
  result := fengine.name() + ' ' + fengine.version();
end;

procedure newgame();
begin
  fengine.newgame();
end;

procedure preparethinking();
begin
  fengine.preparethinking();
end;

procedure abortthinking();
begin
  fengine.abortthinking();
end;

function chooseturn(const agame: tgame): turnty;
begin
  result := fengine.chooseturn(agame);
end;

initialization
  setengine(en_builtin);

finalization
  fengine.free;
end.
