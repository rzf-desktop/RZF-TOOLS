unit applist;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Registry, LazUTF8, FGL;

type

  { TAppEntry }

  TAppEntry = class(TObject)
  private
    FDisplayIcon: string;
    // FNoModify: Integer;
    // FNoRepair: Integer;
    // ShellProducts: string;
    FAuthorizedCDFPrefix: string;
    FComments: string;
    FContact: string;
    FDisplayName: string;
    FDisplayVersion: string;
    FEstimatedSize: integer;
    FGUID: string;
    FHelpLink: string;
    FHelpTelephone: string;
    FInstallDate: string;
    FInstallLocation: string;
    FInstallSource: string;
    FLanguage: integer;
    FModifyPath: string;
    FParentKeyName: string;
    FPublisher: string;
    FReadme: string;
    FReleaseType: string;
    FSettingIdentifier: string;
    FSize: string;
    FSystemComponent: integer;
    FUninstallString: string;
    FURLInfoAbout: string;
    FURLUpdateInfo: string;
    FVersion: integer;
    FVersionMajor: integer;
    FVersionMinor: integer;
    FWindowsInstaller: integer;
    procedure SetFAuthorizedCDFPrefix(AValue: string);
    procedure SetFComments(AValue: string);
    procedure SetFContact(AValue: string);
    procedure SetFDisplayIcon(AValue: string);
    procedure SetFDisplayName(AValue: string);
    procedure SetFDisplayVersion(AValue: string);
    procedure SetFEstimatedSize(AValue: integer);
    procedure SetFGUID(AValue: string);
    procedure SetFHelpLink(AValue: string);
    procedure SetFHelpTelephone(AValue: string);
    procedure SetFInstallDate(AValue: string);
    procedure SetFInstallLocation(AValue: string);
    procedure SetFInstallSource(AValue: string);
    procedure SetFLanguage(AValue: integer);
    procedure SetFModifyPath(AValue: string);
    procedure SetFParentKeyName(AValue: string);
    procedure SetFPublisher(AValue: string);
    procedure SetFReadme(AValue: string);
    procedure SetFReleaseType(AValue: string);
    procedure SetFSettingIdentifier(AValue: string);
    procedure SetFSize(AValue: string);
    procedure SetFSystemComponent(AValue: integer);
    procedure SetFUninstallString(AValue: string);
    procedure SetFURLInfoAbout(AValue: string);
    procedure SetFURLUpdateInfo(AValue: string);
    procedure SetFVersion(AValue: integer);
    procedure SetFVersionMajor(AValue: integer);
    procedure SetFVersionMinor(AValue: integer);
    procedure SetFWindowsInstaller(AValue: integer);
  published
    property AuthorizedCDFPrefix: string read FAuthorizedCDFPrefix
      write SetFAuthorizedCDFPrefix;
    property Comments: string read FComments write SetFComments;
    property Contact: string read FContact write SetFContact;
    property DisplayIcon: string read FDisplayIcon write SetFDisplayIcon;
    property DisplayName: string read FDisplayName write SetFDisplayName;
    property DisplayVersion: string read FDisplayVersion write SetFDisplayVersion;
    property EstimatedSize: integer read FEstimatedSize write SetFEstimatedSize;
    property HelpLink: string read FHelpLink write SetFHelpLink;
    property HelpTelephone: string read FHelpTelephone write SetFHelpTelephone;
    property InstallDate: string read FInstallDate write SetFInstallDate;
    property InstallLocation: string read FInstallLocation write SetFInstallLocation;
    property InstallSource: string read FInstallSource write SetFInstallSource;
    property Language: integer read FLanguage write SetFLanguage;
    property ModifyPath: string read FModifyPath write SetFModifyPath;
    property Publisher: string read FPublisher write SetFPublisher;
    property Readme: string read FReadme write SetFReadme;
    property SettingIdentifier: string read FSettingIdentifier
      write SetFSettingIdentifier;
    property Size: string read FSize write SetFSize;
    property UninstallString: string read FUninstallString write SetFUninstallString;
    property URLInfoAbout: string read FURLInfoAbout write SetFURLInfoAbout;
    property URLUpdateInfo: string read FURLUpdateInfo write SetFURLUpdateInfo;
    property Version: integer read FVersion write SetFVersion;
    property VersionMajor: integer read FVersionMajor write SetFVersionMajor;
    property VersionMinor: integer read FVersionMinor write SetFVersionMinor;
    property WindowsInstaller: integer read FWindowsInstaller write SetFWindowsInstaller;
  published
    property GUID: string read FGUID write SetFGUID;
    property ParentKeyName: string read FParentKeyName write SetFParentKeyName;
    property ReleaseType: string read FReleaseType write SetFReleaseType;
    property SystemComponent: integer read FSystemComponent write SetFSystemComponent;
  end;

  TAppEntries = specialize TFPGObjectList<TAppEntry>;

  { TAppList }

  TAppList = class(TComponent)
  private
    FEntries: TAppEntries;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    function ReadString(const reg: TRegistry; const aName: string): string;
    function ReadInteger(const reg: TRegistry; const aName: string): integer;
    procedure LoadEntries(const Access: longword; const Root: HKEY);
  public
    procedure LoadData();
    property Entries: TAppEntries read FEntries;
  end;

const
  UNINSTALL_KEY = '\Software\Microsoft\Windows\CurrentVersion\Uninstall\';


implementation

uses ufn;

function IsWindows64: boolean;
{
Detect if we are running on 64 bit Windows or 32 bit Windows,
independently of bitness of this program.
Original source:
http://www.delphipraxis.net/118485-ermitteln-ob-32-bit-oder-64-bit-betriebssystem.html
modified for FreePascal in German Lazarus forum:
http://www.lazarusforum.de/viewtopic.php?f=55&t=5287
}
{$ifdef WIN32} //Modified KpjComp for 64bit compile mode
type
  TIsWow64Process = function( // Type of IsWow64Process API fn
      Handle: Windows.THandle; var Res: Windows.BOOL): Windows.BOOL; stdcall;
var
  IsWow64Result: Windows.BOOL; // Result from IsWow64Process
  IsWow64Process: TIsWow64Process; // IsWow64Process fn reference
begin
  // Try to load required function from kernel32
  IsWow64Process := TIsWow64Process(Windows.GetProcAddress(
    Windows.GetModuleHandle('kernel32'), 'IsWow64Process'));
  if Assigned(IsWow64Process) then
  begin
    // Function is implemented: call it
    if not IsWow64Process(Windows.GetCurrentProcess, IsWow64Result) then
      raise SysUtils.Exception.Create('IsWindows64: bad process handle');
    // Return result of function
    Result := IsWow64Result;
  end
  else
    // Function not implemented: can't be running on Wow64
    Result := False;
{$else} //if were running 64bit code, OS must be 64bit :)
begin
 Result := True;
{$endif}
end;

{ TAppEntry }

procedure TAppEntry.SetFAuthorizedCDFPrefix(AValue: string);
begin
  if FAuthorizedCDFPrefix = AValue then
    Exit;
  FAuthorizedCDFPrefix := AValue;
end;

procedure TAppEntry.SetFComments(AValue: string);
begin
  if FComments = AValue then
    Exit;
  FComments := AValue;
end;

procedure TAppEntry.SetFContact(AValue: string);
begin
  if FContact = AValue then
    Exit;
  FContact := AValue;
end;

procedure TAppEntry.SetFDisplayIcon(AValue: string);
begin
  if FDisplayIcon = AValue then
    Exit;
  FDisplayIcon := AValue;
end;

procedure TAppEntry.SetFDisplayName(AValue: string);
begin
  if FDisplayName = AValue then
    Exit;
  FDisplayName := AValue;
end;

procedure TAppEntry.SetFDisplayVersion(AValue: string);
begin
  if FDisplayVersion = AValue then
    Exit;
  FDisplayVersion := AValue;
end;

procedure TAppEntry.SetFEstimatedSize(AValue: integer);
begin
  if FEstimatedSize = AValue then
    Exit;
  FEstimatedSize := AValue;
end;

procedure TAppEntry.SetFGUID(AValue: string);
begin
  if FGUID = AValue then
    Exit;
  FGUID := AValue;
end;

procedure TAppEntry.SetFHelpLink(AValue: string);
begin
  if FHelpLink = AValue then
    Exit;
  FHelpLink := AValue;
end;

procedure TAppEntry.SetFHelpTelephone(AValue: string);
begin
  if FHelpTelephone = AValue then
    Exit;
  FHelpTelephone := AValue;
end;

procedure TAppEntry.SetFInstallDate(AValue: string);
begin
  if FInstallDate = AValue then
    Exit;
  FInstallDate := AValue;
end;

procedure TAppEntry.SetFInstallLocation(AValue: string);
begin
  if FInstallLocation = AValue then
    Exit;
  FInstallLocation := AValue;
end;

procedure TAppEntry.SetFInstallSource(AValue: string);
begin
  if FInstallSource = AValue then
    Exit;
  FInstallSource := AValue;
end;

procedure TAppEntry.SetFLanguage(AValue: integer);
begin
  if FLanguage = AValue then
    Exit;
  FLanguage := AValue;
end;

procedure TAppEntry.SetFModifyPath(AValue: string);
begin
  if FModifyPath = AValue then
    Exit;
  FModifyPath := AValue;
end;

procedure TAppEntry.SetFParentKeyName(AValue: string);
begin
  if FParentKeyName = AValue then
    Exit;
  FParentKeyName := AValue;
end;

procedure TAppEntry.SetFPublisher(AValue: string);
begin
  if FPublisher = AValue then
    Exit;
  FPublisher := AValue;
end;

procedure TAppEntry.SetFReadme(AValue: string);
begin
  if FReadme = AValue then
    Exit;
  FReadme := AValue;
end;

procedure TAppEntry.SetFReleaseType(AValue: string);
begin
  if FReleaseType = AValue then
    Exit;
  FReleaseType := AValue;
end;

procedure TAppEntry.SetFSettingIdentifier(AValue: string);
begin
  if FSettingIdentifier = AValue then
    Exit;
  FSettingIdentifier := AValue;
end;

procedure TAppEntry.SetFSize(AValue: string);
begin
  if FSize = AValue then
    Exit;
  FSize := AValue;
end;

procedure TAppEntry.SetFSystemComponent(AValue: integer);
begin
  if FSystemComponent = AValue then
    Exit;
  FSystemComponent := AValue;
end;

procedure TAppEntry.SetFUninstallString(AValue: string);
begin
  if FUninstallString = AValue then
    Exit;
  FUninstallString := AValue;
end;

procedure TAppEntry.SetFURLInfoAbout(AValue: string);
begin
  if FURLInfoAbout = AValue then
    Exit;
  FURLInfoAbout := AValue;
end;

procedure TAppEntry.SetFURLUpdateInfo(AValue: string);
begin
  if FURLUpdateInfo = AValue then
    Exit;
  FURLUpdateInfo := AValue;
end;

procedure TAppEntry.SetFVersion(AValue: integer);
begin
  if FVersion = AValue then
    Exit;
  FVersion := AValue;
end;

procedure TAppEntry.SetFVersionMajor(AValue: integer);
begin
  if FVersionMajor = AValue then
    Exit;
  FVersionMajor := AValue;
end;

procedure TAppEntry.SetFVersionMinor(AValue: integer);
begin
  if FVersionMinor = AValue then
    Exit;
  FVersionMinor := AValue;
end;

procedure TAppEntry.SetFWindowsInstaller(AValue: integer);
begin
  if FWindowsInstaller = AValue then
    Exit;
  FWindowsInstaller := AValue;
end;

{ TAppList }

function CompareEntriesByName(const Item1, Item2: TAppEntry): integer;
begin
  Result := UTF8CompareStr(Item1.DisplayName, Item2.DisplayName);
end;

constructor TAppList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TAppEntries.Create();
end;

destructor TAppList.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

function TAppList.ReadString(const reg: TRegistry; const aName: string): string;
begin
  Result := '';
  try
    if reg.ValueExists(aName) then
      case reg.GetDataType(aName) of
        rdString: Result := reg.ReadString(aName);
        rdInteger: Result := IntToStr(reg.ReadInteger(aName));
      end;
  except
  end;
end;

function TAppList.ReadInteger(const reg: TRegistry; const aName: string): integer;
begin
  Result := -1;
  try
    case reg.GetDataType(aName) of
      rdString: Result := StrToIntDef(reg.ReadString(aName), -1);
      rdInteger: Result := reg.ReadInteger(aName);
    end;
  except
  end;
end;

procedure TAppList.LoadEntries(const Access: longword; const Root: HKEY);
var
  i, j: integer;
  key_names: TStringList;
  reg: TRegistry;
begin
  key_names := nil;
  reg := TRegistry.Create(Access);
  reg.RootKey := Root;

  if reg.OpenKeyReadOnly(UNINSTALL_KEY) then
  begin
    key_names := TStringList.Create;
    reg.GetKeyNames(key_names);
  end;

  if Assigned(key_names) then
  begin
    for i := 0 to {%H-}key_names.Count - 1 do
    begin
      if reg.OpenKeyReadOnly(UNINSTALL_KEY + key_names[i]) then
      begin
        j := Entries.Add(TAppEntry.Create());
        with TAppEntry(Entries.Items[j]) do
        begin
          GUID := key_names[i];
          ParentKeyName := ReadString(reg, 'ParentKeyName');
          ReleaseType := ReadString(reg, 'ReleaseType');
          SystemComponent := ReadInteger(reg, 'SystemComponent');
          AuthorizedCDFPrefix := ReadString(reg, 'AuthorizedCDFPrefix');
          Comments := ReadString(reg, 'Comments');
          Contact := ReadString(reg, 'Contact');
          DisplayIcon := ReadString(reg, 'DisplayIcon');
          DisplayName := ReadString(reg, 'DisplayName');
          DisplayVersion := ReadString(reg, 'DisplayVersion');
          EstimatedSize := ReadInteger(reg, 'EstimatedSize');
          HelpLink := ReadString(reg, 'HelpLink');
          HelpTelephone := ReadString(reg, 'HelpTelephone');
          InstallDate := ReadString(reg, 'InstallDate');
          InstallLocation := ReadString(reg, 'InstallLocation');
          InstallSource := ReadString(reg, 'InstallSource');
          Language := ReadInteger(reg, 'Language');
          ModifyPath := ReadString(reg, 'ModifyPath');
          Publisher := ReadString(reg, 'Publisher');
          Readme := ReadString(reg, 'Readme');
          SettingIdentifier := ReadString(reg, 'SettingIdentifier');
          Size := ReadString(reg, 'Size');
          UninstallString := ReadString(reg, 'UninstallString');
          URLInfoAbout := ReadString(reg, 'URLInfoAbout');
          URLUpdateInfo := ReadString(reg, 'URLUpdateInfo');
          Version := ReadInteger(reg, 'Version');
          VersionMajor := ReadInteger(reg, 'VersionMajor');
          VersionMinor := ReadInteger(reg, 'VersionMinor');
          WindowsInstaller := ReadInteger(reg, 'WindowsInstaller');
        end;
      end;
    end;

    key_names.Free;
  end;
  reg.Free;
end;

procedure TAppList.LoadData;
begin
  Entries.Clear;
  // This is tested only under 64 bit OS
  if IsWindows64 then
  begin
    LoadEntries(KEY_WOW64_32KEY, HKEY_LOCAL_MACHINE);
    LoadEntries(KEY_WOW64_64KEY, HKEY_LOCAL_MACHINE);
    LoadEntries(KEY_WRITE, HKEY_CURRENT_USER);
  end
  else
  begin
    LoadEntries(KEY_WRITE, HKEY_LOCAL_MACHINE);
    LoadEntries(KEY_WRITE, HKEY_CURRENT_USER);
  end;
  Entries.Sort(@CompareEntriesByName);
end;

end.



