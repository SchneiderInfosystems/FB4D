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
  REST.Types;

{$IFDEF LINUX64}
{$I LinuxTypeDecl.inc}
{$ENDIF}

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
  end;

  TQueryParams = TDictionary<string, TStringDynArray>;
  TTokenMode = (tmNoToken, tmBearer, tmAuthParam);
  IFirebaseRequest = interface;
  TOnResponse = procedure(const RequestID: string;
    Response: IFirebaseResponse) of object;
  TOnRequestError = procedure(const RequestID, ErrMsg: string) of object;
  TRequestResourceParam = TStringDynArray;
  IFirebaseRequest = interface(IInterface)
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TJSONValue;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnResponse; OnRequestError: TOnRequestError); overload;
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnResponse; OnRequestError: TOnRequestError); overload;
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
    procedure StopListening(const NodeName: string = '';
      MaxTimeOutInMS: cardinal = 500);
    function GetResourceParams: TRequestResourceParam;
    function IsStopped: boolean;
  end;

  TOnGetValue = procedure(ResourceParams: TRequestResourceParam; Val: TJSONValue)
    of object;
  TOnDelete = procedure(Params: TRequestResourceParam; Success: boolean)
    of object;
  TOnReceiveEvent = procedure(const Event: string;
    Params: TRequestResourceParam; JSONObj: TJSONObject) of object;
  TOnServerVariable = procedure(const ServerVar: string; Val: TJSONValue)
    of object;
  TOnServerTimeStamp = procedure(ServerTime: TDateTime) of object;
  TOnStopListenEvent = TNotifyEvent;
  TOnAuthRevokedEvent = procedure(TokenRenewPassed: boolean) of object;
  IRealTimeDB = interface(IInterface)
    procedure Get(ResourceParams: TRequestResourceParam;
      OnGetValue: TOnGetValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function GetSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Put(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPutValue: TOnGetValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PutSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Post(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPostValue: TOnGetValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PostSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Patch(ResourceParams: TRequestResourceParam; Data: TJSONValue;
      OnPatchValue: TOnGetValue; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function PatchSynchronous(ResourceParams: TRequestResourceParam;
      Data: TJSONValue; QueryParams: TQueryParams = nil): TJSONValue; // The caller has to free the TJSONValue
    procedure Delete(ResourceParams: TRequestResourceParam;
      OnDelete: TOnDelete; OnRequestError: TOnRequestError;
      QueryParams: TQueryParams = nil);
    function DeleteSynchronous(ResourceParams: TRequestResourceParam;
      QueryParams: TQueryParams = nil): boolean;
    // long time running request
    function ListenForValueEvents(ResourceParams: TRequestResourceParam;
      ListenEvent: TOnReceiveEvent; OnStopListening: TOnStopListenEvent;
      OnError: TOnRequestError;
      OnAuthRevoked: TOnAuthRevokedEvent = nil): IFirebaseEvent;
    function GetLastKeepAliveTimeStamp: TDateTime;
    // To retrieve server variables like timestamp and future variables
    procedure GetServerVariables(const ServerVarName: string;
      ResourceParams: TRequestResourceParam;
      OnServerVariable: TOnServerVariable = nil; OnError: TOnRequestError = nil);
    function GetServerVariablesSynchronous(const ServerVarName: string;
      ResourceParams: TRequestResourceParam): TJSONValue;
  end;

  EFirestoreDocument = class(Exception);
  TJSONObjects = array of TJSONObject;
  TFirestoreFieldType = (fftNull, fftBoolean, fftInteger, fftDouble,
    fftTimeStamp, fftString, fftBytes, fftReference, fftGeoPoint, fftArray,
    fftMap);
  IFirestoreDocument = interface(IInterface)
    function DocumentName(FullPath: boolean): string;
    function CreateTime: TDateTime;
    function UpdateTime: TDatetime;
    function CountFields: integer;
    function FieldName(Ind: integer): string;
    function FieldByName(const FieldName: string): TJSONObject;
    function FieldValue(Ind: integer): TJSONObject;
    function FieldType(Ind: integer): TFirestoreFieldType;
    function FieldTypeByName(const FieldName: string): TFirestoreFieldType;
    function GetValue(Ind: integer): TJSONValue; overload;
    function GetValue(const FieldName: string): TJSONValue; overload;
    function GetStringValue(const FieldName: string): string;
    function GetStringValueDef(const FieldName, Default: string): string;
    function GetIntegerValue(const FieldName: string): integer;
    function GetIntegerValueDef(const FieldName: string;
      Default: integer): integer;
    function GetDoubleValue(const FieldName: string): double;
    function GetDoubleValueDef(const FieldName: string;
      Default: double): double;
    function GetBoolValue(const FieldName: string): boolean;
    function GetBoolValueDef(const FieldName: string;
      Default: boolean): boolean;
    function GetTimeStampValue(const FieldName: string): TDateTime;
    function GetTimeStampValueDef(const FieldName: string;
      Default: TDateTime): TDateTime;
    function GetGeoPoint(const FieldName: string): TLocationCoord2D;
    function GetReference(const FieldName: string): string;
    function GetBytes(const FieldName: string): TBytes;
    function GetArrayValues(const FieldName: string): TJSONObjects;
    function GetArrayMapValues(const FieldName: string): TJSONObjects;
    function GetArraySize(const FieldName: string): integer;
    function GetArrayType(const FieldName: string;
      Index: integer): TFirestoreFieldType;
    function GetArrayItem(const FieldName: string; Index: integer): TJSONPair;
    function GetArrayValue(const FieldName: string; Index: integer): TJSONValue;
    function GetMapSize(const FieldName: string): integer;
    function GetMapType(const FieldName: string;
      Index: integer): TFirestoreFieldType;
    function GetMapValue(const FieldName: string; Index: integer): TJSONValue;
    function GetMapValues(const FieldName: string): TJSONObjects;
    function AddOrUpdateField(Field: TJSONPair): IFirestoreDocument; overload;
    function AddOrUpdateField(const FieldName: string;
      Val: TJSONValue): IFirestoreDocument; overload;
    function AsJSON: TJSONObject;
    property Fields[Index: integer]: TJSONObject read FieldValue;
  end;

  IFirestoreDocuments = interface(IInterface)
    function Count: integer;
    function Document(Ind: integer): IFirestoreDocument;
    function ServerTimeStamp(TimeZone: TTimeZone): TDateTime;
    function SkippedResults: integer;
  end;

  TWhereOperator = (woUnspecific, woLessThan, woLessThanOrEqual,
    woGreaterThan, woGreaterThanOrEqual, woEqual, woArrayContains);
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
  end;

  TOnDocuments = procedure(const Info: string;
    Documents: IFirestoreDocuments) of object;
  TOnDocument = procedure(const Info: string;
    Document: IFirestoreDocument) of object;
  TTransaction = string; // A base64 encoded ID
  TOnBeginTransaction = procedure(Transaction: TTransaction) of object;
  IFirestoreDatabase = interface(IInterface)
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
    procedure BeginReadOnlyTransaction(OnBeginTransaction: TOnBeginTransaction;
      OnRequestError: TOnRequestError);
    function BeginReadOnlyTransactionSynchronous: TTransaction;
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
    function LastLoginAt: TDateTime;
    function IsCreatedAtAvailable: boolean;
    function CreatedAt: TDateTime;
    // Get Token Details and Claim Fields
    function Token: string;
{$IFDEF TOKENJWT}
    function TokenJWT: ITokenJWT;
    function ClaimFieldNames: TStrings;
    function ClaimField(const FieldName: string): TJSONValue;
{$ENDIF}
    function ExpiresAt: TDateTime;
    function RefreshToken: string;
  end;
  TFirebaseUserList = TList<IFirebaseUser>;

  TPasswordVerificationResult = (pvrOpNotAllowed, pvrPassed, pvrpvrExpired,
    pvrInvalid);
  TOnUserResponse = procedure(const Info: string; User: IFirebaseUser) of object;
  TOnFetchProviders = procedure(const EMail: string; IsRegistered: boolean;
    Providers: TStrings) of object;
  TOnPasswordVerification = procedure(const Info: string;
    Result: TPasswordVerificationResult) of object;
  TOnGetUserData = procedure(FirebaseUserList: TFirebaseUserList) of object;
  TOnTokenRefresh = procedure(TokenRefreshed: boolean) of object;
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
    // Logout
    procedure SignOut;
    // Send EMail for EMail Verification
    procedure SendEmailVerification(OnResponse: TOnResponse;
      OnError: TOnRequestError);
    procedure SendEmailVerificationSynchronous;
    // Providers
    procedure FetchProvidersForEMail(const EMail: string;
      OnFetchProviders: TOnFetchProviders; OnError: TOnRequestError);
    function FetchProvidersForEMailSynchronous(const EMail: string;
      Strings: TStrings): boolean; // returns true if EMail is registered
    // Reset Password
    procedure SendPasswordResetEMail(const Email: string;
      OnResponse: TOnResponse; OnError: TOnRequestError);
    procedure SendPasswordResetEMailSynchronous(const Email: string);
    procedure VerifyPasswordResetCode(const ResetPasswortCode: string;
      OnPasswordVerification: TOnPasswordVerification; OnError: TOnRequestError);
    function VerifyPasswordResetCodeSynchronous(const ResetPasswortCode: string):
      TPasswordVerificationResult;
    procedure ConfirmPasswordReset(const ResetPasswortCode, NewPassword: string;
      OnResponse: TOnResponse; OnError: TOnRequestError);
    procedure ConfirmPasswordResetSynchronous(const ResetPasswortCode,
      NewPassword: string);
    // Change password, Change email, Update Profile Data
    // let field empty which shall not be changed
    procedure ChangeProfile(const EMail, Password, DisplayName,
      PhotoURL: string; OnResponse: TOnResponse; OnError: TOnRequestError);
    procedure ChangeProfileSynchronous(const EMail, Password, DisplayName,
      PhotoURL: string);
    // Delete signed in user account
    procedure DeleteCurrentUser(OnResponse: TOnResponse;
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
    function CheckAndRefreshTokenSynchronous: boolean;
    // Getter methods
    function Authenticated: boolean;
    function Token: string;
{$IFDEF TOKENJWT}
    function TokenJWT: ITokenJWT;
{$ENDIF}
    function TokenExpiryDT: TDateTime;
    function NeedTokenRefresh: boolean;
    function GetRefreshToken: string;
  end;

  EFirebaseFunctions = class(Exception);
  TOnFunctionSuccess = procedure(const Info: string; ResultObj: TJSONObject) of
    object;
  IFirebaseFunctions = interface(IInterface)
    procedure CallFunction(OnSuccess: TOnFunctionSuccess;
      OnRequestError: TOnRequestError; const FunctionName: string;
      Params: TJSONObject = nil);
    function CallFunctionSynchronous(const FunctionName: string;
      Params: TJSONObject = nil): TJSONObject;
  end;

  IStorageObject = interface;
  TOnDownload = procedure(const RequestID: string; Obj: IStorageObject)
    of object;
  TOnDownloadError = procedure(Obj: IStorageObject;
    const ErrorMsg: string) of object;
  EStorageObject = class(Exception);
  IStorageObject = interface(IInterface)
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
    function DownloadUrl: string;
    function DownloadToken: string;
    function MD5HashCode: string;
    function storageClass: string;
    function etag: string;
    function generation: Int64;
    function metaGeneration: Int64;
  end;

  TOnGetStorage = procedure(const RequestID: string; Obj: IStorageObject)
    of object;
  TOnDeleteStorage = procedure(const ObjectName: string) of object;
  TOnUploadFromStream = procedure(const ObjectName: string; Obj: IStorageObject)
    of object;
  IFirebaseStorage = interface(IInterface)
    procedure Get(const ObjectName, RequestID: string;
      OnGetStorage: TOnGetStorage; OnGetError: TOnRequestError);
    function GetSynchronous(const ObjectName: string): IStorageObject;
    procedure Delete(const ObjectName: string; OnDelete: TOnDeleteStorage;
      OnDelError: TOnRequestError);
    procedure DeleteSynchronous(const ObjectName: string);
    procedure UploadFromStream(Stream: TStream; const ObjectName: string;
      ContentType: TRESTContentType; OnUpload: TOnUploadFromStream;
      OnUploadError: TOnRequestError);
    function UploadSynchronousFromStream(Stream: TStream;
      const ObjectName: string; ContentType: TRESTContentType): IStorageObject;
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
    function Auth: IFirebaseAuthentication;
    function RealTimeDB: IRealTimeDB;
    function Database: IFirestoreDatabase;
    function Storage: IFirebaseStorage;
    function Functions: IFirebaseFunctions;
  end;

const
  // Params at TQueryParams
  cGetQueryParamOrderBy = 'orderBy';
  cGetQueryParamLimitToFirst = 'limitToFirst';
  cGetQueryParamLimitToLast = 'limitToLast';
  cGetQueryParamStartAt = 'startAt';
  cGetQueryParamEndAt = 'endAt';
  cGetQueryParamEqualTo = 'equalTo';

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

end.
