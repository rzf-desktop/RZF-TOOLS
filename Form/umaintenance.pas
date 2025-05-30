unit umaintenance;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, ExtCtrls, Buttons, Windows, StrUtils, inifiles, DB, IniPropStorage,
  ZConnection, ZDataset, Grids, DBGrids;

type

  { TfrmMaintenance }

  TfrmMaintenance = class(TForm)
    btOptimize: TSpeedButton;
    btCheck: TSpeedButton;
    btAnalyze: TSpeedButton;
    btRepair: TSpeedButton;
    cbMethod: TComboBox;
    chOLocal: TCheckBox;
    chALocal: TCheckBox;
    chQuick: TCheckBox;
    chUsefrm: TCheckBox;
    chRLocal: TCheckBox;
    chExtended: TCheckBox;
    chAll: TCheckBox;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    GroupBox4: TGroupBox;
    GroupBox5: TGroupBox;
    Panel1: TPanel;
    sg: TStringGrid;
    procedure btAnalyzeClick(Sender: TObject);
    procedure btCheckClick(Sender: TObject);
    procedure btOptimizeClick(Sender: TObject);
    procedure btRepairClick(Sender: TObject);
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
  frmMaintenance: TfrmMaintenance;

implementation

uses udm, ufn;

{$R *.lfm}

{ TfrmMaintenance }

procedure TfrmMaintenance.btOptimizeClick(Sender: TObject);
var
  i : integer;
  local,tables : string;
begin
  local:='';tables:='';
  if chOLocal.Checked then local:=' no_write_to_binlog';

  for i := 0 to sg.RowCount-1 do
  begin
    if sg.Cells[0,i]='1' then
    begin
      if tables='' then tables:=sg.Cells[1,i] else
      tables:=tables+','+sg.Cells[1,i];
    end;
  end;

  if tables='' then zq3.Close else
  Open('optimize'+local+' table '+tables,zq3);
end;

procedure TfrmMaintenance.btAnalyzeClick(Sender: TObject);
var
  i : integer;
  local,tables : string;
begin
  tables:='';
  if chALocal.Checked then local:=' local' else
  local:=' no_write_to_binlog';

  for i := 0 to sg.RowCount-1 do
  begin
    if sg.Cells[0,i]='1' then
    begin
      if tables='' then tables:=sg.Cells[1,i] else
      tables:=tables+','+sg.Cells[1,i];
    end;
  end;

  if tables='' then zq3.Close else
  Open('analyze'+local+' table '+tables,zq3);
end;

procedure TfrmMaintenance.btCheckClick(Sender: TObject);
var
  i : integer;
  method,tables : string;
begin
  tables:='';
  case cbMethod.ItemIndex of
    0 : method:='';
    else method:=' '+cbMethod.Text;
  end;

  for i := 0 to sg.RowCount-1 do
  begin
    if sg.Cells[0,i]='1' then
    begin
      if tables='' then tables:=sg.Cells[1,i] else
      tables:=tables+','+sg.Cells[1,i];
    end;
  end;

  if tables='' then zq3.Close else
  Open('check table '+tables+method,zq3);
end;

procedure TfrmMaintenance.btRepairClick(Sender: TObject);
var
  i : integer;
  method,local,tables : string;
begin
  method:='';local:='';tables:='';
  if chQuick.Checked then method:=method+' quick';
  if chUsefrm.Checked then method:=method+' use_frm';
  if chRLocal.Checked then local:=' no_write_to_binlog';
  if chExtended.Checked then method:=method+' extended';

  for i := 0 to sg.RowCount-1 do
  begin
    if sg.Cells[0,i]='1' then
    begin
      if tables='' then tables:=sg.Cells[1,i] else
      tables:=tables+','+sg.Cells[1,i];
    end;
  end;

  if tables='' then zq3.Close else
  Open('repair'+local+' table '+tables+method,zq3);
end;

procedure TfrmMaintenance.chAllChange(Sender: TObject);
var
  i : integer;
begin
  for i := 0 to sg.RowCount-1 do
  begin
    sgSetCheckBoxState(Sender,0,i,chAll.State);
  end;
end;

procedure TfrmMaintenance.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    VK_ESCAPE : self.Close;
  end;
end;

procedure TfrmMaintenance.FormShow(Sender: TObject);
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

  sg.Clear;sg.RowCount:=0;chAll.Checked:=true;
  if Open('SHOW FULL TABLES FROM '+Database+' WHERE Table_type=''BASE TABLE''',zq1) then
  begin
    sg.RowCount:=zq1.RecordCount;i:=0;
    while not zq1.EOF do
    begin
      sg.Cells[0,i]:='1';
      sg.Cells[1,i]:=zq1.Fields[0].AsString;
      Inc(i);
      zq1.Next;
    end;
  end;

  Exec('use `'+Database+'`',zq3);
end;

procedure TfrmMaintenance.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  zq1.Free;zq2.Free;zq3.Free;
  Koneksi.Free;
end;

procedure TfrmMaintenance.sgClick(Sender: TObject);
begin
  if (sg.Col=1) then
  begin
    if (sg.Cells[0,sg.Row]='0') then sg.Cells[0,sg.Row]:='1' else sg.Cells[0,sg.Row]:='0';
  end;
end;

procedure TfrmMaintenance.sgGetCheckboxState(Sender: TObject; ACol, ARow: Integer;
  var Value: TCheckboxState);
begin
  case sg.Cells[ACol, ARow] of
    '0': value := cbUnchecked;
    '1': Value := cbChecked;
    '2': value := cbGrayed;
  end;
end;

procedure TfrmMaintenance.sgSetCheckboxState(Sender: TObject; ACol, ARow: Integer;
  const Value: TCheckboxState);
begin
  case Value of
    cbUnChecked: sg.Cells[ACol, ARow] := '0';
    cbChecked: sg.Cells[ACol, ARow] := '1';
    cbGrayed: sg.Cells[ACol, ARow] := '2';
  end;
end;

end.

