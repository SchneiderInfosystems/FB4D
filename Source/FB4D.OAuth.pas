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
unit FB4D.OAuth;

interface

uses
  System.Classes, System.SysUtils,
  System.JSON, System.JSON.Types,
  REST.Types,
  JOSE.Types.Bytes, JOSE.Context, JOSE.Core.JWT,
  FB4D.Interfaces;

type
  TTokenJWT = class(TInterfacedObject, ITokenJWT)
  private
    fContext: TJOSEContext;
    function GetPublicKey(const Id: string): TJOSEBytes;
  public
    constructor Create(const OAuthToken: string);
    destructor Destroy; override;
    function VerifySignature: boolean;
    function GetHeader: TJWTHeader;
    function GetClaims: TJWTClaims;
  end;

implementation

uses
  JOSE.Core.JWS, JOSE.Signing.RSA,
  FB4D.Request;

{ TTokenJWT }

constructor TTokenJWT.Create(const OAuthToken: string);
var
  CompactToken: TJOSEBytes;

begin
  CompactToken.AsString := OAuthToken;
  fContext := TJOSEContext.Create(CompactToken, TJWTClaims);
end;

destructor TTokenJWT.Destroy;
begin
  fContext.Free;
  inherited;
end;

function TTokenJWT.GetPublicKey(const Id: string): TJOSEBytes;
const
  GOOGLE_x509 = 'https://www.googleapis.com/robot/v1/metadata/x509';
  SToken = 'securetoken@system.gserviceaccount.com';
var
  ARequest: TFirebaseRequest;
  AResponse: IFirebaseResponse;
  JSONObj: TJSONObject;
  c: integer;
begin
  result.Empty;
  ARequest := TFirebaseRequest.Create(GOOGLE_x509, 'GetPublicKey');
  JSONObj := nil;
  try
    AResponse := ARequest.SendRequestSynchronous([SToken], rmGet, nil, nil,
      tmNoToken);
    JSONObj := TJSONObject.ParseJSONValue(AResponse.ContentAsString) as
      TJSONObject;
    for c := 0 to JSONObj.Count-1 do
      if SameText(JSONObj.Pairs[c].JsonString.Value, Id) then
        result.AsString := JSONObj.Pairs[c].JsonValue.Value;
    if result.IsEmpty then
      raise ETokenJWT.Create('kid not found: ' + Id);
  finally
    JSONObj.Free;
    AResponse := nil;
    ARequest.Free;
  end;
end;

function TTokenJWT.GetClaims: TJWTClaims;
begin
  result := fContext.GetClaims;
end;

function TTokenJWT.GetHeader: TJWTHeader;
begin
  result := fContext.GetHeader;
end;

function TTokenJWT.VerifySignature: boolean;
var
  PublicKey: TJOSEBytes;
  jws: TJWS;
begin
  jws := fContext.GetJOSEObject<TJWS>;
  PublicKey := GetPublicKey(GetHeader.JSON.GetValue('kid').Value);
  jws.SetKey(PublicKey);
  result := jws.VerifySignature;
end;

end.
