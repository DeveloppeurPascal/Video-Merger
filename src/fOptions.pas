(* C2PP
  ***************************************************************************

  Video Merger

  Copyright 2024-2025 Patrick PREMARTIN under AGPL 3.0 license.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.

  ***************************************************************************

  Author(s) :
  Patrick PREMARTIN

  Site :
  https://videomerger.olfsoftware.fr

  Project site :
  https://github.com/DeveloppeurPascal/Video-Merger

  ***************************************************************************
  File last update : 2025-10-16T10:43:14.896+02:00
  Signature : 69aa03d019a31e14be7e2b05b7903cba3ebe9688
  ***************************************************************************
*)

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
