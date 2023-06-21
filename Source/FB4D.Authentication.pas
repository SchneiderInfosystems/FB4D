{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2023 Christoph Schneider                                 }
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

unit FB4D.Authentication;

interface

uses
  System.Classes, System.SysUtils, System.Types, System.SyncObjs,
  System.JSON, System.JSON.Types,
  System.Net.HttpClient,
  System.Generics.Collections,
  REST.Types,
{$IFDEF TOKENJWT}
  FB4D.OAuth,
{$ENDIF}
  FB4D.Interfaces, FB4D.Response, FB4D.Request;

type
  TFirebaseAuthentication = class(TInterfacedObject, IFirebaseAuthentication)
  private const
    cSafetyMargin = 5 / 3600 / 24; // 5 sec
  private type
    TSignType = (stNewUser, stLogin, stAnonymousLogin);
  private var
    fApiKey: string;
    fCSForToken: TCriticalSection;
    fAuthenticated: boolean;
    fToken: string;
    {$IFDEF TOKENJWT}
    fTokenJWT: ITokenJWT;
    {$ENDIF}
    fExpiresAt: TDateTime;
    fRefreshToken: string;
    fTokenRefreshCount: cardinal;
    fOnTokenRefresh: TOnTokenRefresh;
    fLastUTCServerTime: TDateTime;
    function SignWithEmailAndPasswordSynchronous(SignType: TSignType;
      const Email: string = ''; const Password: string = ''): IFirebaseUser;
    procedure SignWithEmailAndPassword(SignType: TSignType; const Info: string;
      OnUserResponse: TOnUserResponse; OnError: TOnRequestError;
      const Email: string = ''; const Password: string = '');
    procedure OnUserResp(const RequestID: string; Response: IFirebaseResponse);
    procedure OnFetchProvidersResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnDeleteProvidersResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnVerifyPasswordResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnUserListResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure CheckAndRefreshTokenResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure AddPairForTokenId(Data: TJSONObject);
  public
    constructor Create(const ApiKey: string);
    destructor Destroy; override;
    // Create new User with email and password
    procedure SignUpWithEmailAndPassword(const Email,
      Password: string; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    function SignUpWithEmailAndPasswordSynchronous(const Email,
      Password: string): IFirebaseUser;
    // Login
    procedure SignInWithEmailAndPassword(const Email,
      Password: string; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    function SignInWithEmailAndPasswordSynchronous(const Email,
      Password: string): IFirebaseUser;
    procedure SignInAnonymously(OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    function SignInAnonymouslySynchronous: IFirebaseUser;
    // Link new email/password access to anonymous user
    procedure LinkWithEMailAndPassword(const EMail, Password: string;
      OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
    function LinkWithEMailAndPasswordSynchronous(const EMail,
      Password: string): IFirebaseUser;
    // Login by using OAuth from Facebook, Twitter, Google, etc.
    procedure LinkOrSignInWithOAuthCredentials(const OAuthTokenName, OAuthToken,
      ProviderID, RequestUri: string; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    function LinkOrSignInWithOAuthCredentialsSynchronous(const OAuthTokenName,
      OAuthToken, ProviderID, RequestUri: string): IFirebaseUser;
    // Logout
    procedure SignOut;
    // Send EMail for EMail Verification
    procedure SendEmailVerification(OnResponse: TOnFirebaseResp;
      OnError: TOnRequestError);
    procedure SendEmailVerificationSynchronous;
    // Providers
    procedure FetchProvidersForEMail(const EMail: string;
      OnFetchProviders: TOnFetchProviders; OnError: TOnRequestError);
    function FetchProvidersForEMailSynchronous(const EMail: string;
      Providers: TStrings): boolean; // returns true if EMail is registered
    procedure DeleteProviders(Providers: TStrings;
      OnProviderDeleted: TOnFirebaseResp; OnError: TOnRequestError);
    function DeleteProvidersSynchronous(Providers: TStrings): boolean;
    // Reset Password
    procedure SendPasswordResetEMail(const Email: string;
      OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
    procedure SendPasswordResetEMailSynchronous(const Email: string);
    procedure VerifyPasswordResetCode(const ResetPasswortCode: string;
      OnPasswordVerification: TOnPasswordVerification; OnError: TOnRequestError);
    function VerifyPasswordResetCodeSynchronous(const ResetPasswortCode: string):
      TPasswordVerificationResult;
    procedure ConfirmPasswordReset(const ResetPasswortCode, NewPassword: string;
      OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
    procedure ConfirmPasswordResetSynchronous(const ResetPasswortCode,
      NewPassword: string);
    // Change password, Change email, Update Profile Data
    // let field empty which shall not be changed
    procedure ChangeProfile(const EMail, Password, DisplayName,
      PhotoURL: string; OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
    procedure ChangeProfileSynchronous(const EMail, Password, DisplayName,
      PhotoURL: string);
    // Delete signed in user account
    procedure DeleteCurrentUser(OnResponse: TOnFirebaseResp;
      OnError: TOnRequestError);
    procedure DeleteCurrentUserSynchronous;
    // Get User Data
    procedure GetUserData(OnGetUserData: TOnGetUserData;
      OnError: TOnRequestError);
    function GetUserDataSynchronous: TFirebaseUserList;
    // Token refresh
    procedure RefreshToken(OnTokenRefresh: TOnTokenRefresh;
      OnError: TOnRequestError); overload;
    procedure RefreshToken(const LastRefreshToken: string;
      OnTokenRefresh: TOnTokenRefresh; OnError: TOnRequestError); overload;
    function CheckAndRefreshTokenSynchronous(
      IgnoreExpiryCheck: boolean = false): boolean;
    // register call back in all circumstances when the token will be refreshed
    procedure InstallTokenRefreshNotification(OnTokenRefresh: TOnTokenRefresh);
    // Getter methods
    function Authenticated: boolean;
    function Token: string;
    {$IFDEF TOKENJWT}
    function TokenJWT: ITokenJWT;
    {$ENDIF}
    function TokenExpiryDT: TDateTime;
    function NeedTokenRefresh: boolean;
    function GetRefreshToken: string;
    function GetTokenRefreshCount: cardinal;
    function GetLastServerTime(TimeZone: TTimeZone = tzLocalTime): TDateTime;
    property ApiKey: string read fApiKey;
  end;

  TFirebaseUser = class(TInterfacedObject, IFirebaseUser)
  private
    fJSONResp: TJSONObject;
    fToken: string;
    {$IFDEF TOKENJWT}
    fTokenJWT: ITokenJWT;
    fClaimFields: TDictionary<string,TJSONValue>;
    {$ENDIF}
    fExpiresAt: TDateTime;
    fRefreshToken: string;
  public
    constructor Create(JSONResp: TJSONObject; TokenExpected: boolean = true);
      overload;
    {$IFDEF TOKENJWT}
    constructor Create(JSONResp: TJSONObject; TokenJWT: ITokenJWT); overload;
    {$ENDIF}
    destructor Destroy; override;
    // Get User Identification
    function UID: string;
    // Get EMail Address
    function IsEMailAvailable: boolean;
    function IsEMailRegistered: TThreeStateBoolean;
    function IsEMailVerified: TThreeStateBoolean;
    function EMail: string;
    // Get User Display Name
    function IsDisplayNameAvailable: boolean;
    function DisplayName: string;
    // Get Photo URL for User Avatar or Photo
    function IsPhotoURLAvailable: boolean;
    function PhotoURL: string;
    // Get User Account State and Timestamps
    function IsDisabled: TThreeStateBoolean;
    function IsNewSignupUser: boolean;
    function IsLastLoginAtAvailable: boolean;
    function LastLoginAt(TimeZone: TTimeZone = tzLocalTime): TDateTime;
    function IsCreatedAtAvailable: boolean;
    function CreatedAt(TimeZone: TTimeZone = tzLocalTime): TDateTime;
    // Provider User Info
    function ProviderCount: integer;
    function Provider(ProviderNo: integer): TProviderInfo;
    // In case of OAuth sign-in
    function OAuthFederatedId: string;
    function OAuthProviderId: string;
    function OAuthIdToken: string;
    function OAuthAccessToken: string;
    function OAuthTokenSecret: string;
    function OAuthRawUserInfo: string;
    // Get Token Details and Claim Fields
    function Token: string;
    {$IFDEF TOKENJWT}
    function TokenJWT: ITokenJWT;
    function ClaimFieldNames: TStrings;
    function ClaimField(const FieldName: string): TJSONValue;
    {$ENDIF}
    function ExpiresAt: TDateTime; // local time
    function RefreshToken: string;
  end;

implementation

uses
  FB4D.Helpers;

const
 GOOGLE_PASSWORD_URL =
   'https://www.googleapis.com/identitytoolkit/v3/relyingparty';
 GOOGLE_REFRESH_AUTH_URL =
   'https://securetoken.googleapis.com/v1/token';
 GOOGLE_IDTOOLKIT_URL =
   'https://identitytoolkit.googleapis.com/v1';

resourcestring
  rsSignInAnonymously = 'Sign in anonymously';
  rsSignInWithEmail = 'Sign in with email for %s';
  rsSignUpWithEmail = 'Sign up with email for %s';
  rsSignInWithOAuth = 'Sign in with OAuth for %s';
  rsEnableAnonymousLogin = 'In the firebase console under Authentication/' +
    'Sign-in method firstly enable anonymous sign-in provider.';
  rsSendPasswordResetEMail = 'EMail to reset the password sent to %s';
  rsSendVerificationEMail = 'EMail to verify the email sent';
  rsVerifyPasswordResetCode = 'Verify password reset code';
  rsFetchProviders = 'Fetch providers for %s';
  rsDeleteProviders = 'Delete providers %s';
  rsConfirmPasswordReset = 'Confirm password reset';
  rsChangeProfile = 'Change profile for %s';
  rsDeleteCurrentUser = 'Delete signed-in user account';
  rsRetriveUserList = 'Get account info';
  rsRefreshToken = 'Refresh token';

{ TFirebaseAuthentication }

constructor TFirebaseAuthentication.Create(const ApiKey: string);
begin
  inherited Create;
  fApiKey := ApiKey;
  fCSForToken := TCriticalSection.Create;
  fTokenRefreshCount := 1; // begin with 1 and use 0 as sentinel
  fOnTokenRefresh := nil;
  fLastUTCServerTime := 0;
end;

destructor TFirebaseAuthentication.Destroy;
begin
  fCSForToken.Free;
  inherited;
end;

procedure TFirebaseAuthentication.SignInAnonymously(
  OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
begin
  SignWithEmailAndPassword(stAnonymousLogin, rsSignInAnonymously,
    OnUserResponse, OnError);
end;

function TFirebaseAuthentication.SignInAnonymouslySynchronous: IFirebaseUser;
begin
  result := SignWithEmailAndPasswordSynchronous(stAnonymousLogin);
end;

procedure TFirebaseAuthentication.SignInWithEmailAndPassword(const Email,
  Password: string; OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
begin
  SignWithEmailAndPassword(stLogin, Format(rsSignInWithEmail, [EMail]),
    OnUserResponse, OnError, Email, Password);
end;

function TFirebaseAuthentication.SignInWithEmailAndPasswordSynchronous(
  const Email, Password: string): IFirebaseUser;
begin
  result := SignWithEmailAndPasswordSynchronous(stLogin, Email, Password);
end;

procedure TFirebaseAuthentication.AddPairForTokenId(Data: TJSONObject);
begin
  fCSForToken.Acquire;
  try
    if not fToken.IsEmpty then
      Data.AddPair(TJSONPair.Create('idToken', fToken));
  finally
    fCSForToken.Release;
  end;
end;

procedure TFirebaseAuthentication.LinkOrSignInWithOAuthCredentials(
  const OAuthTokenName, OAuthToken, ProviderID, RequestUri: string;
  OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_IDTOOLKIT_URL,
    Format(rsSignInWithOAuth, [ProviderID]));
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('postBody',
      OAuthTokenName + '=' + OAuthToken + '&providerId=' + ProviderID));
    Data.AddPair(TJSONPair.Create('requestUri', requestUri));
    AddPairForTokenId(Data);
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'true'));
    Data.AddPair(TJSONPair.Create('returnIdpCredential', 'true'));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['accounts:signInWithIdp'], rmPost, Data, Params,
      tmNoToken, OnUserResp, OnError, TOnSuccess.CreateUser(OnUserResponse));
  finally
    Params.Free;
    Data.Free;
  end;
end;

function TFirebaseAuthentication.LinkOrSignInWithOAuthCredentialsSynchronous(
  const OAuthTokenName, OAuthToken, ProviderID,
  RequestUri: string): IFirebaseUser;
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
  User: TFirebaseUser;
begin
  result := nil;
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_IDTOOLKIT_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('postBody',
      OAuthTokenName + '=' + OAuthToken + '&providerId=' + ProviderID));
    Data.AddPair(TJSONPair.Create('requestUri', requestUri));
    AddPairForTokenId(Data);
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'true'));
    Data.AddPair(TJSONPair.Create('returnIdpCredential', 'true'));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['accounts:signInWithIdp'],
      rmPost, Data, Params, tmNoToken);
    Response.CheckForJSONObj;
    User := TFirebaseUser.Create(Response.GetContentAsJSONObj);
    fCSForToken.Acquire;
    try
      fAuthenticated := true;
      fToken := User.fToken;
      {$IFDEF TOKENJWT}
      fTokenJWT := User.fTokenJWT;
      {$ENDIF}
      fExpiresAt := User.fExpiresAt;
      fRefreshToken := User.fRefreshToken;
      inc(fTokenRefreshCount);
    finally
      fCSForToken.Release;
    end;
    if assigned(fOnTokenRefresh) then
      fOnTokenRefresh(not fRefreshToken.IsEmpty);
    result := User;
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.SignOut;
begin
  fCSForToken.Acquire;
  try
    fToken := '';
    {$IFDEF TOKENJWT}
    fTokenJWT := nil;
    {$ENDIF}
    fRefreshToken := '';
    fAuthenticated := false;
    inc(fTokenRefreshCount);
  finally
    fCSForToken.Release;
  end;
  if assigned(fOnTokenRefresh) then
    fOnTokenRefresh(false);
end;

procedure TFirebaseAuthentication.SendEmailVerification(OnResponse: TOnFirebaseResp;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    rsSendVerificationEMail);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('requestType', 'VERIFY_EMAIL'));
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['getOobConfirmationCode'], rmPost, Data, Params,
      tmNoToken, OnResponse, OnError, TOnSuccess.Create(nil));
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.SendEmailVerificationSynchronous;
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('requestType', 'VERIFY_EMAIL'));
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['getOobConfirmationCode'],
      rmPost, Data, Params, tmNoToken);
    if not Response.StatusOk then
      Response.CheckForJSONObj;
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.SignUpWithEmailAndPassword(const Email,
  Password: string; OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
begin
  SignWithEmailAndPassword(stNewUser, Format(rsSignUpWithEmail, [EMail]),
    OnUserResponse, OnError, Email, Password);
end;

function TFirebaseAuthentication.SignUpWithEmailAndPasswordSynchronous(
  const Email, Password: string): IFirebaseUser;
begin
  result := SignWithEmailAndPasswordSynchronous(stNewUser, Email, Password);
end;

procedure TFirebaseAuthentication.OnUserResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  User: IFirebaseUser;
  ErrMsg: string;
begin
  try
    Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    User := TFirebaseUser.Create(Response.GetContentAsJSONObj);
    fCSForToken.Acquire;
    try
      fAuthenticated := true;
      if fToken <> User.Token then
      begin
        fToken := User.Token;
        {$IFDEF TOKENJWT}
        fTokenJWT := User.TokenJWT;
        {$ENDIF}
        inc(fTokenRefreshCount);
      end;
      fExpiresAt := User.ExpiresAt;
      fRefreshToken := User.RefreshToken;
    finally
      fCSForToken.Release;
    end;
    if assigned(Response.OnSuccess.OnUserResponse) then
      Response.OnSuccess.OnUserResponse(RequestID, User);
    if assigned(fOnTokenRefresh) then
      fOnTokenRefresh(not fRefreshToken.IsEmpty);
  except
    on e: EFirebaseResponse do
    begin
      if sameText(e.Message, TFirebaseResponse.ExceptOpNotAllowed) and
        (RequestID = rsSignInAnonymously) then
        ErrMsg := rsEnableAnonymousLogin
      else
        ErrMsg := e.Message;
      if assigned(Response.OnError) then
        Response.OnError(RequestID, ErrMsg)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirebaseAuthentication.OnUserResp', RequestID, ErrMsg]);
    end;
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirebaseAuthentication.OnUserResp', RequestID, e.Message]);
    end;
  end;
end;

procedure TFirebaseAuthentication.SignWithEmailAndPassword(SignType: TSignType;
  const Info: string; OnUserResponse: TOnUserResponse; OnError: TOnRequestError;
  const Email, Password: string);
const
  ResourceStr: array  [TSignType] of string =
    ('signupNewUser', 'verifyPassword', 'signupNewUser');
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL, Info);
  Params := TQueryParams.Create;
  try
    if SignType < stAnonymousLogin then
    begin
      Data.AddPair(TJSONPair.Create('email', Email));
      Data.AddPair(TJSONPair.Create('password', Password));
    end;
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'true'));
    Params.Add('key', [ApiKey]);
    Request.SendRequest([ResourceStr[SignType]], rmPost, Data, Params,
      tmNoToken, OnUserResp, OnError, TOnSuccess.CreateUser(OnUserResponse));
  finally
    Params.Free;
    Data.Free;
  end;
end;

function TFirebaseAuthentication.SignWithEmailAndPasswordSynchronous(
  SignType: TSignType; const Email, Password: string): IFirebaseUser;
const
  ResourceStr: array  [TSignType] of string =
    ('signupNewUser', 'verifyPassword', 'signupNewUser');
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
  User: TFirebaseUser;
begin
  result := nil;
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    if SignType < stAnonymousLogin then
    begin
      Data.AddPair(TJSONPair.Create('email', Email));
      Data.AddPair(TJSONPair.Create('password', Password));
    end;
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'true'));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous([ResourceStr[SignType]], rmPost,
      Data, Params, tmNoToken);
    Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    User := TFirebaseUser.Create(Response.GetContentAsJSONObj);
    fCSForToken.Acquire;
    try
      fAuthenticated := true;
      if fToken <> User.fToken then
      begin
        fToken := User.fToken;
        {$IFDEF TOKENJWT}
        fTokenJWT := User.fTokenJWT;
        {$ENDIF}
        inc(fTokenRefreshCount);
      end;
      fExpiresAt := User.fExpiresAt;
      fRefreshToken := User.fRefreshToken;
    finally
      fCSForToken.Release;
    end;
    if assigned(fOnTokenRefresh) then
      fOnTokenRefresh(not fRefreshToken.IsEmpty);
    result := User;
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.FetchProvidersForEMail(const EMail: string;
  OnFetchProviders: TOnFetchProviders; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    Format(rsFetchProviders, [EMail]));
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('identifier', Email));
    Data.AddPair(TJSONPair.Create('continueUri', 'http://locahost'));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['createAuthUri'], rmPOST, Data, Params, tmNoToken,
      OnFetchProvidersResp, onError,
      TOnSuccess.CreateFetchProviders(OnFetchProviders));
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.OnFetchProvidersResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  ResObj: TJSONObject;
  ResArr: TJSONArray;
  c: integer;
  Registered: boolean;
  Providers: TStringList;
begin
  try
    Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    ResObj := Response.GetContentAsJSONObj;
    Providers := TStringList.Create;
    try
      if not ResObj.GetValue('registered').TryGetValue(Registered) then
        raise EFirebaseAuthentication.Create('JSON field registered missing');
      if Registered then
      begin
        ResArr := ResObj.GetValue('allProviders') as TJSONArray;
        if not assigned(ResArr) then
          raise EFirebaseAuthentication.Create(
            'JSON field allProviders missing');
        for c := 0 to ResArr.Count - 1 do
          Providers.Add(ResArr.Items[c].ToString);
      end;
      if assigned(Response.OnSuccess.OnFetchProviders) then
        Response.OnSuccess.OnFetchProviders(RequestID, Registered, Providers);
    finally
      Providers.Free;
      ResObj.Free;
    end;
  except
    on e: exception do
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message);
  end;
end;

function TFirebaseAuthentication.FetchProvidersForEMailSynchronous(
  const EMail: string; Providers: TStrings): boolean;
var
  Data, ResObj: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  ResArr: TJSONArray;
  c: integer;
begin
  Data := TJSONObject.Create;
  ResObj := nil;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('identifier', Email));
    Data.AddPair(TJSONPair.Create('continueUri', 'http://locahost'));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['createAuthUri'], rmPOST, Data,
      Params, tmNoToken);
    Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    ResObj := Response.GetContentAsJSONObj;
    if not ResObj.GetValue('registered').TryGetValue(result) then
      raise EFirebaseAuthentication.Create('JSON field registered missing');
    if result then
    begin
      ResArr := ResObj.GetValue('allProviders') as TJSONArray;
      if not assigned(ResArr) then
        raise EFirebaseAuthentication.Create('JSON field allProviders missing');
      Providers.Clear;
      for c := 0 to ResArr.Count - 1 do
        Providers.Add(ResArr.Items[c].ToString);
    end;
  finally
    ResObj.Free;
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.DeleteProviders(Providers: TStrings;
  OnProviderDeleted: TOnFirebaseResp; OnError: TOnRequestError);
var
  Data: TJSONObject;
  DelArr: TJSONArray;
  Provider: string;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_IDTOOLKIT_URL,
    Format(rsDeleteProviders, [Providers.CommaText]));
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    DelArr := TJSONArray.Create;
    for Provider in Providers do
      DelArr.Add(Provider);
    Data.AddPair(TJSONPair.Create('deleteProvider', DelArr));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['accounts:update'], rmPOST, Data, Params, tmNoToken,
      OnDeleteProvidersResp, onError, TOnSuccess.Create(OnProviderDeleted));
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.OnDeleteProvidersResp(const RequestID: string;
  Response: IFirebaseResponse);
begin
  try
    if Response.StatusOk then
    begin
      Response.CheckForJSONObj;
      fLastUTCServerTime := Response.GetServerTime(tzUTC);
      if assigned(Response.OnSuccess.OnResponse) then
        Response.OnSuccess.OnResponse(RequestID, Response);
    end;
  except
    on e: exception do
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message);
  end;
end;

function TFirebaseAuthentication.DeleteProvidersSynchronous(
  Providers: TStrings): boolean;
var
  Data: TJSONObject;
  DelArr: TJSONArray;
  Provider: string;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
begin
  result := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_IDTOOLKIT_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    DelArr := TJSONArray.Create;
    for Provider in Providers do
      DelArr.Add(Provider);
    Data.AddPair(TJSONPair.Create('deleteProvider', DelArr));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['accounts:update'], rmPost, Data,
      Params, tmNoToken);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log('FirebaseAuthentication.DeleteProvidersSynchronous ' +
      Response.ContentAsString);
    {$ENDIF}
    if Response.StatusOk then
    begin
      Response.CheckForJSONObj;
      fLastUTCServerTime := Response.GetServerTime(tzUTC);
      result := true;
    end;
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.SendPasswordResetEMail(const Email: string;
  OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    Format(rsSendPasswordResetEMail, [EMail]));
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('email', Email));
    Data.AddPair(TJSONPair.Create('requestType', 'PASSWORD_RESET'));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['getOobConfirmationCode'], rmPost, Data, Params,
      tmNoToken, OnResponse, OnError, TOnSuccess.Create(nil));
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.SendPasswordResetEMailSynchronous(
  const Email: string);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('email', Email));
    Data.AddPair(TJSONPair.Create('requestType', 'PASSWORD_RESET'));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['getOobConfirmationCode'],
      rmPost, Data, Params, tmNoToken);
    if not Response.StatusOk then
      Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.VerifyPasswordResetCode(
  const ResetPasswortCode: string;
  OnPasswordVerification: TOnPasswordVerification; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    rsVerifyPasswordResetCode);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('oobCode', ResetPasswortCode));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['resetPassword'], rmPost,
      Data, Params, tmNoToken, OnVerifyPasswordResp, OnError,
      TOnSuccess.CreatePasswordVerification(OnPasswordVerification));
  finally
    Data.Free;
  end;
end;

function TFirebaseAuthentication.VerifyPasswordResetCodeSynchronous(
  const ResetPasswortCode: string): TPasswordVerificationResult;
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('oobCode', ResetPasswortCode));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['resetPassword'], rmPost, Data,
      Params, tmNoToken);
    if Response.StatusOk then
      result := pvrPassed
    else if SameText(Response.ErrorMsg,
      TFirebaseResponse.ExceptOpNotAllowed) then
      result := pvrOpNotAllowed
    else if SameText(Response.ErrorMsg,
      TFirebaseResponse.ExceptExpiredOobCode) then
      result := pvrpvrExpired
    else if SameText(Response.ErrorMsg,
      TFirebaseResponse.ExceptInvalidOobCode) then
      result := pvrInvalid
    else
      raise EFirebaseResponse.Create(Response.ErrorMsg);
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.OnVerifyPasswordResp(const RequestID: string;
  Response: IFirebaseResponse);
begin
  if assigned(Response.OnSuccess.OnPasswordVerification) then
  begin
    if Response.StatusOk then
      Response.OnSuccess.OnPasswordVerification(RequestID, pvrPassed)
    else if SameText(Response.ErrorMsg, TFirebaseResponse.ExceptOpNotAllowed) then
      Response.OnSuccess.OnPasswordVerification(RequestID, pvrOpNotAllowed)
    else if SameText(Response.ErrorMsg, TFirebaseResponse.ExceptExpiredOobCode) then
      Response.OnSuccess.OnPasswordVerification(RequestID, pvrpvrExpired)
    else if SameText(Response.ErrorMsg, TFirebaseResponse.ExceptInvalidOobCode) then
      Response.OnSuccess.OnPasswordVerification(RequestID, pvrInvalid)
    else if assigned(Response.OnError) then
      Response.OnError(RequestID, Response.ErrorMsg)
    else
      TFirebaseHelpers.Log('FirebaseAuthentication.OnVerifyPassword failed: ' +
        Response.ErrorMsg);
  end;
end;

procedure TFirebaseAuthentication.ConfirmPasswordReset(const ResetPasswortCode,
  NewPassword: string; OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    rsConfirmPasswordReset);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('oobCode', ResetPasswortCode));
    Data.AddPair(TJSONPair.Create('newPassword', NewPassword));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['resetPassword'], rmPost, Data,
      Params, tmNoToken, OnResponse, OnError, TOnSuccess.Create(nil));
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.ConfirmPasswordResetSynchronous(
  const ResetPasswortCode, NewPassword: string);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('oobCode', ResetPasswortCode));
    Data.AddPair(TJSONPair.Create('newPassword', NewPassword));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['resetPassword'], rmPost, Data,
      Params, tmNoToken);
    if not Response.StatusOk then
      Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.ChangeProfile(const EMail, Password,
  DisplayName, PhotoURL: string; OnResponse: TOnFirebaseResp;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
  Info: TStringList;
begin
  Data := TJSONObject.Create;
  Params := TQueryParams.Create;
  Info := TStringList.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'FALSE'));
    if not EMail.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('email', EMail));
      Info.Add('EMail');
    end;
    if not Password.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('password', Password));
      Info.Add('Password');
    end;
    if not DisplayName.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('displayName', DisplayName));
      Info.Add('Display name');
    end;
    if not PhotoURL.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('photoUrl', PhotoURL));
      Info.Add('Photo URL');
    end;
    Params.Add('key', [ApiKey]);
    Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
      Format(rsChangeProfile, [Info.CommaText]));
    Request.SendRequest(['setAccountInfo'], rmPost, Data, Params, tmNoToken,
      OnResponse, OnError, TOnSuccess.Create(nil));
  finally
    Info.Free;
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.ChangeProfileSynchronous(const EMail,
  Password, DisplayName, PhotoURL: string);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
  Info: TStringList;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  Info := TStringList.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'FALSE'));
    if not EMail.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('email', EMail));
      Info.Add('EMail');
    end;
    if not Password.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('password', Password));
      Info.Add('Password');
    end;
    if not DisplayName.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('displayName', DisplayName));
      Info.Add('Display name');
    end;
    if not PhotoURL.IsEmpty then
    begin
      Data.AddPair(TJSONPair.Create('photoUrl', PhotoURL));
      Info.Add('Photo URL');
    end;
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['setAccountInfo'], rmPost, Data,
      Params, tmNoToken);
    if not Response.StatusOk then
      Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log('FirebaseAuthentication.ChangeProfileSynchronous ' +
      Info.CommaText);
    {$ENDIF}
  finally
    Info.Free;
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.LinkWithEMailAndPassword(const EMail,
  Password: string; OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_IDTOOLKIT_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'TRUE'));
    Data.AddPair(TJSONPair.Create('email', EMail));
    Data.AddPair(TJSONPair.Create('password', Password));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['accounts:update'], rmPost, Data, Params, tmNoToken,
      OnUserResp, OnError, TOnSuccess.CreateUser(OnUserResponse));
  finally
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

function TFirebaseAuthentication.LinkWithEMailAndPasswordSynchronous(
  const EMail, Password: string): IFirebaseUser;
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_IDTOOLKIT_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'TRUE'));
    Data.AddPair(TJSONPair.Create('email', EMail));
    Data.AddPair(TJSONPair.Create('password', Password));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['accounts:update'],
      rmPost, Data, Params, tmNoToken);
    Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    result := TFirebaseUser.Create(Response.GetContentAsJSONObj);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log(
      'FirebaseAuthentication.LinkWithEMailAndPasswordSynchronous' +
      Response.ContentAsString);
    {$ENDIF}
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.DeleteCurrentUserSynchronous;
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['deleteAccount'], rmPost, Data,
      Params, tmNoToken);
    if not Response.StatusOk then
      Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log('FirebaseAuthentication.DeleteCurrentUserSynchronous ' +
      Response.ContentAsString);
    {$ENDIF}
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.DeleteCurrentUser(OnResponse: TOnFirebaseResp;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Params.Add('key', [ApiKey]);
    Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL, rsDeleteCurrentUser);
    Request.SendRequest(['deleteAccount'], rmPost, Data, Params, tmNoToken,
      OnResponse, OnError, TOnSuccess.Create(nil));
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.GetUserData(OnGetUserData: TOnGetUserData;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL, rsRetriveUserList);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Params.Add('key', [ApiKey]);
    Request.SendRequest(['getAccountInfo'], rmPost, Data, Params, tmNoToken,
      OnUserListResp, OnError, TOnSuccess.CreateGetUserData(OnGetUserData));
  finally
    Params.Free;
    Data.Free;
  end;
end;

function TFirebaseAuthentication.GetUserDataSynchronous: TFirebaseUserList;
var
  Data, UsersObj: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
  Users: TJSONArray;
  c: integer;
begin
  result := TFirebaseUserList.Create;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', Token));
    Params.Add('key', [ApiKey]);
    Response := Request.SendRequestSynchronous(['getAccountInfo'], rmPost, Data,
      Params, tmNoToken);
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    if not Response.StatusOk then
      Response.CheckForJSONObj
    else begin
      UsersObj := Response.GetContentAsJSONObj;
      try
        if not UsersObj.TryGetValue('users', Users) then
          raise EFirebaseResponse.Create(
            'users field not found in getAccountInfo');
        for c := 0 to Users.Count - 1 do
          {$IFDEF TOKENJWT}
          if fTokenJWT <> nil then
            result.Add(TFirebaseUser.Create(
              Users.Items[c].Clone as TJSONObject, fTokenJWT))
          else
          {$ENDIF}
            result.Add(TFirebaseUser.Create(
              Users.Items[c].Clone as TJSONObject, false));
      finally
        UsersObj.Free;
      end;
    end;
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.OnUserListResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  UsersObj: TJSONObject;
  UserList: TFirebaseUserList;
  Users: TJSONArray;
  c: integer;
begin
  try
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    if not Response.StatusOk then
      Response.CheckForJSONObj
    else if assigned(Response.OnSuccess.OnGetUserData) then
    begin
      UserList := TFirebaseUserList.Create;
      UsersObj := Response.GetContentAsJSONObj;
      try
        if not UsersObj.TryGetValue('users', Users) then
          raise EFirebaseResponse.Create(
            'users field not found in getAccountInfo');
        for c := 0 to Users.Count - 1 do
          {$IFDEF TOKENJWT}
          if fTokenJWT <> nil then
            UserList.Add(TFirebaseUser.Create(
              Users.Items[c].Clone as TJSONObject, fTokenJWT))
          else
          {$ENDIF}
            UserList.Add(TFirebaseUser.Create(
              Users.Items[c].Clone as TJSONObject, false));
        Response.OnSuccess.OnGetUserData(UserList);
      finally
        UsersObj.Free;
        UserList.Free;
      end;
    end;
  except
    on e: exception do
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log('FirebaseAuthentication.OnUserList failed: ' +
          e.Message);
  end;
end;

procedure TFirebaseAuthentication.RefreshToken(OnTokenRefresh: TOnTokenRefresh;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_REFRESH_AUTH_URL, rsRefreshToken);
  Params := TQueryParams.Create;
  try
    Data.AddPair(TJSONPair.Create('grant_type', 'refresh_token'));
    Data.AddPair(TJSONPair.Create('refresh_token', fRefreshToken));
    Params.Add('key', [ApiKey]);
    Request.SendRequest([], rmPost, Data, Params, tmNoToken,
      CheckAndRefreshTokenResp, OnError,
      TOnSuccess.CreateRefreshToken(OnTokenRefresh));
  finally
    Params.Free;
    Data.Free;
  end;
  if assigned(fOnTokenRefresh) then
    fOnTokenRefresh(not fRefreshToken.IsEmpty);
end;

procedure TFirebaseAuthentication.RefreshToken(const LastRefreshToken: string;
  OnTokenRefresh: TOnTokenRefresh; OnError: TOnRequestError);
begin
  fRefreshToken := LastRefreshToken;
  RefreshToken(OnTokenRefresh, OnError);
end;

procedure TFirebaseAuthentication.InstallTokenRefreshNotification(
  OnTokenRefresh: TOnTokenRefresh);
begin
  fOnTokenRefresh := OnTokenRefresh;
end;

procedure TFirebaseAuthentication.CheckAndRefreshTokenResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  NewToken: TJSONObject;
  ExpiresInSec: integer;
begin
  try
    Response.CheckForJSONObj;
    fLastUTCServerTime := Response.GetServerTime(tzUTC);
    NewToken := Response.GetContentAsJSONObj;
    fCSForToken.Acquire;
    try
      fAuthenticated := true;
      if not NewToken.TryGetValue('access_token', fToken) then
        raise EFirebaseUser.Create('access_token not found');
      {$IFDEF TOKENJWT}
      fTokenJWT := TTokenJWT.Create(fToken);
      {$ENDIF}
      inc(fTokenRefreshCount);
      if NewToken.TryGetValue('expires_in', ExpiresInSec) then
        fExpiresAt := now + ExpiresInSec / 24 / 3600
      else
        fExpiresAt := now;
      if not NewToken.TryGetValue('refresh_token', fRefreshToken) then
        fRefreshToken := ''
      else if assigned(Response.OnSuccess.OnRefreshToken) then
        Response.OnSuccess.OnRefreshToken(true);
    finally
      fCSForToken.Release;
      NewToken.Free;
    end;
    if assigned(fOnTokenRefresh) then
      fOnTokenRefresh(not fRefreshToken.IsEmpty);
  except
    on e: exception do
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(
          'FirebaseAuthentication.CheckAndRefreshToken failed: ' + e.Message);
  end;
end;

function TFirebaseAuthentication.CheckAndRefreshTokenSynchronous(
  IgnoreExpiryCheck: boolean = false): boolean;
var
  Data: TJSONObject;
  Params: TQueryParams;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
  NewToken: TJSONObject;
  ExpiresInSec: integer;
begin
  if not NeedTokenRefresh then
  begin
    {$IFDEF DEBUG}
    TFirebaseHelpers.LogFmt(
      'FirebaseAuthentication.CheckAndRefreshTokenSynchronous failed because ' +
      'token not yet (%s) expired: %s', [TimeToStr(now), TimeToStr(fExpiresAt)]);
    {$ENDIF}
    if not IgnoreExpiryCheck then
      exit(false);
  end;
  result := false;
  fCSForToken.Acquire;
  try
    if now + cSafetyMargin < fExpiresAt then
      exit(false); // Another thread has refreshed the token
    fAuthenticated := false;
    Data := TJSONObject.Create;
    Request := TFirebaseRequest.Create(GOOGLE_REFRESH_AUTH_URL, '');
    Params := TQueryParams.Create;
    try
      Data.AddPair(TJSONPair.Create('grant_type', 'refresh_token'));
      Data.AddPair(TJSONPair.Create('refresh_token', fRefreshToken));
      Params.Add('key', [ApiKey]);
      Response := Request.SendRequestSynchronous([], rmPost, Data, Params,
        tmNoToken);
      Response.CheckForJSONObj;
      fLastUTCServerTime := Response.GetServerTime(tzUTC);
      NewToken := Response.GetContentAsJSONObj;
      try
        fAuthenticated := true;
        if not NewToken.TryGetValue('access_token', fToken) then
          raise EFirebaseAuthentication.Create('access_token not found');
        {$IFDEF TOKENJWT}
        fTokenJWT := TTokenJWT.Create(fToken);
        {$ENDIF}
        inc(fTokenRefreshCount);
        if NewToken.TryGetValue('expires_in', ExpiresInSec) then
          fExpiresAt := now + ExpiresInSec / 24 / 3600
        else
          fExpiresAt := now;
        if not NewToken.TryGetValue('refresh_token', fRefreshToken) then
          fRefreshToken := ''
        else
          result := true;
      finally
        NewToken.Free;
      end;
    finally
      Response := nil;
      Params.Free;
      Request.Free;
      Data.Free;
    end;
    {$IFDEF DEBUG}
    if result then
      TFirebaseHelpers.Log(
        'FirebaseAuthentication.CheckAndRefreshTokenSynchronous done')
    else
      TFirebaseHelpers.Log(
        'FirebaseAuthentication.CheckAndRefreshTokenSynchronous failed ' +
        'because no token received');
    {$ENDIF}
  finally
    fCSForToken.Release;
    if result and assigned(fOnTokenRefresh) then
      fOnTokenRefresh(not fRefreshToken.IsEmpty);
  end;
end;

function TFirebaseAuthentication.Authenticated: boolean;
begin
  fCSForToken.Acquire;
  try
    result := fAuthenticated;
  finally
    fCSForToken.Release;
  end;
end;

function TFirebaseAuthentication.NeedTokenRefresh: boolean;
begin
  fCSForToken.Acquire;
  try
    if fAuthenticated then
      result := now + cSafetyMargin > fExpiresAt
    else
      result := false;
  finally
    fCSForToken.Release;
  end;
end;

function TFirebaseAuthentication.GetTokenRefreshCount: cardinal;
begin
  result := fTokenRefreshCount;
end;

function TFirebaseAuthentication.GetRefreshToken: string;
begin
  fCSForToken.Acquire;
  try
    result := fRefreshToken;
  finally
    fCSForToken.Release;
  end;
end;

function TFirebaseAuthentication.GetLastServerTime(
  TimeZone: TTimeZone): TDateTime;
begin
  result := fLastUTCServerTime;
  if TimeZone = tzLocalTime then
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

function TFirebaseAuthentication.Token: string;
begin
  fCSForToken.Acquire;
  try
    result := fToken;
  finally
    fCSForToken.Release;
  end;
end;

function TFirebaseAuthentication.TokenExpiryDT: TDateTime;
begin
  fCSForToken.Acquire;
  try
    result := fExpiresAt;
  finally
    fCSForToken.Release;
  end;
end;

{$IFDEF TOKENJWT}
function TFirebaseAuthentication.TokenJWT: ITokenJWT;
begin
  fCSForToken.Acquire;
  try
    result := fTokenJWT;
  finally
    fCSForToken.Release;
  end;
end;
{$ENDIF}

{ TFirebaseUser }

constructor TFirebaseUser.Create(JSONResp: TJSONObject; TokenExpected: boolean);
var
  ExpiresInSec: integer;
  {$IFDEF TOKENJWT}
  Claims: TJSONObject;
  c: integer;
  {$ENDIF}
begin
  inherited Create;
  {$IFDEF TOKENJWT}
  fTokenJWT := nil;
  fClaimFields := TDictionary<string,TJSONValue>.Create;
  {$ENDIF}
  fJSONResp := JSONResp;
  if not fJSONResp.TryGetValue('idToken', fToken) then
    if TokenExpected then
      raise EFirebaseUser.Create('idToken not found')
    else
      fToken := ''
  else begin
    {$IFDEF TOKENJWT}
    fTokenJWT := TTokenJWT.Create(fToken);
    Claims := fTokenJWT.Claims.JSON;
    for c := 0 to Claims.Count - 1 do
      fClaimFields.Add(Claims.Pairs[c].JsonString.Value,
        Claims.Pairs[c].JsonValue);
    {$ENDIF}
  end;
  if fJSONResp.TryGetValue('expiresIn', ExpiresInSec) then
    fExpiresAt := now + ExpiresInSec / 24 / 3600
  else
    fExpiresAt := now;
  if not fJSONResp.TryGetValue('refreshToken', fRefreshToken) then
    fRefreshToken := '';
end;

{$IFDEF TOKENJWT}
constructor TFirebaseUser.Create(JSONResp: TJSONObject; TokenJWT: ITokenJWT);
var
  ExpiresInSec: integer;
  Claims: TJSONObject;
  c: integer;
begin
  inherited Create;
  fTokenJWT := TokenJWT;
  fClaimFields := TDictionary<string,TJSONValue>.Create;
  fJSONResp := JSONResp;
  Claims := fTokenJWT.Claims.JSON;
  for c := 0 to Claims.Count - 1 do
    fClaimFields.Add(Claims.Pairs[c].JsonString.Value,
      Claims.Pairs[c].JsonValue);
  if fJSONResp.TryGetValue('expiresIn', ExpiresInSec) then
    fExpiresAt := now + ExpiresInSec / 24 / 3600
  else
    fExpiresAt := now;
  if not fJSONResp.TryGetValue('refreshToken', fRefreshToken) then
    fRefreshToken := '';
end;
{$ENDIF}

destructor TFirebaseUser.Destroy;
begin
  {$IFDEF TOKENJWT}
  fClaimFields.Free;
  fTokenJWT := nil;
  {$ENDIF}
  fJSONResp.Free;
  inherited;
end;

function TFirebaseUser.IsDisabled: TThreeStateBoolean;
var
  bool: boolean;
begin
  if not fJSONResp.TryGetValue('disabled', bool) then
    result := tsbUnspecified
  else if bool then
    result := tsbTrue
  else
    result := tsbFalse;
end;

function TFirebaseUser.IsDisplayNameAvailable: boolean;
begin
  result := fJSONResp.GetValue('displayName') <> nil;
end;

function TFirebaseUser.DisplayName: string;
begin
  if not fJSONResp.TryGetValue('displayName', result) then
    raise EFirebaseUser.Create('displayName not found');
end;

function TFirebaseUser.IsEMailAvailable: boolean;
begin
  result := fJSONResp.GetValue('email') <> nil;
end;

function TFirebaseUser.EMail: string;
begin
  if not fJSONResp.TryGetValue('email', result) then
    raise EFirebaseUser.Create('email not found');
end;

function TFirebaseUser.ExpiresAt: TDateTime;
begin
  result := fExpiresAt;
end;

function TFirebaseUser.UID: string;
begin
  if not fJSONResp.TryGetValue('localId', result) then
    raise EFirebaseUser.Create('localId not found');
end;

function TFirebaseUser.IsEMailRegistered: TThreeStateBoolean;
var
  bool: boolean;
begin
  if not fJSONResp.TryGetValue('registered', bool) then
    result := tsbUnspecified
  else if bool then
    result := tsbTrue
  else
    result := tsbFalse;
end;

function TFirebaseUser.IsEMailVerified: TThreeStateBoolean;
var
  {$IFDEF TOKENJWT}
  Val: TJSONValue;
  {$ENDIF}
  bool: boolean;
begin
  {$IFDEF TOKENJWT}
  if fClaimFields.TryGetValue('email_verified', Val) then
  begin
    if Val.GetValue<boolean> then
      exit(tsbTrue)
    else
      exit(tsbFalse);
  end;
  {$ENDIF}
  if not fJSONResp.TryGetValue('emailVerified', bool) then
    result := tsbUnspecified
  else if bool then
    result := tsbTrue
  else
    result := tsbFalse;
end;

function TFirebaseUser.IsCreatedAtAvailable: boolean;
begin
  result := fJSONResp.GetValue('createdAt') <> nil;
end;

function TFirebaseUser.CreatedAt(TimeZone: TTimeZone): TDateTime;
var
  dt: Int64;
begin
  if not fJSONResp.TryGetValue('createdAt', dt) then
    raise EFirebaseUser.Create('createdAt not found');
  case TimeZone of
    tzLocalTime:
      result := TFirebaseHelpers.ConvertTimeStampToLocalDateTime(dt);
    tzUTC:
      result := TFirebaseHelpers.ConvertTimeStampToUTCDateTime(dt);
    else
      raise EFirebaseUser.Create('Invalid timezone');
  end;
end;

function TFirebaseUser.IsLastLoginAtAvailable: boolean;
begin
  result := fJSONResp.GetValue('lastLoginAt') <> nil;
end;

function TFirebaseUser.IsNewSignupUser: boolean;
const
  cSignupNewUser = '#SignupNewUserResponse';
var
  kind: string;
begin
  result := false;
  if fJSONResp.TryGetValue('kind', kind) then
    result := String.EndsText(cSignupNewUser, Kind);
end;

function TFirebaseUser.LastLoginAt(TimeZone: TTimeZone): TDateTime;
var
  dt: Int64;
begin
  if not fJSONResp.TryGetValue('lastLoginAt', dt) then
    raise EFirebaseUser.Create('lastLoginAt not found');
  case TimeZone of
    tzLocalTime:
      result := TFirebaseHelpers.ConvertTimeStampToLocalDateTime(dt);
    tzUTC:
      result := TFirebaseHelpers.ConvertTimeStampToUTCDateTime(dt);
    else
      raise EFirebaseUser.Create('Invalid timezone');
  end;
end;

function TFirebaseUser.IsPhotoURLAvailable: boolean;
begin
  result := fJSONResp.GetValue('photoUrl') <> nil;
end;

function TFirebaseUser.PhotoURL: string;
begin
  if not fJSONResp.TryGetValue('photoUrl', result) then
    raise EFirebaseUser.Create('photoURL not found');
end;

function TFirebaseUser.RefreshToken: string;
begin
  result := fRefreshToken;
end;

function TFirebaseUser.Token: string;
begin
  result := fToken;
end;

function TFirebaseUser.OAuthProviderId: string;
begin
  if not fJSONResp.TryGetValue('providerId', result) then
    result := '';
end;

function TFirebaseUser.OAuthFederatedId: string;
begin
  if not fJSONResp.TryGetValue('federatedId', result) then
    result := '';
end;

function TFirebaseUser.OAuthIdToken: string;
begin
  if not fJSONResp.TryGetValue('oauthIdToken', result) then
    result := '';
end;

function TFirebaseUser.OAuthAccessToken: string;
begin
  if not fJSONResp.TryGetValue('oauthAccessToken', result) then
    result := '';
end;

function TFirebaseUser.OAuthTokenSecret: string;
begin
  if not fJSONResp.TryGetValue('oauthTokenSecret', result) then
    result := '';
end;

function TFirebaseUser.OAuthRawUserInfo: string;
begin
  if not fJSONResp.TryGetValue('rawUserInfo', result) then
    result := '';
end;

function TFirebaseUser.Provider(ProviderNo: integer): TProviderInfo;
var
  ProvArr: TJSONArray;
  Provider: TJSONObject;
begin
  result.ProviderId := '';
  result.FederatedId := '';
  result.RawId := '';
  result.DisplayName := '';
  result.Email := '';
  result.ScreenName := '';
  if fJSONResp.TryGetValue('providerUserInfo', ProvArr) then
  begin
    Provider := ProvArr.Items[ProviderNo] as TJSONObject;
    Provider.TryGetValue('providerId', result.ProviderId);
    Provider.TryGetValue('federatedId', result.FederatedId);
    Provider.TryGetValue('rawId', result.RawId);
    Provider.TryGetValue('displayName', result.DisplayName);
    Provider.TryGetValue('email', result.Email);
    Provider.TryGetValue('screenName', result.ScreenName);
  end;
end;

function TFirebaseUser.ProviderCount: integer;
var
  ProvArr: TJSONArray;
begin
  if not fJSONResp.TryGetValue('providerUserInfo', ProvArr) then
    result := 0
  else
    result := ProvArr.Count;
end;

{$IFDEF TOKENJWT}
function TFirebaseUser.TokenJWT: ITokenJWT;
begin
  result := fTokenJWT;
end;

function TFirebaseUser.ClaimField(const FieldName: string): TJSONValue;
begin
  if not fClaimFields.TryGetValue(FieldName, result) then
    result := nil;
end;

function TFirebaseUser.ClaimFieldNames: TStrings;
var
  Key: string;
begin
  result := TStringList.Create;
  for Key in fClaimFields.Keys do
    result.Add(Key);
end;
{$ENDIF}

end.
