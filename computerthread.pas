unit computerthread;

{$mode objfpc}{$h+}

interface

uses
  mseclasses,
  msethread,
  game,
  computer;

type
  tcomputerthread = class(tmsethread)
  private
    fgame: tgame;
    fclient: tmsecomponent;
    ftag: integer;
    fturn: turnty;
    fdone: boolean;
  protected
    function execute(thread: tmsethread): integer; override;
  public
    constructor create(const agame: tgame; const aclient: tmsecomponent; const atag: integer); reintroduce;
    destructor destroy(); override;
    property turn: turnty read fturn;
    property done: boolean read fdone;
  end;

implementation

constructor tcomputerthread.create(const agame: tgame; const aclient: tmsecomponent; const atag: integer);
begin
  fgame := tgame.createcopy(agame);
  fclient := aclient;
  ftag := atag;
  preparethinking();
  inherited create();
end;

destructor tcomputerthread.destroy();
begin
  inherited;
  fgame.free;
end;

function tcomputerthread.execute(thread: tmsethread): integer;
begin
  fturn := chooseturn(fgame);
  if not terminated then
  begin
    fdone := true;
    fclient.asyncevent(ftag);
  end;
  result := 0;
end;

end.
