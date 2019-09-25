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
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
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
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSignOutClick(Sender: TObject);
  private
    fConfig: IFirebaseConfiguration;
    fUID: string;
    function GetSettingFilename: string;
    function LoadLastToken: string;
    procedure SaveToken;
    procedure OnUserLogin(const Info: string; User: IFirebaseUser);
    procedure WipeToTab(ActiveTab: TTabItem);
    procedure StartListening;
  end;

var
  fmxMain: TfmxMain;

implementation

uses
  System.IniFiles, System.IOUtils;

{$R *.fmx}

resourcestring
  rsUserInfo = 'Logged in with eMail: %s'#13'User ID: %s';

const
  GoogleServiceJSON = '..\..\..\google-services.json';
// Alternative way by entering
//  ApiKey = '<Your Firebase ApiKey listed in the Firebase Console>';
//  ProjectID = '<Your Porject ID listed in the Firebase Console>';
  DBPath: TRequestResourceParam = ['Message'];

procedure TfmxMain.FormCreate(Sender: TObject);
begin
  fConfig := TFirebaseConfiguration.Create(GoogleServiceJSON);
  fUID := '';
end;

procedure TfmxMain.FormShow(Sender: TObject);
begin
  TabControl.ActiveTab := tabAuth;
  FraSelfRegistration.Initialize(fConfig, OnUserLogin, LoadLastToken);
end;

procedure TfmxMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveToken;
end;

function TfmxMain.GetSettingFilename: string;
begin
  result := IncludeTrailingPathDelimiter(
{$IFDEF IOS}
    TPath.GetDocumentsPath
{$ELSE}
    TPath.GetHomePath
{$ENDIF}
    ) + ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
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
end;

end.
