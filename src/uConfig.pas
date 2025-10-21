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
  File last update : 2025-10-16T10:43:14.904+02:00
  Signature : 3a01eb5a696d391551a003f12aac6edf01d30558
  ***************************************************************************
*)

unit uConfig;

interface

type
  TConfig = class
  private
    class procedure SetFFmpegPath(const Value: string); static;
    class procedure SetMergeToPath(const Value: string); static;
    class procedure SetNbVideosToMerge(const Value: integer); static;
    class function GetFFmpegPath: string; static;
    class function GetMergeToPath: string; static;
    class function GetNbVideosToMerge: integer; static;
  protected
  public
    class property FFmpegPath: string read GetFFmpegPath write SetFFmpegPath;
    class property MergeToPath: string read GetMergeToPath write SetMergeToPath;
    class property NbVideosToMerge: integer read GetNbVideosToMerge
      write SetNbVideosToMerge;
    class procedure SetSelectInPath(const Index: integer; const Path: string);
    class function GetSelectInPath(const Index: integer): string;
    class procedure Save;
    class procedure Cancel;
  end;

implementation

uses
  System.Classes,
  System.Types,
  System.SysUtils,
  Olf.RTL.Params,
  Olf.RTL.CryptDecrypt;

procedure InitConfig;
begin
  tparams.InitDefaultFileNameV2('OlfSoftware', 'VideoMerger', false);
{$IFDEF RELEASE }
  tparams.onCryptProc := function(Const AParams: string): TStream
    var
      Keys: TByteDynArray;
      ParStream: TStringStream;
    begin
      ParStream := TStringStream.Create(AParams);
      try
{$I '..\_PRIVATE\src\ConfigFileXORKey.inc'}
        result := TOlfCryptDecrypt.XORCrypt(ParStream, Keys);
      finally
        ParStream.free;
      end;
    end;
  tparams.onDecryptProc := function(Const AStream: TStream): string
    var
      Keys: TByteDynArray;
      Stream: TStream;
      StringStream: TStringStream;
    begin
{$I '..\_PRIVATE\src\ConfigFileXORKey.inc'}
      result := '';
      Stream := TOlfCryptDecrypt.XORdeCrypt(AStream, Keys);
      try
        if assigned(Stream) and (Stream.Size > 0) then
        begin
          StringStream := TStringStream.Create;
          try
            Stream.Position := 0;
            StringStream.CopyFrom(Stream);
            result := StringStream.DataString;
          finally
            StringStream.free;
          end;
        end;
      finally
        Stream.free;
      end;
    end;
{$ENDIF}
  tparams.Load;
end;

{ TConfig }

class procedure TConfig.Cancel;
begin
  tparams.Cancel;
end;

class function TConfig.GetFFmpegPath: string;
begin
  result := tparams.getValue('FFmpeg', '');
end;

class function TConfig.GetMergeToPath: string;
begin
  result := tparams.getValue('ToPath', '');
end;

class function TConfig.GetNbVideosToMerge: integer;
begin
  result := tparams.getValue('NbV', 2);
end;

class function TConfig.GetSelectInPath(const Index: integer): string;
begin
  result := tparams.getValue('sip' + index.tostring, '');
end;

class procedure TConfig.Save;
begin
  tparams.Save;
end;

class procedure TConfig.SetFFmpegPath(const Value: string);
begin
  tparams.setValue('FFmpeg', Value);
end;

class procedure TConfig.SetMergeToPath(const Value: string);
begin
  tparams.setValue('ToPath', Value);
end;

class procedure TConfig.SetNbVideosToMerge(const Value: integer);
begin
  tparams.setValue('NbV', Value);
end;

class procedure TConfig.SetSelectInPath(const Index: integer;
  const Path: string);
begin
  tparams.setValue('sip' + index.tostring, Path);
end;

initialization

InitConfig;

finalization

end.
