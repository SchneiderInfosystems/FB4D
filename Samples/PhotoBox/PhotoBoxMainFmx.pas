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
unit PhotoBoxMainFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.TabControl, FMX.StdCtrls, FMX.Objects,
  FMX.Edit, FMX.Layouts, FMX.Media, FMX.ListBox, FMX.ExtCtrls, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo,
  FB4D.Interfaces, FB4D.Configuration, FB4D.SelfRegistrationFra,
  CameraCaptureFra, PhotoThreads;

type
  TfmxMain = class(TForm)
    TabControl: TTabControl;
    tabRegister: TTabItem;
    tabBox: TTabItem;
    layFBConfig: TLayout;
    edtKey: TEdit;
    Text2: TText;
    edtProjectID: TEdit;
    Text3: TText;
    lblVersionInfo: TLabel;
    edtBucket: TEdit;
    Text1: TText;
    tabCaptureImg: TTabItem;
    layToolbar: TLayout;
    lstPhotoList: TListBox;
    btnCaptureImg: TButton;
    fraCameraCapture: TfraCameraCapture;
    btnPhotoLib: TButton;
    sptPreview: TSplitter;
    imvPreview: TImageViewer;
    StatusBar: TStatusBar;
    lblStatus: TLabel;
    layPreview: TLayout;
    memPhotoInterpretation: TMemo;
    btnHidePreview: TButton;
    btnDelete: TButton;
    btnDownload: TButton;
    FraSelfRegistration: TFraSelfRegistration;
    txtLoggedInUser: TText;
    layUserInfo: TLayout;
    btnSignOut: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCaptureImgClick(Sender: TObject);
    procedure btnPhotoLibClick(Sender: TObject);
    procedure lstPhotoListItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure lstPhotoListMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure imvPreviewResized(Sender: TObject);
    procedure btnDownloadClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure btnHidePreviewClick(Sender: TObject);
    procedure btnSignOutClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    fConfig: IFirebaseConfiguration;
    fUID: string;
    function GetSettingFilename: string;
    function GetAuth: IFirebaseAuthentication;
    procedure OnUserLogin(const Info: string; User: IFirebaseUser);
    procedure SaveSettings;
    procedure HidePreview;
    procedure ShowPreview;
    procedure OnPhotoCaptured(Image: TBitmap; const FileName: string);
    procedure FillPhotoInterpreation(PI: TPhotoInterpretation);
    procedure OnChangedColDocument(Document: IFirestoreDocument);
    procedure OnDeletedColDocument(const DeleteDocumentPath: string;
      TimeStamp: TDateTime);
    procedure OnListenerError(const RequestID, ErrMsg: string);
    procedure OnStopListening(Sender: TObject);
    procedure OnUploaded(Item: TListBoxItem);
    procedure OnUploadFailed(Item: TListBoxItem; const Msg: string);
    procedure OnDownloaded(Item: TListBoxItem);
    procedure OnDownloadFailed(Item: TListBoxItem; const Msg: string);
    procedure OnDocumentDelete(const RequestID: string;
      Response: IFirebaseResponse);
    procedure OnPhotoDeleted(const ObjectName: TObjectName);
    procedure OnDeleteFailed(const RequestID, ErrMsg: string);
  public
    procedure WipeToTab(ActiveTab: TTabItem);
  end;

var
  fmxMain: TfmxMain;

implementation

{$R *.fmx}

uses
  System.IniFiles, System.IOUtils, System.Math, System.StrUtils,
  FB4D.Helpers, FB4D.Firestore;

// Install the following Firestore Rule:
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
//    match /photos/{photoID} {
//      allow read:
//        if (request.auth.uid != null) &&
//        	 (request.auth.uid == resource.data.createdBy);
//      allow write:
//        if (request.auth.uid != null) &&
//        	 (request.auth.uid == request.resource.data.createdBy); }}}

// Install the following Storage Rule:
// rules_version = '2';
// service firebase.storage {
//   match /b/{bucket}/o {
//     match /photos/{userID}/{photoID} {
//       allow read, write:
//         if request.auth.uid == userID;}}}

resourcestring
  rsNoItemSelected = 'First, select an item in the list box';
  rsListenerError = 'Database listener error: %s (%s)';
  rsListenerStopped = 'Database listener stopped';
  rsUploaded = ' uploaded';
  rsUploadFailed = ' upload failed: ';
  rsDownloaded = ' downloaded';
  rsDownloadFailed = ' download failed: ';
  rsDeletePhotoFailed = 'Delete photo %s failed: %s';
  rsPhotoDeleted = 'Photo %s deleted';

{$REGION 'Form Handling'}
procedure TfmxMain.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
  LastEMail: string;
  LastToken: string;
begin
  Caption := Caption + ' - ' + TFirebaseHelpers.GetConfigAndPlatform +
    ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    edtBucket.Text := IniFile.ReadString('FBProjectSettings', 'Bucket', '');
    LastEMail := IniFile.ReadString('Authentication', 'User', '');
    LastToken := IniFile.ReadString('Authentication', 'Token', '');
    fraCameraCapture.InitialDir := IniFile.ReadString('Path', 'ImageLib',
      TPath.GetPicturesPath);
  finally
    IniFile.Free;
  end;
  TabControl.ActiveTab := tabRegister;
  {$IFDEF ANDROID}
  layPreview.Align := TAlignLayout.Client;
  StatusBar.Visible := false;
  btnPhotoLib.StyleLookup := 'organizetoolbutton';
  {$ENDIF}
  FraSelfRegistration.InitializeAuthOnDemand(GetAuth, OnUserLogin, LastToken,
    LastEMail, true, false, true);
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus;
end;

procedure TfmxMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
end;

function TfmxMain.GetSettingFilename: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  result := IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    FileName + TFirebaseHelpers.GetPlatform + '.ini';
end;

function TfmxMain.GetAuth: IFirebaseAuthentication;

  function GetCacheFolder: string;
  var
    FileName: string;
  begin
    FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
    result := IncludeTrailingPathDelimiter(TPath.GetHomePath) + 
      IncludeTrailingPathDelimiter(FileName);
  end;

begin
  fConfig := TFirebaseConfiguration.Create(edtKey.Text, edtProjectID.Text,
    edtBucket.Text);
  fConfig.Storage.SetupCacheFolder(GetCacheFolder);
  result := fConfig.Auth;
  layFBConfig.Visible := false;
end;

procedure TfmxMain.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('FBProjectSettings', 'Bucket', edtBucket.Text);
    IniFile.WriteString('Authentication', 'User', FraSelfRegistration.GetEMail);
    if assigned(fConfig) and fConfig.Auth.Authenticated then
      IniFile.WriteString('Authentication', 'Token',
        fConfig.Auth.GetRefreshToken)
    else
      IniFile.DeleteKey('Authentication', 'Token');
    IniFile.WriteString('Path', 'ImageLib', fraCameraCapture.InitialDir);
  finally
    IniFile.Free;
  end;
end;

procedure TfmxMain.WipeToTab(ActiveTab: TTabItem);
var
  c: integer;
begin
  if TabControl.ActiveTab <> ActiveTab then
  begin
    if ActiveTab = tabBox then
      HidePreview;
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
{$ENDREGION}

{$REGION 'User Login'}
procedure TfmxMain.OnUserLogin(const Info: string; User: IFirebaseUser);
var
  Query: IStructuredQuery;
begin
  txtLoggedInUser.Text := User.DisplayName;
  {$IFDEF DEBUG}
  txtLoggedInUser.Text := txtLoggedInUser.Text + #13#10'(UID:' + User.UID + ')';
  {$ENDIF}
  fUID := User.UID;
  Query := TStructuredQuery.CreateForCollection(TPhotoThread.cCollectionID).
    QueryForFieldFilter(
      TQueryFilter.StringFieldFilter('createdBy', TWhereOperator.woEqual, fUID));
  fConfig.Database.SubscribeQuery(Query, OnChangedColDocument,
    OnDeletedColDocument);
  fConfig.Database.StartListener(OnStopListening, OnListenerError);
  WipeToTab(tabBox);
end;

procedure TfmxMain.btnSignOutClick(Sender: TObject);
begin
  fConfig.Database.StopListener;
  fConfig.Auth.SignOut;
  fUID := '';
  lstPhotoList.Items.Clear;
  FraSelfRegistration.StartEMailEntering;
  WipeToTab(tabRegister);
end;
{$ENDREGION}

procedure TfmxMain.btnCaptureImgClick(Sender: TObject);
begin
  fraCameraCapture.StartCapture(OnPhotoCaptured);
end;

procedure TfmxMain.btnPhotoLibClick(Sender: TObject);
begin
  fraCameraCapture.StartTakePhotoFromLib(OnPhotoCaptured);
end;

procedure TfmxMain.btnDeleteClick(Sender: TObject);
var
  Item: TListBoxItem;
  DocID: string;
begin
  if lstPhotoList.ItemIndex < 0 then
    fraCameraCapture.ToastMsg(rsNoItemSelected)
  else begin
    Item := lstPhotoList.ItemByIndex(lstPhotoList.ItemIndex);
    DocID := Item.TagString;
    // 1st step: Delete document in Firestore
    fConfig.Database.Delete([TPhotoThread.cCollectionID, DocID], nil,
      OnDocumentDelete, OnDeleteFailed);
  end;
end;

procedure TfmxMain.btnDownloadClick(Sender: TObject);
var
  Item: TListBoxItem;
  ObjName: string;
  Obj: IStorageObject;
  Stream: TStream;
begin
  if lstPhotoList.ItemIndex < 0 then
    fraCameraCapture.ToastMsg(rsNoItemSelected)
  else begin
    Item := lstPhotoList.ItemByIndex(lstPhotoList.ItemIndex);
    ObjName := TPhotoThread.GetStorageObjName(Item.TagString, fUID);
    Obj := fConfig.Storage.GetObjectFromCache(ObjName);
    if assigned(Obj) then
    begin
      Stream := fConfig.Storage.GetFileFromCache(ObjName);
      if assigned(Stream) then
      begin
        fraCameraCapture.SaveImageToFile(Stream, Obj.ContentType);
        Stream.Free;
      end;
    end;
  end;
end;

procedure TfmxMain.btnHidePreviewClick(Sender: TObject);
begin
  HidePreview;
end;

procedure TfmxMain.HidePreview;
begin
  sptPreview.Visible := false;
  layPreview.Visible := false;
  btnHidePreview.Visible := false;
  btnDownload.Visible := false;
  btnDelete.Visible := false;
  {$IFDEF ANDROID}
  btnCaptureImg.Visible := true;
  btnPhotoLib.Visible := true;
  {$ENDIF}
end;

procedure TfmxMain.ShowPreview;
begin
  layPreview.Visible := true;
  btnHidePreview.Visible := true;
  btnDelete.Visible := true;
  {$IFDEF ANDROID}
  btnCaptureImg.Visible := false;
  btnPhotoLib.Visible := false;
  {$ELSE}
  btnDownload.Visible := true;
  sptPreview.Visible := true;
  {$ENDIF}
  TThread.ForceQueue(nil,
    procedure
    begin
      Application.ProcessMessages;
      imvPreview.BestFit;
    end);
end;

procedure TfmxMain.imvPreviewResized(Sender: TObject);
begin
  TThread.ForceQueue(nil,
    procedure
    begin
      imvPreview.BestFit;
    end);
end;

procedure TfmxMain.OnPhotoCaptured(Image: TBitmap; const FileName: string);
var
  Item: TListBoxItem;
  Upload: TPhotoThread;
  Thumbnail: TBitmap;
begin
  if TabControl.ActiveTab <> tabBox then
    WipeToTab(tabBox);
  imvPreview.Bitmap.Width := Image.Width;
  imvPreview.Bitmap.Height := Image.Height;
  imvPreview.Bitmap.CopyFromBitmap(Image);
  Item := TListBoxItem.Create(lstPhotoList);
  Item.Text := FileName;
  Thumbnail := TPhotoThread.CreateThumbnail(Image);
  try
    Item.ItemData.Bitmap.Assign(Thumbnail);
  finally
    Thumbnail.Free;
  end;
  lstPhotoList.AddObject(Item);
  lstPhotoList.ItemIndex := Item.Index;
  Upload := TPhotoThread.CreateForUpload(fConfig, fUID, Image, Item);
  Upload.StartThread(OnUploaded, OnUploadFailed);
  memPhotoInterpretation.Lines.Clear;
  ShowPreview;
end;

procedure TfmxMain.OnUploaded(Item: TListBoxItem);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsUploaded);
  if layPreview.Visible then
    if assigned(Item.Data) then
      FillPhotoInterpreation(Item.Data as TPhotoInterpretation)
    else
      memPhotoInterpretation.Lines.Clear;
end;

procedure TfmxMain.OnUploadFailed(Item: TListBoxItem; const Msg: string);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsUploadFailed + Msg);
end;

procedure TfmxMain.OnDownloaded(Item: TListBoxItem);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsDownloaded);
end;

procedure TfmxMain.OnDownloadFailed(Item: TListBoxItem; const Msg: string);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsDownloadFailed + Msg);
end;

procedure TfmxMain.OnChangedColDocument(Document: IFirestoreDocument);
var
  Download: TPhotoThread;
begin
  Download := TPhotoThread.CreateForDownload(fConfig, fUID, lstPhotoList,
    Document);
  Download.StartThread(OnDownloaded, OnDownloadFailed);
end;

procedure TfmxMain.OnDeletedColDocument(const DeleteDocumentPath: string;
  TimeStamp: TDateTime);
var
  arr: TStringDynArray;
  Item: TListBoxItem;
begin
  arr := SplitString(DeleteDocumentPath, '/');
  Assert(length(arr) >= 6, 'Deleted document path is to short: ' +
    DeleteDocumentPath);
  Item := TPhotoThread.SearchItem(lstPhotoList, arr[length(arr) - 1 ]);
  if assigned(Item) then
  begin
    if layPreview.Visible and (lstPhotoList.ItemIndex = Item.Index) then
      HidePreview;
    Item.Free;
  end;
end;

procedure TfmxMain.OnDeleteFailed(const RequestID, ErrMsg: string);
begin
  fraCameraCapture.ToastMsg(Format(rsDeletePhotoFailed, [RequestID, ErrMsg]));
end;

procedure TfmxMain.OnDocumentDelete(const RequestID: string;
  Response: IFirebaseResponse);
var
  StorageObjName: string;
  arr: TStringDynArray;
begin
  arr := SplitString(RequestID, ',');
  Assert(length(arr) = 2,
    'RequestID does not contain a path with 2 levels in OnDeletePhoto');
  StorageObjName := TPhotoThread.GetStorageObjName(arr[1], fUID);
  fConfig.Storage.Delete(StorageObjName, OnPhotoDeleted, OnDeleteFailed);
end;

procedure TfmxMain.OnListenerError(const RequestID, ErrMsg: string);
begin
  if not Application.Terminated then
    fraCameraCapture.ToastMsg(Format(rsListenerError, [ErrMsg, RequestID]));
end;

procedure TfmxMain.OnPhotoDeleted(const ObjectName: TObjectName);
begin
  fraCameraCapture.ToastMsg(Format(rsPhotoDeleted, [ObjectName]));
end;

procedure TfmxMain.OnStopListening(Sender: TObject);
begin
  if not Application.Terminated then
    fraCameraCapture.ToastMsg(rsListenerStopped);
end;

procedure TfmxMain.lstPhotoListItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
var
  ObjName: string;
  Stream: TStream;
begin
  ObjName := TPhotoThread.GetStorageObjName(Item.TagString, fUID);
  Stream := fConfig.Storage.GetFileFromCache(ObjName);
  if assigned(Stream) then
  begin
    imvPreview.Bitmap.LoadFromStream(Stream);
    Stream.Free;
    if assigned(Item.Data) then
      FillPhotoInterpreation(Item.Data as TPhotoInterpretation)
    else
      memPhotoInterpretation.Lines.Clear;
    ShowPreview;
  end;
end;

procedure TfmxMain.FillPhotoInterpreation(PI: TPhotoInterpretation);
const
  cBorders = 4;
begin
  memPhotoInterpretation.Lines.Text := PI.FullInfo;
  memPhotoInterpretation.Height := min(cBorders * 2 +
    memPhotoInterpretation.Lines.Count *
    (memPhotoInterpretation.Font.Size + cBorders), layPreview.Height / 4);
end;

procedure TfmxMain.lstPhotoListMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
begin
  if lstPhotoList.ItemByPoint(X, Y) = nil then
    HidePreview;
end;

end.
