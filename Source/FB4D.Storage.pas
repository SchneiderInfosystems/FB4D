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
    fOnGetStorage: TOnGetStorage;
    fOnDelStorage: TOnDeleteStorage;
    fOnUpload: TOnUploadFromStream;
    fOnGetError, fOnDelError, fOnUploadError: TOnRequestError;
    function BaseURL: string;
    procedure OnGetResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnDelResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnUploadFromStream(const RequestID: string;
      Response: IFirebaseResponse);
  public
    constructor Create(const BucketName: string; Auth: IFirebaseAuthentication);
    procedure Get(const ObjectName, RequestID: string;
      OnGetStorage: TOnGetStorage; OnGetError: TOnRequestError);
    function GetSynchronous(const ObjectName: string): IStorageObject;
    procedure UploadFromStream(Stream: TStream; const ObjectName: string;
      ContentType: TRESTContentType; OnUpload: TOnUploadFromStream;
      OnUploadError: TOnRequestError);
    function UploadSynchronousFromStream(Stream: TStream;
      const ObjectName: string; ContentType: TRESTContentType): IStorageObject;
    procedure Delete(const ObjectName: string; OnDelete: TOnDeleteStorage;
      OnDelError: TOnRequestError);
    procedure DeleteSynchronous(const ObjectName: string);
  end;

  TStorageObject = class(TInterfacedObject, IStorageObject)
  private
    fJSONObj: TJSONObject;
  public
    constructor Create(Response: IFirebaseResponse);
    destructor Destroy; override;
    procedure DownloadToStream(const RequestID: string; Stream: TStream;
      OnSuccess: TOnDownload; OnError: TOnDownloadError);
    procedure DownloadToStreamSynchronous(Stream: TStream);
    function ObjectName(IncludePath: boolean = true): string;
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
begin
  Assert(assigned(Auth), 'Authentication not initalized');
  fBucket := BucketName;
  fAuth := Auth;
end;

function TFirebaseStorage.BaseURL: string;
begin
  result := Format(GOOGLE_STORAGE, [fBucket]);
end;

procedure TFirebaseStorage.Get(const ObjectName, RequestID: string;
  OnGetStorage: TOnGetStorage; OnGetError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  fOnGetStorage := OnGetStorage;
  fOnGetError := OnGetError;
  Request := TFirebaseRequest.Create(BaseURL, RequestID, fAuth);
  Request.SendRequest([ObjectName], rmGet, nil, nil, tmBearer, OnGetResponse,
    OnGetError);
end;

procedure TFirebaseStorage.OnGetResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  try
    Response.CheckForJSONObj;
    if assigned(fOnGetStorage) then
      fOnGetStorage(RequestID, TStorageObject.Create(Response))
    else
      TFirebaseHelpers.Log(Response.ContentAsString);
  except
    on e: Exception do
    begin
      if assigned(fOnGetError) then
        fOnGetError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
    end;
  end;
end;

function TFirebaseStorage.GetSynchronous(
  const ObjectName: string): IStorageObject;
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
end;

function TFirebaseStorage.UploadSynchronousFromStream(Stream: TStream;
  const ObjectName: string; ContentType: TRESTContentType): IStorageObject;
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
  finally
    QueryParams.Free;
  end;
end;

procedure TFirebaseStorage.UploadFromStream(Stream: TStream;
  const ObjectName: string; ContentType: TRESTContentType;
  OnUpload: TOnUploadFromStream; OnUploadError: TOnRequestError);
var
  Request: IFirebaseRequest;
  QueryParams: TQueryParams;
begin
  fOnUpload := OnUpload;
  fOnUploadError := OnUploadError;
  // Because of RSP-23318 the resource parameters shall not be empty when using
  // query parameters
  // https://quality.embarcadero.com/browse/RSP-23318
  // That is why in the workaround the last segement of the URL must be removed
  // from the Base URL and added as first resource parameter.
  Request := TFirebaseRequest.Create(Copy(BaseURL, 1, length(BaseURL) - 2),
    ObjectName, fAuth);
  QueryParams := TQueryParams.Create;
  try
    QueryParams.Add('uploadType', ['media']);
    QueryParams.Add('name',  [ObjectName]);
    Request.SendRequest([BaseURL[length(BaseURL)]], rmPost, Stream, ContentType,
      QueryParams, tmBearer, OnUploadFromStream, fOnUploadError);
  finally
    QueryParams.Free;
  end;
end;

procedure TFirebaseStorage.OnUploadFromStream(const RequestID: string;
  Response: IFirebaseResponse);
begin
  try
    Response.CheckForJSONObj;
    if assigned(fOnUpload) then
      fOnUpload(RequestID, TStorageObject.Create(Response))
    else
      TFirebaseHelpers.Log(Response.ContentAsString);
  except
    on e: Exception do
    begin
      if assigned(fOnUploadError) then
        fOnUploadError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
    end;
  end;
end;

procedure TFirebaseStorage.DeleteSynchronous(const ObjectName: string);
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
  end;
end;

procedure TFirebaseStorage.Delete(const ObjectName: string;
  OnDelete: TOnDeleteStorage; OnDelError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  fOnDelStorage := OnDelete;
  fOnDelError := OnDelError;
  Request := TFirebaseRequest.Create(BaseURL, ObjectName, fAuth);
  Request.SendRequest([ObjectName], rmDelete, nil, nil, tmBearer, OnDelResponse,
    OnDelError);
end;

procedure TFirebaseStorage.OnDelResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  try
    if Response.StatusOk then
    begin
      if assigned(fOnDelStorage) then
        fOnDelStorage(RequestID)
    end
    else if assigned(fOnDelError) then
      fOnDelError(RequestID, Response.ErrorMsgOrStatusText)
    else
      TFirebaseHelpers.Log(Format(rsFBFailureIn,
        [RequestID, Response.ErrorMsgOrStatusText]));
  except
    on e: Exception do
    begin
      if assigned(fOnDelError) then
        fOnDelError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
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

procedure TStorageObject.DownloadToStream(const RequestID: string; Stream: TStream;
  OnSuccess: TOnDownload; OnError: TOnDownloadError);
var
  ErrMsg: string;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Client: THTTPClient;
      Response: IHTTPResponse;
    begin
      TThread.NameThreadForDebugging('StorageObject.DownloadToStream');
      try
        Client := THTTPClient.Create;
        try
          Response := Client.Get(DownloadUrl, Stream);
          if TFirebaseHelpers.AppIsTerminated then
            exit;
          if Response.StatusCode = 200 then
          begin
            if assigned(OnSuccess) then
              TThread.Queue(nil,
                procedure
                begin
                  OnSuccess(RequestID, self);
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
                end);
          end;
        finally
          Client.Free;
        end;
      except
        on e: exception do
          if assigned(OnError) then
          begin
            ErrMsg := e.Message;
            TThread.Queue(nil,
              procedure
              begin
                OnError(self, ErrMsg);
              end);
          end;
      end;
    end).Start;
end;

function TStorageObject.ObjectName(IncludePath: boolean): string;
begin
  if not fJSONObj.TryGetValue('name', result) then
    raise EStorageObject.Create('JSON field name missing');
  if not IncludePath then
    result := result.SubString(result.LastDelimiter('/') + 1);
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
