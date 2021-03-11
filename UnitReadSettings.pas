unit UnitReadSettings;

interface

uses
  IniFiles, System.SysUtils;

  function ReadSettings(SettingsFileName: string; out CountThread: UInt32; out LifeTime: UInt32; out CleanPeriod: UInt32; out LogName: string): Boolean;

implementation

function ReadSettings(SettingsFileName: string; out CountThread: UInt32; out LifeTime: UInt32; out CleanPeriod: UInt32; out LogName: string): Boolean;
var
  IniFile: TIniFile;
begin
  if FileExists(SettingsFileName) then
  begin
    IniFile     := TIniFile.Create(SettingsFileName);
    LogName     := IniFile.ReadString('Main', 'LogName', 'MainLog');
    CountThread := IniFile.ReadInteger('Main', 'CountThread', 2);
    LifeTime    := IniFile.ReadInteger('Main', 'LifeTime', 10);
    CleanPeriod := IniFile.ReadInteger('Main', 'CleanPeriod', 5);

    FreeAndNil(IniFile);
    Exit(True);
  end;

  FreeAndNil(IniFile);
  Exit(False);
end;

end.
