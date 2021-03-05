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

unit ChatMainFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Controls.Presentation, FMX.Edit, FB4D.SelfRegistrationFra, FMX.TabControl,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.Layouts, FMX.ListView, FMX.StdCtrls,
  FB4D.Interfaces, FB4D.Configuration;

type
  TfmxChatMain = class(TForm)
    TabControl: TTabControl;
    tabChat: TTabItem;
    tabLogin: TTabItem;
    edtKey: TEdit;
    Text2: TText;
    edtProjectID: TEdit;
    Text3: TText;
    lsvChat: TListView;
    layPushMessage: TLayout;
    edtMessage: TEdit;
    btnPushMessage: TButton;
    lblVersionInfo: TLabel;
    layUserInfo: TLayout;
    btnSignOut: TButton;
    lblUserInfo: TLabel;
    FraSelfRegistration: TFraSelfRegistration;
    txtUpdate: TText;
    txtError: TText;
    btnDeleteMessage: TButton;
    btnEditMessage: TButton;
    layFBConfig: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSignOutClick(Sender: TObject);
    procedure btnPushMessageClick(Sender: TObject);
    procedure edtMessageKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
    procedure lsvChatItemClick(const Sender: TObject;
      const AItem: TListViewItem);
    procedure btnEditMessageClick(Sender: TObject);
    procedure btnDeleteMessageClick(Sender: TObject);
    procedure lsvChatResized(Sender: TObject);
  private
    fConfig: TFirebaseConfiguration;
    fUID: string;
    fUserName: string;
    fEditDocID: string;
    function GetAuth: IFirebaseAuthentication;
    function GetSettingFilename: string;
    procedure SaveSettings;
    procedure OnUserLogin(const Info: string; User: IFirebaseUser);
    procedure StartChat;
    procedure WipeToTab(ActiveTab: TTabItem);
    procedure EnterEditMode(const DocPath: string);
    procedure ExitEditMode(ClearEditBox: boolean);
    procedure OnAuthRevoked(TokenRenewPassed: boolean);
    procedure OnChangedColDocument(Document: IFirestoreDocument);
    procedure OnDeletedColDocument(const DeleteDocumentPath: string;
      TimeStamp: TDateTime);
    procedure OnListenerError(const RequestID, ErrMsg: string);
    procedure OnStopListening(Sender: TObject);
    function SearchItem(const DocId: string): TListViewItem;
    procedure OnDocWrite(const Info: string; Document: IFirestoreDocument);
    procedure OnDocWriteError(const RequestID, ErrMsg: string);
    procedure OnDocDelete(const RequestID: string; Response: IFirebaseResponse);
    procedure OnDocDeleteError(const RequestID, ErrMsg: string);
  end;

var
  fmxChatMain: TfmxChatMain;

implementation

uses
  System.IniFiles, System.IOUtils, System.JSON,
  FB4D.Helpers, FB4D.Firestore, FB4D.Document;

{$R *.fmx}

const
  cDocID = 'Chat';

// Install the following Firestore Rule:
// rules_version = '2';
// service cloud.firestore {
//   match /databases/{database}/documents {
//     match /Chat/{document=**} {
// 	    allow read, write: if request.auth != null;}}

{ TfmxChatMain }

procedure TfmxChatMain.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
  LastEMail: string;
  LastToken: string;
begin
  Caption := Caption + ' - ' + TFirebaseHelpers.GetPlatform +
    ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    LastEMail := IniFile.ReadString('Authentication', 'User', '');
    LastToken := IniFile.ReadString('Authentication', 'Token', '');
  finally
    IniFile.Free;
  end;
  TabControl.ActiveTab := tabLogin;
  FraSelfRegistration.InitializeAuthOnDemand(GetAuth, OnUserLogin, LastToken,
    LastEMail, true, false, true);
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus;
end;

procedure TfmxChatMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
  FreeAndNil(fConfig);
end;

procedure TfmxChatMain.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('Authentication', 'User', FraSelfRegistration.GetEMail);
    if assigned(fConfig) and fConfig.Auth.Authenticated then
      IniFile.WriteString('Authentication', 'Token',
        fConfig.Auth.GetRefreshToken)
    else
      IniFile.DeleteKey('Authentication', 'Token');
  finally
    IniFile.Free;
  end;
end;

function TfmxChatMain.GetAuth: IFirebaseAuthentication;
begin
  fConfig := TFirebaseConfiguration.Create(edtKey.Text, edtProjectID.Text);
  result := fConfig.Auth;
  edtKey.Enabled := false;
  edtProjectID.Enabled := false;
end;

function TfmxChatMain.GetSettingFilename: string;
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

procedure TfmxChatMain.OnUserLogin(const Info: string; User: IFirebaseUser);
begin
  fUID := User.UID;
  fUserName := User.DisplayName;
  StartChat;
end;

procedure TfmxChatMain.btnSignOutClick(Sender: TObject);
begin
  fConfig.Database.StopListener;
  fConfig.Auth.SignOut;
  fUID := '';
  fUserName := '';
  WipeToTab(tabLogin);
  FraSelfRegistration.StartEMailEntering;
end;

procedure TfmxChatMain.WipeToTab(ActiveTab: TTabItem);
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

procedure TfmxChatMain.StartChat;
begin
  lblUserInfo.Text := fUserName + ' logged in';
  fConfig.Database.SubscribeQuery(TStructuredQuery.CreateForCollection(cDocID).
    OrderBy('DateTime', odAscending),
    OnChangedColDocument, OnDeletedColDocument);
  fConfig.Database.StartListener(OnStopListening, OnListenerError, OnAuthRevoked);
  btnEditMessage.Visible := false;
  btnDeleteMessage.Visible := false;
  btnPushMessage.Visible := true;
  fEditDocID := '';
  WipeToTab(tabChat);
end;

function TfmxChatMain.SearchItem(const DocId: string): TListViewItem;
var
  c: integer;
begin
  result := nil;
  for c := 0 to lsvChat.ItemCount - 1 do
    if lsvChat.Items[c].Purpose = TListItemPurpose.None then
      if lsvChat.Items[c].TagString = DocId then
        exit(lsvChat.Items[c]);
end;

procedure TfmxChatMain.OnChangedColDocument(Document: IFirestoreDocument);
var
  Item: TListViewItem;
  Edited: TDateTime;
begin
  Item := SearchItem(Document.DocumentName(true));
  lsvChat.BeginUpdate;
  try
    if not assigned(Item) then
    begin
      Item := lsvChat.Items.AddItem(lsvChat.ItemCount);
      Item.TagString := Document.DocumentName(true);
    end;
    Item.Text := Document.GetStringValueDef('Message', '?');
    Item.Detail := Document.GetStringValueDef('Sender', '?') + ' at ' +
      DateTimeToStr(TFirebaseHelpers.ConvertToLocalDateTime(
        Document.GetTimeStampValueDef('DateTime', now)));
    Edited := Document.GetTimeStampValueDef('Edited', 0);
    if Edited > 0 then
      Item.Detail := Item.Detail + ' (edited ' +
        DateTimeToStr(TFirebaseHelpers.ConvertToLocalDateTime(Edited)) + ')';
    if Document.GetStringValueDef('UID', '?') = fUID then
    begin
      Item.Tag := 1;
      Item.Objects.TextObject.TextAlign := TTextAlign.Trailing;
      Item.Objects.DetailObject.TextAlign := TTextAlign.Trailing;
    end else begin
      Item.Tag := 0;
      Item.Objects.TextObject.TextAlign := TTextAlign.Leading;
      Item.Objects.DetailObject.TextAlign := TTextAlign.Leading;
    end;
  finally
    lsvChat.EndUpdate;
  end;
  lsvChat.Selected := Item;
  txtUpdate.Text := 'Last message written at ' +
    FormatDateTime('HH:NN:SS.ZZZ', Document.UpdateTime);
end;

procedure TfmxChatMain.lsvChatItemClick(const Sender: TObject;
  const AItem: TListViewItem);
begin
  if AItem.Tag = 1 then // My msg?
  begin
    edtMessage.Text := AItem.Text;
    EnterEditMode(AItem.TagString);
  end else
    ExitEditMode(not fEditDocID.IsEmpty);
end;

procedure TfmxChatMain.lsvChatResized(Sender: TObject);
var
  c: integer;
begin
  for c := 0 to lsvChat.ItemCount - 1 do
    if lsvChat.Items[c].Tag = 1 then
    begin
      lsvChat.Items[c].Objects.TextObject.TextAlign := TTextAlign.Trailing;
      lsvChat.Items[c].Objects.DetailObject.TextAlign := TTextAlign.Trailing;
    end;
end;

procedure TfmxChatMain.EnterEditMode(const DocPath: string);
begin
  fEditDocID := copy(DocPath, DocPath.LastDelimiter('/') + 2);
  btnEditMessage.Visible := true;
  btnDeleteMessage.Visible := true;
  btnPushMessage.Visible := false;
  btnEditMessage.Enabled := true;
  btnDeleteMessage.Enabled := true;
end;

procedure TfmxChatMain.ExitEditMode(ClearEditBox: boolean);
begin
  if ClearEditBox then
    edtMessage.Text := '';
  fEditDocID := '';
  btnEditMessage.Visible := false;
  btnDeleteMessage.Visible := false;
  btnPushMessage.Visible := true;
  btnPushMessage.Enabled := true;
end;

procedure TfmxChatMain.OnDeletedColDocument(const DeleteDocumentPath: string;
  TimeStamp: TDateTime);
var
  Item: TListViewItem;
begin
  Item := SearchItem(DeleteDocumentPath);
  if assigned(Item) then
    lsvChat.Items.Delete(Item.Index);
  lsvChat.Selected := nil;
  txtUpdate.Text := 'Last message deleted at ' +
    FormatDateTime('HH:NN:SS.ZZZ', TimeStamp);
end;

procedure TfmxChatMain.btnPushMessageClick(Sender: TObject);
var
  Doc: IFirestoreDocument;
begin
  Doc := TFirestoreDocument.Create(TFirebaseHelpers.CreateAutoID);
  Doc.AddOrUpdateField(TJSONObject.SetString('Message', edtMessage.Text));
  Doc.AddOrUpdateField(TJSONObject.SetString('Sender', fUserName));
  Doc.AddOrUpdateField(TJSONObject.SetString('UID', fUID));
  Doc.AddOrUpdateField(TJSONObject.SetTimeStamp('DateTime', now));
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('Doc: ' + Doc.AsJSON.ToJSON);
  {$ENDIF}
  fConfig.Database.InsertOrUpdateDocument([cDocID, Doc.DocumentName(false)],
    Doc, nil, OnDocWrite, OnDocWriteError);
  btnPushMessage.Enabled := false;
end;

procedure TfmxChatMain.btnEditMessageClick(Sender: TObject);
var
  Doc: IFirestoreDocument;
begin
  Assert(not fEditDocID.IsEmpty, 'No doc ID to patch');
  Doc := TFirestoreDocument.Create(fEditDocID);
  Doc.AddOrUpdateField(TJSONObject.SetString('Message', edtMessage.Text));
  Doc.AddOrUpdateField(TJSONObject.SetTimeStamp('Edited', now));
  fConfig.Database.PatchDocument([cDocID, fEditDocID], Doc,
    ['Message', 'Edited'], OnDocWrite, OnDocWriteError);
  btnEditMessage.Enabled := false;
  btnDeleteMessage.Enabled := false;
end;

procedure TfmxChatMain.btnDeleteMessageClick(Sender: TObject);
begin
  Assert(not fEditDocID.IsEmpty, 'No doc ID to patch');
  fConfig.Database.Delete([cDocID, fEditDocID], nil, OnDocDelete,
    OnDocDeleteError);
  btnEditMessage.Enabled := false;
  btnDeleteMessage.Enabled := false;
end;

procedure TfmxChatMain.edtMessageKeyUp(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
    if fEditDocID.IsEmpty then
      btnPushMessageClick(Sender)
    else
      btnEditMessageClick(Sender);
end;

procedure TfmxChatMain.OnDocWriteError(const RequestID, ErrMsg: string);
begin
  if btnPushMessage.Visible then
  begin
    txtError.Text := 'Failure while write message: ' + ErrMsg;
    btnPushMessage.Enabled := true
  end else begin
    txtError.Text := 'Failure while update message: ' + ErrMsg;
    btnEditMessage.Enabled := true;
    btnDeleteMessage.Enabled := true;
  end;
end;

procedure TfmxChatMain.OnDocWrite(const Info: string;
  Document: IFirestoreDocument);
begin
  if btnPushMessage.Visible then
    txtUpdate.Text := 'Last message sent on ' +
      DateTimeToStr(Document.UpdateTime)
  else
    txtUpdate.Text := 'Last message update on ' +
      DateTimeToStr(Document.UpdateTime);
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('Written ID: ' + Document.DocumentName(false));
  {$ENDIF}
  ExitEditMode(true);
end;

procedure TfmxChatMain.OnDocDelete(const RequestID: string;
  Response: IFirebaseResponse);
begin
  txtUpdate.Text := 'Last message deleted on ' + DateTimeToStr(now);
  ExitEditMode(true);
end;

procedure TfmxChatMain.OnDocDeleteError(const RequestID, ErrMsg: string);
begin
  txtUpdate.Text := 'Failre while deleted message ' + ErrMsg;
end;

procedure TfmxChatMain.OnStopListening(Sender: TObject);
begin
  txtUpdate.Text := 'Chat listener stopped';
end;

procedure TfmxChatMain.OnAuthRevoked(TokenRenewPassed: boolean);
begin
  if TokenRenewPassed then
    txtUpdate.Text := 'Chat authorization renewed'
  else
    txtError.Text := 'Chat authorization renew failed';
end;

procedure TfmxChatMain.OnListenerError(const RequestID, ErrMsg: string);
begin
  txtError.Text := 'Error in listener: ' + ErrMsg;
end;

end.
