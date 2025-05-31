unit ubackup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls, jwatlhelp32, ufn,
  ComCtrls, ExtCtrls, Buttons, EditBtn, IniPropStorage, Windows, DateUtils, IniFiles, StrUtils;

type

  { TfrmBackup }

  TfrmBackup = class(TForm)
    btBack: TSpeedButton;
    btSimpan: TSpeedButton;
    cbPeriode: TComboBox;
    chBackup: TCheckBox;
    chJam1: TCheckBox;
    chJam2: TCheckBox;
    chJam3: TCheckBox;
    chKonfirmasi: TCheckBox;
    chPeriode: TCheckBox;
    chTutup: TCheckBox;
    chGDrive: TCheckBox;
    edDir: TDirectoryEdit;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Panel1: TPanel;
    sd: TSaveDialog;
    teJam1: TTimeEdit;
    teJam2: TTimeEdit;
    teJam3: TTimeEdit;
    tmrBackup: TTimer;
    procedure chJamChange(Sender: TObject);
    procedure chPeriodeChange(Sender: TObject);
    procedure btBackClick(Sender: TObject);
    procedure btSimpanClick(Sender: TObject);
    procedure chBackupChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure tmrBackupTimer(Sender: TObject);
    procedure Backup(AFile : string='';AutoClose : boolean=false;AUpload : boolean=false);
    procedure BackupDatabase;
  private
    { private declarations }
    function IsAppARunning: Boolean;
  public
    { public declarations }
    AppWasRunning : Boolean;
    lastbackup : TDateTime;
    IFile: TIniPropStorage;
    Hostname,Username,Password,Port,Database : string;
  end;

var
  frmBackup : TfrmBackup;

implementation

uses
  udm;

{$R *.lfm}

{ TfrmBackup }

procedure TfrmBackup.btBackClick(Sender: TObject);
begin
  sd.FileName:='BUD'+formatdatetime('yymmdd',Now)+'_'+Database+'.sql';
  sd.Execute;
  if sd.FileName<>'' then
  begin
    Backup(sd.FileName);
  end;
end;

procedure TfrmBackup.btSimpanClick(Sender: TObject);
var
  i : integer;
  function CekGCloneConfig : boolean;
  var
    Ini: TIniFile;
    FilePath: string;
    Keys: TStringList;
  begin
    Result:=false;
    FilePath:=GetAppConfigDir(False)+'rclone.conf';

    if not FileExists(FilePath) then
    begin
      with TStringList.Create do
      try
        SaveToFile(FilePath);
      finally
        Free;
      end;
    end;

    Ini:=TIniFile.Create(FilePath);
    Keys:=TStringList.Create;
    try
      Ini.ReadSection('gdrive',Keys);
      if Keys.Count<>0 then Result:=true;
    finally
      Keys.Free;
      Ini.Free;
    end;
  end;
begin
  if edDir.Text='' then
  begin
    ShowMessage('Lokasi backup masih kosong, silahkan isi !');
    edDir.SetFocus; Exit;
  end;

  if (RightStr(edDir.Text,1)<>'\') then edDir.Text:=edDir.Text+'\';
  IFile.WriteBoolean('autobackup.aktif',chBackup.Checked);
  IFile.WriteBoolean('autobackup.konfirmasi',chKonfirmasi.Checked);
  IFile.WriteString('autobackup.dir',edDir.Text);
  IFile.WriteBoolean('autobackup.periode',chPeriode.Checked);
  IFile.WriteString('autobackup.jperiode',cbPeriode.Text);
  IFile.WriteBoolean('autobackup.jam1',chJam1.Checked);
  IFile.WriteString('autobackup.jjam1',teJam1.Text);
  IFile.WriteBoolean('autobackup.jam2',chJam2.Checked);
  IFile.WriteString('autobackup.jjam2',teJam2.Text);
  IFile.WriteBoolean('autobackup.jam3',chJam3.Checked);
  IFile.WriteString('autobackup.jjam3',teJam3.Text);
  IFile.WriteBoolean('autobackup.tutup',chTutup.Checked);
  IFile.WriteBoolean('autobackup.gdrive',chGDrive.Checked);
  if (chGDrive.Checked) and (CekGCloneConfig=false) then
  begin
    try
      GCloneConfig;
    finally
      Showmessage('Perubahan berhasil di simpan');
    end;
  end else
  Showmessage('Perubahan berhasil di simpan');
end;

procedure TfrmBackup.chPeriodeChange(Sender: TObject);
begin
  if (chPeriode.Checked) then
  begin
    chJam1.Checked:=false;
    chJam2.Checked:=false;
    chJam3.Checked:=false;
    chPeriode.Checked:=true;
  end;
end;

procedure TfrmBackup.chJamChange(Sender: TObject);
begin
  if (chJam1.Checked) or (chJam2.Checked) or (chJam3.Checked) then
  begin
    chPeriode.Checked:=false;
  end;
end;

procedure TfrmBackup.chBackupChange(Sender: TObject);
begin
  tmrBackup.Enabled:=chBackup.Enabled;
end;

procedure TfrmBackup.FormCreate(Sender: TObject);
begin
  lastbackup:=now;
  AppWasRunning:=false;
end;

procedure TfrmBackup.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case key of
    VK_F3 : btBackClick(Sender);
    VK_F8 : btSimpanClick(Sender);
    VK_ESCAPE : self.Close;
  end;
end;

function TfrmBackup.IsAppARunning: Boolean;
var
  SnapShot: THandle;
  ProcEntry: TProcessEntry32;
begin
  Result := False;
  SnapShot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if SnapShot = INVALID_HANDLE_VALUE then Exit;
  ProcEntry.dwSize := SizeOf(ProcEntry);
  if Process32First(SnapShot, ProcEntry) then
  begin
    repeat
      if AnsiCompareText(ExtractFileName(ProcEntry.szExeFile), ExtractFileName(IFile.ReadString('app.exename',''))) = 0 then
      begin
        Result := True;
        Break;
      end;
    until not Process32Next(SnapShot, ProcEntry);
  end;
  CloseHandle(SnapShot);
end;

procedure TfrmBackup.tmrBackupTimer(Sender: TObject);
var
  IsRunning: Boolean;
begin
  if (IFile.ReadBoolean('autobackup.tutup',false)) then
  begin
    IsRunning:=IsAppARunning;

    if IsRunning then
    Label5.Caption:='Aplikasi sedang dibuka' else
    Label5.Caption:='Aplikasi sedang ditutup';

    if AppWasRunning and not IsRunning then
    begin
      if Now-lastbackup>EncodeTime(0,0,1,0) then
      begin
        BackupDatabase;
      end;
    end;

    AppWasRunning:=IsRunning;
  end;

  if formatdatetime('hh:nn',lastbackup)=formatdatetime('hh:nn',Now) then exit;

  if (IFile.ReadBoolean('autobackup.periode',false)) then
  begin
    case IFile.ReadString('autobackup.jperiode','') of
      'Setiap 1 Menit' : if now>=incminute(lastbackup,1) then BackupDatabase;
      'Setiap 5 Menit' : if now>=incminute(lastbackup,5) then BackupDatabase;
      'Setiap 15 Menit' : if now>=incminute(lastbackup,15) then BackupDatabase;
      'Setiap 30 Menit' : if now>=incminute(lastbackup,30) then BackupDatabase;
      'Setiap 1 Jam' : if now>=inchour(lastbackup,1) then BackupDatabase;
      'Setiap 3 Jam' : if now>=inchour(lastbackup,3) then BackupDatabase;
      'Setiap 6 Jam' : if now>=inchour(lastbackup,6) then BackupDatabase;
      'Setiap 12 Jam' : if now>=inchour(lastbackup,12) then BackupDatabase;
    end;
  end;

  if (IFile.ReadBoolean('autobackup.jam1',false)) then
  begin
    if ReplaceStr(formatdatetime('h:nn',Now),'.',':')=
    ReplaceStr(IFile.ReadString('autobackup.jjam1','0:00'),'.',':') then
    BackupDatabase;
  end;

  if (IFile.ReadBoolean('autobackup.jam2',false)) then
  begin
    if ReplaceStr(formatdatetime('h:nn',Now),'.',':')=
    ReplaceStr(IFile.ReadString('autobackup.jjam2','0:00'),'.',':') then
    BackupDatabase;
  end;

  if (IFile.ReadBoolean('autobackup.jam3',false)) then
  begin
    if ReplaceStr(formatdatetime('h:nn',Now),'.',':')=
    ReplaceStr(IFile.ReadString('autobackup.jjam3','0:00'),'.',':') then
    BackupDatabase;
  end;
end;

procedure TfrmBackup.Backup(AFile : string='';AutoClose : boolean=false;AUpload : boolean=false);
begin
  if (AFile='') then AFile:=edDir.Text+'BUD'+formatdatetime('yymmdd',Now)+'_'+Database+'.sql';

  if not DirectoryExists(ExtractFilePath(AFile)) then CreateDir(ExtractFilePath(AFile));
  try
    if FileExists(AFile) and DeleteFile(PChar(AFile+'.bak')) then
    RenameFile(AFile,AFile+'.bak');
  except
  end;

  with TStringList.Create do
  try
    Add('@echo off');
    Add('title Backup Database');
    Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Silahkan Tunggu...');

    if (Password='') then
    Add('mysqldump -u'+Username+' -h'+Hostname+' -P'+Port+' '+Database+' --max_allowed_packet=512M --single-transaction --quick > "'+AFile+'"') else
    Add('mysqldump -u'+Username+' -p'+Password+' -h'+Hostname+' -P'+Port+' '+Database+' --max_allowed_packet=512M --single-transaction --quick > "'+AFile+'"');
    Add('if errorlevel 1 goto msgerror');
    Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Backup database berhasil');
    if (AUpload) then
    begin
      Add('gclone --config="'+GetAppConfigDir(False)+'rclone.conf" copy "'+AFile+'" gdrive:/"BACKUP DATABASE"/');
      Add('if errorlevel 1 goto msgerror1');
      Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Upload file berhasil');
    end;
    if not AutoClose then Add('pause');
    Add('exit');
    Add(':msgerror');
    Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Backup database gagal');
    Add('pause');
    Add('exit');
    Add(':msgerror1');
    Add('echo %time:~0,2%:%time:~3,2%:%time:~6,2% Upload database gagal');
    Add('pause');
    Add('exit');
    SaveToFile(GetAppConfigDir(False)+'BUD_'+Database+'.bat');
  finally
    Free;
  end;

  ShellExecute(0, 'open', PChar(GetAppConfigDir(False)+'BUD_'+Database+'.bat'), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmBackup.BackupDatabase;
begin
  lastbackup:=Now;
  if IFile.ReadBoolean('autobackup.konfirmasi',false) then
  case QuestionDlg('Informasi','Apakah anda yakin akan melakukan backup database',
  mtInformation,[mrYes,'Ya',mrNo,'Tidak'],0) of
    mrYes : Backup('',true,IFile.ReadBoolean('autobackup.gdrive',false));
  end else
  Backup('',true,IFile.ReadBoolean('autobackup.gdrive',false));
end;

end.

