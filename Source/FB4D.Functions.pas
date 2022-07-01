{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2022 Christoph Schneider                                 }
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

unit FB4D.Functions;

interface

uses
  System.Classes, System.JSON, System.SysUtils,
  System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request;

type
  TFirebaseFunctions = class(TInterfacedObject, IFirebaseFunctions)
  private
    fProjectID: string;
    fServerRegion: string;
    fAuth: IFirebaseAuthentication;
    function BaseURL: string;
    procedure OnResp(const RequestID: string; Response: IFirebaseResponse);
  public
    constructor Create(const ProjectID: string;
      Auth: IFirebaseAuthentication = nil;
      const ServerRegion: string = cRegionUSCent1);
    procedure CallFunction(OnSuccess: TOnFunctionSuccess;
      OnRequestError: TOnRequestError; const FunctionName: string;
      Params: TJSONObject = nil);
    function CallFunctionSynchronous(const FunctionName: string;
      Params: TJSONObject = nil): TJSONObject;
  end;

implementation

uses
  FB4D.Helpers;

const
  GOOGLE_CLOUD_FUNCTIONS_URL = 'https://%s-%s.cloudfunctions.net';

resourcestring
  rsFunctionCall = 'Function call %s';
  rsUnexpectedResult = 'Unexpected result of %s received: %s';

{ TFirestoreFunctions }

constructor TFirebaseFunctions.Create(const ProjectID: string;
  Auth: IFirebaseAuthentication; const ServerRegion: string);
begin
  inherited Create;
  fProjectID := ProjectID;
  fAuth := Auth;
  fServerRegion := ServerRegion;
end;

function TFirebaseFunctions.BaseURL: string;
begin
  result := Format(GOOGLE_CLOUD_FUNCTIONS_URL, [fServerRegion, fProjectID]);
end;

procedure TFirebaseFunctions.CallFunction(OnSuccess: TOnFunctionSuccess;
  OnRequestError: TOnRequestError; const FunctionName: string;
  Params: TJSONObject);
var
  Request: IFirebaseRequest;
  Data: TJSONObject;
begin
  Data := TJSONObject.Create;
  try
    Data.AddPair('data', Params);
    Request := TFirebaseRequest.Create(BaseURL,
      Format(rsFunctionCall, [FunctionName]), fAuth);
    Request.SendRequest([FunctionName], rmPost, Data, nil, tmBearer,
      OnResp, OnRequestError, TOnSuccess.CreateFunctionSuccess(OnSuccess));
  finally
    Data.Free;
  end;
end;

procedure TFirebaseFunctions.OnResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  Msg: string;
  ResultVal: TJSONValue;
  Obj, ResultObj: TJSONObject;
begin
  try
    if not Response.StatusOk then
    begin
      Msg := Response.ErrorMsg;
      if Msg.IsEmpty then
        Msg := Response.StatusText;
      if assigned(Response.OnError) then
        Response.OnError(RequestID, Msg);
    end else begin
      Obj := Response.GetContentAsJSONObj;
      try
        if Obj.TryGetValue('result', ResultVal) and
           assigned(Response.OnSuccess.OnFunctionSuccess) then
        begin
          if ResultVal is TJSONObject then
          begin
            ResultObj := ResultVal as TJSONObject;
            Response.OnSuccess.OnFunctionSuccess(RequestID, ResultObj);
          end
          else if ResultVal is TJSONArray then
          begin
            ResultObj := TJSONObject.Create(
              TJSONPair.Create('result', ResultVal as TJSONArray));
            Response.OnSuccess.OnFunctionSuccess(RequestID, ResultObj);
          end else begin
            if assigned(Response.OnError) then
              Response.OnError(RequestID, Format(rsUnexpectedResult,
                [RequestID, Response.ContentAsString]));
          end;
        end
        else if assigned(Response.OnError) then
          Response.OnError(RequestID, Format(rsUnexpectedResult,
            [RequestID, Response.ContentAsString]));
      finally
        Obj.Free;
      end;
    end;
  except
    on e: exception do
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log('Exception in OnResponse: ' + e.Message);
  end;
end;

function TFirebaseFunctions.CallFunctionSynchronous(const FunctionName: string;
  Params: TJSONObject): TJSONObject;
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  Data: TJSONObject;
  Obj: TJSONObject;
  ResultVal: TJSONValue;
begin
  Data := TJSONObject.Create;
  try
    Data.AddPair('data', Params);
    Request := TFirebaseRequest.Create(BaseURL, '', fAuth);
    Response := Request.SendRequestSynchronous([FunctionName], rmPost, Data,
      nil, tmBearer);
    Response.CheckForJSONObj;
    Obj := Response.GetContentAsJSONObj;
    try
      if not Obj.TryGetValue('result', ResultVal) then
        raise EFirebaseFunctions.CreateFmt(rsUnexpectedResult,
          [FunctionName, Obj.ToJSON])
      else if ResultVal is TJSONObject then
        result := ResultVal.Clone as TJSONObject
      else if ResultVal is TJSONArray then
        result := TJSONObject.Create(
          TJSONPair.Create('result', ResultVal.Clone as TJSONArray))
      else
        raise EFirebaseFunctions.CreateFmt(rsUnexpectedResult,
          [FunctionName, Obj.ToJSON])
    finally
      Obj.Free;
    end;
  finally
    Data.Free;
  end;
end;

end.
