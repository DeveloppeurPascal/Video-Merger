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
  Signature : 185035ca2944d49e5713054952bb83f3a3095b7a
  ***************************************************************************
*)

unit cFileSelector;

interface

uses
  System.SysUtils,
  System.Types,
  System.UITypes,
  System.Classes,
  System.Variants,
  FMX.Types,
  FMX.Graphics,
  FMX.Controls,
  FMX.Forms,
  FMX.Dialogs,
  FMX.StdCtrls,
  Olf.FMX.SelectDirectory,
  FMX.Layouts,
  FMX.ListBox,
  FMX.Controls.Presentation;

type
  TcadFileSelector = class(TFrame)
    btnChooseAFolder: TButton;
    lbFilesList: TListBox;
    OlfSelectDirectoryDialog1: TOlfSelectDirectoryDialog;
    procedure btnChooseAFolderClick(Sender: TObject);
  private
    FOnPathChanged: TProc<TcadFileSelector, string>;
    procedure AddFilesToList(const FromPath, SearchPattern: string);
    procedure SetOnPathChanged(const Value: TProc<TcadFileSelector, string>);
  public
    property OnPathChanged: TProc<TcadFileSelector, string> read FOnPathChanged
      write SetOnPathChanged;
    function getSelectedFile: string;
    procedure ChangePathTo(const NewPath: string);
  end;

implementation

{$R *.fmx}

uses
  System.IOUtils;

procedure TcadFileSelector.AddFilesToList(const FromPath,
  SearchPattern: string);
var
  Files: TStringDynArray;
  i: integer;
begin
  if tdirectory.Exists(FromPath) then
  begin
    Files := tdirectory.GetFiles(FromPath, SearchPattern);
    for i := 0 to length(Files) - 1 do
      lbFilesList.ListItems[lbFilesList.items.Add(tpath.GetFileName(Files[i]))
        ].TagString := Files[i];
  end;
end;

procedure TcadFileSelector.btnChooseAFolderClick(Sender: TObject);
begin
  if OlfSelectDirectoryDialog1.Execute then
    ChangePathTo(OlfSelectDirectoryDialog1.Directory);
end;

procedure TcadFileSelector.ChangePathTo(const NewPath: string);
begin
  if (not NewPath.IsEmpty) and tdirectory.Exists(NewPath) then
  begin
    if assigned(FOnPathChanged) then
      FOnPathChanged(self, NewPath);
    lbFilesList.Clear;
    lbFilesList.ListItems[lbFilesList.items.Add('')].TagString := '';
{$IFDEF DEBUG}
    AddFilesToList(NewPath, '*.*');
{$ELSE}
    AddFilesToList(NewPath, '*.mp4');
    AddFilesToList(NewPath, '*.mkv');
    AddFilesToList(NewPath, '*.mov');
{$ENDIF}
  end;
end;

function TcadFileSelector.getSelectedFile: string;
begin
  if assigned(lbFilesList.Selected) then
    result := lbFilesList.Selected.TagString
  else
    result := '';
end;

procedure TcadFileSelector.SetOnPathChanged(const Value
  : TProc<TcadFileSelector, string>);
begin
  FOnPathChanged := Value;
end;

end.
