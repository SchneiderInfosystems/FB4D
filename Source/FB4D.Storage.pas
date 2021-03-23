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

unit FB4D.Storage;

interface

uses
  System.Classes, System.JSON, System.SysUtils,
  System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request;

type
  TFirebaseStorage = class(TInterfacedObject, IFirebaseStorage)
  private
    fBucket: string;
    fAuth: IFirebaseAuthentication;
    fStorageObjs: TDictionary<TObjectName, IStorageObject>;
    function BaseURL: string;
    procedure OnGetResponse(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
    procedure OnGetAndDownloadResponse(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
    procedure OnDelResponse(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
    procedure OnUploadFromStream(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
  public
    constructor Create(const BucketName: string; Auth: IFirebaseAuthentication);
    destructor Destroy; override;
    procedure Get(const ObjectName: TObjectName; OnGetStorage: TOnStorage;
      OnGetError: TOnStorageError); overload;
    procedure Get(const ObjectName, RequestID: string; OnGetStorage: TOnStorage;
      OnGetError: TOnRequestError); overload; { deprecated }
    function GetSynchronous(const ObjectName: TObjectName): IStorageObject;
    procedure GetAndDownload(const ObjectName: TObjectName; Stream: TStream;
      OnGetStorage: TOnStorage; OnGetError: TOnRequestError);
    function GetAndDownloadSynchronous(const ObjectName: TObjectName;
      Stream: TStream): IStorageObject;
    procedure UploadFromStream(Stream: TStream; const ObjectName: TObjectName;
      ContentType: TRESTContentType; OnUpload: TOnStorage;
      OnUploadError: TOnStorageError);
    function UploadSynchronousFromStream(Stream: TStream;
      const ObjectName: TObjectName;
      ContentType: TRESTContentType): IStorageObject;
    procedure Delete(const ObjectName: TObjectName;
      OnDelete: TOnDeleteStorage; OnDelError: TOnStorageError);
    procedure DeleteSynchronous(const ObjectName: TObjectName);
  end;

  TStorageObject = class(TInterfacedObject, IStorageObject)
  private
    fJSONObj: TJSONObject;
    procedure InternalDownloadToStream(const ObjectName: TObjectName;
      Stream: TStream; OnSuccess: TOnDownload; OnError: TOnDownloadError;
      OnAlternativeError: TOnStorageError);
  public
    constructor Create(Response: IFirebaseResponse);
    destructor Destroy; override;
    procedure DownloadToStream(const ObjectName: TObjectName; Stream: TStream;
      OnSuccess: TOnDownload; OnError: TOnDownloadError); overload;
    procedure DownloadToStream(const ObjectName: TObjectName; Stream: TStream;
      OnSuccess: TOnDownload; OnError: TOnStorageError); overload;
    procedure DownloadToStreamSynchronous(Stream: TStream);
    function ObjectName(IncludePath: boolean = true): string;
    class function GetObjectNameWithoutPath(const NameWithPath: string): string;
    function Path: string;
    function LastPathElement: string;
    function ContentType: string;
    function Size: Int64;
    function Bucket: string;
    function createTime: TDateTime;
    function updateTime: TDatetime;
    function DownloadToken: string;
    function DownloadUrl: string;
    function MD5HashCode: string;
    function storageClass: string;
    function etag: string;
    function generation: Int64;
    function metaGeneration: Int64;
  end;

implementation

uses
  System.NetConsts, System.NetEncoding, System.StrUtils,
  FB4D.Helpers;

const
  GOOGLE_STORAGE = 'https://firebasestorage.googleapis.com/v0/b/%s/o';

{ TFirestoreStorage }

constructor TFirebaseStorage.Create(const BucketName: string;
  Auth: IFirebaseAuthentication);

  function ExcludeTrailingSlash(const S: string): string;
    function IsSlash(const S: string; Index: Integer): Boolean;
    begin
      result := (Index >= Low(string)) and (Index <= High(S)) and
        (S[Index] = '/') and (ByteType(S, Index) = mbSingleByte);
    end;
  begin
    result := S;
    if IsSlash(result, High(result)) then
      SetLength(result, Length(result) - 1);
  end;

begin
  Assert(assigned(Auth), 'Authentication not initalized');
  fBucket := ExcludeTrailingSlash(BucketName);
  fAuth := Auth;
  fStorageObjs := TDictionary<TObjectName, IStorageObject>.Create;
end;

destructor TFirebaseStorage.Destroy;
begin
  fStorageObjs.Free;
  inherited;
end;


function TFirebaseStorage.BaseURL: string;
begin
  result := Format(GOOGLE_STORAGE, [fBucket]);
end;

procedure TFirebaseStorage.Get(const ObjectName: TObjectName;
  OnGetStorage: TOnStorage; OnGetError: TOnStorageError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(BaseURL, ObjectName, fAuth);
  Request.SendRequest([ObjectName], rmGet, nil, nil, tmBearer, OnGetResponse,
    OnGetError, TOnSuccess.CreateStorage(OnGetStorage));
end;

procedure TFirebaseStorage.Get(const ObjectName: TObjectName;
  const RequestID: string; OnGetStorage: TOnStorage;
  OnGetError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(BaseURL, RequestID, fAuth);
  Request.SendRequest([ObjectName], rmGet, nil, nil, tmBearer, OnGetResponse,
    OnGetError, TOnSuccess.CreateStorage(OnGetStorage));
end;

procedure TFirebaseStorage.OnGetResponse(const ObjectName: TObjectName;
  Response: IFirebaseResponse);
var
  StorageObj: IStorageObject;
begin
  try
    Response.CheckForJSONObj;
    StorageObJ := TStorageObject.Create(Response);
    fStorageObjs.TryAdd(ObjectName, StorageObJ);
    if assigned(Response.OnSuccess.OnStorage) then
      Response.OnSuccess.OnStorage(ObjectName, StorageObj)
    else
      TFirebaseHelpers.Log(Response.ContentAsString);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [ObjectName, e.Message]));
    end;
  end;
end;

function TFirebaseStorage.GetSynchronous(
  const ObjectName: TObjectName): IStorageObject;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Request := TFirebaseRequest.Create(BaseURL, '', fAuth);
  Response := Request.SendRequestSynchronous([ObjectName], rmGet);
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log(Response.ContentAsString);
  {$ENDIF}
  Response.CheckForJSONObj;
  result := TStorageObject.Create(Response);
  fStorageObjs.TryAdd(ObjectName, result);
end;

procedure TFirebaseStorage.GetAndDownload(const ObjectName: TObjectName;
  Stream: TStream; OnGetStorage: TOnStorage; OnGetError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(BaseURL, ObjectName, fAuth);
  Request.SendRequest([ObjectName], rmGet, nil, nil, tmBearer,
    OnGetAndDownloadResponse, OnGetError,
    TOnSuccess.CreateStorageGetAndDownload(OnGetStorage, OnGetError, Stream));
end;

procedure TFirebaseStorage.OnGetAndDownloadResponse(
  const ObjectName: TObjectName; Response: IFirebaseResponse);
var
  StorageObj: IStorageObject;
begin
  try
    Response.CheckForJSONObj;
    StorageObJ := TStorageObject.Create(Response);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log(Response.ContentAsString);
    {$ENDIF}
    fStorageObjs.TryAdd(ObjectName, StorageObJ);
    if assigned(Response.OnSuccess.OnStorageGetAndDown) then
      StorageObj.DownloadToStream(ObjectName, Response.OnSuccess.DownStream,
        Response.OnSuccess.OnStorageGetAndDown,
        Response.OnSuccess.OnStorageError);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [ObjectName, e.Message]));
    end;
  end;
end;

function TFirebaseStorage.GetAndDownloadSynchronous(
  const ObjectName: TObjectName; Stream: TStream): IStorageObject;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Request := TFirebaseRequest.Create(BaseURL, '', fAuth);
  Response := Request.SendRequestSynchronous([ObjectName], rmGet);
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log(Response.ContentAsString);
  {$ENDIF}
  Response.CheckForJSONObj;
  result := TStorageObject.Create(Response);
  fStorageObjs.TryAdd(ObjectName, result);
  result.DownloadToStreamSynchronous(Stream);
end;

function TFirebaseStorage.UploadSynchronousFromStream(Stream: TStream;
  const ObjectName: TObjectName; ContentType: TRESTContentType): IStorageObject;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  QueryParams: TQueryParams;
begin
  result := nil;
  Request := TFirebaseRequest.Create(BaseURL, '', fAuth);
  QueryParams := TQueryParams.Create;
  try
    QueryParams.Add('uploadType', ['media']);
    QueryParams.Add('name',  [ObjectName]);
    Response := Request.SendRequestSynchronous([], rmPost, Stream, ContentType,
      QueryParams);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log(Response.ContentAsString);
    {$ENDIF}
    result := TStorageObject.Create(Response);
    fStorageObjs.TryAdd(ObjectName, result);
  finally
    QueryParams.Free;
  end;
end;

procedure TFirebaseStorage.UploadFromStream(Stream: TStream;
  const ObjectName: TObjectName; ContentType: TRESTContentType;
  OnUpload: TOnStorage; OnUploadError: TOnStorageError);
var
  Request: IFirebaseRequest;
  QueryParams: TQueryParams;
begin
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('TFirebaseStorage.UploadFromStream');
  {$ENDIF}
  // RSP-23318 is solved since Delphi 10.3.1
  Request := TFirebaseRequest.Create(BaseURL, ObjectName, fAuth);
  QueryParams := TQueryParams.Create;
  try
    QueryParams.Add('uploadType', ['media']);
    QueryParams.Add('name',  [ObjectName]);
    Request.SendRequest([], rmPost, Stream, ContentType,
      QueryParams, tmBearer, OnUploadFromStream, OnUploadError,
      TOnSuccess.CreateStorage(OnUpload));
  finally
    QueryParams.Free;
  end;
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('TFirebaseStorage.UploadFromStream end');
  {$ENDIF}
end;

procedure TFirebaseStorage.OnUploadFromStream(const ObjectName: TObjectName;
  Response: IFirebaseResponse);
var
  StorageObj: IStorageObject;
begin
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('TFirebaseStorage.OnUploadFromStream: ' + ObjectName);
  {$ENDIF}
  try
    Response.CheckForJSONObj;
    StorageObj := TStorageObject.Create(Response);
    fStorageObjs.TryAdd(ObjectName, StorageObj);
    if assigned(Response.OnSuccess.OnStorage) then
      Response.OnSuccess.OnStorage(ObjectName, StorageObj)
    else
      TFirebaseHelpers.Log(Response.ContentAsString);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [ObjectName, e.Message]));
    end;
  end;
end;

procedure TFirebaseStorage.DeleteSynchronous(const ObjectName: TObjectName);
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Request := TFirebaseRequest.Create(BaseURL, '', fAuth);
  Response := Request.SendRequestSynchronous([ObjectName], rmDelete, nil, nil);
  if not Response.StatusOk then
  begin
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log(Response.ContentAsString);
    {$ENDIF}
    raise EStorageObject.CreateFmt('Delete failed: %s', [Response.StatusText]);
  end else
    fStorageObjs.Remove(ObjectName);
end;

procedure TFirebaseStorage.Delete(const ObjectName: TObjectName;
  OnDelete: TOnDeleteStorage; OnDelError: TOnStorageError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(BaseURL, ObjectName, fAuth);
  Request.SendRequest([ObjectName], rmDelete, nil, nil, tmBearer, OnDelResponse,
    OnDelError, TOnSuccess.CreateDelStorage(OnDelete));
end;

procedure TFirebaseStorage.OnDelResponse(const ObjectName: TObjectName;
  Response: IFirebaseResponse);
begin
  try
    if Response.StatusOk then
    begin
      if assigned(Response.OnSuccess.OnDelStorage) then
        Response.OnSuccess.OnDelStorage(ObjectName);
      fStorageObjs.Remove(ObjectName);
    end
    else if assigned(Response.OnError) then
      Response.OnError(ObjectName, Response.ErrorMsgOrStatusText)
    else
      TFirebaseHelpers.Log(Format(rsFBFailureIn,
        [ObjectName, Response.ErrorMsgOrStatusText]));
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [ObjectName, e.Message]));
    end;
  end;
end;

{ TFirestoreObject }

constructor TStorageObject.Create(Response: IFirebaseResponse);
begin
  fJSONObj := Response.GetContentAsJSONObj;
end;

destructor TStorageObject.Destroy;
begin
  fJSONObj.Free;
  inherited;
end;

function TStorageObject.createTime: TDateTime;
begin
  if not fJSONObj.TryGetValue('timeCreated', result) then
    raise EStorageObject.Create('JSON field timeCreated missing')
  else
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

function TStorageObject.updateTime: TDatetime;
begin
  if not fJSONObj.TryGetValue('updated', result) then
    raise EStorageObject.Create('JSON field updated missing')
  else
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

function TStorageObject.DownloadToken: string;
begin
  if not fJSONObj.TryGetValue('downloadTokens', result) then
    raise EStorageObject.Create('JSON field downloadTokens missing');
end;

function TStorageObject.DownloadUrl: string;
var
  QueryParams: TQueryParams;
begin
  QueryParams := TQueryParams.Create;
  try
    QueryParams.Add('alt', ['media']);
    QueryParams.Add('token', [DownloadToken]);
    result := Format(GOOGLE_STORAGE, [Bucket]) + '/' +
      TNetEncoding.URL.Encode(ObjectName) +
      TFirebaseHelpers.EncodeQueryParams(QueryParams);
  finally
    QueryParams.Free;
  end;
end;

procedure TStorageObject.DownloadToStreamSynchronous(Stream: TStream);
var
  Client: THTTPClient;
  Response: IHTTPResponse;
begin
  Client := THTTPClient.Create;
  try
    Response := Client.Get(DownloadUrl, Stream);
    if Response.StatusCode <> 200 then
    begin
      {$IFDEF DEBUG}
      TFirebaseHelpers.Log(Response.ContentAsString);
      {$ENDIF}
      raise EStorageObject.CreateFmt('Download failed: %s',
        [Response.StatusText]);
    end;
  finally
    Client.Free;
  end;
end;

procedure TStorageObject.InternalDownloadToStream(const ObjectName: TObjectName;
  Stream: TStream; OnSuccess: TOnDownload; OnError: TOnDownloadError;
  OnAlternativeError: TOnStorageError);
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Client: THTTPClient;
      Response: IHTTPResponse;
      ErrMsg: string;
    begin
      TThread.NameThreadForDebugging('StorageObject.DownloadToStream');
      try
        Client := THTTPClient.Create;
        try
          Response := Client.Get(DownloadURL, Stream);
          if TFirebaseHelpers.AppIsTerminated then
            exit;
          if Response.StatusCode = 200 then
          begin
            if assigned(OnSuccess) then
              TThread.Queue(nil,
                procedure
                begin
                  OnSuccess(ObjectName, self);
                end);
          end else begin
            {$IFDEF DEBUG}
            TFirebaseHelpers.Log(Response.ContentAsString);
            {$ENDIF}
            ErrMsg := Response.StatusText;
            if assigned(OnError) then
              TThread.Queue(nil,
                procedure
                begin
                  OnError(self, ErrMsg);
                end)
            else if assigned(OnAlternativeError) then
              TThread.Queue(nil,
                procedure
                begin
                  OnAlternativeError(ObjectName, ErrMsg);
                end);
          end;
        finally
          Client.Free;
        end;
      except
        on e: exception do
          begin
            ErrMsg := e.Message;
            if assigned(OnError) then
              TThread.Queue(nil,
                procedure
                begin
                  OnError(self, ErrMsg);
                end)
            else if assigned(OnAlternativeError) then
              TThread.Queue(nil,
                procedure
                begin
                  OnAlternativeError(ObjectName, ErrMsg);
                end);
          end;
      end;
    end).Start;
end;

procedure TStorageObject.DownloadToStream(const ObjectName: TObjectName;
  Stream: TStream; OnSuccess: TOnDownload; OnError: TOnDownloadError);
begin
  InternalDownloadToStream(ObjectName, Stream, OnSuccess, OnError, nil);
end;

procedure TStorageObject.DownloadToStream(const ObjectName: TObjectName;
  Stream: TStream; OnSuccess: TOnDownload; OnError: TOnStorageError);
begin
  InternalDownloadToStream(ObjectName, Stream, OnSuccess, nil, OnError);
end;

function TStorageObject.ObjectName(IncludePath: boolean): string;
begin
  if not fJSONObj.TryGetValue('name', result) then
    raise EStorageObject.Create('JSON field name missing');
  if not IncludePath then
    result := result.SubString(result.LastDelimiter('/') + 1);
end;

class function TStorageObject.GetObjectNameWithoutPath(
  const NameWithPath: string): string;
begin
  result := NameWithPath.SubString(NameWithPath.LastDelimiter('/') + 1);
end;

function TStorageObject.Path: string;
var
  p: integer;
begin
  if not fJSONObj.TryGetValue('name', result) then
    raise EStorageObject.Create('JSON field name missing');
  p := result.LastDelimiter('/');
  if p > 0 then
    result := result.Substring(0, p)
  else
    result := '';
end;

function TStorageObject.LastPathElement: string;
var
  p: integer;
begin
  result := Path;
  p := result.LastDelimiter('/');
  if p > 0 then
    result := result.Substring(p + 1)
end;

function TStorageObject.Size: Int64;
begin
  if not fJSONObj.TryGetValue('size', result) then
    raise EStorageObject.Create('JSON field size missing');
end;

function TStorageObject.Bucket: string;
begin
  if not fJSONObj.TryGetValue('bucket', result) then
    raise EStorageObject.Create('JSON field bucket missing');
end;

function TStorageObject.ContentType: string;
begin
  if not fJSONObj.TryGetValue('contentType', result) then
    raise EStorageObject.Create('JSON field contentType missing');
end;

function TStorageObject.MD5HashCode: string;
begin
  if not fJSONObj.TryGetValue('md5Hash', result) then
    raise EStorageObject.Create('JSON field md5Hash missing');
end;

function TStorageObject.storageClass: string;
begin
  if not fJSONObj.TryGetValue('storageClass', result) then
    raise EStorageObject.Create('JSON field storageClass missing');
end;

function TStorageObject.etag: string;
begin
  if not fJSONObj.TryGetValue('etag', result) then
    raise EStorageObject.Create('JSON field etag missing');
end;

function TStorageObject.generation: Int64;
begin
  if not fJSONObj.TryGetValue('generation', result) then
    raise EStorageObject.Create('JSON field generation missing');
end;

function TStorageObject.metaGeneration: Int64;
begin
  if not fJSONObj.TryGetValue('metageneration', result) then
    raise EStorageObject.Create('JSON field metageneration missing');
end;

end.
