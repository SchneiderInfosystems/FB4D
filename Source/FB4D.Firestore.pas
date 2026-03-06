{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2026 Christoph Schneider                                 }
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
    procedure OnDeleteResponse2(const RequestID: string;
      Response: IFirebaseResponse);
    procedure BeginReadTransactionResp(const RequestID: string;
      Response: IFirebaseResponse);
    procedure CommitWriteTransactionResp(const RequestID: string;
      Response: IFirebaseResponse);
    /// <summary>Builds the structuredAggregationQuery JSON request body.</summary>
    function BuildAggregationJSON(StructuredQuery: IStructuredQuery;
      const Aggregations: array of TAggregationField): TJSONObject;
    /// <summary>Extracts the IAggregationResult from a runAggregationQuery streaming response.</summary>
    function ParseAggregationResponse(Response: IFirebaseResponse): IAggregationResult;
  public
    constructor Create(const ProjectID: string; Auth: IFirebaseAuthentication;
      const DatabaseID: string = cDefaultDatabaseID);
    destructor Destroy; override;
    function GetProjectID: string;
    function GetDatabaseID: string;
    function CheckListenerHasUnprocessedDocuments: boolean;
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
      Mask: TStringDynArray = []); overload;
    procedure PatchDocument(DocumentPart: IFirestoreDocument;
      UpdateMask: TStringDynArray; OnDocument: TOnDocument;
      OnRequestError: TOnRequestError; Mask: TStringDynArray = []); overload;
    function PatchDocumentSynchronous(DocumentPath: TRequestResourceParam;
      DocumentPart: IFirestoreDocument; UpdateMask: TStringDynArray;
      Mask: TStringDynArray = []): IFirestoreDocument; overload;
    function PatchDocumentSynchronous(DocumentPart: IFirestoreDocument;
      UpdateMask: TStringDynArray;
      Mask: TStringDynArray = []): IFirestoreDocument; overload;
    procedure Delete(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnDeleteResp: TOnFirebaseResp; OnRequestError: TOnRequestError); overload;
    procedure Delete(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnDeletedDoc: TOnDeletedDocument; OnError: TOnRequestError);
      overload;
    function DeleteSynchronous(Params: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirebaseResponse;
    procedure BatchGet(const DocumentPaths: TRequestResourceParams;
      OnDocuments: TOnDocuments; OnRequestError: TOnRequestError;
      const ReadTransaction: TFirestoreReadTransaction = ''); overload;
    function BatchGetSynchronous(
      const DocumentPaths: TRequestResourceParams;
      const ReadTransaction: TFirestoreReadTransaction = ''): IFirestoreDocuments; overload;
    procedure BatchWrite(const Writes: IFirestoreWriteTransaction;
      OnSuccess: TOnCommitWriteTransaction; OnRequestError: TOnRequestError); overload;
    function BatchWriteSynchronous(
      const Writes: IFirestoreWriteTransaction): IFirestoreCommitTransaction; overload;
    // Aggregation queries
    procedure RunAggregationQuery(StructuredQuery: IStructuredQuery;
      const Aggregations: array of TAggregationField;
      OnResult: TOnAggregationResult; OnRequestError: TOnRequestError);
    function RunAggregationQuerySynchronous(StructuredQuery: IStructuredQuery;
      const Aggregations: array of TAggregationField): IAggregationResult;
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
      DoNotSynchronizeEvents: boolean = false); overload;
    procedure StartListener(OnStopListening: TOnStopListenEventDeprecated;
      OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent = nil;
      OnConnectionStateChange: TOnConnectionStateChange = nil;
      DoNotSynchronizeEvents: boolean = false); overload;
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
    property ProjectID: string read GetProjectID;
    property DatabaseID: string read GetDatabaseID;
    property ListenerHasUnprocessedDocuments: boolean
      read CheckListenerHasUnprocessedDocuments;
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
    procedure SetDoc(Document: IFirestoreDocument);
    procedure CreateDoc(Document: IFirestoreDocument);
    procedure UpdateDoc(Document: IFirestoreDocument);
    procedure PatchDoc(Document: IFirestoreDocument;
      UpdateMask: TStringDynArray);
    procedure TransformDoc(const FullDocumentName: string;
      Transform: IFirestoreDocTransform);
    procedure DeleteDoc(const DocumentFullPath: string);
    function GetWritesObjArray: TJSONArray;
  end;

  TAggregationResult = class(TInterfacedObject, IAggregationResult)
  private
    fFields: TJSONObject;  // the aggregateFields JSON object
    fReadTime: TDateTime;
  public
    constructor Create(AggregateFields: TJSONObject; const ReadTimeStr: string);
    destructor Destroy; override;
    function GetCount(const Alias: string = 'field_1'): Int64;
    function GetDouble(const Alias: string): double;
    function GetInt64(const Alias: string): Int64;
    function HasField(const Alias: string): boolean;
    function ReadTime: TDateTime;
    function AliasNames: TArray<string>;
  end;

  TFirestoreDocTransform = class(TInterfacedObject, IFirestoreDocTransform)
  private
    fFieldTransforms: TJSONArray;
    function AsJSON(const DocumentFullName: string): string;
  public
    constructor Create;
    destructor Destroy; override;
    function SetServerTime(const FieldName: string): IFirestoreDocTransform;
    function Increment(const FieldName: string;
      Value: TJSONObject): IFirestoreDocTransform;
    function Maximum(const FieldName: string;
      Value: TJSONObject): IFirestoreDocTransform;
    function Minimum(const FieldName: string;
      Value: TJSONObject): IFirestoreDocTransform;
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
  System.IOUtils,
  FB4D.Helpers;

const
  GOOGLE_FIRESTORE_API_URL =
    'https://firestore.googleapis.com/v1';
  GOOGLE_FIRESTORE_API_URL_DOCUMENTS =
    GOOGLE_FIRESTORE_API_URL + '/projects/%0:s/databases/%1:s/documents';
  METHODE_RUNQUERY = ':runQuery';
  METHODE_BATCHGET = ':batchGet';
  METHODE_BATCHWRITE = ':batchWrite';
  METHODE_RUNAGGREGATIONQUERY = ':runAggregationQuery';
  METHODE_BEGINTRANS = ':beginTransaction';
  METHODE_COMMITTRANS = ':commit';
  METHODE_ROLLBACK = ':rollback';
  FILTER_OERATION: array [TWhereOperator] of string = ('OPERATOR_UNSPECIFIED',
    'LESS_THAN', 'LESS_THAN_OR_EQUAL', 'GREATER_THAN',
    'GREATER_THAN_OR_EQUAL', 'EQUAL', 'NOT_EQUAL', 'ARRAY_CONTAINS',
    'IN', 'ARRAY_CONTAINS_ANY', 'NOT_IN');
  COMPOSITEFILTER_OPERATION: array [TCompostiteOperation] of string = (
    'OPERATOR_UNSPECIFIED', 'AND');
  ORDER_DIRECTION: array [TOrderDirection] of string = ('DIRECTION_UNSPECIFIED',
    'ASCENDING', 'DESCENDING');

resourcestring
  rsRunQuery = 'Run query for ';
  rsBatchGet = 'Batch get documents';
  rsBatchWrite = 'Batch write documents';
  rsRunAggQuery = 'Run aggregation query for ';
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
  fProjectID := ProjectID;
  fAuth := Auth;
  if DatabaseID.IsEmpty then
    fDatabaseID := cDefaultDatabaseID
  else
    fDatabaseID := DatabaseID;
  fListener := TFSListenerThread.Create(ProjectID, fDatabaseID, Auth);
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

{ TAggregationResult }

constructor TAggregationResult.Create(AggregateFields: TJSONObject;
  const ReadTimeStr: string);
begin
  inherited Create;
  // Take ownership of the JSON object if we cloned it, else clone here
  fFields := AggregateFields.Clone as TJSONObject;
  fReadTime := TFirebaseHelpers.DecodeRFC3339DateTime(ReadTimeStr);
end;

destructor TAggregationResult.Destroy;
begin
  fFields.Free;
  inherited;
end;

function TAggregationResult.HasField(const Alias: string): boolean;
begin
  result := Assigned(fFields) and Assigned(fFields.GetValue(Alias));
end;

function TAggregationResult.GetCount(const Alias: string): Int64;
var
  ValObj: TJSONObject;
begin
  result := 0;
  if not Assigned(fFields) then exit;
  ValObj := fFields.GetValue(Alias) as TJSONObject;
  if not Assigned(ValObj) then exit;
  // Firestore returns integerValue as a JSON string
  result := ValObj.GetValue<string>('integerValue').ToInt64;
end;

function TAggregationResult.GetInt64(const Alias: string): Int64;
begin
  result := GetCount(Alias);
end;

function TAggregationResult.GetDouble(const Alias: string): double;
var
  ValObj: TJSONObject;
  IntStr: string;
begin
  result := 0;
  if not Assigned(fFields) then exit;
  ValObj := fFields.GetValue(Alias) as TJSONObject;
  if not Assigned(ValObj) then exit;
  if Assigned(ValObj.GetValue('doubleValue')) then
    result := ValObj.GetValue<double>('doubleValue')
  else if Assigned(ValObj.GetValue('integerValue')) then
  begin
    IntStr := ValObj.GetValue<string>('integerValue');
    result := IntStr.ToInt64;
  end;
end;

function TAggregationResult.ReadTime: TDateTime;
begin
  result := fReadTime;
end;

function TAggregationResult.AliasNames: TArray<string>;
var
  i: integer;
begin
  if not Assigned(fFields) then
  begin
    result := [];
    exit;
  end;
  SetLength(result, fFields.Count);
  for i := 0 to fFields.Count - 1 do
    result[i] := fFields.Pairs[i].JsonString.Value;
end;

{ TFirestoreDatabase.RunAggregationQuery }

function TFirestoreDatabase.BuildAggregationJSON(StructuredQuery: IStructuredQuery;
  const Aggregations: array of TAggregationField): TJSONObject;
var
  Root, SAQ, QueryRoot, InnerQuery: TJSONObject;
  AggArr: TJSONArray;
  AggObj, OpObj, FieldObj: TJSONObject;
  Field: TAggregationField;
begin
  if Length(Aggregations) < 1 then
    raise EArgumentException.Create('At least one aggregation is required');
  if Length(Aggregations) > 5 then
    raise EArgumentException.Create('Firebase allows at most 5 aggregations per query');

  SAQ := TJSONObject.Create;
  // Embed the existing StructuredQuery without double-nesting
  QueryRoot := StructuredQuery.AsJSON;
  try
    if Assigned(QueryRoot) then
    begin
      InnerQuery := QueryRoot.GetValue('structuredQuery') as TJSONObject;
      if Assigned(InnerQuery) then
        SAQ.AddPair('structuredQuery', InnerQuery.Clone as TJSONObject);
    end;
  finally
    QueryRoot.Free;
  end;

  // Build aggregations array
  AggArr := TJSONArray.Create;
  for Field in Aggregations do
  begin
    AggObj := TJSONObject.Create;
    if not Field.Alias.IsEmpty then
      AggObj.AddPair('alias', Field.Alias);
    case Field.Operator of
      aoCount:
        begin
          OpObj := TJSONObject.Create;
          if Field.CountUpTo > 0 then
            OpObj.AddPair('upTo', TJSONString.Create(Field.CountUpTo.ToString));
          AggObj.AddPair('count', OpObj);
        end;
      aoSum:
        begin
          FieldObj := TJSONObject.Create;
          FieldObj.AddPair('fieldPath', Field.FieldPath);
          OpObj := TJSONObject.Create;
          OpObj.AddPair('field', FieldObj);
          AggObj.AddPair('sum', OpObj);
        end;
      aoAvg:
        begin
          FieldObj := TJSONObject.Create;
          FieldObj.AddPair('fieldPath', Field.FieldPath);
          OpObj := TJSONObject.Create;
          OpObj.AddPair('field', FieldObj);
          AggObj.AddPair('avg', OpObj);
        end;
    end;
    AggArr.Add(AggObj);
  end;
  SAQ.AddPair('aggregations', AggArr);

  Root := TJSONObject.Create;
  Root.AddPair('structuredAggregationQuery', SAQ);
  result := Root;
end;

function TFirestoreDatabase.ParseAggregationResponse(
  Response: IFirebaseResponse): IAggregationResult;
var
  RespArr: TJSONArray;
  Element: TJSONValue;
  ResultObj, AggFields: TJSONObject;
  ReadTimeStr: string;
begin
  result := nil;
  RespArr := Response.GetContentAsJSONArr;

  if not Assigned(RespArr) then
    exit;

  // The response is a JSON array; find first element that has 'result'
  for Element in RespArr do
  begin
    if not (Element is TJSONObject) then
      continue;
    ResultObj := (Element as TJSONObject).GetValue('result') as TJSONObject;
    if not Assigned(ResultObj) then
      continue;
    AggFields := ResultObj.GetValue('aggregateFields') as TJSONObject;
    if not Assigned(AggFields) then
      continue;
    ReadTimeStr := (Element as TJSONObject).GetValue<string>('readTime', '');
    result := TAggregationResult.Create(AggFields, ReadTimeStr);
    break;
  end;
end;

procedure TFirestoreDatabase.RunAggregationQuery(
  StructuredQuery: IStructuredQuery;
  const Aggregations: array of TAggregationField;
  OnResult: TOnAggregationResult; OnRequestError: TOnRequestError);
var
  LocalSelf: TFirestoreDatabase;
  LocalQuery: IStructuredQuery;
  LocalAggs: TArray<TAggregationField>;
  LocalAuth: IFirebaseAuthentication;
  LocalBaseURI: string;
  i: integer;
begin
  LocalSelf := Self;
  LocalQuery := StructuredQuery;
  // Copy open-array into a dynamic array so the closure can capture it
  SetLength(LocalAggs, Length(Aggregations));
  for i := 0 to High(Aggregations) do
    LocalAggs[i] := Aggregations[i];
  LocalAuth := fAuth;
  LocalBaseURI := BaseURI + METHODE_RUNAGGREGATIONQUERY;
  TThread.CreateAnonymousThread(
    procedure
    var
      Request: IFirebaseRequest;
      Body: TJSONObject;
      Response: IFirebaseResponse;
      Res: IAggregationResult;
      RequestID, ErrMsg: string;
    begin
      try
        Request := TFirebaseRequest.Create(LocalBaseURI,
          rsRunAggQuery + LocalQuery.GetInfo, LocalAuth);
        Body := LocalSelf.BuildAggregationJSON(LocalQuery, LocalAggs);
        try
          Response := Request.SendRequestSynchronous([], rmPost, Body, nil);
          LocalSelf.fLastReceivedMsg := now;
          Res := LocalSelf.ParseAggregationResponse(Response);
          RequestID := rsRunAggQuery + LocalQuery.GetInfo;
          if Assigned(OnResult) then
            TThread.Queue(nil,
              procedure
              begin
                OnResult(RequestID, Res);
              end);
        finally
          Body.Free;
        end;
      except
        on e: Exception do
        begin
          ErrMsg := e.Message;
          if Assigned(OnRequestError) then
            TThread.Queue(nil,
              procedure
              begin
                OnRequestError(rsRunAggQuery, ErrMsg);
              end)
          else
            TFirebaseHelpers.LogFmt(rsFBFailureIn,
              ['FirestoreDatabase.RunAggregationQuery', '', ErrMsg]);
        end;
      end;
    end).Start;
end;

function TFirestoreDatabase.RunAggregationQuerySynchronous(
  StructuredQuery: IStructuredQuery;
  const Aggregations: array of TAggregationField): IAggregationResult;
var
  Request: IFirebaseRequest;
  Body: TJSONObject;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(BaseURI + METHODE_RUNAGGREGATIONQUERY,
    '', fAuth);
  Body := BuildAggregationJSON(StructuredQuery, Aggregations);
  try
    Response := Request.SendRequestSynchronous([], rmPost, Body, nil);
    fLastReceivedMsg := now;
    result := ParseAggregationResponse(Response);
  finally
    Body.Free;
  end;
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

procedure TFirestoreDatabase.BatchGet(
  const DocumentPaths: TRequestResourceParams; OnDocuments: TOnDocuments;
  OnRequestError: TOnRequestError; const ReadTransaction: TFirestoreReadTransaction);
var
  Request: IFirebaseRequest;
  Data: TJSONObject;
  DocArr: TJSONArray;
  Path: TRequestResourceParam;
begin
  Request := TFirebaseRequest.Create(BaseURI + METHODE_BATCHGET, rsBatchGet, fAuth);
  Data := TJSONObject.Create;
  try
    DocArr := TJSONArray.Create;
    for Path in DocumentPaths do
      DocArr.AddElement(TJSONString.Create(TFirestoreDocument.GetDocFullPath(Path, fProjectID, fDatabaseID)));
    Data.AddPair('documents', DocArr);
    if not ReadTransaction.IsEmpty then
      Data.AddPair('transaction', TJSONString.Create(ReadTransaction));
    Request.SendRequest([], rmPOST, Data, nil, tmBearer, OnQueryResponse,
      OnRequestError, TOnSuccess.CreateFirestoreDocs(OnDocuments));
  finally
    Data.Free;
  end;
end;

function TFirestoreDatabase.BatchGetSynchronous(
  const DocumentPaths: TRequestResourceParams; const ReadTransaction: TFirestoreReadTransaction): IFirestoreDocuments;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  Data: TJSONObject;
  DocArr: TJSONArray;
  Path: TRequestResourceParam;
begin
  result := nil;
  Request := TFirebaseRequest.Create(BaseURI + METHODE_BATCHGET, '', fAuth);
  Data := TJSONObject.Create;
  DocArr := TJSONArray.Create;
  for Path in DocumentPaths do
    DocArr.AddElement(TJSONString.Create(TFirestoreDocument.GetDocFullPath(Path, fProjectID, fDatabaseID)));
  Data.AddPair('documents', DocArr);
  if not ReadTransaction.IsEmpty then
    Data.AddPair('transaction', TJSONString.Create(ReadTransaction));
  try
    Response := Request.SendRequestSynchronous([], rmPOST, Data, nil);
    fLastReceivedMsg := now;
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONArr;
      result := TFirestoreDocuments.CreateFromJSONArr(Response);
    end;
  finally
    Data.Free;
  end;
end;

procedure TFirestoreDatabase.BatchWrite(
  const Writes: IFirestoreWriteTransaction; OnSuccess: TOnCommitWriteTransaction;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
  Data: TJSONObject;
begin
  Request := TFirebaseRequest.Create(BaseURI + METHODE_COMMITTRANS, rsBatchWrite, fAuth);
  Data := TJSONObject.Create;
  try
    Data.AddPair('writes',
      (Writes as TFirestoreWriteTransaction).GetWritesObjArray);
    Request.SendRequest([], rmPOST, Data, nil, tmBearer, CommitWriteTransactionResp,
      OnRequestError, TOnSuccess.CreateFirestoreCommitWriteTransaction(OnSuccess)); // Notice we use CommitWriteTransactionResp as it parses identically
  finally
    Data.Free;
  end;
end;

function TFirestoreDatabase.BatchWriteSynchronous(
  const Writes: IFirestoreWriteTransaction): IFirestoreCommitTransaction;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  Data, Res: TJSONObject;
begin
  Request := TFirebaseRequest.Create(BaseURI + METHODE_BATCHWRITE,
    rsBatchWrite, fAuth);
  Data := TJSONObject.Create;
  Data.AddPair('database', TJSONString.Create('projects/' + fProjectID + '/databases/' + fDatabaseID));
  Data.AddPair('writes',
    (Writes as TFirestoreWriteTransaction).GetWritesObjArray.Clone as TJSONArray);
  try
    Response := Request.SendRequestSynchronous([], rmPOST, Data, nil);
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

function TFirestoreDatabase.GetDatabaseID: string;
begin
  result := fDatabaseID;
end;

function TFirestoreDatabase.CheckListenerHasUnprocessedDocuments: boolean;
begin
  if fListener.IsRunning and fListener.PendingDocumentChanges then
    result := true
  else
    result := false;
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
    rsInsertOrUpdateDoc + Document.DocumentName(true), fAuth);
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

procedure TFirestoreDatabase.PatchDocument(DocumentPart: IFirestoreDocument;
  UpdateMask: TStringDynArray; OnDocument: TOnDocument;
  OnRequestError: TOnRequestError; Mask: TStringDynArray = []);
var
  Request: IFirebaseRequest;
  QueryParams: TQueryParams;
begin
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL, rsPatchDoc +
    DocumentPart.DocumentName(true), fAuth);
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
      TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID,
        DocumentPart.DocumentPathWithinDatabase),
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

function TFirestoreDatabase.PatchDocumentSynchronous(
  DocumentPart: IFirestoreDocument; UpdateMask,
  Mask: TStringDynArray): IFirestoreDocument;
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
      TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID,
        DocumentPart.DocumentPathWithinDatabase),
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

procedure TFirestoreDatabase.Delete(Params: TRequestResourceParam;
  QueryParams: TQueryParams; OnDeletedDoc: TOnDeletedDocument;
  OnError: TOnRequestError);
var
  DBPath: TRequestResourceParam;
  Request: IFirebaseRequest;
begin
  DBPath := TFirestoreDocument.GetDocFullPath(fProjectID, fDatabaseID, Params);
  Request := TFirebaseRequest.Create(GOOGLE_FIRESTORE_API_URL,
    TFirestorePath.GetDocPath(DBPath), fAuth);
  Request.SendRequest(DBPath, rmDELETE, nil, QueryParams, tmBearer,
    OnDeleteResponse2, OnError,
    TOnSuccess.CreateFirestoreDocDelete(OnDeletedDoc));
end;

procedure TFirestoreDatabase.OnDeleteResponse2(const RequestID: string;
  Response: IFirebaseResponse);
begin
  try
    fLastReceivedMsg := now;
    Response.CheckForJSONObj;
    if not Response.StatusOk then
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, Response.StatusText);
    end
    else if assigned(Response.OnSuccess.OnDocumentDeleted) then
      Response.OnSuccess.OnDocumentDeleted(RequestID,
        Response.GetServerTime(tzLocalTime));
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
  Request := TFirebaseRequest.Create(BaseURI + METHODE_BEGINTRANS,
    rsBeginTrans, fAuth);
  Data := TJSONObject.Create(TJSONPair.Create('options',
    TJSONObject.Create(TJSONPair.Create('readOnly', TJSONObject.Create))));
  try
    Request.SendRequest([], rmPOST, Data, nil, tmBearer, BeginReadTransactionResp,
      OnRequestError,
      TOnSuccess.CreateFirestoreReadTransaction(OnBeginReadTransaction));
  finally
    Data.Free;
  end;
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
  Request := TFirebaseRequest.Create(BaseURI + METHODE_BEGINTRANS,
    rsBeginTrans, fAuth);
  Data := TJSONObject.Create(TJSONPair.Create('options',
    TJSONObject.Create(TJSONPair.Create('readOnly', TJSONObject.Create))));
  try
    Response := Request.SendRequestSynchronous([], rmPOST, Data, nil);
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
  Assert(Transaction.NumberOfTransactions > 0, 'No transactions');
  Request := TFirebaseRequest.Create(BaseURI + METHODE_COMMITTRANS,
    rsCommitTrans, fAuth);
  Data := TJSONObject.Create;
  Data.AddPair('writes',
    (Transaction as TFirestoreWriteTransaction).GetWritesObjArray);
  try
    Response := Request.SendRequestSynchronous([], rmPOST, Data, nil);
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
  Request := TFirebaseRequest.Create(BaseURI + METHODE_COMMITTRANS,
    rsCommitTrans, fAuth);
  Data := TJSONObject.Create;
  try
    Data.AddPair('writes',
      (Transaction as TFirestoreWriteTransaction).GetWritesObjArray);
    Request.SendRequest([], rmPOST, Data, nil, tmBearer,
      CommitWriteTransactionResp, OnRequestError,
      TOnSuccess.CreateFirestoreCommitWriteTransaction(OnCommitWriteTransaction));
  finally
    Data.Free;
  end;
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

procedure TFirestoreDatabase.StartListener(
  OnStopListening: TOnStopListenEventDeprecated; OnError: TOnRequestError;
  OnAuthRevoked: TOnAuthRevokedEvent;
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
    // woUnspecific
    ('?',
    // woLessThan
     '<',
    // woLessThanOrEqual
    '≤',
    // woGreaterThan
    '>',
    // woGreaterThanOrEqual
    '≥',
    // woEqual
    '=',
    // woNotEqual
    '≠',
    // woArrayContains
    #$2208, // Attention U+2208 (Element of) is not yet in all MS fonts
    // woInArray
    #$220B, // Attention U+220B (contains as member) is not yet in all MS fonts
    // woArrayContainsAny
    #$2258, // Attention U+220C (corresponds to) is not yet in all MS fonts
    // woNotInArray
    #$220C // Attention U+220C (does not contain as member) is not yet in all MS fonts
    );

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
  fWritesObjArray.Add(Obj);
end;

procedure TFirestoreWriteTransaction.SetDoc(Document: IFirestoreDocument);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('update', TJSONObject.ParseJSONValue(Document.AsJSON.ToJSON));
  fWritesObjArray.Add(Obj);
end;

procedure TFirestoreWriteTransaction.CreateDoc(Document: IFirestoreDocument);
var
  Obj, PreCond: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('update', TJSONObject.ParseJSONValue(Document.AsJSON.ToJSON));
  PreCond := TJSONObject.Create;
  PreCond.AddPair('exists', TJSONBool.Create(False));
  Obj.AddPair('currentDocument', PreCond);
  fWritesObjArray.Add(Obj);
end;

procedure TFirestoreWriteTransaction.UpdateDoc(Document: IFirestoreDocument);
var
  Obj, PreCond: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('update', TJSONObject.ParseJSONValue(Document.AsJSON.ToJSON));
  PreCond := TJSONObject.Create;
  PreCond.AddPair('exists', TJSONBool.Create(True));
  Obj.AddPair('currentDocument', PreCond);
  fWritesObjArray.Add(Obj);
end;

procedure TFirestoreWriteTransaction.TransformDoc(const FullDocumentName: string;
  Transform: IFirestoreDocTransform);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('transform', TJSONObject.ParseJSONValue(
    TFirestoreDocTransform(Transform).AsJSON(FullDocumentName)));
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

{ TFirestoreDocTransform }

constructor TFirestoreDocTransform.Create;
begin
  fFieldTransforms := TJSONArray.Create;
end;

destructor TFirestoreDocTransform.Destroy;
begin
  fFieldTransforms.Free;
  inherited;
end;

function TFirestoreDocTransform.SetServerTime(
  const FieldName: string): IFirestoreDocTransform;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('fieldPath', FieldName);
  Obj.AddPair('setToServerValue', 'REQUEST_TIME');
  fFieldTransforms.Add(Obj);
  result := self;
end;

function TFirestoreDocTransform.Increment(const FieldName: string;
  Value: TJSONObject): IFirestoreDocTransform;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('fieldPath', FieldName);
  Obj.AddPair('increment', Value);
  fFieldTransforms.Add(Obj);
  result := self;
end;

function TFirestoreDocTransform.Maximum(const FieldName: string;
  Value: TJSONObject): IFirestoreDocTransform;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('fieldPath', FieldName);
  Obj.AddPair('maximum', Value);
  fFieldTransforms.Add(Obj);
  result := self;
end;

function TFirestoreDocTransform.Minimum(const FieldName: string;
  Value: TJSONObject): IFirestoreDocTransform;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  Obj.AddPair('fieldPath', FieldName);
  Obj.AddPair('minimum', Value);
  fFieldTransforms.Add(Obj);
  result := self;
end;

function TFirestoreDocTransform.AsJSON(const DocumentFullName: string): string;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('document', DocumentFullName);
    if fFieldTransforms.Count > 0 then
      Obj.AddPair('fieldTransforms', fFieldTransforms.Clone as TJSONArray);
    result := Obj.ToJSON;
  finally
    Obj.Free;
  end;
end;

end.
