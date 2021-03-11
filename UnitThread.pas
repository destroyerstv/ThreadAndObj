unit UnitThread;

interface

uses
  Windows,
  System.Classes, System.SysUtils, System.DateUtils,
  UnitLogger;

type

  TThreadMsg = record
    Text: string;
    Status: string;
  end;

  TMakeMsgThread = class(TThread)
  private
    FId:        UInt32;
    FMsgPeriod: UInt32;
    FCount:     UInt64;
    FLogger:    TLogger;
  protected
    procedure WriteToLog(Msg: TThreadMsg);
    procedure CreateMsg(out Msg: TThreadMsg);
  public
    constructor Create(TaskId: Integer; MsgPeriod: Integer; Logger: TLogger);
    procedure Execute; override;
    property Id: UInt32 read FId;
  end;

const
 CRITICAL = 0;
 WARNING = 1;
 INFO = 2;


implementation

constructor TMakeMsgThread.Create(TaskId: Integer; MsgPeriod: Integer; Logger: TLogger);
begin
  inherited Create(False);
  FId         := TaskId;
  FMsgPeriod  := MsgPeriod;
  FLogger     := Logger;
  FCount      := 0;
end;

procedure TMakeMsgThread.Execute;
var
  NewMessageCrt: TDateTime;
  Msg: TThreadMsg;
begin
  NewMessageCrt := IncSecond(Now, FMsgPeriod);
  while not Terminated do
  begin
    if (CompareDateTime(NewMessageCrt, Now) <= 0) then
    begin
      CreateMsg(Msg);
      WriteToLog(Msg);
      NewMessageCrt := IncSecond(Now, FMsgPeriod);
    end;
  end;
end;

procedure TMakeMsgThread.WriteToLog(Msg: TThreadMsg);
begin
  if not FLogger.Finished then
    FLogger.Add(Msg.Text, Msg.Status);
end;

procedure TMakeMsgThread.CreateMsg(out Msg: TThreadMsg);
var
  Status: Integer;
begin
  ZeroMemory(@Msg, SizeOf(TThreadMsg));
  Msg.Text := 'Сообщение #' + IntToStr(FCount);
  Status := Random(3);
  case Status of
    CRITICAL: Msg.Status := 'Critical';
    WARNING:  Msg.Status := 'Warning';
    INFO:     Msg.Status := 'Info';
  end;
  Randomize;
  inc(FCount);
end;

end.
