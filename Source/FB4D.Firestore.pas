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

unit FB4D.Firestore;

interface

uses
  System.Classes, System.Types, System.JSON, System.SysUtils,
  System.Net.HttpClient, System.Net.URLClient,
  System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request, FB4D.Document,
  FB4D.FireStore.Listener;

type
  TFirestoreDatabase = class(TInterfacedObject, IFirestoreDatabase)
  private
    fProjectID: string;
    fDatabaseID: string;
    fAuth: IFirebaseAuthentication;
    fListener: TFSListenerThread;
    fLastReceivedMsg: TDateTime;
    function BaseURI: string;
    procedure OnQueryResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnGetResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnCreateResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnInsertOrUpdateResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnPatchResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnDeleteResponse(const RequestID: string;
      Response: IFirebaseResponse);
    procedure BeginReadTransactionResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure CommitWriteTransactionResp(const RequestID: string;
      Response: IFirebaseResponse);
  public
    constructor Create(const ProjectID: string; Auth: IFirebaseAuthentication;
      const DatabaseID: string = cDefaultDatabaseID);
    destructor Destroy; override;
    function GetProjectID: string;
    function GetDatabaseID: string;
    procedure RunQuery(StructuredQuery: IStructuredQuery;
      OnDocuments: TOnDocuments; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil); overload;
    procedure RunQuery(DocumentPath: TRequestResourceParam;
      StructuredQuery: IStructuredQuery; OnDocuments: TOnDocuments;
      OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil); overload;
    function RunQuerySynchronous(StructuredQuery: IStructuredQuery;
      QueryParams: TQueryParams = nil): IFirestoreDocuments; overload;
    function RunQuerySynchronous(DocumentPath: TRequestResourceParam;
      StructuredQuery: IStructuredQuery;
      QueryParams: TQueryParams = nil): IFirestoreDocuments; overload;
    procedure Get(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnDocuments: TOnDocuments; OnRequestError: TOnRequestError);
    function GetSynchronous(Params: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirestoreDocuments;
    function GetAndAddSynchronous(var Docs: IFirestoreDocuments;
      Params: TRequestResourceParam; QueryParams: TQueryParams = nil): boolean;
    procedure CreateDocument(DocumentPath: TRequestResourceParam;
      QueryParams: TQueryParams; OnDocument: TOnDocument;
      OnRequestError: TOnRequestError);
    function CreateDocumentSynchronous(DocumentPath: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirestoreDocument;
    procedure InsertOrUpdateDocument(DocumentPath: TRequestResourceParam;
      Document: IFirestoreDocument; QueryParams: TQueryParams;
      OnDocument: TOnDocument; OnRequestError: TOnRequestError); overload;
    procedure InsertOrUpdateDocument(Document: IFirestoreDocument;
      QueryParams: TQueryParams; OnDocument: TOnDocument;
      OnRequestError: TOnRequestError); overload;
    function InsertOrUpdateDocumentSynchronous(
      DocumentPath: TRequestResourceParam; Document: IFirestoreDocument;
      QueryParams: TQueryParams = nil): IFirestoreDocument; overload;
    function InsertOrUpdateDocumentSynchronous(Document: IFirestoreDocument;
      QueryParams: TQueryParams = nil): IFirestoreDocument; overload;
    procedure PatchDocument(DocumentPath: TRequestResourceParam;
      DocumentPart: IFirestoreDocument; UpdateMask: TStringDynArray;
      OnDocument: TOnDocument; OnRequestError: TOnRequestError;
      Mask: TStringDynArray = []);
    function PatchDocumentSynchronous(DocumentPath: TRequestResourceParam;
      DocumentPart: IFirestoreDocument; UpdateMask: TStringDynArray;
      Mask: TStringDynArray = []): IFirestoreDocument;
    procedure Delete(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnDeleteResp: TOnFirebaseResp; OnRequestError: TOnRequestError);
    function DeleteSynchronous(Params: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirebaseResponse;
    // Listener subscription
    function SubscribeDocument(DocPath: TRequestResourceParam;
      OnChangedDoc: TOnChangedDocument;
      OnDeletedDoc: TOnDeletedDocument): cardinal;
    function SubscribeQuery(Query: IStructuredQuery;
      OnChangedDoc: TOnChangedDocument;
      OnDeletedDoc: TOnDeletedDocument;
      DocPath: TRequestResourceParam = []): cardinal;
    procedure Unsubscribe(TargetID: cardinal);
    procedure StartListener(OnStopListening: TOnStopListenEvent;
      OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent = nil;
      OnConnectionStateChange: TOnConnectionStateChange = nil;
      DoNotSynchronizeEvents: boolean = false);
    procedure StopListener(RemoveAllSubscription: boolean = true);
    function GetTimeStampOfLastAccess: TDateTime;
    // Transaction
    procedure BeginReadTransaction(
      OnBeginReadTransaction: TOnBeginReadTransaction;
      OnRequestError: TOnRequestError);
    function BeginReadTransactionSynchronous: TFirestoreReadTransaction;
    function BeginWriteTransaction: IFirestoreWriteTransaction;
    function CommitWriteTransactionSynchronous(
      Transaction: IFirestoreWriteTransaction): IFirestoreCommitTransaction;
    procedure CommitWriteTransaction(Transaction: IFirestoreWriteTransaction;
      OnCommitWriteTransaction: TOnCommitWriteTransaction;
      OnRequestError: TOnRequestError);
  end;

  TStructuredQuery = class(TInterfacedObject, IStructuredQuery)
  private
    fColSelector, fQuery: TJSONObject;
    fFilter, fSelect: TJSONObject;
    fOrder: TJSONArray;
    fStartAt, fEndAt: TJSONObject;
    fLimit, fOffset: integer;
    fInfo: string;
    function GetCursorArr(Cursor: IFirestoreDocument): TJSONArray;
  public
    class function CreateForCollection(const CollectionId: string;
      IncludesDescendants: boolean = false): IStructuredQuery;
    class function CreateForSelect(FieldRefs:
      TRequestResourceParam): IStructuredQuery;
    constructor Create;
    destructor Destroy; override;
    function Select(FieldRefs: TRequestResourceParam): IStructuredQuery;
    function Collection(const CollectionId: string;
      IncludesDescendants: boolean = false): IStructuredQuery;
    function QueryForFieldFilter(Filter: IQueryFilter): IStructuredQuery;
    function QueryForCompositeFilter(CompostiteOperation: TCompostiteOperation;
      Filters: array of IQueryFilter): IStructuredQuery;
    function OrderBy(const FieldRef: string;
      Direction: TOrderDirection): IStructuredQuery;
    function StartAt(Cursor: IFirestoreDocument;
      Before: boolean): IStructuredQuery;
    function EndAt(Cursor: IFirestoreDocument;
      Before: boolean): IStructuredQuery;
    function Limit(limit: integer): IStructuredQuery;
    function Offset(offset: integer): IStructuredQuery;
    function AsJSON: TJSONObject;
    function GetInfo: string;
    function HasSelect: boolean;
    function HasColSelector: boolean;
    function HasFilter: boolean;
    function HasOrder: boolean;
    function HasStartAt: boolean;
    function HasEndAt: boolean;
  end;

  TQueryFilter = class(TInterfacedObject, IQueryFilter)
  private
    fInfo: string;
    fFilter: TJSONObject;
  public
    class function IntegerFieldFilter(const WhereFieldPath: string;
      WhereOperator: TWhereOperator; WhereValue: integer): IQueryFilter;
    class function DoubleFieldFilter(const WhereFieldPath: string;
      WhereOperator: TWhereOperator; WhereValue: double): IQueryFilter;
    class function StringFieldFilter(const WhereFieldPath: string;
      WhereOperator: TWhereOperator; const WhereValue: string): IQueryFilter;
    class function BooleanFieldFilter(const WhereFieldPath: string;
      WhereOperator: TWhereOperator; WhereValue: boolean): IQueryFilter;
    class function TimestampFieldFilter(const WhereFieldPath: string;
      WhereOperator: TWhereOperator; WhereValue: TDateTime): IQueryFilter;
      static;
    constructor Create(const Where, Value: string; Op: TWhereOperator);
    procedure AddPair(const Str: string; Val: TJSONValue); overload;
    procedure AddPair(const Str, Val: string); overload;
    function AsJSON: TJSONObject;
    function GetInfo: string;
  end;

  TFirestoreWriteTransaction = class(TInterfacedObject,
    IFirestoreWriteTransaction)
  private
    fWritesObjArray: TJSONArray;
  public
    constructor Create;
    destructor Destroy; override;
    function NumberOfTransactions: cardinal;
    procedure UpdateDoc(Document: IFirestoreDocument);
    procedure PatchDoc(Document: IFirestoreDocument;
      UpdateMask: TStringDynArray);
    procedure DeleteDoc(const DocumentFullPath: string);
    function GetWritesObjArray: TJSONArray;
  end;

  TFirestoreCommitTransaction = class(TInterfacedObject,
    IFirestoreCommitTransaction)
  private
    fUpdateTime: array of TDateTime;
    fCommitTime: TDateTime;
  public
    constructor Create(Response: IFirebaseResponse);
    function CommitTime(TimeZone: TTimeZone = tzUTC): TDateTime;
    function NoUpdates: cardinal;
    function UpdateTime(Index: cardinal; TimeZone: TTimeZone = tzUTC): TDateTime;
  end;
implementation

uses
  FB4D.Helpers;

const
  GOOGLE_FIRESTORE_API_URL =
    'https://firestore.googleapis.com/v1beta1';
  GOOGLE_FIRESTORE_API_URL_DOCUMENTS =
    GOOGLE_FIRESTORE_API_URL + '/projects/%0:s/databases/%1:s/documents';
  METHODE_RUNQUERY = ':runQuery';
  METHODE_BEGINTRANS = ':beginTransaction';
  METHODE_COMMITTRANS = ':commit';
  METHODE_ROLLBACK = ':rollback';
  FILTER_OERATION: array [TWhereOperator] of string = ('OPERATOR_UNSPECIFIED',
    'LESS_THAN', 'LESS_THAN_OR_EQUAL', 'GREATER_THAN',
    'GREATER_THAN_OR_EQUAL', 'EQUAL', 'ARRAY_CONTAINS');
  COMPOSITEFILTER_OPERATION: array [TCompostiteOperation] of string = (
    'OPERATOR_UNSPECIFIED', 'AND');
  ORDER_DIRECTION: array [TOrderDirection] of string = ('DIRECTION_UNSPECIFIED',
    'ASCENDING', 'DESCENDING');

resourcestring
  rsRunQuery = 'Run query for ';
  rsGetDocument = 'Get document for ';
  rsCreateDoc = 'Create document for ';
  rsInsertOrUpdateDoc = 'Insert or update document for ';
  rsPatchDoc = 'Patch document for ';
  rsDeleteDoc = 'Delete document for ';
  rsBeginTrans = 'Begin transaction';
  rsCommitTrans = 'Commit transaction';
  rsRollBackTrans = 'Roll back transaction';

{ TFirestoreDatabase }

constructor TFirestoreDatabase.Create(const ProjectID: string;
  Auth: IFirebaseAuthentication; const DatabaseID: string);
begin
  inherited Create;
  Assert(assigned(Auth), 'Authentication not initalized');
  fProjectID := ProjectID;
  fAuth := Auth;
  fDatabaseID := DatabaseID;
  fListener := TFSListenerThread.Create(ProjectID, DatabaseID, Auth);
  fLastReceivedMsg := 0;
end;

destructor TFirestoreDatabase.Destroy;
begin
  if fListener.IsRunning then
    fListener.StopListener
  else
    fListener.StopNotStarted;
  fListener.Free;
  inherited;
end;

function TFirestoreDatabase.BaseURI: string;
begin
  result := Format(GOOGLE_FIRESTORE_API_URL_DOCUMENTS,
    [fProjectID, fDatabaseID]);
end;

procedure TFirestoreDatabase.RunQuery(StructuredQuery: IStructuredQuery;
  OnDocuments: TOnDocuments; OnRequestError: TOnRequestError;
  QueryParams: TQueryParams = nil);
var
  Request: IFirebaseRequest;
  Query: TJSONObject;
begin
  Request := TFirebaseRequest.Create(BaseURI + METHODE_RUNQUERY,
    rsRunQuery + StructuredQuery.GetInfo, fAuth);
  Query := StructuredQuery.AsJSON;
  Request.SendRequest([], rmPost, Query, QueryParams, tmBearer,
    OnQueryResponse, OnRequestError,
    TOnSuccess.CreateFirestoreDocs(OnDocuments));
end;

procedure TFirestoreDatabase.OnQueryResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Documents: IFirestoreDocuments;
begin
  try
    fLastReceivedMsg := now;
    Response.CheckForJSONArr;
    Documents := TFirestoreDocuments.CreateFromJSONArr(Response);
    if assigned(Response.OnSuccess.OnDocuments) then
      Response.OnSuccess.OnDocuments(RequestID, Documents);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.OnQueryResponse', RequestID, e.Message]);
    end;
  end;
end;

function TFirestoreDatabase.RunQuerySynchronous(
  StructuredQuery: IStructuredQuery;
  QueryParams: TQueryParams = nil): IFirestoreDocuments;
var
  Request: IFirebaseRequest;
  Query: TJSONObject;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(BaseURI + METHODE_RUNQUERY, '', fAuth);
  Query := StructuredQuery.AsJSON;
  Response := Request.SendRequestSynchronous([], rmPost, Query, QueryParams);
  Response.CheckForJSONArr;
  fLastReceivedMsg := now;
  result := TFirestoreDocuments.CreateFromJSONArr(Response);
end;

procedure TFirestoreDatabase.RunQuery(DocumentPath: TRequestResourceParam;
  StructuredQuery: IStructuredQuery; OnDocuments: TOnDocuments;
  OnRequestError: TOnRequestError; QueryParams: TQueryParams = nil);
var
  Request: IFirebaseRequest;
  Query: TJSONObject;
begin
  Request := TFirebaseRequest.Create(BaseURI +
    TFirebaseHelpers.EncodeResourceParams(DocumentPath) + METHODE_RUNQUERY,
    rsRunQuery + StructuredQuery.GetInfo, fAuth);
  Query := StructuredQuery.AsJSON;
  Request.SendRequest([], rmPost, Query, QueryParams, tmBearer,
    OnQueryResponse, OnRequestError,
    TOnSuccess.CreateFirestoreDocs(OnDocuments));
end;

function TFirestoreDatabase.RunQuerySynchronous(
  DocumentPath: TRequestResourceParam; StructuredQuery: IStructuredQuery;
  QueryParams: TQueryParams = nil): IFirestoreDocuments;
var
  Request: IFirebaseRequest;
  Query: TJSONObject;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(BaseURI +
    TFirebaseHelpers.EncodeResourceParams(DocumentPath) + METHODE_RUNQUERY, '',
    fAuth);
  Query := StructuredQuery.AsJSON;
  Response := Request.SendRequestSynchronous([], rmPost, Query, QueryParams);
  Response.CheckForJSONArr;
  fLastReceivedMsg := now;
  result := TFirestoreDocuments.CreateFromJSONArr(Response);
end;

procedure TFirestoreDatabase.Get(Params: TRequestResourceParam;
  QueryParams: TQueryParams; OnDocuments: TOnDocuments;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, rsGetDocument +
    TFirebaseHelpers.ArrStrToCommaStr(Params), fAuth);
  Request.SendRequest(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, Params), rmGet,
    nil, QueryParams, tmBearer, OnGetResponse, OnRequestError,
    TOnSuccess.CreateFirestoreDocs(OnDocuments));
end;

procedure TFirestoreDatabase.OnGetResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Documents: IFirestoreDocuments;
begin
  try
    fLastReceivedMsg := now;
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Documents := TFirestoreDocuments.CreateFromJSONDocumentsObj(Response);
    end else
      Documents := nil;
    if assigned(Response.OnSuccess.OnDocuments) then
      Response.OnSuccess.OnDocuments(RequestID, Documents);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.OnGetResponse', RequestID, e.Message]);
    end;
  end;
end;

function TFirestoreDatabase.GetSynchronous(Params: TRequestResourceParam;
  QueryParams: TQueryParams = nil): IFirestoreDocuments;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, '', fAuth);
  Response := Request.SendRequestSynchronous(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, Params), rmGet,
    nil, QueryParams);
  fLastReceivedMsg := now;
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    result := TFirestoreDocuments.CreateFromJSONDocumentsObj(Response)
  end else
    result := nil;
end;

function TFirestoreDatabase.GetAndAddSynchronous(var Docs: IFirestoreDocuments;
  Params: TRequestResourceParam; QueryParams: TQueryParams): boolean;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, '', fAuth);
  Response := Request.SendRequestSynchronous(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, Params), rmGet,
    nil, QueryParams);
  fLastReceivedMsg := now;
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    (Docs as TFirestoreDocuments).AddFromJSONDocumentsObj(Response);
    result := true;
  end else
    result := false;
end;

function TFirestoreDatabase.GetDatabaseID: string;
begin
  result := fDatabaseID;
end;

function TFirestoreDatabase.GetProjectID: string;
begin
  result := fProjectID;
end;

procedure TFirestoreDatabase.CreateDocument(DocumentPath: TRequestResourceParam;
  QueryParams: TQueryParams; OnDocument: TOnDocument;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, rsCreateDoc +
    TFirebaseHelpers.ArrStrToCommaStr(DocumentPath), fAuth);
  Request.SendRequest(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, DocumentPath),
    rmPost, nil, QueryParams, tmBearer, OnCreateResponse, OnRequestError,
    TOnSuccess.CreateFirestoreDoc(OnDocument));
end;

procedure TFirestoreDatabase.OnCreateResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Document: IFirestoreDocument;
begin
  try
    fLastReceivedMsg := now;
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Document := TFirestoreDocument.CreateFromJSONObj(Response);
    end else
      Document := nil;
    if assigned(Response.OnSuccess.OnDocument) then
      Response.OnSuccess.OnDocument(RequestID, Document);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.OnCreateResponse', RequestID, e.Message]);
    end;
  end;
end;

function TFirestoreDatabase.CreateDocumentSynchronous(
  DocumentPath: TRequestResourceParam;
  QueryParams: TQueryParams): IFirestoreDocument;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, '', fAuth);
  Response := Request.SendRequestSynchronous(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, DocumentPath),
    rmPost, nil, QueryParams);
  fLastReceivedMsg := now;
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    result := TFirestoreDocument.CreateFromJSONObj(Response);
  end else
    raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
end;

procedure TFirestoreDatabase.InsertOrUpdateDocument(
  DocumentPath: TRequestResourceParam; Document: IFirestoreDocument;
  QueryParams: TQueryParams; OnDocument: TOnDocument;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL,
    rsInsertOrUpdateDoc + TFirebaseHelpers.ArrStrToCommaStr(DocumentPath),
    fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirestoreDatabase.InsertOrUpdateDocument ' +
    Document.AsJSON.ToJSON);
{$ENDIF}
  Request.SendRequest(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, DocumentPath),
    rmPatch, Document.AsJSON, QueryParams, tmBearer, OnInsertOrUpdateResponse,
    OnRequestError, TOnSuccess.CreateFirestoreDoc(OnDocument));
end;

procedure TFirestoreDatabase.InsertOrUpdateDocument(
  Document: IFirestoreDocument; QueryParams: TQueryParams;
  OnDocument: TOnDocument; OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL,
    rsInsertOrUpdateDoc + TFirebaseHelpers.ArrStrToCommaStr(
      Document.DocumentPathWithinDatabase),
    fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirestoreDatabase.InsertOrUpdateDocument ' +
    Document.AsJSON.ToJSON);
{$ENDIF}
  Request.SendRequest(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID,
      Document.DocumentPathWithinDatabase),
    rmPatch, Document.AsJSON, QueryParams, tmBearer, OnInsertOrUpdateResponse,
    OnRequestError, TOnSuccess.CreateFirestoreDoc(OnDocument));
end;

procedure TFirestoreDatabase.OnInsertOrUpdateResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Document: IFirestoreDocument;
begin
  try
    fLastReceivedMsg := now;
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Document := TFirestoreDocument.CreateFromJSONObj(Response);
    end else
      Document := nil;
    if assigned(Response.OnSuccess.OnDocument) then
      Response.OnSuccess.OnDocument(RequestID, Document);
    Document := nil;
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.OnInsertOrUpdateResponse', RequestID, e.Message]);
    end;
  end;
end;

function TFirestoreDatabase.InsertOrUpdateDocumentSynchronous(
  DocumentPath:TRequestResourceParam; Document: IFirestoreDocument;
  QueryParams: TQueryParams = nil): IFirestoreDocument;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, '', fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirestoreDatabase.InsertOrUpdateDocumentSynchronous ' +
    Document.AsJSON.ToJSON);
{$ENDIF}
  Response := Request.SendRequestSynchronous(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, DocumentPath),
    rmPatch, Document.AsJSON, QueryParams);
  fLastReceivedMsg := now;
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    result := TFirestoreDocument.CreateFromJSONObj(Response);
  end else
    raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
end;

function TFirestoreDatabase.InsertOrUpdateDocumentSynchronous(
  Document: IFirestoreDocument; QueryParams: TQueryParams): IFirestoreDocument;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, '', fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirestoreDatabase.InsertOrUpdateDocumentSynchronous ' +
    Document.AsJSON.ToJSON);
{$ENDIF}
  Response := Request.SendRequestSynchronous(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID,
      Document.DocumentPathWithinDatabase),
    rmPatch, Document.AsJSON, QueryParams);
  fLastReceivedMsg := now;
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    result := TFirestoreDocument.CreateFromJSONObj(Response);
  end else
    raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
end;

procedure TFirestoreDatabase.PatchDocument(DocumentPath: TRequestResourceParam;
  DocumentPart: IFirestoreDocument; UpdateMask: TStringDynArray;
  OnDocument: TOnDocument; OnRequestError: TOnRequestError;
  Mask: TStringDynArray = []);
var
  Request: IFirebaseRequest;
  QueryParams: TQueryParams;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, rsPatchDoc +
    TFirebaseHelpers.ArrStrToCommaStr(DocumentPath), fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirestoreDatabase.PatchDocument ' +
    DocumentPart.AsJSON.ToJSON);
{$ENDIF}
  QueryParams := TQueryParams.Create;
  try
    if length(UpdateMask) > 0 then
      QueryParams.Add('updateMask.fieldPaths', UpdateMask);
    if length(Mask) > 0 then
      QueryParams.Add('mask.fieldPaths', Mask);
    Request.SendRequest(
      TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, DocumentPath),
      rmPatch, DocumentPart.AsJSON, QueryParams, tmBearer, OnPatchResponse,
      OnRequestError, TOnSuccess.CreateFirestoreDoc(OnDocument));
  finally
    QueryParams.Free;
  end;
end;

procedure TFirestoreDatabase.OnPatchResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Document: IFirestoreDocument;
begin
  try
    fLastReceivedMsg := now;
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Document := TFirestoreDocument.CreateFromJSONObj(Response);
    end else
      Document := nil;
    if assigned(Response.OnSuccess.OnDocument) then
      Response.OnSuccess.OnDocument(RequestID, Document);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.OnPatchResponse', RequestID, e.Message]);
    end;
  end;
end;

function TFirestoreDatabase.PatchDocumentSynchronous(
  DocumentPath: TRequestResourceParam; DocumentPart: IFirestoreDocument;
  UpdateMask, Mask: TStringDynArray): IFirestoreDocument;
var
  Request: IFirebaseRequest;
  QueryParams: TQueryParams;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, '', fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('FirestoreDatabase.PatchDocumentSynchronous ' +
    DocumentPart.AsJSON.ToJSON);
{$ENDIF}
  QueryParams := TQueryParams.Create;
  try
    if length(UpdateMask) > 0 then
      QueryParams.Add('updateMask.fieldPaths', UpdateMask);
    if length(Mask) > 0 then
      QueryParams.Add('mask.fieldPaths', Mask);
    Response := Request.SendRequestSynchronous(
      TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, DocumentPath),
      rmPatch, DocumentPart.AsJSON, QueryParams);
  finally
    QueryParams.Free;
  end;
  fLastReceivedMsg := now;
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    result := TFirestoreDocument.CreateFromJSONObj(Response);
  end else
    raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
end;

procedure TFirestoreDatabase.Delete(Params: TRequestResourceParam;
  QueryParams: TQueryParams; OnDeleteResp: TOnFirebaseResp;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, rsDeleteDoc +
    TFirebaseHelpers.ArrStrToCommaStr(Params), fAuth);
  Request.SendRequest(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, Params),
    rmDELETE, nil, QueryParams, tmBearer, OnDeleteResponse, OnRequestError,
    TOnSuccess.Create(OnDeleteResp));
end;

procedure TFirestoreDatabase.OnDeleteResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  try
    fLastReceivedMsg := now;
    Response.CheckForJSONObj;
    if assigned(Response.OnSuccess.OnResponse) then
      Response.OnSuccess.OnResponse(RequestID, Response);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.OnDeleteResponse', RequestID, e.Message]);
    end;
  end;
end;

function TFirestoreDatabase.DeleteSynchronous(Params: TRequestResourceParam;
  QueryParams: TQueryParams = nil): IFirebaseResponse;
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, rsDeleteDoc,
    fAuth);
  fLastReceivedMsg := now;
  result := Request.SendRequestSynchronous(
    TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, Params),
    rmDELETE, nil, QueryParams);
end;

{$REGION 'Transactions'}
procedure TFirestoreDatabase.BeginReadTransaction(
  OnBeginReadTransaction: TOnBeginReadTransaction;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
  Data: TJSONObject;
begin
  Assert(assigned(fAuth), 'Authentication is required');
  Request := TFirebaseRequest.Create(
    GOOGLE_FIRESTORE_API_URL + METHODE_BEGINTRANS, rsBeginTrans, fAuth);
  Data := TJSONObject.Create(TJSONPair.Create('options',
    TJSONObject.Create(TJSONPair.Create('readOnly', TJSONObject.Create))));
  Request.SendRequest(TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID),
    rmPOST, Data, nil, tmBearer, BeginReadTransactionResp, OnRequestError,
    TOnSuccess.CreateFirestoreReadTransaction(OnBeginReadTransaction));
end;

procedure TFirestoreDatabase.BeginReadTransactionResp(
  const RequestID: string; Response: IFirebaseResponse);
var
  Res: TJSONObject;
begin
  try
    fLastReceivedMsg := now;
    Response.CheckForJSONObj;
    Res := Response.GetContentAsJSONObj;
    try
      if assigned(Response.OnSuccess.OnBeginReadTransaction) then
        Response.OnSuccess.OnBeginReadTransaction(
          Res.GetValue<string>('transaction'));
    finally
      Res.Free;
    end;
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.BeginReadOnlyTransactionResp', RequestID,
           e.Message]);
    end;
  end;
end;

function TFirestoreDatabase.BeginReadTransactionSynchronous:
  TFirestoreReadTransaction;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  Data, Res: TJSONObject;
begin
  Assert(assigned(fAuth), 'Authentication is required');
  Request := TFirebaseRequest.Create(
    GOOGLE_FIRESTORE_API_URL + METHODE_BEGINTRANS, rsBeginTrans, fAuth);
  Data := TJSONObject.Create(TJSONPair.Create('options',
    TJSONObject.Create(TJSONPair.Create('readOnly', TJSONObject.Create))));
  try
    Response := Request.SendRequestSynchronous(
      TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID), rmPOST, Data,
      nil);
    fLastReceivedMsg := now;
    if Response.StatusOk then
    begin
      Res := Response.GetContentAsJSONObj;
      try
        result := Res.GetValue<string>('transaction');
      finally
        Res.Free;
      end;
    end else
      raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
  finally
    Data.Free;
  end;
end;

function TFirestoreDatabase.BeginWriteTransaction: IFirestoreWriteTransaction;
begin
  result := TFirestoreWriteTransaction.Create;
end;

function TFirestoreDatabase.CommitWriteTransactionSynchronous(
  Transaction: IFirestoreWriteTransaction): IFirestoreCommitTransaction;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  Data, Res: TJSONObject;
begin
  Assert(assigned(fAuth), 'Authentication is required');
  Assert(Transaction.NumberOfTransactions > 0, 'No transactions');
  Request := TFirebaseRequest.Create(
    GOOGLE_FIRESTORE_API_URL + METHODE_COMMITTRANS, rsCommitTrans, fAuth);
  Data := TJSONObject.Create;
  Data.AddPair('writes',
    (Transaction as TFirestoreWriteTransaction).GetWritesObjArray);
  try
    Response := Request.SendRequestSynchronous(
      TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID), rmPOST, Data,
      nil);
    fLastReceivedMsg := now;
    if Response.StatusOk then
    begin
      Res := Response.GetContentAsJSONObj;
      try
        result := TFirestoreCommitTransaction.Create(Response);
      finally
        Res.Free;
      end;
    end else
      raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
  finally
    Data.Free;
  end;
end;

procedure TFirestoreDatabase.CommitWriteTransaction(
  Transaction: IFirestoreWriteTransaction;
  OnCommitWriteTransaction: TOnCommitWriteTransaction;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
  Data: TJSONObject;
begin
  Assert(assigned(fAuth), 'Authentication is required');
  Request := TFirebaseRequest.Create(
    GOOGLE_FIRESTORE_API_URL + METHODE_COMMITTRANS, rsCommitTrans, fAuth);
  Data := TJSONObject.Create;
  Data.AddPair('writes',
    (Transaction as TFirestoreWriteTransaction).GetWritesObjArray);
  Request.SendRequest(TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID),
    rmPOST, Data, nil, tmBearer, CommitWriteTransactionResp, OnRequestError,
    TOnSuccess.CreateFirestoreCommitWriteTransaction(OnCommitWriteTransaction));
end;

procedure TFirestoreDatabase.CommitWriteTransactionResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  Res: TJSONObject;
begin
  try
    fLastReceivedMsg := now;
    Response.CheckForJSONObj;
    Res := Response.GetContentAsJSONObj;
    try
      if assigned(Response.OnSuccess.OnCommitWriteTransaction) then
        Response.OnSuccess.OnCommitWriteTransaction(
          TFirestoreCommitTransaction.Create(Response));
    finally
      Res.Free;
    end;
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['FirestoreDatabase.CommitWriteTransactionResp', RequestID,
           e.Message]);
    end;
  end;
end;
{$ENDREGION}

{$REGION 'Listener subscription'}
function TFirestoreDatabase.SubscribeDocument(DocPath: TRequestResourceParam;
  OnChangedDoc: TOnChangedDocument; OnDeletedDoc: TOnDeletedDocument): cardinal;
begin
  result := fListener.SubscribeDocument(DocPath, OnChangedDoc, OnDeletedDoc);
end;

function TFirestoreDatabase.SubscribeQuery(Query: IStructuredQuery;
  OnChangedDoc: TOnChangedDocument; OnDeletedDoc: TOnDeletedDocument;
  DocPath: TRequestResourceParam): cardinal;
begin
  Assert(not Query.HasSelect,
    'Select clause in query is not supported by Firestore for SubscribeQuery');
  result := fListener.SubscribeQuery(Query, DocPath, OnChangedDoc, OnDeletedDoc);
end;

procedure TFirestoreDatabase.Unsubscribe(TargetID: cardinal);
begin
  fListener.Unsubscribe(TargetID);
end;

procedure TFirestoreDatabase.StartListener(OnStopListening: TOnStopListenEvent;
  OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent;
  OnConnectionStateChange: TOnConnectionStateChange;
  DoNotSynchronizeEvents: boolean);
begin
  fListener.RegisterEvents(OnStopListening, OnError, OnAuthRevoked,
    OnConnectionStateChange, DoNotSynchronizeEvents);
  fListener.Start;
end;

procedure TFirestoreDatabase.StopListener(RemoveAllSubscription: boolean);
var
  RestoredTargets: TTargets;
begin
  fListener.StopListener;
  if not RemoveAllSubscription then
    RestoredTargets := fListener.CloneTargets
  else
    RestoredTargets := nil;
  fListener.Free;
  // Recreate thread because a thread cannot be restarted
  fListener := TFSListenerThread.Create(fProjectID, fDatabaseID, fAuth);
  if not RemoveAllSubscription then
    fListener.RestoreClonedTargets(RestoredTargets);
end;
{$ENDREGION}

function TFirestoreDatabase.GetTimeStampOfLastAccess: TDateTime;
begin
  if fLastReceivedMsg > fListener.LastReceivedMsg then
    result := fLastReceivedMsg
  else
    result := fListener.LastReceivedMsg;
end;

{ TStructuredQuery }

constructor TStructuredQuery.Create;
begin
  fLimit := -1;
  fOffset := -1;
end;

class function TStructuredQuery.CreateForCollection(const CollectionId: string;
  IncludesDescendants: boolean): IStructuredQuery;
begin
  result := TStructuredQuery.Create;
  result.Collection(CollectionId, IncludesDescendants);
end;

class function TStructuredQuery.CreateForSelect(
  FieldRefs: TRequestResourceParam): IStructuredQuery;
begin
  result := TStructuredQuery.Create;
  result.Select(FieldRefs);
end;

destructor TStructuredQuery.Destroy;
begin
  fColSelector.Free;
  fFilter.Free;
  fSelect.Free;
  fOrder.Free;
  fStartAt.Free;
  fEndAt.Free;
  fQuery.Free;
  inherited;
end;

function TStructuredQuery.Collection(const CollectionId: string;
  IncludesDescendants: boolean): IStructuredQuery;
begin
  fColSelector := TJSONObject.Create;
  if not CollectionId.IsEmpty then
    fColSelector.AddPair('collectionId', CollectionId);
  fColSelector.AddPair('allDescendants', TJSONBool.Create(IncludesDescendants));
  result := self;
  fInfo := CollectionId;
end;

function TStructuredQuery.AsJSON: TJSONObject;
var
  StructQuery: TJSONObject;
begin
  fQuery := TJSONObject.Create;
  StructQuery := TJSONObject.Create;
  if HasSelect then
  begin
    StructQuery.AddPair('select', fSelect);
    fSelect := nil;
  end;
  if HasColSelector then
  begin
    StructQuery.AddPair('from', TJSONArray.Create(fColSelector));
    fColSelector := nil;
  end;
  if HasFilter then
  begin
    StructQuery.AddPair('where', fFilter);
    fFilter := nil;
  end;
  if HasOrder then
  begin
    StructQuery.AddPair('orderBy', fOrder);
    fOrder := nil;
  end;
  if HasStartAt then
  begin
    StructQuery.AddPair('startAt', fStartAt);
    fStartAt := nil;
  end;
  if HasEndAt then
  begin
    StructQuery.AddPair('endAt', fEndAt);
    fEndAt := nil;
  end;
  if fOffset > 0 then
    StructQuery.AddPair('offset', TJSONNumber.Create(fOffset));
  if fLimit > 0 then
    StructQuery.AddPair('limit', TJSONNumber.Create(fLimit));
  fQuery.AddPair('structuredQuery', StructQuery);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('StructuredQuery ' + fQuery.ToJSON);
{$ENDIF}
  result := fQuery;
end;

function TStructuredQuery.Select(
  FieldRefs: TRequestResourceParam): IStructuredQuery;
var
  ObjProjection: TJSONArray;
  FieldRef: string;
begin
  FreeAndNil(fSelect);
  ObjProjection := TJSONArray.Create;
  for FieldRef in FieldRefs do
    ObjProjection.AddElement(TJSONObject.Create(
      TJSONPair.Create('fieldPath', FieldRef)));
  fSelect := TJSONObject.Create(TJSONPair.Create('fields', ObjProjection));
  result := self;
end;

function TStructuredQuery.OrderBy(const FieldRef: string;
  Direction: TOrderDirection): IStructuredQuery;
const
  cDirStr: array [TOrderDirection] of string = ('?', 'ASC', 'DESC');
var
  ObjOrder: TJSONObject;
begin
  if not assigned(fOrder) then
    fOrder := TJSONArray.Create;
  ObjOrder := TJSONObject.Create;
  ObjOrder.AddPair('field', TJSONObject.Create(
    TJSONPair.Create('fieldPath', FieldRef)));
  ObjOrder.AddPair('direction', ORDER_DIRECTION[Direction]);
  fOrder.AddElement(ObjOrder);
  result := self;
  fInfo := fInfo + '[OrderBy:' + FieldRef + ' ' + cDirStr[Direction] + ']';
end;

function TStructuredQuery.QueryForFieldFilter(
  Filter: IQueryFilter): IStructuredQuery;
begin
  FreeAndNil(fFilter);
  fFilter := TJSONObject.Create;
  fFilter.AddPair('fieldFilter', Filter.AsJSON);
  result := self;
  fInfo := fInfo + '{' + Filter.GetInfo + '}';
end;

function TStructuredQuery.QueryForCompositeFilter(
  CompostiteOperation: TCompostiteOperation;
  Filters: array of IQueryFilter): IStructuredQuery;
const
  cCompOperationStr: array [TCompostiteOperation] of string = ('?', '+');
var
  arr: TJSONArray;
  FilterVal: TJSONObject;
  Filter: IQueryFilter;
begin
  FreeAndNil(fFilter);
  fFilter := TJSONObject.Create;
  FilterVal := TJSONObject.Create;
  FilterVal.AddPair('op', COMPOSITEFILTER_OPERATION[CompostiteOperation]);
  arr := TJSONArray.Create;
  fInfo := fInfo + '{';
  for Filter in Filters do
  begin
    if arr.Count = 0 then
      fInfo := fInfo + Filter.GetInfo
    else
      fInfo := fInfo + cCompOperationStr[CompostiteOperation] + Filter.GetInfo;
    arr.Add(TJSONObject.Create(TJSONPair.Create('fieldFilter', Filter.AsJSON)));
  end;
  fInfo := fInfo + '}';
  FilterVal.AddPair('filters', arr);
  fFilter.AddPair('compositeFilter', FilterVal);
  result := self;
end;

function TStructuredQuery.GetCursorArr(Cursor: IFirestoreDocument): TJSONArray;
var
  c: integer;
begin
  result := TJSONArray.Create;
  for c := 0 to Cursor.CountFields - 1 do
    result.AddElement(Cursor.FieldValue(c).Clone as TJSONValue);
end;

function TStructuredQuery.StartAt(Cursor: IFirestoreDocument;
  Before: boolean): IStructuredQuery;
begin
  FreeAndNil(fStartAt);
  fStartAt := TJSONObject.Create;
  fStartAt.AddPair('values', GetCursorArr(Cursor));
  fStartAt.AddPair('before', TJSONBool.Create(Before));
  fInfo := fInfo + ' startAt';
  result := self;
end;

function TStructuredQuery.EndAt(Cursor: IFirestoreDocument;
  Before: boolean): IStructuredQuery;
begin
  FreeAndNil(fEndAt);
  fEndAt := TJSONObject.Create;
  fEndAt.AddPair('values', GetCursorArr(Cursor));
  fEndAt.AddPair('before', TJSONBool.Create(Before));
  fInfo := fInfo + ' endAt';
  result := self;
end;

function TStructuredQuery.Limit(limit: integer): IStructuredQuery;
begin
  fLimit := limit;
  fInfo := fInfo + ' limit: ' + limit.ToString;
  result := self;
end;

function TStructuredQuery.Offset(offset: integer): IStructuredQuery;
begin
  fOffset := offset;
  fInfo := fInfo + ' offset: ' + offset.ToString;
  result := self;
end;

function TStructuredQuery.GetInfo: string;
begin
  result := fInfo;
end;

function TStructuredQuery.HasSelect: boolean;
begin
  result := assigned(fSelect);
end;

function TStructuredQuery.HasColSelector: boolean;
begin
  result := assigned(fColSelector);
end;

function TStructuredQuery.HasFilter: boolean;
begin
  result := assigned(fFilter);
end;

function TStructuredQuery.HasOrder: boolean;
begin
  result := assigned(fOrder);
end;

function TStructuredQuery.HasStartAt: boolean;
begin
  result := assigned(fStartAt);
end;

function TStructuredQuery.HasEndAt: boolean;
begin
  result := assigned(fEndAt);
end;

{ TQueryFilter }

class function TQueryFilter.IntegerFieldFilter(const WhereFieldPath: string;
  WhereOperator: TWhereOperator; WhereValue: integer): IQueryFilter;
begin
  result := TQueryFilter.Create(WhereFieldPath, WhereValue.ToString,
    WhereOperator);
  result.AddPair('field',
    TJSONObject.Create(TJSONPair.Create('fieldPath', WhereFieldPath)));
  result.AddPair('op', FILTER_OERATION[WhereOperator]);
  result.AddPair('value',
    TJSONObject.Create(TJSONPair.Create('integerValue', WhereValue.ToString)));
end;

class function TQueryFilter.DoubleFieldFilter(const WhereFieldPath: string;
  WhereOperator: TWhereOperator; WhereValue: double): IQueryFilter;
begin
  result := TQueryFilter.Create(WhereFieldPath, WhereValue.ToString,
    WhereOperator);
  result.AddPair('field',
    TJSONObject.Create(TJSONPair.Create('fieldPath', WhereFieldPath)));
  result.AddPair('op', FILTER_OERATION[WhereOperator]);
  result.AddPair('value',
    TJSONObject.Create(TJSONPair.Create('doubleValue', WhereValue.ToString)));
end;

class function TQueryFilter.BooleanFieldFilter(const WhereFieldPath: string;
  WhereOperator: TWhereOperator; WhereValue: boolean): IQueryFilter;
begin
  result := TQueryFilter.Create(WhereFieldPath, WhereValue.ToString(true),
    WhereOperator);
  result.AddPair('field',
    TJSONObject.Create(TJSONPair.Create('fieldPath', WhereFieldPath)));
  result.AddPair('op', FILTER_OERATION[WhereOperator]);
  result.AddPair('value',
    TJSONObject.Create(TJSONPair.Create('booleanValue',
      TJSONBool.Create(WhereValue))));
end;

class function TQueryFilter.StringFieldFilter(const WhereFieldPath: string;
  WhereOperator: TWhereOperator; const WhereValue: string): IQueryFilter;
begin
  result := TQueryFilter.Create(WhereFieldPath, WhereValue, WhereOperator);
  result.AddPair('field',
    TJSONObject.Create(TJSONPair.Create('fieldPath', WhereFieldPath)));
  result.AddPair('op', FILTER_OERATION[WhereOperator]);
  result.AddPair('value',
    TJSONObject.Create(TJSONPair.Create('stringValue', WhereValue)));
end;

class function TQueryFilter.TimestampFieldFilter(const WhereFieldPath: string;
  WhereOperator: TWhereOperator; WhereValue: TDateTime): IQueryFilter;
const
  cBoolStrs: array [boolean] of String = ('false', 'true');
begin
  result := TQueryFilter.Create(WhereFieldPath, DateTimeToStr(WhereValue),
    WhereOperator);
  result.AddPair('field',
    TJSONObject.Create(TJSONPair.Create('fieldPath', WhereFieldPath)));
  result.AddPair('op', FILTER_OERATION[WhereOperator]);
  result.AddPair('value',
    TJSONObject.Create(TJSONPair.Create('timestampValue',
    TFirebaseHelpers.CodeRFC3339DateTime(WhereValue))));
end;

constructor TQueryFilter.Create(const Where, Value: string; Op: TWhereOperator);
const
  cWhereOperationStr: array [TWhereOperator] of string =
    ('?', '<', '≤', '>', '≥', '=', #2208);
  // Attention U+2208 (Element of) is not yet in all MS fonts
begin
  inherited Create;
  fFilter := TJSONObject.Create;
  fInfo := Where + cWhereOperationStr[Op] + Value;
end;

procedure TQueryFilter.AddPair(const Str: string; Val: TJSONValue);
begin
  fFilter.AddPair(Str, Val);
end;

procedure TQueryFilter.AddPair(const Str, Val: string);
begin
  fFilter.AddPair(Str, Val);
end;

function TQueryFilter.AsJSON: TJSONObject;
begin
  result := fFilter;
end;

function TQueryFilter.GetInfo: string;
begin
  result := fInfo;
end;

{ TFirestoreWriteTransaction }

constructor TFirestoreWriteTransaction.Create;
begin
  FreeAndNil(fWritesObjArray);
  fWritesObjArray := TJSONArray.Create;
end;

destructor TFirestoreWriteTransaction.Destroy;
begin
  FreeAndNil(fWritesObjArray);
  inherited;
end;

function TFirestoreWriteTransaction.GetWritesObjArray: TJSONArray;
begin
  result := fWritesObjArray.Clone as TJSONArray;
end;

function TFirestoreWriteTransaction.NumberOfTransactions: cardinal;
begin
  result := fWritesObjArray.Count;
end;

procedure TFirestoreWriteTransaction.PatchDoc(Document: IFirestoreDocument;
  UpdateMask: TStringDynArray);
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  Mask: string;
begin
  Obj := TJSONObject.Create;
  if length(UpdateMask) > 0 then
  begin
    Arr := TJSONArray.Create;
    for Mask in UpdateMask do
      Arr.Add(Mask);
    Obj.AddPair('updateMask',
      TJSONObject.Create(TJSONPair.Create('fieldPaths', Arr)));
  end;
  Obj.AddPair('update', TJSONObject.ParseJSONValue(Document.AsJSON.ToJSON));
  // Document need to be cloned here;
  fWritesObjArray.Add(Obj);
end;

procedure TFirestoreWriteTransaction.UpdateDoc(Document: IFirestoreDocument);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('update', TJSONObject.ParseJSONValue(Document.AsJSON.ToJSON));
  // Document need to be cloned here;
  fWritesObjArray.Add(Obj);
end;

procedure TFirestoreWriteTransaction.DeleteDoc(const DocumentFullPath: string);
begin
  fWritesObjArray.Add(TJSONObject.Create(TJSONPair.Create('delete',
    DocumentFullPath)));
end;

{ TFirestoreCommitTransaction }

constructor TFirestoreCommitTransaction.Create(Response: IFirebaseResponse);
var
  Res: TJSONObject;
  WRes: TJSONValue;
  Arr: TJSONArray;
  c: integer;
begin
  Res := Response.GetContentAsJSONObj;
  try
    WRes := Res.FindValue('writeResults');
    if not assigned(WRes) then
      raise EFirestoreDatabase.Create('JSON field writeResults missing');
    Arr := WRes as TJSONArray;
    SetLength(fUpdateTime, Arr.Count);
    for c := 0 to Arr.Count - 1 do
      if not (Arr.Items[c] as TJSONObject).TryGetValue('updateTime',
         fUpdateTime[c]) then
        raise EFirestoreDatabase.Create('JSON field updateTime missing');
    if not Res.TryGetValue('commitTime', fCommitTime) then
      raise EFirestoreDatabase.Create('JSON field commitTime missing');
  finally
    Res.Free;
  end;
end;

function TFirestoreCommitTransaction.NoUpdates: cardinal;
begin
  result := length(fUpdateTime);
end;

function TFirestoreCommitTransaction.UpdateTime(Index: cardinal;
  TimeZone: TTimeZone): TDateTime;
begin
  result := fUpdateTime[Index];
  if TimeZone = tzLocalTime then
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

function TFirestoreCommitTransaction.CommitTime(TimeZone: TTimeZone): TDateTime;
begin
  result := fCommitTime;
  if TimeZone = tzLocalTime then
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

end.
