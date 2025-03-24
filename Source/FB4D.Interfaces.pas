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

  cGeminiAIPro1_0 = 'gemini-1.0-pro';
  cGeminiAIPro1_5 = 'gemini-1.5-pro';
  cGeminiAIFlash1_5 = 'gemini-1.5-flash';
  cGeminiAIDefaultModel = cGeminiAIPro1_5;

type
  TGeminiAPIVersion = (V1, V1Beta);
const
  cDefaultGeminiAPIVersion = V1Beta;

type
  // Forward declarations
  IFirebaseUser = interface;
  IFirebaseResponse = interface;
  IFirestoreDocument = interface;
  IFirestoreDocuments = interface;
  IStorageObject = interface;
  IVisionMLResponse = interface;
  IGeminiAIResponse = interface;
  IGeminiSchema = interface;

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
  /// Event handler type for request errors.
  /// This event is triggered when a Firebase request encounters an error.
  /// </summary>
  /// <param name="RequestID">The unique identifier of the request that failed.</param>
  /// <param name="ErrMsg">The error message describing the reason for failure.</param>
  TOnRequestError = procedure(const RequestID, ErrMsg: string) of object;

  /// <summary>
  /// Type alias for a dynamic array of strings representing resource parameters for a request.
  /// Each string in the array represents a segment of the resource path.
  /// </summary>
  TRequestResourceParam = TStringDynArray;

  /// <summary>
  /// Event handler type for successful Firebase responses.
  /// This event is triggered when a Firebase request completes successfully.
  /// </summary>
  /// <param name="RequestID">The unique identifier of the successful request.</param>
  /// <param name="Response">The IFirebaseResponse object containing the response data.</param>
  TOnFirebaseResp = procedure(const RequestID: string;
    Response: IFirebaseResponse) of object;

  /// <summary>
  /// Represents a list of IFirebaseUser objects.
  /// </summary>
  TFirebaseUserList = TList<IFirebaseUser>;

  /// <summary>
  /// Enumerates the possible results of a password verification operation.
  /// </summary>
  TPasswordVerificationResult = (
    pvrOpNotAllowed, ///< The operation is not allowed.
    pvrPassed, ///< The password verification was successful.
    pvrExpired, ///< The password has expired.
    pvrInvalid ///< The provided password is invalid.
  );

  /// <summary>
  /// Event handler type for user-related responses.
  /// This event is triggered when a user operation completes.
  /// </summary>
  /// <param name="Info">Additional information about the response.</param>
  /// <param name="User">The IFirebaseUser object representing the user.</param>
  TOnUserResponse = procedure(const Info: string; User: IFirebaseUser) of object;

  /// <summary>
  /// Event handler type for fetching authentication providers.
  /// This event is triggered when the list of available authentication providers is retrieved.
  /// </summary>
  /// <param name="RequestID">The unique identifier of the request.</param>
  /// <param name="IsRegistered">Indicates whether the user is already registered.</param>
  /// <param name="Providers">A TStrings object containing the list of available providers.</param>
  TOnFetchProviders = procedure(const RequestID: string; IsRegistered: boolean; Providers: TStrings) of object;

  /// <summary>
  /// Event handler type for password verification results.
  /// This event is triggered when a password verification operation completes.
  /// </summary>
  /// <param name="Info">Additional information about the response.</param>
  /// <param name="Result">The result of the password verification operation.</param>
  TOnPasswordVerification = procedure(const Info: string; Result: TPasswordVerificationResult) of object;

  /// <summary>
  /// Event handler type for retrieving user data.
  /// This event is triggered when the user data is successfully retrieved.
  /// </summary>
  /// <param name="FirebaseUserList">A TFirebaseUserList containing the retrieved user data.</param>
  TOnGetUserData = procedure(FirebaseUserList: TFirebaseUserList) of object;

  /// <summary>
  /// Event handler type for token refresh operations.
  /// This event is triggered when a token refresh operation completes.
  /// </summary>
  /// <param name="TokenRefreshed">Indicates whether the token was successfully refreshed.</param>
  TOnTokenRefresh = procedure(TokenRefreshed: boolean) of object;

  /// <summary>
  /// Event handler type for Realtime Database value changes.
  /// This event is triggered when the value of a specific resource in the database changes.
  /// </summary>
  /// <param name="ResourceParams">Parameters of the resource whose value changed.</param>
  /// <param name="Val">The new JSON value of the resource.</param>
  TOnRTDBValue = procedure(ResourceParams: TRequestResourceParam; Val: TJSONValue) of object;

  /// <summary>
  /// Event handler type for Realtime Database delete operations.
  /// This event is triggered when a delete operation on a resource in the database completes.
  /// </summary>
  /// <param name="Params">Parameters of the resource that was deleted.</param>
  /// <param name="Success">Indicates whether the delete operation was successful.</param>
  TOnRTDBDelete = procedure(Params: TRequestResourceParam; Success: boolean) of object;

  /// <summary>
  /// Event handler type for Realtime Database server variable changes.
  /// This event is triggered when the value of a server variable in the database changes.
  /// </summary>
  /// <param name="ServerVar">The name of the server variable that changed.</param>
  /// <param name="Val">The new JSON value of the server variable.</param>
  TOnRTDBServerVariable = procedure(const ServerVar: string; Val: TJSONValue) of object;

  /// <summary>
  /// Event handler type for receiving a single Firestore document.
  /// </summary>
  /// <param name="Info">Additional information about the document retrieval.</param>
  /// <param name="Document">The retrieved Firestore document.</param>
  TOnDocument = procedure(const Info: string; Document: IFirestoreDocument) of object;

  /// <summary>
  /// Event handler type for receiving multiple Firestore documents.
  /// </summary>
  /// <param name="Info">Additional information about the document retrieval.</param>
  /// <param name="Documents">The retrieved Firestore documents.</param>
  TOnDocuments = procedure(const Info: string; Documents: IFirestoreDocuments) of object;

  /// <summary>
  /// Event handler type for receiving a changed Firestore document.
  /// </summary>
  /// <param name="ChangedDocument">The changed Firestore document.</param>
  TOnChangedDocument = procedure(ChangedDocument: IFirestoreDocument) of object;

  /// <summary>
  /// Event handler type for receiving a deleted Firestore document.
  /// </summary>
  /// <param name="DeleteDocumentPath">The path of the deleted document.</param>
  /// <param name="TimeStamp">The timestamp of the deletion.</param>
  TOnDeletedDocument = procedure(const DeleteDocumentPath: string; TimeStamp: TDateTime) of object;

  /// <summary>
  /// Type representing a Firestore read transaction ID, encoded in Base64.
  /// </summary>
  TFirestoreReadTransaction = string;

  /// <summary>
  /// Event handler type for the beginning of a Firestore read transaction.
  /// </summary>
  /// <param name="Transaction">The ID of the started read transaction.</param>
  TOnBeginReadTransaction = procedure(Transaction: TFirestoreReadTransaction) of object;

  /// <summary>
  /// Interface representing a committed Firestore write transaction.
  /// </summary>
  IFirestoreCommitTransaction = interface
    /// <summary>
    /// Returns the commit time of the transaction in the specified time zone.
    /// </summary>
    /// <param name="TimeZone">Either the local time zone or UTC for the commit time (default is UTC).</param>
    /// <returns>The commit time of the transaction.</returns>
    function CommitTime(TimeZone: TTimeZone = tzUTC): TDateTime;

    /// <summary>
    /// Returns the number of updates performed in the transaction.
    /// </summary>
    /// <returns>The number of updates in the transaction.</returns>
    function NoUpdates: cardinal;

    /// <summary>
    /// Returns the update time of the specified update within the transaction.
    /// </summary>
    /// <param name="Index">The index of the update (zero-based).</param>
    /// <param name="TimeZone">Either the local time zone or UTC for the update time (default is UTC).</param>
    /// <returns>The update time of the specified update.</returns>
    function UpdateTime(Index: cardinal; TimeZone: TTimeZone = tzUTC): TDateTime;
  end;

  /// <summary>
  /// Event handler type for the successful commit of a Firestore write transaction.
  /// </summary>
  /// <param name="Transaction">Information about the committed transaction.</param>
  TOnCommitWriteTransaction = procedure(Transaction: IFirestoreCommitTransaction) of object;

  /// <summary>
  /// Type representing the name of an object in the Cloud Storage.
  /// </summary>
  TObjectName = string;

  /// <summary>
  /// Event handler type for successful storage operations.
  /// </summary>
  /// <param name="Obj">The storage object involved in the operation.</param>
  TOnStorage = procedure(Obj: IStorageObject) of object;
  /// <summary>
  /// Deprecated event handler type for successful storage operations. Don't use it for new projects anymore.
  /// Use TOnStorage instead.
  /// </summary>
  TOnStorageDeprecated = procedure(const ObjectName: TObjectName; Obj: IStorageObject) of object;

  /// <summary>
  /// Event handler type for errors during storage operations.
  /// </summary>
  /// <param name="ObjectName">The name of the object involved in the error.</param>
  /// <param name="ErrMsg">The error message.</param>
  TOnStorageError = procedure(const ObjectName: TObjectName; const ErrMsg: string) of object;

  /// <summary>
  /// Event handler type for successful deletion of a storage object.
  /// </summary>
  /// <param name="ObjectName">The name of the deleted object.</param>
  TOnDeleteStorage = procedure(const ObjectName: TObjectName) of object;

  /// <summary>
  /// Event handler type for successful function execution in Cloud Functions.
  /// </summary>
  /// <param name="Info">Additional information about the function execution.</param>
  /// <param name="ResultObj">The result of the function execution as a JSON object.</param>
  TOnFunctionSuccess = procedure(const Info: string; ResultObj: TJSONObject) of object;

  /// <summary>
  /// Event handler signature for receiving annotation results from a Vision ML API call.
  /// </summary>
  /// <param name="Res">The IVisionMLResponse object containing the annotation results.</param>
  TOnAnnotate = procedure(Res: IVisionMLResponse) of object;

  /// <summary>
  /// Event handler signature for receiving model names from a Gemini AI API call.
  /// </summary>
  /// <param name="Models">Returns a list of model names. Copy the string list within the callback handler because
  /// the caller will get Models free after call. In case of error this list is nil.</param>
  /// <param name="ErrorMsg">In cases where Models returns nil the ErrorMsg contains the reason of the problem.</param>
  TOnGeminiFetchModels = procedure(Models: TStrings; const ErrorMsg: string) of object;

  /// <summary>
  /// Detail information of Gemini AI models
  /// </summary>
  TGeminiModelDetails = record
    ModelFullName: string;
    BaseModelId: string;
    Version: string;
    DisplayName: string;
    Description: string;
    InputTokenLimit: integer;
    OutputTokenLimit: integer;
    SupportedGenerationMethods: array of string;
    Temperature: double;
    MaxTemperature: double;
    TopP: double;
    TopK: integer;
    procedure Init;
  end;

  /// <summary>
  /// Event handler signature for receiving model name detail from a Gemini AI API call.
  /// </summary>
  /// <param name="Detail">Returns all details of model. In case of error this list is nil.</param>
  /// <param name="ErrorMsg">In normal case this string is empty. In case of error this string contains the reason
  /// of the problem.</param>
  TOnGeminiFetchModel = procedure(Detail: TGeminiModelDetails; const ErrorMsg: string) of object;

  /// <summary>
  /// Event handler signature for receiving generated content from a Gemini AI API call.
  /// </summary>
  /// <param name="Response">The IGeminiAIResponse object containing the generated content.</param>
  TOnGeminiGenContent = procedure(Response: IGeminiAIResponse) of object;

  /// <summary>
  /// Event handler signature for receiving token count information from a Gemini AI API call.
  /// </summary>
  /// <param name="PromptToken">The number of tokens in the prompt.</param>
  /// <param name="CachedContentToken">The number of tokens in the cached content (if any).</param>
  /// <param name="ErrorMsg">An error message if the token count operation failed.</param>
  TOnGeminiCountToken = procedure(PromptToken, CachedContentToken: integer; const ErrorMsg: string) of object;

  {$REGION 'Internaly used OnSuccess Structure'}
  TOnSuccess = record
    type TOnSuccessCase = (oscUndef,
      oscFB, oscUser, oscFetchProvider, oscPwdVerification, oscGetUserData, oscRefreshToken,
      oscRTDBValue, oscRTDBDelete, oscRTDBServerVariable,
      oscDocument, oscDocuments,
      oscDocumentDeleted, oscBeginReadTransaction, oscCommitWriteTransaction,
      oscStorage, oscStorageDeprecated, oscStorageUpload, oscStorageGetAndDown, oscDelStorage,
      oscFunctionSuccess,
      oscVisionML,
      oscGeminiFetchModelNames, oscGeminiFetchModelDetail, oscGeminiGenContent, oscGeminiCountToken);
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
    constructor CreateGeminiFetchModelNames(OnGeminiFetchModels: TOnGeminiFetchModels);
    constructor CreateGeminiFetchModelDetail(OnGeminiFetchModelDetail: TOnGeminiFetchModel);
    constructor CreateGeminiGenerateContent(OnGeminiGenContent: TOnGeminiGenContent);
    constructor CreateGeminiCountToken(OnGeminiCountToken: TOnGeminiCountToken);
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
      oscGeminiFetchModelNames: (OnFetchModels: TOnGeminiFetchModels);
      oscGeminiFetchModelDetail: (OnFetchModelDetail: TOnGeminiFetchModel);
      oscGeminiGenContent: (OnGenerateContent: TOnGeminiGenContent);
      oscGeminiCountToken: (OnCountToken: TOnGeminiCountToken);
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
      OnFetchModels: TOnGeminiFetchModels;
      OnFetchModelDetail: TOnGeminiFetchModel;
      OnGenerateContent: TOnGeminiGenContent;
      OnCountToken: TOnGeminiCountToken;
    {$ENDIF}
  end;

  TOnRequestErrorWithOnSuccess = procedure(const RequestID, ErrMsg: string;
    OnSuccess: TOnSuccess) of object;
  {$ENDREGION}

  {$REGION 'General used Firebase Response'}
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
    function GetOnErrorWithSuccess: TOnRequestErrorWithOnSuccess;
    function HeaderValue(const HeaderName: string): string;
    property OnSuccess: TOnSuccess read GetOnSuccess;
    property OnError: TOnRequestError read GetOnError;
    property OnErrorWithSuccess: TOnRequestErrorWithOnSuccess
      read GetOnErrorWithSuccess;
   end;
  {$ENDREGION}

  {$REGION 'General used Firebase Request'}
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
      Method: TRESTRequestMethod; Data: TJSONValue;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestErrorWithOnSuccess: TOnRequestErrorWithOnSuccess;
      OnSuccess: TOnSuccess); overload;
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestError: TOnRequestError;
      OnSuccess: TOnSuccess); overload;
    procedure SendRequest(ResourceParams: TRequestResourceParam;
      Method: TRESTRequestMethod; Data: TStream; ContentType: TRESTContentType;
      QueryParams: TQueryParams; TokenMode: TTokenMode;
      OnResponse: TOnFirebaseResp; OnRequestErrorWithOnSuccess: TOnRequestErrorWithOnSuccess;
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
  {$ENDREGION}

  {$REGION 'Firebase Realtime DB'}
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
  {$ENDREGION}

  {$REGION 'Firestore Database'}
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
  {$ENDREGION}

  {$REGION 'Firebase Authentication'}

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
    function GetNoOfClaims: integer;
    function GetClaimName(Index: integer): string;
    function GetClaimValue(Index: integer): TJSONValue;
    function GetClaimValueAsStr(Index: integer): string;
    property Header: TJWTHeader read GetHeader;
    property Claims: TJWTClaims read GetClaims;
    property NoOfClaims: integer read GetNoOfClaims;
    property ClaimName[Index: integer]: string read GetClaimName;
    property ClaimValue[Index: integer]: TJSONValue read GetClaimValue;
    property ClaimValueAsStr[Index: integer]: string read GetClaimValueAsStr;
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

  TPasswordPolicyItem = (RequireUpperCase, RequireLowerCase, RequireSpecialChar,
    RequireNumericChar);
  TPasswordPolicy = set of TPasswordPolicyItem;

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
    procedure RefreshToken(OnTokenRefresh: TOnTokenRefresh;
      OnErrorWithOnSuccess: TOnRequestErrorWithOnSuccess); overload;
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
  {$ENDREGION}

  {$REGION 'Cloud Functions'}
  EFirebaseFunctions = class(Exception);
  IFirebaseFunctions = interface(IInterface)
    procedure CallFunction(OnSuccess: TOnFunctionSuccess;
      OnRequestError: TOnRequestError; const FunctionName: string;
      Params: TJSONObject = nil);
    function CallFunctionSynchronous(const FunctionName: string;
      Params: TJSONObject = nil): TJSONObject;
  end;
  {$ENDREGION}

  {$REGION 'Cloud Storage'}
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
    function MD5HashCode: string; // FB doesn't offer a better hash algo, but for a simple comparison it is sufficient.
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
  {$ENDREGION}

  {$REGION 'Vision ML'}
  EVisionML = class(Exception);
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
  {$ENDREGION}

  {$REGION 'Gemini AI'}

  /// <summary>
  /// Holds metadata about the usage of the Gemini AI API.
  /// </summary>
  TGeminiAIUsageMetaData = record

    /// <summary>
    /// The number of tokens used in the prompt.
    /// </summary>
    PromptTokenCount: integer;

    /// <summary>
    /// The number of tokens generated in the response (CandidatesTokenCount).
    /// </summary>
    GeneratedTokenCount: integer;

    /// <summary>
    /// The total number of tokens used (prompt + generated).
    /// </summary>
    TotalTokenCount: integer;

    /// <summary>
    /// Initializes the metadata record with default values.
    /// </summary>
    procedure Init;
  end;

  /// <summary>
  /// Enumerates the possible states of a Gemini AI result.
  /// </summary>
  TGeminiAIResultState = (
    grsUnknown,       // The result state is unknown.
    grsTransmitError,  // An error occurred during transmission.
    grsParseError,     // An error occurred while parsing the response.
    grsValid,          // The result is valid.
    grsBlockedBySafety, // The result was blocked by the safety system.
    grsBlockedbyOtherReason // The result was blocked for another reason.
  );

  /// <summary>
  /// Enumerates the possible reasons for a Gemini AI generation to finish.
  /// </summary>
  TGeminiAIFinishReason = (
    gfrUnknown,      // The finish reason is unknown.
    gfrStop,         // The generation reached a natural stopping point.
    gfrMaxToken,     // The generation reached the maximum token limit.
    gfrSafety,       // The generation was stopped for safety reasons.
    gfrRecitation,   // The generation was flagged as potential recitation of existing content.
    gfrOther         // The generation finished for another reason.
  );

  /// <summary>
  /// A set of TGeminiAIFinishReason values when getting more than one candidate.
  /// </summary>
  TGeminiAIFinishReasons = set of TGeminiAIFinishReason;

  /// <summary>
  /// Enumerates the different categories of potential harm in AI-generated content.
  /// </summary>
  THarmCategory = (
    hcUnspecific,         // Unspecified harm category.
    hcHateSpeech,         // Hate speech.
    hcHarassment,         // Harassment.
    hcSexuallyExplicit,   // Sexually explicit content.
    hcDangerousContent,   // Dangerous content.
    hcCivicIntegrity,     // Content that undermines civic integrity.
    hcDangerous,          // Dangerous content.
    hcMedicalAdvice,      // Unsolicited medical advice.
    hcSexual,             // Sexual content.
    hcViolence,           // Violent content.
    hcToxicity,           // Toxic or abusive language.
    hcDerogatory          // Derogatory or offensive language.
  );

  /// <summary>
  /// Enumerates the levels of probability and severity for a safety rating.
  /// </summary>
  TProbabilityAndSeverity = (
    psUnknown,     // Unknown probability or severity.
    psNEGLIGIBLE, // Negligible probability or severity.
    psLOW,         // Low probability or severity.
    psMEDIUM,      // Medium probability or severity.
    psHIGH         // High probability or severity.
  );

  /// <summary>
  /// Holds information about the safety rating of a Gemini AI result.
  /// </summary>
  TSafetyRating = record

    /// <summary>
    /// The probability level of the harm category.
    /// </summary>
    Probability: TProbabilityAndSeverity;

    /// <summary>
    /// The probability score (typically a value between 0 and 1).
    /// </summary>
    ProbabilityScore: extended;

    /// <summary>
    /// The severity level of the harm category.
    /// </summary>
    Severity: TProbabilityAndSeverity;

    /// <summary>
    /// The severity score (typically a value between 0 and 1).
    /// </summary>
    SeverityScore: extended;

    /// <summary>
    /// Initializes the safety rating record with default values.
    /// </summary>
    procedure Init;

    /// <summary>
    /// Returns the probability level as a string.
    /// </summary>
    function ProbabilityAsStr: string;

    /// <summary>
    /// Returns the severity level as a string.
    /// </summary>
    function SeverityAsStr: string;
  end;

  /// <summary>
  /// Represents metadata associated with grounding information. This record
  /// stores information related to the active grounding status, relevant content
  /// chunks, supporting evidence, web search queries, rendered content, and a
  /// Google search dynamic retrieval score.
  /// </summary>
  TGroundingMetadata = record

    /// <summary>
    /// Indicates whether active grounding is enabled.
    /// </summary>
    ActiveGrounding: boolean;

    /// <summary>
    /// An array of content chunks relevant to the grounding.  Each chunk
    /// contains a URI and a title.
    /// </summary>
    Chunks: array of record
      /// <summary>
      /// URI of the content chunk.
      /// </summary>
      Uri: string;
      /// <summary>
      /// Title or brief description of the content chunk.
      /// </summary>
      title: string;
    end;

    /// <summary>
    /// An array of support elements providing evidence for the grounding. Each
    /// support element includes indices referencing related chunks, confidence
    /// scores, and a specific text segment.
    /// </summary>
    Support: array of record
      /// <summary>
      /// Indices into the 'Chunks' array, indicating which chunks are
      /// relevant to this particular piece of supporting evidence.
      /// </summary>
      ChunkIndices: array of integer;

      /// <summary>
      /// Confidence scores associated with this supporting evidence, potentially
      /// indicating the strength or reliability of the connection to the chunks.
      /// </summary>
      ConfidenceScores: array of double;

      /// <summary>
      /// The specific text segment that provides the supporting evidence.
      /// </summary>
      Segment: record
        /// <summary>
        /// Index of the part (if the text is divided into parts).  This might
        /// relate to sentence number or paragraph number.  Its meaning is context-dependent.
        /// </summary>
        PartIndex: integer;
        /// <summary>
        /// Starting index (character position) of the segment within the larger text.
        /// </summary>
        StartIndex: integer;
        /// <summary>
        /// Ending index (character position) of the segment within the larger text.
        /// </summary>
        EndIndex: integer;
        /// <summary>
        /// The actual text of the supporting segment.
        /// </summary>
        Text: string;
      end;
    end;

    /// <summary>
    /// An array of web search queries related to the grounding.  These queries
    /// were likely used to retrieve the supporting chunks.
    /// </summary>
    WebSearchQuery: array of string;


    /// <summary>
    /// The rendered content associated with the grounding.  This might be a
    /// summary, explanation, or other synthesized output based on the grounded information.
    /// </summary>
    RenderedContent: string;

    /// <summary>
    /// A score representing the dynamic retrieval quality from Google Search. This
    /// likely reflects how well the retrieved information matches the grounding context.
    /// </summary>
    GoogleSearchDynamicRetrievalScore: double;

    /// <summary>
    /// Initialization procedure for the record.
    /// </summary>
    procedure Init;
  end;

  /// <summary>
  /// Represents a single result from a Gemini AI generation.
  /// </summary>
  TGeminiAIResult = record

    /// <summary>
    /// The reason why the generation finished.
    /// </summary>
    FinishReason: TGeminiAIFinishReason;

    /// <summary>
    /// The index of the result within the response.
    /// </summary>
    Index: integer;

    /// <summary>
    /// An array of strings representing the generated text, split into parts.
    /// </summary>
    PartText: array of string;

    /// <summary>
    /// An array of safety ratings for each harm category.
    /// </summary>
    SafetyRatings: array [THarmCategory] of TSafetyRating;

    /// <summary>
    /// Metadata for enabled grounding. This structure holds information
    /// related to the grounding process, specifically details derived from
    /// a Google search.  This metadata is used when grounding is active.
    /// </summary>
    GroundingMetadata: TGroundingMetadata;

    /// <summary>
    /// Returns the result text formatted as Markdown.
    /// </summary>
    function ResultAsMarkDown: string;

    /// <summary>
    /// Returns the finish reason as a string.
    /// </summary>
    function FinishReasonAsStr: string;

    /// <summary>
    /// Initialize the structure.
    /// </summary>
    procedure Init;
  end;

  /// <summary>
  /// Interface representing a response from the Gemini AI API.
  /// </summary>
  IGeminiAIResponse = interface(IInterface)
    /// <summary>
    /// Returns the result text formatted as Markdown.
    /// </summary>
    function ResultAsMarkDown: string;

    {$IFDEF MARKDOWN2HTML}
    /// <summary>
    /// Returns the result text formatted as HTML (conditionally defined).
    /// </summary>
    function ResultAsHTML: string;
    {$ENDIF}

    /// <summary>
    /// Returns the result as JSON value or object or array when using IGeminiAIRequest.SetJSONResponseSchema.
    /// </summary>
    function ResultAsJSON: TJSONValue;

    /// <summary>
    /// Returns the number of results (candidates) in the response.
    /// </summary>
    function NumberOfResults: integer;

    /// <summary>
    /// Returns the TGeminiAIResult record at the specified index for candidates.
    /// </summary>
    function EvalResult(ResultIndex: integer): TGeminiAIResult;

    /// <summary>
    /// Returns the usage metadata for the request.
    /// </summary>
    function UsageMetaData: TGeminiAIUsageMetaData;

    /// <summary>
    /// Returns the overall state of the result.
    /// </summary>
    function ResultState: TGeminiAIResultState;

    /// <summary>
    /// Returns the result state as a string.
    /// </summary>
    function ResultStateStr: string;

    /// <summary>
    /// Returns the set of finish reasons for the generation.
    /// </summary>
    function FinishReasons: TGeminiAIFinishReasons;

    /// <summary>
    /// Returns the finish reasons as a comma-separated string.
    /// </summary>
    function FinishReasonsCommaSepStr: string;

    /// <summary>
    /// Returns True if the response is valid, False otherwise.
    /// </summary>
    function IsValid: boolean;

    /// <summary>
    /// Returns a string describing the failure, if any.
    /// </summary>
    function FailureDetail: string;

    /// <summary>
    /// Returns the model version.
    /// </summary>
    function ModelVersion: string;

    /// <summary>
    /// Returns the raw JSON response from the API.
    /// </summary>
    function RawJSONResult: TJSONValue;

    /// <summary>
    /// Returns the raw JSON response from the API as formated string or an error.
    /// </summary>
    function RawFormatedJSONResult: string;
  end;

  /// <summary>
  /// Enumerates the reason for safety blocking.
  /// </summary>
  TSafetyBlockLevel = (
    sblNone,            // No safety blocking.
    sblOnlyHigh,        // Block only high-risk content.
    sblMediumAndAbove,  // Block medium and high-risk content.
    sblLowAndAbove,     // Block low, medium, and high-risk content.
    sblUseDefault       // Use the default safety level.
  );

  /// <summary>
  /// Class to hold schema items, where property names and an instances of the IGeminiSchema interface is stored in an
  /// Interface. This structure represents the JSON schema for the data structure definition.
  /// </summary>
  TSchemaItems = TDictionary<string, IGeminiSchema>;

  /// <summary>
  /// Interface for defining a Gemini schema item. This allows building a JSON schema
  /// definition programmatically. The methods are fluent, meaning they return the
  /// interface instance itself, allowing for chained calls.
  /// </summary>
  IGeminiSchema = interface(IInterface)
    /// <summary>
    /// Sets the schema item type to string.
    /// </summary>
    function SetStringType: IGeminiSchema;

    /// <summary>
    /// Sets the schema item type to floating-point number.
    /// </summary>
    function SetFloatType: IGeminiSchema;

    /// <summary>
    /// Sets the schema item type to integer.
    /// </summary>
    function SetIntegerType: IGeminiSchema;

    /// <summary>
    /// Sets the schema item type to boolean.
    /// </summary>
    function SetBooleanType: IGeminiSchema;

    /// <summary>
    /// Sets the schema item type to an enumeration.
    /// EnumValues: An array of strings representing the allowed enum values.
    /// </summary>
    function SetEnumType(EnumValues: TStringDynArray): IGeminiSchema;

    /// <summary>
    /// Sets the schema item type to an array.
    /// </summary>
    /// <param name="ArrayElement">The schema definition for the elements within the array.
    /// </param>
    /// <param name="MaxItems">The maximum number of items allowed in the array (-1 for no limit).
    /// </param>
    /// <param name="MinItems">The minimum number of items allowed in the array (-1 for no limit).
    /// </param>
    function SetArrayType(ArrayElement: IGeminiSchema; MaxItems: integer = -1; MinItems: integer = -1): IGeminiSchema;

    /// <summary>
    /// Sets the schema item type to an object.
    /// </summary>
    /// </param>
    /// <param name="RequiredItems">A dictionary of required schema items for the object, keyed by property name.
    /// </param>
    /// <param name="OptionalItems">A dictionary of optional schema items for the object, keyed by property name.
    /// </param>
    function SetObjectType(RequiredItems: TSchemaItems; OptionalItems: TSchemaItems = nil): IGeminiSchema;

    /// <summary>
    /// Sets the description for the schema item. This is for documentation.
    /// </summary>
    /// <param name="Description">The descriptive text for the schema item. }
    /// </param>
    function SetDescription(const Description: string): IGeminiSchema;

    /// <summary>
    /// Sets the nullability of the schema item.
    /// </summary>
    /// <param name="IsNullable">True if the item can be null, False otherwise.
    /// </param>
    function SetNullable(IsNullable: boolean): IGeminiSchema;
  end;

  /// <summary>
  /// Exception class for Gemini AI requests
  /// </summary>
  EGeminiAIRequest = class(Exception);

  /// <summary>
  /// Interface for starting operations on Gemini AI API.
  /// </summary>
  IGeminiAIRequest = interface(IInterface)

    /// <summary>
    /// Use simple prompt text as request
    /// </summary>
    function Prompt(const PromptText: string): IGeminiAIRequest;

    /// <summary>
    /// Use a media file (document, picture, video, audio) with a command prompt question
    /// </summary>
    function PromptWithMediaData(const PromptText, MimeType: string; MediaStream: TStream): IGeminiAIRequest;

    {$IF CompilerVersion >= 35} // Delphi 11 and later
    {$IF Defined(FMX) OR Defined(FGX)}
    /// <summary>
    /// For images the MimeType can be evaluated automatically
    function PromptWithImgData(const PromptText: string; ImgStream: TStream): IGeminiAIRequest;
    {$ENDIF}
    {$ENDIF}

    /// <summary>
    /// Sets the model parameters for the request.
    /// </summary>
    /// <param name="Temperatur">Controls the randomness of the generated text.
    /// </param>
    /// <param name="TopP">Controls the diversity of the generated text.
    /// </param>
    /// <param name="MaxOutputTokens">Limits the maximum number of tokens in the generated text.
    /// </param>
    /// <param name="TopK">:Controls the number of candidate words considered during generation.
    /// </param>
    function ModelParameter(Temperatur, TopP: double; MaxOutputTokens, TopK: cardinal): IGeminiAIRequest;

    /// <summary>
    /// Sets the stop sequences for the request.
    /// Stop sequences are used to stop the generation process when encountered.
    /// </summary>
    function SetStopSequences(StopSequences: TStrings): IGeminiAIRequest;

    /// <summary>
    /// Sets the safety settings for the request.
    /// </summary>
    /// <param name="HarmCat">Specifies the category of harmful content to block.
    /// </param>
    /// <param name="LevelToBlock">:Specifies the safety level to use for blocking.
    /// </param>
    function SetSafety(HarmCat: THarmCategory; LevelToBlock: TSafetyBlockLevel): IGeminiAIRequest;

    /// <summary>
    /// Sets as result an JSON object with a given JSON schema.
    /// </summary>
    /// <param name="Schema">Interface to IGeminiSchema
    /// </param>
    function SetJSONResponseSchema(Schema: IGeminiSchema): IGeminiAIRequest;

    /// <summary>
    /// Augments the grounding process by incorporating Google Search results. This allows the system to
    /// consider real-world information and context from the web when grounding concepts or entities.
    /// </summary>
    /// <param name="Threshold">The minimum similarity score (between 0 and 1) required for a Google Search
    /// result to be considered a valid grounding source.  A higher threshold increases precision but
    /// might reduce recall.  For example, a threshold of 0.8 means only search results with a similarity
    /// score of 0.8 or greater will be used for grounding.
    /// </param>
    procedure AddGroundingByGoogleSearch(Threshold: double);

    /// <summary>
    /// For using in chats add the model answer to the next request.
    /// </summary>
    procedure AddAnswerForNextRequest(const ResultAsMarkDown: string);

    /// <summary>
    /// In chats after adding the last answer from the model the next question from the user can be added.
    /// </summary>
    procedure AddQuestionForNextRequest(const PromptText: string);

    /// <summary>
    /// Within a chat to calculated to number of tokens in the prompt this function allows get a working request.
    /// </summary>
    function CloneWithoutCfgAndSettings(Request: IGeminiAIRequest): IGeminiAIRequest;
  end;

  /// <summary>
  /// IGeminiAI defines an interface for interacting with a Gemini AI model.
  /// </summary>
  IGeminiAI = interface(IInterface)
    /// <summary>
    /// Allows changing the API Version after creation of the class.
    /// </summary>
    procedure SetAPIVersion(APIVersion: TGeminiAPIVersion);

    /// <summary>
    /// Fetch list of model names accessible in Gemini AI. Use this blocking function not in the main thread of a GUI
    /// application but in threads, services or console applications.
    /// </summary>
    procedure FetchListOfModelsSynchronous(ModelNames: TStrings);

    /// <summary>
    /// Fetch list of model names accessible in Gemini AI. Use this none blocking function in the main thread of a GUI
    /// application.
    /// </summary>
    /// <param name="OnFetchModels">Call back method of the following signature:
    /// procedure(Models: TStrings; const ErrorMsg: string) of object.
    /// </param>
    procedure FetchListOfModels(OnFetchModels: TOnGeminiFetchModels);

    /// <summary>
    /// Returns model details for a Gemini model. If data is already fetched from the webservices returns cached 
	/// value otherwise start a request on webservices. Use this blocking function not in the main thread of a GUI
    /// application but in threads, services or console applications.
    /// </summary>
    /// <param name="ModelName">The name of the model (without "models/" of the full model name).
    /// </param>
    /// <returns>TGeminiModelDetails: Contains all detail information about a model.
    /// </returns>
    function FetchModelDetailsSynchronous(const ModelName: string): TGeminiModelDetails;

    /// <summary>
    /// Returns model details for a Gemini model. If data is already fetched from the webservices returns cached 
	/// value otherwise start a request on webservices. Use this none blocking function in the main thread of a GUI 
	/// application.
    /// </summary>
    /// <param name="ModelName">The name of the model (without "models/" of the full model name).
    /// </param>
    /// <param name="OnFetchModelDetail">Call back method of the following signature:
    /// procedure(Detail: TGeminiModelDetails; const ErrorMsg: string) of object.
    /// </param>
    procedure FetchModelDetails(const ModelName: string; OnFetchModelDetail: TOnGeminiFetchModel);

    /// <summary>
    /// Set name of model for upcomming request
    /// </summary>
    procedure SetModel(const ModelName: string);

    /// <summary>
    /// GenerateContentByPromptSynchronous generates text content as a response based on the provided simple
    /// text prompt containing the question. Use this blocking function not in the main thread of a GUI
    /// application but in threads, services or console applications.
    /// </summary>
    /// <param name="Prompt">The text prompt to generate content from.
    /// </param>
    /// <returns>IGeminiAIResponse: An interface representing the AI's response.
    /// </returns>
    function GenerateContentByPromptSynchronous(const Prompt: string): IGeminiAIResponse;

    /// <summary>
    /// GenerateContentbyPrompt generates content asynchronously based on the provided simple text prompt.
    /// Use this none blocking function in the main thread of a GUI application.
    /// </summary>
    /// <param name="Prompt">The text prompt to generate content from.
    /// </param>
    /// <param name="OnRespone">A callback function to invoke when the response is ready.
    /// </param>
    procedure GenerateContentbyPrompt(const Prompt: string;
      OnRespone: TOnGeminiGenContent);

    /// <summary>
    /// GenerateContentByRequestSynchronous generates content based on the provided IGeminiAIRequest.
    /// Use this blocking function not in the main thread of a GUI application but in threads, services
    /// or console applications.
    /// </summary>
    /// <param name="GeminiAIRequest">An interface of IGeminiAIRequest for using complex
    /// prompts with model parameters, media files and model answers in chat applications.
    /// </param>
    /// <returns>IGeminiAIResponse: An interface representing the AI's response.
    /// </returns>
    function GenerateContentByRequestSynchronous(GeminiAIRequest: IGeminiAIRequest): IGeminiAIResponse;

    /// <summary>
    /// GenerateContentByRequest generates content asynchronously based on the provided IGeminiAIRequest.
    /// Use this none blocking function in the main thread of a GUI applications.
    /// </summary>
    /// <param name="GeminiAIRequest">An interface of IGeminiAIRequest for using complex
    /// prompts with model parameters, media files and model answers in chat applications.
    /// </param>
    /// <param name="OnRespone">A callback function to invoke when the response is ready.
    /// </param>
    procedure GenerateContentByRequest(GeminiAIRequest: IGeminiAIRequest;
      OnRespone: TOnGeminiGenContent);

    /// <summary>
    /// CountTokenOfPrompt asynchronously counts the number of tokens in the given simple text prompt.
    /// Use this none blocking function in the main thread of a GUI applications.
    /// </summary>
    /// <param name="Prompt">The text prompt to count tokens in.
    /// </param>
    /// <param name="OnResponse">A callback function to invoke with the token count.
    /// </param>
    procedure CountTokenOfPrompt(const Prompt: string; OnResponse: TOnGeminiCountToken);

    /// <summary>
    /// CountTokenOfRequestSynchronous synchronously counts the number of tokens in the given simple text prompt.
    /// Use this blocking function not in the main thread of a GUI application but in threads, services
    /// or console applications.
    /// </summary>
    /// <param name="Prompt">The text prompt to count tokens in.
    /// </param>
    /// <param name="ErrorMsg">Returns an error reason in case of an error.
    /// </param>
    /// <param name="CachedContentToken">An output parameter for the cached token count.
    /// When not using cached content 0 will be returned.</param>
    /// <returns>The number of tokens in the prompt.
    /// </returns>
    function CountTokenOfPromptSynchronous(const Prompt: string; out ErrorMsg: string;
      out CachedContentToken: integer): integer;

    /// <summary>
    /// CountTokenOfPrompt asynchronously counts the number of tokens in the given complex prompt.
    /// Use this none blocking function in the main thread of a GUI applications.
    /// </summary>
    /// <param name="GeminiAIRequest">An interface of IGeminiAIRequest with the complex prompt.
    /// </param>
    /// <param name="OnResponse">A callback function to invoke with the token count.
    /// </param>
    procedure CountTokenOfRequest(GeminiAIRequest: IGeminiAIRequest; OnResponse: TOnGeminiCountToken);

    /// <summary>
    /// Use this blocking function not in the main thread of a GUI application but in threads, services
    /// or console applications.
    /// </summary>
    /// <param name="GeminiAIRequest">An interface of IGeminiAIRequest with the complex prompt.
    /// </param>
    /// <param name="ErrorMsg">Returns an error reason in case of an error.
    /// </param>
    /// <param name="CachedContentToken">An output parameter for the cached token count.
    /// When not using cached content 0 will be returned.</param>
    /// <returns>The number of tokens in the prompt.
    /// </returns>
    function CountTokenOfRequestSynchronous(GeminiAIRequest: IGeminiAIRequest; out ErrorMsg: string;
      out CachedContentToken: integer): integer;
  end;
  {$ENDREGION}

  {$REGION 'Class factory for getting Firebase Services'}

  /// <summary>
  /// Exception class for Firebase configuration interface
  /// </summary>
  EFirebaseConfiguration = class(Exception);

  /// <summary>
  /// The interface IFirebaseConfiguration provides a class factory for
  /// accessing all interfaces to the Firebase services.
  /// </summary>
  /// <remarks>
  /// The interface will be created by the constructors of the class
  /// TFirebaseConfiguration in the unit FB4D.Configuration.
  /// The first constructor requires all secrets of the Firebase project
  /// such as ApiKey and Project ID and when using the Storage also the
  /// storage Bucket.
  /// The second constructor variant parses the google-services.json file that
  /// shall be loaded from the Firebase Console after adding an App in the
  /// project settings.
  /// </remarks>
  IFirebaseConfiguration = interface(IInterface)
    /// <summary>
    /// Returns the Firebase project ID.
    /// </summary>
    function ProjectID: string;

    /// <summary>
    /// Returns the IFirebaseAuthentication interface for managing user authentication.
    /// </summary>
    function Auth: IFirebaseAuthentication;

    /// <summary>
    /// Returns the IRealTimeDB interface for interacting with the Firebase Realtime Database.
    /// </summary>
    function RealTimeDB: IRealTimeDB;

    /// <summary>
    /// Returns the IFirestoreDatabase interface for interacting with the Firebase Firestore database.
    /// </summary>
    /// <param name="DatabaseID">The ID of the Firestore database to use.
    /// Default is "(default)".</param>
    function Database(const DatabaseID: string = cDefaultDatabaseID): IFirestoreDatabase;

    /// <summary>
    /// Returns the IFirebaseStorage interface for interacting with Firebase Storage.
    /// </summary>
    function Storage: IFirebaseStorage;

    /// <summary>
    /// Sets the storage bucket to use.
    /// </summary>
    /// <param name="Bucket">The name of the storage bucket.</param>
    procedure SetBucket(const Bucket: string);

    /// <summary>
    /// Returns the IFirebaseFunctions interface for interacting with Firebase Cloud Functions.
    /// </summary>
    function Functions: IFirebaseFunctions;

    /// <summary>
    /// Returns the IVisionML interface for interacting with Firebase ML Vision APIs.
    /// </summary>
    function VisionML: IVisionML;

    /// <summary>
    /// Returns the IGeminiAI interface for interacting with Gemini AI APIs.
    /// </summary>
    function GeminiAI(const ApiKey: string; const Model: string = cGeminiAIDefaultModel;
      APIVersion: TGeminiAPIVersion = cDefaultGeminiAPIVersion): IGeminiAI;
  end;
  {$ENDREGION}

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

constructor TOnSuccess.CreateGeminiFetchModelDetail(OnGeminiFetchModelDetail: TOnGeminiFetchModel);
begin
  Create(nil);
  OnSuccessCase := oscGeminiFetchModelDetail;
  OnFetchModelDetail := OnGeminiFetchModelDetail;
end;

constructor TOnSuccess.CreateGeminiFetchModelNames(OnGeminiFetchModels: TOnGeminiFetchModels);
begin
  Create(nil);
  OnSuccessCase := oscGeminiFetchModelNames;
  OnFetchModels := OnGeminiFetchModels;
end;

constructor TOnSuccess.CreateGeminiGenerateContent(
  OnGeminiGenContent: TOnGeminiGenContent);
begin
  Create(nil);
  OnSuccessCase := oscGeminiGenContent;
  OnGenerateContent := OnGeminiGenContent;
end;

constructor TOnSuccess.CreateGeminiCountToken(OnGeminiCountToken: TOnGeminiCountToken);
begin
  Create(nil);
  OnSuccessCase := oscGeminiCountToken;
  OnCountToken := OnGeminiCountToken;
end;

{ TUsageMetaData }

procedure TGeminiAIUsageMetaData.Init;
begin
  PromptTokenCount := 0;
  GeneratedTokenCount := 0;
  TotalTokenCount := 0;
end;

{ TGeminiResult }

procedure TGeminiAIResult.Init;
var
  hc: THarmCategory;
begin
  FinishReason := TGeminiAIFinishReason.gfrUnknown;
  Index := 0;
  SetLength(PartText, 0);
  for hc := low(THarmCategory) to high(THarmCategory) do
    SafetyRatings[hc].Init;
  GroundingMetadata.Init;
end;

function TGeminiAIResult.ResultAsMarkDown: string;
var
  c: integer;
begin
  case length(PartText) of
    0: result := '';
    1: result := PartText[0];
    else begin
      for c := 0 to length(PartText) - 1 do
        result := result + '- ' + PartText[c] + sLineBreak;
    end;
  end;
end;

function TGeminiAIResult.FinishReasonAsStr: string;
begin
  case FinishReason of
    gfrUnknown:
      result := '?';
    gfrStop:
      result := 'Stop';
    gfrMaxToken:
      result := 'Max token';
    gfrSafety:
      result := 'Safty';
    gfrRecitation:
      result := 'Recitation';
    gfrOther:
      result := 'Other';
  end;
end;

{ TSafetyRating }

procedure TSafetyRating.Init;
begin
  Probability := psUnknown;
  ProbabilityScore := 0;
  Severity := psUnknown;
  SeverityScore := 0;
end;

function TSafetyRating.ProbabilityAsStr: string;
begin
  case Probability of
    psUnknown:
      result := '';
    psNEGLIGIBLE:
      result := 'negligible';
    psLOW:
      result := 'low';
    psMEDIUM:
      result := 'medium';
    psHIGH:
      result := 'high';
    else
      result := '?';
  end;
end;

function TSafetyRating.SeverityAsStr: string;
begin
  case Severity of
    psUnknown:
      result := '';
    psNEGLIGIBLE:
      result := 'negligible';
    psLOW:
      result := 'low';
    psMEDIUM:
      result := 'medium';
    psHIGH:
      result := 'high';
    else
      result := '?';
  end;

end;

{ TGroundingMetadata }

procedure TGroundingMetadata.Init;
begin
  ActiveGrounding := false;
  SetLength(Chunks, 0);
  SetLength(Support, 0);
  SetLength(WebSearchQuery, 0);
  RenderedContent := '';
  GoogleSearchDynamicRetrievalScore := 0;
end;

{ TGeminiModelDetails }

procedure TGeminiModelDetails.Init;
begin
  ModelFullName := '';
  BaseModelId := '';
  Version := '';
  DisplayName := '';
  Description := '';
  InputTokenLimit := 0;
  OutputTokenLimit := 0;
  SetLength(SupportedGenerationMethods, 0);
  Temperature := 0;
  MaxTemperature := 0;
  TopP := 0;
  TopK := 0;
end;

end.
