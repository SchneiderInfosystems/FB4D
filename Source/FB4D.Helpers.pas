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

unit FB4D.Helpers;

interface

uses
  System.Classes, System.Types, System.SysUtils, System.StrUtils,
{$IFNDEF LINUX64}
  System.Sensors,
{$ENDIF}
  System.JSON, System.Generics.Collections,
  FB4D.Interfaces;

type
  TOnSimpleDownloadError = procedure(const DownloadURL, ErrMsg: string) of
    object;
  TOnSimpleDownloadSuccess = procedure(const DownloadURL: string) of object;

  TFirebaseHelpers = class
    // Time conversion functions
    class function CodeRFC3339DateTime(DateTimeStamp: TDateTime): string;
    class function ConvertTimeStampToUTCDateTime(TimeStamp: Int64): TDateTime;
    class function ConvertRFC5322ToUTCDateTime(DateTime: string): TDateTime;
    class function ConvertRFC5322ToLocalDateTime(DateTime: string): TDateTime;
    class function ConvertTimeStampToLocalDateTime(Timestamp: Int64): TDateTime;
    class function ConvertToLocalDateTime(DateTimeStampUTC: TDateTime): TDateTime;
    // Query parameter helpers
    class function EncodeQueryParams(QueryParams: TQueryParams): string;
    class function EncodeQueryParamsWithToken(QueryParams: TQueryParams;
      const EncodedToken: string): string;
    // Request parameter helpers
    class function EncodeResourceParams(Params: TRequestResourceParam): string;
    class function AddParamToResParams(Params: TRequestResourceParam;
      const Param: string): TRequestResourceParam;
    // Encode token for URL based token transmission
    class function EncodeToken(const Token: string): string;
    // Array of string helpers
    class function ArrStrToCommaStr(Arr: array of string): string;
    class function ArrStrToQuotedCommaStr(Arr: array of string): string;
    // FBID is based on charset of cBase64: Helpers and converter to GUID
    type TIDKind = (FBID {random 22 Chars},
                    PUSHID {timestamp and random: total 20 Chars});
    class function CreateAutoID(IDKind: TIDKind = FBID): string;
    class function ConvertGUIDtoFBID(Guid: TGuid): string;
    class function ConvertFBIDtoGUID(const FBID: string): TGuid;
    class function ConvertTimeStampAndRandomPatternToPUSHID(timestamp: TDateTime;
      Random: TBytes): string;
    class function DecodeTimeStampFromPUSHID(const PUSHID: string): TDateTime;

    // File helpers
    class procedure SimpleDownload(const DownloadUrl: string; Stream: TStream;
      OnSuccess: TOnSimpleDownloadSuccess;
      OnError: TOnSimpleDownloadError = nil);
    // Miscellaneous functions
    class function IsEMailAdress(const EMail: string): boolean;
    // Application helpers
    class procedure Log(msg: string);
    class procedure LogFmt(msg: string; const Args: array of const);
    class function AppIsTerminated: boolean;
    class procedure SleepAndMessageLoop(SleepInMs: cardinal);
    class function IsMainThread: boolean;
    class function GetConfigAndPlatform: string;
    class function GetPlatform: string;
  private const
    cBase64 =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-';
    // The last char '-' is not real Base64 because '/' causes troubles in IDs
    cFirebaseID64 =
      '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
    // This notification is used in the Realtime DB for Post and Push operation
  end;

  TJSONHelpers = class helper for TJSONObject
    // String
    function GetStringValue: string; overload;
    function GetStringValue(const Name: string): string; overload;
    class function SetStringValue(const Val: string): TJSONObject;
    class function SetString(const VarName, Val: string): TJSONPair;
    // Integer
    function GetIntegerValue: integer; overload;
    function GetIntegerValue(const Name: string): integer; overload;
    class function SetIntegerValue(Val: integer): TJSONObject;
    class function SetInteger(const VarName: string; Val: integer): TJSONPair;
    // Boolean
    function GetBooleanValue: Boolean; overload;
    function GetBooleanValue(const Name: string): Boolean; overload;
    class function SetBooleanValue(Val: boolean): TJSONObject;
    class function SetBoolean(const VarName: string; Val: boolean): TJSONPair;
    // Double
    function GetDoubleValue: double; overload;
    function GetDoubleValue(const Name: string): double; overload;
    class function SetDoubleValue(Val: double): TJSONObject;
    class function SetDouble(const VarName: string; Val: double): TJSONPair;
    // TimeStamp
    function GetTimeStampValue(const Name: string): TDateTime; overload;
    function GetTimeStampValue: TDateTime; overload;
    class function SetTimeStampValue(Val: TDateTime): TJSONObject;
    class function SetTimeStamp(const VarName: string;
      Val: TDateTime): TJSONPair;
    // Null
    class function SetNullValue: TJSONObject;
    class function SetNull(const VarName: string): TJSONPair;
    function IsNull: boolean;
    // Reference
    function GetReference: string; overload;
    function GetReference(const Name: string): string; overload;
    class function SetReferenceValue(const ProjectID, Ref: string): TJSONObject;
    class function SetReference(const Name, ProjectID, Ref: string): TJSONPair;
    // GeoPoint
    function GetGeoPoint: TLocationCoord2D; overload;
    function GetGeoPoint(const Name: string): TLocationCoord2D; overload;
    class function SetGeoPointValue(Val: TLocationCoord2D): TJSONObject;
    class function SetGeoPoint(const VarName: string;
      Val: TLocationCoord2D): TJSONPair;
    // Bytes
    class function SetBytesValue(Val: TBytes): TJSONObject;
    class function SetBytes(const VarName: string; Val: TBytes): TJSONPair;
    function GetBytes: TBytes; overload;
    function GetBytes(const Name: string): TBytes; overload;
    class function SetMapValue(MapVars: array of TJSONPair): TJSONObject;
    class function SetMap(const VarName: string;
      MapVars: array of TJSONPair): TJSONPair;
    // Map
    function GetMapSize: integer; overload;
    function GetMapSize(const Name: string): integer; overload;
    function GetMapItem(Ind: integer): TJSONPair; overload;
    function GetMapItem(const Name: string): TJSONObject; overload;
    function GetMapItem(const Name: string; Ind: integer): TJSONPair; overload;
    // Array
    class function SetArray(const VarName: string;
      ArrayVars: array of TJSONValue): TJSONPair;
    function GetArraySize: integer; overload;
    function GetArraySize(const Name: string): integer; overload;
    function GetArrayItem(Ind: integer): TJSONObject; overload;
    function GetArrayItem(const Name: string; Ind: integer): TJSONObject;
      overload;
  end;

  TQueryParamsHelper = class helper for TQueryParams
    class function CreateQueryParams(CheckThisInstanceFirst: TQueryParams =
      nil): TQueryParams;
    function AddOrderBy(const FieldName: string): TQueryParams;
    function AddOrderByType(const TypeName: string): TQueryParams;
    function AddLimitToFirst(LimitToFirst: integer): TQueryParams;
    function AddLimitToLast(LimitToLast: integer): TQueryParams;
    function AddTransaction(const Transaction: string): TQueryParams;
    function AddPageSize(PageSize: integer): TQueryParams;
    function AddPageToken(const PageToken: string): TQueryParams;
  end;

resourcestring
  rsFBFailureIn = '%s Firebase failure in %s: %s';

implementation

uses
  System.Character,
{$IF Declared(VCL)}
  WinAPI.Windows,
  VCL.Forms,
{$ELSEIF Declared(FMX)}
  FMX.Types,
  FMX.Forms,
{$ELSE}
  FMX.Types,
  FMX.Forms,
{$ENDIF}
  System.DateUtils, System.NetEncoding, System.JSONConsts, System.Math,
  System.Net.HttpClient, System.Hash,
  IdGlobalProtocols;

resourcestring
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
    FormatDateTime('hh:mm:ss', UTC) + 'Z';
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

class function TFirebaseHelpers.EncodeResourceParams(
  Params: TRequestResourceParam): string;
const
  PathUnsafeChars: TURLEncoding.TUnsafeChars =
    [Ord('"'), Ord('<'), Ord('>'), Ord('^'), Ord('`'), Ord('{'), Ord('}'),
     Ord('|'), Ord('/'), Ord('\'), Ord('?'), Ord('#'), Ord('+')];
  Option: TURLEncoding.TEncodeOptions =
    [TURLEncoding.TEncodeOption.SpacesAsPlus,
     TURLEncoding.TEncodeOption.EncodePercent];
var
  i: integer;
begin
  result := '';
  for i := low(Params) to high(Params) do
    result := result + '/' + TNetEncoding.URL.Encode(Params[i], PathUnsafeChars,
      Option);
end;

class function TFirebaseHelpers.EncodeToken(const Token: string): string;
begin
  if Token.IsEmpty then
    result := ''
  else
    result := '?auth=' + TNetEncoding.URL.Encode(Token);
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
{$IF Declared(FMX)}
  {$IFDEF LINUX}
  writeln(msg);  // Workaround for RSP-32303
  {$ELSE}
  FMX.Types.Log.d(msg, []);
  // there is a bug in DE 10.2 when the wrong method is calling?
  {$ENDIF}
{$ELSEIF Declared(VCL)}
  OutputDebugString(PChar(msg));
{$ELSE}
  writeln(msg);
{$ENDIF}
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
{$IF Declared(VCL) OR Declared(FMX)}
  result := Application.Terminated;
{$ELSE}
  result := false;
{$ENDIF}
end;

class procedure TFirebaseHelpers.SleepAndMessageLoop(SleepInMs: cardinal);
begin
{$IF Declared(VCL) OR Declared(FMX)}
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

class function TFirebaseHelpers.CreateAutoID(IDKind: TIDKind = FBID): string;
begin
  // use OS to generate a random number
  case IDKind of
    FBID:
      result := ConvertGUIDtoFBID(TGuid.NewGuid);
    PUSHID:
      result := ConvertTimeStampAndRandomPatternToPUSHID(now,
        THashMD5.GetHashBytes(GuidToString(TGUID.NewGuid)));
  end;
end;

class function TFirebaseHelpers.ConvertGUIDtoFBID(Guid: TGuid): string;

  function GetBase64(b: Byte): char;
  begin
    result := cBase64[low(cBase64) + b and $3F];
  end;

var
  D1: cardinal;
  D2, D3: Word;
begin
  SetLength(result, 22);
  D1 := Guid.D1;
  result[1] := GetBase64(D1);
  D1 := D1 shr 6;
  result[2] := GetBase64(D1);
  D1 := D1 shr 6;
  result[3] := GetBase64(D1);
  D1 := D1 shr 6;
  result[4] := GetBase64(D1);
  D1 := D1 shr 6;
  result[5] := GetBase64(D1);
  D2 := Guid.D2;
  result[6] := GetBase64(D2);
  D2 := D2 shr 6;
  result[7] := GetBase64(D2);
  D2 := D2 shr 6;
  result[8] := GetBase64(D2 and $F + (D1 and $C0) shr 2);
  D3 := Guid.D3;
  result[9] := GetBase64(D3);
  D3 := D3 shr 6;
  result[10] := GetBase64(D3);
  D3 := D3 shr 6;
  result[11] := GetBase64(D3 and $F + (Guid.D4[0] and $C0) shr 2);
  result[12] := GetBase64(Guid.D4[0]);
  result[13] := GetBase64(Guid.D4[1]);
  result[14] := GetBase64(Guid.D4[2]);
  result[15] := GetBase64(Guid.D4[3]);
  result[16] := GetBase64(Guid.D4[4]);
  result[17] := GetBase64(Guid.D4[5]);
  result[18] := GetBase64(Guid.D4[6]);
  result[19] := GetBase64(Guid.D4[7]);
  result[20] := GetBase64((Guid.D4[1] and $C0) shr 6 +
    (Guid.D4[2] and $C0) shr 4 + (Guid.D4[3] and $C0) shr 2);
  result[21] := GetBase64((Guid.D4[4] and $C0) shr 6 +
    (Guid.D4[5] and $C0) shr 4 + (Guid.D4[6] and $C0) shr 2);
  result[22] := GetBase64((Guid.D4[7] and $C0) shr 6);
end;

class function TFirebaseHelpers.ConvertFBIDtoGUID(const FBID: string): TGuid;
var
  c: integer;
  Base64: array[1..22] of byte;
begin
  for c := low(Base64) to high(Base64) do
    Base64[c] := 0; // Zero for ID that are shorter than 22
  for c := 1 to max(length(FBID), high(Base64)) do
    Base64[c] := pos(FBID[c], cBase64) - 1;
  result.D1 := Base64[1] + Base64[2] shl 6 + Base64[3] shl 12 +
    Base64[4] shl 18 + Base64[5] shl 24 + (Base64[8] and $30) shl 26;
  result.D2 := Base64[6] + Base64[7] shl 6 + (Base64[8] and $F) shl 12;
  result.D3 := Base64[9] + Base64[10] shl 6 + (Base64[11] and $F) shl 12;
  result.D4[0] := Base64[12] + (Base64[11] and $30) shl 2;
  result.D4[1] := Base64[13] + (Base64[20] and $03) shl 6;
  result.D4[2] := Base64[14] + (Base64[20] and $0C) shl 4;
  result.D4[3] := Base64[15] + (Base64[20] and $30) shl 2;
  result.D4[4] := Base64[16] + (Base64[21] and $03) shl 6;
  result.D4[5] := Base64[17] + (Base64[21] and $0C) shl 4;
  result.D4[6] := Base64[18] + (Base64[21] and $30) shl 2;
  result.D4[7] := Base64[19] + (Base64[22] and $03) shl 6;
end;

class function TFirebaseHelpers.ConvertTimeStampAndRandomPatternToPUSHID(
  timestamp: TDateTime; Random: TBytes): string;
var
  tsi: int64;
  c: integer;
begin
  Assert(length(Random) >= 12, 'Too short random pattern');
  tsi := System.DateUtils.DateTimeToUnix(timestamp, false) * 1000;
  result := '';
  for c := 1 to 8 do
  begin
    result := cFirebaseID64[(tsi mod 64) + low(cFirebaseID64)] + result;
    tsi := tsi shr 6;
  end;
  for c := 0 to 11 do
    result := result + cFirebaseID64[Random[c] and $3F + low(cFirebaseID64)];
end;

class function TFirebaseHelpers.DecodeTimeStampFromPUSHID(
  const PUSHID: string): TDateTime;
var
  tsi: int64;
  c: integer;
begin
  Assert(length(PUSHID) = 20, 'Invalid PUSHID length');
  tsi := 0;
  for c := low(PUSHID) to low(PUSHID) + 8 do
    tsi := tsi shl 6 + pos(PUSHID[c], cFirebaseID64) - low(cFirebaseID64);
  result := TTimeZone.Local.ToLocalTime(UnixToDateTime(tsi div 1000));
end;

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

{ TJSONHelpers }

function TJSONHelpers.GetIntegerValue: integer;
begin
  result := GetValue<integer>('integerValue');
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

function TJSONHelpers.GetBooleanValue: Boolean;
begin
  result := GetValue<boolean>('booleanValue');
end;

function TJSONHelpers.GetBooleanValue(const Name: string): Boolean;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetBooleanValue
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
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

function TJSONHelpers.GetTimeStampValue: TDateTime;
begin
  result := GetValue<TDateTime>('timestampValue');
end;

function TJSONHelpers.GetTimeStampValue(const Name: string): TDateTime;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := (Val as TJSONObject).GetTimeStampValue
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
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

class function TJSONHelpers.SetTimeStampValue(Val: TDateTime): TJSONObject;
begin
  result := TJSONObject.Create(TJSONPair.Create('timestampValue',
    TJSONString.Create(TFirebaseHelpers.CodeRFC3339DateTime(Val))));
end;

class function TJSONHelpers.SetTimeStamp(const VarName: string;
  Val: TDateTime): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetTimeStampValue(Val));
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

class function TJSONHelpers.SetReferenceValue(const ProjectID,
  Ref: string): TJSONObject;

  function ConvertRefPath(const ProjectID, Reference: string): string;
  begin
    result := 'projects/' + ProjectID + '/databases/(default)/documents';
    if Reference.StartsWith('/') then
      result := result + Reference
    else
      result := result + '/' + Reference;
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
  begin
    result := (Val as TJSONObject).GetMapSize
  end else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
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
  Obj := GetValue<TJSONObject>('mapValue').GetValue<TJSONObject>('fields');
  if assigned(Obj) then
    for Ind := 0 to Obj.Count - 1 do
      if SameText(Obj.Pairs[Ind].JsonString.Value, Name) then
        exit(Obj.Pairs[Ind].JsonValue as TJSONObject);
  raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;


function TJSONHelpers.GetMapItem(const Name: string; Ind: integer): TJSONPair;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
  begin
    result := (Val as TJSONObject).GetMapItem(Ind)
  end else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

class function TJSONHelpers.SetMapValue(
  MapVars: array of TJSONPair): TJSONObject;
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
  MapVars: array of TJSONPair): TJSONPair;
begin
  result := TJSONPair.Create(VarName, SetMapValue(MapVars));
end;

class function TJSONHelpers.SetArray(const VarName: string;
  ArrayVars: array of TJSONValue): TJSONPair;

  function SetArrayValue(ArrayVars: array of TJSONValue): TJSONObject;
  var
    Arr: TJSONArray;
    c: integer;
  begin
    Arr := TJSONArray.Create;
    for c := 0 to length(ArrayVars) - 1 do
      Arr.AddElement(ArrayVars[c]);
    result := TJSONObject.Create(TJSONPair.Create('arrayValue',
      TJSONObject.Create(TJSONPair.Create('values', Arr))));
  end;

begin
  result := TJSONPair.Create(VarName, SetArrayValue(ArrayVars));
end;

function TJSONHelpers.GetArraySize: integer;
begin
  result := GetValue<TJSONObject>('arrayValue').
    GetValue<TJSONArray>('values').Count;
end;

function TJSONHelpers.GetArraySize(const Name: string): integer;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
  begin
    result := (Val as TJSONObject).GetArraySize
  end else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
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
  const Transaction: string): TQueryParams;
begin
  if not Transaction.IsEmpty then
    Add(cFirestoreTransaction, ['"' + Transaction + '"']);
  result := self;
end;

end.
