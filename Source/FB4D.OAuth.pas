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
unit FB4D.OAuth;

interface

uses
  System.Classes, System.SysUtils, System.Types,
  System.JSON, System.JSON.Types,
  REST.Types,
  JOSE.Types.Bytes, JOSE.Context, JOSE.Core.JWT,
  FB4D.Interfaces;

type
  TTokenJWT = class(TInterfacedObject, ITokenJWT)
  private const
    cAuthTime = 'auth_time';
  private
    fContext: TJOSEContext;
    function GetPublicKey(const Id: string): TJOSEBytes;
  public
    constructor Create(const OAuthToken: string);
    destructor Destroy; override;
    function VerifySignature: boolean;
    function GetHeader: TJWTHeader;
    function GetClaims: TJWTClaims;
    function GetNoOfClaims: integer;
    function GetClaimName(Index: integer): string;
    function GetClaimValue(Index: integer): TJSONValue;
    function GetClaimValueAsStr(Index: integer): string;
  end;

implementation

uses
  System.Generics.Collections,
  JOSE.Core.JWS, JOSE.Signing.RSA,
  FB4D.Request, FB4D.Helpers;

{ TTokenJWT }

constructor TTokenJWT.Create(const OAuthToken: string);
var
  CompactToken: TJOSEBytes;
begin
  CompactToken.AsString := OAuthToken;
  fContext := TJOSEContext.Create(CompactToken, TJWTClaims);
  CompactToken.Clear;
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

function TTokenJWT.GetNoOfClaims: integer;
begin
  result := GetClaims.JSON.Count;
end;

function TTokenJWT.GetClaimName(Index: integer): string;
begin
  result := GetClaims.JSON.Pairs[Index].JsonString.Value;
end;

function TTokenJWT.GetClaimValue(Index: integer): TJSONValue;
begin
  result := GetClaims.JSON.Pairs[Index].JsonValue;
end;

function TTokenJWT.GetClaimValueAsStr(Index: integer): string;
var
  Val: TJSONValue;
  Name: string;
  TimeStamp: Int64;
begin
  Val := GetClaimValue(Index);
  Name := GetClaimName(Index);
  if (Name = TReservedClaimNames.ISSUED_AT) or
     (Name = TReservedClaimNames.EXPIRATION) or
     (Name = cAuthTime) then
  begin
    TimeStamp := StrToInt64Def(Val.Value, 0) * 1000;
    result := DateTimeToStr(TFirebaseHelpers.ConvertTimeStampToUTCDateTime(TimeStamp));
  end
  else if Val is TJSONString then
    result := Val.Value
  else
    result := Val.ToJSON;
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
  {$IFDEF IOS}
  result := false;
  // Unfortunately, this function is no longer available for iOS platform
  // For details check the following discussions
  // https://github.com/SchneiderInfosystems/FB4D/discussions/163
  // https://github.com/paolo-rossi/delphi-jose-jwt/issues/51
  {$ELSE}
  jws.SetKeyFromCert(PublicKey);
  result := jws.VerifySignature;
  {$ENDIF}
end;

end.
