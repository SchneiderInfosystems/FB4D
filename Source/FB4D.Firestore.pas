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

unit FB4D.Firestore;

interface

uses
  System.Classes, System.Types, System.JSON, System.SysUtils,
  System.Net.HttpClient, System.Net.URLClient,
  System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request,
  FB4D.Document;

const
  DefaultDatabaseID = '(default)';

type
  TFirestoreDatabase = class(TInterfacedObject, IFirestoreDatabase)
  private
    fProjectID: string;
    fDatabaseID: string;
    fAuth: IFirebaseAuthentication;
    fOnQueryDocuments, fOnGetDocuments: TOnDocuments;
    fOnQueryError, fOnGetError, fOnCreateError, fOnInsertUpdateError,
    fOnPatchError, fOnDeleteError: TOnRequestError;
    fOnCreateDocument, fOnInsertUpdateDocument, fOnPatchDocument: TOnDocument;
    fOnDelete: TOnResponse;
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
  public
    constructor Create(const ProjectID: string; Auth: IFirebaseAuthentication;
      const DatabaseID: string = DefaultDatabaseID);
    procedure RunQuery(StructuredQuery: IStructuredQuery;
      OnDocuments: TOnDocuments; OnRequestError: TOnRequestError); overload;
    procedure RunQuery(DocumentPath: TRequestResourceParam;
      StructuredQuery: IStructuredQuery; OnDocuments: TOnDocuments;
      OnRequestError: TOnRequestError); overload;
    function RunQuerySynchronous(StructuredQuery: IStructuredQuery):
      IFirestoreDocuments; overload;
    function RunQuerySynchronous(DocumentPath: TRequestResourceParam;
      StructuredQuery: IStructuredQuery): IFirestoreDocuments; overload;
    procedure Get(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnDocuments: TOnDocuments; OnRequestError: TOnRequestError);
    function GetSynchronous(Params: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirestoreDocuments;
    procedure CreateDocument(DocumentPath: TRequestResourceParam;
      QueryParams: TQueryParams; OnDocument: TOnDocument;
      OnRequestError: TOnRequestError);
    function CreateDocumentSynchronous(DocumentPath: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirestoreDocument;
    procedure InsertOrUpdateDocument(DocumentPath: TRequestResourceParam;
      Document: IFirestoreDocument; QueryParams: TQueryParams;
      OnDocument: TOnDocument; OnRequestError: TOnRequestError);
    function InsertOrUpdateDocumentSynchronous(
      DocumentPath: TRequestResourceParam; Document: IFirestoreDocument;
      QueryParams: TQueryParams = nil): IFirestoreDocument;
    procedure PatchDocument(DocumentPath: TRequestResourceParam;
      DocumentPart: IFirestoreDocument; UpdateMask: TStringDynArray;
      OnDocument: TOnDocument; OnRequestError: TOnRequestError;
      Mask: TStringDynArray = []);
    function PatchDocumentSynchronous(DocumentPath: TRequestResourceParam;
      DocumentPart: IFirestoreDocument; UpdateMask: TStringDynArray;
      Mask: TStringDynArray = []): IFirestoreDocument;
    procedure Delete(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnResponse: TOnResponse; OnRequestError: TOnRequestError);
    function DeleteSynchronous(Params: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirebaseResponse;
    property ProjectID: string read fProjectID;
    property DatabaseID: string read fDatabaseID;
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
      WhereOperator: TWhereOperator; WhereValue: TDateTime): IQueryFilter; static;
    constructor Create(const Where, Value: string; Op: TWhereOperator);
    procedure AddPair(const Str: string; Val: TJSONValue); overload;
    procedure AddPair(const Str, Val: string); overload;
    function AsJSON: TJSONObject;
    function GetInfo: string;
  end;

implementation

uses
  FB4D.Helpers;

const
  GOOGLE_FIRESTORE_API_URL =
    'https://firestore.googleapis.com/v1beta1/projects/%0:s/databases/%1:s/' +
    'documents';
  METHODE_RUNQUERY = ':runQuery';
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

{ TFirestoreDatabase }

constructor TFirestoreDatabase.Create(const ProjectID: string;
  Auth: IFirebaseAuthentication; const DatabaseID: string);
begin
  inherited Create;
  Assert(assigned(Auth), 'Authentication not initalized');
  fProjectID := ProjectID;
  fAuth := Auth;
  fDatabaseID := DatabaseID;
end;

function TFirestoreDatabase.BaseURI: string;
begin
  result := Format(GOOGLE_FIRESTORE_API_URL, [fProjectID, fDatabaseID]);
end;

procedure TFirestoreDatabase.RunQuery(StructuredQuery: IStructuredQuery;
  OnDocuments: TOnDocuments; OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
  Query: TJSONObject;
begin
  fOnQueryDocuments := OnDocuments;
  fOnQueryError := OnRequestError;
  Request := TFirebaseRequest.Create(BaseURI + METHODE_RUNQUERY,
    rsRunQuery + StructuredQuery.GetInfo, fAuth);
  Query := StructuredQuery.AsJSON;
  Request.SendRequest([''], rmPost, Query, nil, tmBearer, OnQueryResponse,
    OnRequestError);
end;

procedure TFirestoreDatabase.OnQueryResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Documents: IFirestoreDocuments;
begin
  try
    Response.CheckForJSONArr;
    Documents := TFirestoreDocuments.CreateFromJSONArr(Response);
    if assigned(fOnQueryDocuments) then
      fOnQueryDocuments(RequestID, Documents);
  except
    on e: Exception do
    begin
      if assigned(fOnQueryError) then
        fOnQueryError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
    end;
  end;
end;

function TFirestoreDatabase.RunQuerySynchronous(
  StructuredQuery: IStructuredQuery): IFirestoreDocuments;
var
  Request: IFirebaseRequest;
  Query: TJSONObject;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(BaseURI + METHODE_RUNQUERY, '', fAuth);
  Query := StructuredQuery.AsJSON;
  Response := Request.SendRequestSynchronous([''], rmPost, Query, nil);
  Response.CheckForJSONArr;
  result := TFirestoreDocuments.CreateFromJSONArr(Response);
end;

procedure TFirestoreDatabase.RunQuery(DocumentPath: TRequestResourceParam;
  StructuredQuery: IStructuredQuery; OnDocuments: TOnDocuments;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
  Query: TJSONObject;
begin
  fOnQueryDocuments := OnDocuments;
  fOnQueryError := OnRequestError;
  Request := TFirebaseRequest.Create(BaseURI +
    TFirebaseHelpers.EncodeResourceParams(DocumentPath) + METHODE_RUNQUERY,
    rsRunQuery + StructuredQuery.GetInfo, fAuth);
  Query := StructuredQuery.AsJSON;
  Request.SendRequest([''], rmPost, Query, nil, tmBearer, OnQueryResponse,
    OnRequestError);
end;

function TFirestoreDatabase.RunQuerySynchronous(
  DocumentPath: TRequestResourceParam;
  StructuredQuery: IStructuredQuery): IFirestoreDocuments;
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
  Response := Request.SendRequestSynchronous([''], rmPost, Query, nil);
  Response.CheckForJSONArr;
  result := TFirestoreDocuments.CreateFromJSONArr(Response);
end;

procedure TFirestoreDatabase.Get(Params: TRequestResourceParam;
  QueryParams: TQueryParams; OnDocuments: TOnDocuments;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  fOnGetDocuments := OnDocuments;
  fOnGetError := OnRequestError;
  Request := TFirebaseRequest.Create(BaseURI, rsGetDocument +
    TFirebaseHelpers.ArrStrToCommaStr(Params), fAuth);
  Request.SendRequest(Params, rmGet, nil, QueryParams, tmBearer,
    OnGetResponse, OnRequestError);
end;

procedure TFirestoreDatabase.OnGetResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Documents: IFirestoreDocuments;
begin
  try
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Documents := TFirestoreDocuments.CreateFromJSONDocumentsObj(Response);
    end else
      Documents := nil;
    if assigned(fOnGetDocuments) then
      fOnGetDocuments(RequestID, Documents);
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

function TFirestoreDatabase.GetSynchronous(Params: TRequestResourceParam;
  QueryParams: TQueryParams = nil): IFirestoreDocuments;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
begin
  result := nil;
  Request := TFirebaseRequest.Create(BaseURI, '', fAuth);
  Response := Request.SendRequestSynchronous(Params, rmGet, nil, QueryParams);
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    result := TFirestoreDocuments.CreateFromJSONDocumentsObj(Response)
  end else
    raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
end;

procedure TFirestoreDatabase.CreateDocument(DocumentPath: TRequestResourceParam;
  QueryParams: TQueryParams; OnDocument: TOnDocument;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  fOnCreateDocument := OnDocument;
  fOnCreateError := OnRequestError;
  Request := TFirebaseRequest.Create(BaseURI, rsCreateDoc +
    TFirebaseHelpers.ArrStrToCommaStr(DocumentPath), fAuth);
  Request.SendRequest(DocumentPath, rmPost, nil, QueryParams, tmBearer,
    OnCreateResponse, fOnCreateError);
end;

procedure TFirestoreDatabase.OnCreateResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Document: IFirestoreDocument;
begin
  try
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Document := TFirestoreDocument.CreateFromJSONObj(Response);
    end else
      Document := nil;
    if assigned(fOnCreateDocument) then
      fOnCreateDocument(RequestID, Document);
  except
    on e: Exception do
    begin
      if assigned(fOnCreateError) then
        fOnCreateError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
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
  Request := TFirebaseRequest.Create(BaseURI, '', fAuth);
  Response := Request.SendRequestSynchronous(DocumentPath, rmPost, nil,
    QueryParams);
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
  fOnInsertUpdateDocument := OnDocument;
  fOnInsertUpdateError := OnRequestError;
  Request := TFirebaseRequest.Create(BaseURI, rsInsertOrUpdateDoc +
    TFirebaseHelpers.ArrStrToCommaStr(DocumentPath), fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log(' Document: ' + Document.AsJSON.ToJSON);
{$ENDIF}
  Request.SendRequest(DocumentPath, rmPatch, Document.AsJSON, QueryParams,
    tmBearer, OnInsertOrUpdateResponse, OnRequestError);
end;

procedure TFirestoreDatabase.OnInsertOrUpdateResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Document: IFirestoreDocument;
begin
  try
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Document := TFirestoreDocument.CreateFromJSONObj(Response);
    end else
      Document := nil;
    if assigned(fOnInsertUpdateDocument) then
      fOnInsertUpdateDocument(RequestID, Document);
    Document := nil;
  except
    on e: Exception do
    begin
      if assigned(fOnInsertUpdateError) then
        fOnInsertUpdateError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
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
  Request := TFirebaseRequest.Create(BaseURI, '', fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log(' Document: ' + Document.AsJSON.ToJSON);
{$ENDIF}
  Response := Request.SendRequestSynchronous(DocumentPath, rmPatch,
    Document.AsJSON, QueryParams);
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
  fOnPatchDocument := OnDocument;
  fOnPatchError := OnRequestError;
  Request := TFirebaseRequest.Create(BaseURI, rsPatchDoc +
    TFirebaseHelpers.ArrStrToCommaStr(DocumentPath), fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log(' Document: ' + DocumentPart.AsJSON.ToJSON);
{$ENDIF}
  QueryParams := TQueryParams.Create;
  try
    if length(UpdateMask) > 0 then
      QueryParams.Add('updateMask.fieldPaths', UpdateMask);
    if length(Mask) > 0 then
      QueryParams.Add('mask.fieldPaths', Mask);
    Request.SendRequest(DocumentPath, rmPatch, DocumentPart.AsJSON, QueryParams,
      tmBearer, OnPatchResponse, OnRequestError);
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
    if not Response.StatusNotFound then
    begin
      Response.CheckForJSONObj;
      Document := TFirestoreDocument.CreateFromJSONObj(Response);
    end else
      Document := nil;
    if assigned(fOnPatchDocument) then
      fOnPatchDocument(RequestID, Document);
  except
    on e: Exception do
    begin
      if assigned(fOnPatchError) then
        fOnPatchError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
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
  Request := TFirebaseRequest.Create(BaseURI, '', fAuth);
{$IFDEF DEBUG}
  TFirebaseHelpers.Log(' Document: ' + DocumentPart.AsJSON.ToJSON);
{$ENDIF}
  QueryParams := TQueryParams.Create;
  try
    if length(UpdateMask) > 0 then
      QueryParams.Add('updateMask.fieldPaths', UpdateMask);
    if length(Mask) > 0 then
      QueryParams.Add('mask.fieldPaths', Mask);
    Response := Request.SendRequestSynchronous(DocumentPath, rmPatch,
      DocumentPart.AsJSON, QueryParams);
  finally
    QueryParams.Free;
  end;
  if not Response.StatusNotFound then
  begin
    Response.CheckForJSONObj;
    result := TFirestoreDocument.CreateFromJSONObj(Response);
  end else
    raise EFirebaseResponse.Create(Response.ErrorMsgOrStatusText);
end;

procedure TFirestoreDatabase.Delete(Params: TRequestResourceParam;
  QueryParams: TQueryParams; OnResponse: TOnResponse;
  OnRequestError: TOnRequestError);
var
  Request: IFirebaseRequest;
begin
  fOnDelete := OnResponse;
  fOnDeleteError := OnRequestError;
  Request := TFirebaseRequest.Create(BaseURI, rsDeleteDoc +
    TFirebaseHelpers.ArrStrToCommaStr(Params), fAuth);
  Request.SendRequest(Params, rmDELETE, nil, QueryParams, tmBearer,
    OnDeleteResponse, OnRequestError);
end;

procedure TFirestoreDatabase.OnDeleteResponse(const RequestID: string;
  Response: IFirebaseResponse);
begin
  try
    Response.CheckForJSONObj;
    if assigned(fOnDelete) then
      fOnDelete(RequestID, Response);
  except
    on e: Exception do
    begin
      if assigned(fOnDeleteError) then
        fOnDeleteError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log(Format(rsFBFailureIn, [RequestID, e.Message]));
    end;
  end;
end;

function TFirestoreDatabase.DeleteSynchronous(Params: TRequestResourceParam;
  QueryParams: TQueryParams = nil): IFirebaseResponse;
var
  Request: IFirebaseRequest;
begin
  Request := TFirebaseRequest.Create(BaseURI, rsDeleteDoc, fAuth);
  result := Request.SendRequestSynchronous(Params, rmDELETE, nil, QueryParams);
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
  if assigned(fSelect) then
  begin
    StructQuery.AddPair('select', fSelect);
    fSelect := nil;
  end;
  if assigned(fColSelector) then
  begin
    StructQuery.AddPair('from', TJSONArray.Create(fColSelector));
    fColSelector := nil;
  end;
  if assigned(fFilter) then
  begin
    StructQuery.AddPair('where', fFilter);
    fFilter := nil;
  end;
  if assigned(fOrder) then
  begin
    StructQuery.AddPair('orderBy', fOrder);
    fOrder := nil;
  end;
  if assigned(fStartAt) then
  begin
    StructQuery.AddPair('startAt', fStartAt);
    fStartAt := nil;
  end;
  if assigned(fEndAt) then
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
  TFirebaseHelpers.Log(' StructuredQuery: ' + fQuery.ToJSON);
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
{$IFDEF DEBUG}
  TFirebaseHelpers.Log('  Filter: ' + result.ToJSON);
{$ENDIF}
end;

function TQueryFilter.GetInfo: string;
begin
  result := fInfo;
end;

end.
