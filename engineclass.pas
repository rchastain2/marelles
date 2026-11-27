unit engineclass;

{$mode objfpc}{$h+}

interface

uses
  game;

type
  tengine = class
  protected
    fthinkingtime: integer;
    fstop: boolean;
  public
    constructor create();
    function name(): unicodestring; virtual; abstract;
    procedure setthinkingtime(const amsec: integer); virtual;
    procedure newgame(); virtual;
    procedure preparethinking(); virtual;
    procedure abortthinking(); virtual;
    function chooseturn(const agame: tgame): turnty; virtual; abstract;
  end;

implementation

constructor tengine.create();
begin
  inherited create();
  fthinkingtime := 1500;
  fstop := false;
end;

procedure tengine.setthinkingtime(const amsec: integer);
begin
  fthinkingtime := amsec;
end;

procedure tengine.newgame();
begin
end;

procedure tengine.preparethinking();
begin
  fstop := false;
end;

procedure tengine.abortthinking();
begin
  fstop := true;
end;

end.
