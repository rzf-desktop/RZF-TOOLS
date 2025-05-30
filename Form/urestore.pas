unit urestore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Buttons, Windows, StrUtils, inifiles, IniPropStorage;

type

  { TfrmRestore }

  TfrmRestore = class(TForm)
    btRest: TSpeedButton;
    Label3: TLabel;
    Label4: TLabel;
    od: TOpenDialog;
    Panel1: TPanel;
    procedure btRestClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Restore(AFile : string;AutoClose : boolean=false);
  private
    { private declarations }
  public
    { public declarations }
    IFile: TIniPropStorage;
    Hostname,Username,Password,Port,Database : string;
  end;

var
  frmRestore: TfrmRestore;

implementation

uses udm;

{$R *.lfm}

{ TfrmRestore }

procedure TfrmRestore.btRestClick(Sender: TObject);
begin
  if od.Execute then
  begin
    Restore(od.FileName);
  end;
end;

procedure TfrmRestore.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    VK_F3 : btRestClick(Sender);
    VK_ESCAPE : self.Close;
  end;
end;

procedure TfrmRestore.Restore(AFile : string;AutoClose : boolean=false);
begin
  with TStringList.Create do
  try
    Add('@echo off');
    Add('title Restore Database');
    Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Silahkan Tunggu...');

    if (Password='') then
    Add('mysql -u'+Username+' -h'+Hostname+' -P'+Port+' '+Database+' --max_allowed_packet=512M < "'+AFile+'"') else
    Add('mysql -u'+Username+' -p'+Password+' -h'+Hostname+' -P'+Port+' '+Database+' --max_allowed_packet=512M < "'+AFile+'"');
    Add('if errorlevel 1 goto msgerror');
    Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Restore database berhasil');
    if AutoClose then Add('exit') else Add('pause');
    Add('exit');
    Add(':msgerror');
    Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Restore database gagal');
    Add('pause');
    SaveToFile(GetAppConfigDir(False)+'RES.bat');
  finally
    Free;
  end;

  ShellExecute(0, 'open', PChar(GetAppConfigDir(False)+'RES.bat'), nil, nil, SW_SHOWNORMAL);
end;

end.

