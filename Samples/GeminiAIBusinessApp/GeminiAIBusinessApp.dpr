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

program GeminiAIBusinessApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainFmx in 'MainFmx.pas' {fmxMain},
  FB4D.Interfaces in '..\..\Source\FB4D.Interfaces.pas',
  FB4D.VisionMLDefinition in '..\..\Source\FB4D.VisionMLDefinition.pas',
  FB4D.GeminiAI in '..\..\Source\FB4D.GeminiAI.pas',
  FB4D.Helpers in '..\..\Source\FB4D.Helpers.pas',
  FB4D.Request in '..\..\Source\FB4D.Request.pas',
  FB4D.Response in '..\..\Source\FB4D.Response.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmxMain, fmxMain);
  Application.Run;
end.
