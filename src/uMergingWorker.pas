unit uMergingWorker;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Classes;

type
  TMergingWorker = class(TThread)
  private
    FWaitingList: TQueue<string>;
    FOnWorkStart: TProc;
    FOnWaitingListCountChange: TProc<Nativeint>;
    FOnWorkEnd: TProc;
    FonError: TProc<string>;
    FonLog: TProc<string>;
    procedure SetonError(const Value: TProc<string>);
    procedure SetOnWaitingListCountChange(const Value: TProc<Nativeint>);
    procedure SetOnWorkEnd(const Value: TProc);
    procedure SetOnWorkStart(const Value: TProc);
    procedure SetonLog(const Value: TProc<string>);
  protected
    function GetNextFromQueue: string;
    procedure Execute; override;
    function ExtractPartOf(const FileName: string): string;
    procedure AddLog(Text: string);
    procedure AddError(Text: string);
    procedure ExecuteFFmpegAndWait(const AParams, DestinationFilePath: string);
  public
    property OnWorkStart: TProc read FOnWorkStart write SetOnWorkStart;
    property OnWorkEnd: TProc read FOnWorkEnd write SetOnWorkEnd;
    property OnWaitingListCountChange: TProc<Nativeint>
      read FOnWaitingListCountChange write SetOnWaitingListCountChange;
    property onError: TProc<string> read FonError write SetonError;
    property onLog: TProc<string> read FonLog write SetonLog;
    procedure AddToQueue(const VideosPathWithTabSeparator: string);
    constructor Create;
    destructor Destroy; override;
    procedure Stop;
  end;

implementation

uses
{$IF Defined(MACOS)}
  Posix.Stdlib,
{$ELSEIF Defined(MSWINDOWS)}
  Winapi.ShellAPI,
  Winapi.Windows,
{$ENDIF}
  System.IOUtils,
  System.Types, uConfig;

procedure TMergingWorker.AddError(Text: string);
begin
  if assigned(FonError) and (not Text.IsEmpty) then
    TThread.Queue(nil,
      procedure
      begin
        if assigned(FonError) then
          FonError(Text);
      end);
end;

procedure TMergingWorker.AddLog(Text: string);
begin
  if assigned(FonLog) and (not Text.IsEmpty) then
    TThread.Queue(nil,
      procedure
      begin
        if assigned(FonLog) then
          FonLog(Text);
      end);
end;

procedure TMergingWorker.AddToQueue(const VideosPathWithTabSeparator: string);
var
  Count: Nativeint;
  s: string;
  DoNotAdd: boolean;
begin
  if VideosPathWithTabSeparator.IsEmpty then
    exit;

  System.TMonitor.Enter(FWaitingList);
  try
    DoNotAdd := false;
    if FWaitingList.Count > 0 then
      for s in FWaitingList do
        if s = VideosPathWithTabSeparator then
        begin
          DoNotAdd := true;
          break;
        end;

    if not DoNotAdd then
    begin
      FWaitingList.Enqueue(VideosPathWithTabSeparator);
      if assigned(FOnWaitingListCountChange) then
      begin
        Count := FWaitingList.Count;
        TThread.Queue(nil,
          procedure
          begin
            if assigned(FOnWaitingListCountChange) then
              FOnWaitingListCountChange(Count);
          end);
      end;
    end;
  finally
    System.TMonitor.exit(FWaitingList);
  end;
end;

constructor TMergingWorker.Create;
begin
  inherited Create(true);
  FreeOnTerminate := true;
  FWaitingList := TQueue<string>.Create;
  FOnWorkStart := nil;
  FOnWaitingListCountChange := nil;
  FOnWorkEnd := nil;
  FonError := nil;
  FonLog := nil;
end;

destructor TMergingWorker.Destroy;
begin
  FWaitingList.free;
  inherited;
end;

procedure TMergingWorker.Execute;
var
  Files: string;
  cmd: string;
  Tab: TArray<string>;
  i: integer;
  ToFileName, ToFilePath: string;
  Counter: int64;
  NbVideos: integer;
begin
  Counter := 0;
  while not TThread.CheckTerminated do
  begin
    Files := GetNextFromQueue;
    if Files.IsEmpty then
      sleep(1000)
    else
    begin
      Tab := Files.Split([Tabulator]);
      cmd := '';
      ToFileName := '';
      NbVideos := 0;
      for i := 0 to length(Tab) - 1 do
        if not Tab[i].IsEmpty then
          if tfile.exists(Tab[i]) then
          begin
            inc(NbVideos);
            cmd := cmd + ' -i "' + Tab[i] + '"';
            if ToFileName.IsEmpty then
              ToFileName :=
                ExtractPartOf(tpath.GetFileNameWithoutExtension(Tab[i]))
            else
              ToFileName := ToFileName + '_' +
                ExtractPartOf(tpath.GetFileNameWithoutExtension(Tab[i]));
          end
          else
          begin
            cmd := '';
            AddError('File not found "' + Tab[i] + '".');
            break;
          end;
      if (not cmd.IsEmpty) and (NbVideos > 1) then
      begin
        if assigned(FOnWorkStart) then
          TThread.Queue(nil,
            procedure
            begin
              if assigned(FOnWorkStart) then
                FOnWorkStart;
            end);
        try
          cmd := cmd + ' -filter_complex ''concat=n=' + NbVideos.tostring +
            ':v=1:a=1''';
          inc(Counter);
          ToFilePath := tpath.Combine(TConfig.MergeToPath,
            ToFileName + '-' + Counter.tostring + '.mp4');
{$IFDEF DEBUG}
          AddLog(cmd + ' "' + ToFilePath + '"');
{$ENDIF}
          ExecuteFFmpegAndWait(cmd, ToFilePath);
          AddLog(Files.Replace(Tabulator, ', ') + ' merged in ' + ToFilePath);
        finally
          if assigned(FOnWorkEnd) then
            TThread.Queue(nil,
              procedure
              begin
                if assigned(FOnWorkEnd) then
                  FOnWorkEnd;
              end);
        end;
      end;
    end;
  end;
end;

procedure TMergingWorker.ExecuteFFmpegAndWait(const AParams,
  DestinationFilePath: string);
// procedure from "Le Temps D'Une Tomate" project
// cf https://github.com/DeveloppeurPascal/LeTempsDUneTomate/blob/main/src/fMain.pas
var
  LParams: string;
begin
  if tfile.exists(DestinationFilePath) then
  begin
    AddLog('File "' + DestinationFilePath + '" exist !');
    exit;
  end;

{$IFDEF DEBUG}
  LParams := '-y ' + AParams;
  AddLog('"' + TConfig.FFmpegPath + '" ' + LParams + ' "' +
    DestinationFilePath + '"');
{$ELSE}
  LParams := '-y -loglevel error ' + AParams;
{$ENDIF}
{$IF Defined(MSWINDOWS)}
  ShellExecute(0, pwidechar(TConfig.FFmpegPath),
    pwidechar(LParams + ' "' + DestinationFilePath + '"'), nil, nil,
    SW_SHOWNORMAL);
{$ELSEIF Defined(MACOS)}
  _system(PAnsiChar(ansistring('"' + TConfig.FFmpegPath + '" ' + LParams + ' "'
    + DestinationFilePath + '"')));
{$ELSE}
{$MESSAGE FATAL 'Platform not available.'}
{$ENDIF}
end;

function TMergingWorker.ExtractPartOf(const FileName: string): string;
var
  i: integer;
begin
  i := 0;
  result := '';
  while (result.length < 10) and (i <= length(FileName)) do
  begin
    if charinset(FileName.Chars[i], ['0' .. '9', 'a' .. 'z', 'A' .. 'Z']) then
      result := result + FileName.Chars[i];
    inc(i);
  end;
  result := result.ToLower;
end;

function TMergingWorker.GetNextFromQueue: string;
var
  Count: Nativeint;
begin
  System.TMonitor.Enter(FWaitingList);
  try
    Count := FWaitingList.Count;
    if (Count > 0) then
    begin
      result := FWaitingList.Dequeue;
      if assigned(FOnWaitingListCountChange) then
      begin
        Count := Count - 1;
        TThread.Queue(nil,
          procedure
          begin
            if assigned(FOnWaitingListCountChange) then
              FOnWaitingListCountChange(Count);
          end);
      end;
    end
    else
      result := '';
  finally
    System.TMonitor.exit(FWaitingList);
  end;
end;

procedure TMergingWorker.SetonError(const Value: TProc<string>);
begin
  FonError := Value;
end;

procedure TMergingWorker.SetonLog(const Value: TProc<string>);
begin
  FonLog := Value;
end;

procedure TMergingWorker.SetOnWaitingListCountChange
  (const Value: TProc<Nativeint>);
begin
  FOnWaitingListCountChange := Value;
end;

procedure TMergingWorker.SetOnWorkEnd(const Value: TProc);
begin
  FOnWorkEnd := Value;
end;

procedure TMergingWorker.SetOnWorkStart(const Value: TProc);
begin
  FOnWorkStart := Value;
end;

procedure TMergingWorker.Stop;
begin
  terminate;
end;

end.
