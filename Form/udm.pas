unit udm;

{$mode ObjFPC}{$H+}

interface

uses
  Windows, Classes, SysUtils, ExtCtrls, Menus, Controls, Forms, Dialogs,
  IniPropStorage, applist, RegExpr, ComCtrls, BCButton, Graphics;

type

  { TDM }

  TDM = class(TDataModule)
    IFile: TIniPropStorage;
    IList: TImageList;
    miGDrive: TMenuItem;
    miDownload: TMenuItem;
    miExit: TMenuItem;
    miShow: TMenuItem;
    pm: TPopupMenu;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    Separator3: TMenuItem;
    Separator4: TMenuItem;
    ti: TTrayIcon;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure miGDriveClick(Sender: TObject);
    procedure pmClick(Sender: TObject);
    procedure tiClick(Sender: TObject);
  private

  public
    procedure AddAppToMenu(const aName,aExe: string;aSeparator: TMenuItem; aIndex: integer);
    function LoadConfigs(App : TAppEntry) : integer;
    procedure LaunchAppClick(Sender : TObject);
  end;

var
  DM: TDM;
  FApps: TAppList;
  ConfigList,BackupList,KoneksiList,DatabaseList,MaintenanceList,RestoreList,HapusList: TList;

implementation

uses
  ufn, umf, uobj;

{$R *.lfm}

{ TDM }

procedure TDM.tiClick(Sender: TObject);
begin
  if MF.Showing then MF.Hide else MF.Show;
end;

procedure TDM.pmClick(Sender: TObject);
begin
  if Sender is TMenuItem then
  begin
    if TMenuItem(Sender).Parent=miDownload then
    begin
      StartDownload(DownloadList[TMenuItem(Sender).Tag].Link,
      DownloadList[TMenuItem(Sender).Tag].NamaFile);
      Exit;
    end;

    case TMenuItem(Sender).Caption of
      'Show/Hide' : if MF.Showing then MF.Hide else MF.Show;
      'Exit' : Application.Terminate;
      'Koneksi Database' : if not TForm(KoneksiList[TMenuItem(Sender).Tag]).Showing then
      TForm(KoneksiList[TMenuItem(Sender).Tag]).ShowModal;
      'Maintenance Database' : if not TForm(MaintenanceList[TMenuItem(Sender).Tag]).Showing then
      TForm(MaintenanceList[TMenuItem(Sender).Tag]).ShowModal;
      'Backup Database' : if not TForm(BackupList[TMenuItem(Sender).Tag]).Showing then
      TForm(BackupList[TMenuItem(Sender).Tag]).ShowModal;
      'Restore Database' : if not TForm(RestoreList[TMenuItem(Sender).Tag]).Showing then
      TForm(RestoreList[TMenuItem(Sender).Tag]).ShowModal;
      'Hapus Database' : if not TForm(HapusList[TMenuItem(Sender).Tag]).Showing then
      TForm(HapusList[TMenuItem(Sender).Tag]).ShowModal;
    end;
  end;

  if Sender is TBCButton then
  begin
    case TBCButton(Sender).Caption of
      'KONEKSI DATABASE' : if not TForm(KoneksiList[TBCButton(Sender).Tag]).Showing then
      TForm(KoneksiList[TBCButton(Sender).Tag]).ShowModal;
      'MAINTENANCE DATABASE' : if not TForm(MaintenanceList[TBCButton(Sender).Tag]).Showing then
      TForm(MaintenanceList[TBCButton(Sender).Tag]).ShowModal;
      'BACKUP DATABASE' : if not TForm(BackupList[TBCButton(Sender).Tag]).Showing then
      TForm(BackupList[TBCButton(Sender).Tag]).ShowModal;
      'RESTORE DATABASE' : if not TForm(RestoreList[TBCButton(Sender).Tag]).Showing then
      TForm(RestoreList[TBCButton(Sender).Tag]).ShowModal;
      'HAPUS DATABASE' : if not TForm(HapusList[TBCButton(Sender).Tag]).Showing then
      TForm(HapusList[TBCButton(Sender).Tag]).ShowModal;
    end;
  end;
end;

procedure TDM.DataModuleCreate(Sender: TObject);
var
  i : integer;
begin
  if not DirectoryExists(GetAppConfigDir(False)) then
  CreateDir(GetAppConfigDir(False));

  AddScheduledTask;
  AddAppToUninstall;
  ExtractAllResources;
  ConfigList:=TList.Create;BackupList:=TList.Create;KoneksiList:=TList.Create;
  RestoreList:=TList.Create;MaintenanceList:=TList.Create;HapusList:=TList.Create;
  DatabaseList:=TList.Create;
  IFile.IniFileName:=GetAppConfigDir(False)+'config.ini';
  FApps:=TAppList.Create(Self);
  FApps.LoadData();

  for i := 0 to FApps.Entries.Count - 1 do
  begin
    with FApps.Entries.Items[i] do
    begin
      if (ParentKeyName='') and (DisplayName<>'') then
      begin
        if (Pos(Uppercase('SQLYog'),Uppercase(DisplayName))>0)then
        begin
          AddAppToMenu(DisplayName,'',Separator1,i);
        end;
        if (Pos(Uppercase('Xampp'),Uppercase(DisplayName))>0)then
        begin
          AddAppToMenu(DisplayName,'',Separator1,i);
        end;
        if (Pos(Uppercase('Laragon'),Uppercase(DisplayName))>0)then
        begin
          AddAppToMenu(DisplayName,'',Separator1,i);
        end;
        if (Pos(Uppercase('UltraViewer'),Uppercase(DisplayName))>0)then
        begin
          AddAppToMenu(DisplayName,'UltraViewer_Desktop.exe',Separator1,i);
        end;
      end;
    end;
  end;
end;

procedure TDM.DataModuleDestroy(Sender: TObject);
begin
  RemoveAppFromUninstall;
end;

procedure TDM.miGDriveClick(Sender: TObject);
begin
  GCloneConfig;
end;

procedure TDM.AddAppToMenu(const aName,aExe: string;aSeparator: TMenuItem; aIndex: integer);
var
  TabSheet: TTabSheet;
  ScrollBox: TScrollBox;
  FlowPanel: TFlowPanel;
  NewItem,SubItem : TMenuItem;
begin
  NewItem:=TMenuItem.Create(pm);
  NewItem.Caption:=HapusVersi(aName);
  NewItem.Hint:=FApps.Entries.Items[aIndex].InstallLocation;
  NewItem.Tag:=aIndex;

  SubItem:=TMenuItem.Create(NewItem);
  SubItem.Caption:='Buka Aplikasi';
  SubItem.OnClick:=@LaunchAppClick;
  if FApps.Entries.Items[aIndex].DisplayIcon<>'' then
  SubItem.Hint:=FApps.Entries.Items[aIndex].DisplayIcon else
  if Pos('.exe',aExe)>0 then SubItem.Hint:=NewItem.Hint+'\'+aExe else
  SubItem.Hint:=FindExeFiles(NewItem.Hint,aExe);
  LoadIconToMenuItem(SubItem.Hint,NewItem);
  NewItem.Add(SubItem);

  if Pos('RZF',aExe)>0 then
  begin
    NewItem.Tag:=LoadConfigs(FApps.Entries.Items[aIndex]);
    KoneksiList.Add(LoadKoneksi(TIniPropStorage(ConfigList[NewItem.Tag])));
    MaintenanceList.Add(LoadMaintenance(TIniPropStorage(ConfigList[NewItem.Tag])));
    BackupList.Add(LoadBackup(TIniPropStorage(ConfigList[NewItem.Tag])));
    RestoreList.Add(LoadRestore(TIniPropStorage(ConfigList[NewItem.Tag])));
    HapusList.Add(LoadHapus(TIniPropStorage(ConfigList[NewItem.Tag])));

    TabSheet:=TTabSheet.Create(MF.PageControl1);
    TabSheet.PageControl:=MF.PageControl1;
    TabSheet.Caption:=HapusVersi(aName);

    ScrollBox:=TScrollBox.Create(TabSheet);
    ScrollBox.Parent:=TabSheet;
    ScrollBox.Align:=alClient;

    FlowPanel:=TFlowPanel.Create(ScrollBox);
    FlowPanel.Parent:=ScrollBox;
    FlowPanel.Align:=alClient;
    FlowPanel.BevelOuter:=bvNone;
    FlowPanel.FlowStyle:=fsLeftRightTopBottom;
    FlowPanel.FlowLayout:=tlTop;

    with CreateStyledBCButton(MF,FlowPanel,'BUKA APLIKASI') do
    begin
      OnClick:=@LaunchAppClick;
      Hint:=SubItem.Hint;
    end;

    SubItem:=TMenuItem.Create(NewItem);
    SubItem.Caption:='-';
    NewItem.Add(SubItem);

    SubItem:=TMenuItem.Create(NewItem);
    SubItem.Caption:='Koneksi Database';
    SubItem.Tag:=KoneksiList.Count-1;
    SubItem.OnClick:=@pmClick;
    NewItem.Add(SubItem);

    with CreateStyledBCButton(MF,FlowPanel,'KONEKSI DATABASE') do
    begin
      OnClick:=@pmClick;
      Tag:=KoneksiList.Count-1;
    end;

    SubItem:=TMenuItem.Create(NewItem);
    SubItem.Caption:='Maintenance Database';
    SubItem.OnClick:=@pmClick;
    SubItem.Tag:=MaintenanceList.Count-1;
    NewItem.Add(SubItem);

    with CreateStyledBCButton(MF,FlowPanel,'MAINTENANCE DATABASE') do
    begin
      OnClick:=@pmClick;
      Tag:=MaintenanceList.Count-1;
    end;

    SubItem:=TMenuItem.Create(NewItem);
    SubItem.Caption:='Backup Database';
    SubItem.Tag:=BackupList.Count-1;
    SubItem.OnClick:=@pmClick;
    NewItem.Add(SubItem);

    with CreateStyledBCButton(MF,FlowPanel,'BACKUP DATABASE') do
    begin
      OnClick:=@pmClick;
      Tag:=BackupList.Count-1;
    end;

    SubItem:=TMenuItem.Create(NewItem);
    SubItem.Caption:='Restore Database';
    SubItem.OnClick:=@pmClick;
    SubItem.Tag:=RestoreList.Count-1;
    NewItem.Add(SubItem);

    with CreateStyledBCButton(MF,FlowPanel,'RESTORE DATABASE') do
    begin
      OnClick:=@pmClick;
      Tag:=RestoreList.Count-1;
    end;

    SubItem:=TMenuItem.Create(NewItem);
    SubItem.Caption:='Hapus Database';
    SubItem.OnClick:=@pmClick;
    SubItem.Tag:=HapusList.Count-1;
    NewItem.Add(SubItem);

    with CreateStyledBCButton(MF,FlowPanel,'HAPUS DATABASE') do
    begin
      OnClick:=@pmClick;
      Tag:=HapusList.Count-1;
    end;
  end;

  pm.Items.Insert(pm.Items.IndexOf(aSeparator)+1,NewItem);
  CreateDownloadPopup(miDownload);
end;

function TDM.LoadConfigs(App : TAppEntry) : integer;
var
  Ini: TIniPropStorage;
begin
  Ini:=TIniPropStorage.Create(nil);
  Ini.IniFileName:=GetAppConfigDir(False)+'config.ini';
  Ini.IniSection:=App.DisplayName;
  Ini.WriteString('app.location',App.InstallLocation);
  Ini.WriteString('app.exename',FindExeFiles(App.InstallLocation,'RZF'));
  ConfigList.Add(Ini);
  Result:=ConfigList.Count-1;
end;

procedure TDM.LaunchAppClick(Sender: TObject);
begin
  if Sender is TMenuItem then ShellExecute(0, 'open', PChar(TMenuItem(Sender).Hint), nil, nil, SW_SHOWNORMAL);
  if Sender is TBCButton then ShellExecute(0, 'open', PChar(TBCButton(Sender).Hint), nil, nil, SW_SHOWNORMAL);
end;

end.

