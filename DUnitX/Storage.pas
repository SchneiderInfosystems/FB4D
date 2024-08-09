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

unit Storage;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Hash, System.NetEncoding,
  DUnitX.TestFramework,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request, FB4D.Storage;

{$M+}
type
  [TestFixture]
  UT_FirebaseStorage = class
  strict private
    fStorage: TFirebaseStorage;
  public
    [Setup]
    procedure SetUp;
    [TearDown]
    procedure TearDown;
  published
    procedure TestSynchronousUploadDownload;
  end;

implementation

{$I FBConfig.inc}

procedure UT_FirebaseStorage.SetUp;
begin
  fStorage := TFirebaseStorage.Create(cBucket, nil);
end;

procedure UT_FirebaseStorage.TearDown;
begin
  FreeAndNil(fStorage);
end;

procedure UT_FirebaseStorage.TestSynchronousUploadDownload;
const
  cObjName = 'TestObj.ini';
var
  FileStream: TFileStream;
  MemoryStream: TMemoryStream;
  Obj, Obj2, Obj3: IStorageObject;
begin
  FileStream := TFileStream.Create(ChangeFileExt(ParamStr(0), '.ini'), fmOpenRead);
  try
    Obj := fStorage.UploadSynchronousFromStream(FileStream, cObjName, ctTEXT_PLAIN);
  finally
    FileStream.Free;
  end;
  Assert.AreEqual(Obj.ObjectName(false), cObjName);
  Assert.AreEqual(Obj.Path, '');

  Obj2 := fStorage.GetSynchronous(cObjName);
  Assert.AreEqual(Obj.ObjectName, Obj2.ObjectName);
  Assert.AreEqual(Obj.ContentType, Obj2.ContentType);
  Assert.AreEqual(Obj.MD5HashCode, Obj2.MD5HashCode);
  Status('Download URL: ' + Obj.DownloadUrl);

  MemoryStream := TMemoryStream.Create;
  try
    Obj3 := fStorage.GetAndDownloadSynchronous(cObjName, MemoryStream);
    MemoryStream.Position := 0;
    Assert.AreEqual(Obj.MD5HashCode, TNetEncoding.Base64.EncodeBytesToString(THashMD5.GetHashBytes(MemoryStream)), 'MD5 Hash not identical');
    Status('MD5 Hash code compared between uploaded and downloaded object');
  finally
    MemoryStream.Free;
  end;
  Assert.AreEqual(Obj.ObjectName, Obj3.ObjectName);
  Assert.AreEqual(Obj.ContentType, Obj3.ContentType);
  Assert.AreEqual(Obj.MD5HashCode, Obj3.MD5HashCode);

  fStorage.DeleteSynchronous(cObjName);
  Status(cObjName + ' deleted');
  Assert.WillRaise(
    procedure
    begin
      fStorage.GetSynchronous(cObjName);
    end,
    EFirebaseResponse, 'Not Found. Could not get object');
end;

initialization
  TDUnitX.RegisterTestFixture(UT_FirebaseStorage);
end.

