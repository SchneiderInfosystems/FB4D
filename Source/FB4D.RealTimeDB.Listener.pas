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

unit FB4D.RealTimeDB.Listener;

interface

uses
  System.Types, System.Classes, System.SysUtils, System.StrUtils, System.JSON,
  System.NetConsts, System.Net.HttpClient, System.Net.URLClient,
  System.NetEncoding, System.SyncObjs,
  FB4D.Interfaces, FB4D.Helpers;

type
  TRTDBListenerThread = class(TThread)
  private const
    cWaitTimeBeforeReconnect = 5000; // 5 sec
    cTimeoutConnection = 60000;      // 1 minute
    cTimeoutConnectionLost = 61000;  // 1 minute and 1sec
    cDefTimeOutInMS = 500;
    cJSONExt = '.json';
  private
    fBaseURL: string;
    fURL: string;
    fRequestID: string;
    fAuth: IFirebaseAuthentication;
    fResParams: TRequestResourceParam;
    fClient: THTTPClient;
    fAsyncResult: IAsyncResult;
    fGetFinishedEvent: TEvent;
    fStream: TMemoryStream;
    fReadPos: Int64;
    fOnListenError: TOnRequestError;
    fOnStopListening: TOnStopListenEvent;
    fOnListenEvent: TOnReceiveEvent;
    fOnAuthRevoked: TOnAuthRevokedEvent;
    fOnConnectionStateChange: TOnConnectionStateChange;
    fDoNotSynchronizeEvents: boolean;
    fLastKeepAliveMsg: TDateTime;
    fLastReceivedMsg: TDateTime;
    fConnected: boolean;
    fRequireTokenRenew: boolean;
    fStopWaiting: boolean;
    fCloseRequest: boolean;
    fListenPartialResp: string;
    procedure InitListen(FirstInit: boolean);
    procedure OnRecData(const Sender: TObject; ContentLength,
      ReadCount: Int64; var Abort: Boolean);
    procedure OnEndListenerGet(const ASyncResult: IAsyncResult);
    procedure OnEndThread(Sender: TObject);
  protected
    procedure Execute; override;
  public
    constructor Create(const FirebaseURL: string; Auth: IFirebaseAuthentication);
    destructor Destroy; override;
    procedure RegisterEvents(ResParams: TRequestResourceParam;
      OnListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
      OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent;
      OnConnectionStateChange: TOnConnectionStateChange;
      DoNotSynchronizeEvents: boolean);
    procedure StopListener(TimeOutInMS: integer = cDefTimeOutInMS);
    function IsRunning: boolean;
    property ResParams: TRequestResourceParam read fResParams;
    property StopWaiting: boolean read fStopWaiting;
    property LastKeepAliveMsg: TDateTime read fLastKeepAliveMsg;
    property LastReceivedMsg: TDateTime read fLastReceivedMsg;
  end;

implementation

resourcestring
  rsEvtListenerFailed = 'Event listener for %s failed: %s';
  rsEvtStartFailed = 'Event listener start for %s failed: %s';
  rsEvtParserFailed = 'Exception in event parser';

{ TRTDBListenerThread }

constructor TRTDBListenerThread.Create(const FirebaseURL: string;
  Auth: IFirebaseAuthentication);
var
  EventName: string;
begin
  inherited Create(true);
  fBaseURL := FirebaseURL;
  fAuth := Auth;
  {$IFDEF MSWINDOWS}
  EventName := 'RTDBListenerGetFini';
  {$ELSE}
  EventName := '';
  {$ENDIF}
  fGetFinishedEvent := TEvent.Create(nil, false, false, EventName);
  OnTerminate := OnEndThread;
  FreeOnTerminate := false;
  {$IFNDEF LINUX64}
  NameThreadForDebugging('FB4D.RTListenerThread', ThreadID);
  {$ENDIF}
end;

destructor TRTDBListenerThread.Destroy;
begin
  FreeAndNil(fGetFinishedEvent);
  inherited;
end;

procedure TRTDBListenerThread.InitListen(FirstInit: boolean);
begin
  if FirstInit then
  begin
    fClient := nil;
    fStream := nil;
    fStopWaiting := false;
    fLastKeepAliveMsg := 0;
    fLastReceivedMsg := 0;
    fRequireTokenRenew := false;
    fConnected := false;
  end;
  fReadPos := 0;
  fListenPartialResp := '';
  fCloseRequest := false;
end;

function TRTDBListenerThread.IsRunning: boolean;
begin
  result := Started and not Finished;
end;

procedure TRTDBListenerThread.RegisterEvents(ResParams: TRequestResourceParam;
  OnListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
  OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent;
  OnConnectionStateChange: TOnConnectionStateChange;
  DoNotSynchronizeEvents: boolean);
begin
  fURL := fBaseURL + TFirebaseHelpers.EncodeResourceParams(ResParams) +
    cJSONExt;
  fRequestID :=  TFirebaseHelpers.ArrStrToCommaStr(ResParams);
  fOnListenEvent := OnListenEvent;
  fOnStopListening := OnStopListening;
  fOnListenError := OnError;
  fOnAuthRevoked := OnAuthRevoked;
  fOnConnectionStateChange := OnConnectionStateChange;
  fDoNotSynchronizeEvents := DoNotSynchronizeEvents;
end;

procedure TRTDBListenerThread.StopListener(TimeOutInMS: integer);
var
  Timeout: integer;
begin
  if not fStopWaiting then
  begin
    fStopWaiting := true;
    if not assigned(fClient) then
      raise ERTDBListener.Create('Missing Client in StopListener')
    else if not assigned(fAsyncResult) then
      raise ERTDBListener.Create('Missing AsyncResult in StopListener')
    else
      fAsyncResult.Cancel;
  end;
  Timeout := TimeOutInMS;
  while IsRunning and (Timeout > 0) do
  begin
    TFirebaseHelpers.SleepAndMessageLoop(5);
    dec(Timeout, 5);
  end;
end;

procedure TRTDBListenerThread.Execute;
var
  WaitRes: TWaitResult;
  LastWait: TDateTime;
begin
  try
    InitListen(true);
    while not TThread.CurrentThread.CheckTerminated and not fStopWaiting do
    begin
      fClient := THTTPClient.Create;
      fClient.HandleRedirects := true;
      fClient.Accept := 'text/event-stream';
      fClient.OnReceiveData := OnRecData;
      fClient.ConnectionTimeout := cTimeoutConnection * 2;
      fStream := TMemoryStream.Create;
      try
        InitListen(false);
        if fRequireTokenRenew then
        begin
          if assigned(fAuth) and fAuth.CheckAndRefreshTokenSynchronous then
            fRequireTokenRenew := false;
          if assigned(fOnAuthRevoked) and
             not TFirebaseHelpers.AppIsTerminated then
            if fDoNotSynchronizeEvents then
              fOnAuthRevoked(not fRequireTokenRenew)
            else
              TThread.Queue(nil,
                procedure
                begin
                  fOnAuthRevoked(not fRequireTokenRenew);
                end);
        end;
        fAsyncResult := fClient.BeginGet(OnEndListenerGet,
          fURL + TFirebaseHelpers.EncodeToken(fAuth.Token), fStream);
        repeat
          LastWait := now;
          WaitRes := fGetFinishedEvent.WaitFor(cTimeoutConnectionLost);
          if (WaitRes = wrTimeout) and (fLastReceivedMsg < LastWait) then
          begin
            fAsyncResult.Cancel;
            {$IFDEF DEBUG}
            TFirebaseHelpers.Log('RTDBListenerThread timeout: ' +
              TimeToStr(now - fLastReceivedMsg));
            {$ENDIF}
          end;
        until (WaitRes = wrSignaled) or CheckTerminated;
        if fCloseRequest and fConnected then
        begin
          if assigned(fOnConnectionStateChange) then
            if fDoNotSynchronizeEvents then
              fOnConnectionStateChange(false)
            else
              TThread.Queue(nil,
                procedure
                begin
                  fOnConnectionStateChange(false);
                end);
          fConnected := false;
        end;
      finally
        FreeAndNil(fStream);
        FreeAndNil(fClient);
      end;
    end;
  except
    on e: exception do
      if assigned(fOnListenError) then
      begin
        var ErrMsg := e.Message;
        if fDoNotSynchronizeEvents then
          fOnListenError(fRequestID, ErrMsg)
        else
          TThread.Queue(nil,
            procedure
            begin
              fOnListenError(fRequestID, ErrMsg);
            end)
      end else
        TFirebaseHelpers.LogFmt('RTDBListenerThread.Listener ' +
          rsEvtListenerFailed, [fRequestID, e.Message]);
  end;
end;

procedure TRTDBListenerThread.OnEndListenerGet(const ASyncResult: IAsyncResult);
var
  Resp: IHTTPResponse;
  ErrMsg: string;
begin
  try
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log('RTDBListenerThread.OnEndListenerGet');
    {$ENDIF}
    if not ASyncResult.GetIsCancelled then
    begin
      try
        Resp := fClient.EndAsyncHTTP(ASyncResult);
        if (Resp.StatusCode < 200) or (Resp.StatusCode >= 300) then
        begin
          fCloseRequest := true;
          ErrMsg := Resp.StatusText;
          if assigned(fOnListenError) then
          begin
            if fDoNotSynchronizeEvents then
              fOnListenError(fRequestID, ErrMsg)
            else
              TThread.Queue(nil,
                procedure
                begin
                  fOnListenError(fRequestID, ErrMsg);
                end)
          end else
            TFirebaseHelpers.LogFmt('RTDBListenerThread.OnEndListenerGet ' +
              rsEvtStartFailed, [fRequestID, ErrMsg]);
        end;
      finally
        Resp := nil;
      end;
    end;
    fGetFinishedEvent.SetEvent;
  except
    on e: ENetException do
    begin
      fCloseRequest := true;
      {$IFDEF DEBUG}
      TFirebaseHelpers.Log(
        'RTDBListenerThread.OnEndListenerGet Disconnected by Server: ' +
        e.Message);
      {$ENDIF}
      FreeAndNil(fStream);
      fGetFinishedEvent.SetEvent;
    end;
    on e: exception do
      TFirebaseHelpers.Log('RTDBListenerThread.OnEndListenerGet Exception ' +
        e.Message);
  end;
end;

procedure TRTDBListenerThread.OnEndThread(Sender: TObject);
begin
  if assigned(fOnStopListening) and not TFirebaseHelpers.AppIsTerminated then
    TThread.ForceQueue(nil,
      procedure
      begin
        fOnStopListening(Sender);
      end);
end;

procedure TRTDBListenerThread.OnRecData(const Sender: TObject; ContentLength,
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
var
  ss: TStringStream;
  Lines: TArray<string>;
  EventName, ErrMsg: string;
  DataUTF8: RawByteString;
  Params: TRequestResourceParam;
  JSONObj: TJSONObject;
begin
  try
    fLastReceivedMsg := now;
    if not fConnected then
    begin
      if assigned(fOnConnectionStateChange) then
         if fDoNotSynchronizeEvents then
           fOnConnectionStateChange(true)
         else
           TThread.Queue(nil,
             procedure
             begin
               fOnConnectionStateChange(true);
             end);
      fConnected := true;
    end;
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
        TFirebaseHelpers.Log('RTDBListenerThread.OnRecData ' +
          rsEvtParserFailed + ': ' + ErrMsg);
    end;
  end;
end;

end.
