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

unit RealTimeDB;

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  DUnitX.TestFramework,
  FB4D.Interfaces;

{$M+}
type
  [TestFixture]
  UT_RealTimeDB = class(TObject)
  private
    fConfig: IFirebaseConfiguration;
    fErrMsg: string;
    fReqID: string;
    fInfo: string;
    fData: TJSONObject;
    fCallBack: boolean;
    fRes: TJSONValue;
    fFirebaseEvent: IFirebaseEvent;
    procedure OnPutGet(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnError(const RequestID, ErrMsg: string);
    procedure OnReceive(const Event: string; Params: TRequestResourceParam; JSONObj: TJSONObject);
    procedure OnStop(Sender: TObject);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    [TestCase]
    procedure PutGetSynchronous;
    procedure PutGet;
    procedure GetResourceParamListener;
  end;

implementation

uses
  VCL.Forms,
  FB4D.Configuration,
  Consts;

{$I FBConfig.inc}

const
  cDBPath: TRequestResourceParam = ['TestNode', '1234'];

{ UT_RealTimeDB }

procedure UT_RealTimeDB.Setup;
begin
  fConfig := TFirebaseConfiguration.Create(cApiKey, cProjectID, cBucket);
  fConfig.Auth.SignUpWithEmailAndPasswordSynchronous(cEmail, cPassword);
  fErrMsg := '';
  fReqID := '';
  fInfo := '';
  fData := TJSONObject.Create;
  fCallBack := false;
end;

procedure UT_RealTimeDB.TearDown;
begin
  if Assigned(fFirebaseEvent) and (not fFirebaseEvent.IsStopped) then
    fFirebaseEvent.StopListening;

  fConfig.RealTimeDB.DeleteSynchronous(cDBPath);
  fData.Free;
  fConfig.Auth.DeleteCurrentUserSynchronous;
  fConfig := nil;
end;

procedure UT_RealTimeDB.GetResourceParamListener;
var
  Res: TJSONValue;
  DBPath: string;
  ResourcePath: string;
begin
  Status('Put single value');
  fData.AddPair('Item1', 'TestVal1');
  Res := fConfig.RealTimeDB.PutSynchronous(cDBPath, fData);
  Assert.IsNotNull(res, 'Result of Put is nil');
  Assert.AreEqual(fData.ToJSON, Res.ToJSON,
    'result JSON is different from put');
  Res.Free;

  Status('Listen value');
  fFirebaseEvent := fConfig.RealTimeDB.ListenForValueEvents(cDBPath,
    OnReceive, OnStop, OnError);

  sleep(1); //give time to the thread create fAsyncResult object

  Assert.IsNotNull(fFirebaseEvent.GetResourceParams);
  ResourcePath := string.Join('/', fFirebaseEvent.GetResourceParams);
  DbPath := string.Join('/', cDBPath);
  Assert.AreEqual(DBPath, ResourcePath,
    'ResourceParams is different from the listened');
end;

procedure UT_RealTimeDB.OnReceive(const Event: string; Params:
  TRequestResourceParam; JSONObj: TJSONObject);
begin
  fCallBack := true;
end;

procedure UT_RealTimeDB.OnStop(Sender: TObject);
begin

end;

procedure UT_RealTimeDB.OnError(const RequestID, ErrMsg: string);
begin
  fReqID := RequestID;
  fErrMsg := ErrMsg;
  fCallBack := true;
end;

procedure UT_RealTimeDB.OnPutGet(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  fRes := Val.Clone as TJSONValue;
  fCallBack := true;
end;

procedure UT_RealTimeDB.PutGetSynchronous;
var
  Res: TJSONValue;
begin
  Status('Put single value');
  fData.AddPair('Item1', 'TestVal1');
  Res := fConfig.RealTimeDB.PutSynchronous(cDBPath, fData);
  Assert.IsNotNull(res, 'Result of Put is nil');
  Assert.AreEqual(fData.ToJSON, Res.ToJSON, 'result JSON is different from put');
  Res.Free;

  Status('Get single value');
  Res := fConfig.RealTimeDB.GetSynchronous(cDBPath);
  Assert.IsNotNull(res, 'Result of Get is nil');
  Assert.AreEqual(fData.ToJSON, Res.ToJSON,
    'result JSON is different between get and put');
  Res.Free;

  Status('Put simple object value');
  fData.AddPair('Item2', TJSONNumber.Create(3.14));
  Res := fConfig.RealTimeDB.PutSynchronous(cDBPath, fData);
  Assert.IsNotNull(res, 'Result is nil');
  Assert.AreEqual(fData.ToJSON, Res.ToJSON, 'resul JSON is different from put');
  Res.Free;

  Status('Get single object value');
  Res := fConfig.RealTimeDB.GetSynchronous(cDBPath);
  Assert.IsNotNull(res, 'Result of Get is nil');
  Assert.AreEqual(fData.ToJSON, Res.ToJSON,
    'result JSON is different between get and put');
  Res.Free;

  Status('Put complex object value');
  fData.AddPair('Item3', TJSONObject.Create(TJSONPair.Create('SubItem',
    'TestSubItem')));
  Res := fConfig.RealTimeDB.PutSynchronous(cDBPath, fData);
  Assert.IsNotNull(res, 'Result is nil');
  Assert.AreEqual(fData.ToJSON, Res.ToJSON, 'result JSON is different from put');
  Res.Free;

  Status('Get complex object value');
  Res := fConfig.RealTimeDB.GetSynchronous(cDBPath);
  Assert.IsNotNull(res, 'Result of Get is nil');
  Assert.AreEqual(fData.ToJSON, Res.ToJSON,
    'result JSON is different between get and put');
  Res.Free;
end;

procedure UT_RealTimeDB.PutGet;
begin
  Status('Put single value');
  fData.AddPair('Item1', 'TestVal1');
  fConfig.RealTimeDB.Put(cDBPath, fData, OnPutGet, OnError);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result of Put is nil');
  Assert.AreEqual(fData.ToJSON, fRes.ToJSON, 'result JSON is different from put');
  FreeAndNil(fRes);

  Status('Get single value');
  fCallBack := false;
  fConfig.RealTimeDB.Get(cDBPath, OnPutGet, OnError);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result of Get is nil');
  Assert.AreEqual(fData.ToJSON, fRes.ToJSON,
    'result JSON is different between get and put');
  FreeAndNil(fRes);

  Status('Put simple object value');
  fData.AddPair('Item2', TJSONNumber.Create(3.14));
  fCallBack := false;
  fConfig.RealTimeDB.Put(cDBPath, fData, OnPutGet, OnError);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result of Put is nil');
  Assert.AreEqual(fData.ToJSON, fRes.ToJSON, 'resul JSON is different from put');
  FreeAndNil(fRes);

  Status('Get single object value');
  fCallBack := false;
  fConfig.RealTimeDB.Get(cDBPath, OnPutGet, OnError);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result of Get is nil');
  Assert.AreEqual(fData.ToJSON, fRes.ToJSON,
    'result JSON is different between get and put');
  FreeAndNil(fRes);

  Status('Put complex object value');
  fData.AddPair('Item3', TJSONObject.Create(TJSONPair.Create('SubItem',
    'TestSubItem')));
  fCallBack := false;
  fConfig.RealTimeDB.Put(cDBPath, fData, OnPutGet, OnError);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result is nil');
  Assert.AreEqual(fData.ToJSON, fRes.ToJSON,
    'result JSON is different from put');
  FreeAndNil(fRes);

  Status('Get complex object value');
  fCallBack := false;
  fConfig.RealTimeDB.Get(cDBPath, OnPutGet, OnError);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result of Get is nil');
  Assert.AreEqual(fData.ToJSON, fRes.ToJSON,
    'result JSON is different between get and put');
  FreeAndNil(fRes);
end;

initialization
  TDUnitX.RegisterTestFixture(UT_RealTimeDB);
end.
