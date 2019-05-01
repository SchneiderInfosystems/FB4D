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

unit FB4D.DemoFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.StrUtils, System.JSON,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.Edit, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation, FMX.StdCtrls,
  FMX.TabControl, FMX.DateTimeCtrls, FMX.ListBox, FMX.Layouts, FMX.EditBox,
  FMX.SpinBox,
  FB4D.Interfaces, FB4D.RealTimeDB;

type
  TfmxFirebaseDemo = class(TForm)
    edtProjectID: TEdit;
    Text1: TText;
    TabControl: TTabControl;
    tabAuth: TTabItem;
    edtKey: TEdit;
    Text2: TText;
    btnLogin: TButton;
    Label5: TLabel;
    edtToken: TEdit;
    Label6: TLabel;
    edtUID: TEdit;
    Label1: TLabel;
    edtEmail: TEdit;
    Label2: TLabel;
    edtPassword: TEdit;
    memUser: TMemo;
    btnRefresh: TButton;
    lblTokenExp: TLabel;
    timRefresh: TTimer;
    tabStorage: TTabItem;
    Label9: TLabel;
    edtStorageBucket: TEdit;
    btnGetStorageSynch: TButton;
    btnGetStorageAsynch: TButton;
    Label10: TLabel;
    memoResp: TMemo;
    btnDownloadSync: TButton;
    btnDownloadAsync: TButton;
    SaveDialog: TSaveDialog;
    btnUploadSynch: TButton;
    btnUploadAsynch: TButton;
    OpenDialog: TOpenDialog;
    Label11: TLabel;
    btnDeleteSync: TButton;
    btnDeleteAsync: TButton;
    tabScanRTEvent: TTabItem;
    btnNotifyEvent: TButton;
    memScans: TMemo;
    btnStopEvent: TButton;
    tabRealTimeDB: TTabItem;
    btnPutRTSynch: TButton;
    btnPostRTSynch: TButton;
    edtPutKeyName: TEdit;
    memRTDB: TMemo;
    btnGetRTSynch: TButton;
    btnSignUpNewUser: TButton;
    btnPasswordReset: TButton;
    tabFirestore: TTabItem;
    btnGet: TButton;
    edtCollection: TEdit;
    edtDocument: TEdit;
    Label4: TLabel;
    Label7: TLabel;
    memFirestore: TMemo;
    btnCreateDocument: TButton;
    btnInsertOrUpdateDocument: TButton;
    TabControlUser: TTabControl;
    tabInfo: TTabItem;
    tabUserProfile: TTabItem;
    edtChangeEMail: TEdit;
    txtEMail: TText;
    edtChangeDisplayName: TEdit;
    Text3: TText;
    btnChange: TButton;
    btnChangeEMail: TButton;
    edtChangePassword: TEdit;
    Text4: TText;
    btnChangePwd: TButton;
    edtChangePhotoURL: TEdit;
    txtPhotoURL: TText;
    btnChangePhotoURL: TButton;
    btnGetUserData: TButton;
    edtPath: TEdit;
    Label3: TLabel;
    btnGetRT: TButton;
    Label8: TLabel;
    edtPutKeyValue: TEdit;
    Label12: TLabel;
    lstDBNode: TListBox;
    TabControlRTDB: TTabControl;
    tabGet: TTabItem;
    tabPut: TTabItem;
    tabPost: TTabItem;
    Label13: TLabel;
    aniGetRT: TAniIndicator;
    btnAddUpdateNode: TButton;
    btnClearNode: TButton;
    btnPutRTAsynch: TButton;
    aniPutRT: TAniIndicator;
    Label14: TLabel;
    edtColumName: TEdit;
    Label15: TLabel;
    cboOrderBy: TComboBox;
    spbLimitToFirst: TSpinBox;
    Label16: TLabel;
    spbLimitToLast: TSpinBox;
    Label17: TLabel;
    Label18: TLabel;
    tabPatch: TTabItem;
    btnPatchRTSynch: TButton;
    Label19: TLabel;
    edtPatchKeyName: TEdit;
    Label20: TLabel;
    edtPatchKeyValue: TEdit;
    Label21: TLabel;
    Label22: TLabel;
    edtPostKeyName: TEdit;
    Label23: TLabel;
    edtPostKeyValue: TEdit;
    Label24: TLabel;
    tabDelete: TTabItem;
    tabServerVars: TTabItem;
    btnDelRTSynch: TButton;
    Label25: TLabel;
    btnGetServerTimeStamp: TButton;
    btnPatchRTAsynch: TButton;
    aniPatchRT: TAniIndicator;
    aniPostRT: TAniIndicator;
    btnPostRTAsynch: TButton;
    btnDelRTAsynch: TButton;
    aniDeleteRT: TAniIndicator;
    edtRTDBEventPath: TEdit;
    Label26: TLabel;
    edtStorageObject: TEdit;
    edtStoragePath: TEdit;
    btnDeleteUserAccount: TButton;
    chbComplexDoc: TCheckBox;
    procedure btnLoginClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure timRefreshTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnGetStorageSynchClick(Sender: TObject);
    procedure btnGetStorageAsynchClick(Sender: TObject);
    procedure btnDownloadSyncClick(Sender: TObject);
    procedure btnDownloadAsyncClick(Sender: TObject);
    procedure btnUploadSynchClick(Sender: TObject);
    procedure btnUploadAsynchClick(Sender: TObject);
    procedure btnDeleteSyncClick(Sender: TObject);
    procedure btnDeleteAsyncClick(Sender: TObject);
    procedure btnNotifyEventClick(Sender: TObject);
    procedure btnStopEventClick(Sender: TObject);
    procedure btnPutRTSynchClick(Sender: TObject);
    procedure btnPostRTSynchClick(Sender: TObject);
    procedure btnDelRTSynchClick(Sender: TObject);
    procedure btnPatchRTSynchClick(Sender: TObject);
    procedure btnGetRTSynchClick(Sender: TObject);
    procedure btnPasswordResetClick(Sender: TObject);
    procedure btnSignUpNewUserClick(Sender: TObject);
    procedure edtEmailChange(Sender: TObject);
    procedure TabControlChange(Sender: TObject);
    procedure btnGetClick(Sender: TObject);
    procedure btnCreateDocumentClick(Sender: TObject);
    procedure btnInsertOrUpdateDocumentClick(Sender: TObject);
    procedure btnChangeClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnChangeEMailClick(Sender: TObject);
    procedure btnChangePwdClick(Sender: TObject);
    procedure btnChangePhotoURLClick(Sender: TObject);
    procedure btnGetUserDataClick(Sender: TObject);
    procedure btnGetServerTimeStampClick(Sender: TObject);
    procedure btnGetRTClick(Sender: TObject);
    procedure btnAddUpdateNodeClick(Sender: TObject);
    procedure btnClearNodeClick(Sender: TObject);
    procedure btnPutRTAsynchClick(Sender: TObject);
    procedure cboOrderByChange(Sender: TObject);
    procedure spbLimitToFirstChange(Sender: TObject);
    procedure spbLimitToLastChange(Sender: TObject);
    procedure btnPatchRTAsynchClick(Sender: TObject);
    procedure btnPostRTAsynchClick(Sender: TObject);
    procedure btnDelRTAsynchClick(Sender: TObject);
    procedure btnDeleteUserAccountClick(Sender: TObject);
  private
    fAuth: IFirebaseAuthentication;
    fFirestoreObject: IStorageObject;
    fDatabase: IFirestoreDatabase;
    fRealTimeDB: IRealTimeDB;
    fFirebaseEvent: IFirebaseEvent;
    fDownloadStream: TFileStream;
    fStorage: IFirebaseStorage;
    fUploadStream: TFileStream;
    function CheckSignedIn(Log: TMemo): boolean;
    procedure DisplayUser(mem: TMemo; User: IFirebaseUser);
    procedure DisplayTokenJWT(mem: TMemo);
    procedure OnRecData(const Event: string; Params: TRequestResourceParam;
      JSONObj: TJSONObject);
    procedure OnRecDataError(const Info, ErrMsg: string);
    procedure OnRecDataStop(Sender: TObject);
    procedure ShowDocument(Doc: IFirestoreDocument);
    procedure OnUserResp(const Info: string; Response: IFirebaseResponse);
    procedure OnUserResponse(const Info: string; User: IFirebaseUser);
    procedure OnGetUserData(FirebaseUserList: TFirebaseUserList);
    procedure OnTokenRefresh(TokenRefreshed: boolean);
    procedure OnUserError(const Info, ErrMsg: string);
    procedure CreateAuthenticationClass;
    function CheckAndCreateFirestoreDBClass(Log: TMemo): boolean;
    procedure OnFirestoreError(const Info, ErrMsg: string);
    procedure OnFirestoreGet(const Info: string; Docs: IFirestoreDocuments);
    procedure OnFirestoreCreate(const Info: string; Doc: IFirestoreDocument);
    procedure OnFirestoreInsertOrUpdate(const Info: string;
      Doc: IFirestoreDocument);
    function CheckAndCreateRealTimeDBClass(Log: TMemo): boolean;
    function GetRTDBPath: TStringDynArray;
    function GetOptions: TQueryParams;
    function GetPathFromResParams(ResParams: TRequestResourceParam): string;
    procedure ShowRTNode(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnGetResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnGetError(const RequestID, ErrMsg: string);
    procedure OnPutResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnPutError(const RequestID, ErrMsg: string);
    procedure OnPatchResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnPatchError(const RequestID, ErrMsg: string);
    procedure OnPostResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnPostError(const RequestID, ErrMsg: string);
    procedure OnDeleteResp(Params: TRequestResourceParam; Success: boolean);
    procedure OnDeleteError(const RequestID, ErrMsg: string);
    procedure ShowFirestoreObject(Obj: IStorageObject);
    function GetStorageFileName: string;
    procedure OnGetStorage(const RequestID: string; Obj: IStorageObject);
    procedure OnGetStorageError(const RequestID, ErrMsg: string);
    procedure OnDownload(const RequestID: string; Obj: IStorageObject);
    procedure OnDownloadError(Obj: IStorageObject; const ErrorMsg: string);
    procedure OnUpload(const ObjectName: string; Obj: IStorageObject);
    procedure OnUploadError(const RequestID, ErrorMsg: string);
    procedure OnDeleteStorage(const ObjectName: string);
    procedure OnDeleteStorageError(const RequestID, ErrorMsg: string);
  end;

var
  fmxFirebaseDemo: TfmxFirebaseDemo;

implementation

{$R *.fmx}

uses
  System.Generics.Collections, System.IniFiles, System.IOUtils, System.RTTI,
  REST.Types,
  FB4D.Authentication, FB4D.OAuth, FB4D.Helpers,
  FB4D.Response, FB4D.Request, FB4D.Functions, FB4D.Storage,
  FB4D.Firestore, FB4D.Document;

{$REGION 'Form Handling'}
procedure TfmxFirebaseDemo.FormShow(Sender: TObject);
var
  IniFile: TIniFile;
begin
  OpenDialog.Filter := TBitmapCodecManager.GetFilterString;
  TabControl.ActiveTab := tabAuth;
  IniFile := TIniFile.Create(IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini'));
  try
    edtKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text := IniFile.ReadString('FBProjectSettings', 'ProjectID',
      '');
    edtEmail.Text := IniFile.ReadString('Authentication', 'User', '');
    edtPassword.Text := IniFile.ReadString('Authentication', 'Pwd', '');
    edtPath.Text := IniFile.ReadString('RTDB', 'DBPath', 'TestNode');
    edtRTDBEventPath.Text := IniFile.ReadString('RTDBEvent', 'DBPath',
      'TestNode');
    edtStorageBucket.Text := IniFile.ReadString('Storage', 'Bucket', '');
    edtStorageObject.Text := IniFile.ReadString('Storage', 'Object', '');
    edtStoragePath.Text := IniFile.ReadString('Storage', 'Path', '');
    edtCollection.Text := IniFile.ReadString('Firestore', 'Collection', '');
    edtDocument.Text := IniFile.ReadString('Firestore', 'Document', '');
  finally
    IniFile.Free;
  end;
end;

procedure TfmxFirebaseDemo.FormClose(Sender: TObject; var Action: TCloseAction);
var
  IniFile: TIniFile;
begin
  if assigned(fRealTimeDB) and assigned(fFirebaseEvent) then
    fFirebaseEvent.StopListening;

  IniFile := TIniFile.Create(IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini'));
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('Authentication', 'User', edtEmail.Text);
    {$MESSAGE 'Attention: Password will be stored in your inifile in clear text'}
    IniFile.WriteString('Authentication', 'Pwd', edtPassword.Text);
    IniFile.WriteString('RTDB', 'DBPath', edtPath.Text);
    IniFile.WriteString('RTDBEvent', 'DBPath', edtRTDBEventPath.Text);
    IniFile.WriteString('Storage', 'Bucket', edtStorageBucket.Text);
    IniFile.WriteString('Storage', 'Object', edtStorageObject.Text);
    IniFile.WriteString('Storage', 'Path', edtStoragePath.Text);
    IniFile.WriteString('Firestore', 'Collection', edtCollection.Text);
    IniFile.WriteString('Firestore', 'Document', edtDocument.Text);
  finally
    IniFile.Free;
  end;
end;

procedure TfmxFirebaseDemo.TabControlChange(Sender: TObject);
begin
  if assigned(fAuth) and (TabControl.ActiveTab = tabAuth) and
    (edtToken.Text <> fAuth.Token) then
  begin
    lblTokenExp.Text := 'expires at ' + DateTimeToStr(fAuth.TokenExpiryDT);
    edtToken.Text := fAuth.Token;
    memUser.Lines.Add('Token automatically refreshed ' + fAuth.GetRefreshToken);
  end;
end;
{$ENDREGION }

{$REGION 'Authentication'}
procedure TfmxFirebaseDemo.CreateAuthenticationClass;
begin
  if not assigned(fAuth) then
  begin
    fAuth := TFirebaseAuthentication.Create(edtKey.Text);
    edtKey.ReadOnly := true;
    edtProjectID.ReadOnly := true;
  end;
end;

procedure TfmxFirebaseDemo.btnLoginClick(Sender: TObject);
begin
  CreateAuthenticationClass;
  if edtEMail.Text.IsEmpty then
  begin
    fAuth.SignInAnonymously(OnUserResponse, OnUserError);
  end else
    fAuth.SignInWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
      OnUserResponse, OnUserError);
end;

procedure TfmxFirebaseDemo.btnSignUpNewUserClick(Sender: TObject);
begin
  CreateAuthenticationClass;
  fAuth.SignUpWithEmailAndPassword(edtEmail.Text, edtPassword.Text,
    OnUserResponse, OnUserError);
end;

procedure TfmxFirebaseDemo.OnUserResponse(const Info: string;
  User: IFirebaseUser);
begin
  memUser.Lines.Clear;
  DisplayUser(memUser, User);
  edtToken.Text := fAuth.Token;
  edtUID.Text := User.UID;
  lblTokenExp.Text := 'expires at ' + DateTimeToStr(fAuth.TokenExpiryDT);
  btnRefresh.Enabled := false;
  btnRefresh.Visible := fAuth.Authenticated;
  btnPasswordReset.Visible := not fAuth.Authenticated;
  timRefresh.Enabled := btnRefresh.Visible;
  btnLogin.Visible := not User.IsNewSignupUser;
  btnSignUpNewUser.Visible := User.IsNewSignupUser;
end;

procedure TfmxFirebaseDemo.OnUserResp(const Info: string;
  Response: IFirebaseResponse);
begin
  if Response.StatusOk then
    memUser.Lines.Add(Info + ' done')
  else if not Response.ErrorMsg.IsEmpty then
    memUser.Lines.Add(Info + ' failed: ' + Response.ErrorMsg)
  else
    memUser.Lines.Add(Info + ' failed: ' + Response.StatusText);
end;

procedure TfmxFirebaseDemo.OnUserError(const Info, ErrMsg: string);
begin
  memUser.Lines.Add(Info + ' failed: ' + ErrMsg);
  ShowMessage(Info + ' failed: ' + ErrMsg);
end;

procedure TfmxFirebaseDemo.btnPasswordResetClick(Sender: TObject);
begin
  CreateAuthenticationClass;
  fAuth.SendPasswordResetEMail(edtEmail.Text, OnUserResp, OnUserError);
end;

procedure TfmxFirebaseDemo.edtEmailChange(Sender: TObject);
begin
  if edtEmail.Text.IsEmpty then
    btnLogin.Text := 'Anonymous Login'
  else
    btnLogin.Text := 'Login';
  btnPasswordReset.Enabled := not edtEmail.Text.IsEmpty;
end;

procedure TfmxFirebaseDemo.btnRefreshClick(Sender: TObject);
begin
  if fAuth.NeedTokenRefresh then
    fAuth.RefreshToken(OnTokenRefresh, onUserError);
end;

procedure TfmxFirebaseDemo.OnTokenRefresh(TokenRefreshed: boolean);
begin
  if TokenRefreshed then
  begin
    memUser.Lines.Add('Token refreshed at ' + DateTimeToStr(now));
    edtToken.Text := fAuth.Token;
    DisplayTokenJWT(memUser);
    lblTokenExp.Text := 'expires at ' + DateTimeToStr(fAuth.TokenExpiryDT);
    memUser.Lines.Add('Refresh token ' + fAuth.GetRefreshToken);
  end else
    memUser.Lines.Add('Token refresh failed at ' + DateTimeToStr(now));
end;

procedure TfmxFirebaseDemo.DisplayTokenJWT(mem: TMemo);
var
  c: integer;
begin
  mem.Lines.Add('JWT.Header:');
  for c := 0 to fAuth.TokenJWT.Header.JSON.Count - 1 do
    mem.Lines.Add('  ' +
      fAuth.TokenJWT.Header.JSON.Pairs[c].JsonString.Value + ': ' +
      fAuth.TokenJWT.Header.JSON.Pairs[c].JsonValue.Value);
  mem.Lines.Add('JWT.Claims:');
  for c := 0 to fAuth.TokenJWT.Claims.JSON.Count - 1 do
    if fAuth.TokenJWT.Claims.JSON.Pairs[c].JsonValue is TJSONString then
      mem.Lines.Add('  ' +
        fAuth.TokenJWT.Claims.JSON.Pairs[c].JsonString.Value + ': ' +
        fAuth.TokenJWT.Claims.JSON.Pairs[c].JsonValue.Value)
    else
      mem.Lines.Add('  ' +
        fAuth.TokenJWT.Claims.JSON.Pairs[c].JsonString.Value + ': ' +
        fAuth.TokenJWT.Claims.JSON.Pairs[c].JsonValue.ToJSON);
  if fAuth.TokenJWT.VerifySignature then
    mem.Lines.Add('Token signatur verified')
  else
    mem.Lines.Add('Token signatur broken');
end;

procedure TfmxFirebaseDemo.DisplayUser(mem: TMemo; User: IFirebaseUser);
begin
  mem.Lines.Add('UID: ' + User.UID);
  case User.IsDisabled of
    tsbTrue:
      memUser.Lines.Add('  User is disabled');
    tsbFalse:
      memUser.Lines.Add('  User is not disabled');
  end;
  if User.IsDisplayNameAvailable then
    mem.Lines.Add('Display name: ' + User.DisplayName);
  if User.IsEMailAvailable then
  begin
    mem.Lines.Add('EMail: ' + User.EMail);
    case User.IsEMailVerified of
      tsbTrue:
        memUser.Lines.Add('  EMail is verified');
      tsbFalse:
        memUser.Lines.Add('  EMail is not verified');
    end;
  end;
  if User.IsCreatedAtAvailable then
    mem.Lines.Add('User created at: ' + DateTimeToStr(User.CreatedAt));
  if User.IsLastLoginAtAvailable then
    mem.Lines.Add('Last login at: ' + DateTimeToStr(User.LastLoginAt));
  if User.IsPhotoURLAvailable then
    mem.Lines.Add('Photo URL: ' + User.PhotoURL);
  mem.Lines.Add('Refresh token ' + fAuth.GetRefreshToken);
  if assigned(fAuth.TokenJWT) then
    DisplayTokenJWT(memUser);
  if not edtEMail.Text.IsEmpty then
  begin
    if User.IsDisplayNameAvailable then
      edtChangeDisplayName.Text := User.DisplayName
    else
      edtChangeDisplayName.Text := 'n/a';
    if User.IsEMailAvailable then
      edtChangeEMail.Text := User.EMail
    else
      edtChangeEMail.Text := 'n/a';
    if User.IsPhotoURLAvailable then
      edtChangePhotoURL.Text := User.PhotoURL
    else
      edtChangePhotoURL.Text := '';
  end;
end;

procedure TfmxFirebaseDemo.btnGetUserDataClick(Sender: TObject);
begin
  memUser.Lines.Clear;
  fAuth.GetUserData(OnGetUserData, OnUserError);
end;

procedure TfmxFirebaseDemo.OnGetUserData(
  FirebaseUserList: TFirebaseUserList);
var
  User: IFirebaseUser;
begin
  for User in FirebaseUserList do
    DisplayUser(memUser, User);
end;

procedure TfmxFirebaseDemo.btnChangeClick(Sender: TObject);
begin
  fAuth.ChangeProfile('', '', edtChangeDisplayName.Text, '', OnUserResp,
    OnUserError);
end;

procedure TfmxFirebaseDemo.btnChangeEMailClick(Sender: TObject);
begin
  fAuth.ChangeProfile(edtChangeEMail.Text, '', '', '', OnUserResp,
    OnUserError);
end;

procedure TfmxFirebaseDemo.btnChangePwdClick(Sender: TObject);
begin
  fAuth.ChangeProfile('', edtChangePassword.Text, '', '', OnUserResp,
    OnUserError);
end;

procedure TfmxFirebaseDemo.btnChangePhotoURLClick(Sender: TObject);
begin
  fAuth.ChangeProfile('', '', '', edtChangePhotoURL.Text, OnUserResp,
    OnUserError);
end;

procedure TfmxFirebaseDemo.timRefreshTimer(Sender: TObject);
begin
  if assigned(fAuth) then
    btnRefresh.Enabled := fAuth.NeedTokenRefresh;
end;

function TfmxFirebaseDemo.CheckSignedIn(Log: TMemo): boolean;
begin
  if assigned(fAuth) and fAuth.Authenticated then
    result := true
  else begin
    Log.Lines.Add('Please sign in first!');
    Log.GoToTextEnd;
    result := false;
  end;
end;

procedure TfmxFirebaseDemo.btnDeleteUserAccountClick(Sender: TObject);
begin
  fAuth.DeleteCurrentUser(OnUserResp, OnUserError);
end;
{$ENDREGION}

{$REGION 'Storage'}

function TfmxFirebaseDemo.GetStorageFileName: string;
begin
  result := edtStoragePath.Text;
  if (result.Length > 0) and (result[High(result)] <> '/') then
    result := result + '/';
  result := result + edtStorageObject.Text;
end;

procedure TfmxFirebaseDemo.btnGetStorageSynchClick(Sender: TObject);
var
  Storage: TFirebaseStorage;
begin
  if not CheckSignedIn(memoResp) then
    exit;
  Storage := TFirebaseStorage.Create(edtStorageBucket.Text, fAuth);
  // We could use also fStorage here but in order to demontrate the more simple
  // way of synchronous calls we use a local TFirebaseStorage
  try
    fFirestoreObject := Storage.GetSynchronous(GetStorageFileName);
    memoResp.Lines.Text := 'Firestore object synchronous retrieven';
    ShowFirestoreObject(fFirestoreObject);
    if assigned(fFirestoreObject) then
      btnDownloadSync.Enabled := fFirestoreObject.DownloadToken > ''
    else
      btnDownloadSync.Enabled := false;
    btnDownloadAsync.Enabled := btnDownloadSync.Enabled;
    btnDeleteSync.Enabled := btnDownloadSync.Enabled;
    btnDeleteAsync.Enabled := btnDeleteSync.Enabled;
  finally
    Storage.Free;
  end;
end;

procedure TfmxFirebaseDemo.btnGetStorageAsynchClick(Sender: TObject);
begin
  if not CheckSignedIn(memoResp) then
    exit;
  if not assigned(fStorage) then
    fStorage := TFirebaseStorage.Create(edtStorageBucket.Text, fAuth);
  fStorage.Get(GetStorageFileName, 'Get asynchronous Storage', OnGetStorage,
    OnGetStorageError);
end;

procedure TfmxFirebaseDemo.OnGetStorage(const RequestID: string;
  Obj: IStorageObject);
begin
  memoResp.Lines.Text := 'Firestore object asynchronous retrieven';
  ShowFirestoreObject(Obj);
  if assigned(Obj) then
    btnDownloadSync.Enabled := Obj.DownloadToken > ''
  else
    btnDownloadSync.Enabled := false;
  btnDownloadAsync.Enabled := btnDownloadSync.Enabled;
  btnDeleteSync.Enabled := btnDownloadSync.Enabled;
  btnDeleteAsync.Enabled := btnDeleteSync.Enabled;
  fFirestoreObject := Obj;
end;

procedure TfmxFirebaseDemo.OnGetStorageError(const RequestID, ErrMsg: string);
begin
  memoResp.Lines.Text := 'Error while asynchronous get for ' + RequestID;
  memoResp.Lines.Add('Error: ' + ErrMsg);
end;

procedure TfmxFirebaseDemo.ShowFirestoreObject(Obj: IStorageObject);
begin
  if assigned(Obj) then
  begin
    memoResp.Lines.Add('ObjectName: ' + Obj.ObjectName(false));
    memoResp.Lines.Add('Path: ' + Obj.Path);
    memoResp.Lines.Add('Type: ' + Obj.ContentType);
    memoResp.Lines.Add('Size: ' +
      Format('%.0n bytes', [extended(Obj.Size)]));
    memoResp.Lines.Add('Created: ' +
      DateTimeToStr(Obj.createTime));
    memoResp.Lines.Add('Updated: ' +
      DateTimeToStr(Obj.updateTime));
    memoResp.Lines.Add('Download URL: ' + Obj.DownloadUrl);
    memoResp.Lines.Add('MD5 hash code: ' + Obj.MD5HashCode);
    memoResp.Lines.Add('E-Tag: ' + Obj.etag);
    memoResp.Lines.Add('generation: ' + IntTostr(Obj.generation));
    memoResp.Lines.Add('Meta Generation: ' +
      IntTostr(Obj.metaGeneration));
  end else
    memoResp.Lines.Text := 'No firestore object';
end;

procedure TfmxFirebaseDemo.btnDownloadAsyncClick(Sender: TObject);
begin
  Assert(assigned(fFirestoreObject), 'Firestore object is missing');
  SaveDialog.FileName := fFirestoreObject.ObjectName(false);
  if SaveDialog.Execute then
  begin
    FreeAndNil(fDownloadStream);
    fDownloadStream := TFileStream.Create(SaveDialog.FileName, fmCreate);
    fFirestoreObject.DownloadToStream(SaveDialog.FileName, fDownloadStream,
      OnDownload, OnDownloadError);
    memoResp.Lines.Add(fFirestoreObject.ObjectName(true) + ' download started');
  end;
end;

procedure TfmxFirebaseDemo.btnDownloadSyncClick(Sender: TObject);
var
  Stream: TFileStream;
begin
  Assert(assigned(fFirestoreObject), 'Firestore object is missing');
  SaveDialog.FileName := fFirestoreObject.ObjectName(false);
  if SaveDialog.Execute then
  begin
    Stream := TFileStream.Create(SaveDialog.FileName, fmCreate);
    try
      fFirestoreObject.DownloadToStreamSynchronous(Stream);
      memoResp.Lines.Add(fFirestoreObject.ObjectName(true) + ' downloaded to ' +
        SaveDialog.FileName);
    finally
      Stream.Free;
    end;
  end;
end;

procedure TfmxFirebaseDemo.OnDownload(const RequestID: string;
  Obj: IStorageObject);
begin
  memoResp.Lines.Add(Obj.ObjectName(true) + ' downloaded to ' +
    SaveDialog.FileName + ' passed');
  FreeAndNil(fDownloadStream);
end;

procedure TfmxFirebaseDemo.OnDownloadError(Obj: IStorageObject;
  const ErrorMsg: string);
begin
  memoResp.Lines.Add(Obj.ObjectName(true) + ' downloaded to ' +
    SaveDialog.FileName + ' failed: ' + ErrorMsg);
  FreeAndNil(fDownloadStream);
end;

procedure TfmxFirebaseDemo.btnUploadSynchClick(Sender: TObject);
var
  Storage: TFirebaseStorage;
  fs: TFileStream;
  ExtType: string;
  ContentType: TRESTContentType;
  ObjectName: string;
  Obj: IStorageObject;
begin
  if not CheckSignedIn(memoResp) then
    exit;
  if OpenDialog.Execute then
  begin
    ExtType := LowerCase(ExtractFileExt(OpenDialog.FileName).Substring(1));
    if (ExtType = 'jpg') or (ExtType = 'jpeg') then
      ContentType := TRESTContentType.ctIMAGE_JPEG
    else if ExtType = 'png' then
      ContentType := TRESTContentType.ctIMAGE_PNG
    else if ExtType = 'gif' then
      ContentType := TRESTContentType.ctIMAGE_GIF
    else if ExtType = 'mp4' then
      ContentType := TRESTContentType.ctVIDEO_MP4
    else
      ContentType := TRESTContentType.ctNone;
    edtStorageObject.Text := ExtractFilename(OpenDialog.FileName);
    ObjectName := GetStorageFileName;
    Storage := TFirebaseStorage.Create(edtStorageBucket.Text, fAuth);
    try
      fs := TFileStream.Create(OpenDialog.FileName, fmOpenRead);
      try
        Obj := Storage.UploadSynchronousFromStream(fs, ObjectName, ContentType);
        memoResp.Lines.Text := 'Firestore object synchronous uploaded';
        ShowFirestoreObject(Obj);
      finally
        fs.Free;
      end;
    finally
      Storage.Free;
    end;
  end;
end;

procedure TfmxFirebaseDemo.btnUploadAsynchClick(Sender: TObject);
var
  ExtType: string;
  ContentType: TRESTContentType;
  ObjectName: string;
begin
  if not CheckSignedIn(memoResp) then
    exit;
  if assigned(fUploadStream) then
  begin
    memoResp.Lines.Add('Wait until previous upload is finisehd');
    memoResp.GoToTextEnd;
  end;
  if OpenDialog.Execute then
  begin
    ExtType := LowerCase(ExtractFileExt(OpenDialog.FileName).Substring(1));
    if (ExtType = 'jpg') or (ExtType = 'jpeg') then
      ContentType := TRESTContentType.ctIMAGE_JPEG
    else if ExtType = 'png' then
      ContentType := TRESTContentType.ctIMAGE_PNG
    else if ExtType = 'gif' then
      ContentType := TRESTContentType.ctIMAGE_GIF
    else if ExtType = 'mp4' then
      ContentType := TRESTContentType.ctVIDEO_MP4
    else
      ContentType := TRESTContentType.ctNone;
    edtStorageObject.Text := ExtractFilename(OpenDialog.FileName);
    ObjectName := GetStorageFileName;
    if not assigned(fStorage) then
      fStorage := TFirebaseStorage.Create(edtStorageBucket.Text, fAuth);
    fUploadStream := TFileStream.Create(OpenDialog.FileName, fmOpenRead);
    fStorage.UploadFromStream(fUploadStream, ObjectName, ContentType,
      OnUpload, OnUploadError);
  end;
end;

procedure TfmxFirebaseDemo.OnUpload(const ObjectName: string;
  Obj: IStorageObject);
begin
  memoResp.Lines.Text := 'Firestore object asynchronous uploaded';
  ShowFirestoreObject(Obj);
  FreeAndNil(fUploadStream);
end;

procedure TfmxFirebaseDemo.OnUploadError(const RequestID, ErrorMsg: string);
begin
  memoResp.Lines.Text := 'Error while asynchronous upload of ' + RequestID;
  memoResp.Lines.Add('Error: ' + ErrorMsg);
  FreeAndNil(fUploadStream);
end;

procedure TfmxFirebaseDemo.btnDeleteSyncClick(Sender: TObject);
var
  Storage: TFirebaseStorage;
begin
  Storage := TFirebaseStorage.Create(edtStorageBucket.Text, fAuth);
  try
    Storage.DeleteSynchronous(GetStorageFileName);
    memoResp.Lines.Text := GetStorageFileName + ' synchronous deleted';
    btnDownloadSync.Enabled := false;
    btnDownloadAsync.Enabled :=  false;
    btnDeleteSync.Enabled := false;
    btnDeleteAsync.Enabled := false;
  finally
    Storage.Free;
  end;
end;

procedure TfmxFirebaseDemo.btnDeleteAsyncClick(Sender: TObject);
begin
  if not assigned(fStorage) then
    fStorage := TFirebaseStorage.Create(edtStorageBucket.Text, fAuth);
  fStorage.Delete(GetStorageFileName, OnDeleteStorage, OnDeleteStorageError);
end;

procedure TfmxFirebaseDemo.OnDeleteStorage(const ObjectName: string);
begin
  memoResp.Lines.Text := GetStorageFileName + ' asynchronous deleted';
  btnDownloadSync.Enabled := false;
  btnDownloadAsync.Enabled :=  false;
  btnDeleteSync.Enabled := false;
  btnDeleteAsync.Enabled := false;
end;

procedure TfmxFirebaseDemo.OnDeleteStorageError(const RequestID,
  ErrorMsg: string);
begin
  memoResp.Lines.Text := 'Error while asynchronous delete of ' + RequestID;
  memoResp.Lines.Add('Error: ' + ErrorMsg);
end;

{$ENDREGION}

{$REGION 'Firestore DB'}
function TfmxFirebaseDemo.CheckAndCreateFirestoreDBClass(Log: TMemo): boolean;
begin
  if not CheckSignedIn(Log) then
    exit(false);
  if not assigned(fDatabase) then
  begin
    fDatabase := TFirestoreDatabase.Create(edtProjectID.Text, fAuth);
    edtProjectID.enabled := false;
  end;
  result := true;
end;

procedure TfmxFirebaseDemo.OnFirestoreError(const Info, ErrMsg: string);
begin
  memFirestore.Lines.Add(Info + ' failed: ' + ErrMsg);
  memFirestore.GoToTextEnd;
end;

procedure TfmxFirebaseDemo.btnGetClick(Sender: TObject);
begin
  if not CheckAndCreateFirestoreDBClass(memFirestore) then
    exit;
  fDatabase.Get([edtCollection.Text, edtDocument.Text], nil,
    OnFirestoreGet, OnFirestoreError);
end;

procedure TfmxFirebaseDemo.OnFirestoreGet(const Info: string;
  Docs: IFirestoreDocuments);
var
  c: integer;
begin
  try
    if assigned(Docs) and (Docs.Count > 0) then
      for c := 0 to Docs.Count - 1 do
        ShowDocument(Docs.Document(c))
    else
      ShowDocument(nil);
  except
    on e: exception do
      OnFirestoreError(Info, e.Message);
  end;
end;

procedure TfmxFirebaseDemo.btnCreateDocumentClick(Sender: TObject);
begin
  if not CheckAndCreateFirestoreDBClass(memFirestore) then
    exit;
  fDatabase.CreateDocument([edtCollection.Text], nil, OnFirestoreCreate,
    OnFirestoreError);
end;

procedure TfmxFirebaseDemo.OnFirestoreCreate(const Info: string;
  Doc: IFirestoreDocument);
begin
  try
    ShowDocument(Doc);
    if assigned(Doc) then
      edtDocument.Text := Doc.DocumentName(false)
    else
      edtDocument.Text := '';
  except
    on e: exception do
      OnFirestoreError(Info, e.Message);
  end;
end;

procedure TfmxFirebaseDemo.btnInsertOrUpdateDocumentClick(Sender: TObject);
var
  Doc: IFirestoreDocument;
begin
  if not CheckAndCreateFirestoreDBClass(memFirestore) then
    exit;
  Doc := TFirestoreDocument.Create(edtDocument.Text);
  if chbComplexDoc.IsChecked then
  begin
    Doc.AddOrUpdateField('MyString', TJSONObject.SetStringValue('Text'));
    Doc.AddOrUpdateField('MyInt', TJSONObject.SetIntegerValue(123));
    Doc.AddOrUpdateField('MyReal', TJSONObject.SetDoubleValue(1.54));
    Doc.AddOrUpdateField('MyBool', TJSONObject.SetBooleanValue(true));
    Doc.AddOrUpdateField('MyTime', TJSONObject.SetTimeStampValue(now));
  end else
    Doc.AddOrUpdateField('TestField', TJSONObject.SetStringValue('TestValue'));
  fDatabase.InsertOrUpdateDocument([edtCollection.Text, edtDocument.Text], Doc,
    nil, OnFirestoreInsertOrUpdate, OnFirestoreError);
end;

procedure TfmxFirebaseDemo.OnFirestoreInsertOrUpdate(const Info: string;
  Doc: IFirestoreDocument);
begin
  try
    ShowDocument(Doc);
    if assigned(Doc) then
      edtDocument.Text := Doc.DocumentName(false)
    else
      edtDocument.Text := '';
  except
    on e: exception do
      OnFirestoreError(Info, e.Message);
  end;
end;

procedure TfmxFirebaseDemo.ShowDocument(Doc: IFirestoreDocument);
var
  c, d: integer;
  FieldName: string;
begin
  if assigned(Doc) then
  begin
    memFirestore.Lines.Clear;
    memFirestore.Lines.Add('Document name: ' + Doc.DocumentName(true));
    memFirestore.Lines.Add('Created      : ' + DateTimeToStr(
      TFirebaseHelpers.ConvertToLocalDateTime(doc.createTime)));
    memFirestore.Lines.Add('Updated      : ' + DateTimeToStr(
      TFirebaseHelpers.ConvertToLocalDateTime(doc.updateTime)));
    for c := 0 to Doc.CountFields - 1 do
    begin
      FieldName := Doc.FieldName(c);
      memFirestore.Lines.Add(FieldName + ' : ' +
        TRttiEnumerationType.GetName<TFirestoreFieldType>(Doc.FieldType(c)) +
        ' = ' + Doc.GetValue(c).ToJSON);
      case Doc.FieldType(c) of
        fftNull:
          memFirestore.Lines.Add('  Null');
        fftBoolean:
          memFirestore.Lines.Add('  ' +
            BoolToStr(Doc.GetBoolValue(FieldName), true));
        fftInteger:
          memFirestore.Lines.Add('  ' + Doc.GetIntegerValue(FieldName).ToString);
        fftDouble:
          memFirestore.Lines.Add('  ' + Doc.GetDoubleValue(FieldName).ToString);
        fftTimeStamp:
          memFirestore.Lines.Add('  ' +
            DateTimeToStr(Doc.GetTimeStampValue(FieldName)));
        fftString:
          memFirestore.Lines.Add('  ' + Doc.GetStringValue(FieldName));
        fftGeoPoint:
          memFirestore.Lines.Add(Format('  [%f2.10°N, %f2.10°E]',
            [Doc.GetGeoPoint(FieldName).Latitude,
             Doc.GetGeoPoint(FieldName).Longitude]));
        fftReference:
          memFirestore.Lines.Add('  ' + Doc.GetReference(FieldName));
        fftArray:
          for d := 0 to Doc.GetArraySize(FieldName) - 1 do
          begin
            memFirestore.Lines.Add('  [' + d.ToString + ']: ' +
              TRttiEnumerationType.GetName<TFirestoreFieldType>(
                Doc.GetArrayType(FieldName, d)) + ' = ' +
              Doc.GetArrayValue(FieldName, d).ToJSON);
          end;
        fftMap:
          for d := 0 to Doc.GetMapSize(FieldName) - 1 do
          begin
            memFirestore.Lines.Add('  [' + d.ToString + ']: ' +
              TRttiEnumerationType.GetName<TFirestoreFieldType>(
                Doc.GetMapType(FieldName, d)) + ' = ' +
              Doc.GetMapValue(FieldName, d).Value);
          end;
        fftBytes:
          memFirestore.Lines.Add('not yet supported');
      end;
    end;
  end else
    memFirestore.Lines.Add('No document found');
end;
{$ENDREGION}

{$REGION 'Realtime DB'}
const
  sUnauthorized = 'Unauthorized';
  sHintToDBRules = 'For first steps setup the Realtime Database Rules to '#13 +
    '{'#13'  "rules": {'#13'     ".read": "auth != null",'#13'     ".write": ' +
    '"auth != null"'#13'  }'#13'}';

function TfmxFirebaseDemo.CheckAndCreateRealTimeDBClass(Log: TMemo): boolean;
begin
  if not CheckSignedIn(Log) then
    exit(false);
  if not assigned(fRealTimeDB) then
  begin
    fRealTimeDB := TRealTimeDB.Create(edtProjectID.Text, fAuth);
    edtProjectID.enabled := false;
    fFirebaseEvent := nil;
  end;
  result := true;
end;

function TfmxFirebaseDemo.GetRTDBPath: TStringDynArray;
begin
  result := SplitString(edtPath.Text.Replace('\', '/'), '/');
end;

procedure TfmxFirebaseDemo.cboOrderByChange(Sender: TObject);
begin
  edtColumName.Visible := cboOrderBy.ItemIndex = 1;
end;

procedure TfmxFirebaseDemo.spbLimitToFirstChange(Sender: TObject);
begin
  spbLimitToLast.Value := 0;
end;

procedure TfmxFirebaseDemo.spbLimitToLastChange(Sender: TObject);
begin
  spbLimitToFirst.Value := 0;
end;

function TfmxFirebaseDemo.GetOptions: TQueryParams;
const
  sQuery = '"$%s"';
begin
  result := nil;
  if (cboOrderBy.ItemIndex = 1) and (not edtColumName.Text.IsEmpty) then
  begin
    result := TQueryParams.Create;
    result.Add(cGetQueryParamOrderBy, '"' + edtColumName.Text + '"');
  end
  else if cboOrderBy.ItemIndex > 1 then
  begin
    result := TQueryParams.Create;
    result.Add(cGetQueryParamOrderBy,
      Format(sQuery, [cboOrderBy.Items[cboOrderBy.ItemIndex]]))
  end;
  if spbLimitToFirst.Value > 0 then
  begin
    if not assigned(result) then
      result := TQueryParams.Create;
    result.Add(cGetQueryParamLimitToFirst, spbLimitToFirst.Value.toString);
  end;
  if spbLimitToLast.Value > 0 then
  begin
    if not assigned(result) then
      result := TQueryParams.Create;
    result.Add(cGetQueryParamLimitToLast, spbLimitToLast.Value.toString);
  end;
end;

function TfmxFirebaseDemo.GetPathFromResParams(
  ResParams: TRequestResourceParam): string;
var
  i: integer;
begin
  result := '';
  for i := low(ResParams) to high(ResParams) do
    if i = low(ResParams) then
      result := ResParams[i]
    else
      result := result + '/' + ResParams[i];
end;

procedure TfmxFirebaseDemo.btnGetRTSynchClick(Sender: TObject);
var
  Val: TJSONValue;
  Query: TQueryParams;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  memRTDB.Lines.Clear;
  try
    Query := GetOptions;
    try
      Val := fRealTimeDB.GetSynchronous(GetRTDBPath, Query);
      try
        ShowRTNode(GetRTDBPath, Val);
      finally
        Val.Free;
      end;
    finally
      Query.Free;
    end;
  except
    on e: exception do
      memRTDB.Lines.Add('Get ' + GetPathFromResParams(GetRTDBPath) +
        ' failed: ' + e.Message);
  end;
end;

procedure TfmxFirebaseDemo.ShowRTNode(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
var
  Obj: TJSONObject;
  c: integer;
begin
  try
    if Val is TJSONObject then
    begin
      Obj := Val as TJSONObject;
      for c := 0 to Obj.Count - 1 do
        memRTDB.Lines.Add(Obj.Pairs[c].JsonString.Value + ': ' +
          Obj.Pairs[c].JsonValue.ToJSON);
    end
    else if not(Val is TJSONNull) then
      memRTDB.Lines.Add(Val.ToString)
    else
      memRTDB.Lines.Add(Format('Path %s not found',
        [GetPathFromResParams(ResourceParams)]));
  except
    on e: exception do
      memRTDB.Lines.Add('Show RT Node failed: ' + e.Message);
  end
end;

procedure TfmxFirebaseDemo.btnGetRTClick(Sender: TObject);
var
  Query: TQueryParams;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  Query := GetOptions;
  try
    fRealTimeDB.Get(GetRTDBPath, OnGetResp, OnGetError, Query);
  finally
    Query.Free;
  end;
  memRTDB.Lines.Clear;
  aniGetRT.Enabled := true;
  aniGetRT.Visible := true;
end;

procedure TfmxFirebaseDemo.OnGetResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniGetRT.Visible := false;
  aniGetRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TfmxFirebaseDemo.OnGetError(const RequestID, ErrMsg: string);
begin
  aniGetRT.Enabled := false;
  aniGetRT.Visible := false;
  memRTDB.Lines.Add('Get ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(sHintToDBRules);
end;

procedure TfmxFirebaseDemo.btnAddUpdateNodeClick(Sender: TObject);
begin
  if edtPutKeyName.Text.IsEmpty then
    edtPutKeyName.SetFocus
  else if edtPutKeyValue.Text.IsEmpty then
    edtPutKeyValue.SetFocus
  else begin
    if lstDBNode.Items.IndexOfName(edtPutKeyName.Text) < 0 then
      lstDBNode.Items.AddPair(edtPutKeyName.Text, edtPutKeyValue.Text)
    else
      lstDBNode.Items.Values[edtPutKeyName.Text] := edtPutKeyValue.Text;
  end;
end;

procedure TfmxFirebaseDemo.btnClearNodeClick(Sender: TObject);
begin
  lstDBNode.Clear;
end;

procedure TfmxFirebaseDemo.btnPutRTSynchClick(Sender: TObject);
var
  Data: TJSONObject;
  Val: TJSONValue;
  c: integer;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  if lstDBNode.Items.Count = 0 then
  begin
    memRTDB.Lines.Add('Add first elements to the node');
    exit;
  end;
  Data := TJSONObject.Create;
  Val := nil;
  try
    for c := 0 to lstDBNode.Items.Count - 1 do
      Data.AddPair(lstDBNode.Items.Names[c], lstDBNode.Items.ValueFromIndex[c]);
    memRTDB.Lines.Clear;
    try
      Val := fRealTimeDB.PutSynchronous(GetRTDBPath, Data);
      ShowRTNode(GetRTDBPath, Val);
    except
      on e: exception do
        memRTDB.Lines.Add('Put ' + GetPathFromResParams(GetRTDBPath) +
          ' failed: ' + e.Message);
    end;
  finally
    Val.Free;
    Data.Free;
  end;
end;

procedure TfmxFirebaseDemo.btnPutRTAsynchClick(Sender: TObject);
var
  Data: TJSONObject;
  c: integer;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  if lstDBNode.Items.Count = 0 then
  begin
    memRTDB.Lines.Add('Add first elements to the node');
    exit;
  end;
  Data := TJSONObject.Create;
  try
    for c := 0 to lstDBNode.Items.Count - 1 do
      Data.AddPair(lstDBNode.Items.Names[c], lstDBNode.Items.ValueFromIndex[c]);
    fRealTimeDB.Put(GetRTDBPath, Data, OnPutResp, OnPutError);
  finally
    Data.Free;
  end;
  memRTDB.Lines.Clear;
  aniPutRT.Enabled := true;
  aniPutRT.Visible := true;
end;

procedure TfmxFirebaseDemo.OnPutResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniPutRT.Visible := false;
  aniPutRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TfmxFirebaseDemo.OnPutError(const RequestID, ErrMsg: string);
begin
  aniPutRT.Visible := false;
  aniPutRT.Enabled := false;
  memRTDB.Lines.Add('Put ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(sHintToDBRules);
end;

procedure TfmxFirebaseDemo.btnPostRTSynchClick(Sender: TObject);
var
  Data: TJSONObject;
  Val: TJSONValue;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  Data := TJSONObject.Create;
  Val := nil;
  try
    Data.AddPair(edtPostKeyName.Text, edtPostKeyValue.Text);
    memRTDB.Lines.Clear;
    try
      Val := fRealTimeDB.PostSynchronous(GetRTDBPath, Data);
      ShowRTNode(GetRTDBPath, Val);
    except
      on e: exception do
        memRTDB.Lines.Add('Post ' + GetPathFromResParams(GetRTDBPath) +
          ' failed: ' + e.Message);
    end;
  finally
    Val.Free;
    Data.Free;
  end;
end;

procedure TfmxFirebaseDemo.btnPostRTAsynchClick(Sender: TObject);
var
  Data: TJSONObject;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  Data := TJSONObject.Create;
  try
    Data.AddPair(edtPostKeyName.Text, edtPostKeyValue.Text);
    fRealTimeDB.Post(GetRTDBPath, Data, OnPostResp, OnPostError);
  finally
    Data.Free;
  end;
  memRTDB.Lines.Clear;
  aniPostRT.Enabled := true;
  aniPostRT.Visible := true;
end;

procedure TfmxFirebaseDemo.OnPostResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniPostRT.Visible := false;
  aniPostRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TfmxFirebaseDemo.OnPostError(const RequestID, ErrMsg: string);
begin
  aniPostRT.Visible := false;
  aniPostRT.Enabled := false;
  memRTDB.Lines.Add('Post ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(sHintToDBRules);
end;

procedure TfmxFirebaseDemo.btnPatchRTSynchClick(Sender: TObject);
var
  Data: TJSONObject;
  Val: TJSONValue;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  Data := TJSONObject.Create;
  Val := nil;
  try
    Data.AddPair(edtPatchKeyName.Text, edtPatchKeyValue.Text);
    memRTDB.Lines.Clear;
    try
      Val := fRealTimeDB.PatchSynchronous(GetRTDBPath, Data);
      ShowRTNode(GetRTDBPath, Val);
    except
      on e: exception do
        memRTDB.Lines.Add('Post ' + GetPathFromResParams(GetRTDBPath) +
          ' failed: ' + e.Message);
    end;
  finally
    Val.Free;
    Data.Free;
  end;
end;

procedure TfmxFirebaseDemo.btnPatchRTAsynchClick(Sender: TObject);
var
  Data: TJSONObject;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  Data := TJSONObject.Create;
  try
    Data.AddPair(edtPatchKeyName.Text, edtPatchKeyValue.Text);
    fRealTimeDB.Patch(GetRTDBPath, Data, OnPatchResp, OnPatchError);
  finally
    Data.Free;
  end;
  memRTDB.Lines.Clear;
  aniPatchRT.Enabled := true;
  aniPatchRT.Visible := true;
end;

procedure TfmxFirebaseDemo.OnPatchResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniPatchRT.Visible := false;
  aniPatchRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TfmxFirebaseDemo.OnPatchError(const RequestID, ErrMsg: string);
begin
  aniPatchRT.Visible := false;
  aniPatchRT.Enabled := false;
  memRTDB.Lines.Add('Patch ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(sHintToDBRules);
end;

procedure TfmxFirebaseDemo.btnDelRTSynchClick(Sender: TObject);
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  memRTDB.Lines.Clear;
  try
    if fRealTimeDB.DeleteSynchronous(GetRTDBPath) then
      memRTDB.Lines.Add('Delete ' +
        GetPathFromResParams(GetRTDBPath) +
        ' passed')
    else
      memRTDB.Lines.Add('Path ' +
        GetPathFromResParams(GetRTDBPath) +
        ' not found');
  except
    on e: exception do
      memRTDB.Lines.Add('Delete ' + GetPathFromResParams(GetRTDBPath) +
        ' failed: ' + e.Message);
  end;
end;

procedure TfmxFirebaseDemo.btnDelRTAsynchClick(Sender: TObject);
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  memRTDB.Lines.Clear;
  fRealTimeDB.Delete(GetRTDBPath, OnDeleteResp, OnDeleteError);
  memRTDB.Lines.Clear;
  aniDeleteRT.Enabled := true;
  aniDeleteRT.Visible := true;
end;

procedure TfmxFirebaseDemo.OnDeleteResp(Params: TRequestResourceParam;
  Success: boolean);
begin
  aniDeleteRT.Enabled := false;
  aniDeleteRT.Visible := false;
  if Success then
    memRTDB.Lines.Add('Delete ' + GetPathFromResParams(GetRTDBPath) + ' passed')
  else
    memRTDB.Lines.Add('Path ' + GetPathFromResParams(GetRTDBPath) +
      ' not found');
end;

procedure TfmxFirebaseDemo.OnDeleteError(const RequestID, ErrMsg: string);
begin
  aniDeleteRT.Enabled := false;
  aniDeleteRT.Visible := false;
  memRTDB.Lines.Add('Delete ' + RequestID + ' failed: ' + ErrMsg);
end;

procedure TfmxFirebaseDemo.btnGetServerTimeStampClick(Sender: TObject);
var
  ServerTime: TJSONValue;
begin
  if not CheckAndCreateRealTimeDBClass(memRTDB) then
    exit;
  ServerTime := fRealTimeDB.GetServerVariablesSynchronous(
    cServerVariableTimeStamp, GetRTDBPath);
  try
    memRTDB.Lines.Add('ServerTime (local time): ' +
      DateTimeToStr(TFirebaseHelpers.ConvertTimeStampToLocalDateTime(
        (ServerTime as TJSONNumber).AsInt64)));
  finally
    ServerTime.Free;
  end;
end;
{$ENDREGION}

{$REGION 'Scan RT DB Event'}
procedure TfmxFirebaseDemo.btnNotifyEventClick(Sender: TObject);
begin
  if not CheckAndCreateRealTimeDBClass(memScans) then
    exit;
  fFirebaseEvent := fRealTimeDB.ListenForValueEvents(
    SplitString(edtRTDBEventPath.Text.Replace('\', '/'), '/'),
    OnRecData, OnRecDataStop, OnRecDataError);
  memScans.Lines.Add(TimeToStr(now) + ': Event handler started for ' +
    TFirebaseHelpers.ArrStrToCommaStr(fFirebaseEvent.GetResourceParams));
  btnNotifyEvent.Enabled := false;
  btnStopEvent.Enabled := true;
end;

procedure TfmxFirebaseDemo.btnStopEventClick(Sender: TObject);
begin
  if assigned(fFirebaseEvent) then
    fFirebaseEvent.StopListening;
end;

procedure TfmxFirebaseDemo.OnRecData(const Event: string;
  Params: TRequestResourceParam; JSONObj: TJSONObject);
var
  par, p: string;
begin
  par := '[';
  for p in Params do
  begin
    if par.Length > 1 then
      par := par + ', ' + p
    else
      par := par + p;
  end;
  memScans.Lines.Add(TimeToStr(now) + ': ' + Event + par + '] = ' +
    JSONObj.ToJSON);
end;

procedure TfmxFirebaseDemo.OnRecDataError(const Info, ErrMsg: string);
begin
  memScans.Lines.Add(TimeToStr(now) + ': Error in ' + Info + ': ' + ErrMsg);
end;

procedure TfmxFirebaseDemo.OnRecDataStop(Sender: TObject);
begin
  memScans.Lines.Add(TimeToStr(now) + ': Event handler stopped');
  fFirebaseEvent := nil;
  btnNotifyEvent.Enabled := true;
  btnStopEvent.Enabled := false;
end;
{$ENDREGION}

end.
