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

unit FB4D.Request;

interface

uses
  System.Classes, System.JSON, System.SysUtils,
  System.Net.URLClient, System.Net.HttpClient,
  System.Generics.Collections,
  REST.Client, REST.Types,
  IPPeerClient,
  FB4D.Interfaces, FB4D.Response;

type
  TResendRequest = class;

  TFirebaseRequest = class(TInterfacedObject, IFirebaseRequest)
  private
    class var fResendRequest: TResendRequest;
    procedure RESTRequestAfterExecute(Sender: TCustomRESTRequest);
    procedure RESTRequestHTTPProtocolError(Sender: TCustomRESTRequest);
    function EncodeToken: string;
    function InternalSendRequestSynchronous(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams = nil;
      TokenMode: TTokenMode = tmBearer): IFirebaseResponse; overload;
    procedure InternalSendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    procedure InternalSendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    procedure SendRequestAfterTokenRefresh(TokenRefreshed: boolean);
    procedure SendStreamRequestAfterTokenRefresh(TokenRefreshed: boolean);
  protected
    fBaseURI: string;
    fRequestID: string;
    fAuth: IFirebaseAuthentication;
  public
    constructor Create(const BaseURI: string; const RequestID: string = '';
      Auth: IFirebaseAuthentication = nil);
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    function SendRequestSynchronous(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue = nil;
      QueryParams: TQueryParams = nil;
      TokenMode: TTokenMode = tmBearer): IFirebaseResponse; overload;
    function SendRequestSynchronous(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams = nil;
      TokenMode: TTokenMode = tmBearer): IFirebaseResponse; overload;
  end;

  TResendRequest = class
  strict private
    fBaseURI: string;
    fRequestID: string;
    fAuth: IFirebaseAuthentication;
    fResParams: TRequestResourceParam;
    fMethod: TRESTRequestMethod;
    fData: TJSONValue;
    fDataStream: TStream;
    fContentType: TRESTContentType;
    fQueryParams: TQueryParams;
    fTokenMode: TTokenMode;
    fOnResponse: TOnFirebaseResp;
    fOnSuccess: TOnSuccess;
    fOnRequestError: TOnRequestError;
  public
    constructor Create(Req: TFirebaseRequest; ResParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue; QueryParams: TQueryParams;
      TokenMode: TTokenMode; OnResponse: TOnFirebaseResp;
      OnRequestError: TOnRequestError; OnSuccess: TOnSuccess); overload;
    constructor Create(Req: TFirebaseRequest; ResParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    destructor Destroy; override;
    property BaseURI: string read fBaseURI;
    property RequestID: string read fRequestID;
    property Auth: IFirebaseAuthentication read fAuth;
    property ResParams: TRequestResourceParam read fResParams;
    property Method: TRESTRequestMethod read fMethod;
    property Data: TJSONValue read fData;
    property DataStream: TStream read fDataStream;
    property ContentType: TRESTContentType read fContentType;
    property QueryParams: TQueryParams read fQueryParams;
    property TokenMode: TTokenMode read fTokenMode;
    property OnResponse: TOnFirebaseResp read fOnResponse;
    property OnSuccess: TOnSuccess read fOnSuccess;
    property OnRequestError: TOnRequestError read fOnRequestError;
  end;

implementation

uses
  System.NetConsts, System.NetEncoding, System.StrUtils, System.TypInfo,
  FB4D.Helpers;

resourcestring
  rsTokenRefreshFailed = 'Authorisation token refresh failed';
  rsConnectionToServerBroken = 'Connection to server broken';

{ TResendRequest }

constructor TResendRequest.Create(Req: TFirebaseRequest;
  ResParams: TRequestResourceParam; Method: TRESTRequestMethod;
  Data: TJSONValue; QueryParams: TQueryParams; TokenMode: TTokenMode;
  OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
  OnSuccess: TOnSuccess);
var
  c: integer;
  key: string;
begin
  fBaseURI := Req.fBaseURI;
  fRequestID := Req.fRequestID;
  fAuth := Req.fAuth;
  SetLength(fResParams, length(ResParams));
  for c := low(ResParams) to high(ResParams) do
    fResParams[c] := ResParams[c];
  fMethod := Method;
  if assigned(Data) then
    fData := Data.Clone as TJSONValue;
  if assigned(QueryParams) then
  begin
    fQueryParams := TQueryParams.Create;
    for key in QueryParams.Keys do
      fQueryParams.Add(key, QueryParams.Items[key]);
  end;
  fTokenMode := TokenMode;
  fOnResponse := OnResponse;
  fOnRequestError := OnRequestError;
  fOnSuccess := OnSuccess;
end;

constructor TResendRequest.Create(Req: TFirebaseRequest;
  ResParams: TRequestResourceParam; Method: TRESTRequestMethod; Data: TStream;
  ContentType: TRESTContentType; QueryParams: TQueryParams;
  TokenMode: TTokenMode; OnResponse: TOnFirebaseResp;
  OnRequestError: TOnRequestError; OnSuccess: TOnSuccess);
var
  c: integer;
  key: string;
begin
  fBaseURI := Req.fBaseURI;
  fRequestID := Req.fRequestID;
  fAuth := Req.fAuth;
  SetLength(fResParams, length(ResParams));
  for c := low(ResParams) to high(ResParams) do
    fResParams[c] := ResParams[c];
  fMethod := Method;
  fDataStream := Data;
  fContentType := ContentType;
  if assigned(QueryParams) then
  begin
    fQueryParams := TQueryParams.Create;
    for key in QueryParams.Keys do
      fQueryParams.Add(key, QueryParams.Items[key]);
  end;
  fTokenMode := TokenMode;
  fOnResponse := OnResponse;
  fOnRequestError := OnRequestError;
  fOnSuccess := OnSuccess;
end;

destructor TResendRequest.Destroy;
begin
  if assigned(fData) then
    fData.Free;
  if assigned(fQueryParams) then
    fQueryParams.Free;
  inherited;
end;

{ TFirestoreRequest }

constructor TFirebaseRequest.Create(const BaseURI, RequestID: string;
  Auth: IFirebaseAuthentication);
begin
  inherited Create;
  fBaseURI := BaseURI;
  fRequestID := RequestID;
  fAuth := Auth;
end;

function TFirebaseRequest.InternalSendRequestSynchronous(
  ResourceParams: TRequestResourceParam; Method: TRESTRequestMethod;
  Data: TStream; ContentType: TRESTContentType;
  QueryParams: TQueryParams;
  TokenMode: TTokenMode): IFirebaseResponse;
var
  Client: THTTPClient;
  LResp: IHTTPResponse;
  URL: string;
begin
  Client := THTTPClient.Create;
  try
    Client.ContentType := ContentTypeToString(ContentType);
    if assigned(fAuth) and (TokenMode = tmBearer) and fAuth.Authenticated then
      Client.CustomHeaders['Authorization'] := 'Bearer ' + EncodeToken;
    URL := fBaseURI + TFirebaseHelpers.EncodeResourceParams(ResourceParams);
    if TokenMode = tmAuthParam then
      URL := URL + TFirebaseHelpers.EncodeQueryParamsWithToken(QueryParams,
        EncodeToken)
    else
      URL := URL + TFirebaseHelpers.EncodeQueryParams(QueryParams);
    {$IFDEF DEBUG}
    TFirebasehelpers.Log('FirebaseRequest.InternalSendRequestSynchronous ' +
      GetEnumName(TypeInfo(TRESTRequestMethod), ord(Method)) + ': ' + URL);
    {$ENDIF}
    case Method of
      rmPut:
        LResp := Client.Put(URL, Data);
      rmPost:
        LResp := Client.Post(URL, Data);
      rmPatch:
        LResp := Client.Patch(URL, Data);
      rmGet:
        LResp := Client.Get(URL);
      rmDelete:
        LResp := Client.Delete(URL);
    end;
    result := TFirebaseResponse.Create(LResp);
    {$IFDEF DEBUG}
    if not result.StatusOk then
    begin
      TFirebaseHelpers.Log(
        'FirebaseRequest.InternalSendRequestSynchronous failed: ' +
        IntToStr(result.StatusCode) + ' / ' + result.StatusText);
      TFirebaseHelpers.Log('  Content from ' + URL);
      TFirebaseHelpers.Log('  > ' + result.ContentAsString);
    end;
    {$ENDIF}
  finally
    Client.Free;
  end;
end;

procedure TFirebaseRequest.InternalSendRequest(
  ResourceParams: TRequestResourceParam; Method: TRESTRequestMethod;
  Data: TJSONValue; QueryParams: TQueryParams; TokenMode: TTokenMode;
  OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
  OnSuccess: TOnSuccess);
var
  Client: TRestClient;
  Request: TRestRequest;
  Response: TRESTResponse;
  RequestID: string;
begin
  Client := TRestClient.Create(fBaseURI);
  Request := TRestRequest.Create(Client);
  Response := TRESTResponse.Create(Client);
  Request.OnAfterExecute := RESTRequestAfterExecute;
  Request.OnHTTPProtocolError := RESTRequestHTTPProtocolError;
  Request.Client := Client;
  Request.Method := Method;
  Request.Response := Response;
  if assigned(fAuth) and (TokenMode = tmBearer) and fAuth.Authenticated then
    Request.AddAuthParameter('Authorization', 'Bearer ' + EncodeToken,
      pkHTTPHEADER, [poDoNotEncode]);
  if Data <> nil then
    Request.Body.Add(Data.ToJSON, TRESTContentType.ctAPPLICATION_JSON);
  if assigned(fAuth) and (TokenMode = tmAuthParam) and fAuth.Authenticated then
    Request.Resource := TFirebaseHelpers.EncodeResourceParams(ResourceParams) +
      TFirebaseHelpers.EncodeQueryParamsWithToken(QueryParams, EncodeToken)
  else
    Request.Resource := TFirebaseHelpers.EncodeResourceParams(ResourceParams) +
      TFirebasehelpers.EncodeQueryParams(QueryParams);
  Request.URLAlreadyEncoded := true;
  {$IFDEF DEBUG}
  TFirebasehelpers.Log('FirebaseRequest.InternalSendRequest ' +
    GetEnumName(TypeInfo(TRESTRequestMethod), ord(Request.Method)) + ': ' +
    Request.GetFullRequestURL(true));
  {$ENDIF}
  RequestID := fRequestID;
  Request.ExecuteAsync(
    procedure // Completion Handler
    begin
      try
        try
          if assigned(OnResponse) and not TFirebaseHelpers.AppIsTerminated then
            OnResponse(RequestID, TFirebaseResponse.Create(Response,
              OnRequestError, OnSuccess));
        except
          on e: exception do
            if assigned(OnRequestError) then
              OnRequestError(RequestID, e.Message)
            else
              TFirebaseHelpers.LogFmt(
                'Exception in FirebaseRequest.InternalSendRequest %s: %s',
                [RequestID, e.Message]);
        end;
      finally
        FreeAndNil(Response);
        FreeAndNil(Request);
        FreeAndNil(Client);
      end;
    end,
    true, true,
    procedure(Obj: TObject) // Error Handler
    begin
      try
        if Assigned(Obj) and (Obj is Exception) and assigned(OnRequestError) then
        begin
          {$IFDEF MSWINDOWS}
          if (Pos('(12030)', Exception(Obj).Message) > 1) or
             (Pos('(12007)', Exception(Obj).Message) > 1) then
            // Misleading error message from WinAPI
            // 12030: ERROR_INTERNET_CONNECTION_ABORTED
            // "The connection with the server has been terminated."
            // German "Die Serververbindung wurde aufgrund eines Fehlers beendet."
            // 12007: ERROR_INTERNET_NAME_NOT_RESOLVED
            OnRequestError(RequestID, rsConnectionToServerBroken)
          else
          {$ENDIF}
          OnRequestError(RequestID, Exception(Obj).Message);
        end;
      finally
        FreeAndNil(Response);
        FreeAndNil(Request);
        FreeAndNil(Client);
      end;
    end
  );
end;

procedure TFirebaseRequest.InternalSendRequest(
  ResourceParams: TRequestResourceParam; Method: TRESTRequestMethod;
  Data: TStream; ContentType: TRESTContentType; QueryParams:TQueryParams;
  TokenMode: TTokenMode; OnResponse: TOnFirebaseResp;
  OnRequestError: TOnRequestError; OnSuccess: TOnSuccess);
var
  Client: TRestClient;
  Request: TRestRequest;
  Response: TRESTResponse;
  RequestID: string;
begin
  Client := TRestClient.Create(fBaseURI);
  Request := TRestRequest.Create(Client);
  Response := TRESTResponse.Create(Client);
  Request.OnAfterExecute := RESTRequestAfterExecute;
  Request.OnHTTPProtocolError := RESTRequestHTTPProtocolError;
  Request.Client := Client;
  Request.Method := Method;
  Request.Response := Response;
  if assigned(fAuth) and (TokenMode = tmBearer) and fAuth.Authenticated then
    Request.AddAuthParameter('Authorization', 'Bearer ' + EncodeToken,
      pkHTTPHEADER, [poDoNotEncode]);
  if Data <> nil then
    Request.AddBody(Data, ContentType);
  if TokenMode = tmAuthParam then
    Request.Resource := TFirebaseHelpers.EncodeResourceParams(ResourceParams) +
      TFirebaseHelpers.EncodeQueryParamsWithToken(QueryParams, EncodeToken)
  else
    Request.Resource := TFirebaseHelpers.EncodeResourceParams(ResourceParams) +
      TFirebasehelpers.EncodeQueryParams(QueryParams);
  Request.URLAlreadyEncoded := true;
  {$IFDEF DEBUG}
  TFirebasehelpers.Log('FirebaseRequest.InternalSendRequest ' +
    GetEnumName(TypeInfo(TRESTRequestMethod), ord(Request.Method)) + ': ' +
    Request.GetFullRequestURL(true));
  {$ENDIF}
  RequestID := fRequestID;
  Request.ExecuteAsync(
    procedure // Completion Handler
    begin
      try
        try
          if assigned(OnResponse) and not TFirebaseHelpers.AppIsTerminated then
            OnResponse(RequestID, TFirebaseResponse.Create(Response,
              OnRequestError, OnSuccess));
        except
          on e: exception do
            if assigned(OnRequestError) then
              OnRequestError(RequestID, e.Message)
            else
              TFirebaseHelpers.LogFmt(
                'Exception in FirebaseRequest.InternalSendRequest %s: %s',
                [RequestID, e.Message]);
        end;
      finally
        FreeAndNil(Response);
        FreeAndNil(Request);
        FreeAndNil(Client);
      end;
    end,
    true, true,
    procedure(Obj: TObject) // Error Handler
    begin
      try
        if Assigned(Obj) and (Obj is Exception) and assigned(OnRequestError) then
          OnRequestError(RequestID, Exception(Obj).Message);
      finally
        FreeAndNil(Response);
        FreeAndNil(Request);
        FreeAndNil(Client);
      end;
    end
  );
end;

function TFirebaseRequest.SendRequestSynchronous(
  ResourceParams: TRequestResourceParam;
  Method: TRESTRequestMethod; Data: TJSONValue;
  QueryParams: TQueryParams;
  TokenMode: TTokenMode): IFirebaseResponse;
var
  SourceStr: TStringStream;
begin
  SourceStr := nil;
  if Data <> nil then
    SourceStr := TStringStream.Create(Data.ToJSON);
  try
    result := SendRequestSynchronous(ResourceParams, Method, SourceStr,
      TRESTContentType.ctAPPLICATION_JSON, QueryParams, TokenMode);
  finally
    if Assigned(SourceStr) then
      SourceStr.Free;
  end;
end;

function TFirebaseRequest.SendRequestSynchronous(
  ResourceParams: TRequestResourceParam; Method: TRESTRequestMethod;
  Data: TStream; ContentType: TRESTContentType;
  QueryParams: TQueryParams;
  TokenMode: TTokenMode): IFirebaseResponse;
var
  StartPos: Int64;
begin
  if assigned(Data) then
    StartPos := Data.Position
  else
    StartPos := -1;
  result := InternalSendRequestSynchronous(ResourceParams, Method, Data,
    ContentType, QueryParams, TokenMode);
  if (TokenMode > tmNoToken) and result.StatusIsUnauthorized then
    if assigned(fAuth) and fAuth.CheckAndRefreshTokenSynchronous then
    begin
      if assigned(Data) and (StartPos >= 0) then
        Data.Position := StartPos;
      // Repeat once with fresh token
      result := InternalSendRequestSynchronous(ResourceParams, Method, Data,
        ContentType, QueryParams, TokenMode);
    end;
end;

procedure TFirebaseRequest.RESTRequestAfterExecute(Sender: TCustomRESTRequest);
begin
  {$IFNDEF VER320} // In DE 10.1 and former this leads to an AV
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirebaseRequest.RESTRequestAfterExecute ' +
    GetEnumName(TypeInfo(TRESTRequestMethod), ord(Sender.Method)) + ': ' +
    Sender.GetFullRequestURL(true));
  {$ENDIF}
  {$ENDIF}
end;

procedure TFirebaseRequest.RESTRequestHTTPProtocolError(
  Sender: TCustomRESTRequest);
begin
  TFirebaseHelpers.Log('FirebaseRequest.RESTRequestHTTPProtocolError ' +
    Sender.Response.StatusText);
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('  Details: ' +
    Sender.Response.Content.Replace(#13, '').Replace(#10, '').Replace(' ', ''));
  TFirebaseHelpers.Log('  Request: ' +
    GetEnumName(TypeInfo(TRESTRequestMethod), ord(Sender.Method)) + ': ' +
    Sender.GetFullRequestURL);
  {$ENDIF}
end;

procedure TFirebaseRequest.SendRequest(ResourceParams: TRequestResourceParam;
  Method: TRESTRequestMethod; Data: TJSONValue; QueryParams: TQueryParams;
  TokenMode: TTokenMode; OnResponse: TOnFirebaseResp;
  OnRequestError: TOnRequestError; OnSuccess: TOnSuccess);
begin
  if (TokenMode > tmNoToken) and assigned(fAuth) and fAuth.NeedTokenRefresh then
  begin
    // Captured entire parameters for later send request
    fResendRequest := TResendRequest.Create(self, ResourceParams,
      Method, Data, QueryParams, TokenMode, OnResponse, OnRequestError,
      OnSuccess);
    fAuth.RefreshToken(SendRequestAfterTokenRefresh, OnRequestError);
  end else
    InternalSendRequest(ResourceParams, Method, Data, QueryParams, TokenMode,
      OnResponse, OnRequestError, OnSuccess);
end;

procedure TFirebaseRequest.SendRequest(ResourceParams: TRequestResourceParam;
  Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
  QueryParams: TQueryParams; TokenMode: TTokenMode;
  OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
  OnSuccess: TOnSuccess);
begin
  if (TokenMode > tmNoToken) and assigned(fAuth) and fAuth.NeedTokenRefresh then
  begin
    // Captured entire parameters for later send request
    fResendRequest := TResendRequest.Create(self, ResourceParams,
      Method, Data, ContentType, QueryParams, TokenMode, OnResponse,
      OnRequestError, OnSuccess);
    fAuth.RefreshToken(SendStreamRequestAfterTokenRefresh, OnRequestError);
  end else
    InternalSendRequest(ResourceParams, Method, Data, ContentType, QueryParams,
      TokenMode, OnResponse, OnRequestError, OnSuccess);
end;

procedure TFirebaseRequest.SendRequestAfterTokenRefresh(
  TokenRefreshed: boolean);
var
  Request: TFirebaseRequest;
begin
  if TokenRefreshed and assigned(fResendRequest) then
  begin
    with fResendRequest do
    begin
      Request := TFirebaseRequest.Create(BaseURI, RequestID, Auth);
      try
        Request.InternalSendRequest(ResParams, Method, Data, QueryParams,
          TokenMode, OnResponse, OnRequestError, OnSuccess);
      finally
        Request.Free;
      end;
    end;
    FreeAndNil(fResendRequest);
  end
  else if assigned(fResendRequest.OnRequestError) then
    fResendRequest.OnRequestError(fRequestID, rsTokenRefreshFailed);
end;

procedure TFirebaseRequest.SendStreamRequestAfterTokenRefresh(
  TokenRefreshed: boolean);
var
  Request: TFirebaseRequest;
begin
  if TokenRefreshed and assigned(fResendRequest) then
  begin
    with fResendRequest do
    begin
      Request := TFirebaseRequest.Create(BaseURI, RequestID, Auth);
      try
        Request.InternalSendRequest(ResParams, Method, DataStream, ContentType,
          QueryParams, TokenMode, OnResponse, OnRequestError, OnSuccess);
      finally
        Request.Free;
      end;
    end;
    FreeAndNil(fResendRequest);
  end
  else if assigned(fResendRequest.OnRequestError) then
    fResendRequest.OnRequestError(fRequestID, rsTokenRefreshFailed);
end;

function TFirebaseRequest.EncodeToken: string;
begin
  if assigned(fAuth) then
    result := TNetEncoding.URL.Encode(fAuth.Token)
  else
    result := '';
end;

end.
