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
    fStopped: boolean;
    fDoc, fDoc2: IFirestoreDocument;
    fChangedDocName: string;
    fChangedDocC: integer;
    fChangedDocF1: string;
    fChangedDocF2: integer;
    fDeletedDoc: string;
    procedure OnError(const RequestID, ErrMsg: string);
    procedure OnDoc(const Info: string; Document: IFirestoreDocument);
    procedure OnDoc2(const Info: string; Document: IFirestoreDocument);
    procedure OnDocs(const Info: string; Documents: IFirestoreDocuments);
    procedure OnDocChanged(ChangedDocument: IFirestoreDocument);
    procedure OnDocDeleted(const DeleteDocumentPath: string;
      TimeStamp: TDateTime);
    procedure OnDocDel(const RequestID: string; Response: IFirebaseResponse);
    procedure OnStop(Sender: TObject);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    [TestCase]
    procedure CreateUpdateGetDocumentSynchronous;
    procedure CreateUpdateGetDocument;
    procedure ConcurrentUpdateDocuments;
    procedure FirestoreListenerForSingleDocument;
  end;

implementation

uses
  VCL.Forms,
  FB4D.Configuration, FB4D.Helpers, FB4D.Document;

{$I FBConfig.inc}

const
  cEMail = 'Integration.Tester@FB4D.org';
  cPassword = 'It54623!';
  cDBPath = 'TestNode';
  cTestF1 = 'TestField1';
  cTestF2 = 'testField2';

{ UT_FirestoreDB }

procedure UT_FirestoreDB.Setup;
begin
  fConfig := TFirebaseConfiguration.Create(cApiKey, cProjectID, cBucket);
  fConfig.Auth.SignUpWithEmailAndPasswordSynchronous(cEmail, cPassword);
  fErrMsg := '';
  fReqID := '';
  fInfo := '';
  fCallBack := 0;
  fDoc := nil;
  fDoc2 := nil;
  fChangedDocName := '';
  fChangedDocC := -1;
  fChangedDocF1 := '';
  fChangedDocF2 := -1;
  fDeletedDoc := '';
  fStopped := false;
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
  fChangedDocName := ChangedDocument.DocumentName(false);
  fChangedDocC := ChangedDocument.CountFields;
  fChangedDocF1 := ChangedDocument.GetStringValue(cTestF1);
  fChangedDocF2 := ChangedDocument.GetIntegerValueDef(cTestF2, -1);
  inc(fCallBack);
end;

procedure UT_FirestoreDB.OnDocDel(const RequestID: string;
  Response: IFirebaseResponse);
begin
  fInfo2 := RequestID;
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

procedure UT_FirestoreDB.OnStop(Sender: TObject);
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

  Doc := fConfig.Database.InsertOrUpdateDocumentSynchronous([cDBPath, DocName], fDoc);
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
  Status('Document check 2 passed');
end;

procedure UT_FirestoreDB.CreateUpdateGetDocument;
var
  DocName: string;
  Doc: IFirestoreDocument;
begin
  fConfig.Database.CreateDocument([cDBPath], nil, OnDoc, OnError);
  while fCallBack < 1 do
    Application.ProcessMessages;
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
  fConfig.Database.InsertOrUpdateDocument([cDBPath, DocName], Doc, nil, OnDoc, OnError);
  while fCallBack < 1 do
    Application.ProcessMessages;
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
    Application.ProcessMessages;
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
  Doc1 := TFirestoreDocument.Create(Doc1Name);
  Doc1.AddOrUpdateField(TJSONObject.SetString('TestField', 'Alpha 😀'));

  Doc2 := TFirestoreDocument.Create(Doc2Name);
  Doc2.AddOrUpdateField(TJSONObject.SetString('TestField2', 'Beta 👨'));

  fConfig.Database.InsertOrUpdateDocument([cDBPath, Doc1Name], Doc1, nil, OnDoc, OnError);
  fConfig.Database.InsertOrUpdateDocument([cDBPath, Doc2Name], Doc2, nil, OnDoc2, OnError);
  while fCallBack < 2 do
    Application.ProcessMessages;
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
  DocID := TFirebaseHelpers.CreateAutoID;
  fConfig.Database.SubscribeDocument([cDBPath, DocID], OnDocChanged, OnDocDeleted);
  fConfig.Database.StartListener(OnStop, OnError);

  Doc := TFirestoreDocument.Create(DocID);
  Doc.AddOrUpdateField(TJSONObject.SetString(cTestF1, cTestString));
  Doc.AddOrUpdateField(TJSONObject.SetInteger(cTestF2, cTestInt));
  fConfig.Database.InsertOrUpdateDocument([cDBPath, DocID], Doc, nil, OnDoc, OnError);

  while fCallBack < 2 do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDoc.DocumentName(false), DocID);
  Status('InsertOrUpdateDocument passed: ' + fInfo);

  Assert.AreEqual(fChangedDocName, DocID);
  Assert.AreEqual(fChangedDocF1, cTestString);
  Assert.AreEqual(fChangedDocF2, cTestInt);
  Assert.AreEqual(fChangedDocC, 2);
  Status('OnDocChanged check passed');

  fCallBack := 0;
  Doc := TFirestoreDocument.Create(DocID);
  Doc.AddOrUpdateField(TJSONObject.SetString(cTestF1, cTestString2));
  fConfig.Database.InsertOrUpdateDocument([cDBPath, DocID], Doc, nil, OnDoc, OnError);

  while fCallBack < 2 do
    Application.ProcessMessages;

  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDoc.DocumentName(false), DocID);
  Status('2nd InsertOrUpdateDocument passed: ' + fInfo);

  Assert.AreEqual(fChangedDocName, DocID);
  Assert.AreEqual(fChangedDocF1, cTestString2);
  Assert.AreEqual(fChangedDocF2, -1);
  Assert.AreEqual(fChangedDocC, 1);
  Status('2nd OnDocChanged check passed');

  fCallBack := 0;
  fDeletedDoc := ''; // it is unclear why the FS reports a first that this document was deleted
  fConfig.Database.Delete([cDBPath, DocID], nil, OnDocDel, onError);

  while fCallBack < 2 do
    Application.ProcessMessages;
  Assert.IsEmpty(fErrMsg, 'Error: ' + fErrMsg);
  Assert.AreEqual(fDeletedDoc, fDoc.DocumentName(true));
  Status('3rd: Document deletion check passed');
  fDoc := nil;

  fConfig.Database.StopListener;
  while not fStopped do
    Application.ProcessMessages;
  Status('Listener stopped properly');
end;



initialization
  TDUnitX.RegisterTestFixture(UT_FirestoreDB);
end.
