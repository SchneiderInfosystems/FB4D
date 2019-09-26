{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2019 Christoph Schneider                                 }
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

unit FB4D.PerUserReadWrite;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Edit, FMX.Controls.Presentation, FMX.TabControl, FMX.Layouts,
  FB4D.Interfaces, FB4D.Configuration, FB4D.SelfRegistrationFra;

type
  TfmxMain = class(TForm)
    TabControl: TTabControl;
    tabAuth: TTabItem;
    tabRTDBAccess: TTabItem;
    lblUserInfo: TLabel;
    layUserInfo: TLayout;
    btnSignOut: TButton;
    FraSelfRegistration: TFraSelfRegistration;
    edtDBMessage: TEdit;
    lblStatus: TLabel;
    btnWrite: TButton;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSignOutClick(Sender: TObject);
    procedure edtDBMessageChangeTracking(Sender: TObject);
    procedure btnWriteClick(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    fUID: string;
    function GetSettingFilename: string;
    function LoadLastToken: string;
    procedure SaveToken;
    procedure OnUserLogin(const Info: string; User: IFirebaseUser);
    procedure WipeToTab(ActiveTab: TTabItem);
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
  fmxMain: TfmxMain;

implementation

uses
  System.IniFiles, System.IOUtils,
  FB4D.Helpers;

{$R *.fmx}

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

procedure TfmxMain.FormCreate(Sender: TObject);
begin
  fConfig := TFirebaseConfiguration.Create(GoogleServiceJSON);
  // Alternative with constants for ApiKey and ProjectID
  // fConfig := TFirebaseConfiguration.Create(ApiKey, ProjectID);
  fUID := '';
end;

procedure TfmxMain.FormShow(Sender: TObject);
begin
  Caption := Caption + ' [' + TFirebaseHelpers.GetConfigAndPlatform + ']';
  TabControl.ActiveTab := tabAuth;
  FraSelfRegistration.Initialize(fConfig.Auth, OnUserLogin, LoadLastToken);
end;

procedure TfmxMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveToken;
end;

function TfmxMain.GetSettingFilename: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  result := IncludeTrailingPathDelimiter(
{$IFDEF IOS}
    TPath.GetDocumentsPath
{$ELSE}
    TPath.GetHomePath
{$ENDIF}
    ) + FileName + TFirebaseHelpers.GetPlatform + '.ini';
end;

function TfmxMain.LoadLastToken: string;
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

procedure TfmxMain.SaveToken;
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

procedure TfmxMain.OnUserLogin(const Info: string; User: IFirebaseUser);
begin
  fUID := User.UID;
  lblUserInfo.Text := Format(rsUserInfo, [User.EMail, fUID]);
  StartListening;
end;

procedure TfmxMain.btnSignOutClick(Sender: TObject);
begin
  fConfig.Auth.SignOut;
  fUID := '';
  WipeToTab(tabAuth);
  FraSelfRegistration.StartEMailEntering;
end;

procedure TfmxMain.WipeToTab(ActiveTab: TTabItem);
var
  c: integer;
begin
  if TabControl.ActiveTab <> ActiveTab then
  begin
    ActiveTab.Visible := true;
{$IFDEF ANDROID}
    TabControl.ActiveTab := ActiveTab;
{$ELSE}
    TabControl.GotoVisibleTab(ActiveTab.Index, TTabTransition.Slide,
      TTabTransitionDirection.Normal);
{$ENDIF}
    for c := 0 to TabControl.TabCount - 1 do
      TabControl.Tabs[c].Visible := TabControl.Tabs[c] = ActiveTab;
  end;
end;

procedure TfmxMain.StartListening;
begin
  WipeToTab(tabRTDBAccess);
  fConfig.RealTimeDB.ListenForValueEvents(DBPath, OnDBEvent, OnDBStop,
    OnDBError, nil);
  lblStatus.Text := 'Firebase RT DB connected';
end;

procedure TfmxMain.OnDBStop(Sender: TObject);
begin
  Caption := 'DB Listener was stopped - restart App';
end;

procedure TfmxMain.OnDBEvent(const Event: string;
  Params: TRequestResourceParam; JSONObj: TJSONObject);
begin
  if Event = cEventPut then
  begin
    edtDBMessage.Text := JSONObj.GetValue<string>(cData);
    btnWrite.Enabled := false;
    lblStatus.Text := 'Last read: ' + DateTimeToStr(now);
  end;
end;

procedure TfmxMain.OnDBWritten(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  lblStatus.Text := 'Last write: ' + DateTimeToStr(now);
end;

procedure TfmxMain.OnDBError(const RequestID, ErrMsg: string);
begin
  if SameText(ErrMsg, 'Permission denied') or
     SameText(ErrMsg, 'Unauthorized') then
    lblStatus.Text := rsHintRTDBRules
  else
    lblStatus.Text := 'Error: ' + ErrMsg;
end;

procedure TfmxMain.btnWriteClick(Sender: TObject);
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

procedure TfmxMain.edtDBMessageChangeTracking(Sender: TObject);
begin
  btnWrite.Enabled := true;
end;

function TfmxMain.DBPath: TRequestResourceParam;
begin
  Assert(not fUID.IsEmpty, 'UID missing');
  result := ['UserMsg', fUID];
end;

end.
