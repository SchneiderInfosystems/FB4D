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

unit FB4D.VCL.PerUserReadWrite;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.WinXPanels,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Mask,
  FB4D.Interfaces, FB4D.Configuration, FB4D.SelfRegistrationFra;

type
  TfrmMain = class(TForm)
    CardPanel: TCardPanel;
    CardAuth: TCard;
    CardRTDBAccess: TCard;
    FraSelfRegistration: TFraSelfRegistration;
    pnlUserInfo: TPanel;
    btnSignOut: TButton;
    lblUserInfo: TLabel;
    edtDBMessage: TLabeledEdit;
    btnWrite: TButton;
    lblStatus: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSignOutClick(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
    procedure edtDBMessageChange(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    fUID: string;
    fFirebaseEvent: IFirebaseEvent;
    function GetSettingFilename: string;
    function LoadLastToken: string;
    procedure SaveToken;
    procedure OnUserLogin(const Info: string; User: IFirebaseUser);
    procedure WipeToCard(ActiveCard: TCard);
    procedure StartListening;
    procedure OnDBEvent(const Event: string; Params: TRequestResourceParam;
      JSONObj: TJSONObject);
    procedure OnDBError(const RequestID, ErrMsg: string);
    procedure OnDBWritten(ResourceParams: TRequestResourceParam;
      Val: TJSONValue);
    procedure OnDBStop(Sender: TObject);
    function DBPath: TRequestResourceParam;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.IniFiles, System.IOUtils,
  FB4D.Helpers;

{$R *.dfm}

resourcestring
  rsUserInfo = 'Logged in with eMail: %s'#13'User ID: %s';
  rsHintRTDBRules =
    'Hint to permission error:'#13#13 +
    'Before you can write into the real time database add the following'#13 +
    'text in the Firebase console as rule for the Realtime Database:'#13#13 +
    '{'#13 +
    ' "rules": {'#13 +
    '    "UserMsg": {'#13 +
    '      "$uid": {'#13 +
    '		    ".read": "(auth != null) && (auth.uid == $uid)",'#13 +
    '    		".write": "(auth != null) && (auth.uid == $uid)" '#13 +
    '    	}'#13 +
    '    }'#13 +
    '  }'#13 +
    '}'#13;

const
// Alternative way by entering
//  ApiKey = '<Your Firebase ApiKey listed in the Firebase Console>';
//  ProjectID = '<Your Project ID listed in the Firebase Console>';
{$IFDEF MSWINDOWS}
  GoogleServiceJSON = '..\..\..\google-services.json';
{$ENDIF}
{$IFDEF MACOS}
  GoogleServiceJSON = '../Resources/Startup/google-services.json';
{$ENDIF}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  fConfig := TFirebaseConfiguration.Create(GoogleServiceJSON);
  // Alternative with constants for ApiKey and ProjectID
  // fConfig := TFirebaseConfiguration.Create(ApiKey, ProjectID);
  fUID := '';
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  Caption := Caption + ' [' + TFirebaseHelpers.GetConfigAndPlatform + ']';
  CardPanel.ActiveCard := CardAuth;
  FraSelfRegistration.Initialize(fConfig.Auth, OnUserLogin, LoadLastToken);
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveToken;
end;

function TfrmMain.GetSettingFilename: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  result := IncludeTrailingPathDelimiter(TPath.GetHomePath) + FileName +
    TFirebaseHelpers.GetPlatform + '.ini';
end;

function TfrmMain.LoadLastToken: string;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    result := IniFile.ReadString('LastAccess', 'Token', '');
  finally
    IniFile.Free;
  end;
end;

procedure TfrmMain.SaveToken;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    if fConfig.Auth.Authenticated then
      // Attention: Refreshtoken is stored in the inifile in plain text
      // Better would be to encrypt it with a secret key
      IniFile.WriteString('LastAccess', 'Token', fConfig.Auth.GetRefreshToken)
    else
      IniFile.DeleteKey('LastAccess', 'Token');
  finally
    IniFile.Free;
  end;
end;

procedure TfrmMain.OnUserLogin(const Info: string; User: IFirebaseUser);
begin
  fUID := User.UID;
  lblUserInfo.Caption := Format(rsUserInfo, [User.EMail, fUID]);
  StartListening;
end;

procedure TfrmMain.btnSignOutClick(Sender: TObject);
begin
  fConfig.Auth.SignOut;
  fUID := '';
  WipeToCard(cardAuth);
  FraSelfRegistration.StartEMailEntering;
end;

procedure TfrmMain.WipeToCard(ActiveCard: TCard);
begin
  if CardPanel.ActiveCard <> ActiveCard then
    CardPanel.ActiveCard := ActiveCard;
end;

procedure TfrmMain.StartListening;
begin
  WipeToCard(cardRTDBAccess);
  fFirebaseEvent := fConfig.RealTimeDB.ListenForValueEvents(DBPath, OnDBEvent,
    OnDBStop, OnDBError, nil);
  lblStatus.Caption := 'Firebase RT DB connected';
end;

procedure TfrmMain.OnDBStop(Sender: TObject);
begin
  Caption := 'DB Listener was stopped - restart App';
end;

procedure TfrmMain.OnDBEvent(const Event: string;
  Params: TRequestResourceParam; JSONObj: TJSONObject);
begin
  if Event = cEventPut then
  begin
    edtDBMessage.Text := JSONObj.GetValue<string>(cData);
    btnWrite.Enabled := false;
    lblStatus.Caption := 'Last read: ' + DateTimeToStr(now);
  end;
end;

procedure TfrmMain.OnDBWritten(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  lblStatus.Caption := 'Last write: ' + DateTimeToStr(now);
end;

procedure TfrmMain.OnDBError(const RequestID, ErrMsg: string);
begin
  if SameText(ErrMsg, 'Permission denied') or
     SameText(ErrMsg, 'Unauthorized') then
    lblStatus.Caption := rsHintRTDBRules
  else
    lblStatus.Caption := 'Error: ' + ErrMsg;
end;

procedure TfrmMain.btnWriteClick(Sender: TObject);
var
  Data: TJSONValue;
begin
  Data := TJSONString.Create(edtDBMessage.Text);
  try
    fConfig.RealTimeDB.Put(DBPath, Data, OnDBWritten, OnDBError);
  finally
    Data.Free;
  end;
  btnWrite.Enabled := false;
end;

function TfrmMain.DBPath: TRequestResourceParam;
begin
  Assert(not fUID.IsEmpty, 'UID missing');
  result := ['UserMsg', fUID];
end;

procedure TfrmMain.edtDBMessageChange(Sender: TObject);
begin
  btnWrite.Enabled := true;
end;

end.
