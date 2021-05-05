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
  System.Classes, System.JSON, System.SysUtils, System.SyncObjs,
  System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request;

type
  TFirebaseStorage = class(TInterfacedObject, IFirebaseStorage)
  private type
    TCacheFile = class
      FileName: string;
      MD5Hash: string;
      LastUpdate: TDateTime;
      FileSize: Int64;
      constructor AddToCache(const aFileName: string; FSize: Int64 = 0);
    end;
  private
    fBucket: string;
    fAuth: IFirebaseAuthentication;
    fStorageObjs: TDictionary<TObjectName, IStorageObject>;
    fCacheFolder: string;
    fMaxCacheSpaceInBytes: Int64;
    fCacheSpaceInBytes: Int64;
    fCacheContent: TList<TCacheFile>;
    fScanSync: TCriticalSection;
    fScanFinished: TDateTime;
    fLastUpdateRemovedFromCache: TDateTime;
    function BaseURL: string;
    procedure OnGetResponse(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
    procedure OnGetAndDownloadResponse(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
    procedure OnDelResponse(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
    procedure OnUploadFromStream(const ObjectName: TObjectName;
      Response: IFirebaseResponse);
    procedure ScanCacheFolder;
    procedure ReduceCacheSize;
    procedure AddToCache(StorageObj: IStorageObject; Stream: TStream);
    function CheckInCache(StorageObj: IStorageObject; Stream: TStream): boolean;
    function DeleteFileFromCache(const FileName: string): boolean;
    procedure DeleteObjectFromCache(const ObjectName: TObjectName);
  public
    constructor Create(const BucketName: string; Auth: IFirebaseAuthentication);
    destructor Destroy; override;

    procedure Get(const ObjectName: TObjectName; OnGetStorage: TOnStorage;
      OnGetError: TOnStorageError); overload;
    procedure Get(const ObjectName, RequestID: string;
      OnGetStorage: TOnStorageDeprecated; OnGetError: TOnRequestError);
      overload; { deprecated }
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

    // Long-term storage (beyond the runtime of the app) of loaded storage files
    procedure SetupCacheFolder(const FolderName: string;
      MaxCacheSpaceInBytes: Int64 = cDefaultCacheSpaceInBytes);
    function IsCacheInUse: boolean;
    function IsCacheScanFinished: boolean;
    procedure ClearCache;
    function CacheUsageInPercent: extended;
    function IsCacheOverflowed: boolean;
  end;

  TStorageObject = class(TInterfacedObject, IStorageObject)
  private
    fFirebaseStorage: TFirebaseStorage;
    fJSONObj: TJSONObject;
    procedure InternalDownloadToStream(Stream: TStream;
      OnSuccess: TOnDownload; OnError: TOnDownloadError;
      OnAlternativeError: TOnStorageError; const ObjectName: string = '';
      OnDeprecatedSuccess: TOnDownloadDeprecated = nil);
  public
    constructor Create(FirebaseStorage: TFirebaseStorage;
      Response: IFirebaseResponse);
    destructor Destroy; override;
    procedure DownloadToStream(Stream: TStream; OnSuccess: TOnDownload;
      OnError: TOnDownloadError); overload;
    procedure DownloadToStream(Stream: TStream; OnSuccess: TOnDownload;
      OnError: TOnStorageError); overload;
    procedure DownloadToStream(const ObjectName: TObjectName; Stream: TStream;
      OnSuccess: TOnDownloadDeprecated; OnError: TOnDownloadError);
      overload; { deprecated }
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
    function CacheFileName: string;
    class function CalcCacheFileName(const NameWithPath: string): string;
  end;

implementation

uses
  System.NetConsts, System.NetEncoding, System.StrUtils, System.IOUtils,
  System.Generics.Defaults, System.Hash,
{$IFDEF POSIX}
  Posix.Unistd,
{$ENDIF}
  IdGlobalProtocols,
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
  fBucket := ExcludeTrailingSlash(BucketName);
  fAuth := Auth;
  fStorageObjs := TDictionary<TObjectName, IStorageObject>.Create;
  fCacheFolder := '';
  fMaxCacheSpaceInBytes := 0;
  fCacheContent := TList<TCacheFile>.Create;
  fScanSync := TCriticalSection.Create;
end;

destructor TFirebaseStorage.Destroy;
var
  CacheF: TCacheFile;
begin
  fScanSync.Free;
  for CacheF in fCacheContent do
    CacheF.Free;
  fCacheContent.Free;
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

procedure TFirebaseStorage.Get(const ObjectName, RequestID: string;
  OnGetStorage: TOnStorageDeprecated; OnGetError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(BaseURL, RequestID, fAuth);
  Request.SendRequest([ObjectName], rmGet, nil, nil, tmBearer, OnGetResponse,
    OnGetError, TOnSuccess.CreateStorageDeprecated(OnGetStorage));
end;

procedure TFirebaseStorage.OnGetResponse(const ObjectName: TObjectName;
  Response: IFirebaseResponse);
var
  StorageObj: TStorageObject;
begin
  try
    Response.CheckForJSONObj;
    StorageObj := TStorageObject.Create(self, Response);
    fStorageObjs.TryAdd(ObjectName, StorageObJ);
    case Response.OnSuccess.OnSuccessCase of
      oscStorage:
        if assigned(Response.OnSuccess.OnStorage) then
         Response.OnSuccess.OnStorage(StorageObj);
      oscStorageDeprecated:
        if assigned(Response.OnSuccess.OnStorageDeprecated) then
          Response.OnSuccess.OnStorageDeprecated(ObjectName, StorageObj);
      else
        TFirebaseHelpers.Log('FirebaseStorage.OnGetResponse ' +
          Response.ContentAsString);
    end;
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirebaseStorage.OnGetResponse', ObjectName, e.Message]);
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
  TFirebaseHelpers.Log('FirebaseStorage.GetSynchronous ' +
    Response.ContentAsString);
  {$ENDIF}
  Response.CheckForJSONObj;
  result := TStorageObject.Create(self, Response);
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
    StorageObJ := TStorageObject.Create(self, Response);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log('FirebaseStorage.OnGetAndDownloadResponse ' +
      Response.ContentAsString);
    {$ENDIF}
    fStorageObjs.TryAdd(ObjectName, StorageObJ);
    if assigned(Response.OnSuccess.OnStorageGetAndDown) then
      StorageObj.DownloadToStream(Response.OnSuccess.DownStream,
        Response.OnSuccess.OnStorageGetAndDown,
        Response.OnSuccess.OnStorageError);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirebaseStorage.OnGetAndDownloadResponse', ObjectName, e.Message]);
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
  TFirebaseHelpers.Log('FirebaseStorage.GetAndDownloadSynchronous ' +
    Response.ContentAsString);
  {$ENDIF}
  Response.CheckForJSONObj;
  result := TStorageObject.Create(self, Response);
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
    TFirebaseHelpers.Log('FirebaseStorage.UploadSynchronousFromStream ' +
      Response.ContentAsString);
    {$ENDIF}
    result := TStorageObject.Create(self, Response);
    fStorageObjs.TryAdd(ObjectName, result);
    AddToCache(result, Stream);
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
  // RSP-23318 is solved yet. Delphi 10.3.1 and earlier is no longer recommended
  Request := TFirebaseRequest.Create(BaseURL, ObjectName, fAuth);
  QueryParams := TQueryParams.Create;
  try
    QueryParams.Add('uploadType', ['media']);
    QueryParams.Add('name',  [ObjectName]);
    Request.SendRequest([], rmPost, Stream, ContentType,
      QueryParams, tmBearer, OnUploadFromStream, OnUploadError,
      TOnSuccess.CreateStorageUpload(OnUpload, Stream));
  finally
    QueryParams.Free;
  end;
end;

procedure TFirebaseStorage.OnUploadFromStream(const ObjectName: TObjectName;
  Response: IFirebaseResponse);
var
  StorageObj: IStorageObject;
begin
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirebaseStorage.OnUploadFromStream ' +
    Response.ContentAsString);
  {$ENDIF}
  try
    Response.CheckForJSONObj;
    StorageObj := TStorageObject.Create(self, Response);
    fStorageObjs.TryAdd(ObjectName, StorageObj);
    if assigned(Response.OnSuccess.UpStream) then
      AddToCache(StorageObj, Response.OnSuccess.UpStream);
    if assigned(Response.OnSuccess.OnStorageUpload) then
      Response.OnSuccess.OnStorageUpload(StorageObj)
    else
      TFirebaseHelpers.Log('FirebaseStorage.OnUploadFromStream ' +
        Response.ContentAsString);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirebaseStorage.OnUploadFromStream', ObjectName, e.Message]);
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
    TFirebaseHelpers.Log('FirebaseStorage.DeleteSynchronous: ' +
      Response.ContentAsString);
    {$ENDIF}
    raise EStorageObject.CreateFmt('Delete failed: %s', [Response.StatusText]);
  end else begin
    fStorageObjs.Remove(ObjectName);
    DeleteObjectFromCache(ObjectName);
  end;
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
      DeleteObjectFromCache(ObjectName);
    end
    else if assigned(Response.OnError) then
      Response.OnError(ObjectName, Response.ErrorMsgOrStatusText)
    else
      TFirebaseHelpers.LogFmt(rsFBFailureIn, ['FirebaseStorage.OnDelResponse',
        ObjectName, Response.ErrorMsgOrStatusText]);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(ObjectName, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirebaseStorage.OnDelResponse', ObjectName, e.Message]);
    end;
  end;
end;

{$REGION 'Cache Handling'}
procedure TFirebaseStorage.SetupCacheFolder(const FolderName: string;
  MaxCacheSpaceInBytes: Int64);
begin
  Assert(MaxCacheSpaceInBytes > 0, 'Invalid max cache space');
  Assert(not FolderName.IsEmpty, 'Empty cache folder not allowed');
  fCacheFolder := IncludeTrailingPathDelimiter(FolderName);
  fMaxCacheSpaceInBytes := MaxCacheSpaceInBytes;
  if not TDirectory.Exists(fCacheFolder) then
    TDirectory.CreateDirectory(fCacheFolder);
  ScanCacheFolder;
end;

procedure TFirebaseStorage.ClearCache;
var
  CacheF: TCacheFile;
begin
  fScanSync.Acquire;
  try
    for CacheF in fCacheContent do
      CacheF.Free;
    fCacheContent.Clear;
    fCacheSpaceInBytes := 0;
  finally
    fScanSync.Release;
  end;
  if TDirectory.Exists(fCacheFolder) then
    TDirectory.Delete(fCacheFolder, true);
end;

procedure TFirebaseStorage.ScanCacheFolder;
begin
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirebaseStorage.ScanCacheFolder start ' + fCacheFolder);
  {$ENDIF}
  TThread.CreateAnonymousThread(
    procedure
    var
      FileName: string;
      CacheFile: TCacheFile;
    begin
      {$IFNDEF LINUX64}
      TThread.NameThreadForDebugging('StorageObject.ScanCacheFolder');
      {$ENDIF}
      fScanSync.Acquire;
      try
        fScanFinished := 0;
        fCacheSpaceInBytes := 0;
        for FileName in TDirectory.GetFiles(fCacheFolder) do
        begin
          CacheFile := TCacheFile.AddToCache(FileName);
          if TFirebaseHelpers.AppIsTerminated then
            exit
          else begin
            fCacheSpaceInBytes := fCacheSpaceInBytes + CacheFile.FileSize;
            fCacheContent.Add(CacheFile);
          end;
        end;
        if fCacheSpaceInBytes > fMaxCacheSpaceInBytes then
          ReduceCacheSize;
        {$IFDEF DEBUG}
        TFirebaseHelpers.LogFmt(
          'FirebaseStorage.ScanCacheFolder finished, cache size %dB (%4.2f%%)',
          [fCacheSpaceInBytes, CacheUsageInPercent]);
        {$ENDIF}
        fScanFinished := now;
        fScanSync.Release;
      except
        on e: exception do
          TFirebaseHelpers.Log('StorageObject.ScanCacheFolder Exception: ' +
            e.Message);
      end;
    end).Start;
end;

function TFirebaseStorage.IsCacheScanFinished: boolean;
begin
  result := fScanFinished > 0;
end;

function TFirebaseStorage.IsCacheInUse: boolean;
begin
  result := not fCacheFolder.IsEmpty and (fMaxCacheSpaceInBytes > 0);
end;

function TFirebaseStorage.IsCacheOverflowed: boolean;
begin
  result := fLastUpdateRemovedFromCache > fScanFinished;
end;

procedure TFirebaseStorage.AddToCache(StorageObj: IStorageObject;
  Stream: TStream);
var
  FileName: string;
  CacheFile: TCacheFile;
  FileStream: TFileStream;
  FSize: Int64;
begin
  if IsCacheInUse then
  begin
    FileName := fCacheFolder + StorageObj.CacheFileName;
    FileStream := TFileStream.Create(FileName, fmCreate);
    try
      Stream.Position := 0;
      FileStream.CopyFrom(Stream, Stream.Size);
      FSize := Stream.Size;
    finally
      FileStream.Free;
    end;
    if FSize < fMaxCacheSpaceInBytes then
    begin
      CacheFile := TCacheFile.AddToCache(FileName, FSize);
      fScanSync.Acquire;
      try
        fCacheSpaceInBytes := fCacheSpaceInBytes + CacheFile.FileSize;
        fCacheContent.Add(CacheFile);
      finally
        fScanSync.Release;
      end;
      if fCacheSpaceInBytes > fMaxCacheSpaceInBytes then
        ReduceCacheSize;
    end;
  end;
end;

function TFirebaseStorage.CacheUsageInPercent: extended;
begin
  result := fCacheSpaceInBytes * 100 / fMaxCacheSpaceInBytes;
end;

function  TFirebaseStorage.CheckInCache(StorageObj: IStorageObject;
  Stream: TStream): boolean;
var
  FileName: string;
  CacheFile: TCacheFile;
  FileStream: TFileStream;
begin
  if IsCacheInUse then
  begin
    FileName := fCacheFolder + StorageObj.CacheFileName;
    fScanSync.Acquire;
    try
      for CacheFile in fCacheContent do
        if CacheFile.FileName = FileName then
        begin
          if CacheFile.MD5Hash = StorageObj.MD5HashCode then
          begin
            FileStream := TFileStream.Create(FileName,
              fmShareDenyNone or fmOpenRead);
            try
              Stream.CopyFrom(FileStream, Stream.Size);
            finally
              FileStream.Free;
            end;
            exit(true);
          end else
            exit(false); // Newer version in storage > file must be updated
        end;
    finally
      fScanSync.Release;
    end;
    result := false; // not in Cache
  end else
    result := false;
end;

procedure TFirebaseStorage.DeleteObjectFromCache(const ObjectName: TObjectName);
begin
  if IsCacheInUse then
  begin
    fScanSync.Acquire;
    try
      DeleteFileFromCache(
        fCacheFolder + TStorageObject.CalcCacheFileName(ObjectName));
    finally
      fScanSync.Release;
    end;
  end;
end;

function TFirebaseStorage.DeleteFileFromCache(const FileName: string): boolean;
var
  CacheFile: TCacheFile;
begin
  result := false;
  for CacheFile in fCacheContent do
    if CacheFile.FileName = FileName then
    begin
      fCacheContent.Remove(CacheFile);
      fCacheSpaceInBytes := fCacheSpaceInBytes - CacheFile.FileSize;
      CacheFile.Free;
      DeleteFile(FileName);
      result := true;
      break;
    end;
end;

procedure TFirebaseStorage.ReduceCacheSize;
const
  cMaxUsageAfterClean = 90; // in % of fMaxCacheSpaceInBytes
var
  CacheFile: TCacheFile;
  Usage: extended;
  {$IFDEF DEBUG}
  Count: integer;
  {$ENDIF}
begin
  fScanSync.Acquire;
  try
    fCacheContent.Sort(TComparer<TCacheFile>.Construct(
      function(const Left, Right: TCacheFile): Integer
      begin
        if Left.LastUpdate < Right.LastUpdate then
          result := -1
        else if Left.LastUpdate = Right.LastUpdate then
          result := 0
        else
          result := 1;
      end));
    {$IFDEF DEBUG}
    Count := 0;
    {$ENDIF}
    repeat
      CacheFile := fCacheContent.Items[0];
      fLastUpdateRemovedFromCache := CacheFile.LastUpdate;
      if TFirebaseHelpers.AppIsTerminated or
         not DeleteFileFromCache(CacheFile.FileName) then
        exit
      else begin
        {$IFDEF DEBUG}
        inc(Count);
        {$ENDIF}
      end;
      Usage := CacheUsageInPercent;
    until (Usage < cMaxUsageAfterClean) or (fCacheContent.Count = 0);
  finally
    fScanSync.Release;
  end;
  {$IFDEF DEBUG}
  TFirebaseHelpers.LogFmt('FirebaseStorage.StartReduceCacheSize finished, ' +
    '%d cache file deleted (Remain usage: %4.2f%%)', [Count, Usage]);
  {$ENDIF}
end;
{$ENDREGION}

{ TFirestoreObject }

constructor TStorageObject.Create(FirebaseStorage: TFirebaseStorage;
  Response: IFirebaseResponse);
begin
  fFirebaseStorage := FirebaseStorage;
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
  if not fFirebaseStorage.CheckInCache(self, Stream) then
  begin
    Client := THTTPClient.Create;
    try
      Response := Client.Get(DownloadUrl, Stream);
      if Response.StatusCode = 200 then
        fFirebaseStorage.AddToCache(self, Stream)
      else begin
        {$IFDEF DEBUG}
        TFirebaseHelpers.Log('StorageObject.DownloadToStreamSynchronous ' +
          Response.ContentAsString);
        {$ENDIF}
        raise EStorageObject.CreateFmt('Download failed: %s',
          [Response.StatusText]);
      end;
    finally
      Client.Free;
    end;
  end;
end;

procedure TStorageObject.InternalDownloadToStream(Stream: TStream;
  OnSuccess: TOnDownload; OnError: TOnDownloadError;
  OnAlternativeError: TOnStorageError; const ObjectName: string = '';
  OnDeprecatedSuccess: TOnDownloadDeprecated = nil);
begin
  Assert(assigned(fFirebaseStorage), 'Storage reference missing');
  if fFirebaseStorage.CheckInCache(self, Stream) then
  begin
    if assigned(OnSuccess) then
      OnSuccess(self);
  end else
    TThread.CreateAnonymousThread(
      procedure
      var
        Client: THTTPClient;
        Response: IHTTPResponse;
        ErrMsg: string;
      begin
        {$IFNDEF LINUX64}
        TThread.NameThreadForDebugging('StorageObject.DownloadToStream');
        {$ENDIF}
        try
          Client := THTTPClient.Create;
          try
            Response := Client.Get(DownloadURL, Stream);
            if TFirebaseHelpers.AppIsTerminated then
              exit;
            if Response.StatusCode = 200 then
            begin
              if assigned(OnSuccess) then
                TThread.Synchronize(nil,
                  procedure
                  begin
                    fFirebaseStorage.AddToCache(self, Stream);
                    OnSuccess(self);
                  end)
              else if assigned(OnDeprecatedSuccess) then
                TThread.Synchronize(nil,
                  procedure
                  begin
                    fFirebaseStorage.AddToCache(self, Stream);
                    OnDeprecatedSuccess(ObjectName, self);
                  end);
            end else begin
              {$IFDEF DEBUG}
              TFirebaseHelpers.Log('StorageObject.DownloadToStream failure: ' +
                Response.ContentAsString);
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
              if assigned(OnError) and not TFirebaseHelpers.AppIsTerminated then
                TThread.Queue(nil,
                  procedure
                  begin
                    OnError(self, ErrMsg);
                  end)
              else if assigned(OnAlternativeError) and
                not TFirebaseHelpers.AppIsTerminated then
                TThread.Queue(nil,
                  procedure
                  begin
                    OnAlternativeError(ObjectName, ErrMsg);
                  end)
              else
                TFirebaseHelpers.Log(
                  'StorageObject.DownloadToStream Exception: ' + ErrMsg);
            end;
        end;
      end).Start;
end;

procedure TStorageObject.DownloadToStream(Stream: TStream;
  OnSuccess: TOnDownload; OnError: TOnDownloadError);
begin
  InternalDownloadToStream(Stream, OnSuccess, OnError, nil);
end;

procedure TStorageObject.DownloadToStream(Stream: TStream;
  OnSuccess: TOnDownload; OnError: TOnStorageError);
begin
  InternalDownloadToStream(Stream, OnSuccess, nil, OnError);
end;

procedure TStorageObject.DownloadToStream(const ObjectName: TObjectName;
  Stream: TStream; OnSuccess: TOnDownloadDeprecated; OnError: TOnDownloadError);
begin
  InternalDownloadToStream(Stream, nil, OnError, nil, ObjectName, OnSuccess);
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

function TStorageObject.CacheFileName: string;
begin
  result := CalcCacheFileName(ObjectName);
end;

class function TStorageObject.CalcCacheFileName(
  const NameWithPath: string): string;
begin
  result := THashMD5.GetHashString(NameWithPath);
end;

{ TFirebaseStorage.TCacheFile }

constructor TFirebaseStorage.TCacheFile.AddToCache(const aFileName: string;
  FSize: Int64);
begin
  FileName := aFileName;
  MD5Hash := TNetEncoding.Base64.EncodeBytesToString(
    THashMD5.GetHashBytesFromFile(FileName));
  LastUpdate := TFile.GetLastWriteTime(FileName);
  if FSize > 0 then
    FileSize := FSize
  else
    FileSize := FileSizeByName(FileName);
  {$IFDEF DEBUG}
  TFirebaseHelpers.LogFmt(
    'CacheFile.AddToCache %s (Size: %dB,DateTimeUTC: %s,MD5: %s)',
    [FileName, FileSize, DateTimeToStr(LastUpdate), MD5Hash]);
  {$ENDIF}
end;

end.
