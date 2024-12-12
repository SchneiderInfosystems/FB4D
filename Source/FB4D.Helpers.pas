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

unit FB4D.Helpers;

interface

uses
  System.Classes, System.Types, System.SysUtils, System.StrUtils,
{$IFNDEF LINUX64}
  System.Sensors,
{$ENDIF}
  System.JSON, System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces;

type
  TOnSimpleDownloadError = procedure(const DownloadURL, ErrMsg: string) of
    object;
  TOnSimpleDownloadSuccess = procedure(const DownloadURL: string) of object;
  TOnLog = procedure(const Text: string) of object;

  EID64 = class(Exception);

  TFirebaseHelpers = class
    class var OnLog: TOnLog;
    // Time conversion functions
    class function CodeRFC3339DateTime(DateTimeStamp: TDateTime): string;
    class function DecodeRFC3339DateTime(DateTimeStamp: string): TDateTime;
    class function ConvertTimeStampToUTCDateTime(TimeStamp: Int64): TDateTime;
    class function ConvertRFC5322ToUTCDateTime(DateTime: string): TDateTime;
    class function ConvertRFC5322ToLocalDateTime(DateTime: string): TDateTime;
    class function ConvertTimeStampToLocalDateTime(Timestamp: Int64): TDateTime;
    class function ConvertToLocalDateTime(DateTimeStampUTC: TDateTime): TDateTime;
    class function ConvertToUTCDateTime(DateTimeStampLocal: TDateTime): TDateTime;
    // Query parameter helpers
    class function EncodeQueryParams(QueryParams: TQueryParams): string;
    class function EncodeQueryParamsWithToken(QueryParams: TQueryParams;
      const EncodedToken: string): string;
    // Request parameter helpers
    class function EncodeResourceParam(Param: string): string;
    class function EncodeResourceParams(Params: TRequestResourceParam): string;
    class function AddParamToResParams(Params: TRequestResourceParam;
      const Param: string): TRequestResourceParam;
    // Encode token for URL based token transmission
    class function EncodeToken(const Token: string): string;
    // Array of string helpers
    class function ArrStrToCommaStr(Arr: array of string): string;
    class function ArrStrToQuotedCommaStr(Arr: array of string): string;
    class function FirestorePath(const Path: string): TRequestResourceParam;
      deprecated 'Use TFirestorePath.ConvertToDocPath instead';
    // ID64 is based on charset cID64 (A..z,0..9,_-): Helpers and converter to GUID
    // PUSHID is based on same charset cPushID64 but supports chronological sorting
    type TIDKind = (FBID {random 22 ID64 chars},
                    PUSHID {timestamp and random: total 20 chars of PushID64},
                    FSID {random 20 ID64 chars},
                    FSPUSHID {timestamp and random: total 24 ID64 chars});
    class function CreateAutoID(IDKind: TIDKind = FBID): string;
    class function ConvertGUIDtoID64(Guid: TGuid): string;
    class function ConvertID64toGUID(const ID: string): TGuid;
    class function ConvertTimeStampAndRandomPatternToPUSHID(timestamp: TDateTime;
      RandomPattern: TBytes; TimeIsUTC: boolean = false): string;
    class function DecodeTimeStampFromPUSHID(const PUSHID: string;
      ConvertToLocalTime: boolean = true): TDateTime;
    class function ConvertTimeStampAndRandomPatternToID64(timestamp: TDateTime;
      RandomPattern: TBytes; TimeIsUTC: boolean = false): string;
    class function DecodeTimeStampFromBase64(const FSPUSHID: string;
      ConvertToLocalTime: boolean = true): TDateTime;
    class function DecodeID64ToBytes(const ID64: string): TBytes;
    class function EncodeBytesToID64(Bytes: TBytes): string;

    // File helpers
    class procedure SimpleDownload(const DownloadUrl: string; Stream: TStream;
      OnSuccess: TOnSimpleDownloadSuccess;
      OnError: TOnSimpleDownloadError = nil);
    class procedure SimpleDownloadSynchronous(const DownloadUrl: string;
      Stream: TStream);
    {$IF Defined(FMX) OR Defined(FGX)}
    class function ContentTypeToFileExt(const ContentType: string): string;
    class function ImageStreamToContentType(Stream: TStream): TRESTContentType;
    {$ENDIF}
    // Miscellaneous functions
    class function IsEMailAdress(const EMail: string): boolean;
    class function IsPasswordPolicyFulfilled(const Password: string; Policy: TPasswordPolicy = [];
      MinPasswordLength: integer = 6; MaxPasswordLength: integer = 4096): boolean;
    // Application helpers
    class procedure Log(msg: string);
    class procedure LogFmt(msg: string; const Args: array of const);
    class function AppIsTerminated: boolean;
    class procedure SleepAndMessageLoop(SleepInMs: cardinal);
    class function IsMainThread: boolean;
    class function GetConfigAndPlatform: string;
    class function GetPlatform: string;

    // ML helpers
    class function GetLanguageInEnglishFromCode(const Code: string): string;
  private const
    cID64 =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-';
    // Base64 with exception of the last two chars '_' and '-' are not real Base64
    // because '+' and '/' causes troubles in IDs
    cPushID64 =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
    // This notification is used in the Realtime DB for Post and Push operation
    class function GetID64Char(b: Byte): char;
    class function GetPushID(ch: Char): Integer; inline;
    class function GetID64(ch: Char): Integer; inline;
  end;

  TFirestorePath = class
    class function TrimStartAndEndPathDelimiters(const Path: string): string;
    class function ConvertToDocPath(const Path: string): TRequestResourceParam;
    class function GetDocPath(Params: TRequestResourceParam): string;
    class function ContainsPathDelim(const Path: string): boolean;
    class function ExtractLastCollection(const Path: string): string;
    class function DocPathWithoutLastCollection(
      const Path: string): TRequestResourceParam;
  end;

  TFirestoreMap = array of TJSONPair;
  TFirestoreArr = array of TJSONValue;
  TJSONHelpers = class helper for TJSONObject
    // String
    function GetStringValue: string; overload;
    function GetStringValue(const Name: string): string; overload;
    function GetStringValueDef(const Name: string;
      const Default: string = ''): string; overload;
    function GetStringValueDef(const Default: string = ''): string; overload;
    class function SetStringValue(const Val: string): TJSONObject;
    class function SetString(const VarName, Val: string): TJSONPair;
    // Integer
    function GetIntegerValue: integer; overload;
    function GetIntegerValue(const Name: string): integer; overload;
    function GetIntegerValueDef(const Name: string;
      Default: integer = 0): integer; overload;
    function GetIntegerValueDef(Default: integer = 0): integer; overload;
    function GetInt64Value: Int64; overload;
    function GetInt64Value(const Name: string): Int64; overload;
    function GetInt64ValueDef(Default: Int64 = 0): Int64; overload;
    function GetInt64ValueDef(const Name: string;
      Default: Int64 = 0): Int64; overload;
    class function SetIntegerValue(Val: integer): TJSONObject;
    class function SetInteger(const VarName: string; Val: integer): TJSONPair;
    class function SetInt64Value(Val: Int64): TJSONObject;
    class function SetInt64(const VarName: string; Val: Int64): TJSONPair;
    // Boolean
    function GetBooleanValue: boolean; overload;
    function GetBooleanValue(const Name: string): boolean; overload;
    function GetBooleanValueDef(const Name: string;
      Default: boolean = false): boolean; overload;
    function GetBooleanValueDef(Default: boolean = false): boolean; overload;
    class function SetBooleanValue(Val: boolean): TJSONObject;
    class function SetBoolean(const VarName: string; Val: boolean): TJSONPair;
    // Double
    function GetDoubleValue: double; overload;
    function GetDoubleValue(const Name: string): double; overload;
    function GetDoubleValueDef(const Name: string; Default: double = 0): double;
      overload;
    function GetDoubleValueDef(Default: double = 0): double;
      overload;
    class function SetDoubleValue(Val: double): TJSONObject;
    class function SetDouble(const VarName: string; Val: double): TJSONPair;
    // TimeStamp
    function GetTimeStampValue(TimeZone: TTimeZone = tzUTC): TDateTime; overload;
    function GetTimeStampValue(const Name: string;
      TimeZone: TTimeZone = tzUTC): TDateTime; overload;
    function GetTimeStampValueDef(const Name: string; Default: TDateTime = 0;
      TimeZone: TTimeZone = tzUTC): TDateTime; overload;
    function GetTimeStampValueDef(Default: TDateTime = 0;
      TimeZone: TTimeZone = tzUTC): TDateTime; overload;
    class function SetTimeStampValue(Val: TDateTime;
      TimeZone: FB4D.Interfaces.TTimeZone = tzUTC): TJSONObject;
    class function SetTimeStamp(const VarName: string;
      Val: TDateTime; TimeZone: FB4D.Interfaces.TTimeZone = tzUTC): TJSONPair;
    // Null
    class function SetNullValue: TJSONObject;
    class function SetNull(const VarName: string): TJSONPair;
    function IsNull: boolean;
    // Reference
    function GetReference: string; overload;
    function GetReference(const Name: string): string; overload;
    function GetReferenceDef(const Name: string;
      const Default: string = ''): string; overload;
    function GetReferenceDef(const Default: string = ''): string; overload;
    class function SetReferenceValue(const ProjectID, Ref: string;
      const Database: string = cDefaultDatabaseID): TJSONObject;
    class function SetReference(const Name, ProjectID, Ref: string): TJSONPair;
    // GeoPoint
    function GetGeoPoint: TLocationCoord2D; overload;
    function GetGeoPoint(const Name: string): TLocationCoord2D; overload;
    function GetGeoPointDef(const Name: string;
      Default: TLocationCoord2D): TLocationCoord2D; overload;
    function GetGeoPointDef(Default: TLocationCoord2D): TLocationCoord2D;
      overload;
    class function SetGeoPointValue(Val: TLocationCoord2D): TJSONObject;
    class function SetGeoPoint(const VarName: string;
      Val: TLocationCoord2D): TJSONPair;
    // Bytes
    function GetBytes: TBytes; overload;
    function GetBytes(const Name: string): TBytes; overload;
    class function SetBytesValue(Val: TBytes): TJSONObject;
    class function SetBytes(const VarName: string; Val: TBytes): TJSONPair;
    // Map
    function GetMapSize: integer; overload;
    function GetMapSize(const Name: string): integer; overload;
    function GetMapItem(Ind: integer): TJSONPair; overload;
    function GetMapItem(const Name: string): TJSONObject; overload;
    function GetMapItem(const Name: string; Ind: integer): TJSONPair; overload;
    function GetMapValue(const Name: string; Ind: integer): TJSONObject;
    function GetMapValues: TJSONObject;
    class function SetMapValue(MapVars: TFirestoreMap): TJSONObject;
    class function SetMap(const VarName: string;
      MapVars: TFirestoreMap): TJSONPair;
    // Array
    function GetArraySize: integer; overload;
    function GetArraySize(const Name: string): integer; overload;
    function GetArrayItem(Ind: integer): TJSONObject; overload;
    function GetArrayItem(const Name: string; Ind: integer): TJSONObject;
      overload;
    function GetArrayValues: TJSONObjects;
    function GetStringArray: TStringDynArray;
    class function SetArray(const VarName: string;
      FSArr: TFirestoreArr): TJSONPair;
    class function SetArrayValue(FSArr: TFirestoreArr): TJSONObject;
    class function SetStringArray(const VarName: string;
      Strings: TStringDynArray): TJSONPair; overload;
    class function SetStringArray(const VarName: string;
      Strings: TStringList): TJSONPair; overload;
    class function SetStringArray(const VarName: string;
      Strings: TList<string>): TJSONPair; overload;
  end;

  TQueryParamsHelper = class helper for TQueryParams
    class function CreateQueryParams(CheckThisInstanceFirst: TQueryParams =
      nil): TQueryParams;
    function AddOrderBy(const FieldName: string): TQueryParams;
    function AddOrderByType(const TypeName: string): TQueryParams;
    function AddLimitToFirst(LimitToFirst: integer): TQueryParams;
    function AddLimitToLast(LimitToLast: integer): TQueryParams;
    function AddOrderByAndEqualTo(const FieldName,
      FilterValue: string): TQueryParams; overload;
    function AddOrderByAndEqualTo(const FieldName: string;
      FilterValue: integer): TQueryParams; overload;
    function AddOrderByAndEqualTo(const FieldName: string;
      FilterValue: extended): TQueryParams; overload;
    function AddTransaction(
      Transaction: TFirestoreReadTransaction): TQueryParams;
    function AddPageSize(PageSize: integer): TQueryParams;
    function AddPageToken(const PageToken: string): TQueryParams;
  end;

  TSchemaItemsHelper = class helper for TSchemaItems
    class function CreateItem(const FieldName: string; Schema: IGeminiSchema): TPair<string, IGeminiSchema>;
  end;

resourcestring
  rsFBFailureIn = '%s Firebase failure in %s: %s';

implementation

uses
  System.Character,
{$IFDEF MSWINDOWS}
  WinAPI.Windows,
{$ENDIF}
{$IF Defined(CONSOLE)}
{$ELSEIF Defined(VCL)}
  VCL.Forms,
{$ELSEIF Defined(FMX)}
  FMX.Types, FMX.Forms, FMX.Graphics, FMX.Consts,
{$ELSEIF Defined(FGX)}
  FGX.Forms, FGX.Logs,
{$ELSE}
  FMX.Types, FMX.Forms,
{$ENDIF}
  System.DateUtils, System.NetEncoding, System.JSONConsts, System.Math,
  System.Net.HttpClient, System.Hash,
  IdGlobalProtocols;

resourcestring
  rsArrFieldNotJSONObj = 'Arrayfield[%d] does not contain a JSONObject';
  rsArrFieldNotTypeValue = 'Arrayfield[%d] does not contain type-value pair';
  rsArrayItemOutOfBounds = 'Array item %d out of bounds';
  rsInvalidArrayItem = 'Invalid array item %d';
  rsMapItemOutOfBounds = 'Map item %d out of bounds';

{ TFirestoreHelpers }

class function TFirebaseHelpers.CodeRFC3339DateTime(
  DateTimeStamp: TDateTime): string;
var
  UTC: TDateTime;
begin
  // Convert to UTC
  UTC := TTimeZone.Local.ToUniversalTime(DateTimeStamp);
  // Format RFC3339
  result := FormatDateTime('yyyy-mm-dd', UTC) + 'T' +
    FormatDateTime('hh:mm:ss.zzz', UTC) + 'Z';
end;

class function TFirebaseHelpers.DecodeRFC3339DateTime(
  DateTimeStamp: string): TDateTime;
begin
  result := ISO8601ToDate(DateTimeStamp, false); // To local time
end;

class function TFirebaseHelpers.ConvertRFC5322ToLocalDateTime(
  DateTime: string): TDateTime;
begin
  result := ConvertToLocalDateTime(ConvertRFC5322ToUTCDateTime(DateTime));
end;

class function TFirebaseHelpers.ConvertRFC5322ToUTCDateTime(
  DateTime: string): TDateTime;
begin
  result := StrInternetToDateTime(DateTime);
end;

class function TFirebaseHelpers.ConvertTimeStampToLocalDateTime(
  Timestamp: Int64): TDateTime;
begin
  result := ConvertToLocalDateTime(ConvertTimeStampToUTCDateTime(Timestamp));
end;

class function TFirebaseHelpers.ConvertTimeStampToUTCDateTime(
  TimeStamp: Int64): TDateTime;
begin
  result := UnixToDateTime(TimeStamp div 1000);
end;

class function TFirebaseHelpers.ConvertToLocalDateTime(
  DateTimeStampUTC: TDateTime): TDateTime;
begin
  result := TTimeZone.Local.ToLocalTime(DateTimeStampUTC);
end;

class function TFirebaseHelpers.ConvertToUTCDateTime(
  DateTimeStampLocal: TDateTime): TDateTime;
begin
  result := TTimeZone.Local.ToUniversalTime(DateTimeStampLocal);
end;

class function TFirebaseHelpers.EncodeQueryParams(
  QueryParams: TQueryParams): string;
var
  Param: TPair<string, TStringDynArray>;
  ParVal: string;
begin
  if (not assigned(QueryParams)) or not(QueryParams.Count > 0) then
    exit('');
  result := '?';
  for Param in QueryParams do
    for ParVal in Param.Value do
    begin
      if result <> '?' then
        result := result + '&';
      result := result + TNetEncoding.URL.Encode(Param.Key) + '=' +
        TNetEncoding.URL.Encode(ParVal);
    end;
end;

class function TFirebaseHelpers.EncodeQueryParamsWithToken(
  QueryParams: TQueryParams; const EncodedToken: string): string;
var
  Param: TPair<string, TStringDynArray>;
  ParVal: string;
begin
  result := '?auth=' + EncodedToken;
  if assigned(QueryParams) then
    for Param in QueryParams do
      for ParVal in Param.Value do
        result := result + '&' + TNetEncoding.URL.Encode(Param.Key) + '=' +
          TNetEncoding.URL.Encode(ParVal);
end;

class function TFirebaseHelpers.EncodeResourceParam(Param: string): string;
const
  PathUnsafeChars: TURLEncoding.TUnsafeChars =
    [Ord('"'), Ord('<'), Ord('>'), Ord('^'), Ord('`'), Ord('{'), Ord('}'),
     Ord('|'), Ord('/'), Ord('\'), Ord('?'), Ord('#'), Ord('+')];
  Option: TURLEncoding.TEncodeOptions =
    [TURLEncoding.TEncodeOption.SpacesAsPlus,
     TURLEncoding.TEncodeOption.EncodePercent];
begin
  result := TNetEncoding.URL.Encode(Param, PathUnsafeChars, Option);
end;

class function TFirebaseHelpers.EncodeResourceParams(
  Params: TRequestResourceParam): string;
var
  i: integer;
begin
  result := '';
  for i := low(Params) to high(Params) do
    result := result + '/' + EncodeResourceParam(Params[i]);
end;

class function TFirebaseHelpers.EncodeToken(const Token: string): string;
begin
  if Token.IsEmpty then
    result := ''
  else
    result := '?auth=' + TNetEncoding.URL.Encode(Token);
end;

class function TFirebaseHelpers.FirestorePath(
  const Path: string): TRequestResourceParam;
begin
  if Path.StartsWith('/') or Path.StartsWith('\') then
    result := Path.Substring(1).Split(['/', '\'])
  else
    result := Path.Split(['/', '\']);
end;

class function TFirebaseHelpers.ArrStrToCommaStr(Arr: array of string): string;
var
  i: integer;
begin
  result := '';
  for i := low(Arr) to high(Arr) do
    if i = low(Arr) then
      result := Arr[i]
    else
      result := result + ',' + Arr[i];
end;

class function TFirebaseHelpers.ArrStrToQuotedCommaStr(
  Arr: array of string): string;

  function DoubleQuotedStr(const S: string): string;
  var
    i: integer;
  begin
    result := S;
    for i := result.Length - 1 downto 0 do
      if result.Chars[i] = '"' then
        result := result.Insert(i, '"');
    result := '"' + result + '"';
  end;

var
  i: integer;
begin
  result := '';
  for i := low(Arr) to high(Arr) do
    if i = low(Arr) then
      result := DoubleQuotedStr(Arr[i])
    else
      result := result + ',' + DoubleQuotedStr(Arr[i]);
end;

class procedure TFirebaseHelpers.Log(msg: string);
begin
  if AppIsTerminated then
    exit;
{$IF Defined(FMX)}
  {$IF Defined(LINUX) and (CompilerVersion < 35)}
  writeln(msg);  // Workaround for RSP-32303
  {$ELSE}
  FMX.Types.Log.d(msg, []);
  // there is a bug in DE 10.2 when the wrong method is calling?
  {$ENDIF}
{$ELSEIF Defined(FGX)}
  TfgLog.Debug(msg);
{$ELSEIF Defined(VCL)}
  OutputDebugString(PChar(msg));
{$ELSEIF Defined(MSWINDOWS)}
  OutputDebugString(PChar(msg));
{$ELSEIF Defined(CONSOLE)}
  writeln(msg);
{$ENDIF}
  if Assigned(OnLog) then
    OnLog(msg);
end;

class procedure TFirebaseHelpers.LogFmt(msg: string; const Args: array of const);
begin
  Log(Format(msg, args));
end;

class function TFirebaseHelpers.AddParamToResParams(
  Params: TRequestResourceParam; const Param: string): TRequestResourceParam;
var
  c: integer;
begin
  SetLength(result, length(Params) + 1);
  for c := low(Params) to high(Params) do
    result[c] := Params[c];
  result[length(Params)] := Param;
end;

class function TFirebaseHelpers.AppIsTerminated: boolean;
begin
{$IF Defined(VCL) OR Defined(FMX)}
  result := Application.Terminated;
{$ELSE}
  result := false;
{$ENDIF}
end;

class procedure TFirebaseHelpers.SleepAndMessageLoop(SleepInMs: cardinal);
begin
{$IF Defined(VCL) OR Defined(FMX)}
  Application.ProcessMessages;
{$ENDIF}
  Sleep(SleepInMs);
end;

class procedure TFirebaseHelpers.SimpleDownload(const DownloadUrl: string;
  Stream: TStream; OnSuccess: TOnSimpleDownloadSuccess;
  OnError: TOnSimpleDownloadError);
var
  ErrMsg: string;
begin
  TThread.CreateAnonymousThread(
    procedure
    var
      Client: THTTPClient;
      Response: IHTTPResponse;
    begin
      Client := THTTPClient.Create;
      try
        try
          Response := Client.Get(DownloadUrl, Stream);
          if Response.StatusCode = 200 then
          begin
            if assigned(OnSuccess) then
              TThread.Queue(nil,
                procedure
                begin
                  OnSuccess(DownloadUrl);
                end);
          end else begin
            {$IFDEF DEBUG}
            TFirebaseHelpers.Log(Response.ContentAsString);
            {$ENDIF}
            if assigned(OnError) then
              TThread.Queue(nil,
                procedure
                begin
                  OnError(DownloadUrl, Response.StatusText);
                end);
          end;
        except
          on e: exception do
            if assigned(OnError) then
            begin
              ErrMsg := e.Message;
              TThread.Queue(nil,
                procedure
                begin
                  OnError(DownloadUrl, ErrMsg);
                end)
            end else
              TFirebaseHelpers.LogFmt(rsFBFailureIn,
                ['FirebaseHelpers.SimpleDownload', DownloadUrl, e.Message]);
        end;
      finally
        Client.Free;
      end;
    end).Start;
end;

class procedure TFirebaseHelpers.SimpleDownloadSynchronous(
  const DownloadUrl: string; Stream: TStream);
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
      raise EFirebaseResponse.Create(Response.StatusText);
    end;
  finally
    Client.Free;
  end;
end;

class function TFirebaseHelpers.CreateAutoID(IDKind: TIDKind = FBID): string;

  function ShortenID64To20Chars(const ID: string): string;
  begin
    result := ID;
    if result.Length > 20 then
      result := result.Substring(0, 20);
  end;

begin
  // use OS to generate a safe random number
  case IDKind of
    FBID:
      result := ConvertGUIDtoID64(TGuid.NewGuid);
    FSID:
      result := ShortenID64To20Chars(ConvertGUIDtoID64(TGuid.NewGuid));
    PUSHID:
      result := ConvertTimeStampAndRandomPatternToPUSHID(now,
        copy(THashMD5.GetHashBytes(GuidToString(TGUID.NewGuid)), 1, 12));
    FSPUSHID:
      result := ConvertTimeStampAndRandomPatternToID64(now,
        copy(THashSHA1.GetHashBytes(GuidToString(TGUID.NewGuid)), 1, 16));
  end;
end;

class function TFirebaseHelpers.ConvertGUIDtoID64(Guid: TGuid): string;
var
  D1: cardinal;
  D2, D3: Word;
begin
  SetLength(result, 22);
  D1 := Guid.D1;
  result[1] := GetID64Char(D1 and $FF);
  D1 := D1 shr 6;
  result[2] := GetID64Char(D1 and $FF);
  D1 := D1 shr 6;
  result[3] := GetID64Char(D1 and $FF);
  D1 := D1 shr 6;
  result[4] := GetID64Char(D1 and $FF);
  D1 := D1 shr 6;
  result[5] := GetID64Char(D1 and $FF);
  D2 := Guid.D2;
  result[6] := GetID64Char(D2 and $FF);
  D2 := D2 shr 6;
  result[7] := GetID64Char(D2 and $FF);
  D2 := D2 shr 6;
  result[8] := GetID64Char(D2 and $F + (D1 and $C0) shr 2);
  D3 := Guid.D3;
  result[9] := GetID64Char(D3 and $FF);
  D3 := D3 shr 6;
  result[10] := GetID64Char(D3 and $FF);
  D3 := D3 shr 6;
  result[11] := GetID64Char(D3 and $F + (Guid.D4[0] and $C0) shr 2);
  result[12] := GetID64Char(Guid.D4[0]);
  result[13] := GetID64Char(Guid.D4[1]);
  result[14] := GetID64Char(Guid.D4[2]);
  result[15] := GetID64Char(Guid.D4[3]);
  result[16] := GetID64Char(Guid.D4[4]);
  result[17] := GetID64Char(Guid.D4[5]);
  result[18] := GetID64Char(Guid.D4[6]);
  result[19] := GetID64Char(Guid.D4[7]);
  result[20] := GetID64Char((Guid.D4[1] and $C0) shr 6 +
    (Guid.D4[2] and $C0) shr 4 + (Guid.D4[3] and $C0) shr 2);
  result[21] := GetID64Char((Guid.D4[4] and $C0) shr 6 +
    (Guid.D4[5] and $C0) shr 4 + (Guid.D4[6] and $C0) shr 2);
  result[22] := GetID64Char((Guid.D4[7] and $C0) shr 6);
end;

class function TFirebaseHelpers.ConvertID64toGUID(const ID: string): TGuid;
var
  c: integer;
  ID64: array[1..22] of byte;
begin
  for c := low(ID64) to high(ID64) do
    ID64[c] := 0; // Zero for ID that are shorter than 22
  for c := 1 to max(length(ID), high(ID64)) do
    ID64[c] := GetID64(ID[c]);
  result.D1 := ID64[1] + ID64[2] shl 6 + ID64[3] shl 12 +
    ID64[4] shl 18 + ID64[5] shl 24 + (ID64[8] and $30) shl 26;
  result.D2 := ID64[6] + ID64[7] shl 6 + (ID64[8] and $F) shl 12;
  result.D3 := ID64[9] + ID64[10] shl 6 + (ID64[11] and $F) shl 12;
  result.D4[0] := ID64[12] + (ID64[11] and $30) shl 2;
  result.D4[1] := ID64[13] + (ID64[20] and $03) shl 6;
  result.D4[2] := ID64[14] + (ID64[20] and $0C) shl 4;
  result.D4[3] := ID64[15] + (ID64[20] and $30) shl 2;
  result.D4[4] := ID64[16] + (ID64[21] and $03) shl 6;
  result.D4[5] := ID64[17] + (ID64[21] and $0C) shl 4;
  result.D4[6] := ID64[18] + (ID64[21] and $30) shl 2;
  result.D4[7] := ID64[19] + (ID64[22] and $03) shl 6;
end;

class function TFirebaseHelpers.ConvertTimeStampAndRandomPatternToPUSHID(
  timestamp: TDateTime; RandomPattern: TBytes; TimeIsUTC: boolean): string;
var
  tsi: int64;
  c: integer;
begin
  Assert(length(RandomPattern) >= 12, 'Too short random pattern');
  tsi := System.DateUtils.DateTimeToUnix(timestamp, TimeIsUTC) * 1000 +
    System.DateUtils.MilliSecondOf(timestamp);
  result := '';
  for c := 1 to 8 do
  begin
    result := cPushID64[(tsi mod 64) + low(cPushID64)] + result;
    tsi := tsi shr 6;
  end;
  for c := 0 to length(RandomPattern) - 1 do
    result := result + cPushID64[RandomPattern[c] and $3F + low(cPushID64)];
end;

class function TFirebaseHelpers.GetPushID(ch: Char): Integer;
begin
  result := pos(ch, cPushID64);
  if result < 0 then
    raise EID64.Create('Invalid PushID character: ' + ch);
  if low(cPushID64) > 0 then
    dec(result, low(cPushID64));
end;

class function TFirebaseHelpers.GetID64(ch: Char): Integer;
begin
  result := pos(ch, cID64);
  if result < 0 then
    raise EID64.Create('Invalid ID64 character: ' + ch);
  if low(cID64) > 0 then
    dec(result, low(cID64));
end;

class function TFirebaseHelpers.GetID64Char(b: Byte): char;
begin
  result := cID64[low(cID64) + b and $3F];
end;

class function TFirebaseHelpers.DecodeTimeStampFromPUSHID(
  const PUSHID: string; ConvertToLocalTime: boolean): TDateTime;
var
  tsi: int64;
  c: integer;
begin
  Assert(length(PUSHID) = 20, 'Invalid PUSHID length');
  tsi := 0;
  for c := low(PUSHID) to low(PUSHID) + 7 do
    tsi := tsi shl 6 + GetPushID(PUSHID[c]);
  result := UnixToDateTime(tsi div 1000);
  if ConvertToLocalTime then
    result := TTimeZone.Local.ToLocalTime(result);
  result := result + (tsi mod 1000) / 24 / 3600 / 1000;
end;

class function TFirebaseHelpers.ConvertTimeStampAndRandomPatternToID64(
  timestamp: TDateTime; RandomPattern: TBytes; TimeIsUTC: boolean): string;
var
  tsi: int64;
  c: integer;
begin
  Assert(length(RandomPattern) >= 12, 'Too short random pattern');
  tsi := System.DateUtils.DateTimeToUnix(timestamp, TimeIsUTC) * 1000 +
    System.DateUtils.MilliSecondOf(timestamp);
  result := '';
  for c := 1 to 8 do
  begin
    result := cID64[(tsi mod 64) + low(cID64)] + result;
    tsi := tsi shr 6;
  end;
  for c := 0 to length(RandomPattern) - 1 do
    result := result + cID64[RandomPattern[c] and $3F + low(cID64)];
end;

class function TFirebaseHelpers.DecodeTimeStampFromBase64(const FSPUSHID: string;
  ConvertToLocalTime: boolean): TDateTime;
var
  tsi: int64;
  c: integer;
begin
  Assert(length(FSPUSHID) = 24, 'Invalid PUSHID length');
  tsi := 0;
  for c := low(FSPUSHID) to low(FSPUSHID) + 7 do
    tsi := tsi shl 6 + GetID64(FSPUSHID[c]);
  result := UnixToDateTime(tsi div 1000);
  if ConvertToLocalTime then
    result := TTimeZone.Local.ToLocalTime(result);
  result := result + (tsi mod 1000) / 24 / 3600 / 1000;
end;

class function TFirebaseHelpers.DecodeID64ToBytes(const ID64: string): TBytes;
var
  b: Byte;
  c, d: integer;
begin
  SetLength(result, ceil(length(ID64) * 3 / 4)); // ceil rounds up
  d := 0;
  for c := Low(ID64) to High(ID64) do
  begin
    b := GetID64(ID64[c]);
    case (c - low(ID64)) mod 4 of
      0: begin
           result[d] := b shl 2;
         end;
      1: begin
           result[d] := result[d] + (b shr 4);
           inc(d);
           result[d] := (b and $F) shl 4;
         end;
      2: begin
           result[d] := result[d] + (b shr 2);
           inc(d);
           result[d] := (b and $3) shl 6;
         end;
      3: begin
           result[d] := result[d] + b;
           inc(d);
         end;
    end;
  end;
end;

class function TFirebaseHelpers.EncodeBytesToID64(Bytes: TBytes): string;
var
  c, rest: integer;
begin
  result := '';
  rest := 0;
  for c := 0 to length(Bytes) - 1 do
    case c mod 3 of
      0: begin
           result := result + GetID64Char(Bytes[c] shr 2);
           rest := (Bytes[c] and $3) shl 4;
         end;
      1: begin
           result := result + GetID64Char(rest + Bytes[c] shr 4);
           rest := (Bytes[c] and $F) shl 2;
         end;
      2: begin
           result := result + GetID64Char(rest + Bytes[c] shr 6) + GetID64Char(Bytes[c] and $3F);
           rest := 0;
         end;
    end;
  if rest > 0 then
    result := result + GetID64Char(rest);
end;

{$IF Defined(FMX) OR Defined(FGX)}
class function TFirebaseHelpers.ContentTypeToFileExt(
  const ContentType: string): string;

  {$IF CompilerVersion < 35} // Delphi 10.4 and before
  function SameText(const ContentType: string;
    AContentType: TRESTContentType): boolean;
  begin
    result := System.SysUtils.SameText(ContentType,
      ContentTypeToString(AContentType));
  end;
  {$ENDIF}

begin
  if SameText(ContentType, TRESTContentType.ctIMAGE_JPEG) then
    result := SJPGImageExtension
  else if SameText(ContentType, TRESTContentType.ctIMAGE_GIF) then
    result := SGIFImageExtension
  else if SameText(ContentType, TRESTContentType.ctIMAGE_PNG) then
    result := SPNGImageExtension
  else if SameText(ContentType, TRESTContentType.ctIMAGE_TIFF) then
    result := STIFFImageExtension
  else if SameText(ContentType, TRESTContentType.ctIMAGE_SVG_XML) or
          SameText(ContentType, TRESTContentType.ctAPPLICATION_XML) or
          SameText(ContentType, TRESTContentType.ctTEXT_XML) then
    result := '.xml'
  else if SameText(ContentType, TRESTContentType.ctAPPLICATION_JSON) then
    result := '.json'
  else if SameText(ContentType, TRESTContentType.ctAPPLICATION_PDF) then
    result := '.pdf'
  else if SameText(ContentType, TRESTContentType.ctAPPLICATION_ZIP) then
    result := '.zip'
  else if SameText(ContentType, TRESTContentType.ctTEXT_HTML) then
    result := '.htm'
  else if SameText(ContentType, TRESTContentType.ctTEXT_CSS) then
    result := '.css'
  else if SameText(ContentType, TRESTContentType.ctTEXT_JAVASCRIPT) or
          SameText(ContentType, TRESTContentType.ctAPPLICATION_JAVASCRIPT)then
    result := '.js'
  else if SameText(ContentType, TRESTContentType.ctTEXT_PLAIN) then
    result := '.txt'
  else if SameText(ContentType, TRESTContentType.ctTEXT_CSV) then
    result := '.csv'
  else if SameText(ContentType, TRESTContentType.ctTEXT_X_MARKDOWN) then
    result := '.md'
  else
    result := '';
end;

class function TFirebaseHelpers.ImageStreamToContentType(
  Stream: TStream): TRESTContentType;
var
  ImgType: string;
begin
  ImgType := TImageTypeChecker.GetType(Stream);
  if ImgType = SJPGImageExtension then
    result := TRESTContentType.ctIMAGE_JPEG
  else if ImgType = SGIFImageExtension then
    result := TRESTContentType.ctIMAGE_GIF
  else if ImgType = SPNGImageExtension then
    result := TRESTContentType.ctIMAGE_PNG
  else if ImgType = STIFFImageExtension then
    result := TRESTContentType.ctIMAGE_TIFF
  else // if ImgType = SBMPImageExtension then
    // Unsupported image type!
    {$IF CompilerVersion < 35} // Delphi 10.4 and before
    result := ctNone;
    {$ELSE}
    result := '';
    {$ENDIF}
end;
{$ENDIF}

class function TFirebaseHelpers.IsEMailAdress(const EMail: string): boolean;
// Returns True if the email address is valid
// Inspired by Ernesto D'Spirito

   function IsAtomChars(c: Char): boolean;
   begin
     result := (c >= #33) and (c <= #255) and not c.IsInArray(
       ['(', ')', '<', '>', '@', ',', ';', ':', '\', '/', '"', '.',
       '[', ']', #127]);
   end;

   function IsQuotedStringChars(c: Char): boolean;
   begin
     result := (c < #255) and not c.IsInArray(['"', #13, '\']);
   end;

type
  States = (stBegin, stAtom, stQText, st_QChar, stQuote, stLocalPeriod,
    stExpectingSubDomain, stSubDomain, stHyphen);
var
  State: States;
  i, subdomains: integer;
  c: char;
begin
  State := stBegin;
  subdomains := 1;
  for i := low(email) to high(email) do
  begin
    c := email[i];
    case State of
      stBegin:
        if IsAtomChars(c) then
          State := stAtom
        else if c = '"' then
          State := stQText
        else
          exit(false);
      stAtom:
        if c = '@' then
          State := stExpectingSubDomain
        else if c = '.' then
          State := stLocalPeriod
        else if not IsAtomChars(c) then
          exit(false);
      stQText:
        if c = '\' then
          State := st_QChar
        else if c = '"' then
          State := stQuote
        else if not IsQuotedStringChars(c) then
          exit(false);
      st_QChar:
        State := stQText;
      stQuote:
        if c = '@' then
          State := stExpectingSubDomain
        else if c = '.' then
          State := stLocalPeriod
        else
          exit(false);
      stLocalPeriod:
        if  IsAtomChars(c) then
          State := stAtom
        else if c = '"' then
          State := stQText
        else
          exit(false);
      stExpectingSubDomain:
        if c.IsLetter then
          State := stSubDomain
        else
          exit(false);
      stSubDomain:
        if c = '.' then begin
          inc(subdomains);
          State := stExpectingSubDomain
        end else if c = '-' then
          State := stHyphen
        else if not c.IsLetterOrDigit then
          exit((i = high(email)) and (subdomains >= 2));
      stHyphen:
        if c.IsLetterOrDigit then
          State := stSubDomain
        else if c <> '-' then
          exit(false);
    end;
  end;
  result := (State = stSubDomain) and (subdomains >= 2);
end;

class function TFirebaseHelpers.IsPasswordPolicyFulfilled(const Password: string;
  Policy: TPasswordPolicy; MinPasswordLength, MaxPasswordLength: integer): boolean;
const
  SpecChars = ['^', '$', '*', '.', '[', ']', '{', '}', '(', ')', '?', '"', '!',
    '@', '#', '%', '&', '/', '\', ',', '>', '<', '''', ':', ';', '|', '_', '~'];
var
  UC, LC, SC, NC: boolean;
  Ch: Char;
begin
  result := (Password.Length >= MinPasswordLength) and
    (Password.Length <= MaxPasswordLength);
  UC := false;
  LC := false;
  SC := false;
  NC := false;
  for ch in Password do
    if ch.IsDigit then
      NC := true
    else if ch.IsLower then
      LC := true
    else if ch.IsUpper then
      UC := true
    else if CharInSet(Ch, SpecChars) then
      SC := true;
  if (RequireUpperCase in Policy) and not UC then
    result := false;
  if (RequireLowerCase in Policy) and not LC then
    result := false;
  if (RequireSpecialChar in Policy) and not SC then
    result := false;
  if (RequireNumericChar in Policy) and not NC then
    result := false;
end;

class function TFirebaseHelpers.IsMainThread: boolean;
begin
  result := TThread.Current.ThreadID = System.MainThreadID;
end;

class function TFirebaseHelpers.GetPlatform: string;
begin
{$IF defined(WIN32)}
  result := 'Win32';
{$ELSEIF defined(WIN64)}
  result := 'Win64';
{$ELSEIF defined(MACOS32)}
  result := 'Mac32';
{$ELSEIF defined(MACOS64)}
  result := 'Mac64';
{$ELSEIF defined(IOS32)}
  result := 'iOS32';
{$ELSEIF defined(IOS64)}
  result := 'iOS64';
{$ELSEIF defined(ANDROID32)}
  result := 'Android32';
{$ELSEIF defined(ANDROID64)}
  result := 'Android64';
{$ELSEIF defined(LINUX32)}
  result := 'Linux32';
{$ELSEIF defined(Linux64)}
  result := 'Linux64';
{$ELSE}
  result := 'Platform?';
{$ENDIF}
end;

class function TFirebaseHelpers.GetConfigAndPlatform: string;
begin
{$IF defined(RELEASE)}
  result := 'Release Build/';
{$ELSEIF defined(DEBUG)}
  result := 'Debug Build/';
{$ELSE}
  result := 'Unknown Build/';
{$ENDIF}
  result := result + GetPlatform;
end;

class function TFirebaseHelpers.GetLanguageInEnglishFromCode(
  const Code: string): string;
begin
  if SameText(Code, 'af') then
    result := 'Afrikaans'
  else if SameText(Code, 'am') then
    result := 'Amharic'
  else if SameText(Code, 'ar') then
    result := 'Arabic'
  else if SameText(Code, 'arn') then
    result := 'Mapudungun'
  else if SameText(Code, 'as') then
    result := 'Assamese'
  else if SameText(Code, 'az') then
    result := 'Azeri'
  else if SameText(Code, 'ba') then
    result := 'Bashkir'
  else if SameText(Code, 'be') then
    result := 'Belarusian'
  else if SameText(Code, 'bg') then
    result := 'Bulgarian'
  else if SameText(Code, 'bn') then
    result := 'Bengali'
  else if SameText(Code, 'bo') then
    result := 'Tibetan'
  else if SameText(Code, 'br') then
    result := 'Breton'
  else if SameText(Code, 'bs') then
    result := 'Bosnian'
  else if SameText(Code, 'ca') then
    result := 'Catalan'
  else if SameText(Code, 'co') then
    result := 'Corsican'
  else if SameText(Code, 'cs') then
    result := 'Czech'
  else if SameText(Code, 'cy') then
    result := 'Welsh'
  else if SameText(Code, 'da') then
    result := 'Danish'
  else if SameText(Code, 'de') then
    result := 'German'
  else if SameText(Code, 'dsb') then
    result := 'Lower Sorbian'
  else if SameText(Code, 'dv') then
    result := 'Divehi'
  else if SameText(Code, 'el') then
    result := 'Greek'
  else if SameText(Code, 'en') then
    result := 'English'
  else if SameText(Code, 'es') then
    result := 'Spanish'
  else if SameText(Code, 'et') then
    result := 'Estonian'
  else if SameText(Code, 'eu') then
    result := 'Basque'
  else if SameText(Code, 'fa') then
    result := 'Persian'
  else if SameText(Code, 'fi') then
    result := 'Finnish'
  else if SameText(Code, 'fil') then
    result := 'Filipino'
  else if SameText(Code, 'fo') then
    result := 'Faroese'
  else if SameText(Code, 'fr') then
    result := 'French'
  else if SameText(Code, 'fy') then
    result := 'Frisian'
  else if SameText(Code, 'ga') then
    result := 'Irish'
  else if SameText(Code, 'gd') then
    result := 'Scottish Gaelic'
  else if SameText(Code, 'gl') then
    result := 'Galician'
  else if SameText(Code, 'gsw') then
    result := 'Alsatian'
  else if SameText(Code, 'gu') then
    result := 'Gujarati'
  else if SameText(Code, 'ha') then
    result := 'Hausa'
  else if SameText(Code, 'he') then
    result := 'Hebrew'
  else if SameText(Code, 'hi') then
    result := 'Hindi'
  else if SameText(Code, 'hr') then
    result := 'Croatian'
  else if SameText(Code, 'hsb') then
    result := 'Upper Sorbian'
  else if SameText(Code, 'hu') then
    result := 'Hungarian'
  else if SameText(Code, 'hy') then
    result := 'Armenian'
  else if SameText(Code, 'id') then
    result := 'Indonesian'
  else if SameText(Code, 'ig') then
    result := 'Igbo'
  else if SameText(Code, 'ii') then
    result := 'Yi'
  else if SameText(Code, 'is') then
    result := 'Icelandic'
  else if SameText(Code, 'it') then
    result := 'Italian'
  else if SameText(Code, 'iu') then
    result := 'Inuktitut'
  else if SameText(Code, 'ja') then
    result := 'Japanese'
  else if SameText(Code, 'ka') then
    result := 'Georgian'
  else if SameText(Code, 'kk') then
    result := 'Kazakh'
  else if SameText(Code, 'kl') then
    result := 'Greenlandic'
  else if SameText(Code, 'km') then
    result := 'Khmer'
  else if SameText(Code, 'kn') then
    result := 'Kannada'
  else if SameText(Code, 'ko') then
    result := 'Korean'
  else if SameText(Code, 'kok') then
    result := 'Konkani'
  else if SameText(Code, 'ky') then
    result := 'Kyrgyz'
  else if SameText(Code, 'la') then
    result := 'Latin'
  else if SameText(Code, 'lb') then
    result := 'Luxembourgish'
  else if SameText(Code, 'li') then
    result := 'Limburgan'
  else if SameText(Code, 'lo') then
    result := 'Lao'
  else if SameText(Code, 'ln') then
    result := 'Lingala'
  else if SameText(Code, 'lt') then
    result := 'Lithuanian'
  else if SameText(Code, 'lu') then
    result := 'Luba-Katanga'
  else if SameText(Code, 'lv') then
    result := 'Latvian'
  else if SameText(Code, 'mi') then
    result := 'Maori'
  else if SameText(Code, 'mk') then
    result := 'Macedonian'
  else if SameText(Code, 'ml') then
    result := 'Malayalam'
  else if SameText(Code, 'mn') then
    result := 'Mongolian'
  else if SameText(Code, 'moh') then
    result := 'Mohawk'
  else if SameText(Code, 'mr') then
    result := 'Marathi'
  else if SameText(Code, 'ms') then
    result := 'Malay'
  else if SameText(Code, 'mt') then
    result := 'Maltese'
  else if SameText(Code, 'my') then
    result := 'Burmese'
  else if SameText(Code, 'nb') then
    result := 'Norwegian (Bokmål)'
  else if SameText(Code, 'ne') then
    result := 'Nepali'
  else if SameText(Code, 'nl') then
    result := 'Dutch'
  else if SameText(Code, 'nn') then
    result := 'Norwegian (Nynorsk)'
  else if SameText(Code, 'no') then
    result := 'Norwegian'
  else if SameText(Code, 'nso') then
    result := 'Sesotho'
  else if SameText(Code, 'oc') then
    result := 'Occitan'
  else if SameText(Code, 'or') then
    result := 'Oriya'
  else if SameText(Code, 'pa') then
    result := 'Punjabi'
  else if SameText(Code, 'pl') then
    result := 'Polish'
  else if SameText(Code, 'prs') then
    result := 'Dari'
  else if SameText(Code, 'ps') then
    result := 'Pashto'
  else if SameText(Code, 'pt') then
    result := 'Portuguese'
  else if SameText(Code, 'quc') then
    result := 'K''iche'
  else if SameText(Code, 'quz') then
    result := 'Quechua'
  else if SameText(Code, 'rm') then
    result := 'Romansh'
  else if SameText(Code, 'ro') then
    result := 'Romanian'
  else if SameText(Code, 'ru') then
    result := 'Russian'
  else if SameText(Code, 'rw') then
    result := 'Kinyarwanda'
  else if SameText(Code, 'sa') then
    result := 'Sanskrit'
  else if SameText(Code, 'sah') then
    result := 'Yakut'
  else if SameText(Code, 'se') then
    result := 'Sami (Northern)'
  else if SameText(Code, 'si') then
    result := 'Sinhala'
  else if SameText(Code, 'sk') then
    result := 'Slovak'
  else if SameText(Code, 'sl') then
    result := 'Slovenian'
  else if SameText(Code, 'sma') then
    result := 'Sami (Southern)'
  else if SameText(Code, 'smj') then
    result := 'Sami (Lule)'
  else if SameText(Code, 'smn') then
    result := 'Sami (Inari)'
  else if SameText(Code, 'sms') then
    result := 'Sami (Skolt)'
  else if SameText(Code, 'sq') then
    result := 'Albanian'
  else if SameText(Code, 'sr') then
    result := 'Serbian'
  else if SameText(Code, 'sv') then
    result := 'Swedish'
  else if SameText(Code, 'sw') then
    result := 'Kiswahili'
  else if SameText(Code, 'syr') then
    result := 'Syriac'
  else if SameText(Code, 'ta') then
    result := 'Tamil'
  else if SameText(Code, 'te') then
    result := 'Telugu'
  else if SameText(Code, 'tg') then
    result := 'Tajik'
  else if SameText(Code, 'th') then
    result := 'Thai'
  else if SameText(Code, 'tk') then
    result := 'Turkmen'
  else if SameText(Code, 'tn') then
    result := 'Setswana'
  else if SameText(Code, 'tr') then
    result := 'Turkish'
  else if SameText(Code, 'tt') then
    result := 'Tatar'
  else if SameText(Code, 'tzm') then
    result := 'Tamazight'
  else if SameText(Code, 'ug') then
    result := 'Uyghur'
  else if SameText(Code, 'uk') then
    result := 'Ukrainian'
  else if SameText(Code, 'ur') then
    result := 'Urdu'
  else if SameText(Code, 'uz') then
    result := 'Uzbek'
  else if SameText(Code, 'vi') then
    result := 'Vietnamese'
  else if SameText(Code, 'wo') then
    result := 'Wolof'
  else if SameText(Code, 'xh') then
    result := 'isiXhosa'
  else if SameText(Code, 'yo') then
    result := 'Yoruba'
  else if SameText(Code, 'zh') then
    result := 'Chinese'
  else if SameText(Code, 'zu') then
    result := 'isiZulu'
  else
    result := Code + '?';
end;

{ TFirestorePath }

class function TFirestorePath.ContainsPathDelim(const Path: string): boolean;
begin
  result := (pos('/', Path) >= 0) or (pos('\', Path) >= 0);
end;

class function TFirestorePath.TrimStartAndEndPathDelimiters(
  const Path: string): string;
begin
  if Path.StartsWith('/') or Path.StartsWith('\') then
  begin
    if Path.EndsWith('/') or Path.EndsWith('\') then
      result := Path.Substring(1, length(Path) - 2)
    else
      result := Path.Substring(1)
  end
  else if Path.EndsWith('/') or Path.EndsWith('\') then
    result := Path.Substring(0, length(Path) - 1)
  else
    result := Path;
end;

class function TFirestorePath.ConvertToDocPath(
  const Path: string): TRequestResourceParam;
begin
  result := TrimStartAndEndPathDelimiters(Path).Split(['/', '\']);
end;

class function TFirestorePath.ExtractLastCollection(const Path: string): string;
var
  TrimmedPath: string;
  c: integer;
begin
  TrimmedPath := TrimStartAndEndPathDelimiters(Path);
  {$IF CompilerVersion < 34} // Delphi 10.3 and before
  c := TrimmedPath.LastDelimiter('/\');
  {$ELSE}
  c := TrimmedPath.LastDelimiter(['/', '\']);
  {$ENDIF}
  if c < 0 then
    result := TrimmedPath
  else
    result := TrimmedPath.Substring(c + 1);
end;

class function TFirestorePath.GetDocPath(Params: TRequestResourceParam): string;
var
  i: integer;
begin
  result := '';
  for i := low(Params) to high(Params) do
    result := result + '/' + Params[i];
end;

class function TFirestorePath.DocPathWithoutLastCollection(
  const Path: string): TRequestResourceParam;
var
  TrimmedPath: string;
  c: integer;
begin
  TrimmedPath := TrimStartAndEndPathDelimiters(Path);
  {$IF CompilerVersion < 34} // Delphi 10.3 and before
  c := TrimmedPath.LastDelimiter('/\');
  {$ELSE}
  c := TrimmedPath.LastDelimiter(['/', '\']);
  {$ENDIF}
  if c < 0 then
    result := []
  else
    result := ConvertToDocPath(TrimmedPath.Substring(0, c));
end;

{ TJSONHelpers }

function TJSONHelpers.GetIntegerValue: integer;
begin
  result := GetValue<integer>('integerValue');
end;

function TJSONHelpers.GetInt64Value: Int64;
begin
  result := GetValue<Int64>('integerValue');
end;

function TJSONHelpers.GetInt64ValueDef(Default: Int64): Int64;
begin
  if Assigned(FindValue('integerValue')) then
    result := GetInt64Value
  else
    result := Default;
end;

function TJSONHelpers.GetIntegerValue(const Name: string): integer;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetIntegerValue
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetIntegerValueDef(Default: integer): integer;
begin
  if Assigned(FindValue('integerValue')) then
    result := GetIntegerValue
  else
    result := Default;
end;

function TJSONHelpers.GetIntegerValueDef(const Name: string;
  Default: integer): integer;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetIntegerValue
  else
    result := Default;
end;

function TJSONHelpers.GetInt64Value(const Name: string): Int64;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetInt64Value
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetInt64ValueDef(const Name: string;
  Default: Int64): Int64;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetInt64Value
  else
    result := Default;
end;

function TJSONHelpers.GetStringValue: string;
begin
  result := GetValue<string>('stringValue');
end;

function TJSONHelpers.GetStringValue(const Name: string): string;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetStringValue
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetStringValueDef(const Default: string = ''): string;
begin
  if Assigned(FindValue('stringValue')) then
    result := GetStringValue
  else
    result := Default;
end;

function TJSONHelpers.GetStringValueDef(const Name, Default: string): string;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetStringValue
  else
    result := Default;
end;

function TJSONHelpers.GetBooleanValue: boolean;
begin
  result := GetValue<boolean>('booleanValue');
end;

function TJSONHelpers.GetBooleanValue(const Name: string): boolean;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetBooleanValue
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetBooleanValueDef(Default: boolean): boolean;
begin
  if Assigned(FindValue('booleanValue')) then
    result := GetBooleanValue
  else
    result := Default;
end;

function TJSONHelpers.GetBooleanValueDef(const Name: string;
  Default: boolean): boolean;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetBooleanValue
  else
    result := Default;
end;

function TJSONHelpers.GetDoubleValue: double;
begin
  result := GetValue<double>('doubleValue');
end;

function TJSONHelpers.GetDoubleValue(const Name: string): double;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetDoubleValue
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetDoubleValueDef(Default: double): double;
begin
  if Assigned(FindValue('doubleValue')) then
    result := GetDoubleValue
  else
    result := Default;
end;

function TJSONHelpers.GetDoubleValueDef(const Name: string;
  Default: double): double;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetDoubleValue
  else
    result := Default;
end;

function TJSONHelpers.GetTimeStampValue(
  TimeZone: FB4D.Interfaces.TTimeZone): TDateTime;
begin
  result := GetValue<TDateTime>('timestampValue');
  if TimeZone = tzLocalTime then
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

function TJSONHelpers.GetTimeStampValue(const Name: string;
  TimeZone: FB4D.Interfaces.TTimeZone): TDateTime;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
  begin
    result := (Val as TJSONObject).GetTimeStampValue;
    if TimeZone = tzLocalTime then
      result := TFirebaseHelpers.ConvertToLocalDateTime(result);
  end else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetTimeStampValueDef(Default: TDateTime;
  TimeZone: FB4D.Interfaces.TTimeZone): TDateTime;
begin
  if Assigned(FindValue('timestampValue')) then
    result := GetTimeStampValue(TimeZone)
  else
    result := Default;
end;

function TJSONHelpers.GetTimeStampValueDef(const Name: string;
  Default: TDateTime; TimeZone: FB4D.Interfaces.TTimeZone): TDateTime;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
  begin
    result := (Val as TJSONObject).GetTimeStampValue;
    if TimeZone = tzLocalTime then
      result := TFirebaseHelpers.ConvertToLocalDateTime(result);
  end else
    result := Default;
end;

function TJSONHelpers.GetGeoPoint: TLocationCoord2D;
var
  Val: TJSONValue;
begin
  Val := GetValue<TJSONValue>('geoPointValue');
  result := TLocationCoord2D.Create(Val.GetValue<double>('latitude'),
    Val.GetValue<double>('longitude'))
end;

function TJSONHelpers.GetGeoPoint(const Name: string): TLocationCoord2D;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetGeoPoint
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetGeoPointDef(
  Default: TLocationCoord2D): TLocationCoord2D;
begin
  if Assigned(FindValue('geoPointValue')) then
    result := GetGeoPoint
  else
    result := Default;
end;

function TJSONHelpers.GetGeoPointDef(const Name: string;
  Default: TLocationCoord2D): TLocationCoord2D;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetGeoPoint
  else
    result := Default;
end;

class function TJSONHelpers.SetStringValue(const Val: string): TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('stringValue',
    TJSONString.Create(Val)));
end;

class function TJSONHelpers.SetString(const VarName, Val: string): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetStringValue(Val));
end;

class function TJSONHelpers.SetIntegerValue(Val: integer): TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('integerValue',
    TJSONNumber.Create(Val)));
end;

class function TJSONHelpers.SetInt64Value(Val: Int64): TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('integerValue',
    TJSONNumber.Create(Val)));
end;

class function TJSONHelpers.SetInt64(const VarName: string;
  Val: Int64): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetInt64Value(Val));
end;

class function TJSONHelpers.SetInteger(const VarName: string;
  Val: integer): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetIntegerValue(Val));
end;

class function TJSONHelpers.SetDoubleValue(Val: double): TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('doubleValue',
    TJSONNumber.Create(Val)));
end;

class function TJSONHelpers.SetDouble(const VarName: string;
  Val: double): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetDoubleValue(Val));
end;

class function TJSONHelpers.SetBooleanValue(Val: boolean): TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('booleanValue',
    TJSONBool.Create(Val)));
end;

class function TJSONHelpers.SetBoolean(const VarName: string;
  Val: boolean): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetBooleanValue(Val));
end;

class function TJSONHelpers.SetTimeStampValue(Val: TDateTime;
  TimeZone: FB4D.Interfaces.TTimeZone): TJSONObject;
begin
  if TimeZone = tzLocalTime then
    Val := TFirebaseHelpers.ConvertToUTCDateTime(Val);
  result := TJSONObject.Create(TJSONPair.Create('timestampValue',
    TJSONString.Create(TFirebaseHelpers.CodeRFC3339DateTime(Val))));
end;

class function TJSONHelpers.SetTimeStamp(const VarName: string;
  Val: TDateTime; TimeZone: FB4D.Interfaces.TTimeZone): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetTimeStampValue(Val, TimeZone));
end;

class function TJSONHelpers.SetNullValue: TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('nullValue', TJSONNull.Create));
end;

class function TJSONHelpers.SetNull(const VarName: string): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetNullValue);
end;

function TJSONHelpers.IsNull: boolean;
begin
  result := GetValue<TJSONValue>('nullValue') is TJSONNull;
end;

function TJSONHelpers.GetReference: string;
begin
  result := GetValue<string>('referenceValue');
end;

function TJSONHelpers.GetReference(const Name: string): string;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetReference
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetReferenceDef(const Default: string): string;
begin
  if Assigned(FindValue('referenceValue')) then
    result := GetReference
  else
    result := Default;
end;

function TJSONHelpers.GetReferenceDef(const Name, Default: string): string;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetReference
  else
    result := Default;
end;

class function TJSONHelpers.SetReferenceValue(const ProjectID,
  Ref: string; const Database: string): TJSONObject;

  function ConvertRefPath(const ProjectID, Reference: string): string;
  var
    RefWithPath: string;
  begin
    RefWithPath := Reference;
    if not RefWithPath.StartsWith('/') then
      RefWithPath := '/' + RefWithPath;
    result := System.SysUtils.Format(cFirestoreDocumentPath,
      [ProjectID, Database, RefWithPath]);
  end;

begin
  result := TJSONObject.Create(TJSONPair.Create('referenceValue',
    TJSONString.Create(ConvertRefPath(ProjectID, Ref))));
end;

class function TJSONHelpers.SetReference(const Name, ProjectID,
  Ref: string): TJSONPair;
begin
  result := TJSONPair.Create(Name, SetReferenceValue(ProjectID, Ref));
end;

class function TJSONHelpers.SetGeoPointValue(Val: TLocationCoord2D): TJSONObject;
var
  Geo: TJSONObject;
begin
  Geo := TJSONObject.Create;
  Geo.AddPair('latitude', TJSONNumber.Create(Val.Latitude));
  Geo.AddPair('longitude', TJSONNumber.Create(Val.Longitude));
  result := TJSONObject.Create(TJSONPair.Create('geoPointValue', Geo));
end;

class function TJSONHelpers.SetGeoPoint(const VarName: string;
  Val: TLocationCoord2D): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetGeoPointValue(Val));
end;

class function TJSONHelpers.SetBytesValue(Val: TBytes): TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('bytesValue',
    TJSONString.Create(TNetEncoding.Base64.EncodeBytesToString(Val))));
end;

class function TJSONHelpers.SetBytes(const VarName: string;
  Val: TBytes): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetBytesValue(Val));
end;

function TJSONHelpers.GetBytes: TBytes;
begin
  result := TNetEncoding.Base64.DecodeStringToBytes(
    GetValue<string>('bytesValue'));
end;

function TJSONHelpers.GetBytes(const Name: string): TBytes;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetBytes
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetMapSize: integer;
begin
  result := GetValue<TJSONObject>('mapValue').
    GetValue<TJSONObject>('fields').Count;
end;

function TJSONHelpers.GetMapSize(const Name: string): integer;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetMapSize
  else
    result := 0;
end;

function TJSONHelpers.GetMapItem(Ind: integer): TJSONPair;
var
  Obj: TJSONObject;
begin
  Obj := GetValue<TJSONObject>('mapValue').GetValue<TJSONObject>('fields');
  if (Ind < 0) or (Ind >= Obj.Count) then
    raise EJSONException.CreateFmt(rsMapItemOutOfBounds, [Ind]);
  result := Obj.Pairs[Ind];
end;

function TJSONHelpers.GetMapItem(const Name: string): TJSONObject;
var
  Obj: TJSONObject;
  Ind: integer;
begin
  result := nil;
  Obj := GetValue<TJSONObject>('mapValue').GetValue<TJSONObject>('fields');
  if assigned(Obj) then
    for Ind := 0 to Obj.Count - 1 do
      if SameText(Obj.Pairs[Ind].JsonString.Value, Name) then
        exit(Obj.Pairs[Ind].JsonValue as TJSONObject);
end;

function TJSONHelpers.GetMapItem(const Name: string; Ind: integer): TJSONPair;
var
  Val: TJSONValue;
begin
  result := nil;
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetMapItem(Ind)
end;

function TJSONHelpers.GetMapValue(const Name: string;
  Ind: integer): TJSONObject;
begin
  result := GetMapItem(Name, Ind).JsonValue as TJSONObject;
end;

function TJSONHelpers.GetMapValues: TJSONObject;
begin
  result := GetValue<TJSONObject>('mapValue');
end;

class function TJSONHelpers.SetMapValue(MapVars: TFirestoreMap): TJSONObject;
var
  Map: TJSONObject;
  c: integer;
begin
  Map := TJSONObject.Create;
  for c := 0 to length(mapVars) - 1 do
    Map.AddPair(MapVars[c]);
  result := TJSONObject.Create(TJSONPair.Create('mapValue',
    TJSONObject.Create(TJSONPair.Create('fields', Map))));
end;

class function TJSONHelpers.SetMap(const VarName: string;
  MapVars: TFirestoreMap): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetMapValue(MapVars));
end;

class function TJSONHelpers.SetArrayValue(FSArr: TFirestoreArr): TJSONObject;
var
  Arr: TJSONArray;
  c: integer;
begin
  Arr := TJSONArray.Create;
  for c := 0 to length(FSArr) - 1 do
    Arr.AddElement(FSArr[c]);
  result := TJSONObject.Create(TJSONPair.Create('arrayValue',
    TJSONObject.Create(TJSONPair.Create('values', Arr))));
end;

class function TJSONHelpers.SetArray(const VarName: string;
  FSArr: TFirestoreArr): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetArrayValue(FSArr));
end;

class function TJSONHelpers.SetStringArray(const VarName: string;
  Strings: TStringDynArray): TJSONPair;
var
  Arr: TFirestoreArr;
  c: integer;
begin
  SetLength(Arr, length(Strings));
  for c := 0 to length(Strings) - 1 do
    Arr[c] := TJSONObject.SetStringValue(Strings[c]);
  result := SetArray(VarName, Arr);
end;

class function TJSONHelpers.SetStringArray(const VarName: string;
  Strings: TStringList): TJSONPair;
var
  Arr: TFirestoreArr;
  c: integer;
begin
  SetLength(Arr, Strings.Count);
  for c := 0 to Strings.Count - 1 do
    Arr[c] := TJSONObject.SetStringValue(Strings[c]);
  result := SetArray(VarName, Arr);
end;

class function TJSONHelpers.SetStringArray(const VarName: string;
  Strings: TList<string>): TJSONPair;
var
  Arr: TFirestoreArr;
  c: integer;
begin
  SetLength(Arr, Strings.Count);
  for c := 0 to Strings.Count - 1 do
    Arr[c] := TJSONObject.SetStringValue(Strings[c]);
  result := SetArray(VarName, Arr);
end;

function TJSONHelpers.GetArraySize: integer;
var
  Val : TJSONValue;
begin
  Val := GetValue<TJSONObject>('arrayValue').FindValue('values');
  if assigned(Val) then
    result := TJSONArray(Val).Count
  else
    result := 0;
end;

function TJSONHelpers.GetArraySize(const Name: string): integer;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetArraySize
  else
    result := 0;
end;

function TJSONHelpers.GetArrayValues: TJSONObjects;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  c: integer;
begin
  Obj := GetValue<TJSONObject>('arrayValue');
  if not assigned(Obj) then
    exit(nil);
  Arr := Obj.GetValue('values') as TJSONArray;
  if not assigned(Arr) then
    exit(nil);
  SetLength(result, Arr.Count);
  for c := 0 to Arr.Count - 1 do
  begin
    if not(Arr.Items[c] is TJSONObject) then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotJSONObj, [c]);
    Obj := Arr.Items[c] as TJSONObject;
    if Obj.Count <> 1 then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotTypeValue, [c]);
    result[c] := Obj;
  end;
end;

function TJSONHelpers.GetArrayItem(Ind: integer): TJSONObject;
var
  Arr: TJSONArray;
  Obj: TJSONObject;
begin
  Arr := GetValue<TJSONObject>('arrayValue').GetValue<TJSONArray>('values');
  if (Ind < 0) or (Ind >= Arr.Count) then
    raise EJSONException.CreateFmt(rsArrayItemOutOfBounds, [Ind]);
  if not(Arr.Items[Ind] is TJSONObject) then
    raise EJSONException.CreateFmt(rsInvalidArrayItem, [Ind]);
  Obj := Arr.Items[Ind] as TJSONObject;
  if Obj.Count <> 1 then
    raise EJSONException.CreateFmt(rsInvalidArrayItem, [Ind]);
  result := Obj;
end;

function TJSONHelpers.GetArrayItem(const Name: string;
  Ind: integer): TJSONObject;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetArrayItem(Ind)
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetStringArray: TStringDynArray;
var
  Arr: TJSONArray;
  c: integer;
begin
  Arr := GetValue<TJSONObject>('arrayValue').GetValue<TJSONArray>('values');
  SetLength(result, Arr.Count);
  for c := 0 to Arr.Count - 1 do
    result[c] := (Arr.Items[0] as TJSONObject).GetStringValue;
end;

{ TQueryParamsHelper }

class function TQueryParamsHelper.CreateQueryParams(
  CheckThisInstanceFirst: TQueryParams): TQueryParams;
begin
  if Assigned(CheckThisInstanceFirst) then
    result := CheckThisInstanceFirst
  else
    result := TQueryParams.Create;
end;

function TQueryParamsHelper.AddLimitToFirst(
  LimitToFirst: integer): TQueryParams;
begin
  Add(cGetQueryParamLimitToFirst, [LimitToFirst.ToString]);
  result := self;
end;

function TQueryParamsHelper.AddLimitToLast(LimitToLast: integer): TQueryParams;
begin
  Add(cGetQueryParamLimitToLast, [LimitToLast.ToString]);
  result := self;
end;

function TQueryParamsHelper.AddOrderBy(const FieldName: string): TQueryParams;
begin
  if not FieldName.IsEmpty then
    Add(cGetQueryParamOrderBy,
      ['"' + StringReplace(FieldName, '"', '""', [rfReplaceAll]) + '"']);
  result := self;
end;

function TQueryParamsHelper.AddOrderByType(
  const TypeName: string): TQueryParams;
const
  sQuery = '"$%s"';
begin
  if not TypeName.IsEmpty then
    Add(cGetQueryParamOrderBy, [Format(sQuery, [TypeName])]);
  result := self;
end;

function TQueryParamsHelper.AddOrderByAndEqualTo(const FieldName,
  FilterValue: string): TQueryParams;
begin
  if not FieldName.IsEmpty then
    Add(cGetQueryParamOrderBy,
      ['"' + StringReplace(FieldName, '"', '""', [rfReplaceAll]) + '"']);
  Add(cGetQueryParamEqualTo,
    ['"' + StringReplace(FilterValue, '"', '""', [rfReplaceAll]) + '"']);
  result := self;
end;

function TQueryParamsHelper.AddOrderByAndEqualTo(const FieldName: string;
  FilterValue: integer): TQueryParams;
begin
  if not FieldName.IsEmpty then
    Add(cGetQueryParamOrderBy,
      ['"' + StringReplace(FieldName, '"', '""', [rfReplaceAll]) + '"']);
  Add(cGetQueryParamEqualTo,
    [FilterValue.ToString]);
  result := self;
end;

function TQueryParamsHelper.AddOrderByAndEqualTo(const FieldName: string;
  FilterValue: extended): TQueryParams;
begin
  if not FieldName.IsEmpty then
    Add(cGetQueryParamOrderBy,
      ['"' + StringReplace(FieldName, '"', '""', [rfReplaceAll]) + '"']);
  Add(cGetQueryParamEqualTo,
    [FilterValue.ToString]);
  result := self;
end;

function TQueryParamsHelper.AddPageSize(PageSize: integer): TQueryParams;
begin
  Add(cFirestorePageSize, [PageSize.ToString]);
  result := self;
end;

function TQueryParamsHelper.AddPageToken(const PageToken: string): TQueryParams;
begin
  if not PageToken.IsEmpty then
    Add(cFirestorePageToken, [PageToken]);
  result := self;
end;

function TQueryParamsHelper.AddTransaction(
  Transaction: TFirestoreReadTransaction): TQueryParams;
begin
  if not Transaction.IsEmpty then
    Add(cFirestoreTransaction, [Transaction]);
  result := self;
end;

{ TSchemaItemsHelper }

class function TSchemaItemsHelper.CreateItem(const FieldName: string; Schema: IGeminiSchema): TPair<string, IGeminiSchema>;
begin
  result := TPair<string, IGeminiSchema>.Create(FieldName, Schema);
end;

end.
