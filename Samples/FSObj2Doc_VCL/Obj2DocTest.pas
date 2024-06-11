{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2024 Christoph Schneider                                 }
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

unit Obj2DocTest;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask,
  Vcl.ExtCtrls, Vcl.Samples.Spin,
  FB4D.Interfaces;

type
  TfrmObj2Doc = class(TForm)
    edtProjectID: TLabeledEdit;
    btnAddUpdateDoc: TButton;
    edtDocID: TLabeledEdit;
    lstDocID: TListBox;
    btnGetDocs: TButton;
    lblGetResult: TLabel;
    edtMsg: TLabeledEdit;
    edtDocTitle: TLabeledEdit;
    edtCh: TLabeledEdit;
    lblCreationDate: TLabel;
    edtTestInt: TSpinEdit;
    Label1: TLabel;
    edtLargeNumber: TEdit;
    cboEnum: TComboBox;
    lblByte: TLabel;
    edtArrStr0: TEdit;
    edtArrStr1: TEdit;
    edtArrStr2: TEdit;
    edtArrStr4: TEdit;
    edtArrStr3: TEdit;
    Label2: TLabel;
    Label3: TLabel;
    lblMyArrTime: TLabel;
    GroupBox1: TGroupBox;
    Label4: TLabel;
    lblUpdateInsertResult: TLabel;
    btnInstallListener: TButton;
    btnDeleteDoc: TButton;
    GroupBox2: TGroupBox;
    chbSupressSaveDefVal: TCheckBox;
    chbSupressSavePrivateFields: TCheckBox;
    chbSupressSaveProtectedFields: TCheckBox;
    chbSupressSavePublicFields: TCheckBox;
    chbSupressSavePublishedFields: TCheckBox;
    chbEliminateFieldPrefixF: TCheckBox;
    chbSaveEnumAsString: TCheckBox;
    chbAlpha: TCheckBox;
    GroupBox3: TGroupBox;
    chbBeta: TCheckBox;
    chbGamma: TCheckBox;
    procedure btnAddUpdateDocClick(Sender: TObject);
    procedure btnGetDocsClick(Sender: TObject);
    procedure lstDocIDClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnInstallListenerClick(Sender: TObject);
    procedure btnDeleteDocClick(Sender: TObject);
  private
    fDatabase: IFirestoreDatabase;
    fLastDeletedDocID: string;
    function GetDatabase: IFirestoreDatabase;
    procedure ClearDocIdList;
    procedure OnDocument(const Info: string; Document: IFirestoreDocument);
    procedure OnDocuments(const Info: string; Documents: IFirestoreDocuments);
    procedure OnChangedDocument(ChangedDoc: IFirestoreDocument);
    procedure OnDeletedDocument(const DeletedDocPath: string; TS: TDateTime);
    procedure OnStopListening(sender: TObject);
    procedure OnError(const RequestID, ErrMsg: string);
    function GetOptions: TOTDMapperOptions;
    function GetSettingFileName: string;
    procedure SaveSettings;
  end;

var
  frmObj2Doc: TfrmObj2Doc;

implementation

{$R *.dfm}

uses
  System.IniFiles, System.IOUtils,
  FB4D.Firestore, FB4D.Document, FB4D.Helpers;

const
  cDocs = 'Docs';

resourcestring
  rsHintFSDBRules =
    'Hint to permission error:'#13 +
    'Before you can read and write in the Firestore database add the following ' +
    'text in the Firebase console as rule for the Firestore Database:'#13 +
    'service cloud.firestore {'#13 +
    '  match /databases/{database}/documents {'#13 +
    '    match /Docs/{document=**} {'#13 +
    '     	allow read, write: if true;'#13 +
    '    }'#13 +
    '  }'#13 +
    '}'#13;

type
  TMyEnum = (_Alpha, _Beta, _Gamma);
  TMySet = set of TMyEnum;
  TMyFSDoc = class(TFirestoreDocument)
  private
    fMyPrivate: string;
  protected
    fMyProtected: string;
  public
    // The class TMyFSDoc contains member variables for
    // synchronization from and to the Firestore.
    // Replace these members with specific fields required in your project
    DocTitle: string;
    Msg: AnsiString;
    Ch: Char;
    CreationDateTime: TDateTime;
    TestInt: integer;
    LargeNumber: Int64;
    B: Byte;
    MyEnum: TMyEnum; // Don't define ad-hoc the type here because of limitation in RTTI
    MySet: TMySet;
    MyArr: array of integer;
    MyArrStr: array of string;
    MyArrTime: array of TDateTime;
  end;

procedure TfrmObj2Doc.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    chbSupressSaveDefVal.Checked :=
      IniFile.ReadBool('OTDMOpt', 'SuppressDelVal', true);
    chbSupressSavePrivateFields.Checked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSavePrivateFields', true);
    chbSupressSaveProtectedFields.Checked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSaveProtectedFields', false);
    chbSupressSavePublicFields.Checked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSavePublicFields', false);
    chbSupressSavePublishedFields.Checked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSavePublishedFields', false);
    chbEliminateFieldPrefixF.Checked :=
      IniFile.ReadBool('OTDMOpt', 'EliminateFieldPrefixF', false);
    chbSaveEnumAsString.Checked :=
      IniFile.ReadBool('OTDMOpt', 'SaveEnumAsString', false);
  finally
    IniFile.Free;
  end;
end;

function TfrmObj2Doc.GetSettingFileName: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(Application.ExeName), '.ini');
  result := TPath.Combine(TPath.GetHomePath, FileName);
end;

function TfrmObj2Doc.GetDatabase: IFirestoreDatabase;
begin
  if not assigned(fDatabase) then
  begin
    fDatabase := TFirestoreDatabase.Create(edtProjectID.Text, nil);
    edtProjectID.Enabled := false;
  end;
  result := fDatabase;
end;

function TfrmObj2Doc.GetOptions: TOTDMapperOptions;
begin
  result := [];
  if chbSupressSaveDefVal.Checked then
    result := result + [omSupressSaveDefVal];
  if chbSupressSavePrivateFields.Checked then
    result := result + [omSupressSavePrivateFields];
  if chbSupressSaveProtectedFields.Checked then
    result := result + [omSupressSaveProtectedFields];
  if chbSupressSavePublicFields.Checked then
    result := result + [omSupressSavePublicFields];
  if chbSupressSavePublishedFields.Checked then
    result := result + [omSupressSavePublishedFields];
  if chbEliminateFieldPrefixF.Checked then
    result := result + [omEliminateFieldPrefixF];
  if chbSaveEnumAsString.Checked then
    result := result + [omSaveEnumAsString];
end;

procedure TfrmObj2Doc.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteBool('OTDMOpt', 'SuppressDelVal', chbSupressSaveDefVal.Checked);
    IniFile.WriteBool('OTDMOpt', 'SupressSavePrivateFields',
      chbSupressSavePrivateFields.Checked);
    IniFile.WriteBool('OTDMOpt', 'SupressSaveProtectedFields',
      chbSupressSaveProtectedFields.Checked);
    IniFile.WriteBool('OTDMOpt', 'SupressSavePublicFields',
      chbSupressSavePublicFields.Checked);
    IniFile.WriteBool('OTDMOpt', 'SupressSavePublishedFields',
      chbSupressSavePublishedFields.Checked);
    IniFile.WriteBool('OTDMOpt', 'EliminateFieldPrefixF',
      chbEliminateFieldPrefixF.Checked);
    IniFile.WriteBool('OTDMOpt', 'SaveEnumAsString',
      chbSaveEnumAsString.Checked);
  finally
    IniFile.Free;
  end;
end;

procedure TfrmObj2Doc.FormDestroy(Sender: TObject);
begin
  ClearDocIdList;
  SaveSettings;
end;

procedure TfrmObj2Doc.btnAddUpdateDocClick(Sender: TObject);
var
  Doc: TMyFSDoc;
  ind: integer;
begin
  if edtDocID.Text = '' then
    edtDocID.Text := TFirebaseHelpers.CreateAutoID(FSID);
  Doc := TMyFSDoc.Create([cDocs, edtDocID.Text], GetDatabase);
  Doc.fMyPrivate := 'Private field content';
  Doc.fMyProtected := 'Protected field content';
  Doc.DocTitle := edtDocTitle.Text;
  Doc.Msg := AnsiString(edtMsg.Text);
  if edtCh.Text > '' then
    Doc.Ch := edtCh.Text[1]
  else
    Doc.Ch := #0;
  Doc.CreationDateTime := now;
  Doc.TestInt := integer(edtTestInt.Value);
  Doc.LargeNumber := StrToInt64Def(edtLargeNumber.Text, -1);
  Doc.B := random(255);
  lblByte.Caption := Doc.B.ToString;
  Doc.MyEnum := TMyEnum(cboEnum.ItemIndex);
  Doc.MySet := [];
  if chbAlpha.Checked then
    Doc.MySet := Doc.MySet + [_Alpha];
  if chbBeta.Checked then
    Doc.MySet := Doc.MySet + [_Beta];
  if chbGamma.Checked then
    Doc.MySet := Doc.MySet + [_Gamma];
  SetLength(Doc.MyArr, 3);
  Doc.MyArr[0] := 11; Doc.MyArr[1] := 33; Doc.MyArr[2] := 35;
  if edtArrStr0.Text > '' then
  begin
    SetLength(Doc.MyArrStr, 1);
    Doc.MyArrStr[0] := edtArrStr0.Text;
  end else
    SetLength(Doc.MyArrStr, 0);
  if edtArrStr1.Text > '' then
  begin
    SetLength(Doc.MyArrStr, length(Doc.MyArrStr) + 1);
    Doc.MyArrStr[length(Doc.MyArrStr) - 1] := edtArrStr1.Text;
  end;
  if edtArrStr2.Text > '' then
  begin
    SetLength(Doc.MyArrStr, length(Doc.MyArrStr) + 1);
    Doc.MyArrStr[length(Doc.MyArrStr) - 1] := edtArrStr2.Text;
  end;
  if edtArrStr3.Text > '' then
  begin
    SetLength(Doc.MyArrStr, length(Doc.MyArrStr) + 1);
    Doc.MyArrStr[length(Doc.MyArrStr) - 1] := edtArrStr3.Text;
  end;
  if edtArrStr4.Text > '' then
  begin
    SetLength(Doc.MyArrStr, length(Doc.MyArrStr) + 1);
    Doc.MyArrStr[length(Doc.MyArrStr) - 1] := edtArrStr4.Text;
  end;
  SetLength(Doc.MyArrTime, 2);
  Doc.MyArrTime[0] := now; Doc.MyArrTime[1] := trunc(Now) + 1;
  lblMyArrTime.Caption := '0: ' + DateTimeToStr(Doc.MyArrTime[0]) +
    ' 1: ' + DateTimeToStr(Doc.MyArrTime[1]);
  GetDatabase.InsertOrUpdateDocument(Doc.SaveObjectToDocument(GetOptions),
    nil, OnDocument, OnError);
  ind := lstDocID.Items.IndexOf(Doc.DocumentName(false));
  if ind >= 0 then
  begin
    (lstDocID.Items.Objects[ind] as TMyFSDoc).Free;
    lstDocID.Items.Objects[ind] := Doc;
  end;
end;

procedure TfrmObj2Doc.btnDeleteDocClick(Sender: TObject);
begin
  if edtDocID.Text > '' then
    GetDatabase.Delete([cDocs, edtDocID.Text], nil, OnDeletedDocument, OnError)
  else
    lblGetResult.Caption := 'No document ID to delete';
end;

procedure TfrmObj2Doc.btnGetDocsClick(Sender: TObject);
begin
  GetDatabase.Get([cDocs], nil, OnDocuments, OnError);
end;

procedure TfrmObj2Doc.OnDocument(const Info: string;
  Document: IFirestoreDocument);
begin
  lblUpdateInsertResult.Caption := 'Doc inserted or updated';
end;

procedure TfrmObj2Doc.OnDocuments(const Info: string;
  Documents: IFirestoreDocuments);
var
  Doc: IFirestoreDocument;
begin
  if not assigned(Documents) then
    lblGetResult.Caption := 'No document found'
  else begin
    lblGetResult.Caption := Documents.Count.ToString + ' documents found';
    ClearDocIdList;
    for Doc in Documents do
      lstDocID.AddItem(Doc.DocumentName(false),
        TMyFSDoc.LoadObjectFromDocument(Doc, GetOptions));
  end;
end;

procedure TfrmObj2Doc.btnInstallListenerClick(Sender: TObject);
begin
  GetDatabase.SubscribeQuery(TStructuredQuery.CreateForCollection(cDocs),
    OnChangedDocument, OnDeletedDocument);
  GetDatabase.StartListener(OnStopListening, OnError);
  btnInstallListener.Enabled := false;
  btnGetDocs.Enabled := false;
end;

procedure TfrmObj2Doc.OnChangedDocument(ChangedDoc: IFirestoreDocument);
var
  ind: integer;
begin
  ind := lstDocID.Items.IndexOfName(ChangedDoc.DocumentName(false));
  if ind >= 0 then
  begin
    (lstDocID.Items.Objects[ind] as TMyFSDoc).Free;
    lstDocID.Items.Objects[ind] := TMyFSDoc.LoadObjectFromDocument(ChangedDoc,
      GetOptions);
    if ind = lstDocID.ItemIndex then
      lstDocIDClick(nil);
  end else
    lstDocID.AddItem(ChangedDoc.DocumentName(false),
      TMyFSDoc.LoadObjectFromDocument(ChangedDoc));
end;

procedure TfrmObj2Doc.OnDeletedDocument(const DeletedDocPath: string;
  TS: TDateTime);
var
  DocID: string;
  ind: integer;
begin
  DocID := TFirestorePath.ExtractLastCollection(DeletedDocPath);
  if fLastDeletedDocID = DocID then
    exit; // because OnDeletedDocument is called twice if listener is active
  fLastDeletedDocID := DocID;
  ind := lstDocID.Items.IndexOf(DocID);
  if ind >= 0 then
  begin
    (lstDocID.Items.Objects[ind] as TMyFSDoc).Free;
    lstDocID.Items.Delete(ind);
    lblGetResult.Caption := 'Document ' + DocID + ' deleted';
  end else
    lblGetResult.Caption := 'Document ' + DocID + ' not found';
end;

procedure TfrmObj2Doc.OnStopListening(sender: TObject);
begin
  btnInstallListener.Enabled := true;
  btnGetDocs.Enabled := true;
end;

procedure TfrmObj2Doc.ClearDocIdList;
var
  c: integer;
  Doc: TMyFSDoc;
begin
  for c := 0 to lstDocID.Items.Count - 1 do
  begin
    Doc := lstDocID.Items.Objects[c] as TMyFSDoc;
    Doc.Free;
  end;
  lstDocID.Clear;
end;

procedure TfrmObj2Doc.OnError(const RequestID, ErrMsg: string);
begin
  if SameText(ErrMsg, 'Permission denied') or
     SameText(ErrMsg, 'Missing or insufficient permissions.') then
    ShowMessage(rsHintFSDBRules)
  else
    ShowMessage('Error: ' + ErrMsg);
end;

procedure TfrmObj2Doc.lstDocIDClick(Sender: TObject);
var
  Doc: TMyFSDoc;
begin
  Doc := lstDocID.Items.Objects[lstDocID.ItemIndex] as TMyFSDoc;
  edtDocID.Text := Doc.DocumentName(false);
  edtDocTitle.Text := Doc.DocTitle;
  edtMsg.Text := string(Doc.Msg);
  edtCh.Text := Doc.Ch;
  lblCreationDate.Caption := DateTimeToStr(Doc.CreationDateTime);
  edtTestInt.Value := Doc.TestInt;
  edtLargeNumber.Text := Format('%.0n', [Doc.LargeNumber + 0.0]);
  cboEnum.ItemIndex := ord(Doc.MyEnum);
  chbAlpha.Checked := _Alpha in Doc.MySet;
  chbBeta.Checked := _Beta in Doc.MySet;
  chbGamma.Checked := _Gamma in Doc.MySet;
  lblByte.Caption := Doc.B.ToString;
  if length(Doc.MyArrStr) > 0 then
    edtArrStr0.Text := Doc.MyArrStr[0]
  else
    edtArrStr0.Text := '';
  if length(Doc.MyArrStr) > 1 then
    edtArrStr1.Text := Doc.MyArrStr[1]
  else
    edtArrStr1.Text := '';
  if length(Doc.MyArrStr) > 2 then
    edtArrStr2.Text := Doc.MyArrStr[2]
  else
    edtArrStr2.Text := '';
  if length(Doc.MyArrStr) > 3 then
    edtArrStr3.Text := Doc.MyArrStr[3]
  else
    edtArrStr3.Text := '';
  if length(Doc.MyArrStr) > 4 then
    edtArrStr4.Text := Doc.MyArrStr[4]
  else
    edtArrStr4.Text := '';
  if length(Doc.MyArrTime) = 2 then
    lblMyArrTime.Caption := '0: ' + DateTimeToStr(Doc.MyArrTime[0]) +
      ' 1: ' + DateTimeToStr(Doc.MyArrTime[1])
  else
    lblMyArrTime.Caption := '';
end;

end.
