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
  private
  published
    procedure ConvertGUIDtoFBIDtoGUID;
    procedure DecodeTimeFromPushID;
    procedure ConvertTimeStampAndRandomPatternToPushID;
  end;

implementation

{ UT_FBHelpers }

procedure UT_FBHelpers.ConvertGUIDtoFBIDtoGUID;
var
  Guid: TGuid;
  FBID: string;
  c: integer;
begin
  Guid := TGuid.Empty;
  FBID := TFirebaseHelpers.ConvertGUIDtoFBID(Guid);
  Assert.AreEqual(Guid, TFirebaseHelpers.ConvertFBIDtoGUID(FBID));
  Status('Empty GUID->FBID: ' + FBID);

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

  FBID := TFirebaseHelpers.ConvertGUIDtoFBID(Guid);
  Assert.AreEqual(Guid, TFirebaseHelpers.ConvertFBIDtoGUID(FBID));
  Status('Artifical GUID->FBID: ' + FBID + ' GUID: ' + GUIDToString(Guid));

  for c := 0 to 99 do
  begin
    Guid := TGuid.NewGuid;
    FBID := TFirebaseHelpers.ConvertGUIDtoFBID(Guid);
    Assert.AreEqual(Guid, TFirebaseHelpers.ConvertFBIDtoGUID(FBID));
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

initialization
  TDUnitX.RegisterTestFixture(UT_FBHelpers);
end.
