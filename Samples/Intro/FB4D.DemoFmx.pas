{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2023 Christoph Schneider                                 }
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

unit FB4D.DemoFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.StrUtils, System.JSON, System.ImageList,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.TabControl, FMX.DateTimeCtrls, FMX.ListBox, FMX.Layouts, FMX.EditBox,
  FMX.SpinBox, FMX.Memo.Types, FMX.Menus, FMX.ExtCtrls, FMX.DialogService,
  FMX.ImgList, FMX.Ani,
  FB4D.AuthFra, FB4D.RTDBFra, FB4D.FirestoreFra,
  FB4D.StorageFra, FB4D.FunctionsFra, FB4D.VisionMLFra,
  FB4D.Interfaces;

type
  TfmxFirebaseDemo = class(TForm)
    TabControl: TTabControl;
    tabAuth: TTabItem;
    tabStorage: TTabItem;
    tabRealTimeDB: TTabItem;
    tabFirestore: TTabItem;
    tabFunctions: TTabItem;
    tabVisionML: TTabItem;
    imlFirebaseServices: TImageList;
    edtProjectID: TEdit;
    Text1: TText;
    edtKey: TEdit;
    Text2: TText;
    layToolbar: TLayout;
    btnShowSettings: TButton;
    FloatAniToolbar: TFloatAnimation;
    lblOpenFBConsole: TLabel;
    rctKeyDisabled: TRectangle;
    rctProjectIDDisabled: TRectangle;
    lblOpenFBConsoleForProject: TLabel;
    lblOpenFBConsoleForAuth: TLabel;
    RTDBFra: TRTDBFra;
    lblOpenFBConsoleForRTDB: TLabel;
    lblOpenFBConsoleForFS: TLabel;
    FirestoreFra: TFirestoreFra;
    StorageFra: TStorageFra;
    lblOpenFBConsoleForStorage: TLabel;
    lblOpenFBConsoleForFunctions: TLabel;
    FunctionsFra: TFunctionsFra;
    AuthFra: TAuthFra;
    lblOpenFBConsoleForVisionML: TLabel;
    VisionMLFra: TVisionMLFra;
    procedure FormShow(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnShowSettingsClick(Sender: TObject);
    procedure FloatAniToolbarFinish(Sender: TObject);
    procedure lblOpenFBConsoleClick(Sender: TObject);
    procedure lblOpenFBConsoleForProjectClick(Sender: TObject);
    procedure lblOpenFBConsoleForAuthClick(Sender: TObject);
    procedure lblOpenFBConsoleForRTDBClick(Sender: TObject);
    procedure lblOpenFBConsoleForFSClick(Sender: TObject);
    procedure lblOpenFBConsoleForStorageClick(Sender: TObject);
    procedure lblOpenFBConsoleForFunctionsClick(Sender: TObject);
    procedure lblOpenFBConsoleForVisionMLClick(Sender: TObject);
  private
    function GetIniFileName: string;
    procedure OpenURLinkInBrowser(const URL: string);
  end;

var
  fmxFirebaseDemo: TfmxFirebaseDemo;

implementation

{$R *.fmx}

uses
  System.IniFiles, System.IOUtils,
{$IFDEF MSWINDOWS}
  Winapi.ShellAPI, Winapi.Windows,
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  Posix.Stdlib,
{$ENDIF POSIX}
  FB4D.Helpers,
  FB4D.Configuration;

{$REGION 'Form Handling'}
procedure TfmxFirebaseDemo.FormShow(Sender: TObject);
var
  IniFile: TIniFile;
begin
  Caption := Caption + ' - ' + TFirebaseHelpers.GetPlatform +
    ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
  TabControl.ActiveTab := tabAuth;
  IniFile := TIniFile.Create(GetIniFileName);
  try
    edtKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text := IniFile.ReadString('FBProjectSettings', 'ProjectID',
      '');
    AuthFra.LoadSettingsFromIniFile(IniFile);
    RTDBFra.LoadSettingsFromIniFile(IniFile, edtProjectID.Text);
    FirestoreFra.LoadSettingsFromIniFile(IniFile);
    StorageFra.LoadSettingsFromIniFile(IniFile);
    FunctionsFra.LoadSettingsFromIniFile(IniFile);
    VisionMLFra.LoadSettingsFromIniFile(IniFile);
  finally
    IniFile.Free;
  end;
  if not(edtKey.Text.IsEmpty or edtProjectID.Text.IsEmpty) then
    layToolbar.Height := FloatAniToolbar.StartValue;
end;

procedure TfmxFirebaseDemo.FormClose(Sender: TObject; var Action: TCloseAction);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetIniFileName);
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    AuthFra.SaveSettingsIntoIniFile(IniFile);
    RTDBFra.SaveSettingsIntoIniFile(IniFile);
    FirestoreFra.SaveSettingsIntoIniFile(IniFile);
    StorageFra.SaveSettingsIntoIniFile(IniFile);
    FunctionsFra.SaveSettingsIntoIniFile(IniFile);
    VisionMLFra.SaveSettingsIntoIniFile(IniFile);
  finally
    IniFile.Free;
  end;
end;

function TfmxFirebaseDemo.GetIniFileName: string;
begin
  result := IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
end;

procedure TfmxFirebaseDemo.TabControlChange(Sender: TObject);
begin
  if TabControl.ActiveTab = tabAuth then
    AuthFra.CheckTokenExpired;
  lblOpenFBConsoleForAuth.visible := TabControl.ActiveTab = tabAuth;
  lblOpenFBConsoleForRTDB.visible := TabControl.ActiveTab = tabRealTimeDB;
  lblOpenFBConsoleForFS.visible := TabControl.ActiveTab = tabFirestore;
  lblOpenFBConsoleForStorage.visible := TabControl.ActiveTab = tabStorage;
  lblOpenFBConsoleForFunctions.visible := TabControl.ActiveTab = tabFunctions;
  lblOpenFBConsoleForVisionML.visible := TabControl.ActiveTab = tabVisionML;
end;
{$ENDREGION}

{$REGION 'Firebase Project Settings'}
procedure TfmxFirebaseDemo.btnShowSettingsClick(Sender: TObject);
begin
  FloatAniToolbar.Start;
end;

procedure TfmxFirebaseDemo.FloatAniToolbarFinish(Sender: TObject);
begin
  FloatAniToolbar.Inverse := not FloatAniToolbar.Inverse;
end;

procedure TfmxFirebaseDemo.OpenURLinkInBrowser(const URL: string);
var
  EncodedURL: string;
begin
  EncodedURL := ReplaceStr(ReplaceStr(URL, '(', '-'), ')', '-');
{$IFDEF MSWINDOWS}
  ShellExecute(0, 'OPEN', PChar(EncodedURL), '', '', SW_SHOWNORMAL);
{$ENDIF MSWINDOWS}
{$IFDEF POSIX}
  _system(PAnsiChar('open ' + AnsiString(EncodedURL)));
{$ENDIF POSIX}
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleClick(Sender: TObject);
const
  cFBConsoleURL = 'https://console.firebase.google.com';
begin
  OpenURLinkInBrowser(cFBConsoleURL);
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForProjectClick(Sender: TObject);
const
  cFBConsoleForProjectURL =
    'https://console.firebase.google.com/u/0/project/newproject-e2ba0/overview';
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForProjectURL, [edtProjectID.Text]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForAuthClick(Sender: TObject);
const
  cFBConsoleForAuthURL =
    'https://console.firebase.google.com/u/0/project/%s/authentication/users';
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForAuthURL, [edtProjectID.Text]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForRTDBClick(Sender: TObject);
const
  cFBConsoleForRTDBURL =
    'https://console.firebase.google.com/u/0/project/%s/database/%s/data';
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForRTDBURL,
      [edtProjectID.Text, RTDBFra.GetDatabase]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForFSClick(Sender: TObject);
const
  cFBConsoleForFSURL =
    'https://console.firebase.google.com/u/0/project/%s/firestore/databases/%s/data';
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else if FirestoreFra.CheckAndCreateFirestoreDBClass then
    OpenURLinkInBrowser(Format(cFBConsoleForFSURL,
      [edtProjectID.Text, FirestoreFra.Database.DatabaseID]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForStorageClick(Sender: TObject);
const
  cFBConsoleForStorageURL =
    'https://console.firebase.google.com/u/0/project/%s/storage/%s/files';
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else if StorageFra.edtStorageBucket.Text.IsEmpty then
    StorageFra.edtStorageBucket.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForStorageURL,
      [edtProjectID.Text, StorageFra.edtStorageBucket.Text]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForFunctionsClick(Sender: TObject);
const
  cFBConsoleForFunctionsURL =
    'https://console.firebase.google.com/u/0/project/%s/functions';
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForFunctionsURL, [edtProjectID.Text]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForVisionMLClick(Sender: TObject);
const
  cFBConsoleForMLApisURL =
    'https://console.firebase.google.com/u/0/project/%s/ml/apis';
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForMLApisURL, [edtProjectID.Text]));
end;

{$ENDREGION}

end.
