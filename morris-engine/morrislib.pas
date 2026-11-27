unit morrislib;

{$mode objfpc}{$h+}

interface

uses
  ctypes;

const
  morrispoints = 24;

  morris_ok = 0;
  morris_no_move = -1;
  morris_invalid = -2;
  morris_error = -3;

{$ifdef windows}
  morrislibname = 'morris-engine.dll';
{$else}
  morrislibname = 'libmorris-engine.so';
{$endif}

type
  pmorrisengine = type pointer;
  tmorrispoints = array[0..morrispoints - 1] of cint;

var
  morris_name: function(): pchar; cdecl;
  morris_version: function(): pchar; cdecl;
  morris_create: function(): pmorrisengine; cdecl;
  morris_destroy: procedure(engine: pmorrisengine); cdecl;
  morris_new_game: procedure(engine: pmorrisengine); cdecl;
  morris_set_time: procedure(engine: pmorrisengine; msec: cint); cdecl;
  morris_set_depth: procedure(engine: pmorrisengine; depth: cint); cdecl;
  morris_stop: procedure(engine: pmorrisengine); cdecl;
  morris_choose: function(engine: pmorrisengine; points: pcint;
    hand_white, hand_black, side: cint;
    out source, target, capture: cint): cint; cdecl;

function loadmorrisengine(const afilename: string = ''): boolean;
procedure unloadmorrisengine();
function morrisengineloaded(): boolean;

implementation

uses
  sysutils,
  dynlibs;

var
  libhandle: tlibhandle = nilhandle;

procedure clearentries();
begin
  morris_name := nil;
  morris_version := nil;
  morris_create := nil;
  morris_destroy := nil;
  morris_new_game := nil;
  morris_set_time := nil;
  morris_set_depth := nil;
  morris_stop := nil;
  morris_choose := nil;
end;

function bind(const aname: string; out aentry): boolean;
var
  p: pointer;
begin
  p := getprocedureaddress(libhandle, aname);
  pointer(aentry) := p;
  result := p <> nil;
end;

function loadmorrisengine(const afilename: string): boolean;
var
  ok: boolean;
begin
  if libhandle <> nilhandle then
    exit(true);
  if afilename <> '' then
    libhandle := loadlibrary(afilename)
  else
  begin
    libhandle := loadlibrary(extractfilepath(paramstr(0)) + morrislibname);
    if libhandle = nilhandle then
      libhandle := loadlibrary(morrislibname);
  end;
  if libhandle = nilhandle then
    exit(false);
  ok := bind('morris_name', morris_name);
  ok := bind('morris_version', morris_version) and ok;
  ok := bind('morris_create', morris_create) and ok;
  ok := bind('morris_destroy', morris_destroy) and ok;
  ok := bind('morris_new_game', morris_new_game) and ok;
  ok := bind('morris_set_time', morris_set_time) and ok;
  ok := bind('morris_set_depth', morris_set_depth) and ok;
  ok := bind('morris_stop', morris_stop) and ok;
  ok := bind('morris_choose', morris_choose) and ok;
  if not ok then
    unloadmorrisengine();
  result := ok;
end;

procedure unloadmorrisengine();
begin
  if libhandle <> nilhandle then
    freelibrary(libhandle);
  libhandle := nilhandle;
  clearentries();
end;

function morrisengineloaded(): boolean;
begin
  result := libhandle <> nilhandle;
end;

finalization
  unloadmorrisengine();
end.
