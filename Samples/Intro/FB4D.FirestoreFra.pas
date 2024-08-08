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

unit FB4D.FirestoreFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.IniFiles, System.JSON, System.RTTI,
  System.Generics.Collections, System.ImageList,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.ListBox, FMX.Controls.Presentation, FMX.Memo.Types, FMX.ScrollBox,
  FMX.Memo, FMX.Edit, FMX.TabControl, FMX.Objects, FMX.Menus, FMX.ImgList,
  FB4D.Interfaces;

type
  TFirestoreFra = class(TFrame)
    edtDatabaseID: TEdit;
    txtFirebaseURL: TText;
    rctFBURLDisabled: TRectangle;
    btnCommitWriteTrans: TButton;
    btnCreateDocument: TButton;
    btnDeleteDoc: TButton;
    btnGet: TButton;
    btnInsertOrUpdateDocument: TButton;
    btnPatchDoc: TButton;
    btnRunQuery: TButton;
    btnStartReadTransaction: TButton;
    btnStartWriteTransaction: TButton;
    btnStopReadTrans: TButton;
    cboDemoDocType: TComboBox;
    chbLimitTo10Docs: TCheckBox;
    chbUseChildDoc: TCheckBox;
    chbUsePageToken: TCheckBox;
    edtChildCollection: TEdit;
    Label27: TLabel;
    edtChildDocument: TEdit;
    Label28: TLabel;
    edtCollection: TEdit;
    Label4: TLabel;
    edtDocument: TEdit;
    Label7: TLabel;
    lblMinTestInt: TLabel;
    memFirestore: TMemo;
    trbMinTestInt: TTrackBar;
    TabControl: TTabControl;
    tabCreate: TTabItem;
    tabInsertOrUpdate: TTabItem;
    tabPatch: TTabItem;
    tabGet: TTabItem;
    tabDelete: TTabItem;
    tabQuery: TTabItem;
    tabTransactions: TTabItem;
    tabListener: TTabItem;
    popFSLog: TPopupMenu;
    mniClear: TMenuItem;
    Label13: TLabel;
    imlTabStatus: TImageList;
    GroupBox1: TGroupBox;
    edtCollectionIDForFSListener: TEdit;
    Label29: TLabel;
    chbIncludeDescendants: TCheckBox;
    GroupBox2: TGroupBox;
    edtDocPathForFSListener: TEdit;
    Label30: TLabel;
    btnStopFSListener: TButton;
    btnStartFSListener: TButton;
    lblReadTransID: TLabel;
    edtTestInt: TEdit;
    lblTestInt: TLabel;
    procedure edtDocumentChangeTracking(Sender: TObject);
    procedure btnGetClick(Sender: TObject);
    procedure btnCreateDocumentClick(Sender: TObject);
    procedure btnDeleteDocClick(Sender: TObject);
    procedure btnInsertOrUpdateDocumentClick(Sender: TObject);
    procedure btnPatchDocClick(Sender: TObject);
    procedure chbUseChildDocChange(Sender: TObject);
    procedure trbMinTestIntChange(Sender: TObject);
    procedure btnRunQueryClick(Sender: TObject);
    procedure btnStartWriteTransactionClick(Sender: TObject);
    procedure btnStartReadTransactionClick(Sender: TObject);
    procedure btnStopReadTransClick(Sender: TObject);
    procedure btnCommitWriteTransClick(Sender: TObject);
    procedure mniClearClick(Sender: TObject);
    procedure btnStartFSListenerClick(Sender: TObject);
    procedure btnStopFSListenerClick(Sender: TObject);
    procedure cboDemoDocTypeChange(Sender: TObject);
  private
    fDatabase: IFirestoreDatabase;
    fReadTransaction: TFirestoreReadTransaction;
    fWriteTransaction: IFirestoreWriteTransaction;

    function CheckFirestoreFields(InsUpdGetWF: boolean): boolean;

    procedure ShowDocument(Doc: IFirestoreDocument);
    procedure CheckDocument;

    // General used error callback
    procedure OnFirestoreError(const Info, ErrMsg: string);

    // Create Document
    procedure OnFirestoreCreate(const Info: string; Doc: IFirestoreDocument);

    // Insert or Update Document
    procedure OnFirestoreInsertOrUpdate(const Info: string;
      Doc: IFirestoreDocument);

    // Get Document
    procedure OnFirestoreGet(const Info: string; Docs: IFirestoreDocuments);

    // Delete Document
    procedure OnFirestoreDeleted(const DeleteDocumentPath: string;
      TimeStamp: TDateTime);

    // Listener
    procedure OnFSAuthRevoked(TokenRenewPassed: boolean);
    procedure OnFSChangedDoc(Doc: IFirestoreDocument);
    procedure OnFSChangedDocInCollection(Doc: IFirestoreDocument);
    procedure OnFSDeletedDoc(const DelDocPath: string; TS: TDateTime);
    procedure OnFSDeletedDocCollection(const DelDocPath: string; TS: TDateTime);
    procedure OnFSRequestError(const RequestID, ErrMsg: string);
    procedure OnFSStopListening(const RequestID: string);
  public
    procedure LoadSettingsFromIniFile(IniFile: TIniFile);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
    function CheckAndCreateFirestoreDBClass: boolean;

    property Database: IFirestoreDatabase read fDatabase;
  end;

implementation

uses
{$IFNDEF LINUX64}
  System.Sensors,
{$ENDIF}
  FB4D.Firestore, FB4D.Helpers, FB4D.Document,
  FB4D.DemoFmx;

{$R *.fmx}

{ TFirestoreFra }

{$REGION 'Class Handling'}

function TFirestoreFra.CheckAndCreateFirestoreDBClass: boolean;
begin
  if not assigned(fDatabase) then
  begin
    fDatabase := TFirestoreDatabase.Create(fmxFirebaseDemo.edtProjectID.Text,
      fmxFirebaseDemo.AuthFra.Auth, edtDatabaseID.Text);
    fmxFirebaseDemo.edtProjectID.ReadOnly := true;
    fmxFirebaseDemo.rctProjectIDDisabled.Visible := true;
    fReadTransaction := '';
    fWriteTransaction := nil;
  end;
  result := true;
end;

{$ENDREGION}

{$REGION 'Settings'}

procedure TFirestoreFra.LoadSettingsFromIniFile(IniFile: TIniFile);
begin
  edtCollection.Text := IniFile.ReadString('Firestore', 'Collection', '');
  edtDocument.Text := IniFile.ReadString('Firestore', 'Document', '');
  chbUseChildDoc.IsChecked := IniFile.ReadBool('Firestore', 'UseChild', false);
  chbLimitTo10Docs.IsChecked := IniFile.ReadBool('Firestore', 'Limited', false);
  edtChildCollection.Text := IniFile.ReadString('Firestore', 'ChildCol', '');
  edtChildDocument.Text := IniFile.ReadString('Firestore', 'ChildDoc', '');
  cboDemoDocType.ItemIndex := IniFile.ReadInteger('Firestore', 'DocType', 0);
  edtCollectionIDForFSListener.Text := IniFile.ReadString('Firestore',
    'ListenerColID', '');
  edtDocPathForFSListener.Text := IniFile.ReadString('Firestore', 'DocPath', '');
  CheckDocument;
end;

procedure TFirestoreFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('Firestore', 'Collection', edtCollection.Text);
  IniFile.WriteString('Firestore', 'Document', edtDocument.Text);
  IniFile.WriteBool('Firestore', 'UseChild', chbUseChildDoc.IsChecked);
  IniFile.WriteBool('Firestore', 'Limited', chbLimitTo10Docs.IsChecked);
  IniFile.WriteString('Firestore', 'ChildCol', edtChildCollection.Text);
  IniFile.WriteString('Firestore', 'ChildDoc', edtChildDocument.Text);
  IniFile.WriteInteger('Firestore', 'DocType', cboDemoDocType.ItemIndex);
  IniFile.WriteString('Firestore', 'ListenerColID',
    edtCollectionIDForFSListener.Text);
  IniFile.WriteString('Firestore', 'DocPath', edtDocPathForFSListener.Text);
end;

{$ENDREGION}

function TFirestoreFra.CheckFirestoreFields(InsUpdGetWF: boolean): boolean;
begin
  result := false;
  if edtCollection.Text.IsEmpty then
    memFirestore.Lines.Add('Hint: Collection need to be filled')
  else if not InsUpdGetWF and not chbUseChildDoc.IsChecked then
    result := true
  else if edtDocument.Text.IsEmpty then
     memFirestore.Lines.Add('Hint: Document need to be filled')
  else if not chbUseChildDoc.IsChecked then
    result := true
  else if edtChildCollection.Text.IsEmpty then
    memFirestore.Lines.Add('Hint: Child collection need to be filled')
  else if not InsUpdGetWF then
    result := true
  else if edtChildDocument.Text.IsEmpty then
    memFirestore.Lines.Add('Hint: Child document need to be filled')
  else
    result := true;
end;

procedure TFirestoreFra.CheckDocument;
begin
  edtChildCollection.Visible := chbUseChildDoc.IsChecked;
  edtChildDocument.Visible := chbUseChildDoc.IsChecked;
  chbUsePageToken.Visible := false;
end;

procedure TFirestoreFra.edtDocumentChangeTracking(Sender: TObject);
begin
  CheckDocument;
end;

procedure TFirestoreFra.chbUseChildDocChange(Sender: TObject);
begin
  if chbUseChildDoc.IsChecked and edtDocument.Text.IsEmpty then
  begin
    chbUseChildDoc.IsChecked := false;
    memFirestore.Lines.Add('Hint: You need to enter a Document ID before you ' +
      'can address a child document');
  end;
  edtChildCollection.Visible := chbUseChildDoc.IsChecked;
  edtChildDocument.Visible := chbUseChildDoc.IsChecked;
end;

{$REGION 'General used error callback'}

procedure TFirestoreFra.OnFirestoreError(const Info, ErrMsg: string);
begin
  memFirestore.Lines.Add(Info + ' failed: ' + ErrMsg);
  memFirestore.GoToTextEnd;
end;

{$ENDREGION}

{$REGION 'Create Document'}

procedure TFirestoreFra.btnCreateDocumentClick(Sender: TObject);
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  if not CheckFirestoreFields(false) then
    exit;
  if not chbUseChildDoc.IsChecked then
    fDatabase.CreateDocument([edtCollection.Text], nil, OnFirestoreCreate,
      OnFirestoreError)
  else
    fDatabase.CreateDocument([edtCollection.Text, edtDocument.Text,
      edtChildCollection.Text], nil, OnFirestoreCreate, OnFirestoreError);
end;

procedure TFirestoreFra.OnFirestoreCreate(const Info: string;
  Doc: IFirestoreDocument);
begin
  try
    ShowDocument(Doc);
    if assigned(Doc) and not chbUseChildDoc.IsChecked then
      edtDocument.Text := Doc.DocumentName(false)
    else if not assigned(Doc) and not chbUseChildDoc.IsChecked then
      edtDocument.Text := ''
    else if assigned(Doc) and chbUseChildDoc.IsChecked then
      edtChildDocument.Text := Doc.DocumentName(false)
    else
      edtChildDocument.Text := '';
  except
    on e: exception do
      OnFirestoreError(Info, e.Message);
  end;
end;

{$ENDREGION}

{$REGION 'Insert or Update Document'}

procedure TFirestoreFra.btnInsertOrUpdateDocumentClick(Sender: TObject);
var
  Doc: IFirestoreDocument;
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  if not CheckFirestoreFields(true) then
    exit;
  if not chbUseChildDoc.IsChecked then
    Doc := TFirestoreDocument.Create([edtCollection.Text, edtDocument.Text],
      fDatabase.ProjectID)
  else
    Doc := TFirestoreDocument.Create([edtCollection.Text, edtDocument.Text,
      edtChildCollection.Text, edtChildDocument.Text],
      fDatabase.ProjectID);
  case cboDemoDocType.ItemIndex of
    0: Doc.AddOrUpdateField(TJSONObject.SetString('TestField',
         'Now try to create a simple document 😀 at ' + TimeToStr(now)));
    1: begin
         Doc.AddOrUpdateField(TJSONObject.SetString('MyString',
           'This demonstrates a complex document that contains all supported data types'));
         Doc.AddOrUpdateField(TJSONObject.SetInteger('MyInt', 123)); // Will be overwritten with Inc(2) later by TransformDoc
         Doc.AddOrUpdateField(TJSONObject.SetDouble('MyReal', 1.54)); // Will be overwritten with Max(1.54, 3.14) later by TransformDoc
         Doc.AddOrUpdateField(TJSONObject.SetBoolean('MyBool', true));
         Doc.AddOrUpdateField(TJSONObject.SetTimeStamp('MyTime', now + 0.5)); // Will be overwritten with ServerTime later by TransformDoc
         Doc.AddOrUpdateField(TJSONObject.SetNull('MyNull'));
         Doc.AddOrUpdateField(TJSONObject.SetReference('MyRef', fDatabase.ProjectID,
           edtCollection.Text + '/' + edtDocument.Text));
         Doc.AddOrUpdateField(TJSONObject.SetGeoPoint('MyGeo',
           TLocationCoord2D.Create(1.1, 2.2)));
         Doc.AddOrUpdateField(TJSONObject.SetBytes('MyBytes', [0,1,2,253,254,255]));
         Doc.AddOrUpdateField(TJSONObject.SetMap('MyMap', [
           TJSONObject.SetString('MapStr', 'Map corresponds to a TDictionary in Delphi'),
           TJSONObject.SetInteger('MapInt', 324),
           TJSONObject.SetBoolean('MapBool', false),
           TJSONObject.SetTimeStamp('MapTime', now + 1),
           TJSONObject.SetArray('MapSubArray', [TJSONObject.SetIntegerValue(1),
             TJSONObject.SetStringValue('Types other than in element[0]!')]), // Array in Map
           TJSONObject.SetMap('SubMap', [ // Map in Map
             TJSONObject.SetString('SubMapStr', 'SubText'),
             TJSONObject.SetDouble('SubMapReal', 3.1414),
             TJSONObject.SetGeoPoint('SubMapGeo',
               TLocationCoord2D.Create(-1.0, -2.23)),
             TJSONObject.SetNull('SubMapNull')])]));
         Doc.AddOrUpdateField(TJSONObject.SetArray('MyArr',[
             TJSONObject.SetStringValue('What can I learn next?'),
             TJSONObject.SetStringValue('In order to play later with the function Run Query'),
             TJSONObject.SetStringValue('try also "Docs for Run Query"'),
             // Array in Array is not supported in Firestore: use a map between
             TJSONObject.SetMapValue([
               TJSONObject.SetString('MapInArray_String',
                 'Delphi rocks with Firebase 👨'),
               TJSONObject.SetInteger('MapInArray_Int', 4711)])]));
         Doc.AddOrUpdateField(TJSONObject.SetString('Hint',
           'Keep in mind that the fields order is not defined when call get - ' +
           'multiple gets has different field orders 🤔'));
       end;
    2: begin
         if not chbUseChildDoc.IsChecked then
           Doc.AddOrUpdateField(TJSONObject.SetString('info',
             'This demonstrates a simple collection with random data.'))
         else
           Doc.AddOrUpdateField(TJSONObject.SetString('info',
             'This demonstrates a simple child collection with random data.'));
         Doc.AddOrUpdateField(TJSONObject.SetString('hint',
           'For test Run Query create same record as this one and by press ' +
           'Create Doc and Insert Doc repeatedly, so you have at least 5 documents'));
         Doc.AddOrUpdateField(TJSONObject.SetInteger('testInt', StrToInt(edtTestInt.Text)));
         Doc.AddOrUpdateField(TJSONObject.SetTimeStamp('documentCreated', now));
         edtTestInt.Text := IntToStr(random(100));
       end;
  end;
  if assigned(fWriteTransaction) then
  begin
    fWriteTransaction.UpdateDoc(Doc);
    memFirestore.Lines.Add(Format(
      'UpdateDoc %s on write transaction - use Commit Write to store data',
      [TFirestorePath.GetDocPath(Doc.DocumentPathWithinDatabase)]));
    if cboDemoDocType.ItemIndex = 1 then
    begin
      fWriteTransaction.TransformDoc(Doc.DocumentName(true),
        TFirestoreDocTransform.Create.
          SetServerTime('MyTime').
          Increment('MyInt', TJSONObject.SetIntegerValue(2)).
          Maximum('MyReal', TJSONObject.SetDoubleValue(3.14)));
      memFirestore.Lines.Add(
        'TransformDoc: Demonstrate SetServerTime(MyTime), Inc(MyInt, 2), and Maximum(MyReal, 3.14) by using TransformDoc (for Complex Document only!)');
    end;
  end else
    // Log.d(Doc.AsJSON.ToJSON);
    fDatabase.InsertOrUpdateDocument(Doc, nil, OnFirestoreInsertOrUpdate,
      OnFirestoreError);
end;

procedure TFirestoreFra.OnFirestoreInsertOrUpdate(const Info: string;
  Doc: IFirestoreDocument);
begin
  try
    memFirestore.Lines.Add('Document inserted or updated');
    ShowDocument(Doc);
    if not chbUseChildDoc.IsChecked then
    begin
      if assigned(Doc) then
        edtDocument.Text := Doc.DocumentName(false)
      else
        edtDocument.Text := '';
    end else begin
      if assigned(Doc) then
        edtChildDocument.Text := Doc.DocumentName(false)
      else
        edtChildDocument.Text := '';
    end;
  except
    on e: exception do
      OnFirestoreError(Info, e.Message);
  end;
  Doc := nil;
end;

procedure TFirestoreFra.cboDemoDocTypeChange(Sender: TObject);
begin
  edtTestInt.visible := cboDemoDocType.ItemIndex = 2;
  edtTestInt.Text := IntToStr(random(100));
end;


{$ENDREGION}

{$REGION 'Get Document'}

procedure TFirestoreFra.ShowDocument(Doc: IFirestoreDocument);

  function BytesToHexStr(Bytes: TBytes): string;
  const
    HexChars: string = '0123456789ABCDEF';
  var
    c: integer;
  begin
    result := '[';
    for c := Low(Bytes) to High(Bytes) do
    begin
      result := result + HexChars[1 + Bytes[c] shr 4] +
        HexChars[1 + Bytes[c] and $F];
      if c < High(Bytes) then
        result := result + ', '
      else
        result := result + ']';
    end;
  end;

  function GetFieldVal(const Indent: string; FieldType: TFirestoreFieldType;
    FieldVal: TJSONObject): string;
  var
    c: integer;
    Obj: TJSONObject;
    Pair: TJSONPair;
    SubFieldType: TFirestoreFieldType;
  begin
    result := '';
    case FieldType of
      fftNull:
        result := 'Null';
      fftString:
        result := FieldVal.GetStringValue;
      fftBoolean:
        result := BoolToStr(FieldVal.GetBooleanValue, true);
      fftInteger:
        result := FieldVal.GetIntegerValue.ToString;
      fftDouble:
        result := FieldVal.GetDoubleValue.ToString;
      fftTimeStamp:
        result := DateTimeToStr(FieldVal.GetTimeStampValue(tzLocalTime));
      fftGeoPoint:
        result := Format('[%2.10f°N, %2.10f°E]',
          [FieldVal.GetGeoPoint.Latitude,
           FieldVal.GetGeoPoint.Longitude]);
      fftReference:
        result := FieldVal.GetReference;
      fftBytes:
        result := BytesToHexStr(FieldVal.GetBytes);
      fftArray:
        for c := 0 to FieldVal.GetArraySize - 1 do
        begin
          Obj := FieldVal.GetArrayItem(c);
          SubFieldType := TFirestoreDocument.GetFieldType(
            Obj.Pairs[0].JsonString.Value);
         result := result + #13 + Indent + '[' + c.ToString + ']: ' +
            TRttiEnumerationType.GetName<TFirestoreFieldType>(SubFieldType) +
            ' = ' + GetFieldVal('  ' + Indent, SubFieldType, Obj);
        end;
      fftMap:
        for c := 0 to FieldVal.GetMapSize - 1 do
        begin
          Pair := FieldVal.GetMapItem(c);
          Obj := Pair.JsonValue as TJSONObject;
          SubFieldType := TFirestoreDocument.GetFieldType(
            Obj.Pairs[0].JsonString.Value);
          result := result + #13 + Indent + Pair.JsonString.Value + ': ' +
            TRttiEnumerationType.GetName<TFirestoreFieldType>(SubFieldType) +
            ' = ' + GetFieldVal('  ' + Indent, SubFieldType, Obj);
        end;
      else
        memFirestore.Lines.Add(Indent + 'Unsupported type: ' +
          TRttiEnumerationType.GetName<TFirestoreFieldType>(FieldType));
    end;
  end;

var
  c: integer;
  FieldName: string;
  FieldType: TFirestoreFieldType;
begin
  if assigned(Doc) then
  begin
    memFirestore.Lines.Add('Document name: ' + Doc.DocumentName(true));
    memFirestore.Lines.Add('  Created    : ' + DateTimeToStr(
      doc.createTime(tzLocalTime)));
    memFirestore.Lines.Add('  Updated    : ' + DateTimeToStr(
      doc.updateTime(tzLocalTime)));
    // Log.d(Doc.AsJSON.ToJSON);
    for c := 0 to Doc.CountFields - 1 do
    begin
      FieldName := Doc.FieldName(c);
      FieldType := Doc.FieldType(c);
      memFirestore.Lines.Add('  ' + FieldName + ' : ' +
        TRttiEnumerationType.GetName<TFirestoreFieldType>(FieldType) + ' = ' +
        GetFieldVal('  ', FieldType, Doc.FieldValue(c)));
    end;
  end else
    memFirestore.Lines.Add('No document found');
end;

procedure TFirestoreFra.btnGetClick(Sender: TObject);
var
  Query: TQueryParams;
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  if not CheckFirestoreFields(false) then
    exit;
  if not fReadTransaction.IsEmpty then
    Query := TQueryParams.CreateQueryParams.AddTransaction(fReadTransaction)
  else
    Query := nil;
  if chbLimitTo10Docs.IsChecked then
    Query := TQueryParams.CreateQueryParams(Query).AddPageSize(10);
  if chbUsePageToken.IsChecked then
    Query := TQueryParams.CreateQueryParams(Query).AddPageToken(
      chbUsePageToken.TagString);
  if not chbUseChildDoc.IsChecked then
    fDatabase.Get([edtCollection.Text, edtDocument.Text], Query,
      OnFirestoreGet, OnFirestoreError)
  else
    fDatabase.Get([edtCollection.Text, edtDocument.Text,
      edtChildCollection.Text, edtChildDocument.Text], Query,
      OnFirestoreGet, OnFirestoreError);
  if assigned(Query) then
    Query.Free;
end;

procedure TFirestoreFra.OnFirestoreGet(const Info: string;
  Docs: IFirestoreDocuments);
var
  Doc: IFirestoreDocument;
begin
  try
    if assigned(Docs) and (Docs.Count > 0) then
    begin
      if Docs.MorePagesToLoad then
        memFirestore.Lines.Add(Docs.Count.ToString +
          ' documents fetched but more documents available')
      else if (Docs.SkippedResults = 0) and (Docs.Count > 1) then
        memFirestore.Lines.Add(Docs.Count.ToString + ' documents')
      else if Docs.SkippedResults > 0 then
        memFirestore.Lines.Add(Docs.Count.ToString + ' documents, skipped ' +
          Docs.SkippedResults.ToString);
      chbUsePageToken.IsChecked := Docs.MorePagesToLoad;
      chbUsePageToken.Visible := chbUsePageToken.IsChecked;
      chbUsePageToken.TagString := Docs.PageToken;
      for Doc in Docs do
        ShowDocument(Doc);
    end else
      ShowDocument(nil);
  except
    on e: exception do
      OnFirestoreError(Info, e.Message);
  end;
end;

{$ENDREGION}

{$REGION 'Patch Document'}

procedure TFirestoreFra.btnPatchDocClick(Sender: TObject);
var
  Doc: IFirestoreDocument;
  UpdateMask: TStringDynArray;
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  if not CheckFirestoreFields(true) then
    exit;
  if not chbUseChildDoc.IsChecked then
    Doc := TFirestoreDocument.Create([edtCollection.Text, edtDocument.Text],
      fDatabase.ProjectID)
  else
    Doc := TFirestoreDocument.Create([edtCollection.Text, edtDocument.Text,
      edtChildCollection.Text, edtChildDocument.Text],
      fDatabase.ProjectID);
  Doc.AddOrUpdateField(TJSONObject.SetString('patchedField',
    'This field is added while patch'));
  if cboDemoDocType.ItemIndex = 0 then
    UpdateMask := ['patchedField']
  else begin
    Doc.AddOrUpdateField(TJSONObject.SetString('patchedField2',
      'If this works issue #10 is solved👍'));
    UpdateMask := ['patchedField', 'patchedField2'];
  end;
  if assigned(fWriteTransaction) then
  begin
    fWriteTransaction.PatchDoc(Doc, UpdateMask);
    memFirestore.Lines.Add(Format(
      'PatchDoc %s on write transaction - use Commit Write to store data',
      [TFirestorePath.GetDocPath(Doc.DocumentFullPath)]));
  end else
    fDatabase.PatchDocument(Doc, UpdateMask, OnFirestoreInsertOrUpdate,
      OnFirestoreError);
end;

{$ENDREGION}

{$REGION 'Delete Document'}

procedure TFirestoreFra.btnDeleteDocClick(Sender: TObject);
var
  DocFullPath: string;
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  if not CheckFirestoreFields(true) then
    exit;
  if assigned(fWriteTransaction) then
  begin
    if not chbUseChildDoc.IsChecked then
      DocFullPath := TFirestoreDocument.GetDocFullPath(
        [edtCollection.Text, edtDocument.Text],
        fDatabase.ProjectID)
    else
      DocFullPath := TFirestoreDocument.GetDocFullPath(
        [edtCollection.Text, edtDocument.Text,
         edtChildCollection.Text, edtChildDocument.Text],
        fDatabase.ProjectID);
    fWriteTransaction.DeleteDoc(DocFullPath);
    memFirestore.Lines.Add(Format(
      'DeleteDoc %s on write transaction - use Commit Write to store data',
      [DocFullPath]));
  end
  else if not chbUseChildDoc.IsChecked then
    fDatabase.Delete([edtCollection.Text, edtDocument.Text], nil,
      OnFirestoreDeleted, OnFirestoreError)
  else
    fDatabase.Delete([edtCollection.Text, edtDocument.Text,
      edtChildCollection.Text, edtChildDocument.Text], nil,
      OnFirestoreDeleted, OnFirestoreError)
end;

procedure TFirestoreFra.OnFirestoreDeleted(const DeleteDocumentPath: string;
  TimeStamp: TDateTime);
begin
  memFirestore.Lines.Add('Document deleted: ' + DeleteDocumentPath +
    ' at ' + DateToStr(TimeStamp));
end;

{$ENDREGION}

{$REGION 'Query Document'}

procedure TFirestoreFra.btnRunQueryClick(Sender: TObject);
var
  Query: TQueryParams;
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  if not CheckFirestoreFields(false) then
    exit;
  if not fReadTransaction.IsEmpty then
    Query := TQueryParams.CreateQueryParams.AddTransaction(fReadTransaction)
  else
    Query := nil;
  // The following structured query expects documents that were created with the
  // option 'Docs for Run Query'
  if not chbUseChildDoc.IsChecked then
  begin
    memFirestore.Lines.Add(Format(
      'Query documents: select * from %s where testIn >= %d order by testInt asc',
      [edtCollection.Text, trunc(trbMinTestInt.Value)]));
    fDatabase.RunQuery(
      TStructuredQuery.CreateForCollection(edtCollection.Text).
// To fetch partial documents
//        Select(['testInt']).
        QueryForFieldFilter(
          TQueryFilter.IntegerFieldFilter('testInt', woGreaterThan,
            trunc(trbMinTestInt.Value))).
        OrderBy('testInt', odAscending),
      OnFirestoreGet, OnFirestoreError, Query);
  end else begin
    memFirestore.Lines.Add(
      Format('Query documents: select testInt, documentCreated, info from %s/%s/%s limit 10 where testIn >= %d order by testInt asc, documentCreated desc',
      [edtCollection.Text, edtDocument.Text, edtChildCollection.Text, trunc(trbMinTestInt.Value)]));
    fDatabase.RunQuery([edtCollection.Text, edtDocument.Text],
      TStructuredQuery.CreateForSelect(['testInt', 'documentCreated', 'info']).
        Collection(edtChildCollection.Text).
        QueryForFieldFilter(
          TQueryFilter.IntegerFieldFilter('testInt', woGreaterThan,
            trunc(trbMinTestInt.Value))).
        OrderBy('testInt', odAscending).
        OrderBy('documentCreated', odDescending).
// For testing the cursor function StartAt and EndAt enter existing values from
// your collection for testInt instead of 61 and 85
//        StartAt(TFirestoreDocument.CreateCursor.AddOrUpdateField(
//          TJSONObject.SetInteger('testInt', 61)), false).
//        EndAt(TFirestoreDocument.CreateCursor.AddOrUpdateField(
//          TJSONObject.SetInteger('testInt', 85)), false).
        Limit(10).Offset(0), // returns only the first 10 documents!
      OnFirestoreGet, OnFirestoreError, Query);
  end;
end;

procedure TFirestoreFra.trbMinTestIntChange(Sender: TObject);
begin
  lblMinTestInt.Text := 'Min testInt Val: ' +
    IntToStr(trunc(trbMinTestInt.Value));
end;

{$ENDREGION}

{$REGION 'Database Listener'}

procedure TFirestoreFra.btnStartFSListenerClick(Sender: TObject);
var
  Targets: string;
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  Targets := '';
  if not edtCollectionIDForFSListener.Text.IsEmpty then
  begin
    if TFirestorePath.ContainsPathDelim(edtCollectionIDForFSListener.Text) then
      fDatabase.SubscribeQuery(TStructuredQuery.CreateForCollection(
        TFirestorePath.ExtractLastCollection(
          edtCollectionIDForFSListener.Text),
        chbIncludeDescendants.IsChecked),
        OnFSChangedDocInCollection, OnFSDeletedDocCollection,
        TFirestorePath.DocPathWithoutLastCollection(
          edtCollectionIDForFSListener.Text))
    else
      fDatabase.SubscribeQuery(TStructuredQuery.CreateForCollection(
        edtCollectionIDForFSListener.Text, chbIncludeDescendants.IsChecked),
        OnFSChangedDocInCollection, OnFSDeletedDocCollection);
    Targets := 'Target-1: Collection ';
  end;
  if not edtDocPathForFSListener.Text.IsEmpty then
  begin
    fDatabase.SubscribeDocument(
      TFirestorePath.ConvertToDocPath(edtDocPathForFSListener.Text),
      OnFSChangedDoc, OnFSDeletedDoc);
    Targets := Targets + 'Target-2: Single Doc ';
  end;
  if not Targets.IsEmpty then
  begin
    memFirestore.Lines.Add('Listener started for ' + Targets);
    fDatabase.StartListener(OnFSStopListening, OnFSRequestError,
      OnFSAuthRevoked);
    btnStartFSListener.Enabled := false;
    btnStopFSListener.Enabled := true;
    edtCollectionIDForFSListener.Enabled := false;
    edtDocPathForFSListener.Enabled := false;
    chbIncludeDescendants.Enabled := false;
  end else
    memFirestore.Lines.Add('No target defined for starting listener');
end;

procedure TFirestoreFra.btnStopFSListenerClick(Sender: TObject);
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  fDatabase.StopListener;
  btnStopFSListener.Enabled := false;
  edtCollectionIDForFSListener.Enabled := true;
  edtDocPathForFSListener.Enabled := true;
  chbIncludeDescendants.Enabled := true;
end;

procedure TFirestoreFra.OnFSChangedDocInCollection(
  Doc: IFirestoreDocument);
begin
  memFirestore.Lines.Add('Target-1: ' + TimeToStr(now) + ': Doc changed ' +
    Doc.DocumentName(true));
  memFirestore.Lines.Add(Doc.AsJSON.ToJSON);
end;

procedure TFirestoreFra.OnFSChangedDoc(Doc: IFirestoreDocument);
begin
  memFirestore.Lines.Add('Target-2: ' + TimeToStr(now) + ': Doc changed ' +
    Doc.DocumentName(true));
  memFirestore.Lines.Add(Doc.AsJSON.ToJSON);
end;

procedure TFirestoreFra.OnFSDeletedDocCollection(const DelDocPath: string;
  TS: TDateTime);
begin
  memFirestore.Lines.Add('Target-1: ' + TimeToStr(TS) + ': Doc deleted ' +
    DelDocPath);
end;

procedure TFirestoreFra.OnFSDeletedDoc(const DelDocPath: string;
  TS: TDateTime);
begin
  memFirestore.Lines.Add('Target-2: ' + TimeToStr(TS) + ': Doc deleted ' +
    DelDocPath);
end;

procedure TFirestoreFra.OnFSStopListening(const RequestID: string);
begin
  memFirestore.Lines.Add(TimeToStr(now) + ': Listener for ' + RequestID + ' stopped');
  btnStartFSListener.Enabled := true;
end;

procedure TFirestoreFra.OnFSRequestError(const RequestID, ErrMsg: string);
begin
  memFirestore.Lines.Add(TimeToStr(now) + ': Listener error ' + ErrMsg);
end;

procedure TFirestoreFra.OnFSAuthRevoked(TokenRenewPassed: boolean);
begin
  if TokenRenewPassed then
    memFirestore.Lines.Add(TimeToStr(now) + ': Token renew passed')
  else
    memFirestore.Lines.Add(TimeToStr(now) + ': Token renew failed');
end;

{$ENDREGION}

{$REGION 'Write Transaction'}

procedure TFirestoreFra.btnStartWriteTransactionClick(
  Sender: TObject);
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  fWriteTransaction := fDatabase.BeginWriteTransaction;
  memFirestore.Lines.Add('Write transaction started');
  btnStartWriteTransaction.Enabled := false;
  btnStartReadTransaction.Enabled := false;
  btnCommitWriteTrans.Enabled := true;
  btnStopReadTrans.Enabled := false;
  tabTransactions.ImageIndex := 3;
end;

procedure TFirestoreFra.btnCommitWriteTransClick(Sender: TObject);
var
  Commit: IFirestoreCommitTransaction;
begin
  Assert(assigned(fWriteTransaction), 'Missing write transaction');
  if fWriteTransaction.NumberOfTransactions = 0 then
    memFirestore.Lines.Add('No insert/update, patch, or delete action to commit')
  else
    try
      Commit := fDatabase.CommitWriteTransactionSynchronous(fWriteTransaction);
      memFirestore.Lines.Add('Write transaction comitted at ' +
        DateTimeToStr(Commit.CommitTime));
    except
      on e: EFirebaseResponse do
        memFirestore.Lines.Add('Commit write transaction failed: ' + e.Message);
    end;
  fWriteTransaction := nil;
  btnStopReadTrans.Enabled := false;
  btnCommitWriteTrans.Enabled := false;
  btnStartWriteTransaction.Enabled := true;
  btnStartReadTransaction.Enabled := true;
  tabTransactions.ImageIndex := 0;
end;

{$ENDREGION}

{$REGION 'Read Transaction'}

procedure TFirestoreFra.btnStartReadTransactionClick(Sender: TObject);
begin
  if not CheckAndCreateFirestoreDBClass then
    exit;
  try
    fReadTransaction := fDatabase.BeginReadTransactionSynchronous;
    memFirestore.Lines.Add('Read transaction started: ' + fReadTransaction);
    lblReadTransID.Text := 'Transaction ID: ' + fReadTransaction;
  except
    on e: EFirebaseResponse do
      memFirestore.Lines.Add('Read transaction failed: ' + e.Message);
  end;
  btnStartWriteTransaction.Enabled := false;
  btnStartReadTransaction.Enabled := false;
  btnCommitWriteTrans.Enabled := false;
  btnStopReadTrans.Enabled := true;
  tabTransactions.ImageIndex := 2;
end;

procedure TFirestoreFra.btnStopReadTransClick(Sender: TObject);
begin
  Assert(not fReadTransaction.IsEmpty, 'Missing read transaction');
  fReadTransaction := '';
  lblReadTransID.Text := 'Transaction ID: ';
  btnStopReadTrans.Enabled := false;
  btnCommitWriteTrans.Enabled := false;
  btnStartWriteTransaction.Enabled := true;
  btnStartReadTransaction.Enabled := true;
  tabTransactions.ImageIndex := 0;
end;

{$ENDREGION}

procedure TFirestoreFra.mniClearClick(Sender: TObject);
begin
  memFirestore.Lines.Clear;
end;

end.
