unit morrisplayer;

{$mode objfpc}{$h+}

interface

uses
  game,
  engine,
  morrisengine;

type
  tmorrisplayer = class(tengine)
  private
    fengine: pmorrisengine;
  public
    constructor create(const aengine: pmorrisengine);
    class function createengine(): tmorrisplayer;
    destructor destroy(); override;
    function name(): unicodestring; override;
    procedure setthinkingtime(const amsec: integer); override;
    procedure newgame(); override;
    procedure abortthinking(); override;
    function chooseturn(const agame: tgame): turnty; override;
  end;

implementation

uses
  ctypes;

class function tmorrisplayer.createengine(): tmorrisplayer;
var
  e: pmorrisengine;
begin
  result := nil;
  if not loadmorrisengine() then
    exit;
  e := morris_create();
  if e <> nil then
    result := tmorrisplayer.create(e);
end;

constructor tmorrisplayer.create(const aengine: pmorrisengine);
begin
  inherited create();
  fengine := aengine;
  morris_set_time(fengine, fthinkingtime);
end;

destructor tmorrisplayer.destroy();
begin
  morris_destroy(fengine);
  inherited;
end;

function tmorrisplayer.name(): unicodestring;
begin
  result := unicodestring(utf8string(morris_name())) + ' ' + unicodestring(utf8string(morris_version()));
end;

procedure tmorrisplayer.setthinkingtime(const amsec: integer);
begin
  inherited;
  morris_set_time(fengine, fthinkingtime);
end;

procedure tmorrisplayer.newgame();
begin
  morris_new_game(fengine);
end;

procedure tmorrisplayer.abortthinking();
begin
  inherited;
  morris_stop(fengine);
end;

function tmorrisplayer.chooseturn(const agame: tgame): turnty;
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
  if morris_choose(fengine, @points[0], agame.hand[1], agame.hand[2], agame.player, source, target, capture) = morris_ok then
  begin
    result.source := source;
    result.target := target;
    result.capture := capture;
  end;
end;

end.
