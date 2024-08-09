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
    layToolbar: TLayout;
    FloatAniToolbar: TFloatAnimation;
    btnShowSettings: TButton;
    edtProjectID: TEdit;
    Text1: TText;
    edtKey: TEdit;
    Text2: TText;
    rctKeyDisabled: TRectangle;
    rctProjectIDDisabled: TRectangle;
    imgLogo: TImage;
    lblOpenFBConsole: TLabel;
    lblOpenFBConsoleForProject: TLabel;
    lblOpenFBConsoleForAuth: TLabel;
    lblOpenFBConsoleForRTDB: TLabel;
    lblOpenFBConsoleForFS: TLabel;
    lblOpenFBConsoleForStorage: TLabel;
    lblOpenFBConsoleForFunctions: TLabel;
    lblOpenFBConsoleForVisionML: TLabel;
    RTDBFra: TRTDBFra;
    FirestoreFra: TFirestoreFra;
    FunctionsFra: TFunctionsFra;
    AuthFra: TAuthFra;
    VisionMLFra: TVisionMLFra;
    popClipboard: TPopupMenu;
    mniFromClipboard: TMenuItem;
    mniToClipboard: TMenuItem;
    StorageFra: TStorageFra;
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
    procedure imgLogoClick(Sender: TObject);
    procedure mniFromClipboardClick(Sender: TObject);
    procedure mniToClipboardClick(Sender: TObject);
  private
    function GetIniFileName: string;
    procedure OpenURLinkInBrowser(const URL: string);
  end;

var
  fmxFirebaseDemo: TfmxFirebaseDemo;

implementation

{$R *.fmx}

uses
  System.IniFiles, System.IOUtils, System.RTTI,
  Fmx.Platform,
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
  TabControlChange(Sender);
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
  lblOpenFBConsole.visible := edtProjectID.Text.IsEmpty;
  lblOpenFBConsoleForProject.visible := not lblOpenFBConsole.visible;
  lblOpenFBConsoleForAuth.visible := TabControl.ActiveTab = tabAuth;
  lblOpenFBConsoleForRTDB.visible := TabControl.ActiveTab = tabRealTimeDB;
  lblOpenFBConsoleForFS.visible := TabControl.ActiveTab = tabFirestore;
  lblOpenFBConsoleForStorage.visible := TabControl.ActiveTab = tabStorage;
  lblOpenFBConsoleForFunctions.visible := TabControl.ActiveTab = tabFunctions;
  lblOpenFBConsoleForVisionML.visible := TabControl.ActiveTab = tabVisionML;
end;
{$ENDREGION}

{$REGION 'Firebase Project Settings'}

// Because copy / past directly from the Firebase console is not working due to
// a CRLF before the ID a own solution with a popup menu is implemented here.

function TryGetClipboardService(out clp: IFMXClipboardService): boolean;
begin
  result := TPlatformServices.Current.SupportsPlatformService(
    IFMXClipboardService);
  if result then
    clp := IFMXClipboardService(TPlatformServices.Current.GetPlatformService(
      IFMXClipboardService));
end;

procedure TfmxFirebaseDemo.mniFromClipboardClick(Sender: TObject);
var
  Caller: TPopupMenu;
  Edit: TEdit;
  clp: IFMXClipboardService;
  val: TValue;
  txt: string;
begin
  if TryGetClipboardService(clp) then
  begin
    val := clp.GetClipboard;
    if val.TryAsType(txt) then
    begin
      Caller := (((Sender as TMenuItem).parent) as TContent).parent as TPopupMenu;
      if assigned(Caller) then
      begin
        Edit := Caller.PopupComponent as TEdit;
        Edit.Text := trim(txt);
      end;
    end;
  end;
end;

procedure TfmxFirebaseDemo.mniToClipboardClick(Sender: TObject);
var
  clp: IFMXClipboardService;
begin
  if TryGetClipboardService(clp) then
    clp.SetClipboard(edtProjectID.Text);
end;

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

const
  cFBConsoleURL = 'https://console.firebase.google.com';
  cFBConsoleForProjectBase = cFBConsoleURL + '/u/0/project/%s/';
  cFBConsoleForProjectURL = cFBConsoleForProjectBase + 'overview';
  cFBConsoleForAuthURL = cFBConsoleForProjectBase + 'authentication/users';
  cFBConsoleForRTDBURL = cFBConsoleForProjectBase + 'database/%s/data';
  cFBConsoleForFSURL = cFBConsoleForProjectBase +'firestore/databases/%s/data';
  cFBConsoleForStorageURL = cFBConsoleForProjectBase + 'storage/%s/files';
  cFBConsoleForFunctionsURL = cFBConsoleForProjectBase +'functions';
  cFBConsoleForMLApisURL = cFBConsoleForProjectBase + 'ml/apis';
  cFB4DWikiURL = 'https://github.com/SchneiderInfosystems/FB4D/wiki/';
  cFB4DIntroURL = cFB4DWikiURL + 'Getting-Started-with-FB4D';
  cFB4DAuthURL = cFB4DWikiURL + 'FB4D-Reference-IFirebaseAuthentication';
  cFB4DRTDBURL = cFB4DWikiURL + 'FB4D-Reference-IRealTimeDB';
  cFB4DFSURL = cFB4DWikiURL + 'FB4D-Reference-IFirestoreDatabase';
  cFB4DStorageURL = cFB4DWikiURL + 'FB4D-Reference-IFirebaseStorage';
  cFB4DFunctsionURL = cFB4DWikiURL + 'FB4D-Reference-IFirebaseFunctions';
  cFB4DVisionMLURL = cFB4DWikiURL + 'FB4D-Reference-IVisionML';

procedure TfmxFirebaseDemo.imgLogoClick(Sender: TObject);
begin
  if layToolbar.Height = FloatAniToolbar.StopValue then
    OpenURLinkInBrowser(cFB4DIntroURL)
  else if TabControl.ActiveTab = tabAuth then
    OpenURLinkInBrowser(cFB4DAuthURL)
  else if TabControl.ActiveTab = tabRealTimeDB then
    OpenURLinkInBrowser(cFB4DRTDBURL)
  else if TabControl.ActiveTab = tabFirestore then
    OpenURLinkInBrowser(cFB4DFSURL)
  else if TabControl.ActiveTab = tabStorage then
    OpenURLinkInBrowser(cFB4DStorageURL)
  else if TabControl.ActiveTab = tabFunctions then
    OpenURLinkInBrowser(cFB4DFunctsionURL)
  else if TabControl.ActiveTab = tabVisionML then
    OpenURLinkInBrowser(cFB4DVisionMLURL)
  else
    OpenURLinkInBrowser(cFB4DWikiURL);
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleClick(Sender: TObject);
begin
  OpenURLinkInBrowser(cFBConsoleURL);
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForProjectClick(Sender: TObject);
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForProjectURL, [edtProjectID.Text]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForAuthClick(Sender: TObject);
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForAuthURL, [edtProjectID.Text]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForRTDBClick(Sender: TObject);
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForRTDBURL,
      [edtProjectID.Text, RTDBFra.GetDatabase]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForFSClick(Sender: TObject);
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else if FirestoreFra.CheckAndCreateFirestoreDBClass then
    OpenURLinkInBrowser(Format(cFBConsoleForFSURL,
      [edtProjectID.Text, FirestoreFra.Database.DatabaseID]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForStorageClick(Sender: TObject);
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
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForFunctionsURL, [edtProjectID.Text]));
end;

procedure TfmxFirebaseDemo.lblOpenFBConsoleForVisionMLClick(Sender: TObject);
begin
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus
  else
    OpenURLinkInBrowser(Format(cFBConsoleForMLApisURL, [edtProjectID.Text]));
end;

{$ENDREGION}

end.
