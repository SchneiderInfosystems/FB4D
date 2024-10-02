{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2024 Christoph Schneider                                 }
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
unit FB4D.Interfaces;

interface

uses
  System.Classes, System.Types, System.SysUtils, System.JSON,
{$IFNDEF LINUX64}
  System.Sensors,
{$ENDIF}
  System.Generics.Collections,
{$IFDEF TOKENJWT}
  JOSE.Core.JWT,
{$ENDIF}
  REST.Types,
  FB4D.VisionMLDefinition;

{$IFDEF LINUX64}
{$I LinuxTypeDecl.inc}
{$ENDIF}

const
  cDefaultCacheSpaceInBytes = 536870912; // 500 MByte
  cDefaultDatabaseID = '(default)';

  cRegionUSCent1 = 'us-central1';             // Iowa
  cRegionUSEast1 = 'us-east1';                // South Carolina
  cRegionUSEast4 = 'us-east4';                // Nothern Virginia
  cRegionUSWest2 = 'us-west2';                // Los Angeles
  cRegionUSWest3 = 'us-west3';                // Salt Lake City
  cRegionUSWest4 = 'us-west4';                // Las Vegas
  cRegionUSNoEa1 = 'northamerica-northeast1'; // Montreal
  cRegionUSSoEa1 = 'southamerica-east1';      // Sao Paulo
  cRegionEUWest1 = 'europe-west1';            // Belgium
  cRegionEUWest2 = 'europe-west2';            // London
  cRegionEUWest3 = 'europe-west3';            // Frankfurt
  cRegionEUWest6 = 'europe-west6';            // Zürich
  cRegionEUCent2 = 'europe-central2';         // Warsaw
  cRegionAUSoEa1 = 'australia-southeast1';    // Sydney
  cRegionASEast1 = 'asia-east1';              // Taiwan
  cRegionASEast2 = 'asia-east2';              // Hong Kong
  cRegionASNoEa1 = 'asia-northeast1';         // Tokyo
  cRegionASNoEa2 = 'asia-northeast2';         // Osaka
  cRegionASSout1 = 'asia-south1';             // Mumbai
  cRegionASSoEa1 = 'asia-southeast1';         // Singapore
  cRegionASSoEa2 = 'asia-southeast2';         // Jakarta
  cRegionASSoEa3 = 'asia-southeast3';         // Seoul

type
  /// <summary>
  /// Firebase returns timestamps in UTC time zone (tzUTC). FB4D offers the
  /// or convertion into local time by tzLocalTime.
  /// </summary>
  TTimeZone = (tzUTC, tzLocalTime);

  /// <summary>
  /// Exception for IFirebaseRespone
  /// </summary>
  EFirebaseResponse = class(Exception);

  IFirebaseUser = interface;
  IFirebaseResponse = interface;
  IFirestoreDocument = interface;
  IFirestoreDocuments = interface;
  IStorageObject = interface;

  TOnRequestError = procedure(const RequestID, ErrMsg: string) of object;
  TRequestResourceParam = TStringDynArray;
  TOnFirebaseResp = procedure(const RequestID: string;
    Response: IFirebaseResponse) of object;

  TFirebaseUserList = TList<IFirebaseUser>;
  TPasswordVerificationResult = (pvrOpNotAllowed, pvrPassed, pvrpvrExpired,
    pvrInvalid);
  TOnUserResponse = procedure(const Info: string; User: IFirebaseUser) of object;
  TOnFetchProviders = procedure(const RequestID: string; IsRegistered: boolean;
    Providers: TStrings) of object;
  TOnPasswordVerification = procedure(const Info: string;
    Result: TPasswordVerificationResult) of object;
  TOnGetUserData = procedure(FirebaseUserList: TFirebaseUserList) of object;
  TOnTokenRefresh = procedure(TokenRefreshed: boolean) of object;

  TOnRTDBValue = procedure(ResourceParams: TRequestResourceParam;
    Val: TJSONValue) of object;
  TOnRTDBDelete = procedure(Params: TRequestResourceParam; Success: boolean)
    of object;
  TOnRTDBServerVariable = procedure(const ServerVar: string; Val: TJSONValue)
    of object;

  TOnDocument = procedure(const Info: string;
    Document: IFirestoreDocument) of object;
  TOnDocuments = procedure(const Info: string;
    Documents: IFirestoreDocuments) of object;
  TOnChangedDocument = procedure(ChangedDocument: IFirestoreDocument) of object;
  TOnDeletedDocument = procedure(const DeleteDocumentPath: string;
    TimeStamp: TDateTime) of object;
  TFirestoreReadTransaction = string; // A base64 encoded ID
  TOnBeginReadTransaction = procedure(Transaction: TFirestoreReadTransaction)
    of object;
  IFirestoreCommitTransaction = interface
    function CommitTime(TimeZone: TTimeZone = tzUTC): TDateTime;
    function NoUpdates: cardinal;
    function UpdateTime(Index: cardinal; TimeZone: TTimeZone = tzUTC): TDateTime;
  end;
  TOnCommitWriteTransaction = procedure(Transaction: IFirestoreCommitTransaction)
    of object;

  TObjectName = string;
  TOnStorage = procedure(Obj: IStorageObject) of object;
  TOnStorageDeprecated = procedure(const ObjectName: TObjectName;
    Obj: IStorageObject) of object;
  TOnStorageError = procedure(const ObjectName: TObjectName;
    const ErrMsg: string) of object;
  TOnDeleteStorage = procedure(const ObjectName: TObjectName) of object;

  TOnFunctionSuccess = procedure(const Info: string; ResultObj: TJSONObject) of
    object;

  IVisionMLResponse = interface;

  TOnAnnotate = procedure(Res: IVisionMLResponse) of object;

  TOnSuccess = record
    type TOnSuccessCase = (oscUndef, oscFB, oscUser, oscFetchProvider,
      oscPwdVerification, oscGetUserData, oscRefreshToken, oscRTDBValue,
      oscRTDBDelete, oscRTDBServerVariable, oscDocument, oscDocuments,
      oscDocumentDeleted, oscBeginReadTransaction, oscCommitWriteTransaction,
      oscStorage, oscStorageDeprecated, oscStorageUpload, oscStorageGetAndDown,
      oscDelStorage, oscFunctionSuccess, oscVisionML);
    constructor Create(OnResp: TOnFirebaseResp);
    constructor CreateUser(OnUserResp: TOnUserResponse);
    constructor CreateFetchProviders(OnFetchProvidersResp: TOnFetchProviders);
    constructor CreatePasswordVerification(
      OnPasswordVerificationResp: TOnPasswordVerification);
    constructor CreateGetUserData(OnGetUserDataResp: TOnGetUserData);
    constructor CreateRefreshToken(OnRefreshTokenResp: TOnTokenRefresh);
    constructor CreateRTDBValue(OnRTDBValueResp: TOnRTDBValue);
    constructor CreateRTDBDelete(OnRTDBDeleteResp: TOnRTDBDelete);
    constructor CreateRTDBServerVariable(
      OnRTDBServerVariableResp: TOnRTDBServerVariable);
    constructor CreateFirestoreDoc(OnDocumentResp: TOnDocument);
    constructor CreateFirestoreDocs(OnDocumentsResp: TOnDocuments);
    constructor CreateFirestoreDocDelete(
      OnDocumentDeleteResp: TOnDeletedDocument);
    constructor CreateFirestoreReadTransaction(
      OnBeginReadTransactionResp: TOnBeginReadTransaction);
    constructor CreateFirestoreCommitWriteTransaction(
      OnCommitTransaction: TOnCommitWriteTransaction);
    constructor CreateStorage(OnStorageResp: TOnStorage);
    constructor CreateStorageDeprecated(OnStorageResp: TOnStorageDeprecated);
    constructor CreateStorageGetAndDownload(OnStorageResp: TOnStorage;
      OnStorageErrorResp: TOnRequestError; Stream: TStream);
    constructor CreateStorageUpload(OnStorageResp: TOnStorage; Stream: TStream);
    constructor CreateDelStorage(OnDelStorageResp: TOnDeleteStorage);
    constructor CreateFunctionSuccess(OnFunctionSuccessResp: TOnFunctionSuccess);
    constructor CreateVisionML(OnAnnotateResp: TOnAnnotate);
    {$IFNDEF AUTOREFCOUNT}
    case OnSuccessCase: TOnSuccessCase of
      oscFB: (OnResponse: TOnFirebaseResp);
      oscUser: (OnUserResponse: TOnUserResponse);
      oscFetchProvider: (OnFetchProviders: TOnFetchProviders);
      oscPwdVerification: (OnPasswordVerification: TOnPasswordVerification);
      oscGetUserData: (OnGetUserData: TOnGetUserData);
      oscRefreshToken: (OnRefreshToken: TOnTokenRefresh);
      oscRTDBValue: (OnRTDBValue: TOnRTDBValue);
      oscRTDBDelete: (OnRTDBDelete: TOnRTDBDelete);
      oscRTDBServerVariable: (OnRTDBServerVariable: TOnRTDBServerVariable);
      oscDocument: (OnDocument: TOnDocument);
      oscDocuments: (OnDocuments: TOnDocuments);
      oscDocumentDeleted: (OnDocumentDeleted: TOnDeletedDocument);
      oscBeginReadTransaction: (OnBeginReadTransaction: TOnBeginReadTransaction);
      oscCommitWriteTransaction:
        (OnCommitWriteTransaction: TOnCommitWriteTransaction);
      oscStorage: (OnStorage: TOnStorage);
      oscStorageDeprecated: (OnStorageDeprecated: TOnStorageDeprecated);
      oscStorageGetAndDown:
        (OnStorageGetAndDown: TOnStorage;
         OnStorageError: TOnRequestError;
         DownStream: TStream);
      oscStorageUpload:
        (OnStorageUpload: TOnStorage;
         UpStream: TStream);
      oscDelStorage: (OnDelStorage: TOnDeleteStorage);
      oscFunctionSuccess: (OnFunctionSuccess: TOnFunctionSuccess);
      oscVisionML: (OnAnnotate: TOnAnnotate);
    {$ELSE}
    var
      OnSuccessCase: TOnSuccessCase;
      OnResponse: TOnFirebaseResp;
      OnUserResponse: TOnUserResponse;
      OnFetchProviders: TOnFetchProviders;
      OnPasswordVerification: TOnPasswordVerification;
      OnGetUserData: TOnGetUserData;
      OnRefreshToken: TOnTokenRefresh;
      OnRTDBValue: TOnRTDBValue;
      OnRTDBDelete: TOnRTDBDelete;
      OnRTDBServerVariable: TOnRTDBServerVariable;
      OnDocument: TOnDocument;
      OnDocuments: TOnDocuments;
      OnDocumentDeleted: TOnDeletedDocument;
      OnBeginReadTransaction: TOnBeginReadTransaction;
      OnCommitWriteTransaction: TOnCommitWriteTransaction;
      OnStorage: TOnStorage;
      OnStorageDeprecated: TOnStorageDeprecated;
      OnStorageGetAndDown: TOnStorage;
      OnStorageError: TOnRequestError;
      DownStream: TStream;
      OnStorageUpload: TOnStorage;
      UpStream: TStream;
      OnDelStorage: TOnDeleteStorage;
      OnFunctionSuccess: TOnFunctionSuccess;
      OnAnnotate: TOnAnnotate;
    {$ENDIF}
  end;

  /// <summary>
  /// Interface for handling REST response from all Firebase Services
  /// </summary>
  IFirebaseResponse = interface(IInterface)
    function ContentAsString: string;
    function GetContentAsJSONObj: TJSONObject;
    function GetContentAsJSONArr: TJSONArray;
    function GetContentAsJSONVal: TJSONValue;
    procedure CheckForJSONObj;
    function IsJSONObj: boolean;
    procedure CheckForJSONArr;
    function StatusOk: boolean;
    function StatusIsUnauthorized: boolean;
    function StatusNotFound: boolean;
    function StatusCode: integer;
    function StatusText: string;
    function ErrorMsg: string;
    function ErrorMsgOrStatusText: string;
    function GetServerTime(TimeZone: TTimeZone): TDateTime;
    function GetOnSuccess: TOnSuccess;
    function GetOnError: TOnRequestError;
    function HeaderValue(const HeaderName: string): string;
    property OnSuccess: TOnSuccess read GetOnSuccess;
    property OnError: TOnRequestError read GetOnError;
   end;

  TQueryParams = TDictionary<string, TStringDynArray>;
  TTokenMode = (tmNoToken, tmBearer, tmAuthParam);
  IFirebaseRequest = interface;
  IFirebaseRequest = interface(IInterface)
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    function SendRequestSynchronous(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue = nil;
      QueryParams: TQueryParams = nil; TokenMode: TTokenMode = tmBearer):
      IFirebaseResponse; overload;
    function SendRequestSynchronous(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams = nil; TokenMode: TTokenMode = tmBearer):
      IFirebaseResponse; overload;
  end;

  IFirebaseEvent = interface(IInterface)
    procedure StopListening(MaxTimeOutInMS: cardinal = 500); overload;
    procedure StopListening(const NodeName: string;
      MaxTimeOutInMS: cardinal = 500); overload; deprecated;
    function GetResourceParams: TRequestResourceParam;
    function GetLastReceivedMsg: TDateTime; // Local time
    function IsStopped: boolean;
  end;

  TOnReceiveEvent = procedure(const Event: string;
    Params: TRequestResourceParam; JSONObj: TJSONObject) of object;
  TOnStopListenEvent =  procedure(const RequestId: string) of object;
  TOnStopListenEventDeprecated = TNotifyEvent;
  TOnAuthRevokedEvent = procedure(TokenRenewPassed: boolean) of object;
  TOnConnectionStateChange = procedure(ListenerConnected: boolean) of object;
  ERTDBListener = class(Exception);

  IRealTimeDB = interface(IInterface)
    function GetDatabaseID: string;
    procedure Get(ResourceParams: TRequestResourceParam;
      OnGetValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function GetSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Put(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPutValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PutSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Post(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPostValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PostSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Patch(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPatchValue: TOnRTDBValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PatchSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Delete(ResourceParams: TRequestResourceParam;
      OnDelete: TOnRTDBDelete; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams); overload;
      deprecated 'Use delete method without QueryParams instead';
    procedure Delete(ResourceParams: TRequestResourceParam;
      OnDelete: TOnRTDBDelete; OnRequestError: TOnRequestError); overload;
    function DeleteSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams): boolean; overload;
      deprecated 'Use delete method without QueryParams instead';
    function DeleteSynchronous(
      ResourceParams: TRequestResourceParam): boolean; overload;
    // long time running request
    function ListenForValueEvents(ResourceParams: TRequestResourceParam;
      ListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
      OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent = nil;
      OnConnectionStateChange: TOnConnectionStateChange = nil;
      DoNotSynchronizeEvents: boolean = false): IFirebaseEvent; overload;
    function ListenForValueEvents(ResourceParams: TRequestResourceParam;
      ListenEvent: TOnReceiveEvent;
      OnStopListening: TOnStopListenEventDeprecated;
      OnError: TOnRequestError; OnAuthRevoked: TOnAuthRevokedEvent = nil;
      OnConnectionStateChange: TOnConnectionStateChange = nil;
      DoNotSynchronizeEvents: boolean = false): IFirebaseEvent; overload;
      deprecated 'Use new version with TOnStopListenEvent';
    // To retrieve server variables like timestamp and future variables
    procedure GetServerVariables(const ServerVarName: string;
      ResourceParams: TRequestResourceParam;
      OnServerVariable: TOnRTDBServerVariable = nil;
      OnError: TOnRequestError = nil);
    function GetServerVariablesSynchronous(const ServerVarName: string;
      ResourceParams: TRequestResourceParam): TJSONValue;
  end;

  EFirestoreDocument = class(Exception);
  TJSONObjects = array of TJSONObject;
  TFirestoreFieldType = (fftNull, fftBoolean, fftInteger, fftDouble,
    fftTimeStamp, fftString, fftBytes, fftReference, fftGeoPoint, fftArray,
    fftMap);
  TOTDMapperOption = (
    omSupressSaveDefVal, // Don't save empty string, integer with value 0, etc..
    omSupressSavePrivateFields,   // Don't save private fields
    omSupressSaveProtectedFields, // Don't save protected fields
    omSupressSavePublicFields,    // Don't save public fields
    omSupressSavePublishedFields, // Don't save published fields
    omEliminateFieldPrefixF,      // Eliminate F and f as field prefix
    omSaveEnumAsString);          // Convert Enum to string instead of ord number
  TOTDMapperOptions = Set of TOTDMapperOption;
  IFirestoreDocument = interface(IInterface)
    function DocumentName(FullPath: boolean): string;
    function DocumentFullPath: TRequestResourceParam;
    function DocumentPathWithinDatabase: TRequestResourceParam;
    function CreateTime(TimeZone: TTimeZone = tzUTC): TDateTime;
    function UpdateTime(TimeZone: TTimeZone = tzUTC): TDatetime;
    function CountFields: integer;
    function FieldName(Ind: integer): string;
    function FieldByName(const FieldName: string): TJSONObject;
    function FieldValue(Ind: integer): TJSONObject;
    function FieldType(Ind: integer): TFirestoreFieldType;
    function FieldTypeByName(const FieldName: string): TFirestoreFieldType;
    function AllFields: TStringDynArray;
    function GetValue(Ind: integer): TJSONValue; overload;
    function GetValue(const FieldName: string): TJSONValue; overload;
    function GetStringValue(const FieldName: string): string;
    function GetStringValueDef(const FieldName, Default: string): string;
    function GetIntegerValue(const FieldName: string): integer;
    function GetIntegerValueDef(const FieldName: string;
      Default: integer): integer;
    function GetInt64Value(const FieldName: string): Int64;
    function GetInt64ValueDef(const FieldName: string;
      Default: Int64): Int64;
    function GetDoubleValue(const FieldName: string): double;
    function GetDoubleValueDef(const FieldName: string;
      Default: double): double;
    function GetBoolValue(const FieldName: string): boolean;
    function GetBoolValueDef(const FieldName: string;
      Default: boolean): boolean;
    function GetTimeStampValue(const FieldName: string;
      TimeZone: TTimeZone = tzUTC): TDateTime;
    function GetTimeStampValueDef(const FieldName: string;
      Default: TDateTime; TimeZone: TTimeZone = tzUTC): TDateTime;
    function GetGeoPoint(const FieldName: string): TLocationCoord2D;
    function GetReference(const FieldName: string): string;
    function GetBytes(const FieldName: string): TBytes;
    function GetArrayValues(const FieldName: string): TJSONObjects;
    function GetArrayMapValues(const FieldName: string): TJSONObjects;
    function GetArrayStringValues(const FieldName: string): TStringDynArray;
    function GetArraySize(const FieldName: string): integer;
    function GetArrayType(const FieldName: string;
      Index: integer): TFirestoreFieldType;
    function GetArrayItem(const FieldName: string; Index: integer): TJSONPair;
    function GetArrayValue(const FieldName: string; Index: integer): TJSONValue;
    function GetMapSize(const FieldName: string): integer;
    function GetMapType(const FieldName: string;
      Index: integer): TFirestoreFieldType;
    function GetMapSubFieldName(const FieldName: string; Index: integer): string;
    function GetMapValue(const FieldName: string; Index: integer): TJSONObject;
      overload;
    function GetMapValue(const FieldName, SubFieldName: string): TJSONObject;
      overload;
    function GetMapValues(const FieldName: string): TJSONObjects;
    function AddOrUpdateField(Field: TJSONPair): IFirestoreDocument; overload;
    function AddOrUpdateField(const FieldName: string;
      Val: TJSONValue): IFirestoreDocument; overload;
    function AsJSON: TJSONObject;
    function Clone: IFirestoreDocument;
    function SaveObjectToDocument(
      Options: TOTDMapperOptions = []): IFirestoreDocument;
    property Fields[Index: integer]: TJSONObject read FieldValue;
  end;

  IFirestoreDocuments = interface(IEnumerable<IFirestoreDocument>)
    function Count: integer;
    function Document(Ind: integer): IFirestoreDocument;
    function ServerTimeStamp(TimeZone: TTimeZone): TDateTime;
    function SkippedResults: integer;
    function MorePagesToLoad: boolean;
    function PageToken: string;
    procedure AddPageTokenToNextQuery(Query: TQueryParams);
  end;

  TWhereOperator = (woUnspecific, woLessThan, woLessThanOrEqual,
    woGreaterThan, woGreaterThanOrEqual, woEqual, woNotEqual, woArrayContains,
    woInArray, woArrayContainsAny, woNotInArray);
  IQueryFilter = interface(IInterface)
    procedure AddPair(const Str: string; Val: TJSONValue); overload;
    procedure AddPair(const Str, Val: string); overload;
    function AsJSON: TJSONObject;
    function GetInfo: string;
  end;

  TCompostiteOperation = (coUnspecific, coAnd);
  TOrderDirection = (odUnspecified, odAscending, odDescending);
  IStructuredQuery = interface(IInterface)
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

  IFirestoreDocTransform = interface
    function SetServerTime(const FieldName: string): IFirestoreDocTransform;
    function Increment(const FieldName: string;
      Value: TJSONObject): IFirestoreDocTransform;
    function Maximum(const FieldName: string;
      Value: TJSONObject): IFirestoreDocTransform;
    function Minimum(const FieldName: string;
      Value: TJSONObject): IFirestoreDocTransform;
  end;

  IFirestoreWriteTransaction = interface
    function NumberOfTransactions: cardinal;
    procedure UpdateDoc(Document: IFirestoreDocument);
    procedure PatchDoc(Document: IFirestoreDocument;
      UpdateMask: TStringDynArray);
    procedure TransformDoc(const FullDocumentName: string;
      Transform: IFirestoreDocTransform);
    procedure DeleteDoc(const DocumentFullPath: string);
  end;

  EFirestoreListener = class(Exception);
  EFirestoreDatabase = class(Exception);

  IFirestoreDatabase = interface(IInterface)
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

    // QueryParams: can contain as precondition a JSON object with one field
    // named either as "exists" or "updateTime". Read more at:
    // https://firebase.google.com/docs/firestore/reference/rest/v1/Precondition
    procedure Delete(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnDeletedDoc: TOnDeletedDocument; OnError: TOnRequestError);
      overload;
    procedure Delete(Params: TRequestResourceParam; QueryParams: TQueryParams;
      OnDeleteResponse: TOnFirebaseResp; OnRequestError: TOnRequestError);
      overload;
      deprecated 'Use method with TOnDeletedDocument call back method';
    function DeleteSynchronous(Params: TRequestResourceParam;
      QueryParams: TQueryParams = nil): IFirebaseResponse;

    // Listener subscription
    function SubscribeDocument(DocumentPath: TRequestResourceParam;
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
      deprecated 'Use new version with TOnStopListenEvent';
    procedure StopListener(RemoveAllSubscription: boolean = true);
    function GetTimeStampOfLastAccess: TDateTime; // local time
    function CheckListenerHasUnprocessedDocuments: boolean;

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

{$IFDEF TOKENJWT}
  ETokenJWT = class(Exception);

  /// <summary>
  /// Usually you do not need to create an instance of the class TTokenJWT by
  /// yourself because you get an object with this interface in by the getter
  /// method IFirebaseAuthentication.TokenJWT
  /// </summary>
  ITokenJWT = interface(IInterface)
    function VerifySignature: boolean;
    function GetHeader: TJWTHeader;
    function GetClaims: TJWTClaims;
    property Header: TJWTHeader read GetHeader;
    property Claims: TJWTClaims read GetClaims;
  end;
{$ENDIF}

  EFirebaseUser = class(Exception);
  TThreeStateBoolean = (tsbTrue, tsbFalse, tsbUnspecified);

  TProviderInfo = record
    ProviderId: string;
    FederatedId: string;
    RawId: string;
    DisplayName: string;
    Email: string;
    ScreenName: string;
  end;

  /// <summary>
  /// The IFirebaseUser interface provides only getter functions that are used
  /// to retrieve details of the user profile and the access token.
  /// </summary>
  IFirebaseUser = interface(IInterface)
    // Get User Identification
    function UID: string;
    // Get EMail Address
    function IsEMailAvailable: boolean;
    function IsEMailRegistered: TThreeStateBoolean;
    function IsEMailVerified: TThreeStateBoolean;
    function EMail: string;
    // Get User Display Name
    function DisplayName: string;
    function IsDisplayNameAvailable: boolean;
    // Get Photo URL for User Avatar or Photo
    function IsPhotoURLAvailable: boolean;
    function PhotoURL: string;
    // Get User Account State and Timestamps
    function IsDisabled: TThreeStateBoolean;
    function IsNewSignupUser: boolean;
    function IsLastLoginAtAvailable: boolean;
    function LastLoginAt(TimeZone: TTimeZone = tzLocalTime): TDateTime;
    function IsCreatedAtAvailable: boolean;
    function CreatedAt(TimeZone: TTimeZone = tzLocalTime): TDateTime;
    // Provider User Info
    function ProviderCount: integer;
    function Provider(ProviderNo: integer): TProviderInfo;
    // In case of OAuth sign-in
    function OAuthFederatedId: string;
    function OAuthProviderId: string;
    function OAuthIdToken: string;
    function OAuthAccessToken: string;
    function OAuthTokenSecret: string;
    function OAuthRawUserInfo: string;
    // Get Token Details and Claim Fields
    function Token: string;
{$IFDEF TOKENJWT}
    function TokenJWT: ITokenJWT;
    function ClaimFieldNames: TStrings;
    function ClaimField(const FieldName: string): TJSONValue;
{$ENDIF}
    function ExpiresAt: TDateTime; // local time
    function RefreshToken: string;
  end;
  EFirebaseAuthentication = class(Exception);

  /// <summary>
  /// The interface IFirebaseAuthentication provides all functions for accessing
  /// the Firebase Authentication Service. The interface will be created by the
  /// constructor of the class TFirebaseAuthentication in the unit
  /// FB4D.Authentication. The constructor expects the web API key of the
  /// Firebase project as parameter.
  /// </summary>
  IFirebaseAuthentication = interface(IInterface)
    // Create new User with email and password
    procedure SignUpWithEmailAndPassword(const Email,
      Password: string; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    function SignUpWithEmailAndPasswordSynchronous(const Email,
      Password: string): IFirebaseUser;
    // Login
    procedure SignInWithEmailAndPassword(const Email, Password: string;
      OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
    function SignInWithEmailAndPasswordSynchronous(const Email,
      Password: string): IFirebaseUser;
    procedure SignInAnonymously(OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    function SignInAnonymouslySynchronous: IFirebaseUser;
    // Link new email/password access to anonymous user
    procedure LinkWithEMailAndPassword(const EMail, Password: string;
      OnUserResponse: TOnUserResponse; OnError: TOnRequestError);
    function LinkWithEMailAndPasswordSynchronous(const EMail,
      Password: string): IFirebaseUser;
    // Login by using OAuth from Facebook, Twitter, Google, etc.
    procedure LinkOrSignInWithOAuthCredentials(const OAuthTokenName, OAuthToken,
      ProviderID, RequestUri: string; OnUserResponse: TOnUserResponse;
      OnError: TOnRequestError);
    function LinkOrSignInWithOAuthCredentialsSynchronous(const OAuthTokenName,
      OAuthToken, ProviderID, RequestUri: string): IFirebaseUser;
    // Logout
    procedure SignOut;
    // Send EMail for EMail Verification
    procedure SendEmailVerification(OnResponse: TOnFirebaseResp;
      OnError: TOnRequestError);
    procedure SendEmailVerificationSynchronous;
    // Providers
    procedure FetchProvidersForEMail(const EMail: string;
      OnFetchProviders: TOnFetchProviders; OnError: TOnRequestError);
    function FetchProvidersForEMailSynchronous(const EMail: string;
      Providers: TStrings): boolean; // returns true if EMail is registered
    procedure DeleteProviders(Providers: TStrings;
      OnProviderDeleted: TOnFirebaseResp; OnError: TOnRequestError);
    function DeleteProvidersSynchronous(Providers: TStrings): boolean;
    // Reset Password
    procedure SendPasswordResetEMail(const Email: string;
      OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
    procedure SendPasswordResetEMailSynchronous(const Email: string);
    procedure VerifyPasswordResetCode(const ResetPasswortCode: string;
      OnPasswordVerification: TOnPasswordVerification; OnError: TOnRequestError);
    function VerifyPasswordResetCodeSynchronous(const ResetPasswortCode: string):
      TPasswordVerificationResult;
    procedure ConfirmPasswordReset(const ResetPasswortCode, NewPassword: string;
      OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
    procedure ConfirmPasswordResetSynchronous(const ResetPasswortCode,
      NewPassword: string);
    // Change password, Change email, Update Profile Data
    // let field empty which shall not be changed
    procedure ChangeProfile(const EMail, Password, DisplayName,
      PhotoURL: string; OnResponse: TOnFirebaseResp; OnError: TOnRequestError);
    procedure ChangeProfileSynchronous(const EMail, Password, DisplayName,
      PhotoURL: string);
    // Delete signed in user account
    procedure DeleteCurrentUser(OnResponse: TOnFirebaseResp;
      OnError: TOnRequestError);
    procedure DeleteCurrentUserSynchronous;
    // Get User Data
    procedure GetUserData(OnGetUserData: TOnGetUserData;
      OnError: TOnRequestError);
    function GetUserDataSynchronous: TFirebaseUserList;
    // Token refresh
    procedure RefreshToken(OnTokenRefresh: TOnTokenRefresh;
      OnError: TOnRequestError); overload;
    procedure RefreshToken(const LastRefreshToken: string;
      OnTokenRefresh: TOnTokenRefresh; OnError: TOnRequestError); overload;
    function CheckAndRefreshTokenSynchronous(
      IgnoreExpiryCheck: boolean = false): boolean;
    // register call back in all circumstances when the token will be refreshed
    procedure InstallTokenRefreshNotification(OnTokenRefresh: TOnTokenRefresh);
    // Getter methods
    function Authenticated: boolean;
    function Token: string;
{$IFDEF TOKENJWT}
    function TokenJWT: ITokenJWT;
{$ENDIF}
    function TokenExpiryDT: TDateTime; // local time
    function NeedTokenRefresh: boolean;
    function GetRefreshToken: string;
    function GetTokenRefreshCount: cardinal;
    function GetLastServerTime(TimeZone: TTimeZone = tzLocalTime): TDateTime;
  end;

  EFirebaseFunctions = class(Exception);
  IFirebaseFunctions = interface(IInterface)
    procedure CallFunction(OnSuccess: TOnFunctionSuccess;
      OnRequestError: TOnRequestError; const FunctionName: string;
      Params: TJSONObject = nil);
    function CallFunctionSynchronous(const FunctionName: string;
      Params: TJSONObject = nil): TJSONObject;
  end;

  TOnDownload = procedure(Obj: IStorageObject) of object;
  TOnDownloadDeprecated = procedure(const ObjectName: TObjectName;
    Obj: IStorageObject) of object;
  TOnDownloadError = procedure(Obj: IStorageObject;
    const ErrorMsg: string) of object;
  EStorageObject = class(Exception);
  IStorageObject = interface(IInterface)
    procedure DownloadToStream(Stream: TStream;
      OnSuccess: TOnDownload; OnError: TOnDownloadError); overload;
    procedure DownloadToStream(Stream: TStream;
      OnSuccess: TOnDownload; OnError: TOnStorageError); overload;
    procedure DownloadToStream(const ObjectName: TObjectName; Stream: TStream;
      OnSuccess: TOnDownloadDeprecated; OnError: TOnDownloadError); overload;
      deprecated 'Use method without ObjectName instead';
    procedure DownloadToStreamSynchronous(Stream: TStream);
    function ObjectName(IncludePath: boolean = true): string;
    function Path: string;
    function LastPathElement: string;
    function ContentType: string;
    function Size: Int64;
    function Bucket: string;
    function createTime(TimeZone: TTimeZone = tzLocalTime): TDateTime;
    function updateTime(TimeZone: TTimeZone = tzLocalTime): TDatetime;
    function DownloadUrl: string;
    function DownloadToken: string;
    function MD5HashCode: string;
    function storageClass: string;
    function etag: string;
    function generation: Int64;
    function metaGeneration: Int64;
    function CacheFileName: string;
  end;

  IFirebaseStorage = interface(IInterface)
    procedure Get(const ObjectName: TObjectName; OnGetStorage: TOnStorage;
      OnGetError: TOnStorageError); overload;
    procedure Get(const ObjectName, RequestID: string;
      OnGetStorage: TOnStorageDeprecated; OnGetError: TOnRequestError);
      overload; deprecated 'Use method without RequestID instead';
    function GetSynchronous(const ObjectName: TObjectName): IStorageObject;
    procedure GetAndDownload(const ObjectName: TObjectName; Stream: TStream;
      OnGetStorage: TOnStorage; OnGetError: TOnRequestError);
    function GetAndDownloadSynchronous(const ObjectName: TObjectName;
      Stream: TStream): IStorageObject;
    procedure Delete(const ObjectName: TObjectName; OnDelete: TOnDeleteStorage;
      OnDelError: TOnStorageError);
    procedure DeleteSynchronous(const ObjectName: TObjectName);
    procedure UploadFromStream(Stream: TStream; const ObjectName: TObjectName;
      ContentType: TRESTContentType; OnUpload: TOnStorage;
      OnUploadError: TOnStorageError);
    function UploadSynchronousFromStream(Stream: TStream;
      const ObjectName: TObjectName;
      ContentType: TRESTContentType): IStorageObject;

    // Long-term storage (beyond the runtime of the app) of loaded storage files
    procedure SetupCacheFolder(const FolderName: string;
      MaxCacheSpaceInBytes: Int64 = cDefaultCacheSpaceInBytes);
    function IsCacheInUse: boolean;
    function IsCacheScanFinished: boolean;
    function GetObjectFromCache(const ObjectName: TObjectName): IStorageObject;
    function GetFileFromCache(const ObjectName: TObjectName): TStream;
    procedure ClearCache;
    function CacheUsageInPercent: extended;
    function IsCacheOverflowed: boolean;
  end;

  TVisionMLFeature = (vmlUnspecific, vmlFaceDetection, vmlLandmarkDetection,
    vmlLogoDetection, vmlLabelDetection, vmlTextDetection, vmlDocTextDetection,
    vmlSafeSearchDetection, vmlImageProperties, vmlCropHints, vmlWebDetection,
    vmlProductSearch, vmlObjectLocalization);
  TVisionMLFeatures = set of TVisionMLFeature;

  IVisionMLResponse = interface(IInterface)
    function GetFormatedJSON: string;
    function GetNoPages: integer;
    function GetPageAsFormatedJSON(PageNo: integer = 0): string;
    function GetError(PageNo: integer = 0): TErrorStatus;
    function LabelAnnotations(PageNo: integer = 0): TAnnotationList;
    function LandmarkAnnotations(PageNo: integer = 0): TAnnotationList;
    function LogoAnnotations(PageNo: integer = 0): TAnnotationList;
    function TextAnnotations(PageNo: integer = 0): TAnnotationList;
    function FullTextAnnotations(PageNo: integer = 0): TTextAnnotation;
    function ImagePropAnnotation(
      PageNo: integer = 0): TImagePropertiesAnnotation;
    function CropHintsAnnotation(PageNo: integer = 0): TCropHintsAnnotation;
    function WebDetection(PageNo: integer = 0): TWebDetection;
    function SafeSearchAnnotation(PageNo: integer = 0): TSafeSearchAnnotation;
    function FaceAnnotation(PageNo: integer = 0): TFaceAnnotationList;
    function LocalizedObjectAnnotation(
      PageNo: integer = 0): TLocalizedObjectList;
    function ProductSearchAnnotation(
      PageNo: integer = 0): TProductSearchAnnotation;
    function ImageAnnotationContext(
      PageNo: integer = 0): TImageAnnotationContext;
  end;

  TVisionModel = (vmUnset, vmStable, vmLatest);

  IVisionML = interface(IInterface)
    function AnnotateFileSynchronous(const FileAsBase64,
      ContentType: string; Features: TVisionMLFeatures;
      MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable): IVisionMLResponse;
    procedure AnnotateFile(const FileAsBase64,
      ContentType: string; Features: TVisionMLFeatures;
      OnAnnotate: TOnAnnotate; OnAnnotateError: TOnRequestError;
      const RequestID: string = ''; MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable);
    function AnnotateStorageSynchronous(const RefStorageCloudURI,
      ContentType: string; Features: TVisionMLFeatures;
      MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable): IVisionMLResponse;
    procedure AnnotateStorage(const RefStorageCloudURI,
      ContentType: string; Features: TVisionMLFeatures;
      OnAnnotate: TOnAnnotate; OnAnnotateError: TOnRequestError;
      MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable);
  end;

  /// <summary>
  /// The interface IFirebaseConfiguration provides a class factory for
  /// accessing all interfaces to the Firebase services. The interface will be
  /// created by the constructors of the class TFirebaseConfiguration in the
  /// unit FB4D.Configuration. The first constructor requires all secrets of the
  /// Firebase project as ApiKey and Project ID and when using the Storage also
  /// the storage Bucket. The second constructor parses the google-services.json
  /// file that shall be loaded from the Firebase Console after adding an App in
  /// the project settings.
  /// </summary>
  EFirebaseConfiguration = class(Exception);
  IFirebaseConfiguration = interface(IInterface)
    function ProjectID: string;
    function Auth: IFirebaseAuthentication;
    function RealTimeDB: IRealTimeDB;
    function Database(
      const DatabaseID: string = cDefaultDatabaseID): IFirestoreDatabase;
    function Storage: IFirebaseStorage;
    function Functions: IFirebaseFunctions;
    function VisionML: IVisionML;
    procedure SetBucket(const Bucket: string);
  end;

const
  cFirestoreDocumentPath = 'projects/%s/databases/%s/documents%s';

  // Params at TQueryParams
  cGetQueryParamOrderBy = 'orderBy';
  cGetQueryParamLimitToFirst = 'limitToFirst';
  cGetQueryParamLimitToLast = 'limitToLast';
  cGetQueryParamStartAt = 'startAt';
  cGetQueryParamEndAt = 'endAt';
  cGetQueryParamEqualTo = 'equalTo';

  cFirestorePageSize = 'pageSize';
  cFirestorePageToken = 'pageToken';
  cFirestoreTransaction = 'transaction';

  // Vars at GetServerVariables
  cServerVariableTimeStamp = 'timestamp';

  // Events at TOnReceiveEvent
  cEventPut = 'put';
  cEventPatch = 'patch';
  cEventCancel = 'cancel';

  // Nodes in JSONObj at TOnReceiveEvent
  cData = 'data';
  cPath = 'path';

implementation

{$IFDEF LINUX64}
{$I LinuxTypeImpl.inc}
{$ENDIF}

{ TOnSuccess }

constructor TOnSuccess.Create(OnResp: TOnFirebaseResp);
begin
  if assigned(OnResp) then
    OnSuccessCase := oscFB
  else
    OnSuccessCase := oscUndef;
  {$IFDEF AUTOREFCOUNT}
  OnUserResponse := nil;
  OnFetchProviders := nil;
  OnPasswordVerification := nil;
  OnGetUserData := nil;
  OnRefreshToken := nil;
  OnRTDBValue := nil;
  OnRTDBDelete := nil;
  OnRTDBServerVariable := nil;
  OnDocument := nil;
  OnDocuments := nil;
  OnBeginTransaction := nil;
  OnStorage := nil;
  OnStorageGetAndDown := nil;
  OnStorageUpload := nil;
  OnDelStorage := nil;
  OnFunctionSuccess := nil;
  {$ENDIF}
  OnStorageError := nil;
  DownStream := nil;
  UpStream := nil;
  OnResponse := OnResp;
end;

constructor TOnSuccess.CreateUser(OnUserResp: TOnUserResponse);
begin
  Create(nil);
  OnSuccessCase := oscUser;
  OnUserResponse := OnUserResp;
end;

constructor TOnSuccess.CreateFetchProviders(
  OnFetchProvidersResp: TOnFetchProviders);
begin
  Create(nil);
  OnSuccessCase := oscFetchProvider;
  OnFetchProviders := OnFetchProvidersResp;
end;

constructor TOnSuccess.CreatePasswordVerification(
  OnPasswordVerificationResp: TOnPasswordVerification);
begin
  Create(nil);
  OnSuccessCase := oscPwdVerification;
  OnPasswordVerification := OnPasswordVerificationResp;
end;

constructor TOnSuccess.CreateGetUserData(OnGetUserDataResp: TOnGetUserData);
begin
  Create(nil);
  OnSuccessCase := oscGetUserData;
  OnGetUserData := OnGetUserDataResp;
end;

constructor TOnSuccess.CreateRefreshToken(OnRefreshTokenResp: TOnTokenRefresh);
begin
  Create(nil);
  OnSuccessCase := oscRefreshToken;
  OnRefreshToken := OnRefreshTokenResp;
end;

constructor TOnSuccess.CreateRTDBValue(OnRTDBValueResp: TOnRTDBValue);
begin
  Create(nil);
  OnSuccessCase := oscRTDBValue;
  OnRTDBValue := OnRTDBValueResp;
end;

constructor TOnSuccess.CreateRTDBDelete(OnRTDBDeleteResp: TOnRTDBDelete);
begin
  Create(nil);
  OnSuccessCase := oscRTDBDelete;
  OnRTDBDelete := OnRTDBDeleteResp;
end;

constructor TOnSuccess.CreateRTDBServerVariable(
  OnRTDBServerVariableResp: TOnRTDBServerVariable);
begin
  Create(nil);
  OnSuccessCase := oscRTDBServerVariable;
  OnRTDBServerVariable := OnRTDBServerVariableResp;
end;

constructor TOnSuccess.CreateFirestoreDoc(OnDocumentResp: TOnDocument);
begin
  Create(nil);
  OnSuccessCase := oscDocument;
  OnDocument := OnDocumentResp;
end;

constructor TOnSuccess.CreateFirestoreDocs(OnDocumentsResp: TOnDocuments);
begin
  Create(nil);
  OnSuccessCase := oscDocuments;
  OnDocuments := OnDocumentsResp;
end;

constructor TOnSuccess.CreateFirestoreDocDelete(
  OnDocumentDeleteResp: TOnDeletedDocument);
begin
  Create(nil);
  OnSuccessCase := oscDocumentDeleted;
  OnDocumentDeleted := OnDocumentDeleteResp;
end;

constructor TOnSuccess.CreateFirestoreReadTransaction(
  OnBeginReadTransactionResp: TOnBeginReadTransaction);
begin
  Create(nil);
  OnSuccessCase := oscBeginReadTransaction;
  OnBeginReadTransaction := OnBeginReadTransactionResp;
end;

constructor TOnSuccess.CreateFirestoreCommitWriteTransaction(
  OnCommitTransaction: TOnCommitWriteTransaction);
begin
  Create(nil);
  OnSuccessCase := oscCommitWriteTransaction;
  OnCommitTransaction := OnCommitTransaction;
end;

constructor TOnSuccess.CreateStorage(OnStorageResp: TOnStorage);
begin
  Create(nil);
  OnSuccessCase := oscStorage;
  OnStorage := OnStorageResp;
end;

constructor TOnSuccess.CreateStorageDeprecated(
  OnStorageResp: TOnStorageDeprecated);
begin
  Create(nil);
  OnSuccessCase := oscStorageDeprecated;
  OnStorageDeprecated := OnStorageResp;
end;

constructor TOnSuccess.CreateStorageGetAndDownload(OnStorageResp: TOnStorage;
  OnStorageErrorResp: TOnRequestError; Stream: TStream);
begin
  Create(nil);
  OnSuccessCase := oscStorageGetAndDown;
  OnStorageGetAndDown := OnStorageResp;
  OnStorageError := OnStorageErrorResp;
  DownStream := Stream;
end;

constructor TOnSuccess.CreateStorageUpload(OnStorageResp: TOnStorage;
  Stream: TStream);
begin
  Create(nil);
  OnSuccessCase := oscStorageUpload;
  OnStorageUpload := OnStorageResp;
  UpStream := Stream;
end;

constructor TOnSuccess.CreateDelStorage(OnDelStorageResp: TOnDeleteStorage);
begin
  Create(nil);
  OnSuccessCase := oscDelStorage;
  OnDelStorage := OnDelStorageResp;
end;

constructor TOnSuccess.CreateFunctionSuccess(
  OnFunctionSuccessResp: TOnFunctionSuccess);
begin
  Create(nil);
  OnSuccessCase := oscFunctionSuccess;
  OnFunctionSuccess := OnFunctionSuccessResp;
end;

constructor TOnSuccess.CreateVisionML(OnAnnotateResp: TOnAnnotate);
begin
  Create(nil);
  OnSuccessCase := oscVisionML;
  OnAnnotate := OnAnnotateResp;
end;

end.
