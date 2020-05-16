{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2020 Christoph Schneider                                 }
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
    fInfo: string;
    fCallBack: boolean;
    fDoc: IFirestoreDocument;
    procedure OnError(const RequestID, ErrMsg: string);
    procedure OnDoc(const Info: string; Document: IFirestoreDocument);
    procedure OnDocs(const Info: string; Documents: IFirestoreDocuments);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
  published
    [TestCase]
    procedure CreateUpdateGetDocumentSynchronous;
    procedure CreateUpdateGetDocument;
  end;

implementation

uses
  VCL.Forms,
  FB4D.Configuration, FB4D.Helpers;

{$I FBConfig.inc}

const
  cEMail = 'Integration.Tester@FB4D.org';
  cPassword = 'It54623!';
  cDBPath = 'TestNode';

{ UT_FirestoreDB }

procedure UT_FirestoreDB.Setup;
begin
  fConfig := TFirebaseConfiguration.Create(cApiKey, cProjectID, cBucket);
  fConfig.Auth.SignUpWithEmailAndPasswordSynchronous(cEmail, cPassword);
  fErrMsg := '';
  fReqID := '';
  fInfo := '';
  fCallBack := false;
  fDoc := nil;
end;

procedure UT_FirestoreDB.TearDown;
begin
  if assigned(fDoc) then
    fConfig.Database.DeleteSynchronous([cDBPath, fDoc.DocumentName(false)]);
  fConfig.Auth.DeleteCurrentUserSynchronous;
  fConfig := nil;
end;

procedure UT_FirestoreDB.OnDoc(const Info: string;
  Document: IFirestoreDocument);
begin
  fDoc := Document;
  fInfo := Info;
  fCallBack := true;
end;

procedure UT_FirestoreDB.OnDocs(const Info: string;
  Documents: IFirestoreDocuments);
begin
  if not assigned(Documents) or (Documents.Count <> 1) then
    fErrMsg := 'Get documents not 1 as expected'
  else
    fDoc := Documents.Document(0);
  fInfo := Info;
  fCallBack := true;
end;

procedure UT_FirestoreDB.OnError(const RequestID, ErrMsg: string);
begin
  fReqID := RequestID;
  fErrMsg := ErrMsg;
  fCallBack := true;
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
  while not fCallBack do
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
  fCallBack := false;
  fConfig.Database.InsertOrUpdateDocument([cDBPath, DocName], Doc, nil, OnDoc, OnError);
  while not fCallBack do
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

  fCallBack := false;
  fConfig.Database.Get([cDBPath, DocName], nil, OnDocs, OnError);
  while not fCallBack do
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


initialization
  TDUnitX.RegisterTestFixture(UT_FirestoreDB);
end.
