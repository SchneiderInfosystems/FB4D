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
    fAuth: IFirebaseAuthentication;
    fOnSucess: TOnFunctionSuccess;
    fOnError: TOnRequestError;
    function BaseURL: string;
    procedure OnResp(const RequestID: string; Response: IFirebaseResponse);
  public
    constructor Create(const ProjectID: string; Auth: IFirebaseAuthentication);
    procedure CallFunction(OnSuccess: TOnFunctionSuccess;
      OnRequestError: TOnRequestError; const FunctionName: string;
      Params: TJSONObject = nil);
    procedure CallFunctionSynchronous(const FunctionName: string;
      Params: TJSONObject = nil);
  end;

implementation

uses
  FB4D.Helpers;

const
  GOOGLE_CLOUD_FUNCTIONS_URL = 'https://us-central1-%s.cloudfunctions.net';

resourcestring
  rsFunctionCall = 'Function call %s';
  rsUnexpectedResult = 'Unexpected result of %s received: %s';

{ TFirestoreFunctions }

constructor TFirebaseFunctions.Create(const ProjectID: string;
  Auth: IFirebaseAuthentication);
begin
  inherited Create;
  fProjectID := ProjectID;
  fAuth := Auth;
end;

function TFirebaseFunctions.BaseURL: string;
begin
  result := Format(GOOGLE_CLOUD_FUNCTIONS_URL, [fProjectID]);
end;

procedure TFirebaseFunctions.CallFunction(OnSuccess: TOnFunctionSuccess;
  OnRequestError: TOnRequestError; const FunctionName: string;
  Params: TJSONObject);
var
  Request: IFirebaseRequest;
  Data: TJSONObject;
begin
  fOnSucess := OnSuccess;
  fOnError := OnRequestError;
  Data := TJSONObject.Create;
  try
    Data.AddPair('data', Params);
    Request := TFirebaseRequest.Create(BaseURL,
      Format(rsFunctionCall, [FunctionName]), fAuth);
    Request.SendRequest([FunctionName], rmPost, Data, nil, tmBearer,
      OnResp, OnRequestError);
  finally
    Data.Free;
  end;
end;

procedure TFirebaseFunctions.OnResp(const RequestID: string;
  Response: IFirebaseResponse);
var
  Msg: string;
  Obj, ResultObj: TJSONObject;
begin
  try
    if not Response.StatusOk then
    begin
      Msg := Response.ErrorMsg;
      if Msg.IsEmpty then
        Msg := Response.StatusText;
      if assigned(fOnError) then
        fOnError(RequestID, Msg);
    end else begin
      Obj := Response.GetContentAsJSONObj;
      try
        if Obj.TryGetValue('result', ResultObj) then
        begin
          if assigned(fOnSucess) then
            fOnSucess(RequestID, ResultObj);
        end else
          fOnError(RequestID, Format(rsUnexpectedResult,
            [RequestID, Response.ContentAsString]));
      finally
        Obj.Free;
      end;
    end;
  except
    on e: exception do
      if assigned(fOnError) then
        fOnError(RequestID, e.Message)
      else
        TFirebaseHelpers.Log('Exception in OnResponse: ' + e.Message);
  end;
end;

procedure TFirebaseFunctions.CallFunctionSynchronous(const FunctionName: string;
  Params: TJSONObject);
var
  Request: IFirebaseRequest;
  Response: IFirebaseResponse;
  Data: TJSONObject;
begin
  Data := TJSONObject.Create;
  try
    Data.AddPair('data', Params);
    Request := TFirebaseRequest.Create(BaseURL, '', fAuth);
    Response := Request.SendRequestSynchronous([FunctionName], rmPost, Data,
      nil, tmBearer);
    Response.CheckForJSONObj;
  finally
    Data.Free;
  end;
end;

end.
