unit UnitLogger;

interface

uses
  Windows,
  System.Classes,System.SysUtils, System.DateUtils, System.Generics.Defaults, System.Generics.Collections;

type

  TLoggerMsg = record
    Id: string;
    DateTime: string;
    Text: string;
    Status: string;
  end;


  TNewMsg = procedure(HistoryMsgs: TList<string>) of object;

  TLogger = class(TThread)
  private
    RWSync: TMultiReadExclusiveWriteSynchronizer;
    FLogName: string;
    FDelPeriod: UInt32;
    FHistory: TQueue<TLoggerMsg>;
    FWriteQueue: TThreadedQueue<TLoggerMsg>;
    FOnNewMessage: TNewMsg;
    procedure AddHistory(Msg: TLoggerMsg);
    procedure WriteToFile;
    procedure DeleteOldRows;
  protected

  public
    constructor Create(LogName: string; DelPeriod: UInt32);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Add(Text: string; Status: string);
    function ReadHistory: TList<string>;

    property OnNewMessage: TNewMsg write FOnNewMessage;
  end;

implementation

constructor TLogger.Create(LogName: string; DelPeriod: UInt32);
begin
  inherited Create(False);
  FLogName    := LogName;
  FDelPeriod  := DelPeriod;
  RWSync      := TMultiReadExclusiveWriteSynchronizer.Create;
  FHistory    := TQueue<TLoggerMsg>.Create;
  FWriteQueue := TThreadedQueue<TLoggerMsg>.Create(65535);
end;

destructor TLogger.Destroy;
begin
  FreeAndNil(FHistory);
  FreeAndNil(FWriteQueue);
  FreeAndNil(RWSync);
  inherited;
end;

procedure TLogger.Execute;
var
  NewMessageCrt: TDateTime;
begin
  NewMessageCrt := IncMinute(Now, FDelPeriod);
  while not Terminated do
  begin

    if FWriteQueue.QueueSize > 0 then
      WriteToFile;

    if (CompareDateTime(NewMessageCrt, Now) <= 0) then
    begin
      DeleteOldRows;
      NewMessageCrt := IncSecond(Now, FDelPeriod);
    end;

    Sleep(1000);
  end;
end;

procedure TLogger.AddHistory(Msg: TLoggerMsg);
begin
  RWSync.BeginWrite;
  try
    if FHistory.Count < 10 then
      FHistory.Enqueue(Msg)
    else
    begin
      FHistory.Dequeue;
      FHistory.Enqueue(Msg);
    end;
  finally
    RWSync.EndWrite;
  end;
end;

function TLogger.ReadHistory: TList<string>;
var
  item: TLoggerMsg;
begin
  RWSync.BeginRead;
  try
    Result := TList<string>.Create;
    for item in FHistory do
      Result.Add(item.Id + '  ' + item.DateTime + '  ' + item.Text + '  ' + item.Status);
  finally
    RWSync.EndRead;
  end;
end;

procedure TLogger.Add(Text: string; Status: string);
var
  Msg: TLoggerMsg;
begin

  MonitorEnter(Self);
  try
    ZeroMemory(@Msg, SizeOf(TLoggerMsg));

    Msg.Id        := IntToStr(GetCurrentThreadId);
    Msg.DateTime  := DateTimeToStr(Now);
    Msg.Text      := Text;
    Msg.Status    := Status;

    AddHistory(Msg);
    FWriteQueue.PushItem(Msg);

    if Assigned(FOnNewMessage) then
      FOnNewMessage(ReadHistory);

  finally
    MonitorExit(Self);
  end;

end;

procedure TLogger.WriteToFile;
var
  Fd: TextFile;
  Msg: TLoggerMsg;
begin
  AssignFile(Fd, FLogName);

  if FileExists(FLogName) then
    Append(Fd)
  else
    Rewrite(Fd);

  while FWriteQueue.QueueSize > 0 do
  begin
    Msg := FWriteQueue.PopItem;
    Writeln(Fd, Msg.Id + '  ' + Msg.DateTime + '  ' + Msg.Text + '  ' + Msg.Status);
  end;
  CloseFile(Fd);
end;

procedure TLogger.DeleteOldRows;
var
  Fd: TextFile;
  FdNew: TextFile;
  str: string;
  OldDate : TDateTime;
begin
  AssignFile(Fd, FLogName);
  Reset(Fd);
  AssignFile(FdNew, FLogName + 'New');
  Rewrite(FdNew);
  while (not EOF(Fd)) do
  begin
    Readln(Fd, str);
    OldDate := StrToDateTime(str.Split(['  '])[1]);

    if MinutesBetween(Now, OldDate) >= FDelPeriod then
      Break;

    Writeln(FdNew, str);
  end;
  CloseFile(Fd);
  CloseFile(FdNew);
  DeleteFile(FLogName);
  RenameFile(FLogName + 'New', FLogName);
end;

end.
