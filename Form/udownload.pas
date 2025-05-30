unit udownload;

{$mode ObjFPC}{$H+}

interface

uses
  Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls, ShellAPI, Windows,
  ExtCtrls, Classes, SysUtils, FileUtil, fphttpclient, opensslsockets;

type

  { TDownloadStream }

  TOnWriteStream = procedure(Sender: TObject; APos: Int64) of object;
  TDownloadStream = class(TStream)
  private
    FOnWriteStream: TOnWriteStream;
    FStream: TStream;
  public
    constructor Create(AStream: TStream);
    destructor Destroy; override;
    function Read(var Buffer; Count: LongInt): LongInt; override;
    function Write(const Buffer; Count: LongInt): LongInt; override;
    function Seek(Offset: LongInt; Origin: Word): LongInt; override;
    procedure DoProgress;
  published
    property OnWriteStream: TOnWriteStream read FOnWriteStream write FOnWriteStream;
  end;

  {TDownload}

  TOnDownloadProgress = procedure(Sender: TObject; AFrom, ATo: String; APos, ASize, AElapsed, ARemaining, ASpeed: LongInt) of object;
  TOnDownloadError = procedure(Sender: TObject; const AErrMsg: String = '') of object;
  TOnDownloadCompleted = TNotifyEvent;
  TDownload = class(TThread)
  private
    FMS: TMemoryStream;
    FFPHTTPClient: TFPHTTPClient;
    FURL: String;
    FLocalFile: String;
    FRemaining: Integer;
    FSpeed: Integer;
    FStartTime: QWord;
    FElapsed: QWord;
    FTick: Qword;
    FPos: Int64;
    FSize: Int64;
    FErrMsg: String;
    FOnDownloadProgress: TOnDownloadProgress;
    FOnDownloadError: TOnDownloadError;
    FOnDownloadCompleted: TOnDownloadCompleted;
    procedure GetContentLength;
    function FixProtocol(const AURL: String): String;
    procedure DoOnDataReceived(Sender: TObject; const ContentLength, {%H-}CurrentPos: int64);
    procedure DoOnWriteStream(Sender: TObject; APos: Int64);
    procedure DoOnDownloadProgress;
    procedure DoOnDownloadError;
    procedure DoOnDownloadCompleted;
  protected
    procedure Execute; override;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DownloadFile(const AURL, ALocalFile: String);
    procedure CancelDownoad;
  public
    property OnDownloadProgress: TOnDownloadProgress read FOnDownloadProgress write FOnDownloadProgress;
    property OnDownloadError: TOnDownloadError read FOnDownloadError write FOnDownloadError;
    property OnDownloadCompleted: TOnDownloadCompleted read FOnDownloadCompleted write FOnDownloadCompleted;
  end;

  { TfrmDownload }

  TfrmDownload = class(TForm)
    lbElapsed: TLabel;
    lbElapsedData: TLabel;
    lbFile: TLabel;
    lbFileData: TLabel;
    lbReceived: TLabel;
    lbReceived1: TLabel;
    lbRemaining: TLabel;
    lbRemainingData: TLabel;
    lbSpeed: TLabel;
    lbSpeedData: TLabel;
    Panel1: TPanel;
    pb: TProgressBar;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    FDownload: TDownload;
    FilePath: string;
    procedure DoOnDownloadProgress(Sender: TObject; {%H-}AFrom, ATo: String; APos, ASize, AElapsed, ARemaining, ASpeed: LongInt);
    procedure DoOnDownloadCompleted(Sender: TObject);
  public
    Downloaded: boolean;
    procedure StartDownload(const URL, FileName: string);
  end;

var
  frmDownload: TfrmDownload;

implementation

uses
  ufn;

{$R *.lfm}

{ TDownloadStream }

constructor TDownloadStream.Create(AStream: TStream);
begin
  inherited Create;
  FStream := AStream;
  FStream.Position := 0;
end;

destructor TDownloadStream.Destroy;
begin
  FStream.Free;
  inherited Destroy;
end;

function TDownloadStream.Read(var Buffer; Count: LongInt): LongInt;
begin
  Result := FStream.Read(Buffer, Count);
end;

function TDownloadStream.Write(const Buffer; Count: LongInt): LongInt;
begin
  Result := FStream.Write(Buffer, Count);
  DoProgress;
end;

function TDownloadStream.Seek(Offset: LongInt; Origin: Word): LongInt;
begin
  Result := FStream.Seek(Offset, Origin);
end;

procedure TDownloadStream.DoProgress;
begin
  if Assigned(FOnWriteStream) then
    FOnWriteStream(Self, Self.Position);
end;

{TDownload}

constructor TDownload.Create;
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FMS := TMemoryStream.Create;
  FFPHTTPClient := TFPHTTPClient.Create(nil);
end;

destructor TDownload.Destroy;
begin
  FFPHTTPClient.Free;
  FMS.Free;
  inherited Destroy;
end;

procedure TDownload.DownloadFile(const AURL, ALocalFile: String);
begin
  FURL := FixProtocol(AURL);
  FLocalFile := ALocalFile;
  Self.Start;
end;

procedure TDownload.CancelDownoad;
begin
  if Assigned(FFPHTTPClient) then
    FFPHTTPClient.Terminate;
end;

procedure TDownload.DoOnDataReceived(Sender: TObject; const ContentLength,
  CurrentPos: int64);
begin
  if ContentLength > 0 then
    Abort;
end;

procedure TDownload.DoOnWriteStream(Sender: TObject; APos: Int64);
begin
  FElapsed := GetTickCount64 - FStartTime;
  if FElapsed < 1000 then
    Exit;
  FElapsed := FElapsed div 1000;
  FPos := APos;
  FSpeed := Round(FPos/FElapsed);
  if FSpeed > 0 then
    FRemaining := Round((FSize - FPos)/FSpeed);
  if FElapsed >= FTick + 1 then
  begin
    FTick := FElapsed;
    Synchronize(@DoOnDownloadProgress);
  end;
end;

procedure TDownload.DoOnDownloadProgress;
begin
  if Assigned(FOnDownloadProgress) then
    FOnDownloadProgress(Self, FURL, FLocalFile, FPos, FSize, FElapsed, FRemaining, FSpeed);
end;

procedure TDownload.DoOnDownloadError;
begin
  if Assigned(FOnDownloadError) then
    FOnDownloadError(Self, FErrMsg);
end;

procedure TDownload.DoOnDownloadCompleted;
begin
  if Assigned(FOnDownloadCompleted) then
    FOnDownloadCompleted(Self);
end;

procedure TDownload.GetContentLength;
var
  SS: TStringStream;
  HttpClient: TFPHTTPClient;
  URL: String;
begin
  FSize := 0;
  SS := TStringStream.Create('');
  try
    URL := FixProtocol(FURL);
    HttpClient := TFPHTTPClient.Create(nil);
    try
      HttpClient.OnDataReceived := @DoOnDataReceived;
      HttpClient.AllowRedirect := True;
      HttpClient.ResponseHeaders.NameValueSeparator := ':';
      try
        HttpClient.HTTPMethod('GET', URL, SS, []);
      except
      end;
      if HttpClient.ResponseStatusCode = 200 then
        FSize := StrToIntDef(HttpClient.ResponseHeaders.Values['CONTENT-LENGTH'], 0)
    finally
      HttpClient.Free;
    end;
  finally
    SS.Free
  end;
end;

function TDownload.FixProtocol(const AURL: String): String;
begin
  Result := AURL;
  if (Pos('http://', Result) = 0) and (Pos('https://', Result) = 0) then
    Result := 'https://' + Result;
end;

procedure TDownload.Execute;
var
  DS: TDownloadStream;
  Flags: Word;
begin
  FStartTime := GetTickCount64;
  GetContentLength;
  Flags := fmOpenWrite;
  if not FileExists(FLocalFile) then
  begin
    FPos := 0;
    Flags := Flags or fmCreate;
  end
  else
    FPos := FileUtil.FileSize(FLocalFile);

  DS := TDownloadStream.Create(TFileStream.Create(FLocalFile, Flags));
  try
    DS.FOnWriteStream := @DoOnWriteStream;
    try
      if (FPos > 0) and (FPos < FSize) then
      begin
        DS.Position := FPos;
        FFPHTTPClient.AddHeader('Range', 'bytes=' + IntToStr(FPos) + '-'  + IntToStr(FSize));
      end;
      FFPHTTPClient.AddHeader('User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
        '(KHTML, like Gecko) Chrome/123.0.6312.105 Safari/537.36');
      FFPHTTPClient.AllowRedirect := True;
      FFPHTTPClient.HTTPMethod('GET', FURL, DS, [200, 206]);
      if not FFPHTTPClient.Terminated then
      begin
        Synchronize(@DoOnDownloadProgress);
        Synchronize(@DoOnDownloadCompleted);
      end;
    except
      on E: Exception do
      begin
        FErrMsg := E.Message;
        Synchronize(@DoOnDownloadError);
      end;
    end;
  finally
    DS.Free
  end;
end;

{ TfrmDownload }

procedure TfrmDownload.FormCreate(Sender: TObject);
begin
  FDownload := nil;
end;

procedure TfrmDownload.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if (Assigned(FDownload)) and (Downloaded=false) then
  begin
    CanClose:=false;
    if MessageDlg('Konfirmasi', 'Apakah Anda yakin ingin membatalkan proses download ?',
                  mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      FDownload.CancelDownoad;
      CanClose:=true;
    end;
  end;
end;

procedure TfrmDownload.DoOnDownloadProgress(Sender: TObject; AFrom, ATo: String; APos,
  ASize, AElapsed, ARemaining, ASpeed: LongInt);
begin
  lbFileData.Caption := ': ' + ExtractFileName(ATo);
  lbSpeedData.Caption := ': ' + FormatSpeed(ASpeed);
  lbSpeedData.Update;
  lbElapsedData.Caption := ': ' + SecToHourAndMin(AElapsed);
  lbElapsedData.Update;
  if ASize > 0 then
    lbRemainingData.Caption := ': ' +SecToHourAndMin(ARemaining)
  else
    lbRemainingData.Caption := ': Unknown';
  lbRemainingData.Update;
  if ASize > 0 then
    lbReceived.Caption := ': ' + FormatSize(APos) + ' / ' + FormatSize(ASize)
  else
    lbReceived.Caption := ': ' + FormatSize(APos) + ' / ' + 'Unknown';
  lbReceived.Update;
  if ASize > 0 then
    pb.Position := Round((APos/ASize) * 100);
  pb.Update;
  Application.ProcessMessages;
end;

procedure TfrmDownload.DoOnDownloadCompleted(Sender: TObject);
begin
  //bDownload.Tag := 0;
  //bDownload.Caption := 'Download';
  //showmessage('Download completed'+#10#13+PChar(FilePath));
  Downloaded:=true;
  Close;
end;

procedure TfrmDownload.StartDownload(const URL, FileName: string);
begin
  FilePath:=FileName;
  Downloaded:=false;
  //if TButton(Sender).Tag = 0 then
  //begin
  //  pnDownload.Visible := True;
  //  TButton(Sender).Tag := 1;
  //  TButton(Sender).Caption := 'Cancel';
    FDownload := TDownload.Create;
    FDownload.OnDownloadProgress := @DoOnDownloadProgress;
    FDownload.OnDownloadCompleted := @DoOnDownloadCompleted;
    FDownload.DownloadFile(URL, FilePath);
  //end else
  //if TButton(Sender).Tag = 1 then
  //begin
  //  TButton(Sender).Tag := 0;
  //  TButton(Sender).Caption := 'Download';
  //  FDownload.CancelDownoad;
  //end;
end;

end.

