unit ufn;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, Classes, SysUtils, Registry, applist, Menus, TypInfo, RegExpr, ExtCtrls,
  IniPropStorage, Forms, udownload,
  ShlObj, FileUtil, Dialogs, IniFiles, ZConnection, ZDataset, StrUtils, Controls,
  Process, Clipbrd, Graphics, ShellAPI, DateUtils;

type

  TDownloadItem = record
    Link: string;
    NamaFile: string;
    NamaDownload: string;
  end;

const
  ResourceNames: array[0..5] of string = (
    'libmySQL50.dll',
    'ssleay32.dll',
    'libeay32.dll',
    'mysqldump.exe',
    'mysql.exe',
    'gclone.exe'
  );
  DownloadList: array[0..2] of TDownloadItem = (
    (Link:'https://www.ultraviewer.net/en/UltraViewer_setup_6.6_en.exe';NamaFile:'UltraViewer_setup_6.6_en.exe';NamaDownload:'Ultraviewer'),
    (Link:'https://s3.amazonaws.com/SQLyog_Community/SQLyog+13.1.5/SQLyog-13.1.5-0.x86Community.exe';NamaFile:'SQLyog-13.1.5-0.x86Community.exe';NamaDownload:'SQLYog'),
    (Link:'';NamaFile:'';NamaDownload:'-')
  );

{
EP LX-310
EP LX-300
EP LQ-310

EP TM-U220
EP TM-T82
}

procedure ExtractAllResources;
procedure AddFolderToPath(const Folder: string);
procedure RemoveFolderFromPath(const Folder: string);
procedure AddScheduledTask;
procedure RemoveScheduledTask;
procedure AddAppToUninstall;
procedure RemoveAppFromUninstall;
function FindExeFiles(const Folder, Filter: string) : string;
function GetUserDownloadFolder: string;
procedure WriteLog(const Msg: string);
function TampilkanProperti(App: TAppEntry) : string;
procedure HapusSeparatorBerurutan(Menu: TPopupMenu);
function HapusVersi(const bName: string): string;
procedure LoadIconToMenuItem(const ExePath: string; MenuItem: TMenuItem);
function FormatSize(Size: Int64): String;
function FormatSpeed(Speed: LongInt): String;
function SecToHourAndMin(const ASec: LongInt): String;
procedure ShowNotif(aBallonIndex : integer;aTitle,aMessage : string);
procedure KillProcessByName(const AProcessName: string);
procedure GCloneConfig;
procedure CreateDownloadPopup(aMenu : TMenuItem);
function StartDownload(const URL, FileName: string) : TfrmDownload;
Function FixQuery(AQuery : string) : string;
Function Open(AQuery : string;AZQuery : TZQuery;AReconnect : integer=0) : Boolean;
Procedure Exec(AQuery : string;AZQuery : TZQuery;AReconnect : integer=0);
function OpenConnection(aHost,aUser,aPass,aPort,aData : string) : TZConnection;
function LoadKoneksi(aIFile : TIniPropStorage) : TForm;
function LoadMaintenance(aIFile : TIniPropStorage) : TForm;
function LoadBackup(aIFile : TIniPropStorage) : TForm;
function LoadRestore(aIFile : TIniPropStorage) : TForm;
function LoadHapus(aIFile : TIniPropStorage) : TForm;

implementation

uses
  udm, ubackup, ukoneksi, urestore, umaintenance, uhapus;

procedure ExtractAllResources;
var
  i: Integer;
  ResStream: TResourceStream;
  OutputPath: string;
  T: TextFile;
begin
  AddFolderToPath(GetAppConfigDir(False));
  if not FileExists(GetAppConfigDir(False)+'rclone.conf') then
  begin
    AssignFile(T, GetAppConfigDir(False)+'rclone.conf');
    Rewrite(T);
    try
      Writeln(T, '; rclone config file');
    finally
      CloseFile(T);
    end;
  end;

  for i := 0 to High(ResourceNames) do
  begin
    try
      ResStream := TResourceStream.Create(HInstance, UpperCase(ChangeFileExt(ResourceNames[i],'')), RT_RCDATA);
      try
        OutputPath := GetAppConfigDir(False) + ResourceNames[i];
        if not FileExists(OutputPath) then
          ResStream.SaveToFile(OutputPath);
      finally
        ResStream.Free;
      end;
    except
    end;
  end;
end;

procedure AddFolderToPath(const Folder: string);
var
  OldPath, NewPath: string;
begin
  OldPath := GetEnvironmentVariable('PATH');
  NewPath := Folder + ';' + OldPath;
  SetEnvironmentVariable('PATH', PChar(NewPath));
end;

procedure RemoveFolderFromPath(const Folder: string);
var
  OldPath, NewPath: string;
  PathList: TStringList;
  i: Integer;
begin
  OldPath := GetEnvironmentVariable('PATH');

  PathList := TStringList.Create;
  try
    PathList.Delimiter := ';';
    PathList.StrictDelimiter := True;
    PathList.DelimitedText := OldPath;

    for i := PathList.Count - 1 downto 0 do
      if SameText(ExcludeTrailingPathDelimiter(PathList[i]), ExcludeTrailingPathDelimiter(Folder)) then
        PathList.Delete(i);

    NewPath := PathList.DelimitedText;
    SetEnvironmentVariable('PATH', PChar(NewPath));
  finally
    PathList.Free;
  end;
end;

procedure AddScheduledTask;
var
  TaskCmd, XMLPath: string;
  XMLFile: TextFile;
begin
  XMLPath := GetAppConfigDir(False) + '\RZFTools.xml';

  AssignFile(XMLFile, XMLPath);
  Rewrite(XMLFile);
  WriteLn(XMLFile,
    '<?xml version="1.0" encoding="UTF-16"?>' + sLineBreak +
    '<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">' + sLineBreak +
    '  <RegistrationInfo><Author>RZF</Author></RegistrationInfo>' + sLineBreak +
    '  <Triggers><LogonTrigger><Enabled>true</Enabled></LogonTrigger></Triggers>' + sLineBreak +
    '  <Principals><Principal id="Author"><RunLevel>HighestAvailable</RunLevel><LogonType>InteractiveToken</LogonType></Principal></Principals>' + sLineBreak +
    '  <Settings>' +
    '<MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>' +
    '<DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>' +
    '<StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>' +
    '<AllowHardTerminate>true</AllowHardTerminate>' +
    '<StartWhenAvailable>true</StartWhenAvailable>' +
    '<RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>' +
    '<IdleSettings><StopOnIdleEnd>false</StopOnIdleEnd><RestartOnIdle>false</RestartOnIdle></IdleSettings>' +
    '<AllowStartOnDemand>true</AllowStartOnDemand><Enabled>true</Enabled>' +
    '<Hidden>true</Hidden><RunOnlyIfIdle>false</RunOnlyIfIdle><WakeToRun>false</WakeToRun>' +
    '<ExecutionTimeLimit>PT0S</ExecutionTimeLimit><Priority>7</Priority>' +
    '</Settings>' + sLineBreak +
    '  <Actions Context="Author"><Exec>' +
    '<Command>' + ParamStr(0) + '</Command>' +
    '<Arguments>/tray</Arguments>' +
    '</Exec></Actions>' + sLineBreak +
    '</Task>'
  );
  CloseFile(XMLFile);

  TaskCmd := 'schtasks /create /tn "RZFTools" /xml "' + XMLPath + '" /f';
  ShellExecute(0, 'open', 'cmd.exe', PChar('/C ' + TaskCmd), nil, SW_HIDE);
end;

procedure RemoveScheduledTask;
var
  TaskCmd: string;
begin
  TaskCmd := 'schtasks /delete /tn "RZFTools" /f';
  ShellExecute(0, 'open', 'cmd.exe', PChar('/C ' + TaskCmd), nil, SW_HIDE);
end;

procedure AddAppToUninstall;
var
  Reg: TRegistry;
  UninstallKey: String;
begin
  UninstallKey := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\RZFTools';

  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;

    if Reg.OpenKey(UninstallKey, True) then
    begin
      Reg.WriteString('DisplayName', 'Aplikasi Tools RZF');
      Reg.WriteString('UninstallString', ExtractFileDir(ParamStr(0)));
      Reg.WriteString('Publisher', 'RZFSoftware');
      Reg.WriteString('DisplayVersion', '1.0');
      Reg.WriteString('InstallLocation', ExtractFileDir(ParamStr(0)));
      Reg.WriteString('DisplayIcon', ParamStr(0));
    end;
  finally
    Reg.Free;
  end;
end;

procedure RemoveAppFromUninstall;
var
  Reg: TRegistry;
  UninstallKey: String;
begin
  UninstallKey := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\RZFTools';

  Reg := TRegistry.Create(KEY_WRITE or KEY_WOW64_32KEY);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.KeyExists(UninstallKey) then
    begin
      Reg.DeleteKey(UninstallKey);
    end;
  finally
    Reg.Free;
  end;
end;

function GetUserDownloadFolder: string;
var
  Path: array[0..MAX_PATH] of Char;
begin
  if SHGetSpecialFolderPath(0, Path, CSIDL_PERSONAL, False) then
    Result := IncludeTrailingPathDelimiter(Path) + 'Downloads'
  else
    Result := GetUserDir + 'Downloads';
end;

function FindExeFiles(const Folder, Filter: string) : string;
var
  SearchRec: TSearchRec;
begin
  Result:='';
  if FindFirst(Folder + '\*.exe', faAnyFile, SearchRec) = 0 then
  begin
    repeat
      if Pos(UpperCase(Filter), UpperCase(SearchRec.Name)) > 0 then
        Result:=Folder+SearchRec.Name;
    until FindNext(SearchRec) <> 0;
    FindClose(SearchRec);
  end;
end;

procedure HapusSeparatorBerurutan(Menu: TPopupMenu);
var
  i: Integer;
begin
  i := Menu.Items.Count - 1;
  while i > 0 do
  begin
    if (Menu.Items[i].Caption = '-') and (Menu.Items[i - 1].Caption = '-') then
      Menu.Items.Delete(i); // hapus salah satu separator
    Dec(i);
  end;

  // Opsional: hapus separator di awal dan akhir menu
  if (Menu.Items.Count > 0) and (Menu.Items[0].Caption = '-') then
    Menu.Items.Delete(0);
  if (Menu.Items.Count > 0) and (Menu.Items[Menu.Items.Count - 1].Caption = '-') then
    Menu.Items.Delete(Menu.Items.Count - 1);
end;

procedure WriteLog(const Msg: string);
var
  LogFile: TextFile;
begin
  AssignFile(LogFile, 'applog.txt');
  if FileExists('applog.txt') then
    Append(LogFile)
  else
    Rewrite(LogFile);
  WriteLn(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ' + Msg);
  CloseFile(LogFile);
end;

function TampilkanProperti(App: TAppEntry) : string;
var
  i: Integer;
  PropInfo: PPropInfo;
  PropList: PPropList;
  Count: Integer;
  PropName, PropValue: string;
  Output: string;
begin
  Count := GetPropList(PTypeInfo(App.ClassInfo), tkAny, nil);
  if Count = 0 then Exit;

  GetMem(PropList, Count * SizeOf(PPropInfo));
  try
    GetPropList(PTypeInfo(App.ClassInfo), tkAny, PropList);
    for i := 0 to Count - 1 do
    begin
      PropInfo := PropList^[i];
      PropName := string(PropInfo^.Name);
      PropValue := GetPropValue(App, PropName, True); // True untuk konversi otomatis
      Output := Output + PropName + ' = ' + PropValue + sLineBreak;
    end;
  finally
    Result:=Output;
    FreeMem(PropList);
  end;
end;

function HapusVersi(const bName: string): string;
var
  s: string;
  regex: TRegExpr;
begin
  s := bName;
  s := StringReplace(s, 'version', '', [rfReplaceAll]);
  s := StringReplace(s, 'Version', '', [rfReplaceAll]);
  s := StringReplace(s, 'versi', '', [rfReplaceAll]);
  s := StringReplace(s, 'Versi', '', [rfReplaceAll]);
  s := StringReplace(s, '(64 bit)', '', [rfReplaceAll]);
  s := StringReplace(s, '(32 bit)', '', [rfReplaceAll]);

  regex := TRegExpr.Create;
  try
    regex.Expression := '\s*(v?\s*\d+(\.\d+)*)(\s*)?$';
    if regex.Exec(s) then
      s := Trim(Copy(s, 1, regex.MatchPos[0] - 1));
  finally
    regex.Free;
  end;
  Result := Trim(s);
end;

procedure LoadIconToMenuItem(const ExePath: string; MenuItem: TMenuItem);
var
  SmallIcon: HICON;
  Icon: TIcon;
begin
  if ExtractIconEx(PChar(ExePath), 0, nil, @SmallIcon, 1) > 0 then
  begin
    Icon := TIcon.Create;
    try
      Icon.Handle := SmallIcon;
      MenuItem.ImageIndex:=DM.IList.AddIcon(Icon);   ;
    finally
      Icon.Free;
      DestroyIcon(SmallIcon);
    end;
  end;
end;

function FormatSize(Size: Int64): String;
const
  KB = 1024;
  MB = 1024 * KB;
  GB = 1024 * MB;
begin
  if Size < KB then
    Result := FormatFloat('#,##0 Bytes', Size)
  else if Size < MB then
    Result := FormatFloat('#,##0.0 KB', Size / KB)
  else if Size < GB then
    Result := FormatFloat('#,##0.0 MB', Size / MB)
  else
    Result := FormatFloat('#,##0.0 GB', Size / GB);
end;

function FormatSpeed(Speed: LongInt): String;
const
  KB = 1024;
  MB = 1024 * KB;
  GB = 1024 * MB;
begin
  if Speed < KB then
    Result := FormatFloat('#,##0 bits/s', Speed)
  else if Speed < MB then
    Result := FormatFloat('#,##0.0 kB/s', Speed / KB)
  else if Speed < GB then
    Result := FormatFloat('#,##0.0 MB/s', Speed / MB)
  else
    Result := FormatFloat('#,##0.0 GB/s', Speed / GB);
end;

function SecToHourAndMin(const ASec: LongInt): String;
var
  Hour, Min, Sec: LongInt;
begin
   Hour := Trunc(ASec/3600);
   Min  := Trunc((ASec - Hour*3600)/60);
   Sec  := ASec - Hour*3600 - 60*Min;
   Result := IntToStr(Hour) + 'h: ' + IntToStr(Min) + 'm: ' + IntToStr(Sec) + 's';
end;

procedure ShowNotif(aBallonIndex : integer;aTitle,aMessage : string);
begin
  if not DM.ti.Visible then exit;
  case aBallonIndex of
    0 : DM.ti.BalloonFlags:=bfInfo;
    1 : DM.ti.BalloonFlags:=bfWarning;
    2 : DM.ti.BalloonFlags:=bfError;
  else
    DM.ti.BalloonFlags:=bfNone;
  end;

  DM.ti.BalloonTitle:=aTitle;
  DM.ti.BalloonHint:=aMessage;
  DM.ti.ShowBalloonHint;
end;

procedure KillProcessByName(const AProcessName: string);
var
  AProc: TProcess;
begin
  AProc := TProcess.Create(nil);
  try
    AProc.Executable := 'taskkill';
    AProc.Parameters.Add('/F'); // Force
    AProc.Parameters.Add('/IM'); // Image Name
    AProc.Parameters.Add(AProcessName);
    AProc.Options := [poWaitOnExit, poNoConsole];
    AProc.Execute;
  finally
    AProc.Free;
  end;
end;

procedure GCloneConfig;
var
  i: integer;
  AProcess: TProcess;
  StartTime: TDateTime;
  OutputLines: TStringList;
  LinkExists: boolean;
begin
  LinkExists := false;
  StartTime := Now;

  KillProcessByName('gclone.exe');
  KillProcessByName('rclone.exe');

  AProcess := TProcess.Create(nil);
  OutputLines := TStringList.Create;
  try
    AProcess.Executable := 'gclone';
    AProcess.Parameters.Add('--config="'+GetAppConfigDir(False)+'rclone.conf"');
    AProcess.Parameters.Add('config');
    AProcess.Parameters.Add('create');
    AProcess.Parameters.Add('gdrive');
    AProcess.Parameters.Add('drive');
    //AProcess.Parameters.Add('client_id');
    //AProcess.Parameters.Add('your-client-id.apps.googleusercontent.com');
    //AProcess.Parameters.Add('client_secret');
    //AProcess.Parameters.Add('your-client-secret');
    AProcess.Parameters.Add('scope');
    AProcess.Parameters.Add('drive');

    AProcess.Options := [poUsePipes, poNoConsole];
    AProcess.Execute;

    // Baca output sampai proses selesai
    while (AProcess.Running or (AProcess.Output.NumBytesAvailable > 0)) do
    begin
      if AProcess.Output.NumBytesAvailable > 0 then
      begin
        OutputLines.LoadFromStream(AProcess.Output);
        for i := 0 to OutputLines.Count - 1 do
        begin
          if Pos('http://127.0.0.1:', OutputLines[i]) > 0 then
          begin
            LinkExists := true;
            case QuestionDlg('Login Google', 'Jika browser tidak otomatis terbuka, silahkan login melalui link di bawah ini'+#10#13
            +Trim(Copy(OutputLines[i], Pos('http', OutputLines[i]), MaxInt)), mtInformation, [mrYes, 'Salin Link', mrNo, 'Tutup'], '') of
              mrYes :
              begin
                Clipboard.AsText := Trim(Copy(OutputLines[i], Pos('http', OutputLines[i]), MaxInt));
                ShowMessage('Link telah disalin ke clipboard!');
              end;
            end;
          end;
        end;
      end;

      if ((SecondsBetween(Now, StartTime) > 15) and (LinkExists=false)) or (SecondsBetween(Now, StartTime) > 60) then
      begin
        AProcess.Terminate(0);
        ShowMessage('Prosess timeout, silahkan coba lagi!');
      end;
      Sleep(100);
    end;
  finally
    OutputLines.Free;
    AProcess.Free;
  end;
end;

procedure CreateDownloadPopup(aMenu : TMenuItem);
var
  i: Integer;
  Item: TMenuItem;
begin
  aMenu.Clear;
  for i := Low(DownloadList) to High(DownloadList) do
  begin
    Item := TMenuItem.Create(aMenu);
    Item.Caption := DownloadList[i].NamaDownload;
    Item.Tag := i;
    if (Item.Caption<>'-') then
    begin
      Item.OnClick := @DM.pmClick;
    end;
    aMenu.Add(Item);
  end;
end;

function StartDownload(const URL, FileName: string) : TfrmDownload;
var
  SaveDialog: TSaveDialog;
  SavePath,Ext: string;
begin
  Result := nil;

  SaveDialog := TSaveDialog.Create(nil);
  try
    SaveDialog.Title := 'Simpan File';
    Ext := ExtractFileExt(FileName);
    if Ext <> '' then
      SaveDialog.Filter := UpperCase(Copy(Ext, 2, MaxInt)) + ' File (*' + Ext + ')|*' + Ext
    else
      SaveDialog.Filter := 'Semua File|*.*';
    SaveDialog.FileName := FileName;
    SaveDialog.InitialDir := GetUserDownloadFolder;

    if SaveDialog.Execute then
    begin
      SavePath := SaveDialog.FileName;

      Result := TfrmDownload.Create(nil);
      Result.StartDownload(URL, SavePath);
      Result.ShowModal;
      if Result.Downloaded then
      ShellExecute(0, 'open', PChar(SaveDialog.FileName), nil, nil, SW_SHOWNORMAL);
      Result.Free;
    end;
  finally
    SaveDialog.Free;
  end;
end;

Function FixQuery(AQuery : string) : string;
var
  isQuotes : boolean;
  i : integer;
  function CekQuotes : boolean;
  var
    s : string;
    function GetWords(aLength : integer) : string;
    var
      j : integer;
    begin
      Result:='';
      if aLength>0 then
      begin
        for j := i+1 to i+aLength do
        Result:=Result+AQuery[j];
      end else
      if aLength<0 then
      begin
        for j := i+aLength to i-1 do
        Result:=Result+AQuery[j];
      end;

      Result:=Lowercase(Result);
    end;
    function isNumber(aWord : string) : boolean;
    begin
      case aWord of
        '0','1','2','3','4','5','6','7','8','9' : Result:=true;
        else Result:=false;
      end;
    end;
  begin
    Result:=false;
    if (AQuery[i]='''') then
    begin
      if not isQuotes then
      begin
        if (GetWords(-8)='values (') or (GetWords(-7)='values(') or (GetWords(-2)=''',')
        or (AQuery[i-1]=',') or (GetWords(-5)='like ') or (GetWords(-7)='infile ')
        or (AQuery[i-1]='=') then
        begin
          Result:=true;
          Exit;
        end;
      end else
      begin
        if (GetWords(+2)=',''') or (AQuery[i+1]=',') or (AQuery[i+1]=')') or (AQuery[i+1]=';')
        or (GetWords(+7)='  where') or (GetWords(+6)=' where') or (GetWords(+5)='where')
        or (GetWords(+8)='  having') or (GetWords(+7)=' having') or (GetWords(+6)='having')
        or (GetWords(+5)='  and') or (GetWords(+4)=' and') or (GetWords(+3)='and')
        or (GetWords(+4)='  or') or (GetWords(+3)=' or') or (GetWords(+2)='or')
        or (GetWords(+7)='  order') or (GetWords(+6)=' order') or (GetWords(+5)='order')
        or (GetWords(+7)='  limit') or (GetWords(+6)=' limit') or (GetWords(+5)='limit')
        or (GetWords(+7)='  group') or (GetWords(+6)=' group') or (GetWords(+5)='group')
        or (GetWords(+4)='  */') or (GetWords(+3)=' */') or (GetWords(+2)='*/')
        or (GetWords(+4)='  as') or (GetWords(+3)=' as') or (GetWords(+2)='as')
        or (GetWords(+6)='  from') or (GetWords(+5)=' from') or (GetWords(+4)='from')
        or (GetWords(+7)=' ignore')
        or (i=Length(AQuery)) then
        begin
          Result:=true;
          Exit;
        end;
      end;
    end;
  end;
begin
  AQuery:=TrimRight(AQuery);
  Result:='';isQuotes:=false;
  for i := 1 to Length(AQuery) do
  begin
    if not isQuotes then
    begin
      if not isQuotes then Result:=Result+LowerCase(AQuery[i]) else
      begin
        if (AQuery[i+1]='n') and (AQuery[i]='\') then Result:=Result+ReplaceStr(AQuery[i],'''','''''') else
        Result:=Result+ReplaceStr(ReplaceStr(AQuery[i],'\','\\'),'''','''''');
      end;
      if CekQuotes then isQuotes:=not isQuotes;
    end else
    begin
      if CekQuotes then isQuotes:=not isQuotes;
      if not isQuotes then Result:=Result+LowerCase(AQuery[i]) else
      begin
        if (AQuery[i+1]='n') and (AQuery[i]='\') then Result:=Result+ReplaceStr(AQuery[i],'''','''''') else
        Result:=Result+ReplaceStr(ReplaceStr(AQuery[i],'\','\\'),'''','''''');
      end;
    end;
  end;
end;

Function Open(AQuery : string;AZQuery : TZQuery;AReconnect : integer=0) : Boolean;
begin
  if AQuery='' then exit;
  if AZQuery.Connection.Tag=0 then
  begin
    try
      AZQuery.Connection.Connect;
      AZQuery.Connection.Tag:=1;
    except
      AZQuery.Connection.Tag:=0;
      Exit;
    end;
  end;

  AQuery:=FixQuery(AQuery);
  try
    Screen.Cursor:=crHourGlass;
    AZQuery.Close;AZQuery.SQL.Clear; AZQuery.SQL.AddText(AQuery);AZQuery.Open;
    if Not AZQuery.EOF then Result:=true else Result:=false;
    Screen.Cursor:=crDefault;
  except
    on E : Exception do
    begin
      Screen.Cursor:=crDefault;
      if Pos('SQL Error', E.Message)>0 then
      begin
        if (Pos('MySQL server has gone away', E.Message)>0) or (Pos('Lost connection to MySQL server', E.Message)>0)
        or (Pos('Can''t connect to MySQL server', E.Message)>0) or (Pos('Connection is not opened yet', E.Message)>0) then
        begin
          if AReconnect>0 then begin AZQuery.Connection.Reconnect; Result:=Open(AQuery,AZQuery,AReconnect-1); Exit; end;
          case QuestionDlg ('Peringatan',E.Message,
          mtWarning,[mrRetry,'Reconnect'],'') of
            mrRetry: begin AZQuery.Connection.Reconnect; Result:=Open(AQuery,AZQuery); end;
          end;
        end else
        case QuestionDlg ('Error',E.Message+#10#13+#10#13+'SQL Query : '+AQuery,
        mtError,[mrYes,'Copy Error'],'') of
          mrYes: Clipboard.AsText:='-- '+E.Message+#10#13+AQuery;
        end;
      end else
      begin
        ShowMessage(E.Message);
        Result:=false;
      end;
    end;
  end;
end;

Procedure Exec(AQuery : string;AZQuery : TZQuery;AReconnect : integer=0);
begin
  if AQuery='' then exit;
  if AZQuery.Connection.Tag=0 then
  begin
    try
      AZQuery.Connection.Connect;
      AZQuery.Connection.Tag:=1;
    except
      AZQuery.Connection.Tag:=0;
      Exit;
    end;
  end;

  AQuery:=FixQuery(AQuery);
  try
    Screen.Cursor:=crHourGlass;
    AZQuery.SQL.Clear;AZQuery.SQL.AddText(AQuery);AZQuery.ExecSQL;AZQuery.Close;
    Screen.Cursor:=crDefault;
  except
    on E : Exception do
    begin
      Screen.Cursor:=crDefault;
      if Pos('SQL Error', E.Message)>0 then
      begin
        if (Pos('MySQL server has gone away', E.Message)>0) or (Pos('Lost connection to MySQL server', E.Message)>0)
        or (Pos('Can''t connect to MySQL server', E.Message)>0) or (Pos('Connection is not opened yet', E.Message)>0) then
        begin
          if AReconnect>0 then begin AZQuery.Connection.Reconnect; Exec(AQuery,AZQuery,AReconnect-1); Exit; end;
          case QuestionDlg ('Peringatan',E.Message,
          mtWarning,[mrRetry,'Reconnect'],'') of
            mrRetry: begin AZQuery.Connection.Reconnect; Exec(AQuery,AZQuery); end;
          end;
        end else
        if (Pos('a foreign key constraint fails', E.Message)>0) then
        begin
          Exec('SET FOREIGN_KEY_CHECKS=0',AZQuery);Exec(AQuery,AZQuery);Exec('SET FOREIGN_KEY_CHECKS=1',AZQuery);
        end else
        if Pos('Duplicate entry', E.Message) > 0 then
        begin
          raise;
        end else
        case QuestionDlg ('Error',E.Message+#10#13+#10#13+'SQL Query : '+AQuery,
        mtError,[mrYes,'Copy Error'],'') of
          mrYes: Clipboard.AsText:='-- '+E.Message+#10#13+AQuery;
        end;
      end else
      ShowMessage(E.Message);
    end;
  end;
end;

function OpenConnection(aHost,aUser,aPass,aPort,aData : string) : TZConnection;
begin
  Screen.Cursor:=crHourGlass;
  Result:=TZConnection.Create(nil);
  try
    Result.Protocol:='mysql';
    Result.HostName:=aHost;
    Result.User:=aUser;
    Result.Password:=aPass;
    Result.Database:=aData;
    Result.Port:=strtointdef(aPort,3306);

    try
      Result.Connect;
      Result.Tag:=1;
    except
      Result.Tag:=0;
    end;
  finally
    Screen.Cursor:=crDefault;
  end;
end;

function LoadKoneksi(aIFile : TIniPropStorage) : TForm;
var
  Koneksi : TIniFile;
  aSection : string;
begin
  Result:=TfrmKoneksi.Create(Application);
  with TfrmKoneksi(Result) do
  begin
    Tag:=KoneksiList.Count;
    IFile:=aIFile;

    Koneksi:=TiniFile.Create(IFIle.ReadString('app.location','')+'\koneksi.ini');
    try
      aSection:=Koneksi.ReadString('Database','Aktif','Database');
      edHost.Text:=Koneksi.ReadString(aSection,'Hostname','');
      edUser.Text:=Koneksi.ReadString(aSection,'Username','');
      edPass.Text:=Koneksi.ReadString(aSection,'Password','');
      edPort.Text:=Koneksi.ReadString(aSection,'Port','');
      edData.Text:=Koneksi.ReadString(aSection,'Database','');

      DatabaseList.Add(OpenConnection(edHost.Text,edUser.Text,
      edPass.Text,edPort.Text,edData.Text));
    finally
      Koneksi.Free;
    end;
  end;
end;

function LoadMaintenance(aIFile : TIniPropStorage) : TForm;
begin
  Result:=TfrmMaintenance.Create(Application);
  with TfrmMaintenance(Result) do
  begin
    Tag:=MaintenanceList.Count;
    IFile:=aIFile;
  end;
end;

function LoadBackup(aIFile : TIniPropStorage) : TForm;
var
  aIniFile : TIniFile;
  aSection : string;
begin
  Result:=TfrmBackup.Create(Application);
  with TfrmBackup(Result) do
  begin
    Tag:=BackupList.Count;
    IFile:=aIFile;
    chBackup.Checked:=IFile.ReadBoolean('autobackup.aktif', True);
    chKonfirmasi.Checked:=IFile.ReadBoolean('autobackup.konfirmasi',false);
    edDir.Text:=IFile.ReadString('autobackup.dir','D:\BACKUP DATABASE\');
    chPeriode.Checked:=IFile.ReadBoolean('autobackup.periode',false);
    cbPeriode.Text:=IFile.ReadString('autobackup.jperiode','Setiap 3 Jam');
    chJam1.Checked:=IFile.ReadBoolean('autobackup.jam1',false);
    teJam1.Text:=IFile.ReadString('autobackup.jjam1','0:00');
    chJam2.Checked:=IFile.ReadBoolean('autobackup.jam2',false);
    teJam2.Text:=IFile.ReadString('autobackup.jjam2','0:00');
    chJam3.Checked:=IFile.ReadBoolean('autobackup.jam3',false);
    teJam3.Text:=IFile.ReadString('autobackup.jjam3','0:00');
    chTutup.Checked:=IFile.ReadBoolean('autobackup.tutup',true);
    chGDrive.Checked:=IFile.ReadBoolean('autobackup.gdrive',false);

    aIniFile:=TiniFile.Create(IFIle.ReadString('app.location','')+'\koneksi.ini');
    try
      aSection:=aIniFile.ReadString('Database','Aktif','Database');
      Hostname:=aIniFile.ReadString(aSection,'Hostname','');
      Username:=aIniFile.ReadString(aSection,'Username','');
      Password:=aIniFile.ReadString(aSection,'Password','');
      Port:=aIniFile.ReadString(aSection,'Port','');
      Database:=aIniFile.ReadString(aSection,'Database','');
    finally
      aIniFile.Free;
    end;

    chBackupChange(nil);
  end;
end;

function LoadRestore(aIFile : TIniPropStorage) : TForm;
var
  aIniFile : TIniFile;
  aSection : string;
begin
  Result:=TfrmRestore.Create(Application);
  with TfrmRestore(Result) do
  begin
    Tag:=RestoreList.Count;
    IFile:=aIFile;

    aIniFile:=TiniFile.Create(IFIle.ReadString('app.location','')+'\koneksi.ini');
    try
      aSection:=aIniFile.ReadString('Database','Aktif','Database');
      Hostname:=aIniFile.ReadString(aSection,'Hostname','');
      Username:=aIniFile.ReadString(aSection,'Username','');
      Password:=aIniFile.ReadString(aSection,'Password','');
      Port:=aIniFile.ReadString(aSection,'Port','');
      Database:=aIniFile.ReadString(aSection,'Database','');
    finally
      aIniFile.Free;
    end;
  end;
end;

function LoadHapus(aIFile : TIniPropStorage) : TForm;
begin
  Result:=TfrmHapus.Create(Application);
  with TfrmHapus(Result) do
  begin
    Tag:=HapusList.Count;
    IFile:=aIFile;
  end;
end;

end.

