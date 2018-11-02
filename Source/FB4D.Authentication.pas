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

unit FB4D.Authentication;

interface

uses
  System.Classes, System.SysUtils,
  System.JSON, System.JSON.Types,
  System.Net.HttpClient,
  System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request, FB4D.OAuth;

type
  TFirebaseAuthentication = class(TInterfacedObject, IFirebaseAuthentication)
  private
    type
      TSignType = (stNewUser, stLogin, stAnonymousLogin);
    var
      fApiKey: string;
      fAuthenticated: boolean;
      fToken: string;
      fTokenJWT: ITokenJWT;
      fExpiresAt: TDateTime;
      fRefreshToken: string;
      fOnUserResponse: TOnUserResponse;
      fOnFetchProviders: TOnFetchProviders;
      fOnFetchProvidersError: TOnRequestError;
      fOnPasswordVerification: TOnPasswordVerification;
      fOnGetUserData: TOnGetUserData;
      fOnRefreshToken: TOnTokenRefresh;
      fOnError: TOnRequestError;
    procedure SignWithEmailAndPassword(SignType: TSignType; const Info: string;
      OnUserResponse: TOnUserResponse; OnError: TOnRequestError;
      const Email: string = ''; const Password: string = '');
    procedure OnUserResp(const RequestID: string; Response: IFirebaseResponse);
    procedure OnFetchProvidersResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnVerifyPasswordResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnUserListResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure CheckAndRefreshTokenResp(const RequestID: string;
      Response: IFirebaseResponse);
  public
    constructor Create(const ApiKey: string);
    // Create new User with email and password
    procedure SignUpWithEmailAndPassword(const Email,
      Password: string; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    // Login
    procedure SignInWithEmailAndPassword(const Email,
      Password: string; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    procedure SignInAnonymously(OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    // Logout
    procedure SignOut;
    // Providers
    procedure FetchProvidersForEMail(const EMail: string;
      OnFetchProviders: TOnFetchProviders; OnError: TOnRequestError);
    function FetchProvidersForEMailSynchronous(const EMail: string;
      Strings: TStrings): boolean; // returns true if EMail is registered
    // Reset Password
    procedure SendPasswordResetEMail(const Email: string;
      OnResponse: TOnResponse; OnError: TOnRequestError);
    procedure VerifyPasswordResetCode(const ResetPasswortCode: string;
      OnPasswordVerification: TOnPasswordVerification; OnError: TOnRequestError);
    procedure ConfirmPasswordReset(const ResetPasswortCode, NewPassword: string;
      OnResponse: TOnResponse; OnError: TOnRequestError);
    // Change password, Change email, Update Profile Data
    // let field empty which shall not be changed
    procedure ChangeProfile(const EMail, Password, DisplayName,
      PhotoURL: string; OnResponse: TOnResponse; OnError: TOnRequestError);
    // Get User Data
    procedure GetUserData(OnGetUserData: TOnGetUserData;
      OnError: TOnRequestError);
    // Token refresh
    procedure RefreshToken(OnTokenRefresh: TOnTokenRefresh;
      OnError: TOnRequestError);
    function CheckAndRefreshTokenSynchronous: boolean;
    // Getter methods
    function Authenticated: boolean;
    function Token: string;
    function TokenJWT: ITokenJWT;
    function TokenExpiryDT: TDateTime;
    function NeedTokenRefresh: boolean;
    function GetRefreshToken: string;
    property ApiKey: string read fApiKey;
  end;

  TFirebaseUser = class(TInterfacedObject, IFirebaseUser)
  private
    fJSONResp: TJSONObject;
    fToken: string;
    fTokenJWT: ITokenJWT;
    fExpiresAt: TDateTime;
    fRefreshToken: string;
    fClaimFields: TDictionary<string,TJSONValue>;
  public
    constructor Create(JSONResp: TJSONObject; TokenExpected: boolean = true);
    destructor Destroy; override;
    function UID: string;
    function Token: string;
    function TokenJWT: ITokenJWT;
    function ExpiresAt: TDateTime;
    function RefreshToken: string;
    function IsDisabled: TThreeStateBoolean;
    function IsEMailAvailable: boolean;
    function IsEMailRegistred: TThreeStateBoolean;
    function IsEMailVerified: TThreeStateBoolean;
    function EMail: string;
    function IsDisplayNameAvailable: boolean;
    function DisplayName: string;
    function IsPhotoURLAvailable: boolean;
    function PhotoURL: string;
    function IsNewSignupUser: boolean;
    function IsLastLoginAtAvailable: boolean;
    function LastLoginAt: TDateTime;
    function IsCreatedAtAvailable: boolean;
    function CreatedAt: TDateTime;
    function ClaimFieldNames: TStrings;
    function ClaimField(const FieldName: string): TJSONValue;
  end;

implementation

uses
  FB4D.Helpers;

const
 GOOGLE_PASSWORD_URL =
   'https://www.googleapis.com/identitytoolkit/v3/relyingparty';
 GOOGLE_REFRESH_AUTH_URL =
   'https://securetoken.googleapis.com/v1/token';

resourcestring
  rsSignInAnonymously = 'Sign in anonymously';
  rsSignInWithEmail = 'Sign in with email for %s';
  rsSignUpWithEmail = 'Sign up with email for %s';
  rsEnableAnonymousLogin = 'In the firebase console under Authentication/' +
    'Sign-in method firstly enable anonymous sign-in provider.';
  rsSendPasswordResetEMail = 'EMail to reset the password sent to %s';
  rsVerifyPasswordResetCode = 'Verify password reset code';
  rsConfirmPasswordReset = 'Confirm password reset';
  rsChangeProfile = 'Change profile for %s';
  rsRetriveUserList = 'Get account info';
  rsRefreshToken = 'Refresh token';

{ TFirebaseAuthentication }

constructor TFirebaseAuthentication.Create(const ApiKey: string);
begin
  inherited Create;
  fApiKey := ApiKey;
end;

procedure TFirebaseAuthentication.SignInAnonymously(
  OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
begin
  SignWithEmailAndPassword(stAnonymousLogin, rsSignInAnonymously,
    OnUserResponse, OnError);
end;

procedure TFirebaseAuthentication.SignInWithEmailAndPassword(const Email,
  Password: string; OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
begin
  SignWithEmailAndPassword(stLogin, Format(rsSignInWithEmail, [EMail]),
    OnUserResponse, OnError, Email, Password);
end;

procedure TFirebaseAuthentication.SignOut;
begin
  fToken := '';
  fTokenJWT := nil;
  fRefreshToken := '';
  fAuthenticated := false;
end;

procedure TFirebaseAuthentication.SignUpWithEmailAndPassword(const Email,
  Password: string; OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
begin
  SignWithEmailAndPassword(stNewUser, Format(rsSignUpWithEmail, [EMail]),
    OnUserResponse, OnError, Email, Password);
end;

procedure TFirebaseAuthentication.OnUserResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  User: IFirebaseUser;
  ErrMsg: string;
begin
  try
    Response.CheckForJSONObj;
    fAuthenticated := true;
    User := TFirebaseUser.Create(Response.GetContentAsJSONObj);
    fToken := User.Token;
    fTokenJWT := User.TokenJWT;
    fExpiresAt := User.ExpiresAt;
    fRefreshToken := User.RefreshToken;
    if assigned(fOnUserResponse) then
      fOnUserResponse(RequestID, User);
  except
    on e: EFirebaseResponse do
    begin
      if sameText(e.Message, TFirebaseResponse.ExceptOpNotAllowed) and
        (RequestID = rsSignInAnonymously) then
        ErrMsg := rsEnableAnonymousLogin
      else
        ErrMsg := e.Message;
      if assigned(fOnError) then
        fOnError(RequestID, ErrMsg)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, ErrMsg]));
    end;
    on e: Exception do
    begin
      if assigned(fOnError) then
        fOnError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
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
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
begin
  fOnUserResponse := OnUserResponse;
  fOnError := OnError;
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL, Info);
  Params := TDictionary<string, string>.Create;
  try
    if SignType < stAnonymousLogin then
    begin
      Data.AddPair(TJSONPair.Create('email', Email));
      Data.AddPair(TJSONPair.Create('password', Password));
    end;
    Data.AddPair(TJSONPair.Create('returnSecureToken', 'true'));
    Params.Add('key', ApiKey);
    Request.SendRequest([ResourceStr[SignType]], rmPost, Data, Params,
      tmNoToken, OnUserResp, OnError);
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.FetchProvidersForEMail(const EMail: string;
  OnFetchProviders: TOnFetchProviders; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
begin
  fOnFetchProviders := OnFetchProviders;
  fOnFetchProvidersError := OnError;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL, EMail);
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('identifier', Email));
    Data.AddPair(TJSONPair.Create('continueUri', 'http://locahost'));
    Params.Add('key', ApiKey);
    Request.SendRequest(['createAuthUri'], rmPOST, Data, Params, tmNoToken,
      OnFetchProvidersResp, onError);
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
      if assigned(fOnFetchProviders) then
        fOnFetchProviders(RequestID, Registered, Providers);
    finally
      Providers.Free;
      ResObj.Free;
    end;
  except
    on e: exception do
      if assigned(fOnFetchProvidersError) then
        fOnFetchProvidersError(RequestID, e.Message);
  end;
end;

function TFirebaseAuthentication.FetchProvidersForEMailSynchronous(
  const EMail: string; Strings: TStrings): boolean;
var
  Data, ResObj: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  ResArr: TJSONArray;
  c: integer;
begin
  Data := TJSONObject.Create;
  ResObj := nil;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL);
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('identifier', Email));
    Data.AddPair(TJSONPair.Create('continueUri', 'http://locahost'));
    Params.Add('key', ApiKey);
    Response := Request.SendRequestSynchronous(['createAuthUri'], rmPOST, Data,
      Params, tmNoToken);
    Response.CheckForJSONObj;
    ResObj := Response.GetContentAsJSONObj;
    if not ResObj.GetValue('registered').TryGetValue(result) then
      raise EFirebaseAuthentication.Create('JSON field registered missing');
    if result then
    begin
      ResArr := ResObj.GetValue('allProviders') as TJSONArray;
      if not assigned(ResArr) then
        raise EFirebaseAuthentication.Create('JSON field allProviders missing');
      Strings.Clear;
      for c := 0 to ResArr.Count - 1 do
        Strings.Add(ResArr.Items[c].ToString);
    end;
  finally
    ResObj.Free;
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.SendPasswordResetEMail(const Email: string;
  OnResponse: TOnResponse; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    Format(rsSendPasswordResetEMail, [EMail]));
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('email', Email));
    Data.AddPair(TJSONPair.Create('requestType', 'PASSWORD_RESET'));
    Params.Add('key', ApiKey);
    Request.SendRequest(['getOobConfirmationCode'], rmPost, Data, Params,
      tmNoToken, OnResponse, OnError);
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.VerifyPasswordResetCode(
  const ResetPasswortCode: string;
  OnPasswordVerification: TOnPasswordVerification; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
begin
  fOnPasswordVerification := OnPasswordVerification;
  fOnError := OnError;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    rsVerifyPasswordResetCode);
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('oobCode', ResetPasswortCode));
    Params.Add('key', ApiKey);
    Request.SendRequest(['resetPassword'], rmPost,
      Data, Params, tmNoToken, OnVerifyPasswordResp, OnError);
  finally
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.OnVerifyPasswordResp(const RequestID: string;
  Response: IFirebaseResponse);
begin
  if assigned(fOnPasswordVerification) then
  begin
    if Response.StatusOk then
      fOnPasswordVerification(RequestID, pvrPassed)
    else if SameText(Response.ErrorMsg, TFirebaseResponse.ExceptOpNotAllowed) then
      fOnPasswordVerification(RequestID, pvrOpNotAllowed)
    else if SameText(Response.ErrorMsg, TFirebaseResponse.ExceptExpiredOobCode) then
      fOnPasswordVerification(RequestID, pvrpvrExpired)
    else if SameText(Response.ErrorMsg, TFirebaseResponse.ExceptInvalidOobCode) then
      fOnPasswordVerification(RequestID, pvrInvalid)
    else if assigned(fOnError) then
      fOnError(RequestID, Response.ErrorMsg)
    else
      TFirebaseHelpers.Log('Verify password failed: ' + Response.ErrorMsg);
  end;
end;

procedure TFirebaseAuthentication.ConfirmPasswordReset(const ResetPasswortCode,
  NewPassword: string; OnResponse: TOnResponse; OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
begin
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
    rsConfirmPasswordReset);
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('oobCode', ResetPasswortCode));
    Data.AddPair(TJSONPair.Create('newPassword', NewPassword));
    Params.Add('key', ApiKey);
    Request.SendRequest(['resetPassword'], rmPost, Data,
      Params, tmNoToken, OnResponse, OnError);
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.ChangeProfile(const EMail, Password,
  DisplayName, PhotoURL: string; OnResponse: TOnResponse;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
  Info: TStringList;
begin
  Data := TJSONObject.Create;
  Params := TDictionary<string, string>.Create;
  Info := TStringList.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', fToken));
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
    Params.Add('key', ApiKey);
    Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL,
      Format(rsChangeProfile, [Info.CommaText]));
    Request.SendRequest(['setAccountInfo'], rmPost, Data, Params, tmNoToken,
      OnResponse, OnError);
  finally
    Info.Free;
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.GetUserData(OnGetUserData: TOnGetUserData;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
begin
  fOnGetUserData := OnGetUserData;
  fOnError := OnError;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_PASSWORD_URL, rsRetriveUserList);
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('idToken', fToken));
    Params.Add('key', ApiKey);
    Request.SendRequest(['getAccountInfo'], rmPost, Data, Params, tmNoToken,
      OnUserListResp, OnError);
  finally
    Params.Free;
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
    if not Response.StatusOk then
      Response.CheckForJSONObj
    else if assigned(fOnGetUserData) then
    begin
      UserList := TFirebaseUserList.Create;
      UsersObj := Response.GetContentAsJSONObj;
      try
        if not UsersObj.TryGetValue('users', Users) then
          raise EFirebaseResponse.Create(
            'users field not found in getAccountInfo');
        for c := 0 to Users.Count - 1 do
          UserList.Add(TFirebaseUser.Create(
            Users.Items[c].Clone as TJSONObject, false));
        fOnGetUserData(UserList);
      finally
        UsersObj.Free;
        UserList.Free;
      end;
    end;
  except
    on e: exception do
      if assigned(fOnError) then
        fOnError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log('Firebase GetAccountInfo failed: ' + e.Message);
  end;
end;

procedure TFirebaseAuthentication.RefreshToken(OnTokenRefresh: TOnTokenRefresh;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: IFirebaseRequest;
begin
  fOnRefreshToken := OnTokenRefresh;
  fOnError := OnError;
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_REFRESH_AUTH_URL, rsRefreshToken);
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('grant_type', 'refresh_token'));
    Data.AddPair(TJSONPair.Create('refresh_token', fRefreshToken));
    Params.Add('key', ApiKey);
    Request.SendRequest([], rmPost, Data, Params, tmNoToken,
      CheckAndRefreshTokenResp, OnError);
  finally
    Params.Free;
    Data.Free;
  end;
end;

procedure TFirebaseAuthentication.CheckAndRefreshTokenResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  NewToken: TJSONObject;
  ExpiresInSec: integer;
begin
  try
    Response.CheckForJSONObj;
    fAuthenticated := true;
    NewToken := Response.GetContentAsJSONObj;
    try
      if not NewToken.TryGetValue('access_token', fToken) then
        raise EFirebaseUser.Create('access_token not found')
      else
        fTokenJWT := TTokenJWT.Create(fToken);
      if NewToken.TryGetValue('expires_in', ExpiresInSec) then
        fExpiresAt := now + ExpiresInSec / 24 / 3600
      else
        fExpiresAt := now;
      if not NewToken.TryGetValue('refresh_token', fRefreshToken) then
      begin
        fRefreshToken := ''
      end
      else if assigned(fOnRefreshToken) then
        fOnRefreshToken(true);
    finally
      NewToken.Free;
    end;
  except
    on e: exception do
      if assigned(fOnError) then
        fOnError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log('Firebase RefreshToken failed: ' + e.Message);
  end;
end;

function TFirebaseAuthentication.CheckAndRefreshTokenSynchronous: boolean;
var
  Data: TJSONObject;
  Params: TDictionary<string, string>;
  Request: TFirebaseRequest;
  Response: IFirebaseResponse;
  NewToken: TJSONObject;
  ExpiresInSec: integer;
begin
  if not NeedTokenRefresh then
    exit(false);
  result := false;
  fAuthenticated := false;
  Data := TJSONObject.Create;
  Request := TFirebaseRequest.Create(GOOGLE_REFRESH_AUTH_URL, '');
  Params := TDictionary<string, string>.Create;
  try
    Data.AddPair(TJSONPair.Create('grant_type', 'refresh_token'));
    Data.AddPair(TJSONPair.Create('refresh_token', fRefreshToken));
    Params.Add('key', ApiKey);
    Response := Request.SendRequestSynchronous([], rmPost, Data, Params,
      tmNoToken);
    Response.CheckForJSONObj;
    fAuthenticated := true;
    NewToken := Response.GetContentAsJSONObj;
    try
      if not NewToken.TryGetValue('access_token', fToken) then
        raise EFirebaseAuthentication.Create('access_token not found')
      else
        fTokenJWT := TTokenJWT.Create(fToken);
      if NewToken.TryGetValue('expires_in', ExpiresInSec) then
        fExpiresAt := now + ExpiresInSec / 24 / 3600
      else
        fExpiresAt := now;
      if not NewToken.TryGetValue('refresh_token', fRefreshToken) then
        fRefreshToken := ''
      else
        exit(true);
    finally
      NewToken.Free;
    end;
  finally
    Response := nil;
    Params.Free;
    Request.Free;
    Data.Free;
  end;
end;

function TFirebaseAuthentication.Authenticated: boolean;
begin
  result := fAuthenticated;
end;

function TFirebaseAuthentication.NeedTokenRefresh: boolean;
const
  safetyMargin = 5 / 3600 / 24; // 5 sec
begin
  result := now + safetyMargin > fExpiresAt;
end;

function TFirebaseAuthentication.GetRefreshToken: string;
begin
  result := fRefreshToken;
end;

function TFirebaseAuthentication.Token: string;
begin
  result := fToken;
end;

function TFirebaseAuthentication.TokenExpiryDT: TDateTime;
begin
  result := fExpiresAt;
end;

function TFirebaseAuthentication.TokenJWT: ITokenJWT;
begin
  result := fTokenJWT;
end;

{ TFirebaseUser }

constructor TFirebaseUser.Create(JSONResp: TJSONObject; TokenExpected: boolean);
var
  ExpiresInSec: integer;
  Claims: TJSONObject;
  c: integer;
begin
  inherited Create;
  fTokenJWT := nil;
  fClaimFields := TDictionary<string,TJSONValue>.Create;
  fJSONResp := JSONResp;
  if not fJSONResp.TryGetValue('idToken', fToken) then
    if TokenExpected then
      raise EFirebaseUser.Create('idToken not found')
    else
      fToken := ''
  else begin
    fTokenJWT := TTokenJWT.Create(fToken);
    Claims := fTokenJWT.Claims.JSON;
    for c := 0 to Claims.Count - 1 do
      fClaimFields.Add(Claims.Pairs[c].JsonString.Value,
        Claims.Pairs[c].JsonValue);
  end;
  if fJSONResp.TryGetValue('expiresIn', ExpiresInSec) then
    fExpiresAt := now + ExpiresInSec / 24 / 3600
  else
    fExpiresAt := now;
  if not fJSONResp.TryGetValue('refreshToken', fRefreshToken) then
    fRefreshToken := '';
end;

destructor TFirebaseUser.Destroy;
begin
  fClaimFields.Free;
  fTokenJWT := nil;
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

function TFirebaseUser.IsEMailRegistred: TThreeStateBoolean;
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
  bool: boolean;
begin
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

function TFirebaseUser.CreatedAt: TDateTime;
var
  dt: Int64;
begin
  if not fJSONResp.TryGetValue('createdAt', dt) then
    raise EFirebaseUser.Create('createdAt not found');
  result := TFirebaseHelpers.ConvertTimeStampToLocalDateTime(dt);
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

function TFirebaseUser.LastLoginAt: TDateTime;
var
  dt: Int64;
begin
  if not fJSONResp.TryGetValue('lastLoginAt', dt) then
    raise EFirebaseUser.Create('lastLoginAt not found');
  result := TFirebaseHelpers.ConvertTimeStampToLocalDateTime(dt);
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

end.
