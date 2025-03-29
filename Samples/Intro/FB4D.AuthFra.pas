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

unit FB4D.AuthFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.IniFiles,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.Objects, FMX.Edit, FMX.ScrollBox, FMX.Memo,
  FMX.TabControl, FMX.Controls.Presentation,
  FB4D.Interfaces;

type
  TAuthFra = class(TFrame)
    Label1: TLabel;
    TabControlUser: TTabControl;
    tabInfo: TTabItem;
    memUser: TMemo;
    btnGetUserData: TButton;
    tabUserProfile: TTabItem;
    edtChangeEMail: TEdit;
    txtEMail: TText;
    edtChangeDisplayName: TEdit;
    Text3: TText;
    btnChange: TButton;
    btnChangeEMail: TButton;
    edtChangePassword: TEdit;
    Text4: TText;
    btnChangePwd: TButton;
    edtChangePhotoURL: TEdit;
    txtPhotoURL: TText;
    btnChangePhotoURL: TButton;
    btnDeleteUserAccount: TButton;
    btnSendEMailVerification: TButton;
    lblTokenExp: TLabel;
    Label6: TLabel;
    Label5: TLabel;
    Label2: TLabel;
    edtUID: TEdit;
    edtToken: TEdit;
    edtPassword: TEdit;
    edtEmail: TEdit;
    btnSignUpNewUser: TButton;
    btnRefresh: TButton;
    btnPasswordReset: TButton;
    btnLogin: TButton;
    btnLinkEMailPwd: TButton;
    timRefresh: TTimer;
    btnLogout: TButton;
    btnGoogleOAuth: TButton;
    edtOAuthRefreshToken: TEdit;
    edtRefreshToken: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    btnReSignInWithGoogleAccount: TButton;
    btnReSignInWithRefreshToken: TButton;
    procedure btnSignUpNewUserClick(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
    procedure btnLinkEMailPwdClick(Sender: TObject);
    procedure btnPasswordResetClick(Sender: TObject);
    procedure btnGetUserDataClick(Sender: TObject);
    procedure btnChangeClick(Sender: TObject);
    procedure btnChangeEMailClick(Sender: TObject);
    procedure btnChangePwdClick(Sender: TObject);
    procedure btnChangePhotoURLClick(Sender: TObject);
    procedure timRefreshTimer(Sender: TObject);
    procedure btnDeleteUserAccountClick(Sender: TObject);
    procedure btnSendEMailVerificationClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure edtEmailAndPwdChange(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure btnGoogleOAuthClick(Sender: TObject);
    procedure btnReSignInWithGoogleAccountClick(Sender: TObject);
    procedure btnReSignInWithRefreshTokenClick(Sender: TObject);
  private
    fAuth: IFirebaseAuthentication;
    procedure Log(const Msg: string);
    function CheckAndCreateAuthenticationClass: boolean;
    function CheckAndCreateAuthForGoogleClass: boolean;
    procedure OnUserResp(const Info: string; Response: IFirebaseResponse);
    procedure OnUserResponse(const Info: string; User: IFirebaseUser);
    procedure OnGetUserData(FirebaseUserList: TFirebaseUserList);
    procedure OnTokenRefresh(TokenRefreshed: boolean);
    procedure OnUserError(const Info, ErrMsg: string);
    procedure DisplayUser(mem: TMemo; User: IFirebaseUser);
    procedure DisplayTokenJWT(mem: TMemo);
  public
    procedure LoadSettingsFromIniFile(IniFile: TIniFile);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
    function CheckSignedIn(Log: TMemo): boolean;
    function CheckTokenExpired: boolean;
    property Auth: IFirebaseAuthentication read fAuth;
  end;

implementation

uses
  System.Generics.Collections, System.JSON,
  FMX.DialogService,
  FB4D.Authentication,
  FB4D.DemoFmx;

{$R *.fmx}

{$REGION 'Class Handling'}

function TAuthFra.CheckAndCreateAuthenticationClass: boolean;
begin
  result := true;
  if not assigned(fAuth) then
  begin
    if fmxFirebaseDemo.edtKey.Text.IsEmpty then
    begin
      Log('Enter Web API Key frist');
      fmxFirebaseDemo.edtKey.SetFocus;
      exit(false);
    end;
    fAuth := TFirebaseAuthentication.Create(fmxFirebaseDemo.edtKey.Text);
    fmxFirebaseDemo.edtKey.ReadOnly := true;
    fmxFirebaseDemo.rctKeyDisabled.Visible := true;
  end;
end;

function TAuthFra.CheckAndCreateAuthForGoogleClass: boolean;
begin
  result := false;
  if not CheckAndCreateAuthenticationClass then
    exit;
  if fmxFirebaseDemo.edtGoogleOAuthClientID.Text.IsEmpty then
  begin
    Log('First enter the OAuth Client ID from the Google Cloud Console!');
    fmxFirebaseDemo.edtGoogleOAuthClientID.SetFocus;
  end
  else if fmxFirebaseDemo.edtGoogleOAuthClientSecret.Text.IsEmpty then
  begin
    Log('First enter the OAuth Client Secret from the Google Cloud Console!');
    fmxFirebaseDemo.edtGoogleOAuthClientSecret.SetFocus;
  end else begin
    fAuth.SetGoogleAuth2(fmxFirebaseDemo.edtGoogleOAuthClientID.Text,
      fmxFirebaseDemo.edtGoogleOAuthClientSecret.Text);
    result := true;
  end;
end;

procedure TAuthFra.Log(const Msg: string);
begin
  memUser.Lines.Add(Msg);
  memUser.GoToTextEnd;
  memUser.GoToLineBegin;
end;

{$ENDREGION}

{$REGION 'Settings'}

procedure TAuthFra.LoadSettingsFromIniFile(IniFile: TIniFile);
begin
  edtEmail.Text := IniFile.ReadString('Authentication', 'User', '');
  edtPassword.Text := IniFile.ReadString('Authentication', 'Pwd', '');
  edtEmailAndPwdChange(nil);
  edtRefreshToken.Text := IniFile.ReadString('Authentication', 'RefreshToken', '');
  btnReSignInWithRefreshToken.Enabled := not edtRefreshToken.Text.IsEmpty;
  edtOAuthRefreshToken.Text := IniFile.ReadString('GoogleOAuth2', 'RefreshToken', '');
  btnReSignInWithRefreshToken.Enabled := not edtOAuthRefreshToken.Text.IsEmpty;
end;

procedure TAuthFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('Authentication', 'User', edtEmail.Text);
  if assigned(fAuth) then
    IniFile.WriteString('Authentication', 'RefreshToken', fAuth.GetRefreshToken);
  if assigned(fAuth) and not fAuth.GetOAuthRefreshToken.IsEmpty then
    IniFile.WriteString('GoogleOAuth2', 'RefreshToken', fAuth.GetOAuthRefreshToken);
  {$MESSAGE 'Attention: Password is stored in your ini file in plain text, but don''t do this in real application. Store the RefreshToken instead of password.'}
  IniFile.WriteString('Authentication', 'Pwd', edtPassword.Text);
end;

{$ENDREGION}

function TAuthFra.CheckSignedIn(Log: TMemo): boolean;
begin
  if assigned(fAuth) and fAuth.Authenticated then
    result := true
  else begin
    Log.Lines.Add('Please sign in first!');
    Log.GoToTextEnd;
    Log.GoToLineBegin;
    result := false;
  end;
end;

function TAuthFra.CheckTokenExpired: boolean;
begin
  result := false;
  if assigned(fAuth) and (edtToken.Text <> fAuth.Token) then
  begin
    lblTokenExp.Text := 'expires at ' + DateTimeToStr(fAuth.TokenExpiryDT);
    edtToken.Text := fAuth.Token;
    Log('Token automatically refreshed ' + fAuth.GetRefreshToken);
    result := true;
  end;
end;

procedure TAuthFra.OnGetUserData(FirebaseUserList: TFirebaseUserList);
var
  User: IFirebaseUser;
begin
  for User in FirebaseUserList do
    DisplayUser(memUser, User);
end;

procedure TAuthFra.OnTokenRefresh(TokenRefreshed: boolean);
begin
  if TokenRefreshed then
  begin
    Log('Token refreshed at ' + DateTimeToStr(now));
    edtToken.Text := fAuth.Token;
    DisplayTokenJWT(memUser);
    lblTokenExp.Text := 'expires at ' + DateTimeToStr(fAuth.TokenExpiryDT);
    Log('Refresh token ' + fAuth.GetRefreshToken);
  end else
    Log('Token refresh failed at ' + DateTimeToStr(now));
end;

procedure TAuthFra.OnUserError(const Info, ErrMsg: string);
begin
  ShowMessage(Info + ' failed: ' + ErrMsg);
  Log(Info + ' failed: ' + ErrMsg);
  if Info.Contains(TFirebaseAuthentication.GoogleProviderID) or
     Info.Equals(TFirebaseAuthentication.Auth2Authenticator) then
    btnGoogleOAuth.Enabled := true;
end;

procedure TAuthFra.OnUserResp(const Info: string; Response: IFirebaseResponse);
begin
  if Response.StatusOk then
    Log(Info + ' done')
  else if not Response.ErrorMsg.IsEmpty then
    Log(Info + ' failed: ' + Response.ErrorMsg)
  else
    Log(Info + ' failed: ' + Response.StatusText);
end;

procedure TAuthFra.OnUserResponse(const Info: string; User: IFirebaseUser);
begin
  DisplayUser(memUser, User);
  if User.IsEMailAvailable and not SameText(edtEmail.Text, User.EMail) then
  begin
    Log('User''s email has changed: ' + User.EMail);
    edtEmail.Text := User.EMail;
  end;
  edtToken.Text := fAuth.Token;
  edtUID.Text := User.UID;
  edtRefreshToken.Text := fAuth.GetRefreshToken;
  btnReSignInWithRefreshToken.Enabled := not edtRefreshToken.Text.IsEmpty;
  lblTokenExp.Text := 'expires at ' + DateTimeToStr(fAuth.TokenExpiryDT);
  if not fAuth.GetOAuthRefreshToken.IsEmpty then
  begin
    edtOAuthRefreshToken.Text := fAuth.GetOAuthRefreshToken;
    btnReSignInWithRefreshToken.Enabled := true;
    Log('OAuth refresh token: ' + fAuth.GetOAuthRefreshToken);
  end;
  btnRefresh.Enabled := fAuth.Authenticated;
  btnPasswordReset.Enabled := not fAuth.Authenticated;
  timRefresh.Enabled := btnRefresh.Enabled;
  btnLogin.Enabled := false;
  btnSignUpNewUser.Enabled := false;
  btnLogout.Enabled := fAuth.Authenticated;
end;

procedure TAuthFra.timRefreshTimer(Sender: TObject);
begin
  if assigned(fAuth) then
  begin
    btnRefresh.Enabled := fAuth.NeedTokenRefresh;
    CheckTokenExpired;
  end;
end;

procedure TAuthFra.edtEmailAndPwdChange(Sender: TObject);
begin
  if edtEmail.Text.IsEmpty then
    btnLogin.Text := 'Anonymous Login'
  else
    btnLogin.Text := 'Login';
  btnPasswordReset.Enabled := not edtEmail.Text.IsEmpty;
  btnLogin.Enabled := not edtEmail.Text.IsEmpty and not edtPassword.Text.IsEmpty;
  btnSignUpNewUser.Enabled := btnLogin.Enabled;
end;

procedure TAuthFra.btnChangeClick(Sender: TObject);
begin
  fAuth.ChangeProfile('', '', edtChangeDisplayName.Text, '', OnUserResp,
    OnUserError);
end;

procedure TAuthFra.btnChangeEMailClick(Sender: TObject);
begin
  fAuth.ChangeProfile(edtChangeEMail.Text, '', '', '', OnUserResp,
    OnUserError);
end;

procedure TAuthFra.btnChangePhotoURLClick(Sender: TObject);
begin
  fAuth.ChangeProfile('', '', '', edtChangePhotoURL.Text, OnUserResp,
    OnUserError);
end;

procedure TAuthFra.btnChangePwdClick(Sender: TObject);
begin
  fAuth.ChangeProfile('', edtChangePassword.Text, '', '', OnUserResp,
    OnUserError);
end;

procedure TAuthFra.btnDeleteUserAccountClick(Sender: TObject);
begin
  TabControlUser.ActiveTab := tabInfo;
  if not CheckAndCreateAuthenticationClass then
    exit;
  if not CheckSignedIn(memUser) then
    exit;
  memUser.Lines.Text := 'Delete User Account:';
  TDialogService.MessageDialog('Do you realy wan''t delete the signed-in user?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbYes, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        edtUID.Text := '';
        edtToken.Text := '';
        fAuth.DeleteCurrentUser(OnUserResp, OnUserError)
      end else
        Log('Delete account canceled by user');
    end);
end;

procedure TAuthFra.btnGetUserDataClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  if not CheckSignedIn(memUser) then
    exit;
  memUser.Lines.Text := 'Get User Data:';
  fAuth.GetUserData(OnGetUserData, OnUserError);
end;

procedure TAuthFra.btnLinkEMailPwdClick(Sender: TObject);
begin
  memUser.Lines.Text := 'Link EMail/Password:';
  fAuth.LinkWithEMailAndPassword(edtEmail.Text, edtPassword.Text,
    OnUserResponse, OnUserError);
  btnLinkEMailPwd.Enabled := false;
  btnLogin.Enabled := true;
end;

procedure TAuthFra.btnLoginClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  if edtEMail.Text.IsEmpty then
  begin
    memUser.Lines.Text := 'Sign-In anonymously:';
    fAuth.SignInAnonymously(OnUserResponse, OnUserError);
    btnLinkEMailPwd.Enabled := true;
    btnSignUpNewUser.Enabled := false;
  end else begin
    memUser.Lines.Text := 'Sign-In with email and password:';
    fAuth.SignInWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
      OnUserResponse, OnUserError);
  end;
end;

procedure TAuthFra.btnReSignInWithRefreshTokenClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  if edtRefreshToken.Text.IsEmpty then
    log('Refresh token is missing')
  else begin
    memUser.Lines.Text := 'Re-Sign-In with refresh token: ' + edtRefreshToken.Text;
    fAuth.RefreshToken(edtRefreshToken.Text, OnTokenRefresh, OnUserError);
  end;
end;

procedure TAuthFra.btnGoogleOAuthClick(Sender: TObject);
begin
  if not CheckAndCreateAuthForGoogleClass then
    exit;
  memUser.Lines.Text := 'Sign-In with Google Account on ' + fAuth.GetOAuthRedirectionEndpoint;
  fAuth.SignInWithGoogleAccount(OnUserResponse, OnUserError, edtEMail.Text);
  btnGoogleOAuth.Enabled := false;
end;

procedure TAuthFra.btnReSignInWithGoogleAccountClick(Sender: TObject);
begin
  if not CheckAndCreateAuthForGoogleClass then
    exit;
  memUser.Lines.Text := 'Re-Sign-In with OAuth refresh token: ' + edtOAuthRefreshToken.Text;
  fAuth.ReSignInWithGoogleAccount(edtOAuthRefreshToken.Text, OnUserResponse, OnUserError);
end;

procedure TAuthFra.btnLogoutClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  fAuth.SignOut;
  edtToken.Text := fAuth.Token;
  edtUID.Text := '';
  btnLogout.Enabled := false;
  btnRefresh.Enabled := false;
  btnPasswordReset.Enabled := true;
  timRefresh.Enabled := false;
  btnLogin.Enabled := true;
  btnSignUpNewUser.Enabled := true;
  btnGoogleOAuth.Enabled := true;
  memUser.Lines.Text := 'Logout';
end;

procedure TAuthFra.btnPasswordResetClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  fAuth.SendPasswordResetEMail(edtEmail.Text, OnUserResp, OnUserError);
end;

procedure TAuthFra.btnRefreshClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  if fAuth.NeedTokenRefresh then
    fAuth.RefreshToken(OnTokenRefresh, onUserError);
end;

procedure TAuthFra.btnSendEMailVerificationClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  fAuth.SendEmailVerification(OnUserResp, OnUserError);
end;

procedure TAuthFra.btnSignUpNewUserClick(Sender: TObject);
begin
  if not CheckAndCreateAuthenticationClass then
    exit;
  memUser.Lines.Text := 'Sign-Up new user:';
  fAuth.SignUpWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
    OnUserResponse, OnUserError);
end;

procedure TAuthFra.DisplayUser(mem: TMemo; User: IFirebaseUser);
var
  c: Integer;
begin
  mem.Lines.Add('UID: ' + User.UID);
  if User.IsNewSignupUser then
    mem.Lines.Add('  User is newly created');
  case User.IsDisabled of
    tsbTrue:
      mem.Lines.Add('  User is disabled');
    tsbFalse:
      mem.Lines.Add('  User is not disabled');
  end;
  if User.IsDisplayNameAvailable then
    mem.Lines.Add('Display name: ' + User.DisplayName);
  if User.IsEMailAvailable then
  begin
    mem.Lines.Add('EMail: ' + User.EMail);
    case User.IsEMailVerified of
      tsbTrue:
        mem.Lines.Add('  EMail is verified');
      tsbFalse:
        mem.Lines.Add('  EMail is not verified');
    end;
  end;
  if User.IsCreatedAtAvailable then
    mem.Lines.Add('User created at: ' + DateTimeToStr(User.CreatedAt));
  if User.IsLastLoginAtAvailable then
    mem.Lines.Add('Last login at: ' + DateTimeToStr(User.LastLoginAt));
  if User.IsPhotoURLAvailable then
    mem.Lines.Add('Photo URL: ' + User.PhotoURL);
  mem.Lines.Add('Refresh token ' + fAuth.GetRefreshToken);
  DisplayTokenJWT(memUser);
  if not edtEMail.Text.IsEmpty then
  begin
    if User.IsDisplayNameAvailable then
      edtChangeDisplayName.Text := User.DisplayName
    else
      edtChangeDisplayName.Text := 'n/a';
    if User.IsEMailAvailable then
      edtChangeEMail.Text := User.EMail
    else
      edtChangeEMail.Text := 'n/a';
    if User.IsPhotoURLAvailable then
      edtChangePhotoURL.Text := User.PhotoURL
    else
      edtChangePhotoURL.Text := '';
  end;
  if User.ProviderCount > 0 then
  begin
    mem.Lines.Add(Format('%d Providers:', [User.ProviderCount]));
    for c := 0 to User.ProviderCount - 1 do
    begin
      mem.Lines.Add(Format('  [%d] Provider Id: %s',
        [c + 1, User.Provider(c).ProviderId]));
      if not User.Provider(c).FederatedId.IsEmpty then
        mem.Lines.Add(Format('  [%d] Federated Id: %s',
          [c + 1, User.Provider(c).FederatedId]));
      if not User.Provider(c).RawId.IsEmpty then
        mem.Lines.Add(Format('  [%d] Raw Id: %s',
          [c + 1, User.Provider(c).RawId]));
      if not User.Provider(c).Email.IsEmpty then
        mem.Lines.Add(Format('  [%d] Email: %s',
          [c + 1, User.Provider(c).Email]));
      if not User.Provider(c).DisplayName.IsEmpty then
        mem.Lines.Add(Format('  [%d] Display Name: %s',
          [c + 1, User.Provider(c).DisplayName]));
      if not User.Provider(c).ScreenName.IsEmpty then
        mem.Lines.Add(Format('  [%d] Screen Name: %s',
          [c + 1, User.Provider(c).ScreenName]));
    end;
  end;
  mem.GoToTextEnd;
  mem.GoToLineBegin;
end;

procedure TAuthFra.DisplayTokenJWT(mem: TMemo);
{$IFDEF TOKENJWT}
var
  c: integer;
begin
  if assigned(fAuth.TokenJWT) then
  begin
    mem.Lines.Add('JWT.Header:');
    for c := 0 to fAuth.TokenJWT.Header.JSON.Count - 1 do
      mem.Lines.Add('  ' +
        fAuth.TokenJWT.Header.JSON.Pairs[c].JsonString.Value + ': ' +
        fAuth.TokenJWT.Header.JSON.Pairs[c].JsonValue.Value);
    mem.Lines.Add('JWT.Claims:');
    for c := 0 to fAuth.TokenJWT.NoOfClaims - 1 do
      mem.Lines.Add('  ' + fAuth.TokenJWT.ClaimName[c] + ': ' +
        fAuth.TokenJWT.ClaimValueAsStr[c]);
    if fAuth.TokenJWT.VerifySignature then
      mem.Lines.Add('Token signatur verified')
    else
      mem.Lines.Add('Token signatur broken');
  end else
    mem.Lines.Add('No JWT Token');
end;
{$ELSE}
begin
  mem.Lines.Add('No JWT Support');
end;
{$ENDIF}

end.
