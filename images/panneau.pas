program panneau;

{$mode objfpc}{$h+}

uses
{$ifdef unix}
  cthreads,
{$endif}
  msetypes,
  msegraphutils,
  msegraphics,
  msebitmap,
  mseformatpngread,
  mseformatpngwrite,
  agg_2D,
  agg_basics,
  alphabitmap;

const
  texture = 'wood2.png';
  filename = 'panneau.png';
  panelwidth = 152;
  panelheight = 512;
  cardx = 8;
  cardwidth = 136;
  cardheight = 160;
  cardys: array[0..1] of integer = (8, 344);
  cardradius = 8;
  framemargin = 4;
  slotsize = 14;
  slotradius = 5.5;

procedure drawcards(const abitmap: tmaskedbitmap);
var
  agg: agg2d_ptr;
  i: integer;
  x1, y1, x2, y2: double;
begin
  new(agg, construct);
  agg^.attach(pbyte(abitmap.scanline[0]), abitmap.width, abitmap.height, abitmap.scanlinestep);
  for i := low(cardys) to high(cardys) do
  begin
    x1 := cardx + 0.5;
    y1 := cardys[i] + 0.5;
    x2 := cardx + cardwidth - 0.5;
    y2 := cardys[i] + cardheight - 0.5;
    agg^.noLine();
    agg^.fillColor(0, 0, 0, 50);
    agg^.roundedRect(x1 + 2, y1 + 3, x2 + 2, y2 + 3, cardradius);
    agg^.fillColor(250, 242, 222, 215);
    agg^.lineColor(90, 60, 30, 170);
    agg^.lineWidth(1.2);
    agg^.roundedRect(x1, y1, x2, y2, cardradius);
  end;
  dispose(agg, destruct);
end;

procedure crop(const asource, adest: tmaskedbitmap);
var
  x, y: integer;
  s, d: prgbtriplety;
begin
  adest.size := makesize(panelwidth, panelheight);
  for y := 0 to panelheight - 1 do
  begin
    s := asource.scanline[y];
    d := adest.scanline[y];
    for x := 0 to panelwidth - 1 do
    begin
      d^ := s^;
      inc(s);
      inc(d);
    end;
  end;
end;

procedure drawframe(const agg: agg2d_ptr; const awidth, aheight: integer);
var
  m: double;
begin
  m := framemargin;
  agg^.noFill();
  agg^.lineColor(46, 184, 72, 70);
  agg^.lineWidth(6);
  agg^.roundedRect(m, m, awidth - m, aheight - m, cardradius);
  agg^.lineColor(46, 184, 72);
  agg^.lineWidth(3);
  agg^.roundedRect(m, m, awidth - m, aheight - m, cardradius);
end;

procedure drawslot(const agg: agg2d_ptr; const asize: integer);
begin
  agg^.fillColor(90, 60, 30, 40);
  agg^.lineColor(90, 60, 30, 130);
  agg^.lineWidth(1);
  agg^.ellipse(asize / 2, asize / 2, slotradius, slotradius);
end;

var
  wood, panel: tmaskedbitmap;

begin
  wood := tmaskedbitmap.create(bmk_rgb);
  panel := tmaskedbitmap.create(bmk_rgb);
  try
    wood.loadfromfile(msestring(texture));
    wood.masked := false;
    if (wood.width < panelwidth) or (wood.height < panelheight) then
    begin
      writeln(stderr, 'Unexpected texture size: ', wood.width, 'x', wood.height);
      halt(1);
    end;
    crop(wood, panel);
    drawcards(panel);
    panel.writetofile(msestring(filename), 'png', []);
    writeln('Written: ', filename);
  finally
    wood.free;
    panel.free;
  end;
  writealphaimage('cadre.png', cardwidth + 2 * framemargin, cardheight + 2 * framemargin, @drawframe);
  writealphaimage('emplacement.png', slotsize, @drawslot);
end.
