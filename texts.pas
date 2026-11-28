unit texts;

{$mode objfpc}{$h+}{$codepage utf8}

interface

uses
  msetypes,
  msestrings;

resourcestring
  rs_white = 'Blancs';
  rs_black = 'Noirs';
  rs_prompt = '%s : %s';
  rs_placepiece = 'placez un pion';
  rs_movepiece = 'déplacez un pion';
  rs_choosedestination = 'choisissez la destination';
  rs_removepiece = 'enlevez un pion adverse';
  rs_whitewins = 'Les Blancs ont gagné !';
  rs_blackwins = 'Les Noirs ont gagné !';
  rs_enginewins = '%s a gagné !';
  rs_youwin = 'Vous avez gagné !';
  rs_enginethinking = '%s réfléchit...';
  rs_enginenotfound = 'Morris Engine introuvable : %s le remplace';
  rs_reserve = 'Réserve';
  rs_onboard = 'Sur le plateau';
  rs_phase = 'Phase';
  rs_phaseplace = 'pose';
  rs_phasemove = 'déplacement';
  rs_phasejump = 'vol';
  rs_phaseover = 'terminée';
  rs_abouttitle = 'À propos';
  rs_aboutbuild = 'Compilé le %s avec FPC %s et MSEgui %s.';
  rs_aboutengine = 'Adversaire : %s, temps de réflexion : %d ms.';

function colortext(const aplayer: integer): msestring;
function prompttext(const aplayer: integer; const aaction: string): msestring;
function wintext(const aplayer: integer): msestring;
function enginewinstext(const aname: msestring): msestring;
function thinkingtext(const aname: msestring): msestring;
function enginenotfoundtext(const aname: msestring): msestring;
function aboutbuildtext(const adate, afpcversion, amseversion: msestring): msestring;
function aboutenginetext(const aname: msestring; const atime: integer): msestring;

implementation

uses
  sysutils;

function colortext(const aplayer: integer): msestring;
begin
  if aplayer = 1 then
    result := rs(rs_white)
  else
    result := rs(rs_black);
end;

function prompttext(const aplayer: integer; const aaction: string): msestring;
begin
  result := unicodeformat(rs(rs_prompt), [colortext(aplayer), rs(aaction)]);
end;

function wintext(const aplayer: integer): msestring;
begin
  if aplayer = 1 then
    result := rs(rs_whitewins)
  else
    result := rs(rs_blackwins);
end;

function enginewinstext(const aname: msestring): msestring;
begin
  result := unicodeformat(rs(rs_enginewins), [aname]);
end;

function thinkingtext(const aname: msestring): msestring;
begin
  result := unicodeformat(rs(rs_enginethinking), [aname]);
end;

function enginenotfoundtext(const aname: msestring): msestring;
begin
  result := unicodeformat(rs(rs_enginenotfound), [aname]);
end;

function aboutbuildtext(const adate, afpcversion, amseversion: msestring): msestring;
begin
  result := unicodeformat(rs(rs_aboutbuild), [adate, afpcversion, amseversion]);
end;

function aboutenginetext(const aname: msestring; const atime: integer): msestring;
begin
  result := unicodeformat(rs(rs_aboutengine), [aname, atime]);
end;

end.
