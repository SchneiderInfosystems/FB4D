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

unit FB4D.SelfRegistrationFra;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.WinXCtrls, Vcl.Mask, Vcl.Imaging.jpeg,
  FB4D.Interfaces, Vcl.ExtDlgs;

type
  TOnGetAuth = function : IFirebaseAuthentication of object;
  TOnGetStorage = function : IFirebaseStorage of object;
  TFraSelfRegistration = class(TFrame)
    AniIndicator: TActivityIndicator;
    pnlStatus: TPanel;
    gdpAcitivityInd: TGridPanel;
    pnlCheckRegistered: TPanel;
    btnCheckEMail: TButton;
    btnGoogleOAuth: TButton;
    btnResetPwd: TButton;
    btnSignIn: TButton;
    btnSignUp: TButton;
    edtEMail: TLabeledEdit;
    pnlPassword: TPanel;
    edtPassword: TLabeledEdit;
    lblStatus: TLabel;
    pnlMFA: TPanel;
    imgQrCode: TImage;
    edtOtpCode: TLabeledEdit;
    btnVerifyOTP: TButton;
    pnlDisplayName: TPanel;
    edtDisplayName: TLabeledEdit;
    btnRegisterDisplayName: TButton;
    imgProfile: TImage;
    btnLoadProfile: TButton;
    OpenPictureDialog: TOpenPictureDialog;
    procedure edtEMailChange(Sender: TObject);
    procedure btnCheckEMailClick(Sender: TObject);
    procedure btnGoogleOAuthClick(Sender: TObject);
    procedure btnSignInClick(Sender: TObject);
    procedure btnSignUpClick(Sender: TObject);
    procedure btnResetPwdClick(Sender: TObject);
    procedure edtOtpCodeChange(Sender: TObject);
    procedure btnVerifyOTPClick(Sender: TObject);
    procedure btnRegisterDisplayNameClick(Sender: TObject);
    procedure btnLoadProfileClick(Sender: TObject);
  public const
    cDefaultProfileImgSize = 300; // 300x300 pixels
    cDefaultStoragePathForProfileImg = 'userProfiles';
    cDefaultMfaIssuerName = 'FB4D';
  private
    fAuth: IFirebaseAuthentication;
    fOnUserLogin: TOnUserResponse;
    fOnGetAuth: TOnGetAuth;
    fAllowSelfRegistration: boolean;
    fRequireVerificatedEMail: boolean;
    fRegisterDisplayName: boolean;
    fSupportGoogleAccount: boolean;
    fRequireMFA: boolean;
    fMfaIssuerName: string;
    fMfaPending: TMfaPendingCredential;
    fVerificationEMailSentFor: string;
    fLinkWithGoogleAfterSignIn: boolean;
    fRegisterProfileImg: boolean;
    fStorage: IFirebaseStorage;
    fOnGetStorage: TOnGetStorage;
    fStoragePath: string;
    fReqInfo: string;
    fInfo: string;
    fUser: IFirebaseUser;
    fTokenRefreshed: boolean;
    fProfileLoadStream: TMemoryStream;
    fProfileImgSize: integer;
    fProfileURL: string;
    fProfileImg: TJPEGImage;
    fDefaultProfileImg: TJPEGImage;
    procedure InternalInit(const LastRefreshToken, LastEMail: string;
      AutoCheckEMail: boolean);
    procedure StartTokenReferesh(const LastToken: string);
    procedure OnFetchProviders(const EMail: string; IsRegistered: boolean;
      Providers: TStrings);
    procedure OnFetchProvidersError(const Info, ErrMsg: string);
    procedure OnResetPwd(const Info: string; Response: IFirebaseResponse);
    procedure OnUserError(const Info, ErrMsg: string);
    procedure OnUserResponse(const Info: string; User: IFirebaseUser);
    procedure OnMfaRequired(PendingCredential: TMfaPendingCredential);
    procedure OnMfaEnrollment(const EnrollmentInfo: TMfaTotpEnrollmentInfo);
    procedure OnMfaError(const Info, ErrMsg: string);
    procedure RenderQR(const URI: string);
    procedure OnTokenRefresh(TokenRefreshed: boolean);
    procedure OnGetUserData(FirebaseUserList: TFirebaseUserList);
    procedure HandleUnverifiedEMail;
    procedure OnVerificationMailSent(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnChangedProfile(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnProfileImgUpload(Obj: IStorageObject);
    procedure OnProfileImgError(const RequestID, ErrMsg: string);
    procedure StartDownloadProfileImg(PhotoURL: string);
    procedure OnProfileDownload(const DownloadURL: string);
    function GetProfileImg: TJPEGImage;
    function IsGoogleConnected(User: IFirebaseUser): boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Initialize(Auth: IFirebaseAuthentication;
      OnUserLogin: TOnUserResponse; const LastRefreshToken: string = '';
      const LastEMail: string = ''; AllowSelfRegistration: boolean = true;
      RequireVerificatedEMail: boolean = false;
      RegisterDisplayName: boolean = false;
      AutoCheckEMail: boolean = true;
      SupportGoogleAccount: boolean = false;
      RequireMFA: boolean = false;
      const MfaIssuerName: string = '');
    procedure InitializeAuthOnDemand(OnGetAuth: TOnGetAuth;
      OnUserLogin: TOnUserResponse; const LastRefreshToken: string = '';
      const LastEMail: string = ''; AllowSelfRegistration: boolean = true;
      RequireVerificatedEMail: boolean = false;
      RegisterDisplayName: boolean = false;
      AutoCheckEMail: boolean = true;
      SupportGoogleAccount: boolean = false;
      RequireMFA: boolean = false;
      const MfaIssuerName: string = '');
    procedure RequestProfileImg(OnGetStorage: TOnGetStorage;
      const StoragePath: string = cDefaultStoragePathForProfileImg;
      ProfileImgSize: integer = cDefaultProfileImgSize);
    procedure StartEMailEntering;
    procedure StartEMailChecking;
    procedure InformDelayedStart(const Msg: string);
    procedure StopDelayedStart;
    function GetEMail: string;
    property ProfileImg: TJPEGImage read GetProfileImg;
    property ProfileURL: string read fProfileURL;
  end;

implementation

uses
  REST.Types,
  DelphiZXingQRCode,
  FB4D.Helpers;

{$R *.dfm}

// Under Authentication Settings > UserAction EMail enumeration protection must
// be disabled otherwise a registered email cannot be detected properly

// Install the following Storage Rule when using method RequestProfileImg:
// rules_version = '2';
// service firebase.storage {
//   match /b/{bucket}/o {
//     match /userProfiles/{userID} {
//       allow read: if request.auth != null;
//       allow write: if request.auth.uid == userID;
//     }
//   }
// }

resourcestring
  rsEnterEMail = 'Enter your e-mail address for sign-in or registration';
  rsWait = 'Please wait for Firebase';
  rsEnterPassword = 'Enter your password for registration';
  rsEnterPasswordOrGoogle =
    'Enter your password for registration or login by Google Account';
  rsEnterPasswordToLinkGoogle =
    'Enter your password once to link your existing account with Google';
  rsSetupPassword = 'Setup a new password for future registrations';
  rsNotRegisteredEMail = 'The entered e-mail is not registered';
  rsPleaseCheckEMail = 'Please check your e-mail inbox to renew your password';
  rsLoggedIn = 'Successful logged in';
  rsPleaseCheckEMailForVerify =
    'Please check your e-mail inbox to confirm your email address';
  rsEnterOTP =
    'Multi-factor authentication required! Please enter OTP and click Verify OTP.';
  rsScanQrAndEnterOTP =
    'Scan the QR code with your Authenticator app and enter the 6-digit OTP code to activate MFA.';
  rsWriteProfileData = 'Your %s will be registrated';
  rsUserError = 'Access of user data failed: %s';
  rsProfileLoadErr = 'Load of your profile photo is failed: %s';


constructor TFraSelfRegistration.Create(AOwner: TComponent);
begin
  inherited;
  pnlMFA.Visible := false;
  pnlDisplayName.Visible := false;
  btnRegisterDisplayName.Visible := false;
  imgProfile.Visible := false;
  fProfileURL := '';
  fProfileImg := nil;
  fTokenRefreshed := false;
  fStorage := nil;
  fDefaultProfileImg := TJPEGImage.Create;
  fDefaultProfileImg.Assign(imgProfile.Picture.Bitmap);
end;

destructor TFraSelfRegistration.Destroy;
begin
  fProfileLoadStream.Free;
  fDefaultProfileImg.Free;
  fProfileImg.Free;
  inherited;
end;

procedure TFraSelfRegistration.Initialize(Auth: IFirebaseAuthentication;
  OnUserLogin: TOnUserResponse; const LastRefreshToken, LastEMail: string;
  AllowSelfRegistration, RequireVerificatedEMail, RegisterDisplayName,
  AutoCheckEMail, SupportGoogleAccount, RequireMFA: boolean;
  const MfaIssuerName: string);
begin
  fAuth := Auth;
  fOnUserLogin := OnUserLogin;
  fOnGetAuth := nil;
  fAllowSelfRegistration := AllowSelfRegistration;
  fRequireVerificatedEMail := RequireVerificatedEMail or RequireMFA;
  fRegisterDisplayName := RegisterDisplayName;
  fSupportGoogleAccount := SupportGoogleAccount;
  fRequireMFA := RequireMFA;
  if MfaIssuerName.IsEmpty then
    fMfaIssuerName := cDefaultMfaIssuerName
  else
    fMfaIssuerName := MfaIssuerName;
  InternalInit(LastRefreshToken, LastEMail, AutoCheckEMail);
end;

procedure TFraSelfRegistration.InitializeAuthOnDemand(OnGetAuth: TOnGetAuth;
  OnUserLogin: TOnUserResponse; const LastRefreshToken, LastEMail: string;
  AllowSelfRegistration, RequireVerificatedEMail, RegisterDisplayName,
  AutoCheckEMail, SupportGoogleAccount, RequireMFA: boolean;
  const MfaIssuerName: string);
begin
  fAuth := nil;
  fOnUserLogin := OnUserLogin;
  fOnGetAuth := OnGetAuth;
  fAllowSelfRegistration := AllowSelfRegistration;
  fRequireVerificatedEMail := RequireVerificatedEMail or RequireMFA;
  fRegisterDisplayName := RegisterDisplayName;
  fSupportGoogleAccount := SupportGoogleAccount;
  fRequireMFA := RequireMFA;
  if MfaIssuerName.IsEmpty then
    fMfaIssuerName := cDefaultMfaIssuerName
  else
    fMfaIssuerName := MfaIssuerName;
  InternalInit(LastRefreshToken, LastEMail, AutoCheckEMail);
end;

procedure TFraSelfRegistration.InternalInit(const LastRefreshToken,
  LastEMail: string; AutoCheckEMail: boolean);
begin
  fLinkWithGoogleAfterSignIn := false;
  fMfaPending.MfaPendingCredential := '';
  edtEMail.Text := LastEMail;
  if not LastRefreshToken.IsEmpty then
    StartTokenReferesh(LastRefreshToken)
  else if AutoCheckEMail and TFirebaseHelpers.IsEMailAdress(LastEMail) then
    StartEMailChecking
  else
    StartEMailEntering;
end;

procedure TFraSelfRegistration.RequestProfileImg(OnGetStorage: TOnGetStorage;
  const StoragePath: string; ProfileImgSize: integer);
begin
  fRegisterProfileImg := true;
  fOnGetStorage := OnGetStorage;
  fStoragePath := StoragePath;
  fProfileImgSize := ProfileImgSize;
end;

procedure TFraSelfRegistration.StartEMailEntering;
begin
  fInfo := '';
  fLinkWithGoogleAfterSignIn := false;
  fMfaPending.MfaPendingCredential := '';
  pnlCheckRegistered.Top := gdpAcitivityInd.Top + gdpAcitivityInd.Height;
  pnlCheckRegistered.Visible := true;
  btnCheckEMail.Enabled := TFirebaseHelpers.IsEMailAdress(edtEMail.Text);
  btnCheckEMail.Visible := true;
  btnGoogleOAuth.Visible := fSupportGoogleAccount;
  btnGoogleOAuth.Enabled := fSupportGoogleAccount;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  pnlPassword.Visible := false;
  pnlMFA.Visible := false;
  pnlDisplayName.Visible := false;
  edtDisplayName.Text := '';
  btnRegisterDisplayName.Visible := false;
  imgProfile.Visible := false;
  lblStatus.Visible := true;
  lblStatus.Caption := rsEnterEMail;
end;

procedure TFraSelfRegistration.StartEMailChecking;
begin
  fInfo := '';
  fLinkWithGoogleAfterSignIn := false;
  fMfaPending.MfaPendingCredential := '';
  pnlCheckRegistered.Top := gdpAcitivityInd.Top + gdpAcitivityInd.Height;
  pnlCheckRegistered.Visible := true;
  if not assigned(fAuth) and assigned(fOnGetAuth) then
    fAuth := fOnGetAuth;
  Assert(assigned(fAuth), 'Auth is not initialized');
  fAuth.FetchProvidersForEMail(trim(edtEmail.Text), OnFetchProviders,
    OnFetchProvidersError);
  btnCheckEMail.Enabled := false;
  btnGoogleOAuth.Visible := fSupportGoogleAccount;
  btnGoogleOAuth.Enabled := fSupportGoogleAccount;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  pnlPassword.Visible := false;
  pnlMFA.Visible := false;
  pnlDisplayName.Visible := false;
  edtDisplayName.Text := '';
  btnRegisterDisplayName.Visible := false;
  imgProfile.Visible := false;
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  lblStatus.Visible := true;
  lblStatus.Caption := rsWait;
end;

procedure TFraSelfRegistration.edtEMailChange(Sender: TObject);
begin
  fLinkWithGoogleAfterSignIn := false;
  fMfaPending.MfaPendingCredential := '';
  if not SameText(fVerificationEMailSentFor, trim(edtEMail.Text)) then
    fVerificationEMailSentFor := '';
  if pnlPassword.Visible or pnlMFA.Visible then
  begin
    lblStatus.Caption := rsEnterEMail;
    pnlPassword.Visible := false;
    pnlMFA.Visible := false;
    btnCheckEMail.Visible := true;
    btnGoogleOAuth.Visible := fSupportGoogleAccount;
    btnGoogleOAuth.Enabled := fSupportGoogleAccount;
    btnSignUp.Visible := false;
    btnSignIn.Visible := false;
    btnResetPwd.Visible := false;
  end;
  btnCheckEMail.Enabled := TFirebaseHelpers.IsEMailAdress(edtEMail.Text);
end;

procedure TFraSelfRegistration.btnCheckEMailClick(Sender: TObject);
begin
  StartEMailChecking;
end;

procedure TFraSelfRegistration.btnGoogleOAuthClick(Sender: TObject);
begin
  if not assigned(fAuth) and assigned(fOnGetAuth) then
    fAuth := fOnGetAuth;
  Assert(assigned(fAuth), 'Auth is not initialized');
  fAuth.SignInWithGoogleAccount(OnUserResponse, OnUserError, trim(edtEMail.Text));
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnGoogleOAuth.Enabled := false;
  btnCheckEMail.Enabled := false;
  lblStatus.Caption := rsWait;
end;

procedure TFraSelfRegistration.OnFetchProviders(const EMail: string;
  IsRegistered: boolean; Providers: TStrings);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  if IsRegistered then
  begin
    if fSupportGoogleAccount and (Providers.Count = 1) and
       SameText(Providers[0], 'google.com') then
    begin
      btnGoogleOAuthClick(nil);
      exit;
    end;
    btnSignUp.Visible := false;
    btnSignIn.Visible := true;
    btnSignIn.Enabled := true;
    btnResetPwd.Visible := true;
    btnResetPwd.Enabled := true;
    lblStatus.Visible := true;
    if fSupportGoogleAccount then
      lblStatus.Caption := rsEnterPasswordOrGoogle
    else
      lblStatus.Caption := rsEnterPassword;
    pnlCheckRegistered.visible := Height >= gdpAcitivityInd.Height +
      pnlCheckRegistered.Height + pnlCheckRegistered.Height;
    pnlPassword.Top := pnlCheckRegistered.Top + pnlCheckRegistered.Height;
    pnlPassword.visible := true;
    edtPassword.Text := '';
    edtPassword.SetFocus;
    btnCheckEMail.Visible := false;
    btnGoogleOAuth.Visible := fSupportGoogleAccount;
    btnGoogleOAuth.Enabled := fSupportGoogleAccount;
  end
  else if fAllowSelfRegistration then
  begin
    btnSignUp.Visible := true;
    btnSignUp.Enabled := true;
    btnSignIn.Visible := false;
    btnResetPwd.Visible := false;
    lblStatus.Caption := rsSetupPassword;
    pnlCheckRegistered.visible := Height >= gdpAcitivityInd.Height +
      pnlCheckRegistered.Height + pnlCheckRegistered.Height;
    pnlPassword.Top := pnlCheckRegistered.Top + pnlCheckRegistered.Height;
    pnlPassword.visible := true;
    edtPassword.Text := '';
    edtPassword.SetFocus;
    btnCheckEMail.Visible := false;
    btnGoogleOAuth.Visible := fSupportGoogleAccount;
    btnGoogleOAuth.Enabled := fSupportGoogleAccount;
  end else begin
    lblStatus.Caption := rsNotRegisteredEMail;
    edtEMail.SetFocus;
  end;
end;

procedure TFraSelfRegistration.OnFetchProvidersError(const Info, ErrMsg: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Caption := Info + ': ' + ErrMsg;
  btnCheckEMail.visible := true;
  btnCheckEMail.Enabled := true;
end;

procedure TFraSelfRegistration.btnSignInClick(Sender: TObject);
begin
  fAuth.SignInWithEmailAndPasswordWithMFA(trim(edtEmail.Text), edtPassword.Text,
    OnUserResponse, OnMfaRequired, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignIn.Enabled := false;
  btnResetPwd.Enabled := false;
  lblStatus.Caption := rsWait;
end;

procedure TFraSelfRegistration.btnSignUpClick(Sender: TObject);
begin
  fAuth.SignUpWithEmailAndPassword(trim(edtEmail.Text), edtPassword.Text,
    OnUserResponse, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignUp.Enabled := false;
  lblStatus.Caption := rsWait;
end;

procedure TFraSelfRegistration.btnResetPwdClick(Sender: TObject);
begin
  fAuth.SendPasswordResetEMail(trim(edtEMail.Text), OnResetPwd, OnUserError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnSignIn.Enabled := false;
  btnResetPwd.Enabled := false;
  lblStatus.Caption := rsWait;
end;

procedure TFraSelfRegistration.OnResetPwd(const Info: string; Response: IFirebaseResponse);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  btnSignIn.Enabled := true;
  if Response.StatusOk then
    lblStatus.Caption := rsPleaseCheckEMail
  else
    lblStatus.Caption := Response.ErrorMsgOrStatusText;
end;

procedure TFraSelfRegistration.StartTokenReferesh(const LastToken: string);
begin
  if not assigned(fAuth) and assigned(fOnGetAuth) then
    fAuth := fOnGetAuth;
  Assert(assigned(fAuth), 'Auth is not initialized');
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  pnlCheckRegistered.visible := false;
  lblStatus.Caption := rsWait;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  pnlPassword.Visible := false;
  pnlMFA.Visible := false;
  fReqInfo := 'AfterTokenRefresh';
  fAuth.RefreshToken(LastToken, OnTokenRefresh, OnUserError);
end;

procedure TFraSelfRegistration.OnTokenRefresh(TokenRefreshed: boolean);
begin
  fTokenRefreshed := TokenRefreshed;
  if TokenRefreshed then
    fAuth.GetUserData(OnGetUserData, OnUserError)
  else
    StartEMailEntering;
end;

function TFraSelfRegistration.IsGoogleConnected(User: IFirebaseUser): boolean;
var
  c: integer;
begin
  result := SameText(User.OAuthProviderId, 'google.com');
  if not result then
    for c := 0 to User.ProviderCount - 1 do
      if SameText(User.Provider(c).ProviderId, 'google.com') then
        exit(true);
end;

procedure TFraSelfRegistration.OnGetUserData(FirebaseUserList: TFirebaseUserList);
var
  User: IFirebaseUser;
begin
  if FirebaseUserList.Count = 1 then
  begin
    User := FirebaseUserList[0];
    if fRequireVerificatedEMail and not IsGoogleConnected(User) then
      if User.IsEMailVerified <> tsbTrue then
      begin
        HandleUnverifiedEMail;
        exit;
      end;
    OnUserResponse(fReqInfo, User);
  end else
    StartEMailEntering;
end;

procedure TFraSelfRegistration.HandleUnverifiedEMail;
begin
  if not fVerificationEMailSentFor.IsEmpty and
     SameText(fVerificationEMailSentFor, trim(edtEMail.Text)) then
    OnVerificationMailSent('', nil)
  else begin
    fVerificationEMailSentFor := trim(edtEMail.Text);
    fAuth.SendEmailVerification(OnVerificationMailSent, OnUserError);
  end;
end;

procedure TFraSelfRegistration.OnUserError(const Info, ErrMsg: string);
var
  p1, p2: integer;
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  if fSupportGoogleAccount and Info.Contains('google.com') and
     ErrMsg.Contains('EMAIL_EXISTS') then
  begin
    p1 := Pos('[', ErrMsg);
    p2 := Pos(']', ErrMsg);
    if (p1 > 0) and (p2 > p1) then
      edtEMail.Text := Copy(ErrMsg, p1 + 1, p2 - p1 - 1);
    fLinkWithGoogleAfterSignIn := true;
    btnSignUp.Visible := false;
    btnSignIn.Visible := true;
    btnSignIn.Enabled := true;
    btnResetPwd.Visible := true;
    btnResetPwd.Enabled := true;
    lblStatus.Caption := rsEnterPasswordToLinkGoogle;
    pnlCheckRegistered.visible := Height >= gdpAcitivityInd.Height +
      pnlCheckRegistered.Height + pnlCheckRegistered.Height;
    pnlPassword.Top := pnlCheckRegistered.Top + pnlCheckRegistered.Height;
    pnlPassword.visible := true;
    edtPassword.Text := '';
    edtPassword.SetFocus;
    btnCheckEMail.Visible := false;
    btnGoogleOAuth.Visible := false;
  end else begin
    StartEMailEntering;
    lblStatus.Caption := Info + ': ' + ErrMsg;
  end;
end;

procedure TFraSelfRegistration.OnUserResponse(const Info: string;
  User: IFirebaseUser);
const
  cReqInfo4Photo = 'GetUserDataForPhoto';
  cReqInfo4Mfa = 'GetUserDataForMfa';
var
  WaitForDisplayNameOrProfile: boolean;
begin
  fMfaPending.MfaPendingCredential := '';
  if not User.IsUIDAvailable then
  begin
    fReqInfo := cReqInfo4Mfa;
    fAuth.GetUserData(OnGetUserData, OnUserError);
    exit;
  end;
  if User.IsEMailAvailable and not User.EMail.IsEmpty and
     not SameText(string(edtEMail.Text), User.EMail) then
    edtEMail.Text := User.EMail;
  if fLinkWithGoogleAfterSignIn then
  begin
    fLinkWithGoogleAfterSignIn := false;
    fAuth.LinkWithGoogleAccount(OnUserResponse, OnUserError);
  end else begin
    if fRequireVerificatedEMail and not IsGoogleConnected(User) then
      case User.IsEMailVerified of
        tsbUnspecified:
          begin
            fReqInfo := 'GetUserData';
            fAuth.GetUserData(OnGetUserData, OnUserError);
            exit;
          end;
        tsbFalse:
          begin
            HandleUnverifiedEMail;
            exit;
          end;
      end;
    if fRequireMFA and not IsGoogleConnected(User) and not User.IsMfaEnrolled then
    begin
      if not SameText(Info, cReqInfo4Mfa) and
         not SameText(Info, 'GetUserData') and
         not SameText(Info, 'AfterTokenRefresh') then
      begin
        fReqInfo := cReqInfo4Mfa;
        fAuth.GetUserData(OnGetUserData, OnUserError);
      end else begin
        fAuth.StartMfaTotpEnrollment(OnMfaEnrollment, OnUserError);
      end;
      exit;
    end;
    if fRegisterProfileImg and not User.IsPhotoURLAvailable and
      not SameText(Info, cReqInfo4Photo) and
      not SameText(Info, cReqInfo4Mfa) and
      not SameText(Info, 'GetUserData') and
      not SameText(Info, 'AfterTokenRefresh') then
    begin
      fReqInfo := cReqInfo4Photo;
      fAuth.GetUserData(OnGetUserData, OnUserError);
      exit;
    end;
    AniIndicator.Enabled := false;
    AniIndicator.Visible := false;
    pnlCheckRegistered.visible := false;
    pnlPassword.Visible := false;
    pnlMFA.Visible := false;
    btnSignIn.Visible := false;
    btnSignUp.Visible := false;
    btnResetPwd.Visible := false;
    fInfo := Info;
    if assigned(fUser) and fUser.IsUIDAvailable and (fUser.UID <> User.UID) then
    begin
      fProfileURL := '';
      imgProfile.Picture.Bitmap.Assign(fDefaultProfileImg);
    end;
    fUser := User;
    WaitForDisplayNameOrProfile := false;
    if fRegisterDisplayName and User.IsDisplayNameAvailable and
      not User.DisplayName.IsEmpty then
      edtDisplayName.Text := User.DisplayName;
    if fRegisterProfileImg and User.IsPhotoURLAvailable and
      not User.PhotoURL.IsEmpty and fProfileURL.IsEmpty then
    begin
      StartDownloadProfileImg(User.PhotoURL);
      WaitForDisplayNameOrProfile := true;
    end;
    if fRegisterDisplayName and
      (not User.IsDisplayNameAvailable or User.DisplayName.IsEmpty) then
    begin
      lblStatus.visible := false;
      pnlDisplayName.Visible := true;
      btnRegisterDisplayName.Visible := true;
      edtDisplayName.SetFocus;
      imgProfile.Visible := fRegisterProfileImg;
      btnLoadProfile.Visible := fRegisterProfileImg;
      btnLoadProfile.Enabled := fRegisterProfileImg;
      WaitForDisplayNameOrProfile := true;
    end else
      pnlDisplayName.Visible := false;
    if assigned(fOnUserLogin) and not WaitForDisplayNameOrProfile then
    begin
      lblStatus.Visible := true;
      lblStatus.Caption := rsLoggedIn;
      fOnUserLogin(fInfo, fUser);
    end;
  end;
end;

procedure TFraSelfRegistration.OnMfaRequired(
  PendingCredential: TMfaPendingCredential);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  fMfaPending := PendingCredential;
  pnlPassword.Visible := false;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  btnGoogleOAuth.Visible := false;
  imgQrCode.Visible := false;
  pnlMFA.Height := btnVerifyOTP.Top + btnVerifyOTP.Height +
    MulDiv(12, CurrentPPI, 96);
  pnlCheckRegistered.Visible := Height >= gdpAcitivityInd.Height +
    pnlCheckRegistered.Height + pnlMFA.Height;
  pnlMFA.Top := pnlCheckRegistered.Top + pnlCheckRegistered.Height;
  pnlMFA.Visible := true;
  edtOtpCode.Text := '';
  btnVerifyOTP.Enabled := false;
  edtOtpCode.SetFocus;
  lblStatus.Visible := true;
  lblStatus.Caption := rsEnterOTP;
end;

procedure TFraSelfRegistration.OnMfaEnrollment(
  const EnrollmentInfo: TMfaTotpEnrollmentInfo);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  fMfaPending.MfaPendingCredential := '';
  pnlPassword.Visible := false;
  pnlCheckRegistered.Visible := false;
  btnSignIn.Visible := false;
  btnResetPwd.Visible := false;
  btnSignUp.Visible := false;
  btnGoogleOAuth.Visible := false;
  RenderQR(EnrollmentInfo.CalcQrCodeURL(trim(edtEMail.Text), fMfaIssuerName));
  imgQrCode.Visible := true;
  pnlMFA.Height := imgQrCode.Top + imgQrCode.Height +
    MulDiv(12, CurrentPPI, 96);
  pnlMFA.Top := gdpAcitivityInd.Top + gdpAcitivityInd.Height;
  pnlMFA.Visible := true;
  imgQrCode.Left := (pnlMFA.ClientWidth - imgQrCode.Width) div 2;
  edtOtpCode.Text := '';
  btnVerifyOTP.Enabled := false;
  edtOtpCode.SetFocus;
  lblStatus.Visible := true;
  lblStatus.Caption := rsScanQrAndEnterOTP;
end;

procedure TFraSelfRegistration.OnMfaError(const Info, ErrMsg: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  edtOtpCode.Text := '';
  btnVerifyOTP.Enabled := false;
  if pnlMFA.Visible then
    edtOtpCode.SetFocus;
  lblStatus.Visible := true;
  lblStatus.Caption := Info + ': ' + ErrMsg;
end;

procedure TFraSelfRegistration.edtOtpCodeChange(Sender: TObject);
begin
  btnVerifyOTP.Enabled := length(trim(edtOtpCode.Text)) = 6;
end;

procedure TFraSelfRegistration.btnVerifyOTPClick(Sender: TObject);
begin
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
  btnVerifyOTP.Enabled := false;
  lblStatus.Caption := rsWait;
  if not fMfaPending.MfaPendingCredential.IsEmpty then
    fAuth.MfaSignIn(fMfaPending, trim(edtOtpCode.Text), OnUserResponse,
      OnMfaError)
  else
    fAuth.FinalizeMfaTotpEnrollment(trim(edtOtpCode.Text), fMfaIssuerName,
      OnUserResponse, OnMfaError);
end;

procedure TFraSelfRegistration.RenderQR(const URI: string);
const
  cScale = 8;
var
  QRCode: TDelphiZXingQRCode;
  r, c: integer;
  Bmp: TBitmap;
begin
  QRCode := TDelphiZXingQRCode.Create;
  Bmp := TBitmap.Create;
  try
    QRCode.Data := URI;
    Bmp.SetSize(QRCode.Columns * cScale, QRCode.Rows * cScale);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, Bmp.Width, Bmp.Height));
    Bmp.Canvas.Brush.Color := clBlack;
    for r := 0 to QRCode.Rows - 1 do
      for c := 0 to QRCode.Columns - 1 do
        if QRCode.IsBlack[r, c] then
          Bmp.Canvas.FillRect(Rect(c * cScale, r * cScale, (c + 1) * cScale,
            (r + 1) * cScale));
    imgQrCode.Picture.Bitmap.Assign(Bmp);
  finally
    Bmp.Free;
    QRCode.Free;
  end;
end;

function TFraSelfRegistration.GetEMail: string;
begin
  result := trim(edtEmail.Text);
end;

function TFraSelfRegistration.GetProfileImg: TJPEGImage;
begin
  if assigned(fProfileImg) then
    result := fProfileImg
  else
    result := fDefaultProfileImg;
end;

procedure TFraSelfRegistration.OnVerificationMailSent(const RequestID: string;
  Response: IFirebaseResponse);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  if not pnlPassword.Visible then
    StartEMailEntering
  else begin
    btnSignUp.Visible := false;
    btnSignIn.Visible := true;
    btnSignIn.Enabled := true;
    btnResetPwd.Visible := true;
    btnResetPwd.Enabled := true;
  end;
  lblStatus.Caption := rsPleaseCheckEMailForVerify;
end;

procedure TFraSelfRegistration.btnRegisterDisplayNameClick(Sender: TObject);
begin
  if fRegisterProfileImg then
    pnlDisplayName.Visible := false;
  btnRegisterDisplayName.Visible := false;
  lblStatus.Caption :=
    Format(rsWriteProfileData, [edtDisplayName.EditLabel.Caption]);
  fAuth.ChangeProfile('', '', edtDisplayName.Text, fProfileURL,
    OnChangedProfile, OnUserError);
end;

procedure TFraSelfRegistration.OnChangedProfile(const RequestID: string;
  Response: IFirebaseResponse);
begin
  fReqInfo := 'GetUserData';
  fAuth.GetUserData(OnGetUserData, OnUserError);
end;

procedure TFraSelfRegistration.StartDownloadProfileImg(PhotoURL: string);
begin
  FreeAndNil(fProfileLoadStream);
  imgProfile.Visible := true;
  fProfileLoadStream := TMemoryStream.Create;
  TFirebaseHelpers.SimpleDownload(PhotoURL, fProfileLoadStream,
    OnProfileDownload, OnProfileImgError);
  AniIndicator.Enabled := true;
  AniIndicator.Visible := true;
end;

procedure TFraSelfRegistration.btnLoadProfileClick(Sender: TObject);
var
  Bmp: TJPEGImage;
  BmpConvert: TBitmap;
  DstRct: TRect;
begin
  OpenPictureDialog.Filter := GraphicFilter(TJPEGImage);
  if OpenPictureDialog.Execute(Handle) then
  begin
    Bmp := TJPEGImage.Create;
    fProfileImg := TJPEGImage.Create;
    BmpConvert := TBitmap.Create;
    FreeAndNil(fProfileLoadStream);
    fProfileLoadStream := TMemoryStream.Create;
    try
      Bmp.LoadFromFile(OpenPictureDialog.FileName);
      BmpConvert.SetSize(fProfileImgSize, fProfileImgSize);
      DstRct := Rect(0, 0, fProfileImgSize, fProfileImgSize);
      BmpConvert.Canvas.StretchDraw(DstRct, Bmp);
      fProfileImg.Assign(BmpConvert);
      imgProfile.Picture.Bitmap.Assign(fProfileImg);
      fStorage := fOnGetStorage;
      fProfileImg.SaveToStream(fProfileLoadStream);
      fProfileLoadStream.Position := 0;
      fStorage.UploadFromStream(fProfileLoadStream,
        fStoragePath + '/' + fUser.UID, TRESTContentType.ctIMAGE_JPEG,
        OnProfileImgUpload, OnProfileImgError);
      btnLoadProfile.Enabled := false;
      AniIndicator.Enabled := true;
      AniIndicator.Visible := true;
    finally
      BmpConvert.Free;
      Bmp.Free;
    end;
  end;
end;

procedure TFraSelfRegistration.OnProfileImgUpload(Obj: IStorageObject);
begin
  FreeAndNil(fProfileLoadStream);
  fProfileURL := Obj.DownloadUrl;
  fAuth.ChangeProfile('', '', edtDisplayName.Text, fProfileURL,
    OnChangedProfile, OnUserError);
end;

procedure TFraSelfRegistration.OnProfileDownload(const DownloadURL: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  fProfileURL := DownloadURL;
  fProfileImg := TJPEGImage.Create;
  try
    fProfileImg.LoadFromStream(fProfileLoadStream);
    imgProfile.Picture.Assign(fProfileImg);
  except
    on e: EInvalidGraphic do
    begin
      lblStatus.Caption := Format(rsProfileLoadErr, [e.Message]);
      lblStatus.visible := true;
      exit;
    end;
  end;
  FreeAndNil(fProfileLoadStream);
  if assigned(fOnUserLogin) and
     (not fRegisterDisplayName or not string(edtDisplayName.Text).IsEmpty) then
  begin
    lblStatus.Caption := rsLoggedIn;
    lblStatus.visible := true;
    TThread.CreateAnonymousThread(
      procedure
      begin
        Sleep(100);
        TThread.Queue(nil,
          procedure
          begin
            fOnUserLogin(fInfo, fUser);
          end);
      end).Start;
  end else if fRegisterDisplayName then
    btnRegisterDisplayName.Visible := true;
end;

procedure TFraSelfRegistration.OnProfileImgError(const RequestID,
  ErrMsg: string);
begin
  AniIndicator.Enabled := false;
  AniIndicator.Visible := false;
  lblStatus.Caption := Format(rsProfileLoadErr, [ErrMsg]);
  FreeAndNil(fProfileLoadStream);
end;

procedure TFraSelfRegistration.InformDelayedStart(const Msg: string);
begin
  pnlMFA.Visible := false;
  pnlDisplayName.Visible := false;
  imgProfile.Visible := false;
  AniIndicator.Visible := true;
  AniIndicator.Enabled := true;
  lblStatus.visible := true;
  lblStatus.Caption := Msg;
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('FraSelfRegistration.InformDelayedStart: ' + Msg);
  {$ENDIF}
end;

procedure TFraSelfRegistration.StopDelayedStart;
begin
  AniIndicator.Visible := false;
  AniIndicator.Enabled := false;
  lblStatus.Caption := '';
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('FraSelfRegistration.StopDelayedStart');
  {$ENDIF}
end;

end.
