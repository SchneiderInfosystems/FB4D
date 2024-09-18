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

unit FBHelpers;

interface

uses
  System.Classes, System.SysUtils, System.JSON,
  DUnitX.TestFramework,
  FB4D.Helpers;

{$M+}
type
  [TestFixture]
  UT_FBHelpers = class(TObject)
  published
    procedure CreateAutoIDForFBID;
    procedure CreateAutoIDForFSID;
    procedure CreateAutoIDForPUSHID;
    procedure CreateAutoIDForFSPUSHID;
    procedure ConvertGUIDtoID64toGUID;
    procedure DecodeTimeFromPushID;
    procedure ConvertTimeStampAndRandomPatternToPushID;
    procedure ConvertTimeStampAndRandomPatternToBase64;
    procedure DecodeID64ToBytes;
    procedure EncodeBytesToID64;
    procedure CreateAutoIDandEncodeAndDecodeID64AndBytes;
  end;

implementation

{ UT_FBHelpers }

procedure UT_FBHelpers.CreateAutoIDForFBID;
var
  IDs: TStringList;
  ID: string;
  c: integer;
begin
  IDs := TStringList.Create;
  try
    for c := 1 to 1000 do
    begin
      ID := TFirebaseHelpers.CreateAutoID(FBID);
      Assert.AreEqual(22, length(ID), 'Unexpected length of FBID');
      Assert.AreEqual(-1, IDs.IndexOf(ID), 'Duplicate ID built: ' + ID);
      IDs.Add(ID);
    end;
    Assert.AreEqual(1000, IDs.Count, 'List.Count of IDs wrong');
  finally
    IDs.Free;
  end;
  Status('Test passed: 1000 unique FBID created');
end;

procedure UT_FBHelpers.CreateAutoIDForPUSHID;
var
  IDs: TStringList;
  ID: string;
  c: integer;
begin
  IDs := TStringList.Create;
  try
    for c := 1 to 1000 do
    begin
      ID := TFirebaseHelpers.CreateAutoID(PUSHID);
      Assert.AreEqual(20, length(ID), 'Unexpected length of PUSHID');
      Assert.AreEqual(-1, IDs.IndexOf(ID), 'Duplicate ID built: ' + ID);
      IDs.Add(ID);
    end;
    Assert.AreEqual(1000, IDs.Count, 'List.Count of IDs wrong');
  finally
    IDs.Free;
  end;
  Status('Test passed: 1000 unique PUSHID created');
end;

procedure UT_FBHelpers.CreateAutoIDForFSID;
var
  IDs: TStringList;
  ID: string;
  c: integer;
begin
  IDs := TStringList.Create;
  try
    for c := 1 to 1000 do
    begin
      ID := TFirebaseHelpers.CreateAutoID(FSID);
      Assert.AreEqual(20, length(ID), 'Unexpected length of PUSHID');
      Assert.AreEqual(-1, IDs.IndexOf(ID), 'Duplicate ID built: ' + ID);
      IDs.Add(ID);
    end;
    Assert.AreEqual(1000, IDs.Count, 'List.Count of IDs wrong');
  finally
    IDs.Free;
  end;
  Status('Test passed: 1000 unique FSID created');
end;

procedure UT_FBHelpers.CreateAutoIDForFSPUSHID;
var
  IDs: TStringList;
  ID: string;
  c: integer;
begin
  IDs := TStringList.Create;
  try
    for c := 1 to 1000 do
    begin
      ID := TFirebaseHelpers.CreateAutoID(FSPUSHID);
      Assert.AreEqual(24, length(ID), 'Unexpected length of FSPUSHID');
      Assert.AreEqual(-1, IDs.IndexOf(ID), 'Duplicate ID built: ' + ID);
      IDs.Add(ID);
    end;
    Assert.AreEqual(1000, IDs.Count, 'List.Count of IDs wrong');
  finally
    IDs.Free;
  end;
  Status('Test passed: 1000 unique FSPUSHID created');
end;

procedure UT_FBHelpers.ConvertGUIDtoID64toGUID;
var
  Guid: TGuid;
  ID64: string;
begin
  Guid := TGuid.Empty;
  ID64 := TFirebaseHelpers.ConvertGUIDtoID64(Guid);
  Assert.AreEqual(Guid, TFirebaseHelpers.ConvertID64toGUID(ID64));
  Status('Empty GUID->ID64: ' + ID64);

  Guid.D1 := $FEDCBA98;
  Guid.D2 := $7654;
  Guid.D3 := $3210;
  Guid.D4[0] := $AA;
  Guid.D4[1] := $55;
  Guid.D4[2] := $55;
  Guid.D4[3] := $AA;
  Guid.D4[4] := $00;
  Guid.D4[5] := $01;
  Guid.D4[6] := $FF;
  Guid.D4[7] := $FE;

  ID64 := TFirebaseHelpers.ConvertGUIDtoID64(Guid);
  Assert.AreEqual(Guid, TFirebaseHelpers.ConvertID64toGUID(ID64));
  Status('Artifical GUID->ID64: ' + ID64 + ' GUID: ' + GUIDToString(Guid));

  for var c := 0 to 99 do
  begin
    Guid := TGuid.NewGuid;
    ID64 := TFirebaseHelpers.ConvertGUIDtoID64(Guid);
    Assert.AreEqual(Guid, TFirebaseHelpers.ConvertID64toGUID(ID64));
  end;
end;

procedure UT_FBHelpers.DecodeTimeFromPushID;
const
  IDfromIssue107 = '-MdS-Zc5Ed383SNy4jH3';
var
  ID: string;
  d, d2: TDateTime;
  diff: double;
begin
 d := now;
 ID := TFirebaseHelpers.CreateAutoID(PUSHID);
 d2 := TFirebaseHelpers.DecodeTimeStampFromPUSHID(ID);
 diff := d2 - d;
 Assert.IsTrue(abs(Diff) < 1 / 24 / 3600 / 500, 'Timestamp difference > 2 ms: '
   + FloatToStr(Diff * 24 * 3600 * 1000) + ' ms');
 Status('PushID: ' + ID + ' was generated at ' + DateTimeToStr(d2));

 ID := IDfromIssue107;
 d2 := TFirebaseHelpers.DecodeTimeStampFromPUSHID(ID, false);
 d := EncodeDate(2021, 6, 30) + EncodeTime(13, 01, 08, 0);
 // UTC Date taken from Issue #107
 diff := d2 - d;
 Assert.IsTrue(abs(Diff) < 1 / 24 / 3600, 'Timestamp difference > 1 s: '
   + FloatToStr(Diff * 24 * 3600 * 1000) + ' ms');
 Status('PushID: ' + ID + ' was generated at UTC: ' + DateTimeToStr(d2));
end;

procedure UT_FBHelpers.ConvertTimeStampAndRandomPatternToPushID;
const
  LCID_USA = 1033;
  DateStart = '1/1/1970 00:00:00';
  DateUnixEnd = '1/19/2038 03:14:07';
  DateEnd = '12/31/2999 23:59:59'; // Hope this program can then be replaced ;)
var
  ID: string;
  r: TBytes;
  c: integer;
  dIn, dOut: TDateTime;
begin
  SetLength(r, 12);
  for c := low(r) to High(r) do
    r[c] := 0;
  dIn := StrToDateTime(DateStart, TFormatSettings.Create(LCID_USA));
  ID := TFirebaseHelpers.ConvertTimeStampAndRandomPatternToPUSHID(dIn, r, true);
  Status('First Push ID: ' + ID + ' (' + DateStart + ')');
  dOut := TFirebaseHelpers.DecodeTimeStampFromPUSHID(ID, false);
  Assert.AreEqual(dIn, dOut, 'First Push ID failed');
  dIn := StrToDateTime(DateUnixEnd, TFormatSettings.Create(LCID_USA));
  ID := TFirebaseHelpers.ConvertTimeStampAndRandomPatternToPUSHID(dIn, r, true);
  Status('EndOfUnixDate Push ID: ' + ID + ' (' + DateUnixEnd + ')');
  dOut := TFirebaseHelpers.DecodeTimeStampFromPUSHID(ID, false);
  Assert.AreEqual(dIn, dOut, 'EndOfUnixDate Push ID failed');
  dIn := StrToDateTime(DateEnd, TFormatSettings.Create(LCID_USA));
  ID := TFirebaseHelpers.ConvertTimeStampAndRandomPatternToPUSHID(dIn, r, true);
  Status('Last Push ID: ' + ID + ' (' + DateEnd + ')');
  dOut := TFirebaseHelpers.DecodeTimeStampFromPUSHID(ID, false);
  Assert.AreEqual(dIn, dOut, 'Last Push ID failed');
  dOut := TFirebaseHelpers.DecodeTimeStampFromPUSHID('-zzzzzzzzzzzzzzzzzzz',
    false);
  Status('Last ID starting with "-" character ' + DateTimeToStr(dOut));
end;

procedure UT_FBHelpers.ConvertTimeStampAndRandomPatternToBase64;
var
  ID, ID2: string;
  timeStamp, timeStamp2: TDateTime;
  c: integer;
  r: TBytes;
begin
  ID := TFirebaseHelpers.CreateAutoID(FSPUSHID);
  Status('ID: ' + ID);
  Assert.AreEqual(ID.Length, 24, 'Length of ID not 24 as expected');
  timeStamp := TFirebaseHelpers.DecodeTimeStampFromBase64(ID);
  Status('TimeStamp: ' + DateTimeToStr(timeStamp));
  SetLength(r, 16);
  for c := low(r) to High(r) do
    r[c] := 0;
  ID2 := TFirebaseHelpers.ConvertTimeStampAndRandomPatternToID64(timestamp, r, false);
  Assert.AreEqual(ID2.Length, 24, 'Length of ID2 not 24 as expected');
  Status('ID2: ' + ID2);
  timeStamp2 := TFirebaseHelpers.DecodeTimeStampFromBase64(ID2);
  Assert.AreEqual(timeStamp, timeStamp2, 'Timestamp different');
end;

procedure UT_FBHelpers.DecodeID64ToBytes;
const
  TestID = 'AZIAXSK1_UTUQj-44lk-AA-F';
var
  TestBytes: TBytes;
begin
  TestBytes := TFirebaseHelpers.DecodeID64ToBytes(TestID);
  Assert.IsTrue(18 = length(TestBytes), 'TestBytes length wrong');
  Assert.AreEqual(Byte(1), TestBytes[0], 'Byte 0 wrong');
  Assert.AreEqual(Byte(146), TestBytes[1], 'Byte 1 wrong');
  Assert.AreEqual(Byte(0), TestBytes[2], 'Byte 2 wrong');
  Assert.AreEqual(Byte(93), TestBytes[3], 'Byte 3 wrong');
  Assert.AreEqual(Byte(34), TestBytes[4], 'Byte 4 wrong');
  Assert.AreEqual(Byte(181), TestBytes[5], 'Byte 5 wrong');
  Assert.AreEqual(Byte(249), TestBytes[6], 'Byte 6 wrong');
  Assert.AreEqual(Byte(68), TestBytes[7], 'Byte 7 wrong');
  Assert.AreEqual(Byte(212), TestBytes[8], 'Byte 8 wrong');
  Assert.AreEqual(Byte(66), TestBytes[9], 'Byte 9 wrong');
  Assert.AreEqual(Byte(63), TestBytes[10], 'Byte 10 wrong');
  Assert.AreEqual(Byte(248), TestBytes[11], 'Byte 11 wrong');
  Assert.AreEqual(Byte(226), TestBytes[12], 'Byte 12 wrong');
  Assert.AreEqual(Byte(89), TestBytes[13], 'Byte 13 wrong');
  Assert.AreEqual(Byte(63), TestBytes[14], 'Byte 14 wrong');
  Assert.AreEqual(Byte(0), TestBytes[15], 'Byte 15 wrong');
  Assert.AreEqual(Byte(15), TestBytes[16], 'Byte 16 wrong');
  Assert.AreEqual(Byte(197), TestBytes[17], 'Byte 17 wrong');
  Status('Test EncodeBytesToID64 for ' + TestID + ' passed');
end;

procedure UT_FBHelpers.EncodeBytesToID64;
const
  TestID = 'AZIAXSK1_UTUQj-44lk-AA-F';
var
  TestBytes: TBytes;
  ID64: string;
begin
  SetLength(TestBytes, 18);
  TestBytes[0] := 1;
  TestBytes[1] := 146;
  TestBytes[2] := 0;
  TestBytes[3] := 93;
  TestBytes[4] := 34;
  TestBytes[5] := 181;
  TestBytes[6] := 249;
  TestBytes[7] := 68;
  TestBytes[8] := 212;
  TestBytes[9] := 66;
  TestBytes[10] := 63;
  TestBytes[11] := 248;
  TestBytes[12] := 226;
  TestBytes[13] := 89;
  TestBytes[14] := 63;
  TestBytes[15] := 0;
  TestBytes[16] := 15;
  TestBytes[17] := 197;
  ID64 := TFirebaseHelpers.EncodeBytesToID64(TestBytes);
  Assert.AreEqual(ID64, TestID, 'Wrong result of EncodeBytesToID64');
  Status('Test EncodeBytesToID64 for ' + TestID + '  passed');
end;

procedure UT_FBHelpers.CreateAutoIDandEncodeAndDecodeID64AndBytes;
var
  ID64, IDCompare: string;
  TestBytes: TBytes;
begin
  ID64 := TFirebaseHelpers.CreateAutoID(FBID);
  Assert.AreEqual(22, length(ID64), 'Length of CreateAutoID(FBID)');
  TestBytes := TFirebaseHelpers.DecodeID64ToBytes(ID64);
  IDCompare := TFirebaseHelpers.EncodeBytesToID64(TestBytes);
  Assert.AreEqual(ID64, IDCompare, 'Wrong EncodeBytesToID64(DecodeID64ToBytes(ID))=ID');
  Status('CreateAutoID(FBID)="' + ID64 + '" and DecodeID64ToBytes(EncodeBytesToID64(ID))=ID test passed');

  ID64 := TFirebaseHelpers.CreateAutoID(FSID);
  Assert.AreEqual(20, length(ID64), 'Length of CreateAutoID(FSID)');
  TestBytes := TFirebaseHelpers.DecodeID64ToBytes(ID64);
  IDCompare := TFirebaseHelpers.EncodeBytesToID64(TestBytes);
  Assert.AreEqual(ID64, IDCompare, 'Wrong EncodeBytesToID64(DecodeID64ToBytes(ID))=ID');
  Status('CreateAutoID(FSID)="' + ID64 + '" and DecodeID64ToBytes(EncodeBytesToID64(ID))=ID test passed');

  ID64 := TFirebaseHelpers.CreateAutoID(FSPUSHID);
  Assert.AreEqual(24, length(ID64), 'Length of CreateAutoID(FSID)');
  TestBytes := TFirebaseHelpers.DecodeID64ToBytes(ID64);
  IDCompare := TFirebaseHelpers.EncodeBytesToID64(TestBytes);
  Assert.AreEqual(ID64, IDCompare, 'Wrong EncodeBytesToID64(DecodeID64ToBytes(ID))=ID');
  Status('CreateAutoID(FSPUSHID)="' + ID64 + '" and DecodeID64ToBytes(EncodeBytesToID64(ID))=ID test passed');
end;

initialization
  TDUnitX.RegisterTestFixture(UT_FBHelpers);
end.
