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
  Signature : 2fe20a1542760b6c27727083341659f939fe20f7
  ***************************************************************************
*)

program VideoMerger;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMain in 'fMain.pas' {frmMain},
  cFileSelector in 'cFileSelector.pas' {cadFileSelector: TFrame},
  Olf.FMX.SelectDirectory in '..\lib-externes\Delphi-FMXExtend-Library\src\Olf.FMX.SelectDirectory.pas',
  Olf.FMX.AboutDialog in '..\lib-externes\AboutDialog-Delphi-Component\src\Olf.FMX.AboutDialog.pas',
  Olf.FMX.AboutDialogForm in '..\lib-externes\AboutDialog-Delphi-Component\src\Olf.FMX.AboutDialogForm.pas' {OlfAboutDialogForm},
  Olf.RTL.CryptDecrypt in '..\lib-externes\librairies\src\Olf.RTL.CryptDecrypt.pas',
  Olf.RTL.Params in '..\lib-externes\librairies\src\Olf.RTL.Params.pas',
  u_urlOpen in '..\lib-externes\librairies\src\u_urlOpen.pas',
  uConfig in 'uConfig.pas',
  uMergingWorker in 'uMergingWorker.pas',
  fOptions in 'fOptions.pas' {frmOptions},
  uDMLogo in 'uDMLogo.pas' {dmLogo: TDataModule},
  DOSCommand in 'DOSCommand.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TdmLogo, dmLogo);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
