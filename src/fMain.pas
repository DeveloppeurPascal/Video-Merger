unit fMain;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.Graphics,
  FMX.Dialogs,
  FMX.Memo.Types,
  FMX.Layouts,
  FMX.ScrollBox,
  FMX.Memo,
  FMX.Controls.Presentation,
  FMX.StdCtrls,
  Olf.FMX.AboutDialog,
  Olf.FMX.AboutDialogForm,
  cFileSelector,
  uMergingWorker;

type
  TfrmMain = class(TForm)
    ToolBar1: TToolBar;
    Memo1: TMemo;
    HorzScrollBox1: THorzScrollBox;
    btnOptions: TButton;
    btnAbout: TButton;
    btnQuit: TButton;
    btnMergeFiles: TButton;
    OlfAboutDialog1: TOlfAboutDialog;
    AniIndicator1: TAniIndicator;
    btnAddAFileSelector: TButton;
    StatusBar1: TStatusBar;
    lblWaitingListStatus: TLabel;
    FlowLayout1: TFlowLayout;
    Splitter1: TSplitter;
    procedure btnQuitClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
    procedure btnOptionsClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure btnAddAFileSelectorClick(Sender: TObject);
    procedure btnMergeFilesClick(Sender: TObject);
    procedure FlowLayout1Resize(Sender: TObject);
  private
    FMergingWorker: TMergingWorker;
    procedure SetWaitingListCount(const Value: nativeint);
    function GetLastFileSelector: TcadFileSelector;
    function GetFirstFileSelector: TcadFileSelector;
  protected
    property WaitingListCount: nativeint write SetWaitingListCount;
    procedure AddLog(Const Text: string);
    procedure InitMainFormCaption;
    procedure InitAboutDialogDescriptionAndLicense;

  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  u_urlOpen,
  uConfig;

procedure TfrmMain.AddLog(const Text: string);
begin
  Memo1.lines.Add(Text);
  Memo1.GoToLineEnd;
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  OlfAboutDialog1.Execute;
end;

procedure TfrmMain.btnAddAFileSelectorClick(Sender: TObject);
var
  preccad, newcad: TcadFileSelector;
begin
  preccad := GetLastFileSelector;

  newcad := TcadFileSelector.Create(self);
  newcad.Name := '';
  newcad.Parent := FlowLayout1;
  newcad.height := FlowLayout1.height - newcad.margins.top -
    newcad.margins.bottom;
  newcad.TagObject := nil;

  if assigned(preccad) then
  begin
    preccad.TagObject := newcad;
    newcad.tag := preccad.tag + 1;
  end
  else
    newcad.tag := 1;

  newcad.OnPathChanged := procedure(Sender: TcadFileSelector; NewPath: string)
    begin
      tconfig.setSelectInPath(Sender.tag, NewPath);
      tconfig.save;
    end;
  newcad.ChangePathTo(tconfig.GetSelectInPath(newcad.tag));

  FlowLayout1.width := FlowLayout1.width + newcad.width;
end;

procedure TfrmMain.btnMergeFilesClick(Sender: TObject);
var
  FilePath, FilesList: string;
  cad: TcadFileSelector;
  nb: integer;
begin
  cad := GetFirstFileSelector;

  FilesList := '';
  nb := 0;
  while assigned(cad) do
  begin
    FilePath := cad.getSelectedFile;
    if not FilePath.IsEmpty then
    begin
      inc(nb);
      if FilesList.IsEmpty then
        FilesList := FilePath
      else
        FilesList := FilesList + Tabulator + FilePath;
    end;
    cad := cad.TagObject as TcadFileSelector;
  end;

{$IFDEF DEBUG}
  AddLog(FilesList);
  AddLog(nb.tostring);
{$ENDIF}
  if (nb < 2) then
    showmessage('Choose at least two files to merge something !')
  else if not FilesList.IsEmpty then
    FMergingWorker.AddToQueue(FilesList);
end;

procedure TfrmMain.btnOptionsClick(Sender: TObject);
begin
  // TODO : à compléter
  showmessage('in next release');
end;

procedure TfrmMain.btnQuitClick(Sender: TObject);
begin
  close;
end;

procedure TfrmMain.FlowLayout1Resize(Sender: TObject);
var
  i: integer;
  c: TcadFileSelector;
begin
  for i := 0 to FlowLayout1.ChildrenCount - 1 do
    if FlowLayout1.Children[i] is TcadFileSelector then
    begin
      c := FlowLayout1.Children[i] as TcadFileSelector;
      c.height := FlowLayout1.height - c.margins.top - c.margins.bottom;
    end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FMergingWorker.stop;
  sleep(1000); // wait for thread termination
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if AniIndicator1.Enabled then
  begin
    CanClose := false;
    showmessage('Waiting for current waiting list is empty.');
    tthread.forcequeue(nil,
      procedure
      begin
        sleep(1000);
        close;
      end);
  end
  else
    CanClose := true;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  i: integer;
begin
  FlowLayout1.width := 20;

  InitMainFormCaption;
  InitAboutDialogDescriptionAndLicense;

  Memo1.lines.Clear;
  WaitingListCount := 0;

  FMergingWorker := TMergingWorker.Create;
  FMergingWorker.OnWorkStart := procedure
    begin
      AniIndicator1.visible := true;
      AniIndicator1.Enabled := true;
    end;
  FMergingWorker.OnWorkEnd := procedure
    begin
      AniIndicator1.Enabled := false;
      AniIndicator1.visible := false;
    end;
  FMergingWorker.OnWaitingListCountChange := procedure(Count: nativeint)
    begin
      WaitingListCount := Count;
    end;
  FMergingWorker.onError := procedure(Text: string)
    begin
      AddLog('***** ERROR *****');
      AddLog(Text);
    end;
  FMergingWorker.onLog := procedure(Text: string)
    begin
      AddLog(Text);
    end;
  FMergingWorker.Start;

  for i := 1 to tconfig.NbVideosToMerge do
    tthread.forcequeue(nil,
      procedure
      begin
        btnAddAFileSelectorClick(self);
      end);
end;

procedure TfrmMain.InitAboutDialogDescriptionAndLicense;
begin
  OlfAboutDialog1.Licence.Text :=
    'This program is distributed as shareware. If you use it (especially for ' +
    'commercial or income-generating purposes), please remember the author and '
    + 'contribute to its development by purchasing a license.' + slinebreak +
    slinebreak +
    'This software is supplied as is, with or without bugs. No warranty is offered '
    + 'as to its operation or the data processed. Make backups!';
  OlfAboutDialog1.Description.Text :=
    'Video Merger uses FFmpeg library to join video files.' + slinebreak +
    slinebreak + '*****************' + slinebreak + '* Publisher info' +
    slinebreak + slinebreak +
    'This application was developed by Patrick Prémartin.' + slinebreak +
    slinebreak +
    'It is published by OLF SOFTWARE, a company registered in Paris (France) under the reference 439521725.'
    + slinebreak + slinebreak + '****************' + slinebreak +
    '* Personal data' + slinebreak + slinebreak +
    'This program is autonomous in its current version. It does not depend on the Internet and communicates nothing to the outside world.'
    + slinebreak + slinebreak + 'We have no knowledge of what you do with it.' +
    slinebreak + slinebreak +
    'No information about you is transmitted to us or to any third party.' +
    slinebreak + slinebreak +
    'We use no cookies, no tracking, no stats on your use of the application.' +
    slinebreak + slinebreak + '**********************' + slinebreak +
    '* User support' + slinebreak + slinebreak +
    'If you have any questions or require additional functionality, please leave us a message on the application''s website or on its code repository.'
    + slinebreak + slinebreak + 'To find out more, visit ' +
    OlfAboutDialog1.URL;
end;

function TfrmMain.GetFirstFileSelector: TcadFileSelector;
var
  i: integer;
begin
  result := nil;
  for i := 0 to FlowLayout1.ChildrenCount - 1 do
    if (FlowLayout1.Children[i] is TcadFileSelector) and
      ((FlowLayout1.Children[i] as TcadFileSelector).tag = 1) then
    begin
      result := FlowLayout1.Children[i] as TcadFileSelector;
      break;
    end;
end;

function TfrmMain.GetLastFileSelector: TcadFileSelector;
var
  i: integer;
begin
  result := nil;
  for i := 0 to FlowLayout1.ChildrenCount - 1 do
    if FlowLayout1.Children[i] is TcadFileSelector then
    begin
      result := FlowLayout1.Children[i] as TcadFileSelector;
      break;
    end;
  while assigned(result) and assigned(result.TagObject) do
    result := result.TagObject as TcadFileSelector;
end;

procedure TfrmMain.InitMainFormCaption;
begin
{$IFDEF DEBUG}
  caption := '[DEBUG] ';
{$ELSE}
  caption := '';
{$ENDIF}
  caption := caption + OlfAboutDialog1.Titre + ' v' +
    OlfAboutDialog1.VersionNumero;
end;

procedure TfrmMain.SetWaitingListCount(const Value: nativeint);
begin
  lblWaitingListStatus.Text := 'Waiting count : ' + Value.tostring;
end;

initialization

{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
{$ENDIF}

end.
