unit morris;

{$mode objfpc}{$h+}

interface

uses
  game,
  engineclass,
  morrislib;

type
  tmorrisengine = class(tengine)
  private
    fengine: pmorrisengine;
  public
    constructor create(const aengine: pmorrisengine);
    class function createengine(): tmorrisengine;
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

class function tmorrisengine.createengine(): tmorrisengine;
var
  e: pmorrisengine;
begin
  result := nil;
  if not loadmorrisengine() then
    exit;
  e := morris_create();
  if e <> nil then
    result := tmorrisengine.create(e);
end;

constructor tmorrisengine.create(const aengine: pmorrisengine);
begin
  inherited create();
  fengine := aengine;
  morris_set_time(fengine, fthinkingtime);
end;

destructor tmorrisengine.destroy();
begin
  morris_destroy(fengine);
  inherited;
end;

function tmorrisengine.name(): unicodestring;
begin
  result := unicodestring(utf8string(morris_name())) + ' ' + unicodestring(utf8string(morris_version()));
end;

procedure tmorrisengine.setthinkingtime(const amsec: integer);
begin
  inherited;
  morris_set_time(fengine, fthinkingtime);
end;

procedure tmorrisengine.newgame();
begin
  morris_new_game(fengine);
end;

procedure tmorrisengine.abortthinking();
begin
  inherited;
  morris_stop(fengine);
end;

function tmorrisengine.chooseturn(const agame: tgame): turnty;
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
