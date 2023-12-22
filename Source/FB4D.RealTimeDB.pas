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

unit FB4D.RealTimeDB;

interface

uses
  System.Types, System.Classes, System.SysUtils, System.StrUtils, System.JSON,
  System.NetConsts, System.Net.HttpClient, System.Net.URLClient,
  System.NetEncoding, System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.RealTimeDB.Listener;

type
  TFirebaseEvent = class(TInterfacedObject, IFirebaseEvent)
  private
    fListener: TRTDBListenerThread;
    constructor Create(Listener: TRTDBListenerThread);
  public
    destructor Destroy; override;
    procedure StopListening(MaxTimeOutInMS: cardinal = 500); overload;
    procedure StopListening(const NodeName: string;
      MaxTimeOutInMS: cardinal = 500); overload; { deprecated }
    function GetResourceParams: TRequestResourceParam;
    function GetLastReceivedMsg: TDateTime;
    function IsStopped: boolean;
  end;

  TRealTimeDB = class(TInterfacedObject, IRealTimeDB)
  private
    fBaseURL: string;
    fAuth: IFirebaseAuthentication;
    const
      cJSONExt = '.json';
    function AddJSONExtToRequest(ResourceParams: TRequestResourceParam):
      TRequestResourceParam;
    function SendRequestSynchronous(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue = nil;
      QueryParams: TQueryParams = nil): IFirebaseResponse;
    function RespSynchronous(Response: IFirebaseResponse): TJSONValue;
    procedure SendRequest(const RequestID: string;
      ResourceParams: TRequestResourceParam; Method: TRESTRequestMethod;
      Data: TJSONValue; QueryParams: TQueryParams; OnResponse: TOnFirebaseResp;
      OnRequestError: TOnRequestError; OnSuccess: TOnSuccess);
    procedure OnResponse(const RequestID: string;
      Response: IFirebaseResponse; OnValue: TOnRTDBValue;
      OnError: TOnRequestError);
    procedure OnGetResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnPutResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnPostResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnPatchResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnDeleteResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnServerVarResp(const VarName: string;
      Response: IFirebaseResponse);
  public
    constructor Create(const ProjectID: string; Auth: IFirebaseAuthentication); deprecated;
    constructor CreateByURL(const FirebaseURL: string; Auth: IFirebaseAuthentication);
    procedure Get(ResourceParams: TRequestResourceParam;
      OnGetValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function GetSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams = nil): TJSONValue;
    procedure Put(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPutValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PutSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue;
    procedure Post(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPostValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PostSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue;
    procedure Patch(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPatchValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PatchSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue;
    procedure Delete(ResourceParams: TRequestResourceParam;
      OnDelete: TOnRTDBDelete; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil); overload; { deprecated }
    procedure Delete(ResourceParams: TRequestResourceParam;
      OnDelete: TOnRTDBDelete; OnRequestError: TOnRequestError); overload;
    function DeleteSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams = nil): boolean; overload; { deprecated }
    function DeleteSynchronous(ResourceParams: TRequestResourceParam): boolean;
      overload;
    function ListenForValueEvents(ResourceParams: TRequestResourceParam;
      ListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
      OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent = nil;
      OnConnectionStateChange: TOnConnectionStateChange = nil;
      DoNotSynchronizeEvents: boolean = false): IFirebaseEvent;
    procedure GetServerVariables(const ServerVarName: string;
      ResourceParams: TRequestResourceParam;
      OnServerVariable: TOnRTDBServerVariable = nil;
      OnError: TOnRequestError = nil);
    function GetServerVariablesSynchronous(const ServerVarName: string;
      ResourceParams: TRequestResourceParam): TJSONValue;
  end;

const
  GOOGLE_FIREBASE = 'https://%s.firebaseio.com';

implementation

uses
  FB4D.Helpers, FB4D.Request;

resourcestring
rsEvtListenerFailed = 'Event listener for %s failed: %s';
rsEvtStartFailed = 'Event listener start for %s failed: %s';
rsEvtParserFailed = 'Exception in event parser';

{ TFirebase }

constructor TRealTimeDB.Create(const ProjectID: string;
  Auth: IFirebaseAuthentication);
begin
  inherited Create;
  fBaseURL := Format(GOOGLE_FIREBASE, [ProjectID]);
  fAuth := Auth;
end;

constructor TRealTimeDB.CreateByURL(const FirebaseURL: string;
  Auth: IFirebaseAuthentication);
begin
  fBaseURL := FirebaseURL;
  fAuth := Auth;
end;

function TRealTimeDB.AddJSONExtToRequest(
  ResourceParams: TRequestResourceParam): TRequestResourceParam;
var
  c, e: integer;
begin
  e := length(ResourceParams) - 1;
  if e < 0 then
  begin
    SetLength(result, 1);
    result[0] := cJSONExt;
  end else begin
    SetLength(result, e + 1);
    for c := 0 to e - 1 do
      result[c] := ResourceParams[c];
    result[e] := ResourceParams[e] + cJSONExt;
  end;
end;

function TRealTimeDB.SendRequestSynchronous(
  ResourceParams: TRequestResourceParam; Method: TRESTRequestMethod;
  Data: TJSONValue; QueryParams: TQueryParams): IFirebaseResponse;
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(fBaseURL, '', fAuth);
  result := Request.SendRequestSynchronous(AddJSONExtToRequest(ResourceParams),
    Method, Data, QueryParams, tmAuthParam);
end;

procedure TRealTimeDB.SendRequest(const RequestID: string;
  ResourceParams: TRequestResourceParam; Method: TRESTRequestMethod;
  Data: TJSONValue; QueryParams: TQueryParams; OnResponse: TOnFirebaseResp;
  OnRequestError: TOnRequestError; OnSuccess: TOnSuccess);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(fBaseURL, RequestID, fAuth);
  Request.SendRequest(AddJSONExtToRequest(ResourceParams), Method,
    Data, QueryParams, tmAuthParam, OnResponse, OnRequestError, OnSuccess);
end;

procedure TRealTimeDB.Get(ResourceParams: TRequestResourceParam;
  OnGetValue: TOnRTDBValue; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams);
begin
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmGet, nil, QueryParams, OnGetResponse, OnRequestError,
    TOnSuccess.CreateRTDBValue(OnGetValue));
end;

procedure TRealTimeDB.OnResponse(const RequestID: string;
  Response: IFirebaseResponse; OnValue: TOnRTDBValue; OnError: TOnRequestError);
var
  Val: TJSONValue;
begin
  Val := nil;
  try
    if Response.StatusOk then
    begin
      if Response.IsJSONObj then
      begin
        Response.CheckForJSONObj;
        Val := Response.GetContentAsJSONObj;
      end else
        Val := Response.GetContentAsJSONVal;
    end
    else if not Response.StatusNotFound then
      raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
    if assigned(OnValue) then
      OnValue(SplitString(RequestID, ','), Val);
  except
    on e: Exception do
    begin
      if assigned(OnError) then
        OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['RealTimeDB.OnResponse', RequestID, e.Message]);
    end;
  end;
  Val.Free;
end;

procedure TRealTimeDB.OnGetResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, Response.OnSuccess.OnRTDBValue,
    Response.OnError);
end;

function TRealTimeDB.RespSynchronous(Response: IFirebaseResponse): TJSONValue;
begin
  if Response.StatusOk then
  begin
    if Response.IsJSONObj then
    begin
      Response.CheckForJSONObj;
      result := Response.GetContentAsJSONObj;
    end else
      result := Response.GetContentAsJSONVal;
  end
  else if Response.StatusNotFound then
    result := TJSONNull.Create
  else
    raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
end;

function TRealTimeDB.GetSynchronous(ResourceParams: TRequestResourceParam;
  QueryParams: TQueryParams): TJSONValue;
var
  Resp: IFirebaseResponse;
begin
  Resp := SendRequestSynchronous(ResourceParams, rmGet, nil, QueryParams);
  result := RespSynchronous(Resp);
end;

procedure TRealTimeDB.Put(ResourceParams: TRequestResourceParam;
  Data: TJSONValue; OnPutValue: TOnRTDBValue; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams);
begin
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmPut, Data, QueryParams, OnPutResponse, OnRequestError,
    TOnSuccess.CreateRTDBValue(OnPutValue));
end;

procedure TRealTimeDB.OnPutResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, Response.OnSuccess.OnRTDBValue,
    Response.OnError);
end;

function TRealTimeDB.PutSynchronous(ResourceParams: TRequestResourceParam;
  Data: TJSONValue; QueryParams: TQueryParams): TJSONValue;
var
  Resp: IFirebaseResponse;
begin
  Resp := SendRequestSynchronous(ResourceParams, rmPut, Data, QueryParams);
  result := RespSynchronous(Resp);
end;

function TRealTimeDB.PostSynchronous(ResourceParams: TRequestResourceParam;
  Data: TJSONValue; QueryParams: TQueryParams): TJSONValue;
var
  Resp: IFirebaseResponse;
begin
  Resp := SendRequestSynchronous(ResourceParams, rmPost, Data, QueryParams);
  if Resp.StatusOk then
  begin
    if Resp.IsJSONObj then
    begin
      Resp.CheckForJSONObj;
      result := Resp.GetContentAsJSONObj;
    end else
      result := Resp.GetContentAsJSONVal;
  end
  else if Resp.StatusNotFound then
    result := TJSONNull.Create
  else
    raise EFirebaseResponse.Create(Resp.ErrorMsgOrStatusText);
end;

procedure TRealTimeDB.Post(ResourceParams: TRequestResourceParam;
  Data: TJSONValue; OnPostValue: TOnRTDBValue; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams = nil);
begin
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmPost, Data, QueryParams, OnPostResponse, OnRequestError,
    TOnSuccess.CreateRTDBValue(OnPostValue));
end;

procedure TRealTimeDB.OnPostResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, Response.OnSuccess.OnRTDBValue,
    Response.OnError);
end;

function TRealTimeDB.PatchSynchronous(ResourceParams: TRequestResourceParam;
  Data: TJSONValue; QueryParams: TQueryParams): TJSONValue;
var
  Resp: IFirebaseResponse;
begin
  Resp := SendRequestSynchronous(ResourceParams, rmPatch, Data,
    QueryParams);
  result := RespSynchronous(Resp);
end;

procedure TRealTimeDB.Patch(ResourceParams: TRequestResourceParam;
  Data: TJSONValue; OnPatchValue: TOnRTDBValue; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams = nil);
begin
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmPatch, Data, QueryParams, OnPatchResponse, OnRequestError,
    TOnSuccess.CreateRTDBValue(OnPatchValue));
end;

procedure TRealTimeDB.OnPatchResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, Response.OnSuccess.OnRTDBValue,
    Response.OnError);
end;

function TRealTimeDB.DeleteSynchronous(ResourceParams: TRequestResourceParam;
  QueryParams: TQueryParams): boolean;
var
  Resp: IFirebaseResponse;
begin
  Resp := SendRequestSynchronous(ResourceParams, rmDelete, nil,
    QueryParams);
  if Resp.StatusOk then
    result := true
  else if Resp.StatusNotFound then
    result := false
  else
    raise EFirebaseResponse.Create(Resp.ErrorMsgOrStatusText);
end;


function TRealTimeDB.DeleteSynchronous(
  ResourceParams: TRequestResourceParam): boolean;
var
  Resp: IFirebaseResponse;
begin
  Resp := SendRequestSynchronous(ResourceParams, rmDelete, nil, nil);
  if Resp.StatusOk then
    result := true
  else if Resp.StatusNotFound then
    result := false
  else
    raise EFirebaseResponse.Create(Resp.ErrorMsgOrStatusText);
end;

procedure TRealTimeDB.Delete(ResourceParams: TRequestResourceParam;
  OnDelete: TOnRTDBDelete; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams);
begin
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
   rmDelete, nil, QueryParams, OnDeleteResponse, OnRequestError,
   TOnSuccess.CreateRTDBDelete(OnDelete));
end;

procedure TRealTimeDB.Delete(ResourceParams: TRequestResourceParam;
  OnDelete: TOnRTDBDelete; OnRequestError: TOnRequestError);
begin
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
   rmDelete, nil, nil, OnDeleteResponse, OnRequestError,
   TOnSuccess.CreateRTDBDelete(OnDelete));
end;

procedure TRealTimeDB.OnDeleteResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  if Response.StatusOk then
  begin
    if assigned(Response.OnSuccess.OnRTDBDelete) then
      Response.OnSuccess.OnRTDBDelete(SplitString(RequestID, ','), true)
  end else
  if Response.StatusNotFound then
  begin
    if assigned(Response.OnSuccess.OnRTDBDelete) then
      Response.OnSuccess.OnRTDBDelete(SplitString(RequestID, ','), false)
  end
  else if assigned(Response.OnError) then
    Response.OnError(RequestID, Response.ErrorMsgOrStatusText)
  else
    TFirebaseHelpers.LogFmt(rsFBFailureIn,
      ['RealTimeDB.OnDeleteResponse', RequestID, Response.ErrorMsgOrStatusText]);
end;

function TRealTimeDB.GetServerVariablesSynchronous(const ServerVarName: string;
  ResourceParams: TRequestResourceParam): TJSONValue;
var
  Resp: IFirebaseResponse;
  Data: TJSONObject;
begin
  Data := TJSONObject.Create(TJSONPair.Create('.sv', ServerVarName));
  try
    Resp := SendRequestSynchronous(ResourceParams, rmPut, Data, nil);
    if resp.StatusOk then
      result := resp.GetContentAsJSONVal
    else
      result := nil;
  finally
    Data.Free;
  end;
end;

procedure TRealTimeDB.GetServerVariables(const ServerVarName: string;
  ResourceParams: TRequestResourceParam; OnServerVariable: TOnRTDBServerVariable;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
begin
  Data := TJSONObject.Create(TJSONPair.Create('.sv', ServerVarName));
  try
    SendRequest(ServerVarName, ResourceParams, rmPut, Data, nil,
      OnServerVarResp, OnError,
      TOnSuccess.CreateRTDBServerVariable(OnServerVariable));
  finally
    Data.Free;
  end;
end;

procedure TRealTimeDB.OnServerVarResp(const VarName: string;
  Response: IFirebaseResponse);
var
  Val: TJSONValue;
begin
  try
    if Response.StatusOk then
    begin
      Val := Response.GetContentAsJSONVal;
      try
        if assigned(Response.OnSuccess.OnRTDBServerVariable) then
          Response.OnSuccess.OnRTDBServerVariable(VarName, Val);
      finally
        Val.Free;
      end;
    end else if assigned(Response.OnError) then
    begin
      if not Response.ErrorMsg.IsEmpty then
        Response.OnError(Varname, Response.ErrorMsg)
      else
        Response.OnError(Varname, Response.StatusText);
    end;
  except
    on e: exception do
      if assigned(Response.OnError) then
        Response.OnError(Varname, e.Message)
      else
        TFirebaseHelpers.Log('RealTimeDB.OnServerVarResp Exception ' +
          e.Message);
  end;
end;

function TRealTimeDB.ListenForValueEvents(ResourceParams: TRequestResourceParam;
  ListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
  OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent;
  OnConnectionStateChange: TOnConnectionStateChange;
  DoNotSynchronizeEvents: boolean): IFirebaseEvent;
var
  FirebaseEvent: TFirebaseEvent;
begin
  FirebaseEvent := TFirebaseEvent.Create(
    TRTDBListenerThread.Create(fBaseURL, fAuth));
  FirebaseEvent.fListener.RegisterEvents(ResourceParams, ListenEvent,
    OnStopListening, OnError, OnAuthRevoked, OnConnectionStateChange,
    DoNotSynchronizeEvents);
  FirebaseEvent.fListener.Start;
  result := FirebaseEvent;
end;

{ TFirebaseEvent }

constructor TFirebaseEvent.Create(Listener: TRTDBListenerThread);
begin
  fListener := Listener;
end;

destructor TFirebaseEvent.Destroy;
begin
  if fListener.IsRunning then
    StopListening;
  fListener.Free;
  inherited;
end;

function TFirebaseEvent.GetLastReceivedMsg: TDateTime;
begin
  Assert(assigned(fListener), 'No Listener');
  result := fListener.LastReceivedMsg;
end;

function TFirebaseEvent.GetResourceParams: TRequestResourceParam;
begin
  Assert(assigned(fListener), 'No Listener');
  result := fListener.ResParams;
end;

function TFirebaseEvent.IsStopped: boolean;
begin
  Assert(assigned(fListener), 'No Listener');
  result := fListener.StopWaiting;
end;

procedure TFirebaseEvent.StopListening(MaxTimeOutInMS: cardinal);
begin
  if assigned(fListener) then
    fListener.StopListener(MaxTimeOutInMS);
end;

procedure TFirebaseEvent.StopListening(const NodeName: string;
  MaxTimeOutInMS: cardinal);
begin
  StopListening(MaxTimeOutInMS);
end;

end.
