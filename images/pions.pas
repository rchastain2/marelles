program pions;

{$mode objfpc}{$h+}

uses
{$ifdef unix}
  cthreads,
{$endif}
  agg_2D,
  agg_basics,
  alphabitmap,
  piecedraw;

const
  size = 48;
  radius = 22;
  smallsize = 14;
  smallradius = 6.5;
  filenames: array[0..1] of string = ('blanc.png', 'noir.png');
  smallfilenames: array[0..1] of string = ('petitblanc.png', 'petitnoir.png');
  pieces: array[0..1] of ^piecety = (@whitepiece, @blackpiece);

var
  current: integer;

procedure draw(const agg: agg2d_ptr; const asize: integer);
begin
  drawpiece(agg, asize / 2, asize / 2, radius, pieces[current]^);
end;

procedure drawsmall(const agg: agg2d_ptr; const asize: integer);
begin
  drawpiece(agg, asize / 2, asize / 2, smallradius, pieces[current]^, false);
end;

begin
  for current := low(filenames) to high(filenames) do
  begin
    writealphaimage(filenames[current], size, @draw);
    writealphaimage(smallfilenames[current], smallsize, @drawsmall);
  end;
end.
