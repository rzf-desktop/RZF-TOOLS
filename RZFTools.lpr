program RZFTools;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, SysUtils, Windows, Dialogs, // this includes the LCL widgetset
  Forms, zcomponent, ubackup, udownload, ukoneksi, urestore,
  umaintenance, uhapus, ufn, udm, umf, uobj;

const
  APP_MUTEX_NAME = 'Global\RZFTools.MTX';

var
  hMutex: THandle;
  alreadyRunning: Boolean;

{$R *.res}

begin
  hMutex := CreateMutex(nil, True, APP_MUTEX_NAME);
  alreadyRunning := (GetLastError = ERROR_ALREADY_EXISTS);

  if alreadyRunning then
  begin
    PostMessage(FindWindow(nil,'RZF TOOLS'), LM_MY_MESSAGE, 1, 0);
    ExitProcess(0);
  end;

  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  if FindCmdLineSwitch('tray', True) then
  Application.ShowMainForm:=false else
  Application.ShowMainForm:=true;
  Application.CreateForm(TDM, DM);
  Application.CreateForm(TMF, MF);
  Application.Run;

  if hMutex<>0 then CloseHandle(hMutex);
end.

