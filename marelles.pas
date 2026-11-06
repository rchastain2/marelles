program marelles;

{$mode objfpc}{$h+}
{$ifdef mswindows}
{$apptype gui}
{$R marelles.rc}
{$endif}

uses
{$ifdef unix}
  cthreads,
{$endif}
  msegui, main;

begin
  application.createform(tmainfo, mainfo);
  application.run;
end.
