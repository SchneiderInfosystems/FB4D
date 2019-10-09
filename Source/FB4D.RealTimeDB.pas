{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2019 Christoph Schneider                                 }
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
  FB4D.Interfaces;

type
  TRealTimeDB = class;
  TFirebaseEvent = class(TInterfacedObject, IFirebaseEvent)
  private
    fFirebase: TRealTimeDB;
    fResourceParams: TRequestResourceParam;
    fIsStopped: boolean;
    constructor Create(Firebase: TRealTimeDB;
      ResourceParams: TRequestResourceParam);
  public
    procedure StopListening(const NodeName: string = '';
      MaxTimeOutInMS: cardinal = 500);
    function GetResourceParams: TRequestResourceParam;
    function IsStopped: boolean;
  end;

  TRealTimeDB = class(TInterfacedObject, IRealTimeDB)
  private
    fBaseURL: string;
    fAuth: IFirebaseAuthentication;
    // For ListenForValueEvents
    fThread: TThread;
    fClient: THTTPClient;
    fStream: TMemoryStream;
    fReadPos: Int64;
    fOnGetValue, fOnPutValue, fOnPostValue, fOnPatchValue: TOnGetValue;
    fOnDelete: TOnDelete;
    fOnListenEvent: TOnReceiveEvent;
    fOnGetError, fOnPutError, fOnPostError, fOnPatchError, fOnDeleteError,
    fOnListenError, fOnGetServerVarError: TOnRequestError;
    fOnServerVariable: TOnServerVariable;
    fLastKeepAliveMsg: TDateTime;
    fRequireTokenRenew: boolean;
    fStopWaiting: boolean;
    fListenPartialResp: string;
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
      Data: TJSONValue = nil; QueryParams: TQueryParams = nil;
      OnResponse: TOnResponse = nil; OnRequestError: TOnRequestError = nil);
    procedure OnResponse(const RequestID: string;
      Response: IFirebaseResponse; OnValue: TOnGetValue;
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
    procedure OnServerVarResp(const VarName: string; Resp: IFirebaseResponse);
    procedure OnRecData(const Sender: TObject; ContentLength,
      ReadCount: Int64; var Abort: Boolean);
    procedure InitListen;
  public
    constructor Create(const ProjectID: string; Auth: IFirebaseAuthentication);
    procedure Get(ResourceParams: TRequestResourceParam; OnGetValue: TOnGetValue;
      OnRequestError: TOnRequestError; QueryParams: TQueryParams = nil);
    function GetSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams = nil): TJSONValue;
    procedure Put(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPutValue: TOnGetValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PutSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue;
    procedure Post(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPostValue: TOnGetValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PostSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue;
    procedure Patch(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPatchValue: TOnGetValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PatchSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue;
    procedure Delete(ResourceParams: TRequestResourceParam;
      OnDelete: TOnDelete; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function DeleteSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams = nil): boolean;
    function ListenForValueEvents(ResourceParams: TRequestResourceParam;
      ListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
      OnError: TOnRequestError;
      OnAuthRevoked: TOnAuthRevokedEvent = nil): IFirebaseEvent;
    function GetLastKeepAliveTimeStamp: TDateTime;
    procedure GetServerVariables(const ServerVarName: string;
      ResourceParams: TRequestResourceParam;
      OnServerVariable: TOnServerVariable = nil; OnError: TOnRequestError = nil);
    function GetServerVariablesSynchronous(const ServerVarName: string;
      ResourceParams: TRequestResourceParam): TJSONValue;
  end;

implementation

uses
  FB4D.Helpers, FB4D.Request;

const
  GOOGLE_FIREBASE = 'https://%s.firebaseio.com';

resourcestring
  rsEvtListenerFailed = 'Event listener for %s failed: %s';
  rsEvtStartFailed = 'Event listener start for %s failed: %s';
  rsEvtParserFailed = 'Exception in event parser';

{ TFirebase }

constructor TRealTimeDB.Create(const ProjectID: string;
  Auth: IFirebaseAuthentication);
begin
  inherited Create;
  Assert(assigned(Auth), 'Authentication not initalized');
  fBaseURL := Format(GOOGLE_FIREBASE, [ProjectID]);
  fAuth := Auth;
  InitListen;
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
  Data: TJSONValue; QueryParams: TQueryParams; OnResponse: TOnResponse;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(fBaseURL, RequestID, fAuth);
  Request.SendRequest(AddJSONExtToRequest(ResourceParams), Method, Data,
    QueryParams, tmAuthParam, OnResponse, OnRequestError);
end;

procedure TRealTimeDB.Get(ResourceParams: TRequestResourceParam;
  OnGetValue: TOnGetValue; OnRequestError: TOnRequestError; QueryParams: TQueryParams);
begin
  fOnGetValue := OnGetValue;
  fOnGetError := OnRequestError;
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmGet, nil, QueryParams, OnGetResponse, OnRequestError);
end;

procedure TRealTimeDB.OnResponse(const RequestID: string;
  Response: IFirebaseResponse; OnValue: TOnGetValue; OnError: TOnRequestError);
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
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
    end;
  end;
  Val.Free;
end;

procedure TRealTimeDB.OnGetResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, fOnGetValue, fOnGetError);
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
  Data: TJSONValue; OnPutValue: TOnGetValue; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams);
begin
  fOnPutValue := OnPutValue;
  fOnPutError := OnRequestError;
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmPut, Data, QueryParams, OnPutResponse, OnRequestError);
end;

procedure TRealTimeDB.OnPutResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, fOnPutValue, fOnPutError);
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
  Data: TJSONValue; OnPostValue: TOnGetValue; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams = nil);
begin
  fOnPostValue := OnPostValue;
  fOnPostError := OnRequestError;
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmPost, Data, QueryParams, OnPostResponse, OnRequestError);
end;

procedure TRealTimeDB.OnPostResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, fOnPostValue, fOnPostError);
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
  Data: TJSONValue; OnPatchValue: TOnGetValue; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams = nil);
begin
  fOnPatchValue := OnPatchValue;
  fOnPatchError := OnRequestError;
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
    rmPatch, Data, QueryParams, OnPatchResponse, OnRequestError);
end;

procedure TRealTimeDB.OnPatchResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  OnResponse(RequestID, Response, fOnPatchValue, fOnPatchError);
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

procedure TRealTimeDB.Delete(ResourceParams: TRequestResourceParam;
  OnDelete: TOnDelete; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams);
begin
  fOnDelete := OnDelete;
  fOnDeleteError := OnRequestError;
  SendRequest(TFirebaseHelpers.ArrStrToCommaStr(ResourceParams), ResourceParams,
   rmDelete, nil, QueryParams, OnDeleteResponse, OnRequestError);
end;

procedure TRealTimeDB.OnDeleteResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  if Response.StatusOk then
  begin
    if assigned(fOnDelete) then
      fOnDelete(SplitString(RequestID, ','), true)
  end else
  if Response.StatusNotFound then
  begin
    if assigned(fOnDelete) then
      fOnDelete(SplitString(RequestID, ','), false)
  end
  else if assigned(fOnDeleteError) then
    fOnDeleteError(RequestID, Response.ErrorMsgOrStatusText)
  else
    TFirebaseHelpers.Log(Format(rsFBFailureIn,
      [RequestID, Response.ErrorMsgOrStatusText]));
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
  ResourceParams: TRequestResourceParam; OnServerVariable: TOnServerVariable;
  OnError: TOnRequestError);
var
  Data: TJSONObject;
begin
  fOnServerVariable := OnServerVariable;
  fOnGetServerVarError := OnError;
  Data := TJSONObject.Create(TJSONPair.Create('.sv', ServerVarName));
  try
    SendRequest(ServerVarName, ResourceParams, rmPut, Data, nil,
      OnServerVarResp, OnError);
  finally
    Data.Free;
  end;
end;

procedure TRealTimeDB.OnServerVarResp(const VarName: string;
  Resp: IFirebaseResponse);
var
  Val: TJSONValue;
begin
  try
    if resp.StatusOk then
    begin
      Val := resp.GetContentAsJSONVal;
      try
        if assigned(fOnServerVariable) then
          fOnServerVariable(VarName, Val);
      finally
        Val.Free;
      end;
    end else if assigned(fOnGetServerVarError) then
    begin
      if not resp.ErrorMsg.IsEmpty then
        fOnGetServerVarError(Varname, resp.ErrorMsg)
      else
        fOnGetServerVarError(Varname, resp.StatusText);
    end;
  except
    on e: exception do
      if assigned(fOnGetServerVarError) then
        fOnGetServerVarError(Varname, e.Message)
      else
        TFirebaseHelpers.Log('Exception in OnServerVarResp: ' + e.Message);
  end;
end;

procedure TRealTimeDB.InitListen;
begin
  fThread := nil;
  fClient := nil;
  fStream := nil;
  fReadPos := 0;
  fLastKeepAliveMsg := 0;
  fRequireTokenRenew := false;
  fStopWaiting := false;
end;

function TRealTimeDB.ListenForValueEvents(ResourceParams: TRequestResourceParam;
  ListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
  OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent): IFirebaseEvent;
var
  URL: string;
  Info, ErrMsg: string;
begin
  InitListen;
  URL := fBaseURL + TFirebaseHelpers.EncodeResourceParams(ResourceParams) +
    cJSONExt;
  Info :=  TFirebaseHelpers.ArrStrToCommaStr(ResourceParams);
  fOnListenEvent := ListenEvent;
  fOnListenError := OnError;
  fListenPartialResp := '';
  fClient := THTTPClient.Create;
  fClient.HandleRedirects := true;
  fClient.Accept := 'text/event-stream';
  fClient.OnReceiveData := OnRecData;
  fThread := TThread.CreateAnonymousThread(
    procedure
    var
      Resp: IHTTPResponse;
    begin
      fStream := TMemoryStream.Create;
      try
        while not TThread.CurrentThread.CheckTerminated and not fStopWaiting do
        begin
          fReadPos := 0;
          if fRequireTokenRenew then
          begin
            if assigned(fAuth) and fAuth.CheckAndRefreshTokenSynchronous then
              fRequireTokenRenew := false;
            if assigned(OnAuthRevoked) then
              TThread.Queue(nil,
                procedure
                begin
                  OnAuthRevoked(not fRequireTokenRenew);
                end);
          end;
          Resp := fClient.Get(URL + TFirebaseHelpers.EncodeToken(fAuth.Token),
            fStream);
          if (Resp.StatusCode < 200) or (Resp.StatusCode >= 300) then
          begin
            ErrMsg := Resp.StatusText;
            if assigned(fOnListenError) then
            begin
              TThread.Queue(nil,
                procedure
                begin
                  fOnListenError(Info, ErrMsg);
                end)
            end else
              TFirebaseHelpers.Log(Format(rsEvtStartFailed, [Info, ErrMsg]));
            fStopWaiting := true;
          end;
          // reopen stream
          fStream.Free;
          fStream := TMemoryStream.Create;
        end;
      except
        on e: exception do
          if assigned(fOnListenError) then
          begin
            ErrMsg := e.Message;
            TThread.Queue(nil,
              procedure
              begin
                fOnListenError(Info, ErrMsg);
              end)
          end else
            TFirebaseHelpers.Log(Format(rsEvtListenerFailed, [Info, e.Message]));
      end;
      FreeAndNil(fStream);
      FreeAndNil(fClient);
      fThread := nil;
    end);
  fThread.OnTerminate := OnStopListening;
  fThread.NameThreadForDebugging('FB4D.RTDB.ListenEvent', fThread.ThreadID);
  fThread.FreeOnTerminate := true;
  fThread.Start;
  result := TFirebaseEvent.Create(Self, ResourceParams);
end;

procedure TRealTimeDB.OnRecData(const Sender: TObject; ContentLength: Int64;
  ReadCount: Int64; var Abort: Boolean);

  function GetParams(Request: IURLRequest): TRequestResourceParam;
  var
    Path: string;
  begin
    Path := Request.URL.Path;
    if Path.StartsWith('/') then
      Path := Path.SubString(1);
    if Path.EndsWith(cJSONExt) then
      Path := Path.Remove(Path.Length - cJSONExt.Length);
    result := SplitString(Path, '/');
  end;

const
  cEvent = 'event: ';
  cData = 'data: ';
  cKeepAlive = 'keep-alive';
  cRevokeToken = 'auth_revoked';
{$IFDEF MACOS}
var
  Params: TRequestResourceParam;
  ErrMsg: string;
begin
  try
    if assigned(fStream) then
    begin
      if fStopWaiting then
        Abort := true
      else begin
        Abort := false;
        Params := GetParams(Sender as TURLRequest);
        TThread.Queue(nil,
          procedure
          var
            ss: TStringStream;
            Lines: TArray<string>;
            EventName, Data: string;
            JSONObj: TJSONObject;
          begin
            ss := TStringStream.Create;
            try
              Assert(fReadPos >= 0, 'Invalid stream read position');
              Assert(ReadCount - fReadPos >= 0, 'Invalid stream read count');
              fStream.Position := fReadPos;
              if ReadCount - fReadPos > 0 then
              begin
                // On Mac OS a 'Stream read error' will be thrown inside
                // TStream.ReadBuffer if this code is in the main thread
                ss.CopyFrom(fStream, ReadCount - fReadPos);
                fListenPartialResp := fListenPartialResp + ss.DataString;
              end;
              Lines := fListenPartialResp.Split([#10]);
            finally
              ss.Free;
            end;
            fReadPos := ReadCount;
            if (length(Lines) >= 2) and (Lines[0].StartsWith(cEvent)) then
            begin
              EventName := Lines[0].Substring(length(cEvent));
              if Lines[1].StartsWith(cData) then
                Data := Lines[1].Substring(length(cData))
              else begin
                // resynch
                Data := '';
                fListenPartialResp := '';
              end;
              if EventName = cKeepAlive then
              begin
                fLastKeepAliveMsg := now;
                fListenPartialResp := '';
              end
              else if EventName = cRevokeToken then
              begin
                fRequireTokenRenew := true;
                fListenPartialResp := '';
                fStopWaiting := true;
              end else if Data.Length > 0 then
              begin
                JSONObj := TJSONObject.ParseJSONValue(Data) as TJSONObject;
                if assigned(JSONObj) then
                try
                  fListenPartialResp := '';
                  fOnListenEvent(EventName, Params, JSONObj);
                finally
                  JSONObj.Free;
                end;
              end;
            end;
          end);
      end;
    end else
      Abort := true;
  except
    on e: Exception do
    begin
      ErrMsg := e.Message;
      if assigned(fOnListenError) then
        TThread.Queue(nil,
          procedure
          begin
            fOnListenError(rsEvtParserFailed, ErrMsg)
          end)
      else
        TFirebaseHelpers.Log(rsEvtParserFailed + ': ' + ErrMsg);
    end;
  end;
end;
{$ELSE}
var
  ss: TStringStream;
  Lines: TArray<string>;
  EventName, Data, ErrMsg: string;
  Params: TRequestResourceParam;
  JSONObj: TJSONObject;
begin
  try
    if assigned(fStream) then
    begin
      if fStopWaiting then
        Abort := true
      else begin
        Abort := false;
        Params := GetParams(Sender as TURLRequest);
        ss := TStringStream.Create;
        try
          Assert(fReadPos >= 0, 'Invalid stream read position');
          Assert(ReadCount - fReadPos >= 0, 'Invalid stream read count: ' +
            ReadCount.ToString + ' - ' + fReadPos.ToString);
          fStream.Position := fReadPos;
          ss.CopyFrom(fStream, ReadCount - fReadPos);
          fListenPartialResp := fListenPartialResp + ss.DataString;
          Lines := fListenPartialResp.Split([#10]);
        finally
          ss.Free;
        end;
        fReadPos := ReadCount;
        if (length(Lines) >= 2) and (Lines[0].StartsWith(cEvent)) then
        begin
          EventName := Lines[0].Substring(length(cEvent));
          if Lines[1].StartsWith(cData) then
            Data := Lines[1].Substring(length(cData))
          else begin
            // resynch
            Data := '';
            fListenPartialResp := '';
          end;
          if EventName = cKeepAlive then
          begin
            fLastKeepAliveMsg := now;
            fListenPartialResp := '';
          end
          else if EventName = cRevokeToken then
          begin
            fRequireTokenRenew := true;
            fListenPartialResp := '';
            Abort := true;
          end else if Data.Length > 0 then
          begin
            JSONObj := TJSONObject.ParseJSONValue(Data) as TJSONObject;
            if assigned(JSONObj) then
            begin
              fListenPartialResp := '';
              TThread.Queue(nil,
                procedure
                begin
                  fOnListenEvent(EventName, Params, JSONObj);
                  JSONObj.Free;
                end);
            end;
          end;
        end;
      end;
    end else
      Abort := true;
  except
    on e: Exception do
    begin
      ErrMsg := e.Message;
      if assigned(fOnListenError) then
        TThread.Queue(nil,
          procedure
          begin
            fOnListenError(rsEvtParserFailed, ErrMsg)
          end)
      else
        TFirebaseHelpers.Log(rsEvtParserFailed + ': ' + ErrMsg);
    end;
  end;
end;
{$ENDIF}

function TRealTimeDB.GetLastKeepAliveTimeStamp: TDateTime;
begin
  result := fLastKeepAliveMsg;
end;

{ TFirebaseEvent }

constructor TFirebaseEvent.Create(Firebase: TRealTimeDB;
  ResourceParams: TRequestResourceParam);
begin
  fFirebase := Firebase;
  fResourceParams := ResourceParams;
  fIsStopped := false;
end;

function TFirebaseEvent.GetResourceParams: TRequestResourceParam;
begin
  result := fResourceParams;
end;

function TFirebaseEvent.IsStopped: boolean;
begin
  result := fIsStopped;
end;

procedure TFirebaseEvent.StopListening(const NodeName: string;
  MaxTimeOutInMS: cardinal);
var
  Timeout: cardinal;
begin
  fIsStopped := true;
  try
    if assigned(fFirebase.fThread) then
    begin
      fFirebase.fStopWaiting := true;
      // Workaround because of bug/Change request:
      // https://quality.embarcadero.com/browse/RSP-20827
      // Use side effect of GetServerTime
      if NodeName.IsEmpty then
        fFirebase.GetServerVariables(cServerVariableTimeStamp, fResourceParams)
      else
        fFirebase.GetServerVariables(cServerVariableTimeStamp,
          TFirebaseHelpers.AddParamToResParams(fResourceParams, NodeName));
      Timeout := MaxTimeOutInMS;
      while assigned(fFirebase) and assigned(fFirebase.fThread) and
        (Timeout > 0) do
      begin
        TFirebaseHelpers.SleepAndMessageLoop(1);
        dec(Timeout);
      end;
      if assigned(fFirebase) and assigned(fFirebase.fThread) then
      begin
        TFirebaseHelpers.Log(
          'Hard stop of listener thread because of lost connection');
        fFirebase.fThread.Terminate;
      end;
    end;
  except
    on e: exception do
      TFirebaseHelpers.Log('Exception in StopListening: ' + e.Message);
  end;
end;

end.
