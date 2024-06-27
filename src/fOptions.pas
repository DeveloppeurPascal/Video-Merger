unit fOptions;

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
  FMX.Layouts,
  FMX.StdCtrls,
  FMX.Edit,
  FMX.Controls.Presentation,
  Olf.FMX.SelectDirectory;

type
  TfrmOptions = class(TForm)
    VertScrollBox1: TVertScrollBox;
    GridPanelLayout1: TGridPanelLayout;
    lblFFmpegPath: TLabel;
    btnFFmpegDownload: TButton;
    edtFFmpegPath: TEdit;
    btnFFmpegPathChoose: TEllipsesEditButton;
    btnSaveAndClose: TButton;
    btnCancel: TButton;
    OpenDialogFFmpeg: TOpenDialog;
    lblNbFilesSelectorByDefault: TLabel;
    edtNbFilesSelectorByDefault: TEdit;
    lblOutputPath: TLabel;
    edtOutputPath: TEdit;
    btnOutputPathChoose: TEllipsesEditButton;
    OlfSelectDirectoryDialog1: TOlfSelectDirectoryDialog;
    procedure btnFFmpegDownloadClick(Sender: TObject);
    procedure btnFFmpegPathChooseClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnSaveAndCloseClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure btnOutputPathChooseClick(Sender: TObject);
  private
    procedure SaveConfig;
    procedure InitConfigFields;
    function HasChanged: Boolean;
  public
  end;

implementation

{$R *.fmx}

uses
  FMX.DialogService,
  System.IOUtils,
  u_urlOpen,
  uConfig;

procedure TfrmOptions.btnCancelClick(Sender: TObject);
begin
  InitConfigFields;
  close;
end;

procedure TfrmOptions.btnFFmpegDownloadClick(Sender: TObject);
begin
  url_open_in_browser('https://ffmpeg.org/download.html');
end;

procedure TfrmOptions.btnFFmpegPathChooseClick(Sender: TObject);
begin
  if (not edtFFmpegPath.Text.IsEmpty) and tfile.exists(edtFFmpegPath.Text) then
  begin
    OpenDialogFFmpeg.InitialDir := tpath.getdirectoryname(edtFFmpegPath.Text);
    OpenDialogFFmpeg.FileName := edtFFmpegPath.Text;
  end
  else if OpenDialogFFmpeg.InitialDir.IsEmpty then
    OpenDialogFFmpeg.InitialDir := tpath.GetDownloadsPath;

  if OpenDialogFFmpeg.Execute and tfile.exists(OpenDialogFFmpeg.FileName) then
    edtFFmpegPath.Text := OpenDialogFFmpeg.FileName;
end;

procedure TfrmOptions.btnSaveAndCloseClick(Sender: TObject);
begin
  SaveConfig;
  close;
end;

procedure TfrmOptions.btnOutputPathChooseClick(Sender: TObject);
begin
  if (not edtOutputPath.Text.IsEmpty) and tdirectory.exists(edtOutputPath.Text)
  then
    OlfSelectDirectoryDialog1.Directory := edtOutputPath.Text;

  if OlfSelectDirectoryDialog1.Execute and
    tdirectory.exists(OlfSelectDirectoryDialog1.Directory) then
    edtOutputPath.Text := OlfSelectDirectoryDialog1.Directory;
end;

procedure TfrmOptions.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if HasChanged then
  begin
    CanClose := false;
    TDialogService.MessageDialog
      ('Do you want to save your changes before closing ?',
      tmsgdlgtype.mtConfirmation, mbyesno, tmsgdlgbtn.mbYes, 0,
      procedure(const AModalResult: TModalResult)
      begin
        case AModalResult of
          mryes:
            tthread.forcequeue(nil,
              procedure
              begin
                btnSaveAndCloseClick(Sender);
              end);
        else
          tthread.forcequeue(nil,
            procedure
            begin
              btnCancelClick(Sender);
            end);
        end;
      end);
  end
  else
    CanClose := true;
end;

procedure TfrmOptions.FormCreate(Sender: TObject);
begin
  InitConfigFields;
end;

function TfrmOptions.HasChanged: Boolean;
var
  i: integer;
  e: TEdit;
begin
  result := false;
  for i := 0 to VertScrollBox1.Content.ChildrenCount - 1 do
    if VertScrollBox1.Content.Children[i] is TEdit then
    begin
      e := VertScrollBox1.Content.Children[i] as TEdit;
      result := e.TagString <> e.Text;
      if result then
        break;
    end;
end;

procedure TfrmOptions.InitConfigFields;
var
  i: integer;
  e: TEdit;
begin
  edtFFmpegPath.TagString := tconfig.FFmpegPath;
  edtOutputPath.TagString := tconfig.MergeToPath;
  edtNbFilesSelectorByDefault.TagString := tconfig.NbVideosToMerge.tostring;

  for i := 0 to VertScrollBox1.Content.ChildrenCount - 1 do
    if VertScrollBox1.Content.Children[i] is TEdit then
    begin
      e := VertScrollBox1.Content.Children[i] as TEdit;
      e.Text := e.TagString;
    end;
end;

procedure TfrmOptions.SaveConfig;
begin
  tconfig.FFmpegPath := edtFFmpegPath.Text;
  tconfig.MergeToPath := edtOutputPath.Text;
  tconfig.NbVideosToMerge := edtNbFilesSelectorByDefault.Text.ToInteger;
  tconfig.Save;

  InitConfigFields;
end;

end.
