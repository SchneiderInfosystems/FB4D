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

unit FB4D.MFAMainFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IOUtils, System.IniFiles,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, FMX.Objects,
  FB4D.Configuration, FB4D.Interfaces, FB4D.Helpers, DelphiZXingQRCode;

type
  TfmxMainMFA = class(TForm)
    TabControl: TTabControl;
    TabConfig: TTabItem;
    TabLogin: TTabItem;
    TabMFA: TTabItem;
    TabTest: TTabItem;
    edtApiKey: TEdit;
    Label1: TLabel;
    edtProjectID: TEdit;
    Label2: TLabel;
    btnInitialize: TButton;
    edtEmail: TEdit;
    Label3: TLabel;
    edtPassword: TEdit;
    Label4: TLabel;
    btnLogin: TButton;
    btnSignUpNewUser: TButton;
    btnBackToConfig: TButton;
    edtMfaCode: TEdit;
    edtTestMfaCode: TEdit;
    imgQR: TImage;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    tabEnterMFACode: TTabItem;
    lblTestOTP: TLabel;
    btnAbortLogin: TButton;
    procedure btnAbortLoginClick(Sender: TObject);
    procedure btnInitializeClick(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
    procedure btnSignUpNewUserClick(Sender: TObject);
    procedure btnBackToConfigClick(Sender: TObject);
    procedure edtApiKeyAndProjectIDChange(Sender: TObject);
    procedure btnStartMfaClick(Sender: TObject);
    procedure btnFinalizeMfaClick(Sender: TObject);
    procedure btnSignOutClick(Sender: TObject);
    procedure btnTestSignInClick(Sender: TObject);
    procedure btnTestFinalizeMfaClick(Sender: TObject);
    procedure edtEmailChange(Sender: TObject);
    procedure edtEmailChangeTracking(Sender: TObject);
    procedure edtPasswordEnter(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    fMfaPending: TMfaPendingCredential;
    function GetSettingFileName: string;
    function CheckIfEMailIsVerified(User: IFirebaseUser): boolean;
    procedure RenderQR(const URI: string);
    // Callbacks
    procedure OnFetchProviders(const EMail: string; IsRegistered: boolean;
      Providers: TStrings);
    procedure OnFetchProvidersError(const Info, ErrMsg: string);
    procedure OnUserResponse(const Info: string; User: IFirebaseUser);
    procedure OnError(const RequestID, ErrMsg: string);
    procedure OnGetUserData(FirebaseUserList: TFirebaseUserList);
    procedure OnEmailVerificationSent(const RequestID: string; Response: IFirebaseResponse);
    procedure OnMfaEnrollment(const EnrollmentInfo: TMfaTotpEnrollmentInfo);
    procedure OnMfaRequired(PendingCredential: TMfaPendingCredential);
  private const
    cIssuerName = 'FB4D MFA Demo';
  end;

var
  fmxMainMFA: TfmxMainMFA;

implementation

resourcestring
  rsVerficationSent = 'You get an email verification. Check your mailbox and confirm your mail address. Retry login afterwards!';
  rslblTestOTP = 'Enter OTP Code from Authenticator App in %s';
  rsEnterOTP = 'Multifactor authentication required! Please enter OTP and click Verify OTP.';
  rsMissingMfa = 'Nothing pending. Please press Login Again to trigger MFA requirement.';
  rsLoggedInSuccess = '%s logged in successfully with multifactor authentication!';
  rsSuccess = '%s success: %s';
  rsError = 'Error [%s]: %s';
  rsSignedOut = 'Signed out';
  
{$R *.fmx}

function TfmxMainMFA.GetSettingFileName: string;
begin
  Result := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetHomePath, 'FB4D_MFA_Wizard.ini');
end;

procedure TfmxMainMFA.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFileName);
  try
    edtApiKey.Text := IniFile.ReadString('Settings', 'ApiKey', '');
    edtProjectID.Text := IniFile.ReadString('Settings', 'ProjectId', '');
    edtEmail.Text := IniFile.ReadString('Login', 'Email', '');
  finally
    IniFile.Free;
  end;
  lblTestOTP.Text := Format(rslblTestOTP, [cIssuerName]);
  edtApiKeyAndProjectIDChange(nil);
  if btnInitialize.Enabled then
    btnInitializeClick(nil)
  else
    TabControl.ActiveTab := TabConfig;
end;

procedure TfmxMainMFA.FormDestroy(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFileName);
  try
    IniFile.WriteString('Settings', 'ApiKey', edtApiKey.Text);
    IniFile.WriteString('Settings', 'ProjectId', edtProjectID.Text);
    IniFile.WriteString('Login', 'Email', edtEmail.Text);
  finally
    IniFile.Free;
  end;
  fConfig := nil;
end;

procedure TfmxMainMFA.edtApiKeyAndProjectIDChange(Sender: TObject);
begin
  edtApiKey.Text := edtApiKey.Text.Trim;
  edtProjectID.Text := edtProjectID.Text.Trim;
  btnInitialize.Enabled := not(edtApiKey.Text.IsEmpty or edtProjectID.Text.IsEmpty);
end;

procedure TfmxMainMFA.btnInitializeClick(Sender: TObject);
begin
  fConfig := TFirebaseConfiguration.Create(edtApiKey.Text, edtProjectId.Text, '');
  TabControl.ActiveTab := TabLogin;
end;

procedure TfmxMainMFA.btnBackToConfigClick(Sender: TObject);
begin
  fConfig := nil;
  TabControl.ActiveTab := TabConfig;
end;

procedure TfmxMainMFA.btnLoginClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  fConfig.Auth.SignInWithEmailAndPasswordWithMFA(edtEmail.Text, edtPassword.Text, OnUserResponse, OnMfaRequired, OnError);
end;

procedure TfmxMainMFA.btnSignUpNewUserClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  fConfig.Auth.SignUpWithEmailAndPassword(edtEmail.Text, edtPassword.Text, OnUserResponse, OnError);
end;

procedure TfmxMainMFA.edtEmailChange(Sender: TObject);
begin
  edtEmail.Text := edtEmail.Text.Trim;
  edtPassword.Text := edtPassword.Text.Trim;
end;

procedure TfmxMainMFA.edtEmailChangeTracking(Sender: TObject);
begin
  btnLogin.Enabled := not(edtEMail.Text.IsEmpty or edtPassword.Text.IsEmpty);
  btnSignUpNewUser.Enabled := btnLogin.Enabled;
end;

procedure TfmxMainMFA.edtPasswordEnter(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  fConfig.Auth.FetchProvidersForEMail(trim(edtEmail.Text), OnFetchProviders, OnFetchProvidersError);
end;

procedure TfmxMainMFA.OnFetchProviders(const EMail: string; IsRegistered: boolean; Providers: TStrings);
begin
  btnLogin.Visible := IsRegistered;
  btnSignUpNewUser.Visible := not IsRegistered;
end;

procedure TfmxMainMFA.OnFetchProvidersError(const Info, ErrMsg: string);
begin
  lblStatus.Text := Info + ': ' + ErrMsg;
end;

procedure TfmxMainMFA.OnUserResponse(const Info: string; User: IFirebaseUser);
begin
  fMfaPending.MfaPendingCredential := '';
  edtTestMfaCode.Text := '';
  if TabControl.ActiveTab = tabEnterMFACode then
    lblStatus.Text := Format(rsLoggedInSuccess, [User.PrettyName])
  else
    lblStatus.Text := Format(rsSuccess, [User.PrettyName, Info]);
  if TabControl.ActiveTab = TabLogin then
  begin
    if CheckIfEMailIsVerified(User) then
      TabControl.ActiveTab := TabMFA;
  end
  else if TabControl.ActiveTab = tabEnterMFACode then
    TabControl.ActiveTab := TabTest
  else if TabControl.ActiveTab = TabMFA then
    TabControl.ActiveTab := TabTest;
end;

function TfmxMainMFA.CheckIfEMailIsVerified(User: IFirebaseUser): boolean;
begin
  result := false;
  case User.IsEMailVerified of
    tsbTrue:
      result := true;
    tsbFalse:
      fConfig.Auth.SendEmailVerification(OnEmailVerificationSent, OnError);
    tsbUnspecified:
      fConfig.Auth.GetUserData(OnGetUserData, OnError);
  end;
end;

procedure TfmxMainMFA.OnGetUserData(FirebaseUserList: TFirebaseUserList);
var
  User: IFirebaseUser;
begin
  for User in FirebaseUserList do
    if SameText(User.EMail, edtEmail.Text) then
    begin
      if CheckIfEMailIsVerified(User) then
        TabControl.ActiveTab := TabMFA;
      break;
    end;
end;

procedure TfmxMainMFA.OnEmailVerificationSent(const RequestID: string; Response: IFirebaseResponse);
begin
  lblStatus.Text := rsVerficationSent;
  btnLogin.visible := true;
  btnSignUpNewUser.Visible := false;
end;

procedure TfmxMainMFA.OnError(const RequestID, ErrMsg: string);
begin
  lblStatus.Text := Format(rsError, [RequestID, ErrMsg]);
end;

procedure TfmxMainMFA.OnMfaRequired(PendingCredential: TMfaPendingCredential);
begin
  fMfaPending := PendingCredential;
  lblStatus.Text := rsEnterOTP;
  TabControl.ActiveTab := tabEnterMFACode;
  edtTestMfaCode.SetFocus;
end;

procedure TfmxMainMFA.btnStartMfaClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  fConfig.Auth.StartMfaTotpEnrollment(OnMfaEnrollment, OnError);
end;

procedure TfmxMainMFA.OnMfaEnrollment(const EnrollmentInfo: TMfaTotpEnrollmentInfo);
begin
  RenderQR(EnrollmentInfo.CalcQrCodeURL(edtEmail.Text, cIssuerName));
  edtMfaCode.SetFocus;
end;

procedure TfmxMainMFA.btnFinalizeMfaClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  fConfig.Auth.FinalizeMfaTotpEnrollment(edtMfaCode.Text, cIssuerName, OnUserResponse, OnError);
end;

procedure TfmxMainMFA.btnSignOutClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  fConfig.Auth.SignOut;
  lblStatus.Text := rsSignedOut;
  btnLogin.Visible := false;
  btnSignUpNewUser.Visible := false;
  edtEmail.Text := '';
  edtPassword.Text := '';
  TabControl.ActiveTab := TabLogin;
end;

procedure TfmxMainMFA.btnAbortLoginClick(Sender: TObject);
begin
  btnSignOutClick(Sender);
end;

procedure TfmxMainMFA.btnTestSignInClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  fConfig.Auth.SignInWithEmailAndPasswordWithMFA(edtEmail.Text, edtPassword.Text, OnUserResponse, OnMfaRequired, OnError);
end;

procedure TfmxMainMFA.RenderQR(const URI: string);
var
  QRCode: TDelphiZXingQRCode;
  r, c, Scale: Integer;
  Bmp: TBitmap;
begin
  QRCode := TDelphiZXingQRCode.Create;
  Bmp := TBitmap.Create;
  try
    QRCode.Data := URI;
    Scale := 4;
    Bmp.SetSize(QRCode.Rows * Scale, QRCode.Columns * Scale);
    if Bmp.Canvas.BeginScene then
    try
      Bmp.Canvas.Clear(TAlphaColors.White);
      Bmp.Canvas.Fill.Color := TAlphaColors.Black;
      for r := 0 to QRCode.Rows - 1 do
        for c := 0 to QRCode.Columns - 1 do
        begin
          if QRCode.IsBlack[r, c] then
            Bmp.Canvas.FillRect(TRectF.Create(c * Scale, r * Scale, (c + 1) * Scale, (r + 1) * Scale), 0, 0, AllCorners, 1);
        end;
    finally
      Bmp.Canvas.EndScene;
    end;
    imgQR.Bitmap.Assign(Bmp);
  finally
    Bmp.Free;
    QRCode.Free;
  end;
end;

procedure TfmxMainMFA.btnTestFinalizeMfaClick(Sender: TObject);
begin
  Assert(assigned(fConfig), 'fConfig missing');
  if fMfaPending.MfaPendingCredential = '' then
    lblStatus.Text := rsMissingMfa
  else
    fConfig.Auth.MfaSignIn(fMfaPending, edtTestMfaCode.Text, OnUserResponse, OnError);
end;

end.
