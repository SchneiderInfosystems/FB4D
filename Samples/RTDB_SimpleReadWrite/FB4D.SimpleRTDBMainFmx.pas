{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2020 Christoph Schneider                                 }
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

unit FB4D.SimpleRTDBMainFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit,
  FB4D.Interfaces, FB4D.Configuration;

type
  TFmxSimpleReadWrite = class(TForm)
    edtDBMessage: TEdit;
    btnWrite: TButton;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
    procedure edtDBMessageChangeTracking(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    procedure DBEvent(const Event: string; Params: TRequestResourceParam;
      JSONObj: TJSONObject);
    procedure DBError(const RequestID, ErrMsg: string);
    procedure DBWritten(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnDBStop(Sender: TObject);
  end;

var
  FmxSimpleReadWrite: TFmxSimpleReadWrite;

implementation

uses
  FB4D.Helpers, FB4D.RealTimeDB;

{$R *.fmx}

resourcestring
  rsHintRTDBRules =
    'Hint to permission error: ' +
    'Before you can write into the real time database add the following ' +
    'text in the Firebase console as rule for the Realtime Database:'#13 +
    '  {"rules": {"Message": {".read": true,".write": true}}}'#13;

const
  GoogleServiceJSON = '..\..\..\google-services.json';
// Alternative way by entering
//  ApiKey = '<Your Firebase ApiKey listed in the Firebase Console>';
//  ProjectID = '<Your Porject ID listed in the Firebase Console>';
//  FirebaseURL = '<The URL of your RealTime DB from the Firebase Console>';
  DBPath: TRequestResourceParam = ['Message'];

procedure TFmxSimpleReadWrite.FormCreate(Sender: TObject);
begin
  fConfig := TFirebaseConfiguration.Create(GoogleServiceJSON);
//  fConfig := TFirebaseConfiguration.Create(ApiKey, ProjectID, '', FirebaseURL);
  fConfig.RealTimeDB.ListenForValueEvents(DBPath, DBEvent, OnDBStop, DBError, nil);
  lblStatus.Text := 'Firebase RT DB connected';
  btnWrite.Enabled := false;
end;

procedure TFmxSimpleReadWrite.OnDBStop(Sender: TObject);
begin
  Caption := 'DB Listener was stopped - restart App';
end;

procedure TFmxSimpleReadWrite.DBEvent(const Event: string;
  Params: TRequestResourceParam; JSONObj: TJSONObject);
begin
  if Event = cEventPut then
  begin
    edtDBMessage.Text := JSONObj.GetValue<string>(cData);
    btnWrite.Enabled := false;
    lblStatus.Text := 'Last read: ' + DateTimeToStr(now);
  end;
end;

procedure TFmxSimpleReadWrite.DBWritten(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  lblStatus.Text := 'Last write: ' + DateTimeToStr(now);
end;

procedure TFmxSimpleReadWrite.DBError(const RequestID, ErrMsg: string);
begin
  if SameText(ErrMsg, 'Permission denied') or
     SameText(ErrMsg, 'Unauthorized') then
    lblStatus.Text := rsHintRTDBRules
  else
    lblStatus.Text := 'Error: ' + ErrMsg;
end;

procedure TFmxSimpleReadWrite.btnWriteClick(Sender: TObject);
var
  Data: TJSONValue;
begin
  Data := TJSONString.Create(edtDBMessage.Text);
  try
    fConfig.RealTimeDB.Put(DBPath, Data, DBWritten, DBError);
  finally
    Data.Free;
  end;
  btnWrite.Enabled := false;
end;

procedure TFmxSimpleReadWrite.edtDBMessageChangeTracking(Sender: TObject);
begin
  btnWrite.Enabled := true;
end;

end.
