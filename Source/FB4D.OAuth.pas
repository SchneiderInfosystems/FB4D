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
unit FB4D.OAuth;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  System.JSON, System.JSON.Types,
  REST.Types, REST.Client, REST.Utils, REST.Consts,
  JOSE.Types.Bytes, JOSE.Context, JOSE.Core.JWT,
  IdCustomHTTPServer, IdHTTPServer, IdContext,
  FB4D.Interfaces;

type
  EGoogleOAuth2Authenticator = class(Exception);
  TGoogleOAuth2Authenticator = class
  private const
    cAccessTokenEndpoint = 'https://www.googleapis.com/oauth2/v4/token';
    cAuthorizationEndpoint = 'https://accounts.google.com/o/oauth2/v2/auth';
    cDefaultTimeoutInMS = 60000; // Number of milliseconds while the user has time to authorize in the browser window
  public type
    TAuthorizationState = (idle, started, failed, timeOutOccured, authCodeReceived, passed);
    TOnAuthenticatorFinished = procedure(State: TAuthorizationState; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError) of object;
  private
    fClientID: string;
    fClientSecret: string;
    fScope: string;
    fLoginHint: string;
    fRedirectionEndpoint: string;
    fAuthorizationRequestURI: string;
    fLocalState: string;
    fCodeVerifier: string;
    fCodeChallenge: string;
    fLocalServer: TIdHTTPServer;
    fLocalServerPort: WORD;
    fAuthorizationState: TAuthorizationState;
    fAuthorizationError: string;
    fTimeoutInMS: integer;
    fIDToken: string;
    fAccessTokenExpiry: TDateTime;
    fAuthCode: string;
    fRefreshToken: string;
    fOnAuthenticatorFinished: TOnAuthenticatorFinished;
    procedure SetRedirectionURI;
    function Encode_SHA256(const strBase64: string): string;
    function GetMsgPageAsHtml(const errorStr: string = ''): string;
    procedure StartLocalServer;
    procedure StopLocalServer;
    procedure onCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo);
    procedure onCommandError(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
      AResponseInfo: TIdHTTPResponseInfo; AException: Exception);
  public
    constructor Create(const ClientID, ClientSecret, Scope: string; const GMailAdr: string = '');
    function CheckAccess(const ClientID, ClientSecret: string): boolean;
    procedure OpenDefaultBrowserForLogin(OnAuthenticatorFinished: TOnAuthenticatorFinished;
      OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
    function GetTokensFromAuthCode(RefreshFlag: boolean = false): boolean;
    function AuthorizationStateInfo: string;
    function RequiresTokenRefresh: boolean;
    property AuthorizationRequestURI: string read fAuthorizationRequestURI;
    property IDToken: string read fIDToken;
    property AccessTokenExpiry: TDateTime read fAccessTokenExpiry;
    property AuthorizationState: TAuthorizationState read fAuthorizationState;
    property AuthorizationError: string read fAuthorizationError;
    property TimeoutInMS: integer read fTimeoutInMS write fTimeoutInMS;
  end;

{$IFDEF TOKENJWT}
  TTokenJWT = class(TInterfacedObject, ITokenJWT)
  private const
    cAuthTime = 'auth_time';
  private
    fContext: TJOSEContext;
    function GetPublicKey(const Id: string): TJOSEBytes;
  public
    constructor Create(const OAuthToken: string);
    destructor Destroy; override;
    function VerifySignature: boolean;
    function GetHeader: TJWTHeader;
    function GetClaims: TJWTClaims;
    function GetNoOfClaims: integer;
    function GetClaimName(Index: integer): string;
    function GetClaimValue(Index: integer): TJSONValue;
    function GetClaimValueAsStr(Index: integer): string;
  end;
{$ENDIF}

implementation

uses
  System.Generics.Collections, System.NetEncoding, System.DateUtils,
  System.Threading, System.Hash, System.Net.Socket,
  JOSE.Core.JWS, JOSE.Signing.RSA,
  FB4D.Request, FB4D.Helpers;

{$R 'OAuth.res'}

resourcestring
  rsAuthorizationNotStarted = 'Authorization not started';
  rsAuthorizationStarted = 'Authorization request waiting for user action';
  rsAuthorizationFailed = 'Authorization process failed';
  rsAuthorizationTimeout = 'Authorization not approved within the time limit';
  rsAuthorizationFirstStepPassed = 'First step of authorization passed';
  rsAuthorizationExpired = 'Authorization expired';
  // LanguageCode
  rsParam1 = 'en';
  // Title
  rsParam2Ok = 'Authorization passed';
  rsParam2Fail = 'Authorization failed';
  // Color
  rsParam3Ok = '#16a085';
  rsParam3Fail = '#c0392b';
  // Headline
  rsParam4Ok = 'Authorization was successful!';
  rsParam4Fail = 'The authorization has not been approved!';
  // Message
  rsParam5Ok = 'You can close this page and return to the application.';
  rsParam5Fail = 'You can close this page and return to the application to try again.';

{ TGoogleOAuth2Authenticator }

constructor TGoogleOAuth2Authenticator.Create(const ClientID, ClientSecret, Scope, GMailAdr: string);
begin
  inherited Create;
  fClientID := ClientID;
  fClientSecret := ClientSecret;
  fScope := Scope;
  fLoginHint := GMailAdr;
  fLocalState := '';
  fCodeVerifier := '';
  fCodeChallenge := '';
  fAuthCode := '';
  fRefreshToken := '';
  fIDToken := '';
  fAuthorizationState := idle;
  fAuthorizationError := '';
  fAuthorizationRequestURI := '';
  fRedirectionEndpoint := '';
  fLocalServer := nil;
  fTimeoutInMS := cDefaultTimeoutInMS;
end;

function TGoogleOAuth2Authenticator.CheckAccess(const ClientID, ClientSecret: string): boolean;
begin
  result := (fClientID = ClientID) and (fClientSecret = ClientSecret);
end;

procedure TGoogleOAuth2Authenticator.SetRedirectionURI;
var
  Socket: TSocket;
begin
  Socket := TSocket.Create(TSocketType.TCP);
  try
    Socket.Bind(0);
    fLocalServerPort := Socket.LocalPort;
    Socket.Close(true);
  finally
    Socket.Free;
  end;
  fRedirectionEndpoint := format('http://localhost:%d', [fLocalServerPort]);
end;

function TGoogleOAuth2Authenticator.Encode_SHA256(const strBase64: string): string;
var
  HashSHA2: THashSHA2;
  Base64: TBase64StringEncoding;
begin
  HashSHA2 := THashSHA2.Create(SHA256);
  Base64 := TBase64StringEncoding.Create;
  try
    HashSHA2.Update(strBase64);
    result := StringOf(Base64.Encode(HashSHA2.HashAsBytes));
    result := StringReplace(StringReplace(result, '+', '-', [rfReplaceAll]), '/', '_', [rfReplaceAll]);
    result := StringReplace(result, '=', '',  [rfReplaceAll]);
  finally
    Base64.Free;
  end;
end;

procedure TGoogleOAuth2Authenticator.OpenDefaultBrowserForLogin(OnAuthenticatorFinished: TOnAuthenticatorFinished;
  OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
begin
  fOnAuthenticatorFinished := OnAuthenticatorFinished;
  if not assigned(fOnAuthenticatorFinished) then
    raise EGoogleOAuth2Authenticator.Create('OnAuthenticatorFinished callback missing');
  if fClientID.IsEmpty then
    raise EGoogleOAuth2Authenticator.Create('ClientID missing');
  if fClientSecret.IsEmpty then
    raise EGoogleOAuth2Authenticator.Create('ClientSecret missing');
  SetRedirectionURI;
  // Generate verification codes
  fLocalState := TFirebaseHelpers.CryptoRandom64(10, BASE64);
  fCodeVerifier := TFirebaseHelpers.CryptoRandom64(60, BASE64); // PKCE
  fCodeChallenge := Encode_SHA256(fCodeVerifier);
  fAuthorizationRequestURI := cAuthorizationEndpoint + '?response_type=code&client_id=' + URIEncode(fClientID) +
    '&redirect_uri='  + URIEncode(fRedirectionEndpoint) + '&scope=' + URIEncode(fScope) +
    '&state=' + URIEncode(fLocalState) + '&code_challenge_method=S256&code_challenge=' + URIEncode(fCodeChallenge);
  if not fLoginHint.IsEmpty then
    fAuthorizationRequestURI := fAuthorizationRequestURI + '&login_hint=' + URIEncode(fLoginHint);
  StartLocalServer;
  if not TFirebaseHelpers.OpenURLinkInBrowser(fAuthorizationRequestURI) then
    raise EGoogleOAuth2Authenticator.Create('System browser failed to open ' + fAuthorizationRequestURI);
  fAuthorizationState := started;
  TThread.CreateAnonymousThread(
    procedure
    const
      cSliceTimeInMS = 10;
    var
      Timeout: integer;
    begin
      Timeout := 0;
      while fAuthorizationState = started do
      begin
        Sleep(cSliceTimeInMS);
        inc(Timeout, cSliceTimeInMS);
        if Timeout > fTimeoutInMS then
          fAuthorizationState := timeOutOccured;
      end;
      TThread.Synchronize(nil,
        procedure
        begin
          StopLocalServer;
          if fAuthorizationState = authCodeReceived then
            if GetTokensFromAuthCode then
              fAuthorizationState := passed;
          if assigned(fOnAuthenticatorFinished) then
            fOnAuthenticatorFinished(fAuthorizationState, OnUserResponse, OnError);
        end);
    end).Start;
end;

function TGoogleOAuth2Authenticator.GetTokensFromAuthCode(RefreshFlag: boolean): boolean;
var
  restClient: TRestClient;
  restRequest: TRESTRequest;
  respValueStr: string;
  expireSecs: int64;
begin
  result := false;
  if fAuthCode.IsEmpty then
    exit;
  restClient := TRestClient.Create(cAccessTokenEndpoint);
  try
    restRequest := TRESTRequest.Create(restClient);
    restRequest.Method := TRESTRequestMethod.rmPOST;
    restRequest.AddAuthParameter('client_id', fClientID, TRESTRequestParameterKind.pkGETorPOST);
    restRequest.AddAuthParameter('client_secret', fClientSecret, TRESTRequestParameterKind.pkGETorPOST);
    restRequest.AddAuthParameter('redirect_uri', fRedirectionEndpoint, TRESTRequestParameterKind.pkGETorPOST);
    if not RefreshFlag then
    begin
      restRequest.AddAuthParameter('code', fAuthCode, TRESTRequestParameterKind.pkGETorPOST);
      restRequest.AddAuthParameter('code_verifier', fCodeVerifier, TRESTRequestParameterKind.pkGETorPOST);     // Added for PKCE
      restRequest.AddAuthParameter('grant_type', 'authorization_code', TRESTRequestParameterKind.pkGETorPOST);
    end else begin
      restRequest.AddAuthParameter('refresh_token', fRefreshToken, TRESTRequestParameterKind.pkGETorPOST);
      restRequest.AddAuthParameter('grant_type', 'refresh_token', TRESTRequestParameterKind.pkGETorPOST);
    end;
    restRequest.Execute;
    if restRequest.Response.GetSimpleValue('refresh_token', respValueStr) then
      fRefreshToken := respValueStr;
    if restRequest.Response.GetSimpleValue('id_token', respValueStr) then
    begin
      fIDToken := respValueStr;
      result := true;
    end else begin
      fAuthorizationError := 'id_token missing in response from ' + cAccessTokenEndpoint;
      fAuthorizationState := failed;
    end;
    if restRequest.Response.GetSimpleValue('expires_in', respValueStr) then
    begin
      expireSecs := StrToIntdef(respValueStr, -1);
      if expireSecs > -1 then
        fAccessTokenExpiry := IncSecond(Now, expireSecs)
      else
        fAccessTokenExpiry := 0;
    end;
  finally
    restClient.Free;
  end;
end;

function TGoogleOAuth2Authenticator.RequiresTokenRefresh: boolean;
begin
  result := (AuthorizationState in [passed, authCodeReceived]) and
    (fAccessTokenExpiry < now) and not fRefreshToken.IsEmpty;
end;

function TGoogleOAuth2Authenticator.AuthorizationStateInfo: string;
begin
  case fAuthorizationState of
    idle:
      result := rsAuthorizationNotStarted;
    started:
      result := rsAuthorizationStarted;
    failed:
      begin
        result := rsAuthorizationFailed;
        if not fAuthorizationError.IsEmpty then
          result := result + ': ' + fAuthorizationError;
      end;
    timeOutOccured:
      result := rsAuthorizationTimeout;
    authCodeReceived:
      if fAccessTokenExpiry < now then
        result := rsAuthorizationFirstStepPassed
      else
        result := rsAuthorizationExpired;
    passed:
      result := rsParam2Ok;
    else
      result := rsAuthorizationFailed + ': invalid authorization state';
  end;
end;

procedure TGoogleOAuth2Authenticator.StartLocalServer;
begin
  if assigned(fLocalServer) then
    raise EGoogleOAuth2Authenticator.Create('Local server already started');
  fLocalServer := TIdHTTPServer.Create(nil);
  fLocalServer.DefaultPort := fLocalServerPort;
  fLocalServer.OnCommandGet := onCommandGet;
  fLocalServer.OnCommandError := onCommandError;
  fLocalServer.Active := true;
end;

procedure TGoogleOAuth2Authenticator.StopLocalServer;
begin
  fLocalServer.Active := false;
  FreeAndNil(fLocalServer);
end;

procedure TGoogleOAuth2Authenticator.onCommandError(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo; AException: Exception);
begin
  fAuthorizationState := failed;
  fAuthorizationError := AException.Message;
  AResponseInfo.ContentText := GetMsgPageAsHtml(rsAuthorizationFailed);
end;

procedure TGoogleOAuth2Authenticator.onCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo;
  AResponseInfo: TIdHTTPResponseInfo);
begin
  if ARequestInfo.QueryParams.IsEmpty then
    exit; // Not expected result
  if fAuthorizationState <> started then
    exit; // Exit if not started
  fAuthorizationError := ARequestInfo.Params.Values['error'];
  if not fAuthorizationError.IsEmpty then
    fAuthorizationState := failed
  else if ARequestInfo.Params.Values['state'] = fLocalState then
  begin
    fAuthCode := ARequestInfo.Params.Values['code'];
    fAuthorizationState := authCodeReceived;
  end else
    fAuthorizationError := 'State has changed unexpectly';
  if fAuthorizationState <> authCodeReceived then
    AResponseInfo.ContentText := GetMsgPageAsHtml(fAuthorizationError)
  else
    AResponseInfo.ContentText := GetMsgPageAsHtml;
end;

function TGoogleOAuth2Authenticator.GetMsgPageAsHtml(const errorStr: string): string;
var
  ResStream: TResourceStream;
  HtmlDoc: TBytes;
begin
  ResStream := TResourceStream.Create(hInstance, 'OAuthResp', RT_RCDATA);
  try
    SetLength(HTMLDoc, ResStream.Size);
    ResStream.Position := 0;
    ResStream.Read(HTMLDoc, ResStream.Size);
  finally
    ResStream.Free;
  end;
  if not errorStr.IsEmpty then
    result := Format(UTF8ArrayToString(HtmlDoc),
      [rsParam1, rsParam2Fail, rsParam3Fail,
       THTMLEncoding.HTML.Encode(rsParam4Fail),
       THTMLEncoding.HTML.Encode(rsParam5Fail) + '<br>' +
         THTMLEncoding.HTML.Encode(errorStr)])
  else
    result := Format(UTF8ArrayToString(HtmlDoc),
      [rsParam1, rsParam2Ok, rsParam3Ok, THTMLEncoding.HTML.Encode(rsParam4Ok),
       THTMLEncoding.HTML.Encode(rsParam5Ok)]);
end;

{$IFDEF TOKENJWT}
constructor TTokenJWT.Create(const OAuthToken: string);
var
  CompactToken: TJOSEBytes;
begin
  CompactToken.AsString := OAuthToken;
  fContext := TJOSEContext.Create(CompactToken, TJWTClaims);
  CompactToken.Clear;
end;

destructor TTokenJWT.Destroy;
begin
  fContext.Free;
  inherited;
end;

function TTokenJWT.GetPublicKey(const Id: string): TJOSEBytes;
const
  GOOGLE_x509 = 'https://www.googleapis.com/robot/v1/metadata/x509';
  SToken = 'securetoken@system.gserviceaccount.com';
var
  ARequest: TFirebaseRequest;
  AResponse: IFirebaseResponse;
  JSONObj: TJSONObject;
  c: integer;
begin
  result.Empty;
  ARequest := TFirebaseRequest.Create(GOOGLE_x509, 'GetPublicKey');
  JSONObj := nil;
  try
    AResponse := ARequest.SendRequestSynchronous([SToken], rmGet, nil, nil,
      tmNoToken);
    JSONObj := TJSONObject.ParseJSONValue(AResponse.ContentAsString) as
      TJSONObject;
    for c := 0 to JSONObj.Count-1 do
      if SameText(JSONObj.Pairs[c].JsonString.Value, Id) then
        result.AsString := JSONObj.Pairs[c].JsonValue.Value;
    if result.IsEmpty then
      raise ETokenJWT.Create('kid not found: ' + Id);
  finally
    JSONObj.Free;
    AResponse := nil;
    ARequest.Free;
  end;
end;

function TTokenJWT.GetClaims: TJWTClaims;
begin
  result := fContext.GetClaims;
end;

function TTokenJWT.GetNoOfClaims: integer;
begin
  result := GetClaims.JSON.Count;
end;

function TTokenJWT.GetClaimName(Index: integer): string;
begin
  result := GetClaims.JSON.Pairs[Index].JsonString.Value;
end;

function TTokenJWT.GetClaimValue(Index: integer): TJSONValue;
begin
  result := GetClaims.JSON.Pairs[Index].JsonValue;
end;

function TTokenJWT.GetClaimValueAsStr(Index: integer): string;
var
  Val: TJSONValue;
  Name: string;
  TimeStamp: Int64;
begin
  Val := GetClaimValue(Index);
  Name := GetClaimName(Index);
  if (Name = TReservedClaimNames.ISSUED_AT) or
     (Name = TReservedClaimNames.EXPIRATION) or
     (Name = cAuthTime) then
  begin
    TimeStamp := StrToInt64Def(Val.Value, 0) * 1000;
    result := DateTimeToStr(TFirebaseHelpers.ConvertTimeStampToUTCDateTime(TimeStamp));
  end
  else if Val is TJSONString then
    result := Val.Value
  else
    result := Val.ToJSON;
end;

function TTokenJWT.GetHeader: TJWTHeader;
begin
  result := fContext.GetHeader;
end;

function TTokenJWT.VerifySignature: boolean;
var
  PublicKey: TJOSEBytes;
  jws: TJWS;
begin
  jws := fContext.GetJOSEObject<TJWS>;
  PublicKey := GetPublicKey(GetHeader.JSON.GetValue('kid').Value);
  {$IFDEF IOS}
  result := false;
  // Unfortunately, this function is no longer available for iOS platform
  // For details check the following discussions
  // https://github.com/SchneiderInfosystems/FB4D/discussions/163
  // https://github.com/paolo-rossi/delphi-jose-jwt/issues/51
  {$ELSE}
  jws.SetKeyFromCert(PublicKey);
  result := jws.VerifySignature;
  {$ENDIF}
end;
{$ENDIF}

end.
