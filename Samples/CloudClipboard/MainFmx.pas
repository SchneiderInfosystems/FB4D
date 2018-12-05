{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018 Christoph Schneider                                      }
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
  FB4D.Interfaces, FMX.MultiView, FMX.ScrollBox, FMX.Memo;

type
  TfmxMain = class(TForm)
    TabControl: TTabControl;
    tabSignIn: TTabItem;
    tabClipboard: TTabItem;
    edtEMail: TEdit;
    Text1: TText;
    btnSignIn: TButton;
    edtPassword: TEdit;
    Text2: TText;
    edtKey: TEdit;
    Text3: TText;
    edtProjectID: TEdit;
    Text4: TText;
    lblStatus: TLabel;
    AniIndicator: TAniIndicator;
    lblClipboardState: TLabel;
    btnSettings: TButton;
    tabProjectSettings: TTabItem;
    btnEnteredProjSettings: TButton;
    lblUserInfo: TLabel;
    memClipboardText: TMemo;
    btnSendToCloud: TButton;
    lblStatusRTDB: TLabel;
    aniRTDB: TAniIndicator;
    btnFromClipBoard: TButton;
    btnToClipboard: TButton;
    btnCheckEMail: TButton;
    btnSignUp: TButton;
    btnResetPwd: TButton;
    btnReconnect: TButton;
    imgClipboardPict: TImage;
    TabControlClipboard: TTabControl;
    tabText: TTabItem;
    tabGraphic: TTabItem;
    procedure btnSignInClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnEnteredProjSettingsClick(Sender: TObject);
    procedure btnSendToCloudClick(Sender: TObject);
    procedure btnFromClipBoardClick(Sender: TObject);
    procedure btnToClipboardClick(Sender: TObject);
    procedure btnCheckEMailClick(Sender: TObject);
    procedure edtEMailChangeTracking(Sender: TObject);
    procedure btnSignUpClick(Sender: TObject);
    procedure btnResetPwdClick(Sender: TObject);
    procedure btnReconnectClick(Sender: TObject);
  private
    fAuth: IFirebaseAuthentication;
    fUID: string;
    fRealTimeDB: IRealTimeDB;
    fFirebaseEvent: IFirebaseEvent;
    procedure CreateAuthenticationClass;
    procedure CreateRealTimeDBClass;
    procedure OnFetchProviders(const EMail: string; IsRegistered: boolean;
      Providers: TStrings);
    procedure OnFetchProvidersError(const Info, ErrMsg: string);
    procedure OnUserResponse(const Info: string; User: IFirebaseUser);
    procedure OnUserError(const Info, ErrMsg: string);
    procedure OnResetPwd(const Info: string; Response: IFirebaseResponse);
    procedure OnPutResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnPutError(const RequestID, ErrMsg: string);
    procedure WipeToTab(ActiveTab: TTabItem);
    procedure StartClipboard;
    procedure OnRecData(const Event: string; Params: TRequestResourceParam;
      JSONObj: TJSONObject);
    procedure OnRecDataError(const Info, ErrMsg: string);
    procedure OnRecDataStop(Sender: TObject);
    procedure StartListener;
    procedure StopListener;
    procedure SaveSettings;
    function GetClipboardPictAsBase64: string;
    procedure SetClipboardPictFromBase64(const Base64: string);
  end;

var
  fmxMain: TfmxMain;

implementation

uses
  System.IniFiles, System.IOUtils, System.StrUtils, System.Rtti,
  System.NetEncoding, System.Generics.Collections,
  FMX.Platform, FMX.Surfaces,
  FB4D.Authentication, FB4D.Helpers, FB4D.Response, FB4D.Request,
  FB4D.RealTimeDB;

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

procedure TfmxMain.FormShow(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini'));
  try
    edtKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text := IniFile.ReadString('FBProjectSettings', 'ProjectID',
      '');
    edtEmail.Text := IniFile.ReadString('Authentication', 'User', '');
    edtPassword.Text := IniFile.ReadString('Authentication', 'Pwd', '');
  finally
    IniFile.Free;
  end;
  if edtKey.Text.IsEmpty or edtProjectID.Text.IsEmpty then
    TabControl.ActiveTab := tabProjectSettings
  else
    TabControl.ActiveTab := tabSignIn;
  btnCheckEMail.Enabled := TFirebaseHelpers.IsEMailAdress(edtEMail.Text);
  if btnCheckEMail.Enabled then
    btnCheckEMail.SetFocus
  else
    edtEMail.SetFocus;
  lblStatus.Text := rsEnterEMail;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  edtPassword.Visible := false;
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
  IniFile := TIniFile.Create(IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini'));
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('Authentication', 'User', edtEmail.Text);
    {$MESSAGE 'Attention: Password will be stored in your inifile in clear text'}
    IniFile.WriteString('Authentication', 'Pwd', edtPassword.Text);
  finally
    IniFile.Free;
  end;
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
  end;
end;

procedure TfmxMain.CreateAuthenticationClass;
begin
  if not assigned(fAuth) then
  begin
    fAuth := TFirebaseAuthentication.Create(edtKey.Text);
    edtKey.ReadOnly := true;
    edtProjectID.ReadOnly := true;
  end;
end;

procedure TfmxMain.CreateRealTimeDBClass;
begin
  if not assigned(fRealTimeDB) then
  begin
    fRealTimeDB := TRealTimeDB.Create(edtProjectID.Text, fAuth);
    fFirebaseEvent := nil;
  end;
end;

procedure TfmxMain.edtEMailChangeTracking(Sender: TObject);
begin
  btnCheckEMail.Enabled := TFirebaseHelpers.IsEMailAdress(edtEMail.Text);
  edtPassword.Visible := false;
  btnSignUp.Visible := false;
  btnSignIn.Visible := false;
end;

procedure TfmxMain.btnSettingsClick(Sender: TObject);
begin
  WipeToTab(tabProjectSettings);
end;

procedure TfmxMain.btnCheckEMailClick(Sender: TObject);
begin
  CreateAuthenticationClass;
  fAuth.FetchProvidersForEMail(edtEmail.Text, OnFetchProviders,
    OnFetchProvidersError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnCheckEMail.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TfmxMain.OnFetchProviders(const EMail: string; IsRegistered: boolean;
  Providers: TStrings);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  if IsRegistered then
  begin
    btnSignIn.Visible := true;
    btnResetPwd.Visible := true;
    edtPassword.Visible := true;
    lblStatus.Text := rsEnterPassword;
  end else begin
    btnSignUp.Visible := true;
    edtPassword.Visible := true;
    edtPassword.Text := ''; // clear default password
    btnSignIn.Visible := false;
    btnResetPwd.Visible := false;
    lblStatus.Text := rsSetupPassword;
  end;
  edtPassword.SetFocus;
  btnCheckEMail.Visible := false;
end;

procedure TfmxMain.OnFetchProvidersError(const Info, ErrMsg: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Text := Info + ': ' + ErrMsg;
  btnCheckEMail.Enabled := true;
end;

procedure TfmxMain.btnSignInClick(Sender: TObject);
begin
  fAuth.SignInWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
    OnUserResponse, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignIn.Enabled := false;
  btnResetPwd.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TfmxMain.btnSignUpClick(Sender: TObject);
begin
  fAuth.SignUpWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
    OnUserResponse, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignUp.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TfmxMain.btnReconnectClick(Sender: TObject);
begin
  StartListener;
end;

procedure TfmxMain.btnResetPwdClick(Sender: TObject);
begin
  fAuth.SendPasswordResetEMail(edtEMail.Text, OnResetPwd, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignIn.Enabled := false;
  btnResetPwd.Enabled := false;
  lblStatus.Text := rsWait;
end;

procedure TfmxMain.OnUserError(const Info, ErrMsg: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Text := Info + ': ' + ErrMsg;
  btnSignIn.Enabled := true;
  btnResetPwd.Enabled := true;
  btnSignUp.Enabled := true;
end;

procedure TfmxMain.OnUserResponse(const Info: string;
  User: IFirebaseUser);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Text := 'Logged in to Cloud Clipboard';
  fUID := User.UID;
  if User.IsDisplayNameAvailable and not User.DisplayName.IsEmpty then
    lblUserInfo.Text := 'Logged in user name: ' + User.DisplayName
  else
    lblUserInfo.Text := 'Logged in user eMail: ' + User.EMail;
  StartClipboard;
end;

procedure TfmxMain.OnResetPwd(const Info: string; Response: IFirebaseResponse);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  btnSignIn.Enabled := true;
  if Response.StatusOk then
    lblStatus.Text := 'Please check your email box to renew your password.'
  else
    lblStatus.Text := Response.ErrorMsgOrStatusText;
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
  CreateRealTimeDBClass;
  StartListener;
end;

procedure TfmxMain.StartListener;
begin
  fFirebaseEvent := fRealTimeDB.ListenForValueEvents(['cb', fUID],
    OnRecData, OnRecDataStop, OnRecDataError);
  btnReconnect.Visible := false;
  btnSendToCloud.Visible := true;
end;

procedure TfmxMain.StopListener;
begin
  if assigned(fRealTimeDB) and assigned(fFirebaseEvent) then
    fFirebaseEvent.StopListening('stopEvent');
end;

procedure TfmxMain.btnSendToCloudClick(Sender: TObject);
var
  Data: TJSONObject;
begin
  lblStatusRTDB.Text := '';
  Data := TJSONObject.Create;
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
    StopListener;
    fRealTimeDB.Put(['cb', fUID], Data, OnPutResp, OnPutError);
  finally
    Data.Free;
  end;
  aniRTDB.Visible := true;
  aniRTDB.Enabled := true;
end;

procedure TfmxMain.OnPutError(const RequestID, ErrMsg: string);
begin
  aniRTDB.Visible := false;
  aniRTDB.Enabled := false;
  lblStatusRTDB.Text := 'Failure in ' + RequestID + ': ' + ErrMsg;
  if SameText(ErrMsg, 'Permission denied') then
    memClipboardText.Lines.Text := rsHintRTDBRules;
  StartListener;
end;

procedure TfmxMain.OnPutResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniRTDB.Visible := false;
  aniRTDB.Enabled := false;
  lblStatusRTDB.Text := 'Clipboard updated';
  StartListener;
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
    Data := JSONObj.Pairs[1].JsonValue  as TJSONObject;
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
    lblStatusRTDB.Text := 'New clipboard content at ' + TimeToStr(now);
  end else
    lblStatusRTDB.Text := 'Clipboard is empty';
end;

procedure TfmxMain.OnRecDataError(const Info, ErrMsg: string);
begin
  lblStatusRTDB.Text := 'Clipboard error: ' + ErrMsg;
end;

procedure TfmxMain.OnRecDataStop(Sender: TObject);
begin
  lblStatusRTDB.Text := 'Clipboard stopped';
  fFirebaseEvent := nil;
  btnReconnect.Visible := true;
  btnSendToCloud.Visible := false;
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

end.
