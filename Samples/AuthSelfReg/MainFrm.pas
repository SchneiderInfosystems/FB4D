{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2026 Christoph Schneider                                 }
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
unit MainFrm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.TabControl, FMX.StdCtrls, FMX.Edit, FMX.Objects, FMX.Layouts,
  FMX.Controls.Presentation,
  FB4D.SelfRegistrationFra, FB4D.Interfaces;

type
  TfrmMain = class(TForm)
    TabControl: TTabControl;
    tabLogin: TTabItem;
    tabFirebaseSettings: TTabItem;
    lblProjectID: TLabel;
    edtProjectID: TEdit;
    lblWebAPIKey: TLabel;
    edtWebAPIKey: TEdit;
    lblBucket: TLabel;
    edtBucket: TEdit;
    lblGoogleOAuthClientID: TLabel;
    edtGoogleOAuthClientID: TEdit;
    lblGoogleOAuthClientSecret: TLabel;
    edtGoogleOAuthClientSecret: TEdit;
    btnSaveSettings: TButton;
    tabLoggedIn: TTabItem;
    edtLoggedInUser: TEdit;
    imgUser: TImage;
    FraSelfRegistration: TFraSelfRegistration;
    btnSignOut: TButton;
    layTopBar: TLayout;
    btnSettings: TButton;
    chbAllowAutoLogin: TCheckBox;
    chbAllowSelfRegistration: TCheckBox;
    chbRequireVerificatedEMail: TCheckBox;
    chbRequireMFA: TCheckBox;
    chbSupportGoogleAccount: TCheckBox;
    chbRegisterDisplayName: TCheckBox;
    Label1: TLabel;
    chbUploadProfileImg: TCheckBox;
    chbPersistentEMail: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnSaveSettingsClick(Sender: TObject);
    procedure btnSignOutClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure chbAllowSelfRegistrationChange(Sender: TObject);
    procedure chbRequireVerificatedEMailChange(Sender: TObject);
    procedure chbRegisterDisplayNameChange(Sender: TObject);
    procedure edtGoogleOAuthChange(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    fLastEMail: string;
    fLastToken: string;
    function GetSettingFileName: string;
    procedure SaveSettings;
    procedure StartLogin;
    function GetAuth: IFirebaseAuthentication;
    function GetStorage: IFirebaseStorage;
    procedure OnTokenRefresh(TokenRefreshed: boolean);
    procedure OnUserLogin(const Info: string; User: IFirebaseUser);
    function GetCacheFolder: string;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.IniFiles, System.IOUtils,
  FB4D.Helpers, FB4D.Configuration;

{$R *.fmx}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  Caption := Caption + ' - ' + TFirebaseHelpers.GetConfigAndPlatform +
    ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
  IniFile := TIniFile.Create(GetSettingFileName);
  try
    edtWebAPIKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    edtBucket.Text := IniFile.ReadString('FBProjectSettings', 'Bucket', '');
    edtGoogleOAuthClientID.Text := IniFile.ReadString('GoogleOAuth2', 'ClientID', '');
    edtGoogleOAuthClientSecret.Text := IniFile.ReadString('GoogleOAuth2', 'ClientSecret', '');
    chbAllowAutoLogin.IsChecked := IniFile.ReadBool('Settings', 'AllowAutoLogin', true);
    chbPersistentEMail.IsChecked := IniFile.ReadBool('Settings', 'PersistentEMail', true);
    chbAllowSelfRegistration.IsChecked := IniFile.ReadBool('Settings', 'AllowSelfRegistration', true);
    chbRequireVerificatedEMail.IsChecked := IniFile.ReadBool('Settings', 'RequireVerificatedEMail', true);
    chbRequireMFA.IsChecked := IniFile.ReadBool('Settings', 'RequireMFA', false);
    chbAllowSelfRegistrationChange(nil);
    chbSupportGoogleAccount.IsChecked := IniFile.ReadBool('Settings', 'SupportGoogleAccount', false);
    edtGoogleOAuthChange(nil);
    chbRegisterDisplayName.IsChecked := IniFile.ReadBool('Settings', 'RegisterDisplayName', true);
    chbUploadProfileImg.IsChecked := IniFile.ReadBool('Settings', 'UploadProfileImg', true);
    if chbPersistentEMail.IsChecked then
      fLastEMail := IniFile.ReadString('Authentication', 'User', '');
    if chbAllowAutoLogin.IsChecked then
      fLastToken := IniFile.ReadString('Authentication', 'Token', '');
  finally
    IniFile.Free;
  end;
  if length(edtWebAPIKey.Text) *
     length(edtProjectID.Text) *
     length(edtBucket.Text) = 0 then
    btnSettingsClick(nil)
  else
    StartLogin;
end;

procedure TfrmMain.btnSettingsClick(Sender: TObject);
begin
  TabControl.ActiveTab := tabFirebaseSettings;
end;

function TfrmMain.GetSettingFileName: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
  result := TPath.Combine(TPath.GetHomePath, FileName);
end;

function TfrmMain.GetAuth: IFirebaseAuthentication;
begin
  if not assigned(fConfig) then
  begin
    fConfig := TFirebaseConfiguration.Create(edtWebAPIKey.Text, edtProjectID.Text);
    fConfig.Auth.InstallTokenRefreshNotification(OnTokenRefresh);
    edtWebAPIKey.Enabled := false;
    edtProjectID.Enabled := false;
  end;
  result := fConfig.Auth;
  if chbSupportGoogleAccount.IsChecked and
     (length(edtGoogleOAuthClientID.Text) > 0) and
     (length(edtGoogleOAuthClientSecret.Text) > 0) then
    result.SetGoogleAuth2(edtGoogleOAuthClientID.Text, edtGoogleOAuthClientSecret.Text);
end;

function TfrmMain.GetStorage: IFirebaseStorage;
begin
  Assert(assigned(fConfig), 'FirebaseConfiguration not initialized');
  if (length(edtBucket.Text) > 0) and edtBucket.Enabled then
  begin
    edtBucket.Enabled := false;
    fConfig.SetBucket(edtBucket.Text);
    fConfig.Storage.SetupCacheFolder(GetCacheFolder);
  end;
  result := fConfig.Storage;
end;

function TfrmMain.GetCacheFolder: string;
var
  DirName: string;
begin
  DirName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  result := IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    IncludeTrailingPathDelimiter(DirName);
end;

procedure TfrmMain.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFileName);
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtWebAPIKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('FBProjectSettings', 'Bucket', edtBucket.Text);
    IniFile.WriteString('GoogleOAuth2', 'ClientID', edtGoogleOAuthClientID.Text);
    IniFile.WriteString('GoogleOAuth2', 'ClientSecret', edtGoogleOAuthClientSecret.Text);
    if chbPersistentEMail.IsChecked then
    begin
      fLastEMail := FraSelfRegistration.GetEMail;
      IniFile.WriteString('Authentication', 'User', fLastEMail);
    end else begin
      fLastEMail := '';
      IniFile.DeleteKey('Authentication', 'User');
    end;
    if assigned(fConfig) and fConfig.Auth.Authenticated and chbAllowAutoLogin.IsChecked then
      IniFile.WriteString('Authentication', 'Token',
        fConfig.Auth.GetRefreshToken) // Better encrypt this information
    else
      IniFile.DeleteKey('Authentication', 'Token');
    IniFile.WriteBool('Settings', 'AllowAutoLogin', chbAllowAutoLogin.IsChecked);
    IniFile.WriteBool('Settings', 'PersistentEMail', chbPersistentEMail.IsChecked);
    IniFile.WriteBool('Settings', 'AllowSelfRegistration', chbAllowSelfRegistration.IsChecked);
    IniFile.WriteBool('Settings', 'RequireVerificatedEMail', chbRequireVerificatedEMail.IsChecked);
    IniFile.WriteBool('Settings', 'RequireMFA', chbRequireMFA.IsChecked);
    IniFile.WriteBool('Settings', 'SupportGoogleAccount', chbSupportGoogleAccount.IsChecked);
    IniFile.WriteBool('Settings', 'RegisterDisplayName', chbRegisterDisplayName.IsChecked);
    IniFile.WriteBool('Settings', 'UploadProfileImg', chbUploadProfileImg.IsChecked);
  finally
    IniFile.Free;
  end;
end;

procedure TfrmMain.OnTokenRefresh(TokenRefreshed: boolean);
begin
  SaveSettings;
end;

procedure TfrmMain.btnSaveSettingsClick(Sender: TObject);
begin
  if chbPersistentEMail.IsChecked then
    fLastEMail := FraSelfRegistration.GetEMail
  else
    fLastEMail := '';
  if not chbAllowAutoLogin.IsChecked then
    fLastToken := '';
  SaveSettings;
  StartLogin;
end;

procedure TfrmMain.StartLogin;
begin
  TabControl.ActiveTab := tabLogin;
  Application.ProcessMessages;
  FraSelfRegistration.InitializeAuthOnDemand(GetAuth, OnUserLogin, fLastToken,
    fLastEMail, chbAllowSelfRegistration.IsChecked,
    chbRequireVerificatedEMail.IsChecked,
    chbRegisterDisplayName.IsChecked, true,
    chbSupportGoogleAccount.IsChecked,
    chbRequireMFA.IsChecked);
  if chbUploadProfileImg.IsChecked then
    FraSelfRegistration.RequestProfileImg(GetStorage);
end;

procedure TfrmMain.OnUserLogin(const Info: string; User: IFirebaseUser);
begin
  TabControl.ActiveTab := tabLoggedIn;
  edtLoggedInUser.Text := User.DisplayName + ' (UID:' + User.UID + ')';
  if assigned(FraSelfRegistration.ProfileImg) then
    imgUser.Bitmap.Assign(FraSelfRegistration.ProfileImg);
  SaveSettings;
end;

procedure TfrmMain.btnSignOutClick(Sender: TObject);
begin
  fLastToken := '';
  if chbPersistentEMail.IsChecked then
    fLastEMail := FraSelfRegistration.GetEMail
  else
    fLastEMail := '';
  fConfig.Auth.SignOut;
  SaveSettings;
  StartLogin;
end;

procedure TfrmMain.chbAllowSelfRegistrationChange(Sender: TObject);
begin
  chbRequireVerificatedEMail.Enabled := chbAllowSelfRegistration.IsChecked;
  if not chbAllowSelfRegistration.IsChecked then
    chbRequireVerificatedEMail.IsChecked := false;
  chbRequireVerificatedEMailChange(Sender);
end;

procedure TfrmMain.chbRequireVerificatedEMailChange(Sender: TObject);
begin
  chbRequireMFA.Enabled := chbRequireVerificatedEMail.IsChecked;
  if not chbRequireVerificatedEMail.IsChecked then
    chbRequireMFA.IsChecked := false;
end;

procedure TfrmMain.chbRegisterDisplayNameChange(Sender: TObject);
begin
  chbUploadProfileImg.Enabled := chbRegisterDisplayName.IsChecked;
  if not chbRegisterDisplayName.IsChecked then
    chbUploadProfileImg.IsChecked := false;
end;

procedure TfrmMain.edtGoogleOAuthChange(Sender: TObject);
begin
  chbSupportGoogleAccount.Enabled :=
    (length(edtGoogleOAuthClientID.Text) > 0) and
    (length(edtGoogleOAuthClientSecret.Text) > 0);
  if not chbSupportGoogleAccount.Enabled then
    chbSupportGoogleAccount.IsChecked := false;
end;

end.

