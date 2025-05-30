unit ukoneksi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, Buttons, INIFiles, Windows, IniPropStorage;

type

  { TfrmKoneksi }

  TfrmKoneksi = class(TForm)
    btSimpan: TSpeedButton;
    edHost: TEdit;
    edPass: TEdit;
    edPort: TEdit;
    edData: TEdit;
    edUser: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Panel1: TPanel;
    procedure btSimpanClick(Sender: TObject);
    procedure cbDataKeyPress(Sender: TObject; var Key: char);
    procedure edUserKeyPress(Sender: TObject; var Key: char);
    procedure edPassKeyPress(Sender: TObject; var Key: char);
    procedure edHostKeyPress(Sender: TObject; var Key: char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    IFile: TIniPropStorage;
  end;

var
  frmKoneksi: TfrmKoneksi;

implementation

{$R *.lfm}

{ TfrmKoneksi }

procedure TfrmKoneksi.cbDataKeyPress(Sender: TObject; var Key: char);
begin
  If (edData.Text<>'') and (Key=#13) then btSimpanClick(sender);
end;

procedure TfrmKoneksi.edUserKeyPress(Sender: TObject; var Key: char);
begin
  If (edUser.Text<>'') and (Key=#13) then edPass.SetFocus;
end;

procedure TfrmKoneksi.edPassKeyPress(Sender: TObject; var Key: char);
begin
  If (Key=#13) then edData.SetFocus;
end;

procedure TfrmKoneksi.edHostKeyPress(Sender: TObject; var Key: char);
begin
  If (edHost.Text<>'') and (key=#13) then edUser.SetFocus;
end;

procedure TfrmKoneksi.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    VK_F8 : btSimpanClick(Sender);
    VK_ESCAPE : self.Close;
  end;
end;

procedure TfrmKoneksi.FormShow(Sender: TObject);
begin
  edData.SetFocus;
end;

procedure TfrmKoneksi.btSimpanClick(Sender: TObject);
var
  Koneksi : TIniFile;
begin
  Koneksi:=TiniFile.Create(IFIle.ReadString('app.location','')+'\koneksi.ini');
  if edHost.Text='' then
  begin
    MessageDlg('Informasi','Hostname masih kosong, Silahkan isi !',mtInformation,[mbOK],0);
    edHost.SetFocus;
  end else
  if edUser.Text='' then
  begin
    MessageDlg('Informasi','Username masih kosong, Silahkan isi !',mtInformation,[mbOK],0);
    edUser.SetFocus;
  end else
  begin
    Koneksi.WriteString('Database','Hostname',edHost.Text);
    Koneksi.WriteString('Database','Username',edUser.Text);
    Koneksi.WriteString('Database','Password',edPass.Text);
    Koneksi.WriteString('Database','Port',edPort.Text);
    Koneksi.WriteString('Database','Database',edData.Text);
    Koneksi.Free;

    ShowMessage('Koneksi Database telah berubah');
  end;
end;

end.

