{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018 Christoph Schneider                                      }
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
  System.JSON, System.Generics.Collections;

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
    class function EncodeQueryParams(
      QueryParams: TDictionary<string, string>): string;
    class function EncodeQueryParamsWithToken(
      QueryParams: TDictionary<string, string>;
      const EncodedToken: string): string;
    class function EncodeResourceParams(ResourceParams: TStringDynArray): string;
    class function AddParamToResParams(ResourceParams: TStringDynArray;
      const Param: string): TStringDynArray;
    class function EncodeToken(const Token: string): string;
    class function ArrStrToCommaStr(Arr: array of string): string;
    class procedure Log(msg: string);
    class function AppIsTerminated: boolean;
    class procedure SleepAndMessageLoop(SleepInMs: cardinal);
    class procedure SimpleDownload(const DownloadUrl: string; Stream: TStream;
      OnSuccess: TOnSimpleDownloadSuccess;
      OnError: TOnSimpleDownloadError = nil);
    class function CreateAutoID: string;
    class function ConvertIDtoGUID(const FBID: string): TGuid;
    class function IsEMailAdress(const EMail: string): boolean;
  private
    const
      cBase62 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  end;

  TJSONHelpers = class helper for TJSONObject
    function GetStringValue(const Name: string): string;
    function GetIntegerValue(const Name: string): integer;
    function GetTimeStampValue(const Name: string): TDateTime;
  end;

resourcestring
  rsFBFailureIn = 'Firebase failure in %s: %s';

implementation

uses
{$IFDEF MSWINDOWS}
  WinAPI.Windows,
{$ELSE}
  FMX.Types,
{$ENDIF}
{$IFDEF FMX}
  FMX.Forms,
{$ENDIF}
{$IFDEF VCL}
  VCL.Forms,
{$ENDIF}
  System.DateUtils, System.NetEncoding, System.JSONConsts, System.Math,
  System.Net.HttpClient,
  IdGlobalProtocols;

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
  QueryParams: TDictionary<string, string>): string;
var
  Param: TPair<string, string>;
begin
  if (not assigned(QueryParams)) or not(QueryParams.Count > 0) then
    exit('');
  result := '?';
  for Param in QueryParams do
  begin
    if result <> '?' then
      result := result + '&';
    result := result + TNetEncoding.URL.Encode(Param.Key) + '=' +
      TNetEncoding.URL.Encode(Param.Value);
  end;
end;

class function TFirebaseHelpers.EncodeQueryParamsWithToken(
  QueryParams: TDictionary<string, string>; const EncodedToken: string): string;
var
  Param: TPair<string, string>;
begin
  result := '?auth=' + EncodedToken;
  if assigned(QueryParams) then
    for Param in QueryParams do
    begin
      result := result + '&' + TNetEncoding.URL.Encode(Param.Key) + '=' +
        TNetEncoding.URL.Encode(Param.Value);
    end;
end;

class function TFirebaseHelpers.EncodeResourceParams(
  ResourceParams: TStringDynArray): string;
var
  i: integer;
begin
  result := '';
  for i := low(ResourceParams) to high(ResourceParams) do
    result := result + '/' + TNetEncoding.URL.Encode(ResourceParams[i]);
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

class procedure TFirebaseHelpers.Log(msg: string);
begin
{$IFDEF MSWINDOWS}
  OutputDebugString(PChar(msg));
{$ELSE}
  FMX.Types.Log.d(msg, []);
  // there is a bug in DE 10.2 when the wrong method is calling?
{$ENDIF}
end;

class function TFirebaseHelpers.AddParamToResParams(
  ResourceParams: TStringDynArray; const Param: string): TStringDynArray;
var
  c: integer;
begin
  SetLength(result, length(ResourceParams) + 1);
  for c := low(ResourceParams) to high(ResourceParams) do
    result[c] := ResourceParams[c];
  result[length(ResourceParams)] := Param;
end;

class function TFirebaseHelpers.AppIsTerminated: boolean;
begin
  // In case of compiler error undeclared identifier 'application'
  // add '$(FrameworkType)' into the project settings as conditional defines
  // for the BASE configuration
  result := Application.Terminated;
end;

class procedure TFirebaseHelpers.SleepAndMessageLoop(SleepInMs: cardinal);
begin
  Application.ProcessMessages;
  Sleep(SleepInMs);
end;

class procedure TFirebaseHelpers.SimpleDownload(const DownloadUrl: string;
  Stream: TStream; OnSuccess: TOnSimpleDownloadSuccess;
  OnError: TOnSimpleDownloadError);
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
              TThread.Queue(nil,
                procedure
                begin
                  OnError(DownloadUrl, e.Message);
                end)
            else
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
    result := cBase62[b mod 62]; // reduce 64 to 62
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

{ TJSONHelpers }

function TJSONHelpers.GetIntegerValue(const Name: string): integer;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := Val.GetValue<integer>('integerValue')
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetStringValue(const Name: string): string;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := Val.GetValue<string>('stringValue')
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

function TJSONHelpers.GetTimeStampValue(const Name: string): TDateTime;
var
  Val: TJSONValue;
begin
  Val := GetValue(Name);
  if assigned(Val) then
    result := Val.GetValue<TDateTime>('timestampValue')
  else
    raise EJSONException.CreateFmt(SValueNotFound, [Name]);
end;

class function TFirebaseHelpers.IsEMailAdress(const EMail: string): boolean;
 // Returns True if the email address is valid
 // Author: Ernesto D'Spirito
const
  AtomChars = [#33..#255] -
    ['(', ')', '<', '>', '@', ',', ';', ':', '\', '/', '"', '.', '[', ']', #127];
  QuotedStringChars = [#0..#255] - ['"', #13, '\'];
  Letters = ['A'..'Z', 'a'..'z'];
  LettersDigits = ['0'..'9', 'A'..'Z', 'a'..'z'];
type
  States = (STATE_BEGIN, STATE_ATOM, STATE_QTEXT, STATE_QCHAR,
    STATE_QUOTE, STATE_LOCAL_PERIOD, STATE_EXPECTING_SUBDOMAIN,
    STATE_SUBDOMAIN, STATE_HYPHEN);
var
  State: States;
  i, n, subdomains: integer;
  c: char;
begin
  State := STATE_BEGIN;
  n := Length(email);
  i := 1;
  subdomains := 1;
  while i <= n do
  begin
    c := email[i];
    case State of
      STATE_BEGIN:
        if CharInSet(c, AtomChars) then
          State := STATE_ATOM
        else if c = '"' then
          State := STATE_QTEXT
        else
          break;
      STATE_ATOM:
        if c = '@' then
          State := STATE_EXPECTING_SUBDOMAIN
        else if c = '.' then
          State := STATE_LOCAL_PERIOD
        else if not CharInSet(c, AtomChars) then
          break;
      STATE_QTEXT:
        if c = '\' then
          State := STATE_QCHAR
        else if c = '"' then
          State := STATE_QUOTE
        else if not CharInSet(c, QuotedStringChars) then
          break;
      STATE_QCHAR:
        State := STATE_QTEXT;
      STATE_QUOTE:
        if c = '@' then
          State := STATE_EXPECTING_SUBDOMAIN
        else if c = '.' then
          State := STATE_LOCAL_PERIOD
        else
          break;
      STATE_LOCAL_PERIOD:
        if  CharInSet(c, AtomChars) then
          State := STATE_ATOM
        else if c = '"' then
          State := STATE_QTEXT
        else
          break;
      STATE_EXPECTING_SUBDOMAIN:
        if CharInSet(c, Letters) then
          State := STATE_SUBDOMAIN
        else
          break;
      STATE_SUBDOMAIN:
        if c = '.' then begin
          inc(subdomains);
          State := STATE_EXPECTING_SUBDOMAIN
        end else if c = '-' then
          State := STATE_HYPHEN
        else if not CharInSet(c, LettersDigits) then
          break;
      STATE_HYPHEN:
        if CharInSet(c, LettersDigits) then
          State := STATE_SUBDOMAIN
        else if c <> '-' then
          break;
    end;
    inc(i);
  end;
  if i <= n then
    result := false
  else
    result := (State = STATE_SUBDOMAIN) and (subdomains >= 2);
end;

end.
