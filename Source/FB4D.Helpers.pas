{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2020 Christoph Schneider                                 }
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
  System.Classes, System.Types, System.SysUtils,
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
    class function CodeRFC3339DateTime(DateTimeStamp: TDateTime): string;
    class function ConvertTimeStampToUTCDateTime(TimeStamp: Int64): TDateTime;
    class function ConvertRFC5322ToUTCDateTime(DateTime: string): TDateTime;
    class function ConvertRFC5322ToLocalDateTime(DateTime: string): TDateTime;
    class function ConvertTimeStampToLocalDateTime(Timestamp: Int64): TDateTime;
    class function ConvertToLocalDateTime(DateTimeStampUTC: TDateTime): TDateTime;
    class function EncodeQueryParams(QueryParams: TQueryParams): string;
    class function EncodeQueryParamsWithToken(QueryParams: TQueryParams;
      const EncodedToken: string): string;
    class function EncodeResourceParams(Params: TRequestResourceParam): string;
    class function AddParamToResParams(Params: TRequestResourceParam;
      const Param: string): TRequestResourceParam;
    class function EncodeToken(const Token: string): string;
    class function ArrStrToCommaStr(Arr: array of string): string;
    class function ArrStrToQuotedCommaStr(Arr: array of string): string;
    class procedure Log(msg: string);
    class function AppIsTerminated: boolean;
    class procedure SleepAndMessageLoop(SleepInMs: cardinal);
    class procedure SimpleDownload(const DownloadUrl: string; Stream: TStream;
      OnSuccess: TOnSimpleDownloadSuccess;
      OnError: TOnSimpleDownloadError = nil);
    class function CreateAutoID: string;
    class function ConvertIDtoGUID(const FBID: string): TGuid;
    class function IsEMailAdress(const EMail: string): boolean;
    class function IsMainThread: boolean;
    class function GetConfigAndPlatform: string;
    class function GetPlatform: string;
  private
    const
      cBase62 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  end;

  TJSONHelpers = class helper for TJSONObject
    function GetStringValue: string; overload;
    function GetStringValue(const Name: string): string; overload;
    class function SetStringValue(const Val: string): TJSONObject;
    class function SetString(const VarName, Val: string): TJSONPair;
    function GetIntegerValue: integer; overload;
    function GetIntegerValue(const Name: string): integer; overload;
    class function SetIntegerValue(Val: integer): TJSONObject;
    class function SetInteger(const VarName: string; Val: integer): TJSONPair;
    function GetBooleanValue: Boolean; overload;
    function GetBooleanValue(const Name: string): Boolean; overload;
    class function SetBooleanValue(Val: boolean): TJSONObject;
    class function SetBoolean(const VarName: string; Val: boolean): TJSONPair;
    function GetDoubleValue: double; overload;
    function GetDoubleValue(const Name: string): double; overload;
    class function SetDoubleValue(Val: double): TJSONObject;
    class function SetDouble(const VarName: string; Val: double): TJSONPair;
    function GetTimeStampValue(const Name: string): TDateTime; overload;
    function GetTimeStampValue: TDateTime; overload;
    class function SetTimeStampValue(Val: TDateTime): TJSONObject;
    class function SetTimeStamp(const VarName: string;
      Val: TDateTime): TJSONPair;
    class function SetNullValue: TJSONObject;
    class function SetNull(const VarName: string): TJSONPair;
    function IsNull: boolean;
    function GetReference: string; overload;
    function GetReference(const Name: string): string; overload;
    class function SetReferenceValue(const ProjectID, Ref: string): TJSONObject;
    class function SetReference(const Name, ProjectID, Ref: string): TJSONPair;
    function GetGeoPoint: TLocationCoord2D; overload;
    function GetGeoPoint(const Name: string): TLocationCoord2D; overload;
    class function SetGeoPointValue(Val: TLocationCoord2D): TJSONObject;
    class function SetGeoPoint(const VarName: string;
      Val: TLocationCoord2D): TJSONPair;
    class function SetBytesValue(Val: TBytes): TJSONObject;
    class function SetBytes(const VarName: string; Val: TBytes): TJSONPair;
    function GetBytes: TBytes; overload;
    function GetBytes(const Name: string): TBytes; overload;
    class function SetMapValue(MapVars: array of TJSONPair): TJSONObject;
    class function SetMap(const VarName: string;
      MapVars: array of TJSONPair): TJSONPair;
    function GetMapSize: integer; overload;
    function GetMapSize(const Name: string): integer; overload;
    function GetMapItem(Ind: integer): TJSONPair; overload;
    function GetMapItem(const Name: string): TJSONObject; overload;
    function GetMapItem(const Name: string; Ind: integer): TJSONPair; overload;
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
  rsFBFailureIn = 'Firebase failure in %s: %s';

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
  System.Net.HttpClient,
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
{$IF Declared(FMX)}
  FMX.Types.Log.d(msg, []);
  // there is a bug in DE 10.2 when the wrong method is calling?
{$ELSEIF Declared(VCL)}
  OutputDebugString(PChar(msg));
{$ELSE}
  writeln(msg);
{$ENDIF}
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
              TFirebaseHelpers.Log(
                Format(rsFBFailureIn, [DownloadUrl, e.Message]));
        end;
      finally
        Client.Free;
      end;
    end).Start;
end;


class function TFirebaseHelpers.CreateAutoID: string;

  function GetBase62(b: Byte): char;
  begin
    result := cBase62[low(cBase62) + b mod 62]; // reduce 64 to 62
  end;

var
  Guid: TGuid;
  D1: cardinal;
  D2, D3: Word;
begin
  Guid := TGuid.NewGuid; // use OS to generate a random number
  SetLength(result, 20);
  D1 := Guid.D1;
  result[1] := GetBase62(D1 and $3F);
  D1 := D1 shr 6;
  result[2] := GetBase62(D1 and $3F);
  D1 := D1 shr 6;
  result[3] := GetBase62(D1 and $3F);
  D1 := D1 shr 6;
  result[4] := GetBase62(D1 and $3F);
  D1 := D1 shr 6;
  result[5] := GetBase62(D1 and $3F);
  D2 := Guid.D2;
  result[6] := GetBase62(D2 and $3F);
  D2 := D2 shr 6;
  result[7] := GetBase62(D2 and $3F);
  D2 := D2 shr 6;
  result[8] := GetBase62(D2 and $F + (Guid.D4[0] and $C0) shr 2);
  D3 := Guid.D3;
  result[9] := GetBase62(D3 and $3F);
  D3 := D3 shr 6;
  result[10] := GetBase62(D3 and $3F);
  D3 := D3 shr 6;
  result[11] := GetBase62(D3 and $F + (Guid.D4[1] and $C0) shr 2);
  result[12] := GetBase62(Guid.D4[0] and $3F);
  result[13] := GetBase62(Guid.D4[1] and $3F);
  result[14] := GetBase62(Guid.D4[2] and $3F);
  result[15] := GetBase62(Guid.D4[3] and $3F);
  result[16] := GetBase62(Guid.D4[4] and $3F);
  result[17] := GetBase62(Guid.D4[5] and $3F);
  result[18] := GetBase62(Guid.D4[6] and $3F);
  result[19] := GetBase62(Guid.D4[7] and $3F);
  result[20] := GetBase62((Guid.D4[5] and $C0) shr 6 +
    (Guid.D4[6] and $C0) shr 4 +
    (Guid.D4[7] and $C0));
end;

class function TFirebaseHelpers.ConvertIDtoGUID(const FBID: string): TGuid;
var
  c: integer;
  Base62: array[1..20] of byte;
  D1: cardinal;
  D2, D3: Word;
  D4a, D4b: cardinal;
begin
  for c := low(Base62) to high(Base62) do
    Base62[c] := 0; // Zero for ID that are shorter than 20
  for c := 1 to max(length(FBID), high(Base62)) do
    Base62[c] := pos(FBID[c], cBase62);
  D1 := Base62[1] + Base62[2] shl 6 + Base62[3] shl 12 + Base62[4] shl 18 +
    Base62[5] shl 24;
  D2 := Base62[6] and $7 + Base62[7] shl 3 + Base62[8] shl 9;
  D3 := (Base62[6] and $38) shr 3 + Base62[9] shl 3 + Base62[10] shl 9;
  D4a := Base62[11] + Base62[12] shl 6 + Base62[13] shl 12 + Base62[14] shl 18 +
    Base62[15] shl 24;
  D4b := Base62[16] + Base62[17] shl 6 + Base62[18] shl 12 + Base62[19] shl 18 +
    Base62[20] shl 24;
  result.D1 := D1; // 2 bits are missing
  result.D2 := D2; // 1 bit is missing
  result.D3 := D3; // 1 bit is missing
  result.D4[0] := D4a and $FF;
  result.D4[1] := (D4a shr 8) and $FF;
  result.D4[2] := (D4a shr 16) and $FF;
  result.D4[3] := (D4a shr 24) and $FF; // 2 bits are missing
  result.D4[4] := D4b and $FF;
  result.D4[5] := (D4b shr 8) and $FF;
  result.D4[6] := (D4b shr 16) and $FF;
  result.D4[7] := (D4b shr 24) and $FF; // 2 bits are missing
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
  States = (STATE_BEGIN, STATE_ATOM, STATE_QTEXT, STATE_QCHAR,
    STATE_QUOTE, STATE_LOCAL_PERIOD, STATE_EXPECTING_SUBDOMAIN,
    STATE_SUBDOMAIN, STATE_HYPHEN);
var
  State: States;
  i, subdomains: integer;
  c: char;
begin
  State := STATE_BEGIN;
  subdomains := 1;
  for i := low(email) to high(email) do
  begin
    c := email[i];
    case State of
      STATE_BEGIN:
        if IsAtomChars(c) then
          State := STATE_ATOM
        else if c = '"' then
          State := STATE_QTEXT
        else
          exit(false);
      STATE_ATOM:
        if c = '@' then
          State := STATE_EXPECTING_SUBDOMAIN
        else if c = '.' then
          State := STATE_LOCAL_PERIOD
        else if not IsAtomChars(c) then
          exit(false);
      STATE_QTEXT:
        if c = '\' then
          State := STATE_QCHAR
        else if c = '"' then
          State := STATE_QUOTE
        else if not IsQuotedStringChars(c) then
          exit(false);
      STATE_QCHAR:
        State := STATE_QTEXT;
      STATE_QUOTE:
        if c = '@' then
          State := STATE_EXPECTING_SUBDOMAIN
        else if c = '.' then
          State := STATE_LOCAL_PERIOD
        else
          exit(false);
      STATE_LOCAL_PERIOD:
        if  IsAtomChars(c) then
          State := STATE_ATOM
        else if c = '"' then
          State := STATE_QTEXT
        else
          exit(false);
      STATE_EXPECTING_SUBDOMAIN:
        if c.IsLetter then
          State := STATE_SUBDOMAIN
        else
          exit(false);
      STATE_SUBDOMAIN:
        if c = '.' then begin
          inc(subdomains);
          State := STATE_EXPECTING_SUBDOMAIN
        end else if c = '-' then
          State := STATE_HYPHEN
        else if not c.IsLetterOrDigit then
          exit((i = high(email)) and (subdomains >= 2));
      STATE_HYPHEN:
        if c.IsLetterOrDigit then
          State := STATE_SUBDOMAIN
        else if c <> '-' then
          exit(false);
    end;
  end;
  result := (State = STATE_SUBDOMAIN) and (subdomains >= 2);
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

function TJSONHelpers.GetArrayItem(const Name: string; Ind: integer): TJSONObject;
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
    Add(cGetQueryParamOrderBy, ['"' + FieldName + '"']);
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
