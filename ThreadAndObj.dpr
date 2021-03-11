program ThreadAndObj;

uses

  {$IFDEF DEBUG}
  FastMM4 in 'FastMM4.pas',
  {$ENDIF }

  Vcl.Forms,
  UnitMain in 'UnitMain.pas' {FMain},
  UnitThread in 'UnitThread.pas',
  UnitLogger in 'UnitLogger.pas',
  UnitReadSettings in 'UnitReadSettings.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFMain, FMain);
  Application.Run;
end.
