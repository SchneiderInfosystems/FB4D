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

unit FirestoreDB;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Sensors,
  DUnitX.TestFramework,
  FB4D.Interfaces;

{$M+}
type
  [TestFixture]
  UT_FirestoreDB = class(TObject)
  private
    fConfig: IFirebaseConfiguration;
    fErrMsg: string;
    fReqID: string;
    fInfo, fInfo2: string;
    fCallBack: integer;
    fDocChanged: boolean;
    fDocDeleted: boolean;
    fStopped: boolean;
    fDoc, fDoc2: IFirestoreDocument;
    fChangedDocName: string;
    fChangedDocC: integer;
    fChangedDocF1: string;
    fChangedDocF2: integer;
    fDeletedDoc: string;
    fStarted: TDateTime;
    procedure WaitAndCheckTimeout(const Step: string);
    procedure OnError(const RequestID, ErrMsg: string);
    procedure OnDoc(const Info: string; Document: IFirestoreDocument);
    procedure OnDoc2(const Info: string; Document: IFirestoreDocument);
    procedure OnDocs(const Info: string; Documents: IFirestoreDocuments);
    procedure OnDocChanged(ChangedDocument: IFirestoreDocument);
    procedure OnDocDeleted(const DeleteDocumentPath: string;
      TimeStamp: TDateTime);
    procedure OnDocDel(const DeleteDocumentPath: string; TimeStamp: TDateTime);
    procedure OnStop(const RequestID: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    procedure CreateUpdateGetDocumentSynchronous;
    procedure CreateUpdateGetDocument;
    procedure ConcurrentUpdateDocuments;
    procedure FirestoreListenerForSingleDocument;
    procedure Object2DocumentMapper;
    procedure Object2DocumentMapperWithOptions;
  end;

implementation

uses
  VCL.Forms,
  System.StrUtils,
  FB4D.Configuration,
  FB4D.Helpers,
  FB4D.Document,
  Consts;

{$I FBConfig.inc}

const
  cDBPath = 'TestNode';
  cTestF1 = 'TestField1';
  cTestF2 = 'testField2';
  cDoc2Obj = 'Doc2Obj';

{ UT_FirestoreDB }

procedure UT_FirestoreDB.Setup;
begin
  fConfig := TFirebaseConfiguration.Create(cApiKey, cProjectID, cBucket);
  try
    fConfig.Auth.SignUpWithEmailAndPasswordSynchronous(cEmail, cPassword);
  except
    on e: EFirebaseResponse do
    begin
      fConfig.Auth.SignInWithEmailAndPasswordSynchronous(cEMail, cPassword);
      Status('Account already exists');
    end;
  end;
  fErrMsg := '';
  fReqID := '';
  fInfo := '';
  fCallBack := 0;
  fDocChanged := false;
  fDocDeleted := false;
  fDoc := nil;
  fDoc2 := nil;
  fChangedDocName := '';
  fChangedDocC := -1;
  fChangedDocF1 := '';
  fChangedDocF2 := -1;
  fDeletedDoc := '';
  fStopped := false;
  fStarted := now;
end;

procedure UT_FirestoreDB.TearDown;
begin
  if assigned(fDoc) then
    fConfig.Database.DeleteSynchronous([cDBPath, fDoc.DocumentName(false)]);
  if assigned(fDoc2) then
    fConfig.Database.DeleteSynchronous([cDBPath, fDoc2.DocumentName(false)]);
  fConfig.Auth.DeleteCurrentUserSynchronous;
  fConfig := nil;
end;

procedure UT_FirestoreDB.WaitAndCheckTimeout(const Step: string);
const
  cTimeout = 15 / 24 / 3600; // 15 sec
begin
  Application.ProcessMessages;
  if now - fStarted > cTimeout then
    Assert.Fail('Timeout in ' + Step);
end;

procedure UT_FirestoreDB.OnDoc(const Info: string;
  Document: IFirestoreDocument);
begin
  fDoc := Document;
  fInfo := Info;
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnDoc2(const Info: string;
  Document: IFirestoreDocument);
begin
  fDoc2 := Document;
  fInfo2 := Info;
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnDocChanged(ChangedDocument: IFirestoreDocument);
begin
  fDocChanged := true;
  fChangedDocName := ChangedDocument.DocumentName(false);
  fChangedDocC := ChangedDocument.CountFields;
  fChangedDocF1 := ChangedDocument.GetStringValue(cTestF1);
  fChangedDocF2 := ChangedDocument.GetIntegerValueDef(cTestF2, -1);
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnDocDel(const DeleteDocumentPath: string;
  TimeStamp: TDateTime);
begin
  fDocDeleted := true;
  fInfo2 := DeleteDocumentPath;
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnDocDeleted(const DeleteDocumentPath: string;
  TimeStamp: TDateTime);
begin
  fDeletedDoc := DeleteDocumentPath;
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnDocs(const Info: string;
  Documents: IFirestoreDocuments);
begin
  if not assigned(Documents) or (Documents.Count <> 1) then
    fErrMsg := 'Get documents not 1 as expected'
  else
    fDoc := Documents.Document(0);
  fInfo := Info;
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnError(const RequestID, ErrMsg: string);
begin
  fReqID := RequestID;
  fErrMsg := ErrMsg;
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnStop(const RequestID: string);
begin
  fStopped := true;
  inc(fCallBack);
end;

procedure UT_FirestoreDB.CreateUpdateGetDocumentSynchronous;
var
  DocName: string;
  Doc: IFirestoreDocument;
  Docs: IFirestoreDocuments;
begin
  fDoc := fConfig.Database.CreateDocumentSynchronous([cDBPath]);
  Assert.IsNotNull(fDoc, 'Result of CreateDocument is nil');
  DocName := fDoc.DocumentName(false);
  Status('Document created: ' + DocName);
  Assert.AreEqual(fDoc.DocumentName(true),
    'projects/' + cProjectID + '/databases/(default)/documents/' + cDBPath + '/' + DocName,
    'Doc name not expected: ' + fDoc.DocumentName(true));

  fDoc.AddOrUpdateField(TJSONObject.SetString('Item1', 'TestVal1'));
  fDoc.AddOrUpdateField(TJSONObject.SetBoolean('Item2', true));
  fDoc.AddOrUpdateField(TJSONObject.SetInteger('Item3', 13));
  fDoc.AddOrUpdateField(TJSONObject.SetMap('Item4', [
    TJSONObject.SetString('Item4.1', 'Test4.1'),
    TJSONObject.SetDouble('Item4.2', 7.3254),
    TJSONObject.SetGeoPoint('Item4.3',
      TLocationCoord2D.Create(-1.6423, 6.8954)),
    TJSONObject.SetNull('Item4.4')]));
  Status('Document created: ' + fDoc.CountFields.ToString + ' fields');

  Doc := fConfig.Database.InsertOrUpdateDocumentSynchronous(fDoc);
  Status('InsertOrUpdateDocument passed');
  Assert.AreEqual(fDoc.CountFields, Doc.CountFields, 'Doc field count not as expected');
  Assert.AreEqual(Doc.FieldByName('Item1').GetStringValue, 'TestVal1', 'Item1 does not match');
  Assert.AreEqual(Doc.FieldByName('Item2').GetBooleanValue, true, 'Item2 does not match');
  Assert.AreEqual(Doc.FieldByName('Item3').GetIntegerValue, 13, 'Item3 does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapSize, 4, 'Item4 map size does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.1').GetStringValue, 'Test4.1', 'Item4.1 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.2').GetDoubleValue, 7.3254, 0.0001, 'Item4.2 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Latitude, -1.6423, 0.000001, 'Item4.3.Lat value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Longitude, 6.8954, 0.000001, 'Item4.3.Long value does not match');
  Assert.IsTrue(Doc.FieldByName('Item4').GetMapItem('Item4.4').IsNull, 'Item4.4 value does not match');
  Status('Document check passed');

  Docs := fConfig.Database.GetSynchronous([cDBPath, DocName]);
  Assert.IsNotNull(Docs, 'Get documents failed');
  Assert.AreEqual(Docs.Count, 1, 'Get documents not 1 as expected');
  Doc := Docs.Document(0);
  Assert.AreEqual(Doc.DocumentName(true),
    'projects/' + cProjectID + '/databases/(default)/documents/' + cDBPath + '/' + DocName,
    'Doc name not expected: ' + Doc.DocumentName(true));
  Status('Get passed');
  Assert.AreEqual(fDoc.CountFields, Doc.CountFields, 'Doc field count not as expected');
  Assert.AreEqual(Doc.FieldByName('Item1').GetStringValue, 'TestVal1', 'Item1 does not match');
  Assert.AreEqual(Doc.FieldByName('Item2').GetBooleanValue, true, 'Item2 does not match');
  Assert.AreEqual(Doc.FieldByName('Item3').GetIntegerValue, 13, 'Item3 does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapSize, 4, 'Item4 map size does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.1').GetStringValue, 'Test4.1', 'Item4.1 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.2').GetDoubleValue, 7.3254, 0.0001, 'Item4.2 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Latitude, -1.6423, 0.000001, 'Item4.3.Lat value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Longitude, 6.8954, 0.000001, 'Item4.3.Long value does not match');
  Assert.IsTrue(Doc.FieldByName('Item4').GetMapItem('Item4.4').IsNull, 'Item4.4 value does not match');
  Status('Document check 2 passed: ' + fDoc.DocumentName(true) + ' created ' + DateTimeToStr(fDoc.CreateTime));
end;

procedure UT_FirestoreDB.CreateUpdateGetDocument;
var
  DocName: string;
  Doc: IFirestoreDocument;
begin
  fConfig.Database.CreateDocument([cDBPath], nil, OnDoc, OnError);
  while fCallBack < 1 do
    WaitAndCheckTimeout('CreateDocument');
  Status('CreateDocument passed: ' + fInfo);
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  DocName := fDoc.DocumentName(false);
  Status('Document created: ' + DocName);
  Assert.AreEqual(fDoc.DocumentName(true),
    'projects/' + cProjectID + '/databases/(default)/documents/' + cDBPath + '/' + DocName,
    'Doc name not expected: ' + fDoc.DocumentName(true));

  fDoc.AddOrUpdateField(TJSONObject.SetString('Item1', 'TestVal1'));
  fDoc.AddOrUpdateField(TJSONObject.SetBoolean('Item2', true));
  fDoc.AddOrUpdateField(TJSONObject.SetInteger('Item3', 13));
  fDoc.AddOrUpdateField(TJSONObject.SetMap('Item4', [
    TJSONObject.SetString('Item4.1', 'Test4.1'),
    TJSONObject.SetDouble('Item4.2', 7.3254),
    TJSONObject.SetGeoPoint('Item4.3',
      TLocationCoord2D.Create(-1.6423, 6.8954)),
    TJSONObject.SetNull('Item4.4')]));
  Status('Document created: ' + fDoc.CountFields.ToString + ' fields');
  Doc := fDoc;

  fDoc := nil;
  fCallBack := 0;
  fConfig.Database.InsertOrUpdateDocument(Doc, nil, OnDoc, OnError);
  while fCallBack < 1 do
    WaitAndCheckTimeout('InsertOrUpdateDocument');
  Status('InsertOrUpdateDocument passed: ' + fInfo);
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDoc.CountFields, Doc.CountFields, 'Doc field count not as expected');
  Assert.AreEqual(Doc.FieldByName('Item1').GetStringValue, 'TestVal1', 'Item1 does not match');
  Assert.AreEqual(Doc.FieldByName('Item2').GetBooleanValue, true, 'Item2 does not match');
  Assert.AreEqual(Doc.FieldByName('Item3').GetIntegerValue, 13, 'Item3 does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapSize, 4, 'Item4 map size does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.1').GetStringValue, 'Test4.1', 'Item4.1 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.2').GetDoubleValue, 7.3254, 0.0001, 'Item4.2 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Latitude, -1.6423, 0.000001, 'Item4.3.Lat value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Longitude, 6.8954, 0.000001, 'Item4.3.Long value does not match');
  Assert.IsTrue(Doc.FieldByName('Item4').GetMapItem('Item4.4').IsNull, 'Item4.4 value does not match');
  Status('Document check passed');

  fCallBack := 0;
  fConfig.Database.Get([cDBPath, DocName], nil, OnDocs, OnError);
  while fCallBack < 1 do
    WaitAndCheckTimeout('Get');
  Status('Get passed: ' + fInfo);
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDoc.CountFields, Doc.CountFields, 'Doc field count not as expected');
  Assert.AreEqual(Doc.FieldByName('Item1').GetStringValue, 'TestVal1', 'Item1 does not match');
  Assert.AreEqual(Doc.FieldByName('Item2').GetBooleanValue, true, 'Item2 does not match');
  Assert.AreEqual(Doc.FieldByName('Item3').GetIntegerValue, 13, 'Item3 does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapSize, 4, 'Item4 map size does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.1').GetStringValue, 'Test4.1', 'Item4.1 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.2').GetDoubleValue, 7.3254, 0.0001, 'Item4.2 value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Latitude, -1.6423, 0.000001, 'Item4.3.Lat value does not match');
  Assert.AreEqual(Doc.FieldByName('Item4').GetMapItem('Item4.3').GetGeoPoint.Longitude, 6.8954, 0.000001, 'Item4.3.Long value does not match');
  Assert.IsTrue(Doc.FieldByName('Item4').GetMapItem('Item4.4').IsNull, 'Item4.4 value does not match');
  Status('Document check 2 passed');
end;

procedure UT_FirestoreDB.ConcurrentUpdateDocuments;
const
  Doc1Name = 'Doc1';
  Doc2Name = 'Doc2';
var
  Doc1, Doc2: IFirestoreDocument;
begin
  Doc1 := TFirestoreDocument.Create([cDBPath, Doc1Name], fConfig.ProjectID);
  Doc1.AddOrUpdateField(TJSONObject.SetString('TestField', 'Alpha 😀'));

  Doc2 := TFirestoreDocument.Create([cDBPath, Doc2Name], fConfig.ProjectID);
  Doc2.AddOrUpdateField(TJSONObject.SetString('TestField2', 'Beta 👨'));

  fConfig.Database.InsertOrUpdateDocument(Doc1, nil, OnDoc, OnError);
  fConfig.Database.InsertOrUpdateDocument(Doc2, nil, OnDoc2, OnError);
  while fCallBack < 2 do
    WaitAndCheckTimeout('InsertOrUpdateDocument-2');
  Status('InsertOrUpdateDocument passed: ' + fInfo);
  Status('InsertOrUpdateDocument 2 passed: ' + fInfo2);
  Assert.IsNotNull(fDoc, 'Document 1 nil');
  Assert.IsNotNull(fDoc2, 'Document 2 nil');
  Assert.AreEqual(fDoc.DocumentName(false), Doc1Name);
  Assert.AreEqual(fDoc2.DocumentName(false), Doc2Name);
end;

procedure UT_FirestoreDB.FirestoreListenerForSingleDocument;
const
  cTestString = 'First test';
  cTestString2 = 'First 😀 Test';
  cTestInt = 4711;
var
  DocID: string;
  Doc: IFirestoreDocument;
begin
  DocID := TFirebaseHelpers.CreateAutoID + '-_'; // Test with critical characters '-' and '_'
  Status('Check for DocID including critical characters "-" and "_": ' + DocID);
  fConfig.Database.SubscribeDocument([cDBPath, DocID], OnDocChanged, OnDocDeleted);
  fConfig.Database.StartListener(OnStop, OnError);
  while fCallBack < 1 do
    WaitAndCheckTimeout('StartListener');
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.IsTrue(fDeletedDoc.EndsWith(DocID), 'Unexpected deleted doc: "' + fDeletedDoc + '"');
  Status('OnDocDeleted check passed for empty query');

  fCallBack := 0;
  Doc := TFirestoreDocument.Create([cDBPath, DocID], fConfig.ProjectID);
  Doc.AddOrUpdateField(TJSONObject.SetString(cTestF1, cTestString));
  Doc.AddOrUpdateField(TJSONObject.SetInteger(cTestF2, cTestInt));
  fConfig.Database.InsertOrUpdateDocument(Doc, nil, OnDoc, OnError);
  while not fDocChanged do
    WaitAndCheckTimeout('InsertOrUpdateDocument');
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDoc.DocumentName(false), DocID, 'DocID');
  Status('InsertOrUpdateDocument passed: ' + fInfo);

  Assert.AreEqual(fChangedDocName, DocID, 'Changed Doc ID');
  Assert.AreEqual(fChangedDocF1, cTestString , 'F1');
  Assert.AreEqual(fChangedDocF2, cTestInt, 'F2');
  Assert.AreEqual(fChangedDocC, 2, 'FCount');
  Status('OnDocChanged check passed');

  fCallBack := 0;
  fDocChanged := false;
  Doc := TFirestoreDocument.Create([cDBPath, DocID], fConfig.ProjectID);
  Doc.AddOrUpdateField(TJSONObject.SetString(cTestF1, cTestString2));
  fConfig.Database.InsertOrUpdateDocument(Doc, nil, OnDoc, OnError);

  while not fDocChanged do
    WaitAndCheckTimeout('InsertOrUpdateDocument-2');

  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDoc.DocumentName(false), DocID, '2nd DocID');
  Status('2nd InsertOrUpdateDocument passed: ' + fInfo);

  Assert.AreEqual(fChangedDocName, DocID, '2nd Changed Doc ID');
  Assert.AreEqual(fChangedDocF1, cTestString2, '2nd F1');
  Assert.AreEqual(fChangedDocF2, -1, '2nd F2');
  Assert.AreEqual(fChangedDocC, 1, '2nd FCount');
  Status('2nd OnDocChanged check passed');

  fCallBack := 0;
  fDeletedDoc := '';
  fDocDeleted := false;
  fConfig.Database.Delete([cDBPath, DocID], nil, OnDocDel, onError);

  while not fDocDeleted or fDeletedDoc.IsEmpty do
    WaitAndCheckTimeout('Delete');

  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDeletedDoc, fDoc.DocumentName(true), 'DeleteDoc ID wrong');
  Status('3rd: Document deletion check passed');
  fDoc := nil;

  fConfig.Database.StopListener;
  while not fStopped do
    WaitAndCheckTimeout('StopListener');
  Status('Listener stopped properly');
end;

type
  {$TYPEINFO ON}
  TMySet = set of Byte;
  TMyEnum = (_Alpha, _Beta, _Gamma, _Delta);
  TArrDouble = array[0..1] of double;
  TRec = record
    First: string;
    Second: integer;
    Third: extended;
  end;
  TRec2 = record
    StateOk: boolean;
    ErrorTS: TDateTime;
    ErrNo: integer;
    ErrMsg: string;
  end;
  TRec3 = record
    TestEnum: TMyEnum;
    ArrInRec: array[0..2] of string;
    DArrInRec: array of integer;
  end;
  TArrRec = array[0..1] of TRec2;
  TDynArrRec = array of TRec;
  TMyFSDoc = class(TFirestoreDocument)
  public
    DocTitle: string;
    Msg: AnsiString;
    Flag: Boolean;
    Ch: Char;
    CreationDateTime: TDateTime;
    TestInt: integer;
    LargeNumber: Int64;
    B: Byte;
    FloatSmall: single;
    FloatMedium: double;
    FloatLarge: extended;
    MyEnum: TMyEnum;
    MySet, MySet2: TMySet;
    CArrDouble: TArrDouble; // array[0..1] of double;
    DArrInt: array of integer;
    DArrStr: array of string;
    DArrTime: array of TDateTime;
    Rec: TRec;
//    record
//      First: string;
//      Second: integer;
//      Third: extended;
//    end;
    ArrRec: TArrRec;
    DynArrRec: TDynArrRec;
    ArrArrStr: array[0..1, 0..1] of string;
    Rec3: TRec3;
    DArrRec3: array of TRec3;
    fLoc: TLocationCoord2D;
  end;

procedure UT_FirestoreDB.Object2DocumentMapper;
const
  sTitle = 'Object to Document';
  saMessage = '''
    I hope that this new approach will make the use of FB4D.Firestore
    extremely easy compared to the access via field getter and setter
    methods.
    ''';
var
  DocPath: TRequestResourceParam;
  Doc, Doc2: TMyFSDoc;
  DocI: IFirestoreDocument;
  i, j, k: integer;
begin
  DocPath := [cDoc2Obj, TFirebaseHelpers.CreateAutoID(FSID)];
  Doc := TMyFSDoc.Create(DocPath, fConfig.Database);
  Doc.DocTitle := sTitle;
  Doc.Msg := saMessage;
  Doc.Flag := false;
  Doc.Ch := '@';
  Doc.CreationDateTime := now;
  Doc.TestInt := 4711;
  Doc.LargeNumber := 100_200_300;
  Doc.B := random(255);
  Doc.FloatSmall := 1.1119;
  Doc.FloatMedium := 2.222229;
  Doc.FloatLarge := 3.33333333339;
  Doc.MyEnum := _Beta;
  Doc.MySet := [1, 3, 65, 128, 255];
  Doc.MySet2 := [];
  Doc.CArrDouble[0] := 1.0;
  Doc.CArrDouble[1] := 2.0;
  SetLength(Doc.DArrInt, 3);
  Doc.DArrInt[0] := 11; Doc.DArrInt[1] := 33; Doc.DArrInt[2] := 35;
  SetLength(Doc.DArrStr, 6);
  Doc.DArrStr[0] := '1st'; Doc.DArrStr[1] := '2nd'; Doc.DArrStr[2] := '3rd';
  Doc.DArrStr[3] := '4th'; Doc.DArrStr[4] := '5th'; Doc.DArrStr[5] := '6th';
  SetLength(Doc.DArrTime, 2);
  Doc.DArrTime[0] := now; Doc.DArrTime[1] := trunc(Now) + 1;
  Doc.Rec.First := 'Test Record';
  Doc.Rec.Second := 5511;
  Doc.Rec.Third := 3.1415;
  Doc.ArrRec[0].ErrorTS := now - 1;
  Doc.ArrRec[0].ErrNo := 27;
  Doc.ArrRec[0].ErrMsg := 'Check the device';
  Doc.ArrRec[0].StateOk := false;
  Doc.ArrRec[1].ErrorTS := now - 0.5;
  Doc.ArrRec[1].ErrNo := 28;
  Doc.ArrRec[1].ErrMsg := 'Check the server';
  Doc.ArrRec[1].StateOk := true;
  SetLength(Doc.DynArrRec, 3);
  Doc.DynArrRec[0].First := '1.1';
  Doc.DynArrRec[0].Second := 12;
  Doc.DynArrRec[0].Third := 1.3;
  Doc.DynArrRec[1].First := '2.1';
  Doc.DynArrRec[1].Second := 22;
  Doc.DynArrRec[1].Third := 2.3;
  Doc.DynArrRec[2].First := '3.1';
  Doc.DynArrRec[2].Second := 32;
  Doc.DynArrRec[2].Third := 3.3;
  Doc.ArrArrStr[0, 0] := '[0,0]';
  Doc.ArrArrStr[0, 1] := '[0,1]';
  Doc.ArrArrStr[1, 0] := '[1,0]';
  Doc.ArrArrStr[1, 1] := '[1,1]';
  Doc.Rec3.TestEnum := _Gamma;
  Doc.Rec3.ArrInRec[0] := 'alpha α';
  Doc.Rec3.ArrInRec[1] := 'beta ϐ';
  Doc.Rec3.ArrInRec[2] := 'gamma ɣ';
  SetLength(Doc.Rec3.DArrInRec, 3);
  Doc.Rec3.DArrInRec[0] := 7;
  Doc.Rec3.DArrInRec[1] := 9;
  Doc.Rec3.DArrInRec[2] := 11;
  SetLength(Doc.DArrRec3, 2);
  Doc.DArrRec3[0].TestEnum := _Gamma;
  Doc.DArrRec3[0].ArrInRec[0] := 'α';
  Doc.DArrRec3[0].ArrInRec[1] := 'ϐ';
  Doc.DArrRec3[0].ArrInRec[2] := 'ɣ';
  SetLength(Doc.DArrRec3[0].DArrInRec, 0);
  Doc.DArrRec3[1].TestEnum := _Gamma;
  Doc.DArrRec3[1].ArrInRec[0] := 'Δ';
  Doc.DArrRec3[1].ArrInRec[1] := 'ε';
  Doc.DArrRec3[1].ArrInRec[2] := 'ɸ';
  SetLength(Doc.DArrRec3[1].DArrInRec, 1);
  Doc.DArrRec3[1].DArrInRec[0] := 13;
  Doc.fLoc := TLocationCoord2D.Create(1.001, 2.002);
  fConfig.Database.InsertOrUpdateDocumentSynchronous(Doc.SaveObjectToDocument);
  Status('Document saved ' + Doc.DocumentName(false));
  try
    i := 0;
    for DocI in fConfig.Database.GetSynchronous(DocPath) do
    begin
      Doc2 := TMyFSDoc.LoadObjectFromDocument(DocI);
      Status('Document loaded ' + Doc2.DocumentName(false));
      Assert.AreEqual(Doc.DocTitle, Doc2.DocTitle, 'Wrong DocTitle');
      Assert.AreEqual(Doc.Msg, Doc2.Msg, 'Wrong Msg');
      Assert.AreEqual(Doc.Flag, Doc2.Flag, 'Wrong Flag');
      Assert.AreEqual(Doc.Ch, Doc2.Ch, 'Wrong Ch');
      Assert.AreEqual(DateTimeToStr(Doc.CreationDateTime), DateTimeToStr(Doc2.CreationDateTime), 'Wrong CreationDateTime');
      Assert.AreEqual(Doc.TestInt, Doc2.TestInt, 'Wrong TestInt');
      Assert.AreEqual(Doc.LargeNumber, Doc2.LargeNumber, 'Wrong LargeNumber');
      Assert.AreEqual(Doc.B, Doc2.B, 'Wrong B');
      Assert.AreEqual(Doc.FloatSmall, Doc2.FloatSmall, 'Wrong FloatSmall');
      Assert.AreEqual(Doc.FloatMedium, Doc2.FloatMedium, 'Wrong FloatMedium');
      Assert.AreEqual(Doc.FloatLarge, Doc2.FloatLarge, 'Wrong FloatLarge');
      Assert.AreEqual(Doc.MyEnum, Doc2.MyEnum, 'Wrong MyEnum');
      Assert.AreEqual(Doc.MySet, Doc2.MySet, 'Wrong MySet');
      Assert.AreEqual(Doc.MySet2, Doc2.MySet2, 'Wrong MySet2');
      Assert.AreEqual(Doc.CArrDouble[0], Doc2.CArrDouble[0], 'Wrong CArrDouble[0]');
      Assert.AreEqual(Doc.CArrDouble[1], Doc2.CArrDouble[1], 'Wrong CArrDouble[1]');
      Assert.AreEqual(length(Doc.DArrInt), length(Doc2.DArrInt), 'Wrong DArrInt.length');
      for j := 0 to length(Doc.DArrInt) - 1 do
        Assert.AreEqual(Doc.DArrInt[j], Doc2.DArrInt[j], 'Wrong DArrInt[' + j.ToString + ']');
      Assert.AreEqual(length(Doc.DArrStr), length(Doc2.DArrStr), 'Wrong DArrStr.length');
      for j := 0 to length(Doc.DArrStr) - 1 do
        Assert.AreEqual(Doc.DArrStr[j], Doc2.DArrStr[j], 'Wrong DArrStr[' + j.ToString + ']');
      Assert.AreEqual(length(Doc.DArrTime), length(Doc2.DArrTime), 'Wrong DArrTime.length');
      for j := 0 to length(Doc.DArrTime) - 1 do
        Assert.AreEqual(DateTimeToStr(Doc.DArrTime[j]), DateTimeToStr(Doc2.DArrTime[j]), 'Wrong DArrTime[' + j.ToString + ']');
      Assert.AreEqual(Doc.Rec.First, Doc2.Rec.First, 'Wrong Rec.First');
      Assert.AreEqual(Doc.Rec.Second, Doc2.Rec.Second, 'Wrong Rec.Second');
      Assert.AreEqual(Doc.Rec.Third, Doc2.Rec.Third, 'Wrong Rec.Third');
      for j := 0 to length(Doc.ArrRec) - 1 do
      begin
        Assert.AreEqual(Doc.ArrRec[j].StateOk, Doc2.ArrRec[j].StateOk, 'Wrong Doc.ArrRec[' + j.ToString + '].StateOk');
        Assert.AreEqual(Doc.ArrRec[j].ErrMsg, Doc2.ArrRec[j].ErrMsg, 'Wrong Doc.ArrRec[' + j.ToString + '].ErrMsg');
        Assert.AreEqual(Doc.ArrRec[j].ErrNo, Doc2.ArrRec[j].ErrNo, 'Wrong Doc.ArrRec[' + j.ToString + '].ErrNo');
        Assert.AreEqual(DateTimeToStr(Doc.ArrRec[j].ErrorTS), DateTimeToStr(Doc2.ArrRec[j].ErrorTS), 'Wrong Doc.ArrRec[' + j.ToString + '].ErrMsg');
      end;
      for j := 0 to length(Doc.DynArrRec) - 1 do
      begin
        Assert.AreEqual(Doc.DynArrRec[j].First, Doc2.DynArrRec[j].First, 'Wrong DynArrRec[' + j.ToString + '].First');
        Assert.AreEqual(Doc.DynArrRec[j].Second, Doc2.DynArrRec[j].Second, 'Wrong DynArrRec[' + j.ToString + '].Second');
        Assert.AreEqual(Doc.DynArrRec[j].Third, Doc2.DynArrRec[j].Third, 'Wrong DynArrRec[' + j.ToString + '].Third');
      end;
      for j := 0 to 1 do
        for k := 0 to 1 do
          Assert.AreEqual(Doc.ArrArrStr[j, k], Doc2.ArrArrStr[j, k], 'Wrong ArrArrStr[' + j.ToString + ',' + k.ToString + ']');
      Assert.AreEqual(Doc.Rec3.TestEnum, Doc2.Rec3.TestEnum, 'Wrong Rec3.TestEnum');
      Assert.AreEqual(Doc.Rec3.ArrInRec[0], Doc2.Rec3.ArrInRec[0], 'Wrong Rec3.ArrInRec[0]');
      Assert.AreEqual(Doc.Rec3.ArrInRec[1], Doc2.Rec3.ArrInRec[1], 'Wrong Rec3.ArrInRec[1]');
      Assert.AreEqual(Doc.Rec3.ArrInRec[2], Doc2.Rec3.ArrInRec[2], 'Wrong Rec3.ArrInRec[2]');
      Assert.AreEqual(Doc.Rec3.DArrInRec[0], Doc2.Rec3.DArrInRec[0], 'Wrong Rec3.DArrInRec[0]');
      Assert.AreEqual(Doc.Rec3.DArrInRec[1], Doc2.Rec3.DArrInRec[1], 'Wrong Rec3.DArrInRec[1]');
      Assert.AreEqual(Doc.Rec3.DArrInRec[2], Doc2.Rec3.DArrInRec[2], 'Wrong Rec3.DArrInRec[2]');
      Assert.AreEqual(Doc.DArrRec3[0].TestEnum, Doc2.DArrRec3[0].TestEnum, 'Wrong DArrRec3[0].TestEnum');
      Assert.AreEqual(Doc.DArrRec3[0].ArrInRec[0], Doc2.DArrRec3[0].ArrInRec[0], 'Wrong DArrRec3[0].ArrInRec[0]');
      Assert.AreEqual(Doc.DArrRec3[0].ArrInRec[1], Doc2.DArrRec3[0].ArrInRec[1], 'Wrong DArrRec3[0].ArrInRec[1]');
      Assert.AreEqual(Doc.DArrRec3[0].ArrInRec[2], Doc2.DArrRec3[0].ArrInRec[2], 'Wrong DArrRec3[0].ArrInRec[2]');
      Assert.AreEqual(length(Doc.DArrRec3[0].DArrInRec), length(Doc2.DArrRec3[0].DArrInRec), 'Wrong length(DArrRec3[0].DArrInRec)');
      Assert.AreEqual(Doc.DArrRec3[1].TestEnum, Doc2.DArrRec3[1].TestEnum, 'Wrong Doc.DArrRec3[1].TestEnum');
      Assert.AreEqual(Doc.DArrRec3[1].ArrInRec[0], Doc2.DArrRec3[1].ArrInRec[0], 'Wrong DArrRec3[1].ArrInRec[0]');
      Assert.AreEqual(Doc.DArrRec3[1].ArrInRec[1], Doc2.DArrRec3[1].ArrInRec[1], 'Wrong DArrRec3[1].ArrInRec[1]');
      Assert.AreEqual(Doc.DArrRec3[1].ArrInRec[2], Doc2.DArrRec3[1].ArrInRec[2], 'Wrong DArrRec3[1].ArrInRec[2]');
      Assert.AreEqual(length(Doc.DArrRec3[1].DArrInRec), length(Doc2.DArrRec3[1].DArrInRec), 'Wrong length(DArrRec3[1].DArrInRec)');
      Assert.AreEqual(Doc.DArrRec3[1].DArrInRec[0], Doc2.DArrRec3[1].DArrInRec[0], 'Wrong DArrRec3[1].DArrInRec[0]');
      Status('Document check passed ' + Doc2.DocumentName(false));
      inc(i);
    end;
    Assert.AreEqual(i, 1, 'Wrong document count');
  finally
    fConfig.Database.DeleteSynchronous(DocPath);
    Status('Document deleted ' + Doc.DocumentName(false));
  end;
  FreeAndNil(Doc);
  FreeAndNil(Doc2);
end;

procedure UT_FirestoreDB.Object2DocumentMapperWithOptions;
const
  sTitle = 'Object to Document';
  saMessage = '''
    I hope that this new approach will make the use of FB4D.Firestore
    extremely easy compared to the access via field getter and setter
    methods.
    ''';
var
  DocPath: TRequestResourceParam;
  Doc, Doc2: TMyFSDoc;
  DocI: IFirestoreDocument;
  i, j, k: integer;
  Options: TOTDMapperOptions;
begin
  Options := [omSupressSaveDefVal, omSaveEnumAsString, omEliminateFieldPrefixF];
  DocPath := [cDoc2Obj, TFirebaseHelpers.CreateAutoID(FSID)];
  Doc := TMyFSDoc.Create(DocPath, fConfig.Database);
  Doc.DocTitle := sTitle;
  Doc.Msg := saMessage;
  Doc.Flag := false;
  Doc.Ch := '@';
  Doc.CreationDateTime := now;
  Doc.TestInt := 4711;
  Doc.LargeNumber := 100_200_300;
  Doc.B := random(255);
  Doc.FloatSmall := 1.1119;
  Doc.FloatMedium := 2.222229;
  Doc.FloatLarge := 3.33333333339;
  Doc.MyEnum := _Delta;
  Doc.MySet := [1, 3, 65, 128, 255];
  Doc.MySet2 := [];
  Doc.CArrDouble[0] := 1.0;
  Doc.CArrDouble[1] := 2.0;
  SetLength(Doc.DArrInt, 3);
  Doc.DArrInt[0] := 11; Doc.DArrInt[1] := 33; Doc.DArrInt[2] := 35;
  SetLength(Doc.DArrStr, 6);
  Doc.DArrStr[0] := '1st'; Doc.DArrStr[1] := '2nd'; Doc.DArrStr[2] := '3rd';
  Doc.DArrStr[3] := '4th'; Doc.DArrStr[4] := '5th'; Doc.DArrStr[5] := '6th';
  SetLength(Doc.DArrTime, 2);
  Doc.DArrTime[0] := now; Doc.DArrTime[1] := trunc(Now) + 1;
  Doc.Rec.First := 'Test Record';
  Doc.Rec.Second := 5511;
  Doc.Rec.Third := 3.1415;
  Doc.ArrRec[0].ErrorTS := now - 1;
  Doc.ArrRec[0].ErrNo := 27;
  Doc.ArrRec[0].ErrMsg := 'Check the device';
  Doc.ArrRec[0].StateOk := false;
  Doc.ArrRec[1].ErrorTS := now - 0.5;
  Doc.ArrRec[1].ErrNo := 28;
  Doc.ArrRec[1].ErrMsg := 'Check the server';
  Doc.ArrRec[1].StateOk := true;
  SetLength(Doc.DynArrRec, 3);
  Doc.DynArrRec[0].First := '1.1';
  Doc.DynArrRec[0].Second := 12;
  Doc.DynArrRec[0].Third := 1.3;
  Doc.DynArrRec[1].First := '2.1';
  Doc.DynArrRec[1].Second := 22;
  Doc.DynArrRec[1].Third := 2.3;
  Doc.DynArrRec[2].First := '3.1';
  Doc.DynArrRec[2].Second := 32;
  Doc.DynArrRec[2].Third := 3.3;
  Doc.ArrArrStr[0, 0] := '[0,0]';
  Doc.ArrArrStr[0, 1] := '[0,1]';
  Doc.ArrArrStr[1, 0] := '[1,0]';
  Doc.ArrArrStr[1, 1] := '[1,1]';
  Doc.Rec3.TestEnum := _Gamma;
  Doc.Rec3.ArrInRec[0] := 'alpha α';
  Doc.Rec3.ArrInRec[1] := 'beta ϐ';
  Doc.Rec3.ArrInRec[2] := 'gamma ɣ';
  SetLength(Doc.Rec3.DArrInRec, 3);
  Doc.Rec3.DArrInRec[0] := 7;
  Doc.Rec3.DArrInRec[1] := 9;
  Doc.Rec3.DArrInRec[2] := 11;
  SetLength(Doc.DArrRec3, 2);
  Doc.DArrRec3[0].TestEnum := _Gamma;
  Doc.DArrRec3[0].ArrInRec[0] := 'α';
  Doc.DArrRec3[0].ArrInRec[1] := 'ϐ';
  Doc.DArrRec3[0].ArrInRec[2] := 'ɣ';
  SetLength(Doc.DArrRec3[0].DArrInRec, 0);
  Doc.DArrRec3[1].TestEnum := _Gamma;
  Doc.DArrRec3[1].ArrInRec[0] := 'Δ';
  Doc.DArrRec3[1].ArrInRec[1] := 'ε';
  Doc.DArrRec3[1].ArrInRec[2] := 'ɸ';
  SetLength(Doc.DArrRec3[1].DArrInRec, 1);
  Doc.DArrRec3[1].DArrInRec[0] := 13;
  Doc.fLoc := TLocationCoord2D.Create(1.001, 2.002);
  fConfig.Database.InsertOrUpdateDocumentSynchronous(Doc.SaveObjectToDocument(Options));
  Status('Document saved ' + Doc.DocumentName(false));
  try
    i := 0;
    for DocI in fConfig.Database.GetSynchronous(DocPath) do
    begin
      Doc2 := TMyFSDoc.LoadObjectFromDocument(DocI, Options);
      Status('Document loaded ' + Doc2.DocumentName(false));
      Assert.AreEqual(Doc.DocTitle, Doc2.DocTitle, 'Wrong DocTitle');
      Assert.AreEqual(Doc.Msg, Doc2.Msg, 'Wrong Msg');
      Assert.AreEqual(Doc.Flag, Doc2.Flag, 'Wrong Flag');
      Assert.AreEqual(Doc.Ch, Doc2.Ch, 'Wrong Ch');
      Assert.AreEqual(DateTimeToStr(Doc.CreationDateTime), DateTimeToStr(Doc2.CreationDateTime), 'Wrong CreationDateTime');
      Assert.AreEqual(Doc.TestInt, Doc2.TestInt, 'Wrong TestInt');
      Assert.AreEqual(Doc.LargeNumber, Doc2.LargeNumber, 'Wrong LargeNumber');
      Assert.AreEqual(Doc.B, Doc2.B, 'Wrong B');
      Assert.AreEqual(Doc.FloatSmall, Doc2.FloatSmall, 'Wrong FloatSmall');
      Assert.AreEqual(Doc.FloatMedium, Doc2.FloatMedium, 'Wrong FloatMedium');
      Assert.AreEqual(Doc.FloatLarge, Doc2.FloatLarge, 'Wrong FloatLarge');
      Assert.AreEqual(Doc.MyEnum, Doc2.MyEnum, 'Wrong MyEnum');
      Assert.AreEqual(Doc.MySet, Doc2.MySet, 'Wrong MySet');
      Assert.AreEqual(Doc.MySet2, Doc2.MySet2, 'Wrong MySet2');
      Assert.AreEqual(Doc.CArrDouble[0], Doc2.CArrDouble[0], 'Wrong CArrDouble[0]');
      Assert.AreEqual(Doc.CArrDouble[1], Doc2.CArrDouble[1], 'Wrong CArrDouble[1]');
      Assert.AreEqual(length(Doc.DArrInt), length(Doc2.DArrInt), 'Wrong DArrInt.length');
      for j := 0 to length(Doc.DArrInt) - 1 do
        Assert.AreEqual(Doc.DArrInt[j], Doc2.DArrInt[j], 'Wrong DArrInt[' + j.ToString + ']');
      Assert.AreEqual(length(Doc.DArrStr), length(Doc2.DArrStr), 'Wrong DArrStr.length');
      for j := 0 to length(Doc.DArrStr) - 1 do
        Assert.AreEqual(Doc.DArrStr[j], Doc2.DArrStr[j], 'Wrong DArrStr[' + j.ToString + ']');
      Assert.AreEqual(length(Doc.DArrTime), length(Doc2.DArrTime), 'Wrong DArrTime.length');
      for j := 0 to length(Doc.DArrTime) - 1 do
        Assert.AreEqual(DateTimeToStr(Doc.DArrTime[j]), DateTimeToStr(Doc2.DArrTime[j]), 'Wrong DArrTime[' + j.ToString + ']');
      Assert.AreEqual(Doc.Rec.First, Doc2.Rec.First, 'Wrong Rec.First');
      Assert.AreEqual(Doc.Rec.Second, Doc2.Rec.Second, 'Wrong Rec.Second');
      Assert.AreEqual(Doc.Rec.Third, Doc2.Rec.Third, 'Wrong Rec.Third');
      for j := 0 to length(Doc.ArrRec) - 1 do
      begin
        Assert.AreEqual(Doc.ArrRec[j].StateOk, Doc2.ArrRec[j].StateOk, 'Wrong Doc.ArrRec[' + j.ToString + '].StateOk');
        Assert.AreEqual(Doc.ArrRec[j].ErrMsg, Doc2.ArrRec[j].ErrMsg, 'Wrong Doc.ArrRec[' + j.ToString + '].ErrMsg');
        Assert.AreEqual(Doc.ArrRec[j].ErrNo, Doc2.ArrRec[j].ErrNo, 'Wrong Doc.ArrRec[' + j.ToString + '].ErrNo');
        Assert.AreEqual(DateTimeToStr(Doc.ArrRec[j].ErrorTS), DateTimeToStr(Doc2.ArrRec[j].ErrorTS), 'Wrong Doc.ArrRec[' + j.ToString + '].ErrMsg');
      end;
      for j := 0 to length(Doc.DynArrRec) - 1 do
      begin
        Assert.AreEqual(Doc.DynArrRec[j].First, Doc2.DynArrRec[j].First, 'Wrong DynArrRec[' + j.ToString + '].First');
        Assert.AreEqual(Doc.DynArrRec[j].Second, Doc2.DynArrRec[j].Second, 'Wrong DynArrRec[' + j.ToString + '].Second');
        Assert.AreEqual(Doc.DynArrRec[j].Third, Doc2.DynArrRec[j].Third, 'Wrong DynArrRec[' + j.ToString + '].Third');
      end;
      for j := 0 to 1 do
        for k := 0 to 1 do
          Assert.AreEqual(Doc.ArrArrStr[j, k], Doc2.ArrArrStr[j, k], 'Wrong ArrArrStr[' + j.ToString + ',' + k.ToString + ']');
      Assert.AreEqual(Doc.Rec3.TestEnum, Doc2.Rec3.TestEnum, 'Wrong Rec3.TestEnum');
      Assert.AreEqual(Doc.Rec3.ArrInRec[0], Doc2.Rec3.ArrInRec[0], 'Wrong Rec3.ArrInRec[0]');
      Assert.AreEqual(Doc.Rec3.ArrInRec[1], Doc2.Rec3.ArrInRec[1], 'Wrong Rec3.ArrInRec[1]');
      Assert.AreEqual(Doc.Rec3.ArrInRec[2], Doc2.Rec3.ArrInRec[2], 'Wrong Rec3.ArrInRec[2]');
      Assert.AreEqual(Doc.Rec3.DArrInRec[0], Doc2.Rec3.DArrInRec[0], 'Wrong Rec3.DArrInRec[0]');
      Assert.AreEqual(Doc.Rec3.DArrInRec[1], Doc2.Rec3.DArrInRec[1], 'Wrong Rec3.DArrInRec[1]');
      Assert.AreEqual(Doc.Rec3.DArrInRec[2], Doc2.Rec3.DArrInRec[2], 'Wrong Rec3.DArrInRec[2]');
      Assert.AreEqual(Doc.DArrRec3[0].TestEnum, Doc2.DArrRec3[0].TestEnum, 'Wrong DArrRec3[0].TestEnum');
      Assert.AreEqual(Doc.DArrRec3[0].ArrInRec[0], Doc2.DArrRec3[0].ArrInRec[0], 'Wrong DArrRec3[0].ArrInRec[0]');
      Assert.AreEqual(Doc.DArrRec3[0].ArrInRec[1], Doc2.DArrRec3[0].ArrInRec[1], 'Wrong DArrRec3[0].ArrInRec[1]');
      Assert.AreEqual(Doc.DArrRec3[0].ArrInRec[2], Doc2.DArrRec3[0].ArrInRec[2], 'Wrong DArrRec3[0].ArrInRec[2]');
      Assert.AreEqual(length(Doc.DArrRec3[0].DArrInRec), length(Doc2.DArrRec3[0].DArrInRec), 'Wrong length(DArrRec3[0].DArrInRec)');
      Assert.AreEqual(Doc.DArrRec3[1].TestEnum, Doc2.DArrRec3[1].TestEnum, 'Wrong Doc.DArrRec3[1].TestEnum');
      Assert.AreEqual(Doc.DArrRec3[1].ArrInRec[0], Doc2.DArrRec3[1].ArrInRec[0], 'Wrong DArrRec3[1].ArrInRec[0]');
      Assert.AreEqual(Doc.DArrRec3[1].ArrInRec[1], Doc2.DArrRec3[1].ArrInRec[1], 'Wrong DArrRec3[1].ArrInRec[1]');
      Assert.AreEqual(Doc.DArrRec3[1].ArrInRec[2], Doc2.DArrRec3[1].ArrInRec[2], 'Wrong DArrRec3[1].ArrInRec[2]');
      Assert.AreEqual(length(Doc.DArrRec3[1].DArrInRec), length(Doc2.DArrRec3[1].DArrInRec), 'Wrong length(DArrRec3[1].DArrInRec)');
      Assert.AreEqual(Doc.DArrRec3[1].DArrInRec[0], Doc2.DArrRec3[1].DArrInRec[0], 'Wrong DArrRec3[1].DArrInRec[0]');
      Status('Document check passed ' + Doc2.DocumentName(false));
      inc(i);
    end;
    Assert.AreEqual(i, 1, 'Wrong document count');
  finally
    fConfig.Database.DeleteSynchronous(DocPath);
    Status('Document deleted ' + Doc.DocumentName(false));
  end;
  FreeAndNil(Doc);
  FreeAndNil(Doc2);
end;

initialization
  TDUnitX.RegisterTestFixture(UT_FirestoreDB);
end.
