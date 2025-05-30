unit uhapus;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Buttons, Windows, StrUtils, inifiles, DB, IniPropStorage,
  ZConnection, ZDataset, Grids, DBGrids;

type

  { TfrmHapus }

  TfrmHapus = class(TForm)
    btHapus: TSpeedButton;
    chAll: TCheckBox;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    GroupBox5: TGroupBox;
    Label1: TLabel;
    Label4: TLabel;
    Panel1: TPanel;
    sg: TStringGrid;
    procedure btHapusClick(Sender: TObject);
    procedure chAllChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure sgClick(Sender: TObject);
    procedure sgGetCheckboxState(Sender: TObject; ACol, ARow: Integer;
      var Value: TCheckboxState);
    procedure sgSetCheckboxState(Sender: TObject; ACol, ARow: Integer;
      const Value: TCheckboxState);
  private
    { private declarations }
    Koneksi : TZConnection;
    zq1,zq2,zq3 : TZQuery;
    Database : string;
  public
    { public declarations }
    IFile: TIniPropStorage;
  end;

var
  frmHapus: TfrmHapus;

implementation

uses udm, ufn;

{$R *.lfm}

{ TfrmHapus }

procedure TfrmHapus.btHapusClick(Sender: TObject);
var
  i : integer;
begin
  for i := 0 to sg.RowCount-1 do
  begin
    if sg.Cells[0,i]='1' then
    begin
      Exec('delete from '+sg.Cells[1,i],zq3);
      Exec('truncate table '+sg.Cells[1,i],zq3);
    end;
  end;

  sgClick(Sender);
end;

procedure TfrmHapus.chAllChange(Sender: TObject);
var
  i : integer;
begin
  for i := 0 to sg.RowCount-1 do
  begin
    sgSetCheckBoxState(Sender,0,i,chAll.State);
  end;
end;

procedure TfrmHapus.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    VK_F3 : btHapusClick(Sender);
    VK_ESCAPE : self.Close;
  end;
end;

procedure TfrmHapus.FormShow(Sender: TObject);
var
  i : integer;
  aIniFile : TIniFile;
  aSection : string;
begin
  aIniFile:=TiniFile.Create(IFIle.ReadString('app.location','')+'\koneksi.ini');
  try
    aSection:=aIniFile.ReadString('Database','Aktif','Database');
    Koneksi:=OpenConnection(aIniFile.ReadString(aSection,'Hostname',''),
    aIniFile.ReadString(aSection,'Username',''),
    aIniFile.ReadString(aSection,'Password',''),
    aIniFile.ReadString(aSection,'Port',''),'');
    Database:=aIniFile.ReadString(aSection,'Database','');
  finally
    aIniFile.Free;
  end;
  zq1:=TZQuery.Create(nil);zq2:=TZQuery.Create(nil);zq3:=TZQuery.Create(nil);
  zq1.Connection:=Koneksi;zq2.Connection:=Koneksi;zq3.Connection:=Koneksi;
  DataSource1.DataSet:=zq3;

  sg.Clear;sg.RowCount:=0;chAll.Checked:=false;
  if Open('SHOW FULL TABLES FROM '+Database+' WHERE Table_type=''BASE TABLE''',zq1) then
  begin
    sg.RowCount:=zq1.RecordCount;i:=0;
    while not zq1.EOF do
    begin
      sg.Cells[0,i]:='0';
      sg.Cells[1,i]:=zq1.Fields[0].AsString;
      Inc(i);
      zq1.Next;
    end;
  end;

  Exec('use `'+Database+'`',zq3);
  sg.Row:=0;sg.Col:=1;
  sgClick(Sender);
end;

procedure TfrmHapus.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  zq1.Free;zq2.Free;zq3.Free;
  Koneksi.Free;
end;

procedure TfrmHapus.sgClick(Sender: TObject);
begin
  if (sg.Col=1) then
  begin
    Open('select * from '+sg.Cells[1,sg.Row]+' limit 100',zq3);
  end;
end;

procedure TfrmHapus.sgGetCheckboxState(Sender: TObject; ACol, ARow: Integer;
  var Value: TCheckboxState);
begin
  case sg.Cells[ACol, ARow] of
    '0': value := cbUnchecked;
    '1': Value := cbChecked;
    '2': value := cbGrayed;
  end;
end;

procedure TfrmHapus.sgSetCheckboxState(Sender: TObject; ACol, ARow: Integer;
  const Value: TCheckboxState);
begin
  case Value of
    cbUnChecked: sg.Cells[ACol, ARow] := '0';
    cbChecked: sg.Cells[ACol, ARow] := '1';
    cbGrayed: sg.Cells[ACol, ARow] := '2';
  end;
end;

end.

