unit alphabitmap;

{$mode objfpc}{$h+}

interface

uses
  msetypes,
  msegraphutils,
  msegraphics,
  msebitmap,
  mseformatpngwrite,
  agg_2D;

type
  drawproc = procedure(const agg: agg2d_ptr; const asize: integer);
  drawrectproc = procedure(const agg: agg2d_ptr; const awidth, aheight: integer);

procedure writealphaimage(const afilename: string; const asize: integer; const adraw: drawproc); overload;
procedure writealphaimage(const afilename: string; const awidth, aheight: integer; const adraw: drawrectproc); overload;

implementation

procedure extractalpha(const abitmap: tmaskedbitmap);
var
  x, y: integer;
  p: prgbtriplety;
  m: pbyte;
begin
  for y := 0 to abitmap.height - 1 do
  begin
    p := abitmap.scanline[y];
    m := abitmap.mask.scanline[y];
    for x := 0 to abitmap.width - 1 do
    begin
      m^ := p^.res;
      if p^.res > 0 then
      begin
        p^.red := p^.red * 255 div p^.res;
        p^.green := p^.green * 255 div p^.res;
        p^.blue := p^.blue * 255 div p^.res;
      end;
      p^.res := 0;
      inc(p);
      inc(m);
    end;
  end;
end;

function beginimage(const awidth, aheight: integer; out abitmap: tmaskedbitmap): agg2d_ptr;
begin
  abitmap := tmaskedbitmap.create(bmk_rgb);
  abitmap.graymask := true;
  abitmap.masked := true;
  abitmap.size := makesize(awidth, aheight);
  new(result, construct);
  result^.attach(pbyte(abitmap.scanline[0]), abitmap.width, abitmap.height, abitmap.scanlinestep);
  result^.clearAll(0, 0, 0, 0);
end;

procedure endimage(const afilename: string; const abitmap: tmaskedbitmap; const agg: agg2d_ptr);
begin
  try
    dispose(agg, destruct);
    extractalpha(abitmap);
    abitmap.writetofile(msestring(afilename), 'png', []);
    writeln('Written: ', afilename);
  finally
    abitmap.free;
  end;
end;

procedure writealphaimage(const afilename: string; const asize: integer; const adraw: drawproc);
var
  bitmap: tmaskedbitmap;
  agg: agg2d_ptr;
begin
  agg := beginimage(asize, asize, bitmap);
  adraw(agg, asize);
  endimage(afilename, bitmap, agg);
end;

procedure writealphaimage(const afilename: string; const awidth, aheight: integer; const adraw: drawrectproc);
var
  bitmap: tmaskedbitmap;
  agg: agg2d_ptr;
begin
  agg := beginimage(awidth, aheight, bitmap);
  adraw(agg, awidth, aheight);
  endimage(afilename, bitmap, agg);
end;

end.
