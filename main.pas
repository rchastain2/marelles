unit main;

{$mode objfpc}{$h+}{$codepage utf8}

interface

uses
  msetypes,
  mseglob,
  mseguiglob,
  mseguiintf,
  mseapplication,
  msestat,
  msestatfile,
  msemenus,
  msegui,
  msegraphics,
  msegraphutils,
  mseevent,
  mseclasses,
  msewidgets,
  mseforms,
  msesimplewidgets,
  msebitmap,
  mseactions,
  game,
  computer,
  computerthread,
  logfile,
  morrislib;

const
  appversion = '1.1';
  cellsize = 64;
  piecesize = 48;
  containerheight = 551;
  cardx = 8;
  cardwidth = 136;
  cardheight = 160;
  cardys: array[1..2] of integer = (8, 344);
  framemargin = 4;
  slotsize = 14;
  textcolor = $3C2814;

type
  tmainfo = class(tmainform)
    board: tpaintbox;
    statuslb: tlabel;
    panel: tpaintbox;
    menubar: tmainmenu;
    popupitemframe: tframecomp;
    popupitemframeactive: tframecomp;
    popupframe: tframecomp;
    baritemframe: tframecomp;
    baritemframeactive: tframecomp;
    separatorframe: tframecomp;
    barface: tfacecomp;
    activeface: tfacecomp;
    popupface: tfacecomp;
    newgameact: taction;
    playact: taction;
    autoplayact: taction;
    quitact: taction;
    mainstat: tstatfile;
    aboutact: taction;
    procedure createev(const sender: TObject);
    procedure destroyev(const sender: TObject);
    procedure paintev(const sender: twidget; const acanvas: tcanvas);
    procedure panelpaintev(const sender: twidget; const acanvas: tcanvas);
    procedure mouseev(const sender: twidget; var ainfo: mouseeventinfoty);
    procedure newgameev(const sender: TObject);
    procedure playev(const sender: TObject);
    procedure autoplayev(const sender: TObject);
    procedure quitev(const sender: TObject);
    procedure aboutev(const sender: TObject);
    procedure statafterreadev(const sender: TObject);
  private
    fplateau: tmaskedbitmap;
    fpieces: array[1..2] of tmaskedbitmap;
    fselection: tmaskedbitmap;
    fdestination: tmaskedbitmap;
    fcapture: tmaskedbitmap;
    fpanel: tmaskedbitmap;
    fcardframe: tmaskedbitmap;
    fsmallpieces: array[1..2] of tmaskedbitmap;
    fslot: tmaskedbitmap;
    fgame: tgame;
    fselected: integer;
    fdragging: boolean;
    fdragoffset: pointty;
    fdragpos: pointty;
    fcomputer: integer;
    fthread: tcomputerthread;
    function readoptions(): msestring;
    procedure initgame();
    procedure updatestatus();
    function phasename(const aplayer: integer): msestring;
    procedure paintcard(const acanvas: tcanvas; const aplayer: integer);
    procedure clickpoint(const aindex: integer);
    procedure checkcomputer();
    procedure setcomputer(const aplayer: integer);
    procedure updatecomputer();
    function playerprompt(const atext: msestring): msestring;
    procedure startthinking();
    procedure finishturn();
    procedure stopthinking();
    function pointcenter(const aindex: integer): pointty;
    procedure paintcentered(const acanvas: tcanvas; const abitmap: tmaskedbitmap; const acenter: pointty);
    function pointatpos(const apos: pointty): integer;
  protected
    procedure doasyncevent(var atag: integer); override;
  end;

var
  mainfo: tmainfo;

implementation

uses
  sysutils,
  main_mfm,
  msedrawtext,
  msefileutils,
  msesysintf,
  mseformatpngread;

const
  playernames: array[1..2] of msestring = ('Blancs', 'Noirs');

  tag_startturn = 0;
  tag_turnready = 1;

procedure tmainfo.createev(const sender: TObject);
var
  dir: filenamety;
  msg: msestring;
begin
  writelog('Marelles ' + appversion + ', compilé le ' + {$i %date%} + ' avec FPC ' + {$i %fpcversion%}, true);
  msg := readoptions();
  writelog('Adversaire : ' + string(enginename) + format(', temps de réflexion : %d ms', [thinkingtime]));
  dir := filedir(sys_getapplicationpath) + 'images/';
  fplateau := tmaskedbitmap.create(bmk_rgb);
  fplateau.loadfromfile(dir + 'plateau.png');
  fpieces[1] := tmaskedbitmap.create(bmk_rgb);
  fpieces[1].loadfromfile(dir + 'blanc.png');
  fpieces[2] := tmaskedbitmap.create(bmk_rgb);
  fpieces[2].loadfromfile(dir + 'noir.png');
  fselection := tmaskedbitmap.create(bmk_rgb);
  fselection.loadfromfile(dir + 'selection.png');
  fdestination := tmaskedbitmap.create(bmk_rgb);
  fdestination.loadfromfile(dir + 'destination.png');
  fcapture := tmaskedbitmap.create(bmk_rgb);
  fcapture.loadfromfile(dir + 'prise.png');
  fpanel := tmaskedbitmap.create(bmk_rgb);
  fpanel.loadfromfile(dir + 'panneau.png');
  fcardframe := tmaskedbitmap.create(bmk_rgb);
  fcardframe.loadfromfile(dir + 'cadre.png');
  fsmallpieces[1] := tmaskedbitmap.create(bmk_rgb);
  fsmallpieces[1].loadfromfile(dir + 'petitblanc.png');
  fsmallpieces[2] := tmaskedbitmap.create(bmk_rgb);
  fsmallpieces[2].loadfromfile(dir + 'petitnoir.png');
  fslot := tmaskedbitmap.create(bmk_rgb);
  fslot.loadfromfile(dir + 'emplacement.png');
  icon.loadfromfile(dir + 'icone48.png');
  writelog(format('Hauteur de la barre de menu : %d px, correction : %d px', [container.bounds_y, containerheight - container.bounds_cy]));
  bounds_cy := bounds_cy + containerheight - container.bounds_cy;
  caption := 'Marelles ' + appversion;
  fgame := tgame.create();
  fcomputer := 0;
  updatecomputer();
  initgame();
  if msg <> '' then
    statuslb.caption := msg;
end;

function tmainfo.readoptions(): msestring;
var
  i, n: integer;
  s: string;
  wantmorris: boolean;
begin
  result := '';
  wantmorris := false;
  for i := 1 to paramcount do
  begin
    s := paramstr(i);
    if s = '--engine=builtin' then
      wantmorris := false
    else if s = '--engine=morris' then
      wantmorris := true
    else if copy(s, 1, 7) = '--time=' then
    begin
      if trystrtoint(copy(s, 8, maxint), n) and (n >= minthinkingtime) and (n <= maxthinkingtime) then
        setthinkingtime(n)
      else
        writelog(format('Valeur incorrecte : %s (entre %d et %d ms)', [s, minthinkingtime, maxthinkingtime]));
    end
    else
      writelog('Option inconnue : ' + s);
  end;
  if wantmorris and not setengine(en_morris) then
  begin
    writelog('Morris Engine introuvable (' + morrislibname + ')');
    result := 'Morris Engine introuvable : ' + enginename + ' le remplace';
  end;
end;

procedure tmainfo.destroyev(const sender: TObject);
begin
  writelog('Fin');
  stopthinking();
  fgame.free;
  fplateau.free;
  fpieces[1].free;
  fpieces[2].free;
  fselection.free;
  fdestination.free;
  fcapture.free;
  fpanel.free;
  fcardframe.free;
  fsmallpieces[1].free;
  fsmallpieces[2].free;
  fslot.free;
end;

procedure tmainfo.initgame();
begin
  stopthinking();
  computer.newgame();
  fgame.init();
  writelog('Nouvelle partie');
  if fcomputer <> 0 then
    writelog(string(enginename) + ' joue les ' + string(playernames[fcomputer]));
  fselected := -1;
  fdragging := false;
  updatestatus();
  board.invalidate();
  checkcomputer();
end;

procedure tmainfo.updatestatus();
var
  s: msestring;
begin
  if fthread <> nil then
    s := enginename + ' réfléchit...'
  else
    case fgame.phase of
      ph_place:
        s := playerprompt('placez un pion');
      ph_move:
        if fselected < 0 then
          s := playerprompt('déplacez un pion')
        else
          s := playerprompt('choisissez la destination');
      ph_remove:
        s := playerprompt('enlevez un pion adverse');
      ph_over:
        if fcomputer = 0 then
          s := 'Les ' + playernames[fgame.winner] + ' ont gagné !'
        else if fgame.winner = fcomputer then
          s := enginename + ' a gagné !'
        else
          s := 'Vous avez gagné !';
    end;
  statuslb.caption := s;
  panel.invalidate();
  playact.enabled := not (fgame.phase in [ph_remove, ph_over]) and (fthread = nil);
end;

function tmainfo.phasename(const aplayer: integer): msestring;
begin
  if fgame.phase = ph_over then
    result := 'terminée'
  else if fgame.hand[aplayer] > 0 then
    result := 'pose'
  else if fgame.mayjump(aplayer) then
    result := 'vol'
  else
    result := 'déplacement';
end;

procedure tmainfo.paintcard(const acanvas: tcanvas; const aplayer: integer);
var
  x, y, i: integer;

  procedure drawrow(const atop: integer; const alabel, avalue: msestring);
  begin
    drawtext(acanvas, alabel, mr(x + 8, atop, cardwidth - 16, 16), [tf_ycentered]);
    if avalue <> '' then
      drawtext(acanvas, avalue, mr(x + 8, atop, cardwidth - 16, 16), [tf_right, tf_ycentered]);
  end;

begin
  x := cardx;
  y := cardys[aplayer];
  if (aplayer = fgame.player) and (fgame.phase <> ph_over) then
    fcardframe.paint(acanvas, mp(x - framemargin, y - framemargin));
  fpieces[aplayer].paint(acanvas, mp(x + 8, y + 8));
  acanvas.font.color := textcolor;
  acanvas.font.height := 18;
  acanvas.font.style := [fs_bold];
  drawtext(acanvas, playernames[aplayer], mr(x + 64, y + 8, cardwidth - 72, 48), [tf_ycentered]);
  acanvas.font.height := 13;
  acanvas.font.style := [];
  drawrow(y + 64, 'Réserve', '');
  for i := 0 to piecesperplayer - 1 do
    if i < fgame.hand[aplayer] then
      fsmallpieces[aplayer].paint(acanvas, mp(x + 5 + i * slotsize, y + 84))
    else
      fslot.paint(acanvas, mp(x + 5 + i * slotsize, y + 84));
  drawrow(y + 108, 'Sur le plateau', msestring(inttostr(fgame.countpieces(aplayer))));
  drawrow(y + 132, 'Phase', phasename(aplayer));
end;

procedure tmainfo.panelpaintev(const sender: twidget; const acanvas: tcanvas);
begin
  fpanel.paint(acanvas, nullpoint);
  paintcard(acanvas, 1);
  paintcard(acanvas, 2);
end;

function tmainfo.pointcenter(const aindex: integer): pointty;
begin
  result.x := coords[aindex, 0] * cellsize;
  result.y := coords[aindex, 1] * cellsize;
end;

procedure tmainfo.paintcentered(const acanvas: tcanvas; const abitmap: tmaskedbitmap; const acenter: pointty);
begin
  abitmap.paint(acanvas, mp(acenter.x - abitmap.width div 2, acenter.y - abitmap.height div 2));
end;

function tmainfo.pointatpos(const apos: pointty): integer;
var
  i: integer;
  c: pointty;
begin
  for i := 0 to pointcount - 1 do
  begin
    c := pointcenter(i);
    if (abs(apos.x - c.x) < piecesize div 2) and (abs(apos.y - c.y) < piecesize div 2) then
      exit(i);
  end;
  result := -1;
end;

procedure tmainfo.clickpoint(const aindex: integer);
begin
  writelog(format('Clic sur le point %d', [aindex]));
  case fgame.phase of
    ph_place:
      fgame.place(aindex);
    ph_move:
      if fgame.points[aindex] = fgame.player then
      begin
        fselected := aindex;
        writelog(format('Sélection du pion %d', [aindex]));
      end
      else
      begin
        if fselected >= 0 then
          fgame.move(fselected, aindex);
        fselected := -1;
      end;
    ph_remove:
      fgame.remove(aindex);
  end;
  updatestatus();
  board.invalidate();
  checkcomputer();
end;

procedure tmainfo.setcomputer(const aplayer: integer);
begin
  if aplayer = fcomputer then
    exit;
  stopthinking();
  fcomputer := aplayer;
  if fcomputer = 0 then
    writelog('L''ordinateur ne joue plus')
  else
    writelog(string(enginename) + ' joue les ' + string(playernames[fcomputer]));
  updatestatus();
end;

procedure tmainfo.updatecomputer();
begin
  if autoplayact.checked then
    setcomputer(3 - fgame.player)
  else
    setcomputer(0);
end;

function tmainfo.playerprompt(const atext: msestring): msestring;
begin
  result := playernames[fgame.player] + ' : ' + atext;
end;

procedure tmainfo.checkcomputer();
begin
  if (fcomputer = fgame.player) and (fgame.phase <> ph_over) then
    asyncevent();
end;

procedure tmainfo.doasyncevent(var atag: integer);
begin
  inherited;
  case atag of
    tag_startturn:
      if (fthread = nil) and (fcomputer = fgame.player) and (fgame.phase <> ph_over) then
        startthinking();
    tag_turnready:
      finishturn();
  end;
end;

procedure tmainfo.startthinking();
begin
  fselected := -1;
  fdragging := false;
  writelog('Tour de l''ordinateur (' + string(playernames[fgame.player]) + ')');
  fthread := tcomputerthread.create(fgame, self, tag_turnready);
  updatestatus();
  board.invalidate();
end;

procedure tmainfo.finishturn();
var
  t: turnty;
begin
  if (fthread = nil) or not fthread.done then
    exit;
  t := fthread.turn;
  application.waitforthread(fthread);
  freeandnil(fthread);
  if t.target < 0 then
    writelog('L''ordinateur ne trouve aucune action')
  else
    case fgame.phase of
      ph_place:
        fgame.place(t.target);
      ph_move:
        fgame.move(t.source, t.target);
      ph_remove:
        fgame.remove(t.target);
    end;
  if (fgame.phase = ph_remove) and (t.capture >= 0) then
    fgame.remove(t.capture);
  updatestatus();
  board.invalidate();
  checkcomputer();
end;

procedure tmainfo.stopthinking();
begin
  if fthread = nil then
    exit;
  writelog('Calcul de l''ordinateur interrompu');
  abortthinking();
  fthread.terminate();
  application.waitforthread(fthread);
  freeandnil(fthread);
end;

procedure tmainfo.paintev(const sender: twidget; const acanvas: tcanvas);
var
  i: integer;
  c: pointty;
begin
  fplateau.paint(acanvas, nullpoint);
  for i := 0 to pointcount - 1 do
  begin
    c := pointcenter(i);
    if (fgame.points[i] <> 0) and not (fdragging and (i = fselected)) then
      paintcentered(acanvas, fpieces[fgame.points[i]], c);
    if (fgame.phase = ph_remove) and fgame.maytake(i) then
      paintcentered(acanvas, fcapture, c)
    else if (fgame.phase = ph_move) and (fselected >= 0) and fgame.maymove(fselected, i) then
      paintcentered(acanvas, fdestination, c);
  end;
  if (fgame.phase = ph_move) and (fselected >= 0) then
    paintcentered(acanvas, fselection, pointcenter(fselected));
  if fdragging then
    paintcentered(acanvas, fpieces[fgame.player], subpoint(fdragpos, fdragoffset));
end;

procedure tmainfo.mouseev(const sender: twidget; var ainfo: mouseeventinfoty);
var
  i: integer;
begin
  if (fgame.phase = ph_over) or (fcomputer = fgame.player) or (fthread <> nil) then
    exit;
  case ainfo.eventkind of
    ek_buttonpress:
      if ainfo.button = mb_left then
      begin
        i := pointatpos(ainfo.pos);
        if (fgame.phase = ph_move) and (i >= 0) and (fgame.points[i] = fgame.player) then
        begin
          fselected := i;
          fdragging := true;
          fdragoffset := subpoint(ainfo.pos, pointcenter(i));
          fdragpos := ainfo.pos;
          updatestatus();
          board.invalidate();
        end;
      end;
    ek_mousemove:
      if fdragging then
      begin
        fdragpos := ainfo.pos;
        board.invalidate();
      end;
    ek_buttonrelease:
      if ainfo.button = mb_left then
      begin
        i := pointatpos(ainfo.pos);
        if fdragging then
        begin
          fdragging := false;
          if (i >= 0) and (i <> fselected) then
            clickpoint(i)
          else
            board.invalidate();
        end else if i >= 0 then
          clickpoint(i)
        else if fselected >= 0 then
        begin
          fselected := -1;
          updatestatus();
          board.invalidate();
        end;
      end;
  end;
end;

procedure tmainfo.newgameev(const sender: TObject);
begin
  initgame();
end;

procedure tmainfo.playev(const sender: TObject);
begin
  writelog('Commande Jouer');
  if (fgame.phase in [ph_remove, ph_over]) or (fthread <> nil) then
    exit;
  if autoplayact.checked then
  begin
    setcomputer(fgame.player);
    checkcomputer();
  end
  else
    startthinking();
end;

procedure tmainfo.autoplayev(const sender: TObject);
begin
  if autoplayact.checked then
    writelog('Réponse automatique activée')
  else
    writelog('Réponse automatique désactivée');
  updatecomputer();
  checkcomputer();
end;

procedure tmainfo.quitev(const sender: TObject);
begin
  writelog('Commande Quitter');
  close();
end;

procedure tmainfo.aboutev(const sender: TObject);
begin
  writelog('Commande À propos');
  showmessage(
    'Marelles ' + appversion + lineend + lineend +
    'Compilé le ' + {$i %date%} + ' avec FPC ' + {$i %fpcversion%} + ' et MSEgui ' + mseguiversiontext + '.' + lineend + lineend +
    'Adversaire : ' + enginename + ', temps de réflexion : ' + msestring(inttostr(thinkingtime)) + ' ms.',
    'À propos'
  );
end;

procedure tmainfo.statafterreadev(const sender: TObject);
begin
  if fgame = nil then
    exit;
  if autoplayact.checked then
    writelog('Réglages relus : réponse automatique activée')
  else
    writelog('Réglages relus : réponse automatique désactivée');
  updatecomputer();
  checkcomputer();
end;

end.
