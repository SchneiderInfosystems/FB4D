{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2025 Christoph Schneider                                 }
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

unit SymCrypto;

interface

uses
  System.Types, System.Classes, System.SysUtils, System.StrUtils,
  System.Win.WinRT,
  Winapi.Windows, Winapi.WinRT, Winapi.CommonTypes,
  Winapi.Security.Cryptography;

  // For more information about WinRTCrypto check also this open source project
  // https://github.com/SchneiderInfosystems/WinRTCrypto

type
  TSymmetricCrypto = class
  private
    fKeyAsBase64: string;
    fKey: Core_ICryptographicKey;
    fIV: IBuffer;
    const cDefaultAESKeySize = 256;
    function AesCbcPkcs7Algo: Core_ISymmetricKeyAlgorithmProvider;
    function EncodeAsBase64(Buf: IBuffer): string;
    function DecodeFromBase64(const Base64: string): IBuffer;
    function StrToIBuffer(const Text: string): IBuffer;
    function IBufferToStr(Buf: IBuffer): string;
  public
    constructor Create;
    destructor Destroy; override;
    function GenerateAESKey(KeySizeInBits: integer = cDefaultAESKeySize): string;
    procedure ImportAESKey(const KeyAsBase64: string);
    function EncryptToBase64(const ClearText, ID: string): string;
    function DecrytClearText(const EncryptedBase64, ID: string): string;
    property KeyAsBase64: string read fKeyAsBase64 write ImportAESKey;
  end;

implementation

uses
  WinApi.Storage.Streams,
  System.Win.ComObj, System.NetEncoding;

constructor TSymmetricCrypto.Create;
begin
  fKey := nil;
  fIV := nil;
end;

destructor TSymmetricCrypto.Destroy;
begin
  fKeyAsBase64 := StringOfChar('#', fKeyAsBase64.Length);  // Protect key in memory after free
  fKey := nil;
  fIV := nil;
  inherited;
end;

resourcestring
  rsNotApplicable = 'n/a';

function TSymmetricCrypto.EncodeAsBase64(Buf: IBuffer): string;
begin
  if not assigned(Buf) then
    exit(rsNotApplicable);
  result := TWindowsString.HStringToString(
    TCryptographicBuffer.EncodeToBase64String(Buf));
end;

function TSymmetricCrypto.DecodeFromBase64(const Base64: string): IBuffer;
begin
  if SameText(Base64, rsNotApplicable) then
    exit(nil);
  result := TCryptographicBuffer.DecodeFromBase64String(
    TWindowsString.Create(Base64));
end;

function TSymmetricCrypto.StrToIBuffer(const Text: string): IBuffer;
var
  data: TBytes;
begin
  data := TEncoding.UTF8.GetBytes(Text);
  result := TCryptographicBuffer.CreateFromByteArray(length(data), @data[0]);
end;

function TSymmetricCrypto.IBufferToStr(Buf: IBuffer): string;
begin
  result := TCryptographicBuffer.ConvertBinaryToString(
    BinaryStringEncoding.Utf8, Buf).ToString;
end;

function TSymmetricCrypto.GenerateAESKey(KeySizeInBits: integer): string;
var
  KeyMat: IBuffer;
  AES: Core_ISymmetricKeyAlgorithmProvider;
begin
  KeyMat := TCryptographicBuffer.GenerateRandom(KeySizeInBits div 8);
  fKeyAsBase64 := EncodeAsBase64(KeyMat);
  AES := AesCbcPkcs7Algo;
  fKey := AES.CreateSymmetricKey(KeyMat);
  result := fKeyAsBase64;
end;

procedure TSymmetricCrypto.ImportAESKey(const KeyAsBase64: string);
var
  KeyMat: IBuffer;
begin
  KeyMat := DecodeFromBase64(KeyAsBase64);
  fKeyAsBase64 := KeyAsBase64;
  fKey := AesCbcPkcs7Algo.CreateSymmetricKey(KeyMat);
end;

function TSymmetricCrypto.AesCbcPkcs7Algo: Core_ISymmetricKeyAlgorithmProvider;
begin
  result := TCore_SymmetricKeyAlgorithmProvider.OpenAlgorithm(
    TCore_SymmetricAlgorithmNames.AesCbcPkcs7);
end;

function TSymmetricCrypto.EncryptToBase64(const ClearText, ID: string): string;
var
  ClearData, Encrypted: IBuffer;
begin
  if ClearText.IsEmpty then
    exit('');
  Assert(assigned(fKey), 'Missing key in EncryptToBase64');
  ClearData := StrToIBuffer(ClearText);
  Encrypted := TCore_CryptographicEngine.Encrypt(fKey, ClearData, StrToIBuffer(ID));
  result := EncodeAsBase64(Encrypted);
end;

function TSymmetricCrypto.DecrytClearText(const EncryptedBase64, ID: string): string;
var
  ClearData, Encrypted: IBuffer;
begin
  if EncryptedBase64.IsEmpty then
    exit('');
  Assert(assigned(fKey), 'Missing key in DecrytClearText');
  Encrypted := DecodeFromBase64(EncryptedBase64);
  try
    ClearData := TCore_CryptographicEngine.Decrypt(fKey, Encrypted, StrToIBuffer(ID));
    result := IBufferToStr(ClearData);
  except
    on e: EOLEException do
      result := 'DecrytClearText failed: ' + e.Message;
  end;
end;

end.
