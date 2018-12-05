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

unit FB4D.Document;

interface

uses
  System.Classes, System.JSON, System.SysUtils,
  FB4D.Interfaces, FB4D.Response, FB4D.Request;

{$WARN DUPLICATE_CTOR_DTOR OFF}

type
  TFirestoreDocument = class(TInterfacedObject, IFirestoreDocument)
  private
    fJSONObj: TJSONObject;
    fJSONObjOwned: boolean;
    fCreated, fUpdated: TDateTime;
    fDocumentName: string;
    fFields: array of record
      Name: string;
      Obj: TJSONValue; // TJSONObject;
    end;
  public
    constructor Create(const Name: string);
    constructor CreateFromJSONObj(Response: IFirebaseResponse); overload;
    constructor CreateFromJSONObj(JSONObj: TJSONObject); overload;
    destructor Destroy; override;
    function DocumentName(FullPath: boolean): string;
    function CreateTime: TDateTime;
    function UpdateTime: TDatetime;
    function CountFields: integer;
    function Fields(Ind: integer): TJSONValue;
    function FieldName(Ind: integer): string;
    function FieldByName(const FieldName: string): TJSONValue;
    function GetStringValue(const FieldName: string): string;
    function GetStringValueDef(const FieldName, Default: string): string;
    function GetIntegerValue(const FieldName: string): integer;
    function GetIntegerValueDef(const FieldName: string;
      Default: integer): integer;
    function GetDoubleValue(const FieldName: string): double;
    function GetDoubleValueDef(const FieldName: string;
      Default: double): double;
    function GetTimeStampValue(const FieldName: string): TDateTime;
    function GetTimeStampValueDef(const FieldName: string;
      Default: TDateTime): TDateTime;
    function GetArrayValues(const FieldName: string): TJSONObjects;
    procedure AddOrUpdateField(const FieldName: string; Val: TJSONValue);
    function AsJSON: TJSONObject;
  end;

  TFirestoreDocuments = class(TInterfacedObject, IFirestoreDocuments)
  private
    fJSONArr: TJSONArray;
    fJSONObj: TJSONObject;
    fDocumentList: array of IFirestoreDocument;
    fServerTimeStampUTC: TDatetime;
  public
    constructor CreateFromJSONDocumentsObj(Response: IFirebaseResponse);
    class function IsJSONDocumentsObj(Response: IFirebaseResponse): boolean;
    constructor CreateFromJSONArr(Response: IFirebaseResponse);
    destructor Destroy; override;
    function Count: integer;
    function Document(Ind: integer): IFirestoreDocument;
    function ServerTimeStamp(TimeZone: TTimeZone): TDateTime;
  end;

implementation

uses
  System.Generics.Collections,
  FB4D.Helpers;

{ TFirestoreDocuments }
constructor TFirestoreDocuments.CreateFromJSONArr(Response: IFirebaseResponse);
var
  Obj: TJSONObject;
  c: integer;
begin
  inherited Create;
  fJSONArr := Response.GetContentAsJSONArr;
  SetLength(fDocumentList, 0);
  if fJSONArr.Count < 1 then
    raise EFirestoreDocument.Create('Invalid document - node count not 1');
  for c := 0 to fJSONArr.Count - 1 do
  begin
    Obj := fJSONArr.Items[c] as TJSONObject;
    if (fJSONArr.Count = 1) and (Obj.Pairs[0].JsonString.Value = 'readTime') then
      // Empty [{'#$A'  "readTime": "2018-06-21T08:08:50.445723Z"'#$A'}'#$A']
      SetLength(fDocumentList, 0)
    else if Obj.Pairs[0].JsonString.Value <> 'document' then
      raise EFirestoreDocument.Create('Invalid document node: ' +
        Obj.Pairs[0].JsonString.ToString)
    else if not(Obj.Pairs[0].JsonValue is TJSONObject) then
      raise EFirestoreDocument.Create('Invalid document - not an object: ' +
        Obj.ToString)
    else begin
      SetLength(fDocumentList, length(fDocumentList) + 1);
      fDocumentList[length(fDocumentList) - 1] :=
        TFirestoreDocument.CreateFromJSONObj(
          Obj.Pairs[0].JsonValue as TJSONObject);
    end;
  end;
  fServerTimeStampUTC := Response.GetServerTime(tzUTC);
end;

constructor TFirestoreDocuments.CreateFromJSONDocumentsObj(
  Response: IFirebaseResponse);
var
  c: integer;
begin
  fJSONObj := Response.GetContentAsJSONObj;
  if fJSONObj.Count < 1 then
    SetLength(fDocumentList, 0)
  else if fJSONObj.Pairs[0].JsonString.ToString = '"documents"' then
  begin
    if not(fJSONObj.Pairs[0].JsonValue is TJSONArray) then
      raise EFirestoreDocument.Create('Invalid document - not an array: ' +
        fJSONObj.ToString);
    fJSONArr := fJSONObj.Pairs[0].JsonValue as TJSONArray;
    SetLength(fDocumentList, fJSONArr.Count);
    for c := 0 to fJSONArr.Count - 1 do
      fDocumentList[c] := TFirestoreDocument.CreateFromJSONObj(
        fJSONArr.Items[c] as TJSONObject);
  end else begin
    SetLength(fDocumentList, 1);
    fDocumentList[0] := TFirestoreDocument.CreateFromJSONObj(fJSONObj);
  end;
  fServerTimeStampUTC := Response.GetServerTime(tzUTC);
end;

class function TFirestoreDocuments.IsJSONDocumentsObj(
  Response: IFirebaseResponse): boolean;
var
  JSONObj: TJSONObject;
begin
  JSONObj := Response.GetContentAsJSONObj;
  result := (JSONObj.Count = 1) and
    (JSONObj.Pairs[0].JsonString.ToString = '"documents"');
end;

destructor TFirestoreDocuments.Destroy;
begin
  if assigned(fJSONArr) then
    fJSONArr.Free
  else if assigned(fJSONObj) then
    fJSONObj.Free;
  SetLength(fDocumentList, 0);
  inherited;
end;

function TFirestoreDocuments.Count: integer;
begin
  result := length(fDocumentList);
end;

function TFirestoreDocuments.Document(Ind: integer): IFirestoreDocument;
begin
  if Ind < Count then
    result := fDocumentList[Ind]
  else
    raise EFirestoreDocument.Create('Index out of bound for document list');
end;

function TFirestoreDocuments.ServerTimeStamp(TimeZone: TTimeZone): TDateTime;
const
  cInitialDate: double = 0;
begin
  case TimeZone of
    tzUTC:
      result := fServerTimeStampUTC;
    tzLocalTime:
      result := TFirebaseHelpers.ConvertToLocalDateTime(fServerTimeStampUTC);
    else
      result := TDateTime(cInitialDate);
  end;
end;

{ TFirestoreDocument }

constructor TFirestoreDocument.Create(const Name: string);
begin
  inherited Create;
  fJSONObjOwned := true;
  fJSONObj := TJSONObject.Create;
  fJSONObj.AddPair('name', Name);
  SetLength(fFields, 0);
end;

constructor TFirestoreDocument.CreateFromJSONObj(JSONObj: TJSONObject);
var
  obj: TJSONObject;
  c: integer;
begin
  inherited Create;
  fJSONObjOwned := false;
  fJSONObj := JSONObj;
  if fJSONObj.Count < 3 then
    raise EFirestoreDocument.Create('Invalid document - node count less 3');
  if not fJSONObj.TryGetValue('name', fDocumentName) then
    raise EStorageObject.Create('JSON field name missing');
  if not fJSONObj.TryGetValue('createTime', fCreated) then
    raise EStorageObject.Create('JSON field createTime missing')
  else
    fCreated := TFirebaseHelpers.ConvertToLocalDateTime(fCreated);
  if not fJSONObj.TryGetValue('updateTime', fUpdated) then
    raise EStorageObject.Create('JSON field updateTime missing')
  else
    fUpdated := TFirebaseHelpers.ConvertToLocalDateTime(fUpdated);
  if fJSONObj.TryGetValue('fields', obj) then
  begin
    SetLength(fFields, obj.Count);
    for c := 0 to CountFields - 1 do
    begin
      fFields[c].Name := obj.Pairs[c].JsonString.Value;
      if not(obj.Pairs[c].JsonValue is TJSONObject) then
        raise EStorageObject.CreateFmt(
          'Field %d is not a JSON object as expected', [c]);
      fFields[c].Obj := obj.Pairs[c].JsonValue as TJSONObject;
    end;
  end else
    SetLength(fFields, 0);
end;

constructor TFirestoreDocument.CreateFromJSONObj(Response: IFirebaseResponse);
begin
  CreateFromJSONObj(Response.GetContentAsJSONObj);
end;

destructor TFirestoreDocument.Destroy;
begin
  SetLength(fFields, 0);
  if fJSONObjOwned then
    fJSONObj.Free;
  inherited;
end;

procedure TFirestoreDocument.AddOrUpdateField(const FieldName: string;
  Val: TJSONValue);

  function FieldIndByName(const FieldName: string): integer;
  var
    c: integer;
  begin
    result := -1;
    for c := 0 to CountFields - 1 do
      if SameText(fFields[c].Name, FieldName) then
        exit(c);
  end;

var
  FieldsObj: TJSONObject;
  Ind: integer;
begin
  if not fJSONObj.TryGetValue('fields', FieldsObj) then
  begin
    FieldsObj := TJSONObject.Create;
    fJSONObj.AddPair('fields', FieldsObj);
  end;
  Ind := FieldIndByName(FieldName);
  if Ind < 0 then
  begin
    Ind := CountFields;
    SetLength(fFields, Ind + 1);
    fFields[Ind].Name := FieldName;
  end else
    FieldsObj.RemovePair(FieldName);
  FieldsObj.AddPair(FieldName, Val);
  fFields[Ind].Obj := Val.Clone as TJSONValue;
end;

function TFirestoreDocument.AsJSON: TJSONObject;
begin
  result := fJSONObj;
end;

function TFirestoreDocument.CountFields: integer;
begin
  result := length(fFields);
end;

function TFirestoreDocument.DocumentName(FullPath: boolean): string;
begin
  result := fDocumentName;
  if not FullPath then
    result := result.SubString(result.LastDelimiter('/') + 1);
end;

function TFirestoreDocument.FieldName(Ind: integer): string;
begin
  if Ind >= CountFields then
    raise EFirestoreDocument.Create('Index out of bound for field list');
  result := fFields[Ind].Name;
end;

function TFirestoreDocument.Fields(Ind: integer): TJSONValue;
begin
  if Ind >= CountFields then
    raise EFirestoreDocument.Create('Index out of bound for field list');
  result := fFields[Ind].Obj;
end;

function TFirestoreDocument.FieldByName(const FieldName: string): TJSONValue;
var
  c: integer;
begin
  result := nil;
  for c := 0 to CountFields - 1 do
    if SameText(fFields[c].Name, FieldName) then
      exit(fFields[c].Obj);
end;

function TFirestoreDocument.GetStringValue(const FieldName: string): string;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<string>('stringValue')
  else
    raise EFirestoreDocument.Create('Field ' + FieldName + ' not found');
end;

function TFirestoreDocument.GetStringValueDef(const FieldName,
  Default: string): string;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<string>('stringValue')
  else
    result := Default;
end;

function TFirestoreDocument.GetIntegerValue(const FieldName: string): integer;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<integer>('integerValue')
  else
    raise EFirestoreDocument.Create('Field ' + FieldName + ' not found');
end;

function TFirestoreDocument.GetIntegerValueDef(const FieldName: string;
  Default: integer): integer;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<integer>('integerValue')
  else
    result := Default;
end;

function TFirestoreDocument.GetDoubleValue(const FieldName: string): double;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<double>('doubleValue')
  else
    raise EFirestoreDocument.Create('Field ' + FieldName + ' not found');
end;

function TFirestoreDocument.GetDoubleValueDef(const FieldName: string;
  Default: double): double;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<double>('doubleValue')
  else
    result := Default;
end;

function TFirestoreDocument.GetTimeStampValue(
  const FieldName: string): TDateTime;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<TDateTime>('timestampValue')
  else
    raise EFirestoreDocument.Create('Field ' + FieldName + ' not found');
end;

function TFirestoreDocument.GetTimeStampValueDef(const FieldName: string;
  Default: TDateTime): TDateTime;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<TDateTime>('timestampValue')
  else
    result := Default;
end;

function TFirestoreDocument.GetArrayValues(
  const FieldName: string): TJSONObjects;
var
  Val: TJSONValue;
  Obj: TJSONObject;
  Arr: TJSONArray;
  c: integer;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    exit(nil);
  Obj := Val.GetValue<TJSONObject>('arrayValue');
  if not assigned(Obj) then
    exit(nil);
  Arr := Obj.GetValue('values') as TJSONArray;
  if not assigned(Arr) then
    exit(nil);
  SetLength(result, Arr.Count);
  for c := 0 to Arr.Count - 1 do
    result[c] := Arr.Items[c].GetValue<TJSONObject>('mapValue.fields');
end;

function TFirestoreDocument.CreateTime: TDateTime;
begin
  result := fCreated;
end;

function TFirestoreDocument.UpdateTime: TDatetime;
begin
  result := fUpdated;
end;

end.
