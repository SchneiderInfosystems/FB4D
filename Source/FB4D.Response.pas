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

unit FB4D.Response;

interface

uses
  System.SysUtils, System.JSON,
  System.Net.HttpClient,
  REST.Client,
  FB4D.Interfaces;

type
  TFirebaseResponse = class(TInterfacedObject, IFirebaseResponse)
  private
    fHttpResp: IHTTPResponse;
    fRestResp: TRESTResponse;
    fOnError: TOnRequestError;
    fOnSuccess: TOnSuccess;
  public
    const
      ExceptOpNotAllowed = 'OPERATION_NOT_ALLOWED';
      ExceptTokenExpired = 'TOKEN_EXPIRED';
      ExceptUserDisabled = 'USER_DISABLED';
      ExceptUserNotFound = 'USER_NOT_FOUND';
      ExceptEmailNotFound = 'EMAIL_NOT_FOUND';
      ExceptExpiredOobCode = 'EXPIRED_OOB_CODE';
      ExceptInvalidOobCode = 'INVALID_OOB_CODE';
    constructor Create(HTTPResponse: IHTTPResponse); overload;
    constructor Create(RestResponse: TRESTResponse;
      OnError: TOnRequestError; OnSuccess: TOnSuccess); overload;

    function ContentAsString: string;
    function GetContentAsJSONObj: TJSONObject;
    function GetContentAsJSONArr: TJSONArray;
    function GetContentAsJSONVal: TJSONValue;
    function GetServerTime(TimeZone: TTimeZone): TDateTime;
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
    function GetOnError: TOnRequestError;
    function GetOnSuccess: TOnSuccess;
  end;

implementation

uses
  System.Generics.Collections,
  FB4D.Helpers;

resourcestring
  rsResponseIsNotJSON = 'The reponse from the firestore is not a JSON: %s';
  rsResponseIsNotJSONObj =
    'The reponse from the firestore is not a JSON object: %s';
  rsResponseIsNotJSONArr =
    'The reponse from the firestore is not a JSON array: %s';
  rsTimeZoneIsNotSupported = 'Time zone %d is not supported yet';

{ TFirestoreResponse }

constructor TFirebaseResponse.Create(HTTPResponse: IHTTPResponse);
begin
  inherited Create;
  fRestResp := nil;
  fHttpResp := HTTPResponse;
  fOnSuccess.Create(nil);
  fOnError := nil;
end;

constructor TFirebaseResponse.Create(RestResponse: TRESTResponse;
  OnError: TOnRequestError; OnSuccess: TOnSuccess);
begin
  inherited Create;
  fRestResp := RestResponse;
  fHttpResp := nil;
  fOnSuccess := OnSuccess;
  fOnError := OnError;
end;

function TFirebaseResponse.StatusCode: integer;
begin
  if assigned(fHttpResp) then
    result := fHttpResp.StatusCode
  else if assigned(fRestResp) then
    result := fRestResp.StatusCode
  else
    raise EFirebaseResponse.Create('No initialized response class');
end;

function TFirebaseResponse.StatusText: string;
begin
  if assigned(fHttpResp) then
    result := fHttpResp.StatusText
  else if assigned(fRestResp) then
    result := fRestResp.StatusText
  else
    raise EFirebaseResponse.Create('No initialized response class');
end;

function TFirebaseResponse.ContentAsString: string;
begin
  if assigned(fHttpResp) then
    result := fHttpResp.ContentAsString
  else if assigned(fRestResp) then
    result := fRestResp.Content
  else
    raise EFirebaseResponse.Create('No initialized response class');
end;

function TFirebaseResponse.StatusIsUnauthorized: boolean;
begin
  result := (StatusCode = 401) or (StatusCode = 403);
end;

function TFirebaseResponse.StatusNotFound: boolean;
begin
  result := StatusCode = 404;
end;

function TFirebaseResponse.StatusOk: boolean;
begin
  result := (StatusCode >= 200) and  (StatusCode < 300);
end;

procedure TFirebaseResponse.CheckForJSONObj;
var
  JSONValue: TJSONValue;
  Error, ErrMsg: TJSONValue;
begin
  JSONValue := TJSONObject.ParseJSONValue(ContentAsString);
  try
    if not Assigned(JSONValue) then
      raise EFirebaseResponse.CreateFmt(rsResponseIsNotJSON, [ContentAsString])
    else if not (JSONValue is TJSONObject) then
      raise EFirebaseResponse.CreateFmt(rsResponseIsNotJSONObj,
        [ContentAsString])
    else if (JSONValue as TJSONObject).TryGetValue('error', Error) and
      (Error.TryGetValue('message', ErrMsg)) then
      raise EFirebaseResponse.Create(ErrMsg.Value);
  finally
    JSONValue.Free;
  end;
end;

function TFirebaseResponse.ErrorMsg: string;
var
  JSONValue: TJSONValue;
  Error, ErrMsg: TJSONValue;
begin
  JSONValue := TJSONObject.ParseJSONValue(ContentAsString);
  try
    if not Assigned(JSONValue) then
      raise EFirebaseResponse.CreateFmt(rsResponseIsNotJSON, [ContentAsString])
    else if not (JSONValue is TJSONObject) then
      raise EFirebaseResponse.CreateFmt(rsResponseIsNotJSONObj,
        [ContentAsString])
    else if (JSONValue as TJSONObject).TryGetValue('error', Error) then
    begin
      if Error.TryGetValue('message', ErrMsg) then
        result := ErrMsg.Value
      else
        result := Error.Value;
    end else
      result := '';
  finally
    JSONValue.Free;
  end;
end;

function TFirebaseResponse.ErrorMsgOrStatusText: string;
var
  Cont: string;
  JSONValue: TJSONValue;
  Error, ErrMsg: TJSONValue;
begin
  result := StatusText;
  Cont := ContentAsString;
  if not Cont.IsEmpty then
  begin
    JSONValue := TJSONObject.ParseJSONValue(Cont);
    try
      if Assigned(JSONValue) and (JSONValue is TJSONObject) and
        (JSONValue as TJSONObject).TryGetValue('error', Error) then
      begin
        if Error.TryGetValue('message', ErrMsg) then
          result := ErrMsg.Value
        else if Error is TJSONString then
          result := Error.Value;
      end;
    finally
      JSONValue.Free;
    end;
  end;
end;

function TFirebaseResponse.IsJSONObj: boolean;
var
  JSONValue: TJSONValue;
  Error: TJSONValue;
begin
  JSONValue := TJSONObject.ParseJSONValue(ContentAsString);
  try
    if not Assigned(JSONValue) then
      result := false
    else if not (JSONValue is TJSONObject) then
      result := false
    else if (JSONValue as TJSONObject).TryGetValue('error', Error) then
      result := false
    else
      result := true;
  finally
    JSONValue.Free;
  end;
end;

procedure TFirebaseResponse.CheckForJSONArr;
var
  JSONValue: TJSONValue;
  Error, ErrMsg: TJSONValue;
begin
  JSONValue := TJSONObject.ParseJSONValue(ContentAsString);
  try
    if not Assigned(JSONValue) then
      raise EFirebaseResponse.CreateFmt(rsResponseIsNotJSON, [ContentAsString])
    else if not (JSONValue is TJSONArray) then
      raise EFirebaseResponse.CreateFmt(rsResponseIsNotJSONArr,
        [ContentAsString])
    else if (JSONValue as TJSONArray).Count < 1 then
      raise EFirebaseResponse.CreateFmt(rsResponseIsNotJSONArr,
        [ContentAsString])
    else if (JSONValue as TJSONArray).Items[0].TryGetValue('error', Error) then
    begin
      if Error.TryGetValue('message', ErrMsg) then
        raise EFirebaseResponse.Create(ErrMsg.Value)
      else
        raise EFirebaseResponse.Create(Error.Value);
    end;
  finally
    JSONValue.Free;
  end;
end;

function TFirebaseResponse.GetContentAsJSONObj: TJSONObject;
begin
  result := TJSONObject.ParseJSONValue(ContentAsString) as TJSONObject;
end;

function TFirebaseResponse.GetContentAsJSONVal: TJSONValue;
begin
  result := TJSONObject.ParseJSONValue(ContentAsString);
end;

function TFirebaseResponse.GetContentAsJSONArr: TJSONArray;
begin
  result := TJSONObject.ParseJSONValue(ContentAsString) as TJSONArray;
end;

function TFirebaseResponse.GetServerTime(TimeZone: TTimeZone): TDateTime;
const
  cInitialDate: double = 0;
var
  ServerDate: string;
begin
  result := TDateTime(cInitialDate);
  if assigned(fHttpResp) then
    ServerDate := fHttpResp.HeaderValue['Date']
  else if assigned(fRestResp) then
    ServerDate := fRestResp.Headers.Values['Date']
  else
    raise EFirebaseResponse.Create('No initialized response class');
  case TimeZone of
    tzUTC:
      result := TFirebaseHelpers.ConvertRFC5322ToUTCDateTime(ServerDate);
    tzLocalTime:
      result := TFirebaseHelpers.ConvertRFC5322ToLocalDateTime(ServerDate);
    else
      EFirebaseResponse.CreateFmt(rsTimeZoneIsNotSupported, [Ord(TimeZone)]);
  end;
end;

function TFirebaseResponse.GetOnError: TOnRequestError;
begin
  result := fOnError;
end;

function TFirebaseResponse.GetOnSuccess: TOnSuccess;
begin
  result := fOnSuccess;
end;

end.
