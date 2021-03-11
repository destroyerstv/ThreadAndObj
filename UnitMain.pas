unit UnitMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Generics.Defaults, System.Generics.Collections,
  UnitThread, UnitLogger, UnitReadSettings;

type
  TFMain = class(TForm)
    lst1: TListBox;
    pnlBotom: TPanel;
    btnStart: TButton;
    btnStop: TButton;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FPath:      string;
    Logger:     TLogger;
    ThreadLst:  TList<TMakeMsgThread>;

    procedure StopThreads;
    procedure GetHistory(HistoryMsgs: TList<string>);
    { Private declarations }
  public
    { Public declarations }
  end;

var
  FMain: TFMain;


implementation

{$R *.dfm}

procedure TFMain.StopThreads;
var
  i: Integer;
begin

  for i := 0 to ThreadLst.Count - 1 do
  begin
    ThreadLst[i].Terminate;
    while not ThreadLst[i].Finished do
    begin
      Sleep(1);
      Application.ProcessMessages;
    end;

    ThreadLst[i].Free;
  end;

  ThreadLst.Clear;

  if Logger <> nil then
  begin
    if not Logger.Finished then
    begin
      Logger.Terminate;
      while not Logger.Finished do
      begin
        Sleep(1);
        Application.ProcessMessages;
      end;
      FreeAndNil(Logger);
    end
    else
    begin
      FreeAndNil(Logger);
    end;
  end;
end;

procedure TFMain.GetHistory(HistoryMsgs: TList<string>);
var
  str: string;
begin
  lst1.Clear;
  for str in HistoryMsgs do
    lst1.Items.Add(str);

  HistoryMsgs.Clear;
  FreeAndNil(HistoryMsgs);
end;

procedure TFMain.btnStartClick(Sender: TObject);
var
  CountThread:    UInt32;
  LifeTime:       UInt32;
  CleanPeriod:    UInt32;
  LogName:        string;
  i:              Integer;
  MakeMsgThread:  TMakeMsgThread;
begin
  btnStart.Enabled := False;
  if (ReadSettings(FPath + 'Settings.ini', CountThread, LifeTime, CleanPeriod, LogName)) then
  begin
    Logger := TLogger.Create(FPath + LogName, CleanPeriod);
    Logger.OnNewMessage := GetHistory;

    for i := 0 to CountThread - 1 do
    begin
      MakeMsgThread := TMakeMsgThread.Create(i, LifeTime, Logger);
      ThreadLst.Add(MakeMsgThread);
    end;

  end
  else
  begin
    ShowMessage('Файл с настройками не найден');
    btnStart.Enabled := True;
  end;
end;

procedure TFMain.btnStopClick(Sender: TObject);
begin
  StopThreads;
  btnStart.Enabled := True;
end;

procedure TFMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopThreads;
  FreeAndNil(ThreadLst);
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
  FPath := ExtractFilePath(Application.ExeName);
  ThreadLst :=  TList<TMakeMsgThread>.Create;
end;

end.
