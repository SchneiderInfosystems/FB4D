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

unit FB4D.FireStore.Listener;

interface

uses
  System.Types, System.Classes, System.SysUtils, System.Generics.Collections,
  System.NetConsts, System.Net.HttpClient, System.Net.URLClient,
  System.NetEncoding, System.SyncObjs,
  FB4D.Interfaces, FB4D.Helpers;

type
  TTargetKind = (tkDocument, tkQuery);
  TTarget = record
    TargetID: cardinal;
    OnChangedDoc: TOnChangedDocument;
    OnDeletedDoc: TOnDeletedDocument;
    TargetKind: TTargetKind;
    //  tkDocument:
    DocumentPath: string;
    // tkQuery:
    QueryJSON: string;
  end;

  TFSListenerThread = class(TThread)
  private const
    cWaitTimeBeforeReconnect = 2000; // 2 sec
    cTimeoutConnectionLost = 61000; // 1 minute 1sec
    cDefTimeOutInMS = 500;
  private type
    TInitMode = (Refetch, NewSIDRequest, NewListener);
  private
    fDatabase: string;
    fAuth: IFirebaseAuthentication;
    // For ListenForValueEvents
    fLastTokenRefreshCount: cardinal;
    fSID, fGSessionID: string;
    fRequestID: string;
    fClient: THTTPClient;
    fAsyncResult: IAsyncResult;
    fGetFinishedEvent: TEvent;
    fStream: TMemoryStream;
    fReadPos: Int64;
    fMsgSize: integer;
    fOnStopListening: TOnStopListenEvent;
    fOnListenError: TOnRequestError;
    fOnAuthRevoked: TOnAuthRevokedEvent;
    fOnConnectionStateChange: TOnConnectionStateChange;
    fDoNotSynchronizeEvents: boolean;
    fLastKeepAliveMsg: TDateTime;
    fLastReceivedMsg: TDateTime;
    fConnected: boolean;
    fRequireTokenRenew: boolean;
    fCloseRequest: boolean;
    fStopWaiting: boolean;
    fPartialResp: string;
    fLastTelegramNo: integer;
    fResumeToken: string;
    fTargets: TList<TTarget>;
    function GetTargetIndById(TargetID: cardinal): integer;
    function GetRequestData: string;
    procedure InitListen(Mode: TInitMode = Refetch);
    function RequestSIDInThread: boolean;
    function SearchNextMsg: string;
    procedure Parser;
    procedure Interprete(const Telegram: string);
    procedure ReportErrorInThread(const ErrMsg: string);
    procedure OnRecData(const Sender: TObject; ContentLength, ReadCount: Int64;
      var Abort: Boolean);
    procedure OnEndListenerGet(const ASyncResult: IAsyncResult);
    procedure OnEndThread(Sender: TObject);
  protected
    procedure Execute; override;
  public
    constructor Create(const ProjectID, DatabaseID: string;
      Auth: IFirebaseAuthentication);
    destructor Destroy; override;
    procedure RegisterEvents(OnStopListening: TOnStopListenEvent;
      OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent;
      OnConnectionStateChange: TOnConnectionStateChange;
      DoNotSynchronizeEvents: boolean);
    procedure StopListener(TimeOutInMS: integer = cDefTimeOutInMS);
    procedure StopNotStarted;
    function IsRunning: boolean;
    function SubscribeDocument(DocumentPath: TRequestResourceParam;
      OnChangedDoc: TOnChangedDocument;
      OnDeletedDoc: TOnDeletedDocument): cardinal;
    function SubscribeQuery(Query: IStructuredQuery;
      DocumentPath: TRequestResourceParam; OnChangedDoc: TOnChangedDocument;
      OnDeletedDoc: TOnDeletedDocument): cardinal;
    procedure Unsubscribe(TargetID: cardinal);
    property LastReceivedMsg: TDateTime read fLastReceivedMsg;
  end;

implementation

uses
  System.JSON, System.StrUtils,
  REST.Types,
  FB4D.Document, FB4D.Response, FB4D.Request;

{$IFDEF DEBUG}
{$DEFINE ParserLog}
{.$DEFINE ParserLogDetails}
{$ENDIF}

const
  cBaseURL = 'https://firestore.googleapis.com/google.firestore.v1.Firestore';
  cResourceParams: TRequestResourceParam = ['Listen', 'channel'];
  cVER = '8';
  cCVER = '22';
  cHttpHeaders =
    'X-Goog-Api-Client:gl-js/ file(8.2.3'#13#10'Content-Type:text/plain';

resourcestring
  rsEvtListenerFailed = 'Event listener failed: %s';
  rsEvtStartFailed = 'Event listener start failed: %s';
  rsEvtParserFailed = 'Exception in listener: ';
  rsParserFailed = 'Exception in event parser: ';
  rsInterpreteFailed = 'Exception in event interpreter: ';
  rsUnknownStatus = 'Unknown status msg %d: %s';
  rsUnexpectedExcept = 'Unexpected exception: ';
  rsUnexpectedThreadEnd = 'Listener unexpected stopped';

{ TListenerThread }

constructor TFSListenerThread.Create(const ProjectID, DatabaseID: string;
  Auth: IFirebaseAuthentication);
var
  EventName: string;
begin
  inherited Create(true);
  Assert(assigned(Auth), 'Authentication not initalized');
  fAuth := Auth;
  fDatabase := 'projects/' + ProjectID + '/databases/' + DatabaseID;
  fTargets := TList<TTarget>.Create;
  {$IFDEF WINDOWS}
  EventName := 'FB4DFSListenerGetFini';
  {$ELSE}
  EventName := '';
  {$ENDIF}
  fGetFinishedEvent := TEvent.Create(nil, false, false, EventName);
  OnTerminate := OnEndThread;
  FreeOnTerminate := false;
  {$IFNDEF LINUX64}
  NameThreadForDebugging('FB4D.FSListenerThread', ThreadID);
  {$ENDIF}
end;

destructor TFSListenerThread.Destroy;
begin
  FreeAndNil(fGetFinishedEvent);
  FreeAndNil(fTargets);
  inherited;
end;

function TFSListenerThread.SubscribeDocument(
  DocumentPath: TRequestResourceParam; OnChangedDoc: TOnChangedDocument;
  OnDeletedDoc: TOnDeletedDocument): cardinal;
var
  Target: TTarget;
begin
  if IsRunning then
    raise EFirestoreListener.Create(
      'SubscribeDocument must not be called for started Listener');
  Target.TargetID := (fTargets.Count + 1) * 2;
  Target.TargetKind := TTargetKind.tkDocument;
  Target.DocumentPath := TFirebaseHelpers.EncodeResourceParams(DocumentPath);
  Target.QueryJSON := '';
  Target.OnChangedDoc := OnChangedDoc;
  Target.OnDeletedDoc := OnDeletedDoc;
  fTargets.Add(Target);
  result := Target.TargetID;
end;

function TFSListenerThread.SubscribeQuery(Query: IStructuredQuery;
  DocumentPath: TRequestResourceParam; OnChangedDoc: TOnChangedDocument;
  OnDeletedDoc: TOnDeletedDocument): cardinal;
var
  Target: TTarget;
  JSONobj: TJSONObject;
begin
  if IsRunning then
    raise EFirestoreListener.Create(
      'SubscribeQuery must not be called for started Listener');
  Target.TargetID := (fTargets.Count + 1) * 2;
  Target.TargetKind := TTargetKind.tkQuery;
  JSONobj := Query.AsJSON;
  JSONobj.AddPair('parent', fDatabase + '/documents' +
    TFirebaseHelpers.EncodeResourceParams(DocumentPath));
  Target.QueryJSON := JSONobj.ToJSON;
  Target.DocumentPath := '';
  Target.OnChangedDoc := OnChangedDoc;
  Target.OnDeletedDoc := OnDeletedDoc;
  fTargets.Add(Target);
  result := Target.TargetID;
end;

procedure TFSListenerThread.Unsubscribe(TargetID: cardinal);
var
  c: integer;
begin
  if IsRunning then
    raise EFirestoreListener.Create(
      'Unsubscribe must not be called for started Listener');
  c := GetTargetIndById(TargetID);
  if c >= 0 then
    fTargets.Delete(c);
end;

function TFSListenerThread.GetTargetIndById(TargetID: cardinal): integer;
var
  c: integer;
begin
  for c := 0 to fTargets.Count - 1 do
    if fTargets[c].TargetID = TargetID then
      exit(c);
  result := -1;
end;

function TFSListenerThread.GetRequestData: string;
const
  // Count=1
  // ofs=0
  // req0___data__={"database":"projects/<ProjectID>/databases/(default)",
  // "addTarget":{"documents":{"documents":["projects/<ProjectID>/databases/(default)/documents/<DBPath>"]},
  // "targetId":2}}
  cResumeToken = ',"resumeToken":"%s"';
  cDocumentTemplate =
    '{"database":"%0:s",' +
     '"addTarget":{' +
       '"documents":' +
         '{"documents":["%0:s/documents%1:s"]},' +
       '"targetId":%2:d%3:s}}';
  cQueryTemplate =
    '{"database":"%0:s",' +
     '"addTarget":{' +
       '"query":%1:s,' +
       '"targetId":%2:d%3:s}}';
  cHead = 'count=%d&ofs=0';
  cTarget= '&req%d___data__=%s';
var
  Target: TTarget;
  ind: cardinal;
  JSON: string;
begin
  ind := 0;
  result := Format(cHead, [fTargets.Count]);
  for Target in fTargets do
  begin
    if fResumeToken.IsEmpty then
      JSON := ''
    else
      JSON := Format(cResumeToken, [fResumeToken]);
    case Target.TargetKind of
      tkDocument:
        JSON := Format(cDocumentTemplate,
          [fDatabase, Target.DocumentPath, Target.TargetID, JSON]);
      tkQuery:
        begin
          JSON := Format(cQueryTemplate,
            [fDatabase, Target.QueryJSON, Target.TargetID, JSON]);
          {$IFDEF ParserLogDetails}
          TFirebaseHelpers.Log('FSListenerThread.GetRequestData Query: ' + JSON);
          {$ENDIF}
        end;
    end;
    result := result + Format(cTarget, [ind, TNetEncoding.URL.Encode(JSON)]);
    inc(ind);
  end;
end;

procedure TFSListenerThread.Interprete(const Telegram: string);

  procedure HandleTargetChanged(ChangedObj: TJsonObject);
  begin
    ChangedObj.TryGetValue('resumeToken', fResumeToken);
    {$IFDEF ParserLogDetails}
    TFirebaseHelpers.Log('FSListenerThread.Interprete Token: ' + fResumeToken);
    {$ENDIF}
  end;

  procedure HandleDocChanged(DocChangedObj: TJsonObject);
  var
    DocObj: TJsonObject;
    TargetIds: TJsonArray;
    c, ind: integer;
    Doc: IFirestoreDocument;
  begin
    DocObj := DocChangedObj.GetValue('document') as TJsonObject;
    TargetIds := DocChangedObj.GetValue('targetIds') as TJsonArray;
    Doc := TFirestoreDocument.CreateFromJSONObj(DocObj);
    try
      for c := 0 to TargetIds.Count - 1 do
      begin
        ind := GetTargetIndById(TargetIds.Items[c].AsType<integer>);
        if (ind >= 0) and assigned(fTargets[ind].OnChangedDoc) then
        begin
          if fDoNotSynchronizeEvents then
            fTargets[ind].OnChangedDoc(Doc)
          else
            TThread.Synchronize(nil,
              procedure
              begin
                fTargets[ind].OnChangedDoc(Doc);
              end);
        end;
      end;
    finally
      Doc := nil;
    end;
  end;

  function HandleDocDeleted(DocDeletedObj: TJsonObject): boolean;
  var
    DocPath: string;
    TargetIds: TJsonArray;
    TimeStamp: TDateTime;
    c, ind: integer;
  begin
    result := false;
    DocPath := DocDeletedObj.GetValue<string>('document');
    TimeStamp := DocDeletedObj.GetValue<TDateTime>('readTime');
    TargetIds := DocDeletedObj.GetValue('removedTargetIds') as TJsonArray;
    for c := 0 to TargetIds.Count - 1 do
    begin
      ind := GetTargetIndById(TargetIds.Items[c].AsType<integer>);
      if (ind >= 0) and assigned(fTargets[ind].OnDeletedDoc) then
        if fDoNotSynchronizeEvents then
          fTargets[ind].OnDeletedDoc(DocPath, TimeStamp)
        else
          TThread.Queue(nil,
            procedure
            begin
              fTargets[ind].OnDeletedDoc(DocPath, TimeStamp);
            end);
    end;
  end;

  procedure HandleErrorStatus(ErrObj: TJsonObject);
  var
    ErrCode: integer;
  begin
    ErrCode := (ErrObj.GetValue('code') as TJSONNumber).AsInt;
    case ErrCode of
      401: // Missing or invalid authentication
        fRequireTokenRenew := true;
      else
        ReportErrorInThread(Format(rsUnknownStatus, [ErrCode, Telegram]));
    end;
  end;

const
  cKeepAlive = '"noop"';
  cClose = '"close"';
  cDocChange = 'documentChange';
  cDocDelete = 'documentDelete';
  cDocRemove = 'documentRemove';
  cTargetChange = 'targetChange';
  cFilter = 'filter';
  cStatusMessage = '__sm__';
var
  Obj: TJsonObject;
  ObjName: string;
  StatusArr, StatusArr2: TJSONArray;
  c, d: integer;
begin
  try
    {$IFDEF ParserLog}
    TFirebaseHelpers.LogFmt('FSListenerThread.Interprete Telegram[%d] %s',
       [fLastTelegramNo, Telegram]);
    {$ENDIF}
    if Telegram = cKeepAlive then
      fLastKeepAliveMsg := now
    else if Telegram = cClose then
      fCloseRequest := true
    else if Telegram.StartsWith('{') and Telegram.EndsWith('}') then
    begin
      Obj := TJSONObject.ParseJSONValue(Telegram) as TJSONObject;
      try
        ObjName := Obj.Pairs[0].JsonString.Value;
        if ObjName = cTargetChange then
          HandleTargetChanged(Obj.Pairs[0].JsonValue as TJsonObject)
        else if ObjName = cFilter then
          // Filter(Obj.Pairs[0].JsonValue as TJsonObject)
        else if ObjName = cDocChange then
          HandleDocChanged(Obj.Pairs[0].JsonValue as TJsonObject)
        else if (ObjName = cDocDelete) or (ObjName = cDocRemove) then
          HandleDocDeleted(Obj.Pairs[0].JsonValue as TJsonObject)
        else if ObjName = cStatusMessage then
        begin
          StatusArr := (Obj.Pairs[0].JsonValue as TJsonObject).
            GetValue('status') as TJSONArray;
          for c := 0 to StatusArr.Count - 1 do
          begin
            StatusArr2 := StatusArr.Items[c] as TJSONArray;
            for d := 0 to StatusArr2.Count - 1 do
              HandleErrorStatus(
                StatusArr2.Items[c].GetValue<TJsonObject>('error'));
          end;
        end else
          raise EFirestoreListener.Create('Unknown JSON telegram: ' + Telegram);
      finally
        Obj.Free;
      end;
    end else
      raise EFirestoreListener.Create('Unknown telegram: ' + Telegram);
  except
    on e: exception do
      ReportErrorInThread(rsInterpreteFailed + e.Message);
  end;
end;

function TFSListenerThread.IsRunning: boolean;
begin
  result := Started and not Finished;
end;

function TFSListenerThread.SearchNextMsg: string;

  function GetNextLine(const Line: string; out NextResp: string): string;
  const
    cLineFeed = #10;
  var
    p: integer;
  begin
    p := Pos(cLineFeed, Line);
    if p > 1 then
    begin
      result := copy(Line, 1, p - 1);
      NextResp := copy(Line, p + 1);
    end else
      result := '';
  end;

var
  NextResp: string;
begin
  fMsgSize := StrToIntDef(GetNextLine(fPartialResp, NextResp), -1);
  if (fMsgSize >= 0) and (NextResp.Length >= fMsgSize) then
  begin
    result := copy(NextResp, 1, fMsgSize);
    fPartialResp := copy(NextResp, fMsgSize + 1);
    {$IFDEF ParserLog}
    if not fPartialResp.IsEmpty then
      TFirebaseHelpers.Log('FSListenerThread.Rest line after SearchNextMsg: ' +
        fPartialResp);
    {$ENDIF}
  end else
    result := '';
end;

procedure TFSListenerThread.Parser;

  procedure ParseNextMsg(const msg: string);

    function FindTelegramStart(var Line: string): integer;
    var
      p: integer;
    begin
      // Telegram start with '[' + MsgNo.ToString+ ',['
      if not Line.StartsWith('[') then
        raise EFirestoreListener.Create('Invalid telegram start: ' + Line);
      p := 2;
      while (p < Line.Length) and (Line[p] <> ',') do
        inc(p);
      if Copy(Line, p, 2) = ',[' then
      begin
        result := StrToIntDef(copy(Line, 2, p - 2), -1);
        Line := Copy(Line, p + 2);
      end
      else if Copy(Line, p, 2) = ',{' then
      begin
        result := StrToIntDef(copy(Line, 2, p - 2), -1);
        Line := Copy(Line, p + 1); // Take { into telegram
      end else
        raise EFirestoreListener.Create('Invalid telegram received: ' + Line);
    end;

    function FindNextTelegram(var Line: string): string;
    var
      p, BracketLevel, BraceLevel: integer;
      InString, EndFlag: boolean;
    begin
      Assert(Line.Length > 2, 'Too short telegram: ' + Line);
      BracketLevel := 0;
      BraceLevel := 0;
      InString := false;
      if Line[1] = '[' then
        BracketLevel := 1
      else if Line[1] = '{' then
        BraceLevel := 1
      else if Line[1] = '"' then
        InString := true
      else
        raise EFirestoreListener.Create('Invalid telegram start char: ' + Line);
      EndFlag := false;
      p := 2;
      result := Line[1];
      while p < Line.Length do
      begin
        if (Line[p] = '"') and (Line[p - 1] <> '\') then
        begin
          InString := not InString;
          if (Line[1] = '"') and not InString then
            EndFlag := true;
        end
        else if not InString then
        begin
          if Line[p] = '{' then
            inc(BraceLevel)
          else if Line[p] = '}' then
          begin
            dec(BraceLevel);
            if (BraceLevel = 0) and (Line[1] = '{') then
              EndFlag := true;
          end
          else if Line[p] = '[' then
            inc(BracketLevel)
          else if Line[p] = ']' then
          begin
            dec(BracketLevel);
            if (BracketLevel = 0) and (Line[1] = '[') then
              EndFlag := true;
          end;
        end;
        if InString or (Line[p] <> #10) then
          result := result + Line[p];
        inc(p);
        if EndFlag then
        begin
          if Line[p] = #10 then
            Line := Copy(Line, p + 1)
          else
            Line := Copy(Line, p);
          exit;
        end;
      end;
      raise EFirestoreListener.Create('Invalid telegram end received: ' + Line);
    end;

  var
    msgNo: integer;
    Line, Telegram: string;
  begin
    {$IFDEF ParserLogDetails}
    TFirebaseHelpers.Log('FSListenerThread.Parser: ' + msg);
    {$ENDIF}
    if not(msg.StartsWith('[') and msg.EndsWith(']')) then
      raise EFirestoreListener.Create('Invalid packet received: ' + msg);
    Line := copy(msg, 2, msg.Length - 2);
    repeat
      MsgNo := FindTelegramStart(Line);
      if MsgNo > fLastTelegramNo then
      begin
        fLastTelegramNo := MsgNo;
        Interprete(FindNextTelegram(Line));
      end else begin
        Telegram := FindNextTelegram(Line);
        {$IFDEF ParserLog}
        TFirebaseHelpers.Log('FSListenerThread.Parser Ignore obsolete ' +
          'telegram ' + MsgNo.ToString + ': ' + Telegram);
        {$ENDIF}
      end;
      if not Line.EndsWith(']]') then
        raise EFirestoreListener.Create('Invalid telegram end received: ' +
          Line);
      if (Line.length > 4) and (Line[3] = ',') then
        Line := Copy(Line, 4)
      else
        Line := Copy(Line, 3);
    until Line.IsEmpty;
  end;

var
  msg: string;
begin
  if TFirebaseHelpers.AppIsTerminated then
    exit;
  try
    repeat
      msg := SearchNextMsg;
      if not msg.IsEmpty then
        ParseNextMsg(msg);
    until msg.IsEmpty;
  except
    on e: exception do
      ReportErrorInThread(rsParserFailed + e.Message);
  end;
end;

procedure TFSListenerThread.ReportErrorInThread(const ErrMsg: string);
begin
  if assigned(fOnListenError) and not TFirebaseHelpers.AppIsTerminated then
    if fDoNotSynchronizeEvents then
      fOnListenError(fRequestID, ErrMsg)
    else
      TThread.Queue(nil,
        procedure
        begin
          fOnListenError(fRequestID, ErrMsg);
        end)
  else
    TFirebaseHelpers.Log('FSListenerThread.ReportErrorInThread ' + ErrMsg);
end;

procedure TFSListenerThread.InitListen(Mode: TInitMode);
begin
  fReadPos := 0;
  fLastKeepAliveMsg := 0;
  fRequireTokenRenew := false;
  fCloseRequest := false;
  fStopWaiting := false;
  fMsgSize := -1;
  fPartialResp := '';
  if Mode >= NewSIDRequest then
  begin
    fLastTelegramNo := 0;
    fSID := '';
    fGSessionID := '';
    fConnected := false;
    if Mode >= NewListener then
    begin
      fResumeToken := '';
      fLastReceivedMsg := 0;
    end;
  end;
end;

function TFSListenerThread.RequestSIDInThread: boolean;

  function FetchSIDFromResponse(Response: IFirebaseResponse): boolean;
  // 51
  // [[0,["c","XrzGTQGX9ETvyCg6j6Rjyg","",8,12,30000]]]
  const
    cBeginPattern = '[[0,[';
    cEndPattern = ']]]'#10;
  var
    RespElement: TStringDynArray;
    Resp: string;
  begin
    fPartialResp := Response.ContentAsString;
    Resp := SearchNextMsg;
    fPartialResp := '';
    if not Resp.StartsWith(cBeginPattern) then
      raise EFirestoreListener.Create('Invalid SID response start: ' + Resp);
    if not Resp.EndsWith(cEndPattern) then
      raise EFirestoreListener.Create('Invalid SID response end: ' + Resp);
    Resp := copy(Resp, cBeginPattern.Length + 1,
     Resp.Length - cBeginPattern.Length - cEndPattern.Length);
    RespElement := SplitString(Resp, ',');
    if length(RespElement) < 2 then
      raise EFirestoreListener.Create('Invalid SID response array size: ' +
        Resp);
    fSID := RespElement[1];
    if (fSID.Length < 24) or
       not(fSID.StartsWith('"') and fSID.EndsWith('"')) then
      raise EFirestoreListener.Create('Invalid SID ' + fSID + ' response : ' +
        Resp);
    fSID := copy(fSID, 2, fSID.Length - 2);
    fGSessionID := Response.HeaderValue('x-http-session-id');
    {$IFDEF ParserLog}
    TFirebaseHelpers.Log('FSListenerThread.RequestSIDInThread ' + fSID + ', ' +
      fGSessionID);
    {$ENDIF}
    result := true;
  end;

var
  Request: IFirebaseRequest;
  DataStr: TStringStream;
  QueryParams: TQueryParams;
  Response: IFirebaseResponse;
begin
  result := false;
  InitListen(NewSIDRequest);
  try
    Request := TFirebaseRequest.Create(cBaseURL, fRequestID, fAuth);
    DataStr := TStringStream.Create(GetRequestData);
    QueryParams := TQueryParams.Create;
    try
      QueryParams.Add('database', [fDatabase]);
      QueryParams.Add('VER', [cVER]);
      QueryParams.Add('RID', ['0']);
      QueryParams.Add('CVER', [cCVER]);
      QueryParams.Add('X-HTTP-Session-Id', ['gsessionid']);
      QueryParams.Add('$httpHeaders', [cHttpHeaders]);
      Response := Request.SendRequestSynchronous(cResourceParams, rmPost,
        DataStr, TRESTContentType.ctTEXT_PLAIN, QueryParams, tmBearer);
      if Response.StatusOk then
      begin
        fLastTokenRefreshCount := fAuth.GetTokenRefreshCount;
        result := FetchSIDFromResponse(Response);
      end else
        ReportErrorInThread(Format(rsEvtStartFailed, [Response.StatusText]));
    finally
      QueryParams.Free;
      DataStr.Free;
    end;
  except
    on e: exception do
      if fConnected then
        ReportErrorInThread(Format(rsEvtStartFailed, [e.Message]));
  end;
end;

procedure TFSListenerThread.Execute;
var
  URL: string;
  QueryParams: TQueryParams;
  WasTokenRefreshed: boolean;
  WaitRes: TWaitResult;
  LastWait: TDateTime;
begin
  if fStopWaiting then
    exit; // for StopNotStarted
  InitListen(NewListener);
  QueryParams := TQueryParams.Create;
  try
    while not CheckTerminated and not fStopWaiting do
    begin
      if assigned(fAuth) then
        WasTokenRefreshed :=
          fAuth.GetTokenRefreshCount > fLastTokenRefreshCount
      else
        WasTokenRefreshed := false;
      if fSID.IsEmpty or fGSessionID.IsEmpty or WasTokenRefreshed or
         fCloseRequest then
      begin
        if not RequestSIDInThread then
          fCloseRequest := true // Probably not connected with server
        else if not fConnected then
        begin
          fConnected := true;
          if assigned(fOnConnectionStateChange) then
            if fDoNotSynchronizeEvents then
              fOnConnectionStateChange(true)
            else
              TThread.Queue(nil,
                procedure
                begin
                  fOnConnectionStateChange(true);
                end);
        end;
      end else
        InitListen;
      if fSID.IsEmpty or fGSessionID.IsEmpty then
      begin
        {$IFDEF ParserLog}
        TFirebaseHelpers.Log('FSListenerThread delay before reconnect');
        {$ENDIF}
        Sleep(cWaitTimeBeforeReconnect);
      end else begin
        fStream := TMemoryStream.Create;
        fClient := THTTPClient.Create;
        try
          try
            fClient.HandleRedirects := true;
            fClient.Accept := '*/*';
            fClient.OnReceiveData := OnRecData;
            QueryParams.Clear;
            QueryParams.Add('database', [fDatabase]);
            QueryParams.Add('gsessionid', [fGSessionID]);
            QueryParams.Add('VER', [cVER]);
            QueryParams.Add('RID', ['rpc']);
            QueryParams.Add('SID', [fSID]);
            QueryParams.Add('AID', [fLastTelegramNo.ToString]);
            QueryParams.Add('TYPE', ['xmlhttp']);
            URL := cBaseURL +
              TFirebaseHelpers.EncodeResourceParams(cResourceParams) +
              TFirebaseHelpers.EncodeQueryParams(QueryParams);
            {$IFDEF ParserLog}
            TFirebaseHelpers.Log('FSListenerThread Get: [' +
              fLastTelegramNo.ToString + '] ' + URL);
            {$ENDIF}
            if not fCloseRequest then
            begin
              fAsyncResult := fClient.BeginGet(OnEndListenerGet, URL, fStream);
              repeat
                LastWait := now;
                WaitRes := fGetFinishedEvent.WaitFor(cTimeoutConnectionLost);
                if (WaitRes = wrTimeout) and (fLastReceivedMsg < LastWait) then
                begin
                  fCloseRequest := true;
                  fAsyncResult.Cancel;
                  {$IFDEF ParserLog}
                  TFirebaseHelpers.Log('FSListenerThread timeout: ' +
                    TimeToStr(now - fLastReceivedMsg));
                  {$ENDIF}
                end;
              until (WaitRes = wrSignaled) or fCloseRequest or CheckTerminated;
            end;
            if fCloseRequest and not (fStopWaiting or fRequireTokenRenew) then
            begin
              if assigned(fOnConnectionStateChange) and fConnected then
                if fDoNotSynchronizeEvents then
                  fOnConnectionStateChange(false)
                else
                  TThread.Queue(nil,
                    procedure
                    begin
                      fOnConnectionStateChange(false);
                    end);
              fConnected := false;
              if fLastReceivedMsg < now - cTimeoutConnectionLost then
              begin
                {$IFDEF ParserLog}
                TFirebaseHelpers.Log('FSListenerThread wait before reconnect');
                {$ENDIF}
                Sleep(cWaitTimeBeforeReconnect);
              end;
            end
            else if not fConnected then
            begin
              fConnected := true;
              if assigned(fOnConnectionStateChange) then
                if fDoNotSynchronizeEvents then
                  fOnConnectionStateChange(true)
                else
                  TThread.Queue(nil,
                    procedure
                    begin
                      fOnConnectionStateChange(true);
                    end);
            end;
          except
            on e: exception do
            begin
              ReportErrorInThread(Format(rsEvtListenerFailed,
                ['InnerException=' + e.Message]));
              // retry
            end;
          end;
          if fRequireTokenRenew then
          begin
            if assigned(fAuth) and fAuth.CheckAndRefreshTokenSynchronous then
            begin
              {$IFDEF ParserLog}
              TFirebaseHelpers.Log(
                'FSListenerThread RequireTokenRenew: sucess at ' +
                TimeToStr(now));
              {$ENDIF}
              fRequireTokenRenew := false;
            end else begin
              {$IFDEF ParserLog}
              TFirebaseHelpers.Log(
                'FSListenerThread RequireTokenRenew: failed at ' +
                TimeToStr(now));
              {$ENDIF}
            end;
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
        finally
          FreeAndNil(fClient);
        end;
      end;
    end;
  except
    on e: exception do
      ReportErrorInThread(Format(rsEvtListenerFailed, [e.Message]));
  end;
  {$IFDEF ParserLog}
  TFirebaseHelpers.Log('FSListenerThread exit thread');
  {$ENDIF}
  FreeAndNil(QueryParams);
end;

procedure TFSListenerThread.RegisterEvents(OnStopListening: TOnStopListenEvent;
  OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent;
  OnConnectionStateChange: TOnConnectionStateChange;
  DoNotSynchronizeEvents: boolean);
begin
  if IsRunning then
    raise EFirestoreListener.Create(
      'RegisterEvents must not be called for started Listener');
  InitListen(NewListener);
  fRequestID := 'FSListener for ' + fTargets.Count.ToString + ' target(s)';
  fOnStopListening := OnStopListening;
  fOnListenError := OnError;
  fOnAuthRevoked := OnAuthRevoked;
  fOnConnectionStateChange := OnConnectionStateChange;
  fDoNotSynchronizeEvents := DoNotSynchronizeEvents;
end;

procedure TFSListenerThread.OnEndListenerGet(const ASyncResult: IAsyncResult);
var
  Resp: IHTTPResponse;
begin
  try
    if not ASyncResult.GetIsCancelled then
    begin
      try
        Resp := fClient.EndAsyncHTTP(ASyncResult);
        if not fCloseRequest and
          (Resp.StatusCode < 200) or (Resp.StatusCode >= 300) then
        begin
          ReportErrorInThread(Resp.StatusText);
          fCloseRequest := true;
          {$IFDEF ParserLogDetails}
          TFirebaseHelpers.Log('FSListenerThread.OnEndListenerGet Response: ' +
            Resp.ContentAsString);
          {$ENDIF}
        end else
          {$IFDEF ParserLog}
          TFirebaseHelpers.Log('FSListenerThread.OnEndListenerGet ' +
            Resp.StatusCode.ToString + ': ' + Resp.StatusText);
          {$ENDIF}
      finally
        Resp := nil;
      end;
    end else begin
      {$IFDEF ParserLog}
      TFirebaseHelpers.Log('FSListenerThread.OnEndListenerGet: canceled');
      {$ENDIF}
    end;
    FreeAndNil(fStream);
    if assigned(fGetFinishedEvent) then
      fGetFinishedEvent.SetEvent
  except
    on e: ENetException do
    begin
      fCloseRequest := true;
      {$IFDEF ParserLog}
      TFirebaseHelpers.Log(
        'FSListenerThread.OnEndListenerGet Disconnected by Server:' +
        e.Message);
      {$ENDIF}
      FreeAndNil(fStream);
      fGetFinishedEvent.SetEvent;
    end;
    on e: exception do
      TFirebaseHelpers.Log('FSListenerThread.OnEndListenerGet Exception ' +
        e.Message);
  end;
end;

procedure TFSListenerThread.OnEndThread(Sender: TObject);
begin
  if TFirebaseHelpers.AppIsTerminated then
    exit;
  if assigned(fOnStopListening) then
    TThread.ForceQueue(nil,
      procedure
      begin
        fOnStopListening(Sender);
      end);
  if not fStopWaiting and assigned(fOnListenError) then
    fOnListenError(fRequestID, rsUnexpectedThreadEnd);
end;

procedure TFSListenerThread.StopListener(TimeOutInMS: integer);
var
  Timeout: integer;
begin
  if not fStopWaiting then
  begin
    {$IFDEF ParserLog}
    TFirebaseHelpers.Log('FSListenerThread.StopListener stop');
    {$ENDIF}
    fStopWaiting := true;
    if not assigned(fClient) then
      raise EFirestoreListener.Create('Missing Client in StopListener')
    else if not assigned(fAsyncResult) then
      raise EFirestoreListener.Create('Missing AsyncResult in StopListener')
    else
      fAsyncResult.Cancel;
  end;
  Timeout := TimeOutInMS;
  while not Finished and (Timeout > 0) do
  begin
    if Timeout < TimeOutInMS div 2 then
    begin
      {$IFDEF ParserLog}
      TFirebaseHelpers.Log('FSListenerThread.StopListener emergency stop');
      {$ENDIF}
      if assigned(fAsyncResult) then
        fAsyncResult.Cancel;
      if assigned(fGetFinishedEvent) then
        fGetFinishedEvent.SetEvent;
    end;
    TFirebaseHelpers.SleepAndMessageLoop(5);
    dec(Timeout, 5);
  end;
  if not Finished then
  begin
    {$IFDEF ParserLog}
    TFirebaseHelpers.Log('FSListenerThread.StopListener not stopped!');
    {$ENDIF}
  end;
end;

procedure TFSListenerThread.StopNotStarted;
begin
  fStopWaiting := true;
  if not Suspended then
  begin
    {$IFDEF ParserLog}
    TFirebaseHelpers.Log('FSListenerThread.StopNotStarted');
    {$ENDIF}
    if assigned(fAsyncResult) then
      fAsyncResult.Cancel;
    if assigned(fGetFinishedEvent) then
      fGetFinishedEvent.SetEvent;
    Start;
    WaitFor;
  end;
end;

procedure TFSListenerThread.OnRecData(const Sender: TObject; ContentLength,
  ReadCount: Int64; var Abort: Boolean);
var
  ss: TStringStream;
  ErrMsg: string;
  Retry: integer;
  StreamReadFailed: boolean;
begin
  try
    fLastReceivedMsg := Now;
    if fStopWaiting then
     Abort := true
    else if assigned(fStream) and
      ((fMsgSize = -1) or
       (fPartialResp.Length + ReadCount - fReadPos >= fMsgSize)) then
    begin
      ss := TStringStream.Create('', TEncoding.UTF8);
      try
        Assert(fReadPos >= 0, 'Invalid stream read position');
        Assert(ReadCount - fReadPos >= 0, 'Invalid stream read count: ' +
          ReadCount.ToString + ' - ' + fReadPos.ToString);
        Retry := 2;
        StreamReadFailed := false;
        repeat
          fStream.Position := fReadPos;
          try
            ss.CopyFrom(fStream, ReadCount - fReadPos);
            StreamReadFailed := false;
          except
            on e: EReadError do
              if Retry > 0 then
              begin
                StreamReadFailed := true;
                dec(Retry);
              end else
                Raise;
          end;
        until not StreamReadFailed;
        try
          fPartialResp := fPartialResp + ss.DataString;
          fReadPos := ReadCount;
        except
          on e: EEncodingError do
            if (fMsgSize = -1) and fPartialResp.IsEmpty then
              // ignore Unicode decoding errors for the first received packet
            else
              raise;
        end;
      finally
        ss.Free;
      end;
      if not fPartialResp.IsEmpty then
        Parser;
    end;
  except
    on e: Exception do
    begin
      ErrMsg := e.Message;
      if not TFirebaseHelpers.AppIsTerminated then
        if assigned(fOnListenError) then
          if fDoNotSynchronizeEvents then
            fOnListenError(fRequestID, rsEvtParserFailed + ErrMsg)
          else
            TThread.Queue(nil,
              procedure
              begin
                fOnListenError(fRequestID, rsEvtParserFailed + ErrMsg);
              end)
        else
          TFirebaseHelpers.Log('FSListenerThread.OnRecData ' + ErrMsg);
    end;
  end;
end;

end.
