{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2025 Christoph Schneider                                 }
{  Schneider Infosystems AG, Switzerland                                       }
{  https://github.com/SchneiderInfosystems/FB4D                                }
{                                                                              }
{******************************************************************************}
{                                                                              }
{  Licensed under the Apache License, Version 2.0 (the "License");             }
{  you may not use this file except in compliance with the License.            }
{  You may obtain a copy of the License at                                     }
{                                                                              }
{      http://www.apache.org/licenses/LICENSE-2.0                              }
{                                                                              }
{  Unless required by applicable law or agreed to in writing, software         }
{  distributed under the License is distributed on an "AS IS" BASIS,           }
{  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.    }
{  See the License for the specific language governing permissions and         }
{  limitations under the License.                                              }
{                                                                              }
{******************************************************************************}

unit MainFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Edit, FMX.TabControl,
  FMX.MultiView, FMX.ScrollBox, FMX.Memo, FMX.Ani, FMX.Layouts,
  FB4D.Interfaces, FB4D.SelfRegistrationFra, FMX.Memo.Types;

type
  TfmxMain = class(TForm)
    TabControl: TTabControl;
    tabSignIn: TTabItem;
    tabClipboard: TTabItem;
    edtKey: TEdit;
    Text3: TText;
    edtProjectID: TEdit;
    Text4: TText;
    lblClipboardState: TLabel;
    btnSettings: TButton;
    tabProjectSettings: TTabItem;
    btnEnteredProjSettings: TButton;
    memClipboardText: TMemo;
    btnSendToCloud: TButton;
    lblStatusRTDB: TLabel;
    aniRTDB: TAniIndicator;
    btnFromClipBoard: TButton;
    btnToClipboard: TButton;
    btnReconnect: TButton;
    imgClipboardPict: TImage;
    TabControlClipboard: TTabControl;
    tabText: TTabItem;
    tabGraphic: TTabItem;
    tmrTesting: TTimer;
    chbTesting: TCheckBox;
    lblSendStatusRTDB: TLabel;
    FloatAnimationHideStatus: TFloatAnimation;
    lblVersionInfo: TLabel;
    FraSelfRegistration: TFraSelfRegistration;
    layToolbar: TLayout;
    layUserInfo: TLayout;
    btnSignOut: TButton;
    lblUserInfo: TLabel;
    btnClearSettings: TButton;
    imgCloudOff: TImage;
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnEnteredProjSettingsClick(Sender: TObject);
    procedure btnSendToCloudClick(Sender: TObject);
    procedure btnFromClipBoardClick(Sender: TObject);
    procedure btnToClipboardClick(Sender: TObject);
    procedure btnReconnectClick(Sender: TObject);
    procedure chbTestingChange(Sender: TObject);
    procedure tmrTestingTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSignOutClick(Sender: TObject);
    procedure btnClearSettingsClick(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    fUID: string;
    fFirebaseEvent: IFirebaseEvent;
    fReceivedUpdates, fErrorCount: Int64;
    fStressTestCounter: Int64;
    function OnGetAuth: IFirebaseAuthentication;
    procedure OnUserLogin(const Info: string; User: IFirebaseUser);
    procedure OnPutResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnPutError(const RequestID, ErrMsg: string);
    procedure WipeToTab(ActiveTab: TTabItem);
    procedure StartClipboard;
    procedure OnRecData(const Event: string; Params: TRequestResourceParam;
      JSONObj: TJSONObject);
    procedure OnRecDataError(const Info, ErrMsg: string);
    procedure OnRecDataStop(const RequestId: string);
    procedure OnConnectionStateChange(ListenerConnected: boolean);
    procedure StartListener;
    procedure StopListener;
    procedure SaveSettings;
    function GetSettingFilename: string;
    function GetClipboardPictAsBase64: string;
    procedure SetClipboardPictFromBase64(const Base64: string);
    procedure ExceptionHandler(Sender: TObject; E: Exception);
  end;

var
  fmxMain: TfmxMain;

implementation

uses
  System.IniFiles, System.IOUtils, System.StrUtils, System.Rtti,
  System.NetEncoding, System.Generics.Collections,
  FMX.Platform, FMX.Surfaces,
  FB4D.Configuration, FB4D.Authentication, FB4D.Helpers, FB4D.Response,
  FB4D.Request, FB4D.RealTimeDB;

resourcestring
  rsEnterEMail = 'Enter your email address for login';
  rsWait = 'Please wait for Firebase';
  rsEnterPassword = 'Enter your password for login';
  rsSetupPassword = 'Setup a new password for future logins';
  rsHintRTDBRules =
    'Hint to permission error:'#13#13 +
    'Before you can write into the real time database add the following'#13 +
    'text in the Firebase console as rule for the Realtime Database:'#13#13 +
    '{'#13 +
    ' "rules": {'#13 +
    '    "cb": {'#13 +
    '      "$uid": {'#13 +
    '		    ".read": "(auth != null) && (auth.uid == $uid)",'#13 +
    '    		".write": "(auth != null) && (auth.uid == $uid)" '#13 +
    '    	}'#13 +
    '    }'#13 +
    '  }'#13 +
    '}'#13;

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.iPhone55in.fmx IOS}
{$R *.Macintosh.fmx MACOS}

procedure TfmxMain.FormCreate(Sender: TObject);
begin
  Application.OnException := ExceptionHandler;
end;

procedure TfmxMain.ExceptionHandler(Sender: TObject; E: Exception);
begin
{$IFDEF DEBUG}
  tmrTesting.Enabled := false;
  chbTesting.IsChecked := false;
{$ENDIF}
  TabControlClipboard.ActiveTab := tabText;
  memClipboardText.Lines.Clear;
  memClipboardText.Lines.Add('Exception at: ' +
    FormatDateTime('dd/mm/yy hh:nn:ss:zzz', now));
  memClipboardText.Lines.Add(E.ClassName);
  memClipboardText.Lines.Add(E.Message);
  memClipboardText.Lines.Add(E.StackTrace);
end;

procedure TfmxMain.FormShow(Sender: TObject);
var
  IniFile: TIniFile;
  LastEMail: string;
  LastToken: string;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    LastEMail := IniFile.ReadString('Authentication', 'User', '');
    LastToken := IniFile.ReadString('Authentication', 'Token', '');
  finally
    IniFile.Free;
  end;
  if edtKey.Text.IsEmpty or edtProjectID.Text.IsEmpty then
    TabControl.ActiveTab := tabProjectSettings
  else
    TabControl.ActiveTab := tabSignIn;
  FraSelfRegistration.InitializeAuthOnDemand(OnGetAuth, OnUserLogin, LastToken,
    LastEMail);
  Caption := Caption + ' - ' + TFirebaseHelpers.GetConfigAndPlatform +
    ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
{$IFDEF DEBUG}
  chbTesting.Visible := true;
{$ELSE}
  chbTesting.Visible := false;
{$ENDIF}
end;

procedure TfmxMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopListener;
  SaveSettings;
end;

procedure TfmxMain.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('Authentication', 'User', FraSelfRegistration.GetEMail);
    if assigned(fConfig) and fConfig.Auth.Authenticated then
      IniFile.WriteString('Authentication', 'Token',
        fConfig.Auth.GetRefreshToken)
    else
      IniFile.DeleteKey('Authentication', 'Token');
  finally
    IniFile.Free;
  end;
end;

function TfmxMain.GetSettingFilename: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  result := IncludeTrailingPathDelimiter(
{$IFDEF IOS}
    TPath.GetDocumentsPath
{$ELSE}
    TPath.GetHomePath
{$ENDIF}
    ) + FileName + TFirebaseHelpers.GetPlatform + '.ini';
end;

procedure TfmxMain.btnClearSettingsClick(Sender: TObject);
begin
  edtKey.Text := '';
  edtProjectID.Text := '';
  fConfig.Auth.SignOut;
  SaveSettings;
end;

procedure TfmxMain.btnEnteredProjSettingsClick(Sender: TObject);
begin
  if edtKey.Text.IsEmpty then
    edtKey.SetFocus
  else if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else begin
    SaveSettings;
    WipeToTab(tabSignIn);
    FraSelfRegistration.StartEMailEntering;
  end;
end;

procedure TfmxMain.OnConnectionStateChange(ListenerConnected: boolean);
begin
  imgCloudOff.Visible := not ListenerConnected;
end;

function TfmxMain.OnGetAuth: IFirebaseAuthentication;
begin
  if not assigned(fConfig) then
  begin
    fConfig := TFirebaseConfiguration.Create(edtKey.Text, edtProjectID.Text);
    edtKey.ReadOnly := true;
    edtProjectID.ReadOnly := true;
    fFirebaseEvent := nil;
  end;
  result := fConfig.Auth;
end;

procedure TfmxMain.btnSettingsClick(Sender: TObject);
begin
  WipeToTab(tabProjectSettings);
end;

procedure TfmxMain.btnSignOutClick(Sender: TObject);
begin
  StopListener;
  fConfig.Auth.SignOut;
  fUID := '';
  WipeToTab(tabSignIn);
  FraSelfRegistration.StartEMailEntering;
end;

procedure TfmxMain.OnUserLogin(const Info: string; User: IFirebaseUser);
begin
  fUID := User.UID;
  if User.IsDisplayNameAvailable and not User.DisplayName.IsEmpty then
    lblUserInfo.Text := 'Logged in user name: ' + User.DisplayName
  else
    lblUserInfo.Text := 'Logged in user eMail: ' + User.EMail;
  lblUserInfo.Text := lblUserInfo.Text + #13 + 'UserID: ' + fUID;
  StartClipboard;
end;

procedure TfmxMain.btnReconnectClick(Sender: TObject);
begin
  StartListener;
end;

procedure TfmxMain.WipeToTab(ActiveTab: TTabItem);
var
  c: integer;
begin
  if TabControl.ActiveTab <> ActiveTab then
  begin
    ActiveTab.Visible := true;
{$IFDEF ANDROID}
    TabControl.ActiveTab := ActiveTab;
{$ELSE}
    TabControl.GotoVisibleTab(ActiveTab.Index, TTabTransition.Slide,
      TTabTransitionDirection.Normal);
{$ENDIF}
    for c := 0 to TabControl.TabCount - 1 do
      TabControl.Tabs[c].Visible := TabControl.Tabs[c] = ActiveTab;
  end;
end;

procedure TfmxMain.StartClipboard;
begin
  SaveSettings;
  WipeToTab(tabClipboard);
  StartListener;
end;

procedure TfmxMain.StartListener;
begin
  fFirebaseEvent := fConfig.RealTimeDB.ListenForValueEvents(['cb', fUID],
    OnRecData, OnRecDataStop, OnRecDataError, nil, OnConnectionStateChange);
  btnReconnect.Visible := false;
  btnSendToCloud.Visible := true;
  fReceivedUpdates := 0;
  fErrorCount := 0;
end;

procedure TfmxMain.StopListener;
begin
  if assigned(fConfig) and assigned(fFirebaseEvent) then
    fFirebaseEvent.StopListening;
end;

procedure TfmxMain.btnSendToCloudClick(Sender: TObject);
var
  Data: TJSONObject;
begin
  FloatAnimationHideStatus.Stop;
  lblSendStatusRTDB.Opacity := 1;
  lblSendStatusRTDB.Text := '';
  Data := TJSONObject.Create;
  try
    try
      if TabControlClipboard.ActiveTab = tabText then
      begin
        Data.AddPair('type', 'text');
        Data.AddPair('text', string(UTF8Encode(memClipboardText.Lines.Text)));
      end
      else if TabControlClipboard.ActiveTab = tabGraphic then
      begin
        Data.AddPair('type', 'picture');
        Data.AddPair('picture', GetClipboardPictAsBase64);
      end else
        exit;
      fConfig.RealTimeDB.Put(['cb', fUID], Data, OnPutResp, OnPutError);
    finally
      Data.Free;
    end;
  except
    on e: exception do
    begin
      TabControlClipboard.ActiveTab := tabText;
      memClipboardText.Lines.Clear;
      memClipboardText.Lines.Add('Exception in btnSendToCloudClick at: ' +
        FormatDateTime('dd/mm/yy hh:nn:ss:zzz', now));
      memClipboardText.Lines.Add(E.ClassName);
      memClipboardText.Lines.Add(E.Message);
      memClipboardText.Lines.Add(E.StackTrace);
    end;
  end;
  aniRTDB.Visible := true;
  aniRTDB.Enabled := true;
end;

procedure TfmxMain.OnPutError(const RequestID, ErrMsg: string);
begin
  aniRTDB.Visible := false;
  aniRTDB.Enabled := false;
  FloatAnimationHideStatus.Stop;
  lblSendStatusRTDB.Opacity := 1;
  lblSendStatusRTDB.Text := 'Failure in ' + RequestID + ': ' + ErrMsg;
  if SameText(ErrMsg, 'Permission denied') then
    memClipboardText.Lines.Text := rsHintRTDBRules;
end;

procedure TfmxMain.OnPutResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniRTDB.Visible := false;
  aniRTDB.Enabled := false;
  FloatAnimationHideStatus.Stop;
  lblSendStatusRTDB.Opacity := 1;
  lblSendStatusRTDB.Text := 'Clipboard updated';
  FloatAnimationHideStatus.Start;
end;

procedure TfmxMain.OnRecData(const Event: string; Params: TRequestResourceParam;
  JSONObj: TJSONObject);
var
  Path: string;
  Data: TJSONObject;
begin
  Assert(assigned(JSONObj), 'JSON object expected');
  Assert(JSONObj.Count = 2, 'Invalid JSON object received');
  Path := JSONObj.Pairs[0].JsonValue.Value;
  if JSONObj.Pairs[1].JsonValue is TJSONObject then
  begin
    inc(fReceivedUpdates);
    Data := JSONObj.Pairs[1].JsonValue as TJSONObject;
    // '{"text":"payload of clipboard","type":"text"}'
    if Data.GetValue('type').Value = 'text' then
    begin
      TabControlClipboard.ActiveTab := tabText;
      memClipboardText.Lines.Text :=
        UTF8ToString(RawByteString(Data.GetValue('text').Value))
    end
    else if Data.GetValue('type').Value = 'picture' then
    begin
      TabControlClipboard.ActiveTab := tabGraphic;
      SetClipboardPictFromBase64(Data.GetValue('picture').Value);
    end else begin
      TabControlClipboard.ActiveTab := tabText;
      memClipboardText.Lines.Text := 'Unsupported clipboard type: ' +
        Data.GetValue('type').Value;
    end;
    lblStatusRTDB.Text := Format('New clipboard content #%d at %s',
      [fReceivedUpdates, TimeToStr(now)]);
  end else
    lblStatusRTDB.Text := 'Clipboard is empty';
end;

procedure TfmxMain.OnRecDataError(const Info, ErrMsg: string);
begin
  inc(fErrorCount);
  lblStatusRTDB.Text := 'Clipboard error: ' + ErrMsg;
end;

procedure TfmxMain.OnRecDataStop(const RequestId: string);
begin
  lblStatusRTDB.Text := Format('Clipboard stopped at %s %d',
    [TimeToStr(now), fReceivedUpdates]);
  fFirebaseEvent := nil;
  btnReconnect.Visible := true;
  btnSendToCloud.Visible := false;
{$IFDEF DEBUG}
  tmrTesting.Enabled := false;
  chbTesting.IsChecked := false;
{$ENDIF}
end;

procedure TfmxMain.btnFromClipBoardClick(Sender: TObject);
var
  Svc: IFMXClipboardService;
  Value: TValue;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService,
    Svc) then
  begin
    Value := Svc.GetClipboard;
    if not Value.IsEmpty then
    begin
      if Value.IsType<string> then
      begin
        TabControlClipboard.ActiveTab := tabText;
        memClipboardText.Lines.Text := Value.ToString;
      end
      else if Value.IsType<TBitmapSurface> then
      begin
        TabControlClipboard.ActiveTab := tabGraphic;
        imgClipboardPict.Bitmap.Assign(Value.AsObject as TBitmapSurface);
      end;
    end;
  end;
end;

procedure TfmxMain.btnToClipboardClick(Sender: TObject);
var
  Svc: IFMXClipboardService;
begin
  if TPlatformServices.Current.SupportsPlatformService(IFMXClipboardService,
    Svc) then
  begin
    if TabControlClipboard.ActiveTab = tabText then
      Svc.SetClipboard(memClipboardText.Lines.Text)
    else if TabControlClipboard.ActiveTab = tabGraphic then
      Svc.SetClipboard(imgClipboardPict.Bitmap)
  end;
end;

function TfmxMain.GetClipboardPictAsBase64: string;
var
  MemoryStream: TMemoryStream;
  Bytes: TBytes;
begin
  try
    MemoryStream := TMemoryStream.Create;
    try
      imgClipboardPict.Bitmap.SaveToStream(MemoryStream);
      MemoryStream.Position := 0;
      SetLength(Bytes, MemoryStream.Size);
      MemoryStream.Read(Bytes, MemoryStream.Size);
    finally
      MemoryStream.Free;
    end;
    result := TNetEncoding.Base64.EncodeBytesToString(Bytes);
  except
    on e: exception do
    begin
      TabControlClipboard.ActiveTab := tabText;
      memClipboardText.Lines.Clear;
      memClipboardText.Lines.Add('Exception in GetClipboardPictAsBase64 at: ' +
        FormatDateTime('dd/mm/yy hh:nn:ss:zzz', now));
      memClipboardText.Lines.Add(E.ClassName);
      memClipboardText.Lines.Add(E.Message);
      memClipboardText.Lines.Add(E.StackTrace);
    end;
  end;
end;

procedure TfmxMain.SetClipboardPictFromBase64(const Base64: string);
var
  MemoryStream: TMemoryStream;
  Bytes: TBytes;
begin
  Bytes := TNetEncoding.Base64.DecodeStringToBytes(Base64);
  MemoryStream := TMemoryStream.Create;
  try
    MemoryStream.WriteData(Bytes, length(Bytes));
    MemoryStream.Position := 0;
    imgClipboardPict.Bitmap.LoadFromStream(MemoryStream);
  finally
    MemoryStream.Free;
  end;
end;

{$REGION 'StressTest'}
procedure TfmxMain.chbTestingChange(Sender: TObject);
begin
  fStressTestCounter := 0;
  tmrTesting.Enabled := chbTesting.IsChecked;
end;

procedure TfmxMain.tmrTestingTimer(Sender: TObject);
begin
  TabControlClipboard.ActiveTab := tabText;
  memClipboardText.Lines.Clear;
  memClipboardText.Lines.Add('Stress Test');
  memClipboardText.Lines.Add('Number of received updates .. : ' +
    fReceivedUpdates.ToString);
  memClipboardText.Lines.Add('Number of sent updates ...... : ' +
    fStressTestCounter.ToString);
  memClipboardText.Lines.Add('Number of errors ............ : ' +
    fErrorCount.ToString);
  memClipboardText.Lines.Add('Timestamp of last sent update : ' +
    FormatDateTime('dd/mm/yy hh:nn:ss:zzz', now));
  memClipboardText.Lines.Add('Sender''s token refresh time . : ' +
    FormatDateTime('dd/mm/yy hh:nn:ss:zzz', fConfig.Auth.TokenExpiryDT));
  memClipboardText.Lines.Add('Sender''s config and platform  : ' +
    TFirebaseHelpers.GetConfigAndPlatform);
  btnSendToCloudClick(Sender);
  inc(fStressTestCounter);
end;
{$ENDREGION}

end.
