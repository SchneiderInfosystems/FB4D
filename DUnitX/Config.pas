{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2021 Christoph Schneider                                 }
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

unit Config;

interface

uses
  System.Classes, System.SysUtils,
  DUnitX.TestFramework,
  FB4D.Interfaces;

{$M+}
type
  [TestFixture]
  UT_Config = class(TObject)
  private
    fConfig: IFirebaseConfiguration;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    [TestCase]
    procedure CheckConfig;
  end;

implementation

uses
  FB4D.Configuration;

{$I FBConfig.inc}

{ UT_Config }

procedure UT_Config.Setup;
begin
  fConfig := TFirebaseConfiguration.Create(cApiKey, cProjectID, cBucket);
end;

procedure UT_Config.TearDown;
begin
  fConfig := nil;
end;

procedure UT_Config.CheckConfig;
begin
  Assert.AreEqual(fConfig.ProjectID, cProjectID);
  Assert.IsNotNull(fConfig.Auth);
  Assert.IsNotNull(fConfig.RealTimeDB);
  Assert.IsNotNull(fConfig.Database);
  Assert.IsNotNull(fConfig.Storage);
  Assert.IsNotNull(fConfig.Functions);
  Status('Passed for ' + TFirebaseConfiguration.GetLibVersionInfo);
end;

initialization
  TDUnitX.RegisterTestFixture(UT_Config);
end.
