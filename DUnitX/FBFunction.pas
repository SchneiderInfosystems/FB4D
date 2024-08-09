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

unit FBFunction;

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  DUnitX.TestFramework,
  FB4D.Interfaces;

{$M+}
type
  [TestFixture]
  UT_FBFunction = class(TObject)
  private
    fConfig: IFirebaseConfiguration;
    fErrMsg: string;
    fReqID: string;
    fRes: TJSONObject;
    fCallBack: boolean;
    procedure OnSucc(const Info: string; ResultObj: TJSONObject);
    procedure OnError(const RequestID, ErrMsg: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    procedure CallSynchFuncDoTest;
    procedure CallAsynchFuncDoTest;
    procedure CallSynchFuncDoTest2;
    procedure CallAsynchFuncDoTest2;
  end;

implementation

uses
  VCL.Forms,
  FB4D.Configuration,
  Consts;

{$I FBConfig.inc}

procedure UT_FBFunction.Setup;
begin
  fConfig := TFirebaseConfiguration.Create(cApiKey, cProjectID, cBucket);
  fErrMsg := '';
  fReqID := '';
  fCallBack := false;
end;

procedure UT_FBFunction.TearDown;
begin
  fConfig := nil;
end;

procedure UT_FBFunction.OnError(const RequestID, ErrMsg: string);
begin
  fErrMsg := '';
  fCallBack := true;
  Status('Error: ' + fErrMsg);
end;

procedure UT_FBFunction.OnSucc(const Info: string; ResultObj: TJSONObject);
begin
  fRes := ResultObj.Clone as TJSONObject;
  Status(fRes.ToJSON);
  fCallBack := true;
end;

procedure UT_FBFunction.CallSynchFuncDoTest;
const
  cStrTest = 'UnitTest Function';
var
  Data, Res: TJSONObject;
begin
  Data := TJSONObject.Create;
  Res := nil;
  try
    Data.AddPair('strTest', cStrTest);
    Res := fConfig.Functions.CallFunctionSynchronous('doTest', Data);
    Status(Res.ToJSON);
    Assert.AreEqual(Res.GetValue<string>('res'), cStrTest.ToUpper);
  finally
    Res.Free;
  end;
end;

procedure UT_FBFunction.CallAsynchFuncDoTest;
const
  cStrTest = 'UnitTest-Function2 with unicode emoticons ✌';
var
  Data: TJSONObject;
begin
  Data := TJSONObject.Create;
  Data.AddPair('strTest', cStrTest);
  fConfig.Functions.CallFunction(OnSucc, OnError, 'doTest', Data);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result of CallFunction is nil');
  Assert.AreEqual(fRes.GetValue<string>('res'), cStrTest.ToUpper);
end;

procedure UT_FBFunction.CallSynchFuncDoTest2;
const
  op1 = 13;
  op2 = 4;
var
  Data, Res: TJSONObject;
begin
  Data := TJSONObject.Create;
  Res := nil;
  try
    Data.AddPair('op1', TJSONNumber.Create(op1));
    Data.AddPair('op2', TJSONNumber.Create(op2));
    Res := fConfig.Functions.CallFunctionSynchronous('doTest2', Data);
    Status(Res.ToJSON);
    Assert.AreEqual(Res.GetValue<integer>('res'), op1 + op2);
  finally
    Res.Free;
  end;
end;

procedure UT_FBFunction.CallAsynchFuncDoTest2;
const
  op1 = 4711;
  op2 = 13243;
var
  Data: TJSONObject;
begin
  Data := TJSONObject.Create;
  Data.AddPair('op1', TJSONNumber.Create(op1));
  Data.AddPair('op2', TJSONNumber.Create(op2));
  fConfig.Functions.CallFunction(OnSucc, OnError, 'doTest2', Data);
  while not fCallBack do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsNotNull(fRes, 'Result of CallFunction is nil');
  Assert.AreEqual(fRes.GetValue<integer>('res'), op1 + op2);
end;

initialization
  TDUnitX.RegisterTestFixture(UT_FBFunction);
end.
