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

unit EyncryptedNotesFrm;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes, System.IOUtils, System.IniFiles,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.ExtCtrls, Vcl.WinXCtrls, Vcl.ComCtrls,
  FB4D.Interfaces, SymCrypto;

type
  TfrmEncryptedNotes = class(TForm)
    SplitViewSettings: TSplitView;
    edtProjectID: TLabeledEdit;
    edtAESKey: TLabeledEdit;
    btnSave: TButton;
    btnGenerateKey: TButton;
    lstNotes: TListBox;
    btnCreateNote: TButton;
    memNote: TMemo;
    StatusBar: TStatusBar;
    btnSettings: TButton;
    pnlMain: TPanel;
    edtSender: TLabeledEdit;
    btnDeleteNote: TButton;
    stcID: TEdit;
    lblID: TLabel;
    lblEncrypted: TLabel;
    btnSaveNote: TButton;
    lblDateTime: TLabel;
    lblSenderID: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnCreateNoteClick(Sender: TObject);
    procedure btnDeleteNoteClick(Sender: TObject);
    procedure btnGenerateKeyClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnSaveNoteClick(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure lstNotesClick(Sender: TObject);
  private
    fDatabase: IFirestoreDatabase;
    fSymmetricCrypto: TSymmetricCrypto;
    fSenderID: string;
    // Ideally, the following project-specific secrets are not included in the
    // code but loaded from a secure location.
    const cProjectSecretKey = 'MQO+y5/yTSSXs77GxjymI0DMA2EHOA9hunW0QHhFDEA=';
    const cProjectSecretIV = 'YougS-OsCqkGRrlywsvR';
    function GetSettingFileName: string;
    function GetDatabase: IFirestoreDatabase;
    procedure SaveSettings;
    function StartListener: boolean;
    procedure ClearNote(OnNewDoc: boolean = false);
    procedure OnNewDocument(const Info: string; Document: IFirestoreDocument);
    procedure OnError(const RequestID, ErrMsg: string);
    procedure OnDeleteError(const RequestID, ErrMsg: string);
    procedure OnChangedDocument(ChangedDocument: IFirestoreDocument);
    procedure OnDeletedDocument(const DeleteDocumentPath: string; TimeStamp: TDateTime);
    procedure OnStopListening(const RequestId: string);
    procedure OnListenerError(const RequestID, ErrMsg: string);
  end;

var
  frmEncryptedNotes: TfrmEncryptedNotes;

implementation

uses
  FB4D.Configuration, FB4D.Firestore, FB4D.Document, FB4D.Helpers;

{$R *.dfm}

resourcestring
  rsHintFSDBRules =
    'Hint to permission error:'#13 +
    'Before you can read and write in the Firestore database add the following ' +
    'text in the Firebase console as rule for the Firestore Database:'#13 +
    'service cloud.firestore {'#13 +
    '  match /databases/{database}/documents {'#13 +
    '    match /%s/{document=**} {'#13 +
    '     	allow read, write: if true;'#13 +
    '    }'#13 +
    '  }'#13 +
    '}'#13;

type
  TNoteDoc = class(TFirestoreDocument)
  private
    fID: string;
    fNoteClearText: string;
  public
    Note: string; // Encrypted
    Sender: string;
    CreationDateTime: TDateTime;
    const cDocs = 'noteDocs';
    constructor Create(const NoteClearText: string); overload;
    constructor LoadObjectFromDocument(Doc: IFirestoreDocument;
      Options: TOTDMapperOptions = []); override;
    function SaveObjectToDocument(
      Options: TOTDMapperOptions = []): IFirestoreDocument; override;
    function GetCaption: string;
    property NoteClearText: string read fNoteClearText;
  end;

{$REGION 'TfrmEncryptedNotes - Settings in Splitview'}
procedure TfrmEncryptedNotes.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  fSymmetricCrypto := TSymmetricCrypto.Create;
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtProjectID.Text := IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    fSymmetricCrypto.ImportAESKey(cProjectSecretKey);
    edtAESKey.Text := fSymmetricCrypto.DecrytClearText(IniFile.ReadString('AES', 'Key', ''), cProjectSecretIV);
    fSenderID := IniFile.ReadString('App', 'ID',  TFirebaseHelpers.CreateAutoID(FSID));
  finally
    IniFile.Free;
  end;
  Caption := Caption + ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
  edtSender.Text := fSenderID;
  btnGenerateKey.Enabled := length(edtAESKey.Text) = 0;
  if not btnGenerateKey.Enabled then
    fSymmetricCrypto.ImportAESKey(edtAESKey.Text);
  if (length(edtProjectID.Text) = 0) or btnGenerateKey.Enabled then
    SplitViewSettings.Show
  else begin
    SplitViewSettings.Hide;
    btnSave.Enabled := not StartListener;
  end;
end;

procedure TfrmEncryptedNotes.FormDestroy(Sender: TObject);
var
  Ind: integer;
begin
  for Ind := 0 to lstNotes.Items.Count - 1 do
    (lstNotes.Items.Objects[Ind] as TNoteDoc).Free;
  fSymmetricCrypto.Free;
end;

function TfrmEncryptedNotes.GetSettingFileName: string;
begin
  result := TPath.Combine(TPath.GetHomePath, ChangeFileExt(ExtractFileName(Application.ExeName), '.ini'));
end;

procedure TfrmEncryptedNotes.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('App', 'ID',  fSenderID);
    fSymmetricCrypto.ImportAESKey(cProjectSecretKey);
    IniFile.WriteString('AES', 'Key', fSymmetricCrypto.EncryptToBase64(edtAESKey.Text, cProjectSecretIV));
  finally
    IniFile.Free;
  end;
  fSymmetricCrypto.ImportAESKey(edtAESKey.Text);
  edtAESKey.ReadOnly := true;
  btnSave.Enabled := not StartListener;
end;

procedure TfrmEncryptedNotes.btnGenerateKeyClick(Sender: TObject);
begin
  edtAESKey.Text := fSymmetricCrypto.GenerateAESKey;
  btnGenerateKey.Enabled := false;
end;

procedure TfrmEncryptedNotes.btnSaveClick(Sender: TObject);
begin
  if not((length(edtProjectID.Text) = 0) or btnGenerateKey.Enabled) then
  begin
    SaveSettings;
    SplitViewSettings.Hide;
  end;
end;

procedure TfrmEncryptedNotes.btnSettingsClick(Sender: TObject);
begin
  if SplitViewSettings.Visible then
    SplitViewSettings.Hide
  else
    SplitViewSettings.Show;
end;
{$ENDREGION}

{$REGION 'TfrmEncryptedNotes - Access Firestore Database'}
function TfrmEncryptedNotes.GetDatabase: IFirestoreDatabase;
begin
  if not assigned(fDatabase) then
  begin
    fDatabase := TFirestoreDatabase.Create(edtProjectID.Text, nil);
    edtProjectID.ReadOnly := true;
  end;
  result := fDatabase;
end;
{$ENDREGION}

{$REGION 'TfrmEncryptedNotes - Store a new note into Firestore'}
procedure TfrmEncryptedNotes.ClearNote(OnNewDoc: boolean);
begin
  memNote.Lines.Clear;
  stcID.Text := '';
  lblDateTime.Caption := '';
  lblSenderID.Caption := '';
  btnDeleteNote.Enabled := false;
  if OnNewDoc then
  begin
    lstNotes.ItemIndex := -1;
    btnSaveNote.Visible := true;
    btnCreateNote.Visible := false;
    lblEncrypted.Caption := 'Write your note and press Save';
  end else begin
    btnSaveNote.Visible := false;
    btnCreateNote.Visible := true;
    lblEncrypted.Caption := '';
  end;
end;

procedure TfrmEncryptedNotes.btnCreateNoteClick(Sender: TObject);
begin
  ClearNote(true);
end;

procedure TfrmEncryptedNotes.btnSaveNoteClick(Sender: TObject);
var
  NoteDoc: TNoteDoc;
begin
  if trim(memNote.Lines.Text).IsEmpty then
  begin
    ShowMessage('Enter first a note');
    memNote.SetFocus;
    exit;
  end;
  btnSaveNote.Visible := false;
  btnCreateNote.Visible := true;
  NoteDoc := TNoteDoc.Create(memNote.Lines.Text);
  try
    GetDatabase.InsertOrUpdateDocument(NoteDoc.SaveObjectToDocument([]),
      nil, OnNewDocument, OnError);
    stcID.Text := NoteDoc.DocumentName(false);
    lblDateTime.Caption := 'Created at ' + DateTimeToStr(NoteDoc.CreationDateTime);
    lblSenderID.Caption := 'Sender ID: ' + NoteDoc.Sender;
    lblEncrypted.Caption := 'Encrypted: ' + NoteDoc.Note;
  finally
    NoteDoc.Free;
  end;
end;

procedure TfrmEncryptedNotes.OnNewDocument(const Info: string; Document: IFirestoreDocument);
begin
  StatusBar.SimpleText := 'Document ' + Document.DocumentName(false) + ' created';
end;

procedure TfrmEncryptedNotes.OnError(const RequestID, ErrMsg: string);
begin
  if SameText(ErrMsg, 'Permission denied') or
     SameText(ErrMsg, 'Missing or insufficient permissions.') then
    StatusBar.SimpleText := Format(rsHintFSDBRules, [TNoteDoc.cDocs])
  else
    StatusBar.SimpleText := 'Error: ' + ErrMsg;
end;
{$ENDREGION}

{$REGION 'TfrmEncryptedNotes - Delete an existing note from Firestore'}
procedure TfrmEncryptedNotes.btnDeleteNoteClick(Sender: TObject);
var
  NoteDoc: TNoteDoc;
begin
  btnDeleteNote.Enabled := false;
  btnSaveNote.visible := false;
  if lstNotes.ItemIndex >= 0 then
  begin
    NoteDoc := lstNotes.Items.Objects[lstNotes.ItemIndex] as TNoteDoc;
    GetDatabase.Delete(NoteDoc.DocumentPathWithinDatabase, nil, OnDeletedDocument, OnDeleteError);
  end;
end;

procedure TfrmEncryptedNotes.OnDeletedDocument(const DeleteDocumentPath: string; TimeStamp: TDateTime);
var
  Id: string;
  NoteDoc: TNoteDoc;
  Ind: integer;
begin
  Id := TFirestorePath.ExtractLastCollection(DeleteDocumentPath);
  StatusBar.SimpleText := 'Document ' + Id + ' deleted';
  ClearNote;
  for Ind := 0 to lstNotes.Items.Count - 1 do
  begin
    NoteDoc := lstNotes.Items.Objects[Ind] as TNoteDoc;
    if NoteDoc.fID = Id then
    begin
      lstNotes.Items.Delete(Ind);
      NoteDoc.Free;
      exit;
    end;
  end;
end;

procedure TfrmEncryptedNotes.OnDeleteError(const RequestID, ErrMsg: string);
begin
  StatusBar.SimpleText := 'Error while delete document: ' + ErrMsg;
end;
{$ENDREGION}

{$REGION 'TfrmEncryptedNotes - Listener for retrieving all docs from Firestore and filling in the master list'}
function TfrmEncryptedNotes.StartListener: boolean;
begin
  Assert(length(edtAESKey.Text) > 0, 'AES Key missing');
  Assert(length(edtProjectID.Text) > 0, 'Project ID missing');
  GetDatabase.SubscribeQuery(
    TStructuredQuery.CreateForCollection(TNoteDoc.cDocs).OrderBy('CreationDateTime', odDescending),
    OnChangedDocument, OnDeletedDocument);
  GetDatabase.StartListener(OnStopListening, OnListenerError);
  result := true;
end;

procedure TfrmEncryptedNotes.OnChangedDocument(ChangedDocument: IFirestoreDocument);

  function GetIndex(CreationDT: TDateTime): integer;
  var
    Ind: integer;
    NoteDoc: TNoteDoc;
  begin
    for Ind := 0 to lstNotes.Items.Count - 1 do
    begin
      NoteDoc := lstNotes.Items.Objects[Ind] as TNoteDoc;
      if CreationDT > NoteDoc.CreationDateTime then
        exit(Ind);
    end;
    result := lstNotes.Items.Count;
  end;

var
  NoteDoc: TNoteDoc;
  Index: integer;
begin
  NoteDoc := TNoteDoc.LoadObjectFromDocument(ChangedDocument, []);
  Index := GetIndex(NoteDoc.CreationDateTime);
  lstNotes.Items.InsertObject(Index, NoteDoc.GetCaption, NoteDoc);
  if stcID.Text = NoteDoc.fID then
    lstNotes.ItemIndex := Index
  else
    lstNotes.ItemIndex := -1;
end;

procedure TfrmEncryptedNotes.OnStopListening(const RequestId: string);
begin
  StatusBar.SimpleText := 'Listener stopped';
end;

procedure TfrmEncryptedNotes.OnListenerError(const RequestID, ErrMsg: string);
begin
  StatusBar.SimpleText := 'Error in listener: ' + ErrMsg;
end;
{$ENDREGION}

{$REGION 'TfrmEncryptedNotes - Click on master list shows details of the selected note'}
procedure TfrmEncryptedNotes.lstNotesClick(Sender: TObject);
var
  NoteDoc: TNoteDoc;
begin
  if lstNotes.ItemIndex >= 0 then
  begin
    NoteDoc := lstNotes.Items.Objects[lstNotes.ItemIndex] as TNoteDoc;
    stcID.Text := NoteDoc.DocumentName(false);
    memNote.Lines.Text := NoteDoc.NoteClearText;
    lblDateTime.Caption := 'Created at ' + DateTimeToStr(NoteDoc.CreationDateTime);
    lblSenderID.Caption := 'Sender ID: ' + NoteDoc.Sender;
    lblEncrypted.Caption := 'Encrypted: ' + NoteDoc.Note;
    btnDeleteNote.Enabled := true;
    btnSaveNote.Visible := false;
    btnCreateNote.Visible := true;
  end else
    ClearNote;
end;
{$ENDREGION}

{$REGION 'TNoteDoc'}
constructor TNoteDoc.Create(const NoteClearText: string);
begin
  Assert(assigned(frmEncryptedNotes), 'Missing frmEncryptedNotes');
  fID := TFirebaseHelpers.CreateAutoID(FSID);
  inherited Create([cDocs, fID], frmEncryptedNotes.GetDatabase);
  fNoteClearText := NoteClearText;
  CreationDateTime := now;
  Sender := frmEncryptedNotes.fSenderID;
end;

function TNoteDoc.GetCaption: string;
var
  TimeInfo: string;
  Today, Day: integer;
begin
  Assert(assigned(frmEncryptedNotes), 'Missing frmEncryptedNotes');
  Today := trunc(now);
  Day := trunc(CreationDateTime);
  if Today = Day then
    TimeInfo := 'at ' + TimeToStr(CreationDateTime)
  else if Today - 1 = Day then
    TimeInfo := 'from yesterday'
  else if Today - 7 < Day then
    TimeInfo := 'from last ' + FormatDateTime('ddd', CreationDateTime)
  else
    TimeInfo := 'on ' + FormatDateTime('d/mm/yy', CreationDateTime);
  if Sender = frmEncryptedNotes.fSenderID then
    result := 'Myself ' + TimeInfo
  else
    result := Sender.Substring(0, 5) + '.. ' + TimeInfo;
end;

constructor TNoteDoc.LoadObjectFromDocument(Doc: IFirestoreDocument; Options: TOTDMapperOptions);
begin
  Assert(assigned(frmEncryptedNotes), 'Missing frmEncryptedNotes');
  Assert(assigned(frmEncryptedNotes.fSymmetricCrypto), 'Missing frmEncryptedNotes.fSymmetricCrypto');
  inherited LoadObjectFromDocument(Doc, Options + [omSupressSavePrivateFields]);
  fID := Doc.DocumentName(false);
  fNoteClearText := frmEncryptedNotes.fSymmetricCrypto.DecrytClearText(Note, fID);
end;

function TNoteDoc.SaveObjectToDocument(Options: TOTDMapperOptions): IFirestoreDocument;
begin
  Assert(assigned(frmEncryptedNotes), 'Missing frmEncryptedNotes');
  Assert(assigned(frmEncryptedNotes.fSymmetricCrypto), 'Missing frmEncryptedNotes.fSymmetricCrypto');
  Note := frmEncryptedNotes.fSymmetricCrypto.EncryptToBase64(fNoteClearText, fID);
  result := inherited SaveObjectToDocument(Options + [omSupressSavePrivateFields]);
end;
{$ENDREGION}

end.
