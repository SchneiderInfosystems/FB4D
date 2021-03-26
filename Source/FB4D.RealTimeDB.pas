{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2021 Christoph Schneider                                 }
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
    fOnListenError: TOnRequestError;
    fOnListenEvent: TOnReceiveEvent;
    fDoNotSynchronizeEvents: boolean;
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
    procedure OnRecData(const Sender: TObject; ContentLength,
      ReadCount: Int64; var Abort: Boolean);
    procedure InitListen;
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
      DoNotSynchronizeEvents: boolean = false): IFirebaseEvent;
    function GetLastKeepAliveTimeStamp: TDateTime;
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
  Assert(assigned(Auth), 'Authentication not initalized');
  fBaseURL := Format(GOOGLE_FIREBASE, [ProjectID]);
  fAuth := Auth;
  InitListen;
end;

constructor TRealTimeDB.CreateByURL(const FirebaseURL: string;
  Auth: IFirebaseAuthentication);
begin
  Assert(assigned(Auth), 'Authentication not initalized');
  fBaseURL := FirebaseURL;
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
  OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent;
  DoNotSynchronizeEvents: boolean): IFirebaseEvent;
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
  fDoNotSynchronizeEvents := DoNotSynchronizeEvents;
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
            if assigned(OnAuthRevoked) and
               not TFirebaseHelpers.AppIsTerminated then
              if DoNotSynchronizeEvents then
                OnAuthRevoked(not fRequireTokenRenew)
              else
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
            if assigned(OnError) then
            begin
              if DoNotSynchronizeEvents then
                OnError(Info, ErrMsg)
              else
                TThread.Queue(nil,
                  procedure
                  begin
                    OnError(Info, ErrMsg);
                  end)
            end else
              TFirebaseHelpers.LogFmt('RealTimeDB.ListenForValueEvents ' +
                rsEvtStartFailed, [Info, ErrMsg]);
            fStopWaiting := true;
          end;
          // reopen stream
          fStream.Free;
          fStream := TMemoryStream.Create;
        end;
      except
        on e: exception do
          if assigned(OnError) then
          begin
            ErrMsg := e.Message;
            if DoNotSynchronizeEvents then
              OnError(Info, ErrMsg)
            else
              TThread.Queue(nil,
                procedure
                begin
                  OnError(Info, ErrMsg);
                end)
          end else
            TFirebaseHelpers.LogFmt('RealTimeDB.ListenForValueEvents ' +
              rsEvtListenerFailed, [Info, e.Message]);
      end;
      FreeAndNil(fStream);
      FreeAndNil(fClient);
      fThread := nil;
    end);
  fThread.OnTerminate := OnStopListening;
  {$IFNDEF LINUX64}
  fThread.NameThreadForDebugging('FB4D.RTDB.ListenEvent', fThread.ThreadID);
  {$ENDIF}
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
{$IFDEF POSIX}
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
        // fDoNotSynchronizeEvents has no effect on Delphi 10.3 and below on
        // Posix systems
        TThread.Queue(nil,
          procedure
          var
            ss: TStringStream;
            Lines: TArray<string>;
            EventName: string;
            DataUTF8: RawByteString;
            JSONObj: TJSONObject;
          begin
            sleep(1); // is required because of RSP-28205
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
                DataUTF8 := RawByteString(Lines[1].Substring(length(cData)))
              else begin
                // resynch
                DataUTF8 := '';
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
              end else if length(DataUTF8) > 0 then
              begin
                JSONObj := TJSONObject.ParseJSONValue(UTF8ToString(DataUTF8)) as
                  TJSONObject;
                if assigned(JSONObj) then
                try
                  fListenPartialResp := '';
                  if assigned(fOnListenEvent) and
                     not TFirebaseHelpers.AppIsTerminated then
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
      if assigned(fOnListenError) and not TFirebaseHelpers.AppIsTerminated then
        if fDoNotSynchronizeEvents then
          fOnListenError(rsEvtParserFailed, ErrMsg)
        else
          TThread.Queue(nil,
            procedure
            begin
              fOnListenError(rsEvtParserFailed, ErrMsg)
            end)
        else
          TFirebaseHelpers.Log('RealTimeDB.OnRecData ' + rsEvtParserFailed +
            ': ' + ErrMsg);
    end;
  end;
end;
{$ELSE}
var
  ss: TStringStream;
  Lines: TArray<string>;
  EventName, ErrMsg: string;
  DataUTF8: RawByteString;
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
            DataUTF8 := RawByteString(Lines[1].Substring(length(cData)))
          else begin
            // resynch
            DataUTF8 := '';
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
          end else if length(DataUTF8) > 0 then
          begin
            JSONObj := TJSONObject.ParseJSONValue(UTF8ToString(DataUTF8)) as
              TJSONObject;
            if assigned(JSONObj) then
            begin
              fListenPartialResp := '';
              if assigned(fOnListenEvent) and
                 not TFirebaseHelpers.AppIsTerminated then
                if fDoNotSynchronizeEvents then
                begin
                  fOnListenEvent(EventName, Params, JSONObj);
                  JSONObj.Free;
                end else
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
      if assigned(fOnListenError) and not TFirebaseHelpers.AppIsTerminated then
        if fDoNotSynchronizeEvents then
          fOnListenError(rsEvtParserFailed, ErrMsg)
        else
          TThread.Queue(nil,
            procedure
            begin
              fOnListenError(rsEvtParserFailed, ErrMsg)
            end)
      else
        TFirebaseHelpers.Log('RealTimeDB.OnRecData ' + rsEvtParserFailed +
          ': ' + ErrMsg);
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
        TFirebaseHelpers.Log('FirebaseEvent.StopListening Hard stop of ' +
          'listener thread because of lost connection');
        fFirebase.fThread.Terminate;
      end;
    end;
  except
    on e: exception do
      TFirebaseHelpers.Log('FirebaseEvent.StopListening Exception: ' +
        e.Message);
  end;
end;

end.
