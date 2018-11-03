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

program DemoFB4D;

{$WARN DUPLICATE_CTOR_DTOR OFF}

uses
  {$IFDEF DEBUG}
  FastMM4,
  {$ENDIF }
  System.StartUpCopy,
  FMX.Forms,
  FB4D.DemoFmx in 'FB4D.DemoFmx.pas' {fmxFirebaseDemo},
  FB4D.Interfaces in '..\..\Source\FB4D.Interfaces.pas',
  FB4D.Authentication in '..\..\Source\FB4D.Authentication.pas',
  FB4D.OAuth in '..\..\Source\FB4D.OAuth.pas',
  FB4D.Response in '..\..\Source\FB4D.Response.pas',
  FB4D.Request in '..\..\Source\FB4D.Request.pas',
  FB4D.Firestore in '..\..\Source\FB4D.Firestore.pas',
  FB4D.Document in '..\..\Source\FB4D.Document.pas',
  FB4D.Functions in '..\..\Source\FB4D.Functions.pas',
  FB4D.Helpers in '..\..\Source\FB4D.Helpers.pas',
  FB4D.Storage in '..\..\Source\FB4D.Storage.pas',
  FB4D.RealTimeDB in '..\..\Source\FB4D.RealTimeDB.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TfmxFirebaseDemo, fmxFirebaseDemo);
  Application.Run;
end.
