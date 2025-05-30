unit umf;

{$mode objfpc}{$H+}

interface

uses
  Windows, Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Menus,
  udm, ufn, LMessages, ComCtrls, StdCtrls, BCButton;

const
  LM_MY_MESSAGE = LM_USER + 1;

type

  { TMF }

  TMF = class(TForm)
    PageControl1: TPageControl;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    procedure MessageHandler(var Message: TLMessage); message LM_MY_MESSAGE;
    procedure AppExceptionHandler(Sender: TObject; E: Exception);
  public

  end;

var
  MF: TMF;

implementation

{$R *.lfm}

{ TMF }

procedure TMF.MessageHandler(var Message: TLMessage);
begin
  case Message.wParam of
    1: Show;
  end;
end;

procedure TMF.AppExceptionHandler(Sender: TObject; E: Exception);
var
  LogFile: TextFile;
begin
  AssignFile(LogFile, 'applog.txt');
  if FileExists('applog.txt') then
    Append(LogFile)
  else
    Rewrite(LogFile);

  WriteLn(LogFile, FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' - ERROR: ' + E.Message);
  CloseFile(LogFile);
end;

procedure TMF.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  Hide;CanClose:=false;
end;

procedure TMF.FormCreate(Sender: TObject);
var
  i : integer;
begin
  DM.ti.Visible:=true;
  DM.ti.Hint:='RZF TOOLS';
  DM.ti.Icon:=Application.Icon;
  Application.OnException:=@AppExceptionHandler;

  for i := 0 to FApps.Entries.Count - 1 do
  begin
    with FApps.Entries.Items[i] do
    begin
      if (ParentKeyName='') and (DisplayName<>'') then
      begin
        if (Pos(Uppercase('RZF'),Uppercase(Publisher))>0)then
        begin
          DM.AddAppToMenu(DisplayName,'RZF',DM.Separator2,i);
        end;
      end;
    end;
  end;

  HapusSeparatorBerurutan(DM.pm);
end;

end.

