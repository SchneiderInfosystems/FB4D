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

unit FB4D.Document;

interface

uses
  System.Types, System.Classes, System.JSON, System.SysUtils, System.StrUtils,
  System.Rtti, System.TypInfo,
{$IFNDEF LINUX64}
  System.Sensors,
{$ENDIF}
  FB4D.Interfaces, FB4D.Response, FB4D.Request, FB4D.Helpers;

{$WARN DUPLICATE_CTOR_DTOR OFF}

type
  TFirestoreDocument = class(TInterfacedObject, IFirestoreDocument)
  private
    fJSONObj: TJSONObject;
    fCreated, fUpdated: TDateTime;
    fDocumentName: string;
    fFields: array of record
      Name: string;
      Obj: TJSONObject;
    end;
    function FieldIndByName(const FieldName: string): integer;
    function ConvertRefPath(const Reference: string): string;
    function ArrayToFSArr(R: TRTTIType; V: TValue;
      const FName: string): TFirestoreArr;
    function DynArrToFSArr(R: TRTTIType; V: TValue;
      const FName: string): TFirestoreArr;
    function EnumToI64(V: TValue; const FName: string): Int64;
    function FloatToObj(R: TRTTIType; V: TValue): TJSONObject;
    function MapToFSMap(DAT: TRttiRecordType; V: TValue): TFirestoreMap;
    function SetToStr(V: TValue): string;
    procedure LoadObjectFromDoc;
    function AnsiCharToVal(TypeInfo: PTypeInfo; const s: string): TValue;
    function AnsiStringToVal(TypeInfo: PTypeInfo; const s: string): TValue;
    function ArrayToVal(F: TRTTIField; Arr: TJSONObjects): TValue;
    function CharToVal(TypeInfo: PTypeInfo; const s: string): TValue;
    function DynArrayToVal(F: TRTTIField; Arr: TJSONObjects): TValue;
    function EnumToVal(TypeInfo: PTypeInfo; I: Int64): TValue;
    function FloatToVal(RType: TRTTIType; Obj: TJSONObject): TValue;
    function RecordToVal(DAT: TRttiRecordType; const FName: string;
      Map: TJSONObject): TValue;
    function SetToVal(TypeInfo: PTypeInfo; const s: string): TValue;
    function WideStringToVal(TypeInfo: PTypeInfo; const s: string): TValue;
  public
    class function CreateCursor(const ProjectID: string): IFirestoreDocument;
    class function GetDocFullPath(
      const ProjectID: string;
      const Database: string = cDefaultDatabaseID;
      DocumentPath: TRequestResourceParam = []): TRequestResourceParam; overload;
    class function GetDocFullPath(DocumentPath: TRequestResourceParam;
      const ProjectID: string;
      const Database: string = cDefaultDatabaseID): string; overload;
    constructor Create(DocumentPath: TRequestResourceParam;
      const ProjectID: string; const Database: string = cDefaultDatabaseID);
      overload;
    constructor Create(DocumentPath: TRequestResourceParam;
      Firestore: IFirestoreDatabase); overload;
    constructor CreateFromJSONObj(Response: IFirebaseResponse); overload;
    constructor CreateFromJSONObj(JSONObj: TJSONObject); overload;
    destructor Destroy; override;
    function DocumentName(FullPath: boolean): string;
    function DocumentFullPath: TRequestResourceParam;
    function DocumentPathWithinDatabase: TRequestResourceParam;
    function CreateTime(TimeZone: TTimeZone = tzUTC): TDateTime;
    function UpdateTime(TimeZone: TTimeZone = tzUTC): TDatetime;
    function CountFields: integer;
    function FieldName(Ind: integer): string;
    function FieldByName(const FieldName: string): TJSONObject;
    function FieldValue(Ind: integer): TJSONObject;
    function FieldType(Ind: integer): TFirestoreFieldType;
    function FieldTypeByName(const FieldName: string): TFirestoreFieldType;
    function AllFields: TStringDynArray;
    function GetValue(Ind: integer): TJSONValue; overload;
    function GetValue(const FieldName: string): TJSONValue; overload;
    function GetStringValue(const FieldName: string): string;
    function GetStringValueDef(const FieldName, Default: string): string;
    function GetIntegerValue(const FieldName: string): integer;
    function GetIntegerValueDef(const FieldName: string;
      Default: integer): integer;
    function GetInt64Value(const FieldName: string): Int64;
    function GetInt64ValueDef(const FieldName: string;
      Default: Int64): Int64;
    function GetDoubleValue(const FieldName: string): double;
    function GetDoubleValueDef(const FieldName: string;
      Default: double): double;
    function GetTimeStampValue(const FieldName: string;
      TimeZone: TTimeZone = tzUTC): TDateTime;
    function GetTimeStampValueDef(const FieldName: string;
      Default: TDateTime; TimeZone: TTimeZone = tzUTC): TDateTime;
    function GetBoolValue(const FieldName: string): boolean;
    function GetBoolValueDef(const FieldName: string;
      Default: boolean): boolean;
    function GetGeoPoint(const FieldName: string): TLocationCoord2D;
    function GetReference(const FieldName: string): string;
    function GetReferenceDef(const FieldName, Default: string): string;
    function GetBytes(const FieldName: string): TBytes;
    function GetArraySize(const FieldName: string): integer;
    function GetArrayType(const FieldName: string;
      Index: integer): TFirestoreFieldType;
    function GetArrayItem(const FieldName: string; Index: integer): TJSONPair;
    function GetArrayValue(const FieldName: string; Index: integer): TJSONValue;
    function GetArrayValues(const FieldName: string): TJSONObjects;
    function GetArrayMapValues(const FieldName: string): TJSONObjects;
    function GetArrayStringValues(const FieldName: string): TStringDynArray;
    function GetMapSize(const FieldName: string): integer;
    function GetMapType(const FieldName: string;
      Index: integer): TFirestoreFieldType;
    function GetMapSubFieldName(const FieldName: string; Index: integer): string;
    function GetMapValue(const FieldName: string; Index: integer): TJSONObject;
      overload;
    function GetMapValue(const FieldName, SubFieldName: string): TJSONObject;
      overload;
    function GetMapValues(const FieldName: string): TJSONObjects;
    procedure AddOrUpdate(Field: TJSONPair); overload;
    procedure AddOrUpdate(const FieldName: string; Val: TJSONValue); overload;
    function AddOrUpdateField(Field: TJSONPair): IFirestoreDocument; overload;
    function AddOrUpdateField(const FieldName: string;
      Val: TJSONValue): IFirestoreDocument;
      overload;
    function AsJSON: TJSONObject;
    function Clone: IFirestoreDocument;
    class function GetFieldType(const FieldType: string): TFirestoreFieldType;
    class function IsCompositeType(FieldType: TFirestoreFieldType): boolean;
    { Object to Document Mapper }
    constructor LoadObjectFromDocument(Doc: IFirestoreDocument);
    function SaveObjectToDocument: IFirestoreDocument;
  end;

  TFirestoreDocuments = class(TInterfacedObject, IFirestoreDocuments,
    IEnumerable<IFirestoreDocument>, IEnumerable)
  private
    fDocumentList: array of IFirestoreDocument;
    fServerTimeStampUTC: TDatetime;
    fPageToken: string;
    fSkippedResults: integer;
  protected
    function GetGenericEnumerator: IEnumerator<IFirestoreDocument>;
    function GetEnumerator: IEnumerator;
    function IFirestoreDocuments.GetEnumerator = GetGenericEnumerator;
    function IEnumerable<IFirestoreDocument>.GetEnumerator =
      GetGenericEnumerator;
  public
    constructor CreateFromJSONDocumentsObj(Response: IFirebaseResponse);
    class function IsJSONDocumentsObj(Response: IFirebaseResponse): boolean;
    constructor CreateFromJSONArr(Response: IFirebaseResponse);
    destructor Destroy; override;
    procedure AddFromJSONDocumentsObj(Response: IFirebaseResponse);
    function Count: integer;
    function Document(Ind: integer): IFirestoreDocument;
    function ServerTimeStamp(TimeZone: TTimeZone): TDateTime;
    function SkippedResults: integer;
    function MorePagesToLoad: boolean;
    function PageToken: string;
    procedure AddPageTokenToNextQuery(Query: TQueryParams);
  end;

  TFirestoreDocsEnumerator = class(TInterfacedObject,
    IEnumerator<IFirestoreDocument>, IEnumerator)
  private
    fDocs: TFirestoreDocuments;
    fCursor: integer;
  protected
  protected
    function GetCurrent: TObject;
    function GenericGetCurrent: IFirestoreDocument;
    function IEnumerator<IFirestoreDocument>.GetCurrent = GenericGetCurrent;
  public
    constructor Create(Docs: TFirestoreDocuments);
    function MoveNext: Boolean;
    procedure Reset;
  end;

implementation

uses
  System.Generics.Collections, System.NetEncoding;

resourcestring
  rsInvalidDocNotOneNode = 'Invalid document - not one node only';
  rsInvalidDocNode = 'Invalid document node: %s';
  rsNotObj = 'not an object: ';
  rsInvalidDocArr = 'Invalid document - not an array: %s';
  rsInvalidDocumentPath =
    'Invalid document path "%s", expected "projects/*/database/*/documents"';
  rsDocIndexOutOfBound = 'Index out of bound for document list';
  rsInvalidDocNodeCountLess3 = 'Invalid document - node count less 3';
  rsJSONFieldNameMissing = 'JSON field name missing';
  rsJSONFieldCreateTimeMissing = 'JSON field createTime missing';
  rsJSONFieldUpdateTimeMissing = 'JSON field updateTime missing';
  rsFieldIsNotJSONObj = 'Field %d is not a JSON object as expected';
  rsFieldIndexOutOfBound = 'Index out of bound for field list';
  rsFieldNotContainJSONObj = 'Field does not contain a JSONObject';
  rsFieldNotContainTypeValPair = 'Field does not contain type-value pair';
  rsFieldNoFound = 'Field %s not found';
  rsArrFieldNotJSONObj = 'Arrayfield[%d] does not contain a JSONObject';
  rsArrFieldNotTypeValue = 'Arrayfield[%d] does not contain type-value pair';
  rsArrFieldNoMap = 'Arrayfield[%d] does not contain a map';
  rsArrIndexOutOfBound = 'Array index out of bound for array field';
  rsMapIndexOutOfBound = 'Map index out of bound for array field';
  rsInvalidMapField = 'Field %s is not a map field';

{ TFirestoreDocuments }

constructor TFirestoreDocuments.CreateFromJSONArr(Response: IFirebaseResponse);
var
  JSONArr: TJSONArray;
  Obj: TJSONObject;
  c: integer;
begin
  inherited Create;
  fSkippedResults := 0;
  fPageToken := '';
  JSONArr := Response.GetContentAsJSONArr;
  try
    SetLength(fDocumentList, 0);
    if JSONArr.Count < 1 then
      raise EFirestoreDocument.Create(rsInvalidDocNotOneNode);
    for c := 0 to JSONArr.Count - 1 do
    begin
      Obj := JSONArr.Items[c] as TJSONObject;
      if (JSONArr.Count >= 1) and
         (Obj.Pairs[0].JsonString.Value = 'readTime') then
      begin
        // Empty [{'#$A'  "readTime": "2018-06-21T08:08:50.445723Z"'#$A'}'#$A']
        SetLength(fDocumentList, 0);
        if (JSONArr.Count >= 2) and
           (Obj.Pairs[1].JsonString.Value = 'skippedResults') then
          fSkippedResults := (Obj.Pairs[1].JsonValue as TJSONNumber).AsInt;
      end
      else if Obj.Pairs[0].JsonString.Value <> 'document' then
        raise EFirestoreDocument.CreateFmt(rsInvalidDocNode,
          [Obj.Pairs[0].JsonString.ToString])
      else if not(Obj.Pairs[0].JsonValue is TJSONObject) then
        raise EFirestoreDocument.CreateFmt(rsInvalidDocNode,
          [rsNotObj + Obj.ToString])
      else begin
        SetLength(fDocumentList, length(fDocumentList) + 1);
        fDocumentList[length(fDocumentList) - 1] :=
          TFirestoreDocument.CreateFromJSONObj(
            Obj.Pairs[0].JsonValue as TJSONObject);
      end;
    end;
  finally
    JSONArr.Free;
  end;
  fServerTimeStampUTC := Response.GetServerTime(tzUTC);
end;

constructor TFirestoreDocuments.CreateFromJSONDocumentsObj(
  Response: IFirebaseResponse);
var
  c: integer;
  JSONObj: TJSONObject;
  JSONArr: TJSONArray;
begin
  fSkippedResults := 0;
  JSONObj := Response.GetContentAsJSONObj;
  try
    if JSONObj.Count < 1 then
      SetLength(fDocumentList, 0)
    else if JSONObj.Pairs[0].JsonString.Value = 'documents' then
    begin
      if not(JSONObj.Pairs[0].JsonValue is TJSONArray) then
        raise EFirestoreDocument.CreateFmt(rsInvalidDocArr, [JSONObj.ToString]);
      JSONArr := JSONObj.Pairs[0].JsonValue as TJSONArray;
      SetLength(fDocumentList, JSONArr.Count);
      for c := 0 to JSONArr.Count - 1 do
        fDocumentList[c] := TFirestoreDocument.CreateFromJSONObj(
          JSONArr.Items[c] as TJSONObject);
    end else begin
      SetLength(fDocumentList, 1);
      fDocumentList[0] := TFirestoreDocument.CreateFromJSONObj(JSONObj);
    end;
    fServerTimeStampUTC := Response.GetServerTime(tzUTC);
    if not JSONObj.TryGetValue<string>('nextPageToken', fPageToken) then
      fPageToken := '';
  finally
    JSONObj.Free;
  end;
end;

procedure TFirestoreDocuments.AddFromJSONDocumentsObj(
  Response: IFirebaseResponse);
var
  c, l: integer;
  JSONObj: TJSONObject;
  JSONArr: TJSONArray;
begin
  fSkippedResults := 0;
  JSONObj := Response.GetContentAsJSONObj;
  try
    if JSONObj.Count >= 1 then
    begin
      l := length(fDocumentList);
      if JSONObj.Pairs[0].JsonString.Value = 'documents' then
      begin
        if not(JSONObj.Pairs[0].JsonValue is TJSONArray) then
          raise EFirestoreDocument.CreateFmt(rsInvalidDocArr,
            [JSONObj.ToString]);
        JSONArr := JSONObj.Pairs[0].JsonValue as TJSONArray;
        SetLength(fDocumentList, l + JSONArr.Count);
        for c := 0 to JSONArr.Count - 1 do
          fDocumentList[l + c] := TFirestoreDocument.CreateFromJSONObj(
            JSONArr.Items[c] as TJSONObject);
      end else begin
        SetLength(fDocumentList, l + 1);
        fDocumentList[l] := TFirestoreDocument.CreateFromJSONObj(JSONObj);
      end;
    end;
    fServerTimeStampUTC := Response.GetServerTime(tzUTC);
    if not JSONObj.TryGetValue<string>('nextPageToken', fPageToken) then
      fPageToken := '';
  finally
    JSONObj.Free;
  end;
end;

class function TFirestoreDocuments.IsJSONDocumentsObj(
  Response: IFirebaseResponse): boolean;
var
  JSONObj: TJSONObject;
begin
  JSONObj := Response.GetContentAsJSONObj;
  try
    result := (JSONObj.Count = 1) and
      (JSONObj.Pairs[0].JsonString.ToString = '"documents"');
  finally
    JSONObj.Free;
  end;
end;

destructor TFirestoreDocuments.Destroy;
begin
  SetLength(fDocumentList, 0);
  inherited;
end;

function TFirestoreDocuments.Count: integer;
begin
  result := length(fDocumentList);
end;

function TFirestoreDocuments.Document(Ind: integer): IFirestoreDocument;
begin
  if (Ind >= 0) and (Ind < Count) then
    result := fDocumentList[Ind]
  else
    raise EFirestoreDocument.Create(rsDocIndexOutOfBound);
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

function TFirestoreDocuments.SkippedResults: integer;
begin
  result := fSkippedResults;
end;

function TFirestoreDocuments.MorePagesToLoad: boolean;
begin
  result := not fPageToken.IsEmpty;
end;

function TFirestoreDocuments.PageToken: string;
begin
  result := fPageToken;
end;

procedure TFirestoreDocuments.AddPageTokenToNextQuery(Query: TQueryParams);
begin
  if MorePagesToLoad then
    Query.AddPageToken(fPageToken);
end;

function TFirestoreDocuments.GetEnumerator: IEnumerator;
begin
  result := GetGenericEnumerator;
end;

function TFirestoreDocuments.GetGenericEnumerator: IEnumerator<IFirestoreDocument>;
begin
  result := TFirestoreDocsEnumerator.Create(self);
end;

{ TFirestoreDocument }

class function TFirestoreDocument.GetDocFullPath(
  DocumentPath: TRequestResourceParam; const ProjectID,
  Database: string): string;
begin
  result := Format(cFirestoreDocumentPath,
    [ProjectID, Database, TFirebaseHelpers.EncodeResourceParams(DocumentPath)]);
end;

class function TFirestoreDocument.GetDocFullPath(const ProjectID,
  Database: string; DocumentPath: TRequestResourceParam): TRequestResourceParam;
var
  c, c0: integer;
begin
  result := ['projects', ProjectID, 'databases', Database, 'documents'];
  if length(DocumentPath) > 0 then
  begin
    c0 := length(result);
    SetLength(result, c0 + length(DocumentPath));
    for c := 0 to length(DocumentPath) - 1 do
      result[c0 + c] := DocumentPath[c];
  end;
end;

constructor TFirestoreDocument.Create(DocumentPath: TRequestResourceParam;
  const ProjectID, Database: string);
begin
  inherited Create;
  fDocumentName := GetDocFullPath(DocumentPath, ProjectID, Database);
  fJSONObj := TJSONObject.Create;
  fJSONObj.AddPair('name', fDocumentName);
  SetLength(fFields, 0);
end;

constructor TFirestoreDocument.Create(DocumentPath: TRequestResourceParam;
  Firestore: IFirestoreDatabase);
begin
  Create(DocumentPath, Firestore.ProjectID, Firestore.DatabaseID);
end;

class function TFirestoreDocument.CreateCursor(
  const ProjectID: string): IFirestoreDocument;
begin
  result := TFirestoreDocument.Create(['CursorDoc'], ProjectID);
end;

constructor TFirestoreDocument.CreateFromJSONObj(JSONObj: TJSONObject);
var
  obj: TJSONObject;
  c: integer;
begin
  inherited Create;
  fJSONObj := JSONObj.Clone as TJSONObject;
  if fJSONObj.Count < 3 then
    raise EFirestoreDocument.Create(rsInvalidDocNodeCountLess3);
  if not fJSONObj.TryGetValue('name', fDocumentName) then
    raise EStorageObject.Create(rsJSONFieldNameMissing);
  if not fJSONObj.TryGetValue('createTime', fCreated) then
    raise EStorageObject.Create(rsJSONFieldCreateTimeMissing);
  if not fJSONObj.TryGetValue('updateTime', fUpdated) then
    raise EStorageObject.Create(rsJSONFieldUpdateTimeMissing);
  if fJSONObj.TryGetValue('fields', obj) then
  begin
    SetLength(fFields, obj.Count);
    for c := 0 to CountFields - 1 do
    begin
      fFields[c].Name := obj.Pairs[c].JsonString.Value;
      if not(obj.Pairs[c].JsonValue is TJSONObject) then
        raise EStorageObject.CreateFmt(rsFieldIsNotJSONObj, [c]);
      fFields[c].Obj := obj.Pairs[c].JsonValue.Clone as TJSONObject;
    end;
  end else
    SetLength(fFields, 0);
end;

constructor TFirestoreDocument.CreateFromJSONObj(Response: IFirebaseResponse);
var
  JSONObj: TJSONObject;
begin
  JSONObj := Response.GetContentAsJSONObj;
  try
    CreateFromJSONObj(JSONObj);
  finally
    JSONObj.Free;
  end;
end;

destructor TFirestoreDocument.Destroy;
var
  c: integer;
begin
  for c := 0 to length(fFields) - 1 do
    FreeAndNil(fFields[c].Obj);
  SetLength(fFields, 0);
  fJSONObj.Free;
  inherited;
end;

function TFirestoreDocument.FieldIndByName(const FieldName: string): integer;
var
  c: integer;
begin
  result := -1;
  for c := 0 to CountFields - 1 do
    if SameText(fFields[c].Name, FieldName) then
      exit(c);
end;

procedure TFirestoreDocument.AddOrUpdate(const FieldName: string;
  Val: TJSONValue);
var
  FieldsObj: TJSONObject;
  Ind: integer;
begin
  Assert(Assigned(fJSONObj), 'Missing JSON object in AddOrUpdateField');
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
    FieldsObj.RemovePair(FieldName).free;
  FieldsObj.AddPair(FieldName, Val);
  fFields[Ind].Obj := Val.Clone as TJSONObject;
end;

function TFirestoreDocument.AddOrUpdateField(const FieldName: string;
  Val: TJSONValue): IFirestoreDocument;
begin
  AddOrUpdate(FieldName, Val);
  result := self;
end;

procedure TFirestoreDocument.AddOrUpdate(Field: TJSONPair);
var
  FieldName: string;
  FieldsObj: TJSONObject;
  Ind: integer;
begin
  FieldName := Field.JsonString.Value;
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
    FieldsObj.RemovePair(FieldName).free;
  FieldsObj.AddPair(Field);
  fFields[Ind].Obj := Field.JsonValue.Clone as TJSONObject;
end;

function TFirestoreDocument.AddOrUpdateField(
  Field: TJSONPair): IFirestoreDocument;
begin
  AddOrUpdate(Field);
  result := self;
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

function TFirestoreDocument.DocumentFullPath: TRequestResourceParam;
begin
  result := fDocumentName.Split(['/']);
end;

function TFirestoreDocument.DocumentPathWithinDatabase: TRequestResourceParam;
var
  RemovedProjAndDB: string;
  c, p: integer;
begin
  p := 0;
  for c := 1 to 5 do
  begin
    p := pos('/', fDocumentName, p + 1);
    if p = 0 then
      raise EFirestoreDocument.CreateFmt(rsInvalidDocumentPath, [fDocumentName]);
  end;
  RemovedProjAndDB := copy(fDocumentName, p + 1);
  result := RemovedProjAndDB.Split(['/']);
end;

function TFirestoreDocument.FieldName(Ind: integer): string;
begin
  if (Ind < 0 ) or (Ind >= CountFields) then
    raise EFirestoreDocument.Create(rsFieldIndexOutOfBound);
  result := fFields[Ind].Name;
end;

function TFirestoreDocument.FieldType(Ind: integer): TFirestoreFieldType;
var
  Obj: TJSONObject;
begin
  if (Ind < 0 ) or (Ind >= CountFields) then
    raise EFirestoreDocument.Create(rsFieldIndexOutOfBound);
  if not(fFields[Ind].Obj is TJSONObject) then
    raise EFirestoreDocument.Create(rsFieldNotContainJSONObj);
  Obj := fFields[Ind].Obj as TJSONObject;
  if Obj.Count <> 1 then
    raise EFirestoreDocument.Create(rsFieldNotContainTypeValPair);
  result := GetFieldType(Obj.Pairs[0].JsonString.Value);
end;

function TFirestoreDocument.FieldValue(Ind: integer): TJSONObject;
begin
  if (Ind < 0 ) or (Ind >= CountFields) then
    raise EFirestoreDocument.Create(rsFieldIndexOutOfBound);
  result := fFields[Ind].Obj;
end;

function TFirestoreDocument.FieldTypeByName(
  const FieldName: string): TFirestoreFieldType;
var
  c: integer;
begin
  for c := 0 to CountFields - 1 do
    if SameText(fFields[c].Name, FieldName) then
      exit(FieldType(c));
  raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.AllFields: TStringDynArray;
var
  c: integer;
begin
  SetLength(result, CountFields);
  for c := 0 to CountFields - 1 do
    result[c] := fFields[c].Name;
end;

class function TFirestoreDocument.GetFieldType(
  const FieldType: string): TFirestoreFieldType;
begin
  if SameText(FieldType, 'nullValue') then
    result := fftNull
  else if SameText(FieldType, 'booleanValue') then
    result := fftBoolean
  else if SameText(FieldType, 'integerValue') then
    result := fftInteger
  else if SameText(FieldType, 'doubleValue') then
    result := fftDouble
  else if SameText(FieldType, 'timestampValue') then
    result := fftTimeStamp
  else if SameText(FieldType, 'stringValue') then
    result := fftString
  else if SameText(FieldType, 'bytesValue') then
    result := fftBytes
  else if SameText(FieldType, 'referenceValue') then
    result := fftReference
  else if SameText(FieldType, 'geoPointValue') then
    result := fftGeoPoint
  else if SameText(FieldType, 'arrayValue') then
    result := fftArray
  else if SameText(FieldType, 'mapValue') then
    result := fftMap
  else
    raise EFirestoreDocument.CreateFmt('Unknown field type %s', [FieldType]);
end;

function TFirestoreDocument.FieldByName(const FieldName: string): TJSONObject;
var
  c: integer;
begin
  result := nil;
  for c := 0 to CountFields - 1 do
    if SameText(fFields[c].Name, FieldName) then
      exit(fFields[c].Obj);
end;

function TFirestoreDocument.GetValue(Ind: integer): TJSONValue;
var
  Obj: TJSONObject;
begin
  if Ind >= CountFields then
    raise EFirestoreDocument.Create(rsFieldIndexOutOfBound);
  if not(fFields[Ind].Obj is TJSONObject) then
    raise EFirestoreDocument.Create(rsFieldNotContainJSONObj);
  Obj := fFields[Ind].Obj as TJSONObject;
  if Obj.Count <> 1 then
    raise EFirestoreDocument.Create(rsFieldNotContainTypeValPair);
  result := Obj.Pairs[0].JsonValue;
end;

function TFirestoreDocument.GetValue(const FieldName: string): TJSONValue;
var
  c: integer;
begin
  for c := 0 to CountFields - 1 do
    if SameText(fFields[c].Name, FieldName) then
      exit(GetValue(c));
  raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetStringValue(const FieldName: string): string;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<string>('stringValue')
  else
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetStringValueDef(const FieldName,
  Default: string): string;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    result := Default
  else if not Val.TryGetValue<string>('stringValue', result) then
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
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetIntegerValueDef(const FieldName: string;
  Default: integer): integer;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    result := Default
  else if not Val.TryGetValue<integer>('integerValue', result) then
    result := Default;
end;

function TFirestoreDocument.GetInt64Value(const FieldName: string): Int64;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<Int64>('integerValue')
  else
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetInt64ValueDef(const FieldName: string;
  Default: Int64): Int64;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    result := Default
  else if not Val.TryGetValue<Int64>('integerValue', result) then
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
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetDoubleValueDef(const FieldName: string;
  Default: double): double;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    result := Default
  else if not Val.TryGetValue<double>('doubleValue', result) then
    result := Default;
end;

function TFirestoreDocument.GetTimeStampValue(const FieldName: string;
  TimeZone: TTimeZone): TDateTime;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
  begin
    result := Val.GetValue<TDateTime>('timestampValue');
    if TimeZone = tzLocalTime then
      result := TFirebaseHelpers.ConvertToLocalDateTime(result);
  end else
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetTimeStampValueDef(const FieldName: string;
  Default: TDateTime; TimeZone: TTimeZone): TDateTime;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    result := Default
  else if Val.TryGetValue<TDateTime>('timestampValue', result) then
  begin
    if TimeZone = tzLocalTime then
      result := TFirebaseHelpers.ConvertToLocalDateTime(result);
  end else
    result := Default;
end;

function TFirestoreDocument.GetBoolValue(const FieldName: string): boolean;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := Val.GetValue<boolean>('booleanValue')
  else
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetBoolValueDef(const FieldName: string;
  Default: boolean): boolean;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    result := Default
  else if not Val.TryGetValue<boolean>('booleanValue', result) then
    result := Default;
end;

function TFirestoreDocument.GetGeoPoint(
  const FieldName: string): TLocationCoord2D;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName).GetValue<TJSONValue>('geoPointValue');
  if assigned(Val) then
    result := TLocationCoord2D.Create(Val.GetValue<double>('latitude'),
      Val.GetValue<double>('longitude'))
  else
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.ConvertRefPath(const Reference: string): string;
begin
  result := StringReplace(Reference, '\/', '/', [rfReplaceAll]);
end;

function TFirestoreDocument.GetReference(const FieldName: string): string;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := ConvertRefPath(Val.GetValue<string>('referenceValue'))
  else
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetReferenceDef(const FieldName,
  Default: string): string;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    result := Default
  else if Val.TryGetValue<string>('referenceValue', result) then
    result := ConvertRefPath(result)
  else
    result := Default;
end;

function TFirestoreDocument.GetBytes(const FieldName: string): TBytes;
var
  Val: TJSONValue;
begin
  Val := FieldByName(FieldName);
  if assigned(Val) then
    result := TNetEncoding.Base64.DecodeStringToBytes(
      Val.GetValue<string>('bytesValue'))
  else
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
end;

function TFirestoreDocument.GetArraySize(const FieldName: string): integer;
var
  Val: TJSONValue;
  Obj: TJSONObject;
  Arr: TJSONArray;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    exit(0);
  Obj := Val.GetValue<TJSONObject>('arrayValue');
  if not assigned(Obj) then
    exit(0);
  Arr := Obj.GetValue('values') as TJSONArray;
  if not assigned(Arr) then
    exit(0);
  result := Arr.Count;
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
  begin
    if not(Arr.Items[c] is TJSONObject) then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotJSONObj, [c]);
    Obj := Arr.Items[c] as TJSONObject;
    if Obj.Count <> 1 then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotTypeValue, [c]);
    result[c] := Obj;
  end;
end;

function TFirestoreDocument.GetArrayMapValues(
  const FieldName: string): TJSONObjects;
var
  Val: TJSONValue;
  Obj: TJSONObject;
  Arr: TJSONArray;
  c: integer;
  FieldType: string;
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
  begin
    if not(Arr.Items[c] is TJSONObject) then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotJSONObj, [c]);
    Obj := Arr.Items[c] as TJSONObject;
    if Obj.Count <> 1 then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotTypeValue, [c]);
    FieldType := Obj.Pairs[0].JsonString.Value;
    if SameText(FieldType, 'mapValue') then
      result[c] := Obj.GetValue<TJSONObject>('mapValue.fields')
    else
      raise EFirestoreDocument.CreateFmt(rsArrFieldNoMap, [c]);
  end;
end;

function TFirestoreDocument.GetArrayStringValues(
  const FieldName: string): TStringDynArray;
var
  Val: TJSONValue;
  Obj: TJSONObject;
  Arr: TJSONArray;
  c: integer;
  FieldType: string;
begin
  SetLength(result, 0);
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    exit;
  Obj := Val.GetValue<TJSONObject>('arrayValue');
  Arr := Obj.GetValue('values') as TJSONArray;
  if not assigned(Arr) then
    exit;
  SetLength(result, Arr.Count);
  for c := 0 to Arr.Count - 1 do
  begin
    if not(Arr.Items[c] is TJSONObject) then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotJSONObj, [c]);
    Obj := Arr.Items[c] as TJSONObject;
    if Obj.Count <> 1 then
      raise EFirestoreDocument.CreateFmt(rsArrFieldNotTypeValue, [c]);
    FieldType := Obj.Pairs[0].JsonString.Value;
    if SameText(FieldType, 'stringValue') then
      result[c] := Obj.GetValue<string>('stringValue')
    else
      raise EFirestoreDocument.CreateFmt(rsArrFieldNoMap, [c]);
  end;
end;

function TFirestoreDocument.GetArrayType(const FieldName: string;
  Index: integer): TFirestoreFieldType;
var
  Objs: TJSONObjects;
begin
  Objs := GetArrayValues(FieldName);
  if not assigned(Objs) then
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
  if Index >= length(Objs) then
    raise EFirestoreDocument.Create(rsArrIndexOutOfBound);
  result := GetFieldType(Objs[Index].Pairs[0].JsonString.Value);
end;

function TFirestoreDocument.GetArrayValue(const FieldName: string;
  Index: integer): TJSONValue;
var
  Objs: TJSONObjects;
begin
  Objs := GetArrayValues(FieldName);
  if not assigned(Objs) then
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
  if Index >= length(Objs) then
    raise EFirestoreDocument.Create(rsArrIndexOutOfBound);
  result := Objs[Index].Pairs[0].JsonValue;
end;

function TFirestoreDocument.GetArrayItem(const FieldName: string;
  Index: integer): TJSONPair;
var
  Objs: TJSONObjects;
begin
  Objs := GetArrayValues(FieldName);
  if not assigned(Objs) then
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
  if Index >= length(Objs) then
    raise EFirestoreDocument.Create(rsArrIndexOutOfBound);
  result := Objs[Index].Pairs[0];
end;

function TFirestoreDocument.GetMapSize(const FieldName: string): integer;
var
  Val: TJSONValue;
  Obj, Obj2: TJSONObject;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    exit(0);
  Obj := Val.GetValue<TJSONObject>('mapValue');
  if not assigned(Obj) then
    exit(0);
  Obj2 := Obj.GetValue('fields') as TJSONObject;
  if not assigned(Obj2) then
    exit(0);
  result := Obj2.Count;
end;

function TFirestoreDocument.GetMapType(const FieldName: string;
  Index: integer): TFirestoreFieldType;
var
  Objs: TJSONObjects;
begin
  Objs := GetMapValues(FieldName);
  if not assigned(Objs) then
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
  if (Index < 0) or (Index >= length(Objs)) then
    raise EFirestoreDocument.Create(rsMapIndexOutOfBound);
  result := GetFieldType(Objs[Index].Pairs[0].JsonString.Value);
end;

function TFirestoreDocument.GetMapSubFieldName(const FieldName: string;
  Index: integer): string;
var
  Val: TJSONValue;
  Obj, Obj2: TJSONObject;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
  Obj := Val.GetValue<TJSONObject>('mapValue');
  if not assigned(Obj) then
    raise EFirestoreDocument.CreateFmt(rsInvalidMapField, [FieldName]);
  Obj2 := Obj.GetValue('fields') as TJSONObject;
  if not assigned(Obj2) then
    raise EFirestoreDocument.CreateFmt(rsInvalidMapField, [FieldName]);
  if (Index < 0) or (Index >= Obj2.Count) then
    raise EFirestoreDocument.Create(rsMapIndexOutOfBound);
  result := Obj2.Pairs[Index].JsonString.Value;
end;

function TFirestoreDocument.GetMapValue(const FieldName: string;
  Index: integer): TJSONObject;
var
  Objs: TJSONObjects;
begin
  Objs := GetMapValues(FieldName);
  if not assigned(Objs) then
    raise EFirestoreDocument.CreateFmt(rsFieldNoFound, [FieldName]);
  if (Index < 0) or (Index >= length(Objs)) then
    raise EFirestoreDocument.Create(rsMapIndexOutOfBound);
  result := Objs[Index];
end;

function TFirestoreDocument.GetMapValue(const FieldName,
  SubFieldName: string): TJSONObject;
var
  Val: TJSONValue;
  Obj, Obj2: TJSONObject;
  c: integer;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    exit(nil);
  Obj := Val.GetValue<TJSONObject>('mapValue');
  if not assigned(Obj) then
    exit(nil);
  Obj2 := Obj.GetValue('fields') as TJSONObject;
  if not assigned(Obj2) then
    exit(nil);
  for c := 0 to Obj2.Count - 1 do
    if Obj2.Pairs[c].JsonString.Value = SubFieldName then
      exit(Obj2.Pairs[c].JsonValue as TJSONObject);
  result := nil;
end;

function TFirestoreDocument.GetMapValues(const FieldName: string): TJSONObjects;
var
  Val: TJSONValue;
  Obj, Obj2: TJSONObject;
  c: integer;
begin
  Val := FieldByName(FieldName);
  if not assigned(Val) then
    exit(nil);
  Obj := Val.GetValue<TJSONObject>('mapValue');
  if not assigned(Obj) then
    exit(nil);
  Obj2 := Obj.GetValue('fields') as TJSONObject;
  if not assigned(Obj2) then
    exit(nil);
  SetLength(result, Obj2.Count);
  for c := 0 to Obj2.Count - 1 do
    result[c] := Obj2.Pairs[c].JsonValue as TJSONObject;
end;

function TFirestoreDocument.CreateTime(TimeZone: TTimeZone): TDateTime;
begin
  result := fCreated;
  if TimeZone = tzLocalTime then
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

function TFirestoreDocument.UpdateTime(TimeZone: TTimeZone): TDatetime;
begin
  result := fUpdated;
  if TimeZone = tzLocalTime then
    result := TFirebaseHelpers.ConvertToLocalDateTime(result);
end;

function TFirestoreDocument.Clone: IFirestoreDocument;
begin
  result := TFirestoreDocument.CreateFromJSONObj(fJSONObj);
end;

class function TFirestoreDocument.IsCompositeType(
  FieldType: TFirestoreFieldType): boolean;
begin
  result := FieldType in [fftArray, fftMap];
end;

{$REGION 'Object to Document Mapper'}
function TFirestoreDocument.SetToStr(V: TValue): string;
var
  Buffer: set of Byte;
  TD: PTypeData;
  i: integer;
begin
  V.ExtractRawData(@Buffer);
  TD := V.TypeInfo.TypeData.CompType^.TypeData;
  result := '';
  for i := TD.MinValue to TD.MaxValue do
    if i in Buffer then
      result := result + i.ToString + ',';
  if result.EndsWith(',') then
    result := result.Remove(result.Length -1);
end;

function TFirestoreDocument.EnumToI64(V: TValue; const FName: string): Int64;
const
  sMethodName = 'TFirestoreDocument.EnumToI64';
begin
  if not V.TryAsOrdinal(result) then
    raise Exception.CreateFmt('%s: Field value not accessible in %s',
      [FName, sMethodName]);
end;

function TFirestoreDocument.FloatToObj(R: TRTTIType; V: TValue): TJSONObject;
begin
  if SameText(R.Name, 'TDateTime') then
    result := TJSONObject.SetTimeStampValue(V.AsExtended)
  else
    result := TJSONObject.SetDoubleValue(V.AsExtended);
end;

function TFirestoreDocument.MapToFSMap(DAT: TRttiRecordType;
  V: TValue): TFirestoreMap;
const
  sMethodName = 'TFirestoreDocument.MapToFSMap';
var
  Fields: TArray<TRttiField>;
  i: integer;
  VE: TValue;
  Buffer: TBytes;
begin
  Fields := DAT.GetDeclaredFields;
  SetLength(Result, length(Fields));
  SetLength(Buffer, V.DataSize);
  V.ExtractRawData(Buffer);
  for i := 0 to length(Fields) - 1 do
  begin
    VE := Fields[i].GetValue(Buffer);
    case Fields[i].FieldType.TypeKind of
      tkChar,
      tkWChar,
      tkString,
      tkLString,
      tkWString,
      tkUString:
        result[i] := TJSONPair.Create(Fields[i].Name,
          TJSONObject.SetStringValue(VE.AsString));
      tkInteger:
        result[i] := TJSONPair.Create(Fields[i].Name,
          TJSONObject.SetIntegerValue(VE.AsInteger));
      tkInt64:
        result[i] := TJSONPair.Create(Fields[i].Name,
          TJSONObject.SetInt64Value(VE.AsInt64));
      tkEnumeration:
        result[i] := TJSONPair.Create(Fields[i].Name,
          TJSONObject.SetInt64Value(EnumToI64(VE, Fields[i].Name)));
      tkFloat:
        result[i] := TJSONPair.Create(Fields[i].Name,
          FloatToObj(Fields[i].FieldType, VE));
      tkSet:
        result[i] := TJSONPair.Create(Fields[i].Name,
          TJSONObject.SetStringValue(SetToStr(VE)));
      tkArray:
        result[i] := TJSONPair.Create(Fields[i].Name,
          TJSONObject.SetArrayValue(ArrayToFSArr(Fields[i].FieldType, VE,
            Fields[i].Name)));
      tkDynArray:
        result[i] := TJSONPair.Create(Fields[i].Name,
          TJSONObject.SetArrayValue(DynArrToFSArr(Fields[i].FieldType, VE,
            Fields[i].Name)));
      tkRecord:
         result[i] := TJSONPair.Create(Fields[i].Name,
           TJSONObject.SetMapValue(MapToFSMap(
             Fields[i].FieldType as TRttiRecordType, VE)));
      else
        raise Exception.CreateFmt(
          '%s: record sub type %s not yet supported in %s',
          [Fields[i].Name,
           TRttiEnumerationType.GetName(Fields[i].FieldType.TypeKind),
           sMethodName]);
    end;
  end;
end;

function TFirestoreDocument.DynArrToFSArr(R: TRTTIType; V: TValue;
  const FName: string): TFirestoreArr;
const
  sMethodName = 'TFirestoreDocument.DynArrToFSArr';
var
  DAT: TRttiDynamicArrayType;
  i: integer;
  VE: TValue;
begin
  DAT := R as TRttiDynamicArrayType;
  Assert(assigned(DAT.ElementType), Format(
    '%s: Element type missing in %s.DynArrToFSArr', [FName, sMethodName]));
  SetLength(result, V.GetArrayLength);
  for i := 0 to V.GetArrayLength - 1 do
  begin
    VE := V.GetArrayElement(i);
    case DAT.ElementType.TypeKind of
      tkChar,
      tkWChar,
      tkString,
      tkLString,
      tkWString,
      tkUString:
        result[i] := TJSONObject.SetStringValue(VE.AsString);
      tkInteger:
        result[i] := TJSONObject.SetIntegerValue(VE.AsInteger);
      tkInt64:
        result[i] := TJSONObject.SetInt64Value(VE.AsInt64);
      tkEnumeration:
        result[i] := TJSONObject.SetInt64Value(EnumToI64(VE, FName));
      tkFloat:
        result[i] := FloatToObj(DAT.ElementType, VE);
      tkSet:
        result[i] := TJSONObject.SetStringValue(SetToStr(VE));
      tkArray,
      tkDynArray:
        raise Exception.CreateFmt(
          '%s: array of array not supported by Firestore', [FName]);
      tkRecord:
        result[i] := TJSONObject.SetMapValue(MapToFSMap(
          DAT.ElementType as TRttiRecordType, VE));
      else
        raise Exception.CreateFmt(
          '%s: array type %s not yet supported in %s',
          [FName,
           TRttiEnumerationType.GetName(DAT.ElementType.TypeKind),
           sMethodName]);
    end;
  end;
end;

function TFirestoreDocument.ArrayToFSArr(R: TRTTIType; V: TValue;
  const FName: string): TFirestoreArr;
const
  sMethodName = 'TFirestoreDocument.ArrayToFSArr';
var
  DAT: TRttiArrayType;
  i: integer;
  VE: TValue;
begin
  DAT := R as TRttiArrayType;
  Assert(assigned(DAT.ElementType), Format(
    '%s: Element type missing in %s.ArrayToFSAss', [FName, sMethodName]));
  SetLength(result, V.GetArrayLength);
  for i := 0 to V.GetArrayLength - 1 do
  begin
    VE := V.GetArrayElement(i);
    case DAT.ElementType.TypeKind of
      tkChar,
      tkWChar,
      tkString,
      tkLString,
      tkWString,
      tkUString:
        result[i] := TJSONObject.SetStringValue(VE.AsString);
      tkInteger:
        result[i] := TJSONObject.SetIntegerValue(VE.AsInteger);
      tkInt64:
        result[i] := TJSONObject.SetInt64Value(VE.AsInt64);
      tkEnumeration:
        result[i] := TJSONObject.SetInt64Value(EnumToI64(VE, FName));
      tkFloat:
        result[i] := FloatToObj(DAT.ElementType, VE);
      tkSet:
        result[i] := TJSONObject.SetStringValue(SetToStr(VE));
      tkArray,
      tkDynArray:
        raise Exception.CreateFmt(
          '%s: array of array not supported by Firestore', [FName]);
      tkRecord:
        result[i] := TJSONObject.SetMapValue(MapToFSMap(
          DAT.ElementType as TRttiRecordType, VE));
      else
        raise Exception.CreateFmt(
          '%s: array type %s not yet supported in %s',
          [FName,
           TRttiEnumerationType.GetName(DAT.ElementType.TypeKind),
           sMethodName]);
    end;
  end;
end;

function TFirestoreDocument.SaveObjectToDocument: IFirestoreDocument;
const
  sMethodName = 'TFirestoreDocument.SaveObjectToDocument';
var
  Ctx: TRTTIContext;
  T: TRTTIType;
  F: TRTTIField;
  IsInheritedClass: boolean;
begin
  Ctx := TRTTIContext.Create;
  try
    T := Ctx.GetType(ClassInfo);
    for F in T.GetFields do
    begin
      IsInheritedClass := not(
        (F.Parent.Name = 'TFirestoreDocument') or
        (F.Parent.Name = 'TInterfacedObject') or
        (F.Parent.Name = 'TInterfacedObject'));
      if IsInheritedClass then
      begin
        if not assigned(F.FieldType) then
          raise Exception.CreateFmt('%s: Fieldtype not accessible in %s',
            [F.Name, sMethodName]);
        case F.FieldType.TypeKind of
          tkChar,
          tkWChar,
          tkString,
          tkLString,
          tkWString,
          tkUString:
            AddOrUpdate(F.Name,
              TJSONObject.SetStringValue(F.GetValue(self).AsString));
          tkFloat:
            AddOrUpdate(F.Name, FloatToObj(F.FieldType, F.GetValue(self)));
          tkSet:
            AddOrUpdate(F.Name,
              TJSONObject.SetStringValue(SetToStr(F.GetValue(self))));
          tkEnumeration:
            AddOrUpdate(F.Name,
              TJSONObject.SetInt64Value(EnumToI64(F.GetValue(self), F.Name)));
          tkInteger:
            AddOrUpdate(F.Name,
              TJSONObject.SetIntegerValue(F.GetValue(self).AsInteger));
          tkInt64:
            AddOrUpdate(F.Name,
              TJSONObject.SetInt64Value(F.GetValue(self).AsInt64));
          tkDynArray:
            AddOrUpdate(TJSONObject.SetArray(F.Name,
              DynArrToFSArr(F.FieldType, F.GetValue(self), F.Name)));
          tkArray:
            AddOrUpdate(TJSONObject.SetArray(F.Name,
              ArrayToFSArr(F.FieldType, F.GetValue(self), F.Name)));
          tkRecord:
            AddOrUpdate(TJSONObject.SetMap(F.Name, MapToFSMap(
              F.FieldType as TRttiRecordType, F.GetValue(self))));
          tkUnknown,
          tkClassRef,
          tkPointer,
          tkProcedure,
          tkMethod,
          tkMRecord: ;
          tkClass,
          tkInterface,
          tkVariant:
            raise Exception.CreateFmt('%s: Type %s not yet supported in %s',
              [F.Name, TRttiEnumerationType.GetName(F.FieldType.TypeKind),
               sMethodName]);
        end;
      end;
    end;
    {$IFDEF DEBUG}
    var s: string;
    for s in SplitString(fJSONObj.Format, #13) do
      TFirebaseHelpers.Log('  ' + s);
    {$ENDIF}
    result := self;
  finally
    Ctx.Free;
  end;
end;

function TFirestoreDocument.CharToVal(TypeInfo: PTypeInfo;
  const s: string): TValue;
var
  c: Char;
begin
  if s > '' then
    c := s[1]
  else
    c := #0;
  TValue.Make(@c, TypeInfo, result);
end;

function TFirestoreDocument.AnsiCharToVal(TypeInfo: PTypeInfo;
  const s: string): TValue;
var
  c: AnsiChar;
begin
  if s > '' then
    c := AnsiChar(s[1])
  else
    c := #0;
  TValue.Make(@c, TypeInfo, result);
end;

function TFirestoreDocument.AnsiStringToVal(TypeInfo: PTypeInfo;
  const s: string): TValue;
var
  a: AnsiString;
begin
  a := AnsiString(s);
  TValue.Make(@a, TypeInfo, result);
end;

function TFirestoreDocument.WideStringToVal(TypeInfo: PTypeInfo;
  const s: string): TValue;
var
  w: WideString;
begin
  w := WideString(s);
  TValue.Make(@w, TypeInfo, result);
end;

function TFirestoreDocument.FloatToVal(RType: TRTTIType;
  Obj: TJSONObject): TValue;
begin
  if SameText(RType.Name, 'TDateTime') then
    result := Obj.GetTimeStampValue(tzLocalTime)
  else if RType.RttiDataSize <= 11 then
    result := Obj.GetDoubleValue
  else
    result := extended(Obj.GetDoubleValue);
end;

function TFirestoreDocument.EnumToVal(TypeInfo: PTypeInfo; I: Int64): TValue;
begin
  TValue.Make(i, TypeInfo, result);
end;

function TFirestoreDocument.SetToVal(TypeInfo: PTypeInfo;
  const s: string): TValue;
var
  Buffer: set of Byte;
  sl: TStringDynArray;
  si: string;
begin
  sl := SplitString(s, ',');
  Buffer := [];
  for si in sl do
    Buffer := Buffer + [StrToIntDef(si, 0)];
  TValue.Make(@Buffer, TypeInfo, result);
end;

function TFirestoreDocument.RecordToVal(DAT: TRttiRecordType;
  const FName: string; Map: TJSONObject): TValue;
const
  sMethodName = 'TFirestoreDocument.RecordToVal';
var
  Fields: TArray<TRttiField>;
  i: integer;
  Obj: TJSONObject;
  VE: TValue;
  Buffer: TBytes;
begin
  Fields := DAT.GetDeclaredFields;
  SetLength(Buffer, DAT.TypeSize);
  if Map.GetMapSize < length(Fields) then
    raise Exception.CreateFmt(
      '%s: record %s to less fields in the Firestore %d, (expected: %d)',
         [sMethodName, FName, Map.GetMapSize, length(Fields)]);

  for i := 0 to length(Fields) - 1 do
  begin
    Obj := Map.GetMapItem(Fields[i].Name);
    case Fields[i].FieldType.TypeKind of
      tkChar:
        VE := AnsiCharToVal(Fields[i].FieldType.Handle, Obj.GetStringValue);
      tkWChar:
        VE := CharToVal(Fields[i].FieldType.Handle, Obj.GetStringValue);
      tkLString,
      tkString:
        VE := AnsiStringToVal(Fields[i].FieldType.Handle, Obj.GetStringValue);
      tkWString:
        VE := WideStringToVal(Fields[i].FieldType.Handle, Obj.GetStringValue);
      tkUString:
        VE := Obj.GetStringValue;
      tkInteger:
        VE := Obj.GetIntegerValue;
      tkInt64:
        VE := Obj.GetInt64Value;
      tkEnumeration:
        VE := EnumToVal(Fields[i].FieldType.Handle, Obj.GetInt64Value);
      tkFloat:
        VE := FloatToVal(Fields[i].FieldType, Obj);
      tkSet:
        VE := SetToVal(DAT.Handle, Obj.GetStringValue);
      tkArray:
        VE := ArrayToVal(Fields[i], Obj.GetArrayValues);
      tkDynArray:
        VE := DynArrayToVal(Fields[i], Obj.GetArrayValues);
      tkRecord:
        VE := RecordToVal(Fields[i].FieldType as TRttiRecordType,
          Fields[i].Name, Obj.GetMapValues);
      else
        raise Exception.CreateFmt(
          '%s.%s: record type %s not yet supported in %s',
          [FName, Fields[i].Name,
           TRttiEnumerationType.GetName(Fields[i].FieldType.TypeKind),
           sMethodName]);
    end;
    VE. ExtractRawData(
      pointer(NativeInt(@Buffer[0]) + NativeInt(Fields[i].Offset)));
  end;
  TValue.Make(Buffer, DAT.Handle, result);
end;

function TFirestoreDocument.DynArrayToVal(F: TRTTIField;
  Arr: TJSONObjects): TValue;
const
  sMethodName = 'TFirestoreDocument.DynArrayToVal';
var
  DAT: TRttiDynamicArrayType;
  i: integer;
  VA: array of TValue;
begin
  DAT := F.FieldType as TRttiDynamicArrayType;
  SetLength(VA, length(Arr));
  for i := 0 to length(Arr) - 1 do
  begin
    case DAT.ElementType.TypeKind of
      tkChar:
        VA[i] := AnsiCharToVal(DAT.Handle, Arr[i].GetStringValue);
      tkWChar:
        VA[i] := CharToVal(DAT.Handle, Arr[i].GetStringValue);
      tkLString,
      tkString:
        VA[i] := String(AnsiString(Arr[i].GetStringValue));
      tkWString:
        VA[i] := WideString(Arr[i].GetStringValue);
      tkUString:
        VA[i] := Arr[i].GetStringValue;
      tkInteger:
        VA[i] := Arr[i].GetIntegerValue;
      tkInt64:
        VA[i] := Arr[i].GetInt64Value;
      tkEnumeration:
        VA[i] := EnumToVal(DAT.Handle, Arr[i].GetInt64Value);
      tkFloat:
        VA[i] := FloatToVal(DAT.ElementType, Arr[i]);
      tkSet:
        VA[i] := SetToVal(DAT.Handle, Arr[i].GetStringValue);
      tkRecord:
        VA[i] := RecordToVal(DAT.ElementType as TRttiRecordType, F.Name,
          Arr[i]);
     else
       raise Exception.CreateFmt(
         '%s: dynarray type %s not yet supported in %s',
         [F.Name, TRttiEnumerationType.GetName(DAT.ElementType.TypeKind),
          sMethodName]);
   end;
  end;
  result := TValue.FromArray(F.FieldType.Handle, VA);
end;

function TFirestoreDocument.ArrayToVal(F: TRTTIField;
  Arr: TJSONObjects): TValue;
const
  sMethodName = 'TFirestoreDocument.ArrayToVal';
var
  DAT: TRttiArrayType;
  i: integer;
  VA: array of TValue;
begin
  DAT := F.FieldType as TRttiArrayType;
  SetLength(VA, length(Arr));
  for i := 0 to length(Arr) - 1 do
  begin
    case DAT.ElementType.TypeKind of
      tkChar:
        VA[i] := AnsiCharToVal(DAT.Handle, Arr[i].GetStringValue);
      tkWChar:
        VA[i] := CharToVal(DAT.Handle, Arr[i].GetStringValue);
      tkLString,
      tkString:
        VA[i] := String(AnsiString(Arr[i].GetStringValue));
      tkWString:
        VA[i] := WideString(Arr[i].GetStringValue);
      tkUString:
        VA[i] := Arr[i].GetStringValue;
      tkInteger:
        VA[i] := Arr[i].GetIntegerValue;
      tkInt64:
        VA[i] := Arr[i].GetInt64Value;
      tkEnumeration:
        VA[i] := EnumToVal(DAT.Handle, Arr[i].GetInt64Value);
      tkFloat:
        VA[i] := FloatToVal(DAT.ElementType, Arr[i]);
      tkSet:
        VA[i] := SetToVal(DAT.Handle, Arr[i].GetStringValue);
      tkRecord:
        VA[i] := RecordToVal(DAT.ElementType as TRttiRecordType, F.Name,
          Arr[i]);
     else
       raise Exception.CreateFmt(
         '%s: array type %s not yet supported in %s',
         [F.Name, TRttiEnumerationType.GetName(DAT.ElementType.TypeKind),
          sMethodName]);
   end;
  end;
  result := TValue.FromArray(F.FieldType.Handle, VA);
end;

procedure TFirestoreDocument.LoadObjectFromDoc;
const
  sMethodName = 'TFirestoreDocument.LoadObjectFromDoc';
var
  Ctx: TRTTIContext;
  T: TRTTIType;
  F: TRTTIField;
  IsInheritedClass: boolean;
begin
  Ctx := TRTTIContext.Create;
  try
    T := Ctx.GetType(ClassInfo);
    for F in T.GetFields do
    begin
      IsInheritedClass := not(
        (F.Parent.Name = 'TFirestoreDocument') or
        (F.Parent.Name = 'TInterfacedObject') or
        (F.Parent.Name = 'TInterfacedObject'));
      if IsInheritedClass then
      begin
        if not assigned(F.FieldType) then
          raise Exception.CreateFmt('%s: Fieldtype not accessible in %s',
            [F.Name, sMethodName]);
        case F.FieldType.TypeKind of
          tkChar:
            F.SetValue(self,
              AnsiCharToVal(F.FieldType.Handle, GetStringValueDef(F.Name, '')));
          tkWChar:
            F.SetValue(self,
              CharToVal(F.FieldType.Handle, GetStringValueDef(F.Name, '')));
          tkUString:
            F.SetValue(self, GetStringValueDef(F.Name, ''));
          tkString,
          tkLString:
            F.SetValue(self,
              AnsiStringToVal(F.FieldType.Handle, GetStringValueDef(F.Name, '')));
          tkWString:
            F.SetValue(self,
              WideStringToVal(F.FieldType.Handle, GetStringValueDef(F.Name, '')));
          tkInteger:
            F.SetValue(self, GetIntegerValueDef(F.Name, 0));
          tkInt64:
            F.SetValue(self, GetInt64ValueDef(F.Name, 0));
          tkFloat:
            F.SetValue(self, FloatToVal(F.FieldType, FieldByName(F.Name)));
          tkEnumeration:
            F.SetValue(self,
              EnumToVal(F.FieldType.Handle, GetInt64ValueDef(F.Name, 0)));
          tkSet:
            F.SetValue(self,
              SetToVal(F.FieldType.Handle, GetStringValueDef(F.Name, '')));
          tkDynArray:
            F.SetValue(self, DynArrayToVal(F, GetArrayValues(F.Name)));
          tkArray:
            F.SetValue(self, ArrayToVal(F, GetArrayValues(F.Name)));
          tkRecord:
            F.SetValue(self, RecordToVal(F.FieldType as TRttiRecordType,
              F.Name, FieldByName(F.Name)));
          tkUnknown,
          tkClassRef,
          tkPointer,
          tkProcedure,
          tkMethod,
          tkMRecord: ;
          tkClass,
          tkInterface,
          tkVariant:
            raise Exception.CreateFmt('%s: Type %s not yet supported in %s',
              [F.Name, TRttiEnumerationType.GetName(F.FieldType.TypeKind),
               sMethodName]);
        end;
      end;
    end;
  finally
    Ctx.Free;
  end;
end;

constructor TFirestoreDocument.LoadObjectFromDocument(Doc: IFirestoreDocument);
begin
  CreateFromJSONObj(Doc.AsJSON);
  LoadObjectFromDoc;
end;
{$ENDREGION}

{ TFirestoreDocsEnumerator }

constructor TFirestoreDocsEnumerator.Create(Docs: TFirestoreDocuments);
begin
  fDocs := Docs;
  fCursor := -1;
end;

function TFirestoreDocsEnumerator.GetCurrent: TObject;
begin
  result := TObject(GenericGetCurrent);
end;

function TFirestoreDocsEnumerator.GenericGetCurrent: IFirestoreDocument;
begin
  if fCursor < fDocs.Count then
    result := fDocs.Document(fCursor)
  else
    result := nil;
end;

function TFirestoreDocsEnumerator.MoveNext: Boolean;
begin
  inc(fCursor);
  result := fCursor < fDocs.Count;
end;

procedure TFirestoreDocsEnumerator.Reset;
begin
  fCursor := -1;
end;

end.
