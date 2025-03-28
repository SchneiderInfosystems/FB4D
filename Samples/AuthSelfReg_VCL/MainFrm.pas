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
unit MainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.WinXPanels,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask,
  FB4D.SelfRegistrationFra, FB4D.Interfaces;

type
  TfrmMain = class(TForm)
    CardPanel: TCardPanel;
    CardLogin: TCard;
    CardFirebaseSettings: TCard;
    edtProjectID: TLabeledEdit;
    edtWebAPIKey: TLabeledEdit;
    edtBucket: TLabeledEdit;
    btnSaveSettings: TButton;
    CardLoggedIn: TCard;
    edtLoggedInUser: TEdit;
    imgUser: TImage;
    FraSelfRegistration: TFraSelfRegistration;
    btnSignOut: TButton;
    btnSettings: TButton;
    chbAllowAutoLogin: TCheckBox;
    chbAllowSelfRegistration: TCheckBox;
    chbRequireVerificatedEMail: TCheckBox;
    chbRegisterDisplayName: TCheckBox;
    Label1: TLabel;
    chbUploadProfileImg: TCheckBox;
    chbPersistentEMail: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure btnSaveSettingsClick(Sender: TObject);
    procedure btnSignOutClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure chbAllowSelfRegistrationClick(Sender: TObject);
    procedure chbRegisterDisplayNameClick(Sender: TObject);
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

{$R *.dfm}

procedure TfrmMain.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  Caption := Caption + ' - ' + TFirebaseHelpers.GetConfigAndPlatform +
    ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtWebAPIKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    edtBucket.Text := IniFile.ReadString('FBProjectSettings', 'Bucket', '');
    chbAllowAutoLogin.checked := IniFile.ReadBool('Settings', 'AllowAutoLogin', true);
    chbPersistentEMail.checked := IniFile.ReadBool('Settings', 'PersistentEMail', true);
    chbAllowSelfRegistration.checked := IniFile.ReadBool('Settings', 'AllowSelfRegistration', true);
    chbRequireVerificatedEMail.checked := IniFile.ReadBool('Settings', 'RequireVerificatedEMail', true);
    chbRegisterDisplayName.checked := IniFile.ReadBool('Settings', 'RegisterDisplayName', true);
    chbUploadProfileImg.checked := IniFile.ReadBool('Settings', 'UploadProfileImg', true);
    if chbPersistentEMail.checked then
      fLastEMail := IniFile.ReadString('Authentication', 'User', '');
    if chbAllowAutoLogin.checked then
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
  CardPanel.ActiveCard := CardFirebaseSettings;
end;

function TfrmMain.GetSettingFileName: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(Application.ExeName), '.ini');
  result := TPath.Combine(TPath.GetHomePath, FileName);
end;

function TfrmMain.GetAuth: IFirebaseAuthentication;
begin
  fConfig := TFirebaseConfiguration.Create(edtWebAPIKey.Text, edtProjectID.Text);
  result := fConfig.Auth;
  result.InstallTokenRefreshNotification(OnTokenRefresh);
  edtWebAPIKey.Enabled := false;
  edtProjectID.Enabled := false;
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
  DirName := ChangeFileExt(ExtractFileName(Application.ExeName), '');
  result := IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    IncludeTrailingPathDelimiter(DirName);
end;

procedure TfrmMain.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtWebAPIKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('FBProjectSettings', 'Bucket', edtBucket.Text);
    if chbPersistentEMail.checked then
      IniFile.WriteString('Authentication', 'User', FraSelfRegistration.GetEMail);
    if assigned(fConfig) and fConfig.Auth.Authenticated and chbAllowAutoLogin.checked then
      IniFile.WriteString('Authentication', 'Token',
        fConfig.Auth.GetRefreshToken) // Better encrypt this information
    else
      IniFile.DeleteKey('Authentication', 'Token');
    IniFile.WriteBool('Settings', 'AllowAutoLogin', chbAllowAutoLogin.checked);
    IniFile.WriteBool('Settings', 'PersistentEMail', chbPersistentEMail.checked);
    IniFile.WriteBool('Settings', 'AllowSelfRegistration', chbAllowSelfRegistration.checked);
    IniFile.WriteBool('Settings', 'RequireVerificatedEMail', chbRequireVerificatedEMail.checked);
    IniFile.WriteBool('Settings', 'RegisterDisplayName', chbRegisterDisplayName.checked);
    IniFile.WriteBool('Settings', 'UploadProfileImg', chbUploadProfileImg.checked);
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
  SaveSettings;
  StartLogin;
end;

procedure TfrmMain.StartLogin;
begin
  CardPanel.ActiveCard := CardLogin;
  Application.ProcessMessages;
  FraSelfRegistration.InitializeAuthOnDemand(GetAuth, OnUserLogin, fLastToken,
    fLastEMail, chbAllowSelfRegistration.checked,
    chbRequireVerificatedEMail.checked,
    chbRegisterDisplayName.checked);
  if chbUploadProfileImg.checked then
    FraSelfRegistration.RequestProfileImg(GetStorage);
end;

procedure TfrmMain.OnUserLogin(const Info: string; User: IFirebaseUser);
begin
  CardPanel.ActiveCard := CardLoggedIn;
  edtLoggedInUser.Text := User.DisplayName + ' (UID:' + user.UID + ')';
  if assigned(FraSelfRegistration.ProfileImg) then
    ImgUser.Picture.Assign(FraSelfRegistration.ProfileImg);
  SaveSettings;
end;

procedure TfrmMain.btnSignOutClick(Sender: TObject);
begin
  fLastToken := '';
  fConfig.Auth.SignOut;
  StartLogin;
end;

procedure TfrmMain.chbAllowSelfRegistrationClick(Sender: TObject);
begin
  chbRequireVerificatedEMail.Enabled := chbAllowSelfRegistration.checked;
  if not chbAllowSelfRegistration.checked then
    chbRequireVerificatedEMail.checked := false;
end;

procedure TfrmMain.chbRegisterDisplayNameClick(Sender: TObject);
begin
  chbUploadProfileImg.Enabled := chbRegisterDisplayName.checked;
  if not chbRegisterDisplayName.checked then
    chbUploadProfileImg.checked := false;
end;

end.
