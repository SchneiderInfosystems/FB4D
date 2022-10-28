{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2022 Christoph Schneider                                 }
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

unit FB4D.VisionMLDefinition;

interface

uses
  System.Classes, System.Types, System.SysUtils, System.JSON,
  System.Generics.Collections;

type
  TErrorStatus = record
    ErrorFound: boolean;
    ErrorCode: integer;  // See https://github.com/googleapis/googleapis/blob/master/google/rpc/code.proto
    ErrorMessage: string;
    Details: TStringDynArray;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TVertex = record
    x: integer;
    y: integer;
    procedure Init;
    procedure SetFromJSON(Vertex: TJSONObject);
    function AsStr: string;
  end;

  TNormalizedVertex = record
    x: double;
    y: double;
    procedure Init;
    procedure SetFromJSON(Vertex: TJSONObject);
    function AsStr: string;
  end;

  TBoundingPoly = record
    Vertices: array of TVertex;
    NormalizedVertices: array of TNormalizedVertex;
    procedure Init;
    procedure SetFromJSON(BoundingPoly: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TLocationInfo = record
    Latitude, Longitude: Extended;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TProperty = record
    Name, Value: string;
    uInt64Value: UInt64;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TEntityAnnotation = record
    Id: string;
    Locale: string;
    Description: string;
    Score, Topicality, Confidence: double;
    BoundingBox: TBoundingPoly;
    Locations: array of TLocationInfo;
    Properties: array of TProperty;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TAnnotationList = array of TEntityAnnotation;

  TFaceLandmarkType = (flmUnkown, flmLeftEye, flmRightEye,
    flmLeftOfLeftEyeBrow, flmRightOfLeftEyeBrow,
    flmLeftOfRightEyeBrow, flmRightOfRightEyeBrow,
    flmMidpointBetweenEyes, flmNoseTip, flmUpperLip, flmLowerLip,
    flmMouthLeft, flmMouthRight, flmMouthCenter,
    flmNoseBottomRight, flmNoseBottomLeft, flmNoseBottomCenter,
    flmLeftEyeTopBoundary, flmLeftEyeRightCorner,
    flmLeftEyeBottomBoundary, flmLeftEyeLeftCorner,
    flmRightEyeTopBoundary, flmRightEyeRightCorner,
    flmRightEyeBottomBoundary, flmRightEyeLeftCorner,
    flmLeftEyebrowUpperMidpoint, flmRightEyebrowUpperMidpoint,
    flmLeftEarTragion, flmRightEarTragion,
    flmLeftEyePupil, flmRightEyePupil,
    flmForeheadGlabella, flmChinGnathion,
    flmChinLeftGonion, flmChinRightGonion,
    flmLeftCheekCenter, flmRightCheekCenter);

  TFacePosition = record
    x, y, z: double;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TFaceLandmark = record
    FaceLandmarkType: TFaceLandmarkType;
    Position: TFacePosition;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TLikelihood = (lhUnknown, lhVeryUnlikely, lhUnlikely, lhPossible, lhLikely,
    lhVeryLikely);

  TFaceAnnotation = record
    BoundingPoly: TBoundingPoly;
    FaceDetectionBP: TBoundingPoly;
    FaceLandmarks: array of TFaceLandmark;
    RollAngle: double; // -180..180
    PanAngle: double; // -180..180
    TiltAngle: double; // -180..180
    DetectionConfidence: double; // 0..1
    LandmarkingConfidence: double; // 0..1
    JoyLikelihood: TLikelihood;
    SorrowLikelihood: TLikelihood;
    AngerLikelihood: TLikelihood;
    SurpriseLikelihood: TLikelihood;
    UnderExposedLikelihood: TLikelihood;
    BlurredLikelihood: TLikelihood;
    HeadwearLikelihood: TLikelihood;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;
  TFaceAnnotationList = array of TFaceAnnotation;

  TLocalizedObjectAnnotation = record
    Id: string;
    LanguageCode: string;
    Name: string;
    Score: double;
    BoundingPoly: TBoundingPoly;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;
  TLocalizedObjectList = array of TLocalizedObjectAnnotation;

  TDetectedLanguage = record
    LanguageCode: string;
    Confidence: double;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TDetectedBreakType = (dbtUnknown, dbtSpace, dbtSureSpace, dbtEOLSureSpace,
    dtbHyphen, dbtLineBreak);

  TTextProperty = record
    DetectedLanguages: array of TDetectedLanguage;
    DetectedBreakType: TDetectedBreakType;
    DetectedBreakIsPrefix: boolean;
    procedure Init;
    procedure SetFromJSON(TextProperty: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
    function AsStr: string;
  end;

  TSymbols = record
    TextProperty: TTextProperty;
    BoundingBox: TBoundingPoly;
    Text: string;
    Confidence: double;
    procedure Init;
    procedure SetFromJSON(Symbol: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
    function AsStr(Short: boolean = false): string;
  end;

  TWord = record
    TextProperty: TTextProperty;
    BoundingBox: TBoundingPoly;
    Symbols: array of TSymbols;
    Confidence: double;
    procedure Init;
    procedure SetFromJSON(Word: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
    function AsStr(Short: boolean = false): string;
  end;

  TParagraph = record
    TextProperty: TTextProperty;
    BoundingBox: TBoundingPoly;
    Words: array of TWord;
    Confidence: double;
    procedure Init;
    procedure SetFromJSON(Paragraph: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
    function AsStr: string;
  end;

  TBlockType = (btUnkown, btText, btTable, btPicture, btRuler, btBarcode);
  TBlock = record
    TextProperty: TTextProperty;
    BoundingBox: TBoundingPoly;
    Paragraphs: array of TParagraph;
    BlockType: TBlockType;
    Confidence: double;
    procedure Init;
    procedure SetFromJSON(Block: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TTextPages = record
    TextProperty: TTextProperty;
    Width, Height: integer;
    Blocks: array of TBlock;
    Confidence: double;
    procedure Init;
    procedure SetFromJSON(Page: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TTextAnnotation = record
    Text: string;
    EncodedText: string;
    TextPages: array of TTextPages;
    procedure Init;
    procedure SetFromJSON(FullText: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TColorInfo = record
    Red, Green, Blue, Alpha: integer;
    Score, PixelFraction: double;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TImagePropertiesAnnotation = record
    DominantColors: array of TColorInfo;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TCropHint = record
    BoundingPoly: TBoundingPoly;
    Confidence: double;
    ImportanceFraction: double;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TCropHintsAnnotation = record
    CropHints: array of TCropHint;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TWebEntity = record
    EntityId: string;
    Description: string;
    Score: Double;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TWebImage = record
    URL: string;
    Score: Double;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TWebPage = record
    URL: string;
    Score: Double;
    PageTitle: string;
    FullMatchingImages: array of TWebImage;
    PartialMatchingImages: array of TWebImage;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TWebLabel = record
    LabelText: string;
    LanguageCode: string;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TWebDetection = record
    WebEntities: array of TWebEntity;
    FullMatchingImages: array of TWebImage;
    PartialMatchingImages: array of TWebImage;
    PagesWithMatchingImages: array of TWebPage;
    VisuallySimilarImages: array of TWebImage;
    BestGuessLabels: array of TWebLabel;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TSafeSearchAnnotation = record
    AdultContent: TLikelihood;
    Spoof: TLikelihood;
    MedicalImage: TLikelihood;
    ViolentContent: TLikelihood;
    RacyContent: TLikelihood;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TKeyValue = record
    Key: string;
    Value: string;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    function AsStr: string;
  end;

  TProduct = record
    Name: string;
    DisplayName: string;
    Description: string;
    ProductCategory: string;
    ProductLabels: array of TKeyValue;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TProductResult = record
    Product: TProduct;
    Score: double;
    Image: string;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TObjectAnnotation = record
    Id: string;
    LanguageCode: string;
    Name: string;
    Score: double;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TGroupedProductResult = record
    BoundingPoly: TBoundingPoly;
    ProductResults: array of TProductResult;
    ObjectAnnotations: array of TObjectAnnotation;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TProductSearchAnnotation = record
    IndexTime: TDateTime;
    ProductResults: array of TProductResult;
    GroupedProductResults: array of TGroupedProductResult;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

  TImageAnnotationContext = record
    URI: string;
    PageNumber: integer;
    procedure Init;
    procedure SetFromJSON(Item: TJSONObject);
    procedure AddStrings(s: TStrings; Indent: integer);
  end;

implementation

uses
  System.TypInfo,
  FB4D.Helpers;

{ TEntityAnnotation }

procedure TEntityAnnotation.Init;
begin
  Id := '';
  Locale := '';
  Description := '';
  Score := 0;
  Topicality := 0;
  Confidence := 0;
  BoundingBox.Init;
  SetLength(Locations, 0);
  SetLength(Properties, 0);
end;

procedure TEntityAnnotation.SetFromJSON(Item: TJSONObject);
var
  O: TJSONObject;
  A: TJSONArray;
  c: integer;
begin
  if not Item.TryGetValue<string>('mid', Id) then
    Id := '';
  if not Item.TryGetValue<string>('locale', Locale) then
    Locale := '';
  if not Item.TryGetValue<string>('description', Description) then
    Description := '';
  if not Item.TryGetValue<Double>('score', Score) then
    Score := 0;
  if not Item.TryGetValue<Double>('topicality', Topicality) then
    Topicality := 0;
  if not Item.TryGetValue<Double>('confidence', Confidence) then
    Confidence := 0;
  if Item.TryGetValue<TJSONObject>('boundingPoly', O) then
    BoundingBox.SetFromJSON(O)
  else
    BoundingBox.Init;
  if Item.TryGetValue<TJSONArray>('locations', A) then
  begin
    SetLength(Locations, A.Count);
    for c := 0 to A.Count - 1 do
      Locations[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(Locations, 0);
  if Item.TryGetValue<TJSONArray>('properties', A) then
  begin
    SetLength(Properties, A.Count);
    for c := 0 to A.Count - 1 do
      Properties[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(Properties, 0);
end;

procedure TEntityAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  Line, Ind: string;
  c: integer;
begin
  Ind := StringOfChar(' ', Indent);
  Line := Ind + '"' + Description + '"';
  if Score > 0 then
    Line := Line + Format(' score %3.1f%%', [Score * 100]);
  if (Topicality > 0) and (abs(Score - Topicality) > 0.01) then
    Line := Line + Format(' topicality %3.1f%%', [Topicality * 100]);
  if not Locale.IsEmpty then
    Line := Line + ' locale ' + Locale;
  if not Id.IsEmpty then
    Line := Line + ' (mid ' + Id + ')';
  s.Add(Line);
  BoundingBox.AddStrings(s, Indent);
  for c := 0 to length(Locations) - 1 do
  begin
    s.Add(Format('%sLocation %d of %d', [Ind, c + 1, length(Locations)]));
    Locations[c].AddStrings(s, Indent + 2);
  end;
  for c := 0 to length(Properties) - 1 do
  begin
    s.Add(Format('%sProperty %d of %d', [Ind, c + 1, length(Properties)]));
    Properties[c].AddStrings(s, Indent + 2);
  end;
end;

{ TDetectedLanguage }

procedure TDetectedLanguage.Init;
begin
  LanguageCode := '';
  Confidence := 0;
end;

procedure TDetectedLanguage.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<string>('languageCode', LanguageCode) then
    LanguageCode := '';
  if not Item.TryGetValue<double>('confidence', Confidence) then
    Confidence := 0;
end;

function TDetectedLanguage.AsStr: string;
begin
  if Confidence > 0 then
    result := Format('"%s" confidence %3.1f%%',
      [TFirebaseHelpers.GetLanguageInEnglishFromCode(LanguageCode),
       Confidence * 100])
  else
    result := Format('"%s"',
      [TFirebaseHelpers.GetLanguageInEnglishFromCode(LanguageCode)]);
end;

{ TTextPages }

procedure TTextPages.Init;
begin
  TextProperty.Init;
  SetLength(Blocks, 0);
  Width := 0;
  Height := 0;
  Confidence := 0;
end;

procedure TTextPages.SetFromJSON(Page: TJSONObject);
var
  P: TJSONObject;
  B: TJSONArray;
  c: integer;
begin
  if Page.TryGetValue<TJSONObject>('property', P) then
    TextProperty.SetFromJSON(P);
  Page.TryGetValue<integer>('width', Width);
  Page.TryGetValue<integer>('height', Height);
  Page.TryGetValue<double>('confidence', Confidence);
  if Page.TryGetValue<TJSONArray>('blocks', B) then
  begin
    SetLength(Blocks, B.Count);
    for c := 0 to B.Count - 1 do
      Blocks[c].SetFromJSON(B[c] as TJSONObject);
  end;
end;

procedure TTextPages.AddStrings(s: TStrings; Indent: integer);
var
  Line: string;
  c: integer;
begin
  Line := StringOfChar(' ', Indent);
  if Width > 0 then
    Line := Line + 'width ' + Width.ToString + ' ';
  if Height > 0 then
    Line := Line + 'height ' + Height.ToString + ' ';
  if Confidence > 0 then
    Line := Line + 'confidence ' + Format('%3.1f%% ', [Confidence * 100]);
  if not trim(Line).IsEmpty then
    s.Add(Line);
  TextProperty.AddStrings(s, Indent + 2);
  for c := 0 to length(Blocks) - 1 do
    Blocks[c].AddStrings(s, Indent + 2);
end;

{ TTextAnnotation }

procedure TTextAnnotation.Init;
begin
  Text := '';
  EncodedText := '';
  SetLength(TextPages, 0);
end;

procedure TTextAnnotation.SetFromJSON(FullText: TJSONObject);
var
  Str: TJSONString;
  Pages: TJSONArray;
  c: integer;
begin
  if FullText.TryGetValue<TJSONString>('text', Str) then
  begin
    EncodedText := Str.ToJSON;
    Text := Str.Value;
  end else begin
    Text := '';
    EncodedText := '';
  end;
  if FullText.TryGetValue<TJSONArray>('pages', Pages) then
  begin
    SetLength(TextPages, Pages.Count);
    for c := 0 to Pages.Count - 1 do
      TextPages[c].SetFromJSON(Pages[c] as TJSONObject);
  end else
    SetLength(TextPages, 0);
end;

procedure TTextAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
  TextPage: integer;
begin
  Ind := StringOfChar(' ', Indent);
  for TextPage := 0 to length(TextPages) - 1 do
  begin
    s.Add(Format('%sText page %d of %d',
      [Ind, TextPage + 1, length(TextPages)]));
    TextPages[TextPage].AddStrings(s, Indent + 2);
  end;
  if not EncodedText.IsEmpty then
    s.Add(Format('%sEncoded text: %s', [Ind, EncodedText]))
  else if not Text.IsEmpty then
    s.Add(Format('%sText: %s', [Ind, Text]))
  else
    s.Add(Format('%sNo text found', [Ind]));
end;

{ TTextProperty }

procedure TTextProperty.Init;
begin
  SetLength(DetectedLanguages, 0);
  DetectedBreakType := TDetectedBreakType.dbtUnknown;
  DetectedBreakIsPrefix := false;
end;

procedure TTextProperty.SetFromJSON(TextProperty: TJSONObject);
var
  L: TJSONArray;
  O: TJSONObject;
  c: integer;
  t: string;
begin
  if TextProperty.TryGetValue<TJSONArray>('detectedLanguages', L) then
  begin
    SetLength(DetectedLanguages, L.Count);
    for c := 0 to L.Count - 1 do
      DetectedLanguages[c].SetFromJSON(L[c] as TJSONObject);
  end else
    SetLength(DetectedLanguages, 0);
  if TextProperty.TryGetValue<TJSONObject>('detectedBreak', O) then
  begin
    if O.TryGetValue<string>('type', t) then
    begin
      if SameText(t, 'SPACE') then
        DetectedBreakType := TDetectedBreakType.dbtSpace
      else if SameText(t, 'SURE_SPACE') then
        DetectedBreakType := TDetectedBreakType.dbtSureSpace
      else if SameText(t, 'EOL_SURE_SPACE') then
        DetectedBreakType := TDetectedBreakType.dbtEOLSureSpace
      else if SameText(t, 'HYPHEN') then
        DetectedBreakType := TDetectedBreakType.dtbHyphen
      else if SameText(t, 'LINE_BREAK') then
        DetectedBreakType := TDetectedBreakType.dbtLineBreak
      else
       DetectedBreakType := TDetectedBreakType.dbtUnknown;
    end;
    if not O.TryGetValue<boolean>('isPrefix', DetectedBreakIsPrefix) then
      DetectedBreakIsPrefix := false;
  end else begin
    DetectedBreakType := TDetectedBreakType.dbtUnknown;
    DetectedBreakIsPrefix := false;
  end;
end;

procedure TTextProperty.AddStrings(s: TStrings; Indent: integer);
var
  Line: string;
  dl: TDetectedLanguage;
begin
  Line := StringOfChar(' ', Indent);
  for dl in DetectedLanguages do
    s.Add(Line + dl.AsStr);
  if DetectedBreakType > TDetectedBreakType.dbtUnknown then
  begin
    if DetectedBreakIsPrefix then
      case DetectedBreakType of
        dbtSpace:
          s.Add(Line + 'Prepends break: regular space');
        dbtSureSpace:
          s.Add(Line + 'Prepends break: wide space');
        dbtEOLSureSpace:
          s.Add(Line + 'Prepends break: line-wrapping');
        dtbHyphen:
          s.Add(Line + 'Prepends break: end line hyphen');
        dbtLineBreak:
          s.Add(Line + 'Prepends break: end line break');
      end
    else
      case DetectedBreakType of
        dbtSpace:
          s.Add(Line + 'Break: regular space');
        dbtSureSpace:
          s.Add(Line + 'Break: wide space');
        dbtEOLSureSpace:
          s.Add(Line + 'Break: line-wrapping');
        dtbHyphen:
          s.Add(Line + 'Break: end line hyphen');
        dbtLineBreak:
          s.Add(Line + 'Break: end line break');
      end;
  end;
end;

function TTextProperty.AsStr: string;
var
  dl: TDetectedLanguage;
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    for dl in DetectedLanguages do
      sl.Add(dl.AsStr);
    if DetectedBreakType > TDetectedBreakType.dbtUnknown then
    begin
      if DetectedBreakIsPrefix then
        case DetectedBreakType of
          dbtSpace:
            sl.Add('Prepends break: regular space');
          dbtSureSpace:
            sl.Add('Prepends break: wide space');
          dbtEOLSureSpace:
            sl.Add('Prepends break: line-wrapping');
          dtbHyphen:
            sl.Add('Prepends break: end line hyphen');
          dbtLineBreak:
            sl.Add('Prepends break: end line break');
        end
      else
        case DetectedBreakType of
          dbtSpace:
            sl.Add('Break: regular space');
          dbtSureSpace:
            sl.Add('Break: wide space');
          dbtEOLSureSpace:
            sl.Add('Break: line-wrapping');
          dtbHyphen:
            sl.Add('Break: end line hyphen');
          dbtLineBreak:
            sl.Add('Break: end line break');
        end;
    end;
    sl.QuoteChar := #0;
    sl.Delimiter := ',';
    result := sl.DelimitedText;
  finally
    sl.Free;
  end;
end;

{ TTextBlock }

procedure TBlock.Init;
begin
  TextProperty.Init;
  BoundingBox.Init;
  SetLength(Paragraphs, 0);
  BlockType := TBlockType.btUnkown;
  Confidence := 0;
end;

procedure TBlock.SetFromJSON(Block: TJSONObject);
var
  Item: TJSONObject;
  Arr: TJSONArray;
  bType: string;
  c: integer;
begin
  if Block.TryGetValue<TJSONObject>('property', Item) then
    TextProperty.SetFromJSON(Item)
  else
    TextProperty.Init;
  if Block.TryGetValue<TJSONObject>('boundingBox', Item) then
    BoundingBox.SetFromJSON(Item)
  else
    BoundingBox.Init;
  if Block.TryGetValue<TJSONArray>('paragraphs', Arr) then
  begin
    SetLength(Paragraphs, Arr.Count);
    for c := 0 to Arr.Count - 1 do
      Paragraphs[c].SetFromJSON(Arr[c] as TJSONObject);
  end;
  if Block.TryGetValue<string>('blockType', bType) then
  begin
    if SameText(bType, 'TEXT') then
      BlockType := TBlockType.btText
    else if SameText(bType, 'TABLE') then
      BlockType := TBlockType.btTable
    else if SameText(bType, 'PICTURE') then
      BlockType := TBlockType.btPicture
    else if SameText(bType, 'RULER') then
      BlockType := TBlockType.btRuler
    else if SameText(bType, 'BARCODE') then
      BlockType := TBlockType.btBarcode
    else
      BlockType := TBlockType.btUnkown;
  end else
    BlockType := TBlockType.btUnkown;
  if not Block.TryGetValue<double>('confidence', Confidence) then
    Confidence := 0;
end;

procedure TBlock.AddStrings(s: TStrings; Indent: integer);
var
  Line: string;
  c: integer;
begin
  if BlockType > TBlockType.btUnkown then
  begin
    case BlockType of
      btText:
        Line := 'Text';
      btTable:
        Line := 'Table';
      btPicture:
        Line := 'Picture';
      btRuler:
        Line := 'Ruler';
      btBarcode:
        Line := 'Barcode';
    end;
    Line := StringOfChar(' ', Indent) + 'Block type: ' + Line;
    if Confidence > 0 then
      Line := Format('%s confidence %3.1f%%', [Line, Confidence * 100]);
    s.Add(Line);
  end;
  TextProperty.AddStrings(s, Indent);
  BoundingBox.AddStrings(s, Indent);
  for c := 0 to Length(Paragraphs) - 1 do
  begin
    s.Add(Format('%sParagraph %d of %d: %s',
      [StringOfChar(' ', Indent), c + 1, Length(Paragraphs),
       Paragraphs[c].AsStr]));
    Paragraphs[c].AddStrings(s, Indent + 2);
  end;
end;

{ TParagraph }

procedure TParagraph.Init;
begin
  TextProperty.Init;
  BoundingBox.Init;
  SetLength(Words, 0);
  Confidence := 0;
end;

procedure TParagraph.SetFromJSON(Paragraph: TJSONObject);
var
  Item: TJSONObject;
  Arr: TJSONArray;
  c: integer;
begin
  if Paragraph.TryGetValue<TJSONObject>('property', Item) then
    TextProperty.SetFromJSON(Item)
  else
    TextProperty.Init;
  if Paragraph.TryGetValue<TJSONObject>('boundingBox', Item) then
    BoundingBox.SetFromJSON(Item)
  else
    BoundingBox.Init;
  if Paragraph.TryGetValue<TJSONArray>('words', Arr) then
  begin
    SetLength(Words, Arr.Count);
    for c := 0 to Arr.Count - 1 do
      Words[c].SetFromJSON(Arr[c] as TJSONObject);
  end;
  if not Paragraph.TryGetValue<double>('confidence', Confidence) then
    Confidence := 0;
end;

procedure TParagraph.AddStrings(s: TStrings; Indent: integer);
var
  c: integer;
begin
  BoundingBox.AddStrings(s, Indent);
  for c := 0 to Length(Words) - 1 do
  begin
    s.Add(Format('%sWord %d of %d: %s',
      [StringOfChar(' ', Indent), c + 1, Length(Words), Words[c].AsStr]));
    Words[c].AddStrings(s, Indent + 2);
  end;
end;

function TParagraph.AsStr: string;
var
  c: integer;
begin
  result := '"';
  for c := 0 to Length(Words) - 1 do
    result := result + Words[c].AsStr(true) + ' ';
  result := trim(result) + '"';
  if Confidence > 0 then
    result := result + Format(', %3.1f%% confidence', [Confidence * 100]);
  result := result + TextProperty.AsStr;
end;

{ TWord }

procedure TWord.Init;
begin
  TextProperty.Init;
  BoundingBox.Init;
  SetLength(Symbols, 0);
  Confidence := 0;
end;

procedure TWord.SetFromJSON(Word: TJSONObject);
var
  Item: TJSONObject;
  Arr: TJSONArray;
  c: integer;
begin
  if Word.TryGetValue<TJSONObject>('property', Item) then
    TextProperty.SetFromJSON(Item)
  else
    TextProperty.Init;
  if Word.TryGetValue<TJSONObject>('boundingBox', Item) then
    BoundingBox.SetFromJSON(Item)
  else
    BoundingBox.Init;
  if Word.TryGetValue<TJSONArray>('symbols', Arr) then
  begin
    SetLength(Symbols, Arr.Count);
    for c := 0 to Arr.Count - 1 do
      Symbols[c].SetFromJSON(Arr[c] as TJSONObject);
  end;
  if not Word.TryGetValue<double>('confidence', Confidence) then
    Confidence := 0;
end;

procedure TWord.AddStrings(s: TStrings; Indent: integer);
var
  c: integer;
begin
  BoundingBox.AddStrings(s, Indent);
  for c := 0 to Length(Symbols) - 1 do
  begin
    s.Add(Format('%sSymbols %d of %d: %s',
      [StringOfChar(' ', Indent), c + 1, Length(Symbols), Symbols[c].AsStr]));
    Symbols[c].AddStrings(s, Indent + 2);
  end;
end;

function TWord.AsStr(Short: boolean): string;
var
  c: integer;
begin
  result := '';
  for c := 0 to Length(Symbols) - 1 do
    result := result + Symbols[c].AsStr(true);
  if not Short then
  begin
    result := '"' + result + '"';
    if Confidence > 0 then
      result := result + Format(', confidence %3.1f%%', [Confidence * 100]);
    if not TextProperty.AsStr.IsEmpty then
      result := result + ', ' + TextProperty.AsStr;
  end;
end;

{ TSymbols }

procedure TSymbols.Init;
begin
  TextProperty.Init;
  BoundingBox.Init;
  Text := '';
  Confidence := 0;
end;

procedure TSymbols.SetFromJSON(Symbol: TJSONObject);
var
  Item: TJSONObject;
begin
  if Symbol.TryGetValue<TJSONObject>('property', Item) then
    TextProperty.SetFromJSON(Item)
  else
    TextProperty.Init;
  if Symbol.TryGetValue<TJSONObject>('boundingBox', Item) then
    BoundingBox.SetFromJSON(Item)
  else
    BoundingBox.Init;
  if not Symbol.TryGetValue<string>('text', Text) then
    Text := '';
  if not Symbol.TryGetValue<double>('confidence', Confidence) then
    Confidence := 0;
end;

procedure TSymbols.AddStrings(s: TStrings; Indent: integer);
begin
  BoundingBox.AddStrings(s, Indent);
end;

function TSymbols.AsStr(Short: boolean): string;
begin
  if Short then
    result := Text
  else begin
    result := '"' + Text + '" ';
    if Confidence > 0 then
      result := result + Format(', %3.1f%% confidence', [Confidence * 100]);
    result := result + ' ' + TextProperty.AsStr;
  end;
end;

{ TBoundingPoly }

procedure TBoundingPoly.Init;
begin
  SetLength(Vertices, 0);
  SetLength(NormalizedVertices, 0);
end;

procedure TBoundingPoly.SetFromJSON(BoundingPoly: TJSONObject);
var
  Arr: TJSONArray;
  c: integer;
begin
  if BoundingPoly.TryGetValue<TJSONArray>('vertices', Arr) then
  begin
    SetLength(Vertices, Arr.Count);
    for c := 0 to Arr.Count - 1 do
      Vertices[c].SetFromJSON(Arr[c] as TJSONObject);
  end;
  if BoundingPoly.TryGetValue<TJSONArray>('normalizedVertices', Arr) then
  begin
    SetLength(NormalizedVertices, Arr.Count);
    for c := 0 to Arr.Count - 1 do
      NormalizedVertices[c].SetFromJSON(Arr[c] as TJSONObject);
  end;
end;

procedure TBoundingPoly.AddStrings(s: TStrings; Indent: integer);
var
  c: integer;
  Ind, Line: string;
begin
  Ind := StringOfChar(' ', Indent);
  Line := '';
  for c := 0 to length(Vertices) - 1 do
    Line := Line + Vertices[c].AsStr;
  if not Line.IsEmpty then
    s.Add(Ind + 'Vertices: ' + Line)
  else begin
    Line := '';
    for c := 0 to length(NormalizedVertices) - 1 do
      Line := Line + NormalizedVertices[c].AsStr;
    if not Line.IsEmpty then
      s.Add(Ind + 'Normalized Vertices: ' + Line);
  end;
end;

{ TVertex }

procedure TVertex.Init;
begin
  x := 0;
  y := 0;
end;

procedure TVertex.SetFromJSON(Vertex: TJSONObject);
begin
  if not Vertex.TryGetValue<integer>('x', x) then
    x := 0;
  if not Vertex.TryGetValue<integer>('y', y) then
    y := 0;
end;

function TVertex.AsStr: string;
begin
  result := '[';
  if x > 0 then
    result := result + 'x: ' + IntToStr(x);
  if y > 0 then
  begin
    if not result.EndsWith('[') then
      result := result + ',';
    result := result + 'y: ' + IntToStr(y);
  end;
  result := result + ']';
end;

{ TNormalizedVertex }

procedure TNormalizedVertex.Init;
begin
  x := 0;
  y := 0;
end;

procedure TNormalizedVertex.SetFromJSON(Vertex: TJSONObject);
begin
  if not Vertex.TryGetValue<double>('x', x) then
    x := 0;
  if not Vertex.TryGetValue<double>('y', y) then
    y := 0;
end;

function TNormalizedVertex.AsStr: string;
begin
  result := '[';
  if x > 0 then
    result := result + 'x: ' + FloatToStr(x);
  if y > 0 then
  begin
    if not result.EndsWith('[') then
      result := result + ',';
    result := result + 'y: ' + FloatToStr(y);
  end;
  result := result + ']';
end;

{ TLocationInfo }

procedure TLocationInfo.Init;
begin
  Latitude := 0;
  Longitude := 0;
end;

procedure TLocationInfo.SetFromJSON(Item: TJSONObject);
var
  O: TJSONObject;
begin
  if Item.TryGetValue<TJSONObject>('latLng', O) then
  begin
    if not O.TryGetValue<extended>('latitude', Latitude) then
      Latitude := 0;
    if not O.TryGetValue<extended>('longitude', Longitude) then
      Longitude := 0;
  end else
    Init;
end;

procedure TLocationInfo.AddStrings(s: TStrings; Indent: integer);
begin
  s.Add(Format('%sLocation latitude %9.6f longitude %9.6f',
      [StringOfChar(' ', Indent), Latitude, Longitude]));
end;

{ TProperty }

procedure TProperty.Init;
begin
  Name := '';
  Value := '';
  uInt64Value := 0;
end;

procedure TProperty.SetFromJSON(Item: TJSONObject);
var
  Val: string;
begin
  if not Item.TryGetValue<string>('name', Name) then
    Name := '';
  if not Item.TryGetValue<string>('value', Value) then
    Value := '';
  if Item.TryGetValue<string>('uint64Value', Val) then
    uInt64Value := StrToInt64Def(Val, 0)
  else
    uInt64Value := 0;
end;

procedure TProperty.AddStrings(s: TStrings; Indent: integer);
var
 Val: string;
begin
  if not Value.IsEmpty then
  begin
    Val := '"' + Value + '"';
    if uInt64Value > 0 then
      Val := Val + ' (' + IntToStr(uInt64Value) + ')';
  end else
    Val := IntToStr(uInt64Value);
  s.Add(Format('%sProperty "%s"=%s',
      [StringOfChar(' ', Indent), Name, Val]));
end;

{ TErrorStatus }

procedure TErrorStatus.Init;
begin
  ErrorFound := false;
  ErrorCode := 0;
  ErrorMessage := '';
  SetLength(Details, 0);
end;

procedure TErrorStatus.SetFromJSON(Item: TJSONObject);
var
  A: TJSONArray;
  c: integer;
begin
  ErrorFound := assigned(Item);
  if not ErrorFound then
    Init
  else begin
    if not Item.TryGetValue<integer>('code', ErrorCode) then
      ErrorCode := 0;
    if not Item.TryGetValue<string>('message', ErrorMessage) then
      ErrorMessage := '';
    if Item.TryGetValue<TJSONArray>('details', A) then
    begin
      SetLength(Details, A.Count);
      for c := 0 to A.Count - 1 do
        Details[c] := A.Items[c].Value;
    end else
      SetLength(Details, 0);
  end;
end;

function TErrorStatus.AsStr: string;
begin
  if ErrorFound then
    result := Format('Error "%s" (%d)', [ErrorMessage, ErrorCode])
  else
    result := '';
end;

{ TLikelihood }

function ConvertLikelihood(const s: string): TLikelihood;
begin
  if SameText(s, 'VERY_UNLIKELY') then
    result := TLikelihood.lhVeryUnlikely
  else if SameText(s, 'UNLIKELY') then
    result := TLikelihood.lhUnlikely
  else if SameText(s, 'POSSIBLE') then
    result := TLikelihood.lhPossible
  else if SameText(s, 'LIKELY') then
    result := TLikelihood.lhLikely
  else if SameText(s, 'VERY_LIKELY') then
    result := TLikelihood.lhVeryLikely
  else
    result := TLikelihood.lhUnknown;
end;

function LikelihoodAsStr(l: TLikelihood): string;
begin
  case l of
    lhVeryUnlikely:
      result := 'very unlikely';
    lhUnlikely:
      result := 'unlikely';
    lhPossible:
      result := 'possible';
    lhLikely:
      result := 'likely';
    lhVeryLikely:
      result := 'very likely';
    else
      result := 'unknown likelihood';
  end;
end;

{ TColorInfo }

procedure TColorInfo.Init;
begin
  Red := 0;
  Green := 0;
  Blue := 0;
  Alpha := 1;
  Score := 0;
  PixelFraction := 0;
end;

procedure TColorInfo.SetFromJSON(Item: TJSONObject);
var
  Col: TJSONObject;
begin
  if Item.TryGetValue<TJSONObject>('color', Col) then
  begin
    if not Col.TryGetValue<integer>('red', Red) then
      Red := 0;
    if not Col.TryGetValue<integer>('green', Green) then
      Green := 0;
    if not Col.TryGetValue<integer>('blue', Blue) then
      Blue := 0;
    if not Col.TryGetValue<integer>('alpha', Alpha) then
      Alpha := 1;
  end else begin
    Red := 0;
    Green := 0;
    Blue := 0;
    Alpha := 0;
  end;
  if not Item.TryGetValue<double>('score', Score) then
    Score := 0;
  if not Item.TryGetValue<double>('pixelFraction', PixelFraction) then
    PixelFraction := 0;
end;

function TColorInfo.AsStr: string;
begin
  result := Format('R%d G%d B%d A%d, score %3.1f%%, pixel fraction %3.1f%%',
    [Red, Green, Blue, Alpha, Score * 100, PixelFraction * 100]);
end;

{ TImagePropertiesAnnotation }

procedure TImagePropertiesAnnotation.Init;
begin
  SetLength(DominantColors, 0);
end;

procedure TImagePropertiesAnnotation.SetFromJSON(Item: TJSONObject);
var
  O: TJSONObject;
  A: TJSONArray;
  c: integer;
begin
  Init;
  if Item.TryGetValue<TJSONObject>('dominantColors', O) and
     O.TryGetValue<TJSONArray>('colors', A) then
  begin
    SetLength(DominantColors, A.Count);
    for c := 0 to A.Count - 1 do
      DominantColors[c].SetFromJSON(A[c] as TJSONObject);
  end;
end;

procedure TImagePropertiesAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
  c: integer;
begin
  Ind := StringOfChar(' ', Indent);
  if length(DominantColors) = 0 then
    s.Add(Ind + 'No dominante colors')
  else
    for c := 0 to length(DominantColors) - 1 do
      s.Add(Format('%sDominant color %d of %d: %s',
        [Ind, c + 1, length(DominantColors), DominantColors[c].AsStr]));
end;

{ TCropHint }

procedure TCropHint.Init;
begin
  BoundingPoly.Init;
  Confidence := 0;
  ImportanceFraction := 0;
end;

procedure TCropHint.SetFromJSON(Item: TJSONObject);
var
  O: TJSONObject;
begin
  if Item.TryGetValue<TJSONObject>('boundingPoly', O) then
    BoundingPoly.SetFromJSON(O)
  else
    BoundingPoly.Init;
  if not Item.TryGetValue<double>('confidence', Confidence) then
    Confidence := 0;
  if not Item.TryGetValue<double>('importanceFraction', ImportanceFraction) then
    ImportanceFraction := 0;
end;

procedure TCropHint.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
begin
  BoundingPoly.AddStrings(s, Indent);
  Ind := StringOfChar(' ', Indent);
  s.Add(Format('%sConfidence %3.1f%%, importance Fraction %3.1f%%',
    [Ind, Confidence * 100, ImportanceFraction * 100]));
end;

{ TCropHintsAnnotation }

procedure TCropHintsAnnotation.Init;
begin
  SetLength(CropHints, 0);
end;

procedure TCropHintsAnnotation.SetFromJSON(Item: TJSONObject);
var
  A: TJSONArray;
  c: integer;
begin
  Init;
  if Item.TryGetValue<TJSONArray>('cropHints', A) then
  begin
    SetLength(CropHints, A.Count);
    for c := 0 to A.Count - 1 do
      CropHints[c].SetFromJSON(A[c] as TJSONObject);
  end;
end;

procedure TCropHintsAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
  c: integer;
begin
  Ind := StringOfChar(' ', Indent);
  if length(CropHints) = 0 then
    s.Add(Ind + 'No crop hints')
  else begin
    for c := 0 to length(CropHints) - 1 do
    begin
      s.Add(Format('%sCrop hints %d of %d',
        [Ind, c + 1, length(CropHints)]));
      CropHints[c].AddStrings(s, Indent + 2);
    end;
  end;
end;

{ TWebEntity }

procedure TWebEntity.Init;
begin
  EntityId := '';
  Description := '';
  Score := 0;
end;

procedure TWebEntity.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<string>('entityId', EntityId) then
    EntityId := '';
  if not Item.TryGetValue<double>('score', Score) then
    Score := 0;
  if not Item.TryGetValue<string>('description', Description) then
    Description := '';
end;

function TWebEntity.AsStr: string;
begin
  if Score > 0 then
    result := Format('"%s" (Id %s) %3.1f%% score',
      [Description, EntityId, Score * 100])
  else
    result := Format('"%s" (Id %s)', [Description, EntityId]);
end;

{ TWebImage }

procedure TWebImage.Init;
begin
  URL := '';
  Score := 0;
end;

procedure TWebImage.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<string>('url', URL) then
    URL := '';
  if not Item.TryGetValue<double>('score', Score) then
    Score := 0;
end;

function TWebImage.AsStr: string;
begin
  if URL.IsEmpty then
    result := 'No URL found'
  else if Score > 0 then
    result := Format('URL: %s score %3.1f%%', [URL, Score * 100])
  else
    result := Format('URL: %s', [URL]);
end;

{ TWebPage }

procedure TWebPage.Init;
begin
  URL := '';
  Score := 0;
  PageTitle := '';
  SetLength(FullMatchingImages, 0);
  SetLength(PartialMatchingImages, 0);
end;

procedure TWebPage.SetFromJSON(Item: TJSONObject);
var
  A: TJSONArray;
  c: integer;
begin
  if not Item.TryGetValue<string>('url', URL) then
    URL := '';
  if not Item.TryGetValue<double>('score', Score) then
    Score := 0;
  if not Item.TryGetValue<string>('pageTitle', PageTitle) then
    PageTitle := '';
  if Item.TryGetValue<TJSONArray>('fullMatchingImages', A) then
  begin
    SetLength(FullMatchingImages, A.Count);
    for c := 0 to A.Count - 1 do
      FullMatchingImages[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(FullMatchingImages, 0);
  if Item.TryGetValue<TJSONArray>('partialMatchingImages', A) then
  begin
    SetLength(PartialMatchingImages, A.Count);
    for c := 0 to A.Count - 1 do
      PartialMatchingImages[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(PartialMatchingImages, 0);
end;

procedure TWebPage.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
  c: integer;
begin
  Ind := StringOfChar(' ', Indent);
  s.Add(Format('%s"%s" URL: %s score %3.1f%%',
    [Ind, PageTitle, URL, Score * 100]));
  for c := 0 to length(FullMatchingImages) - 1 do
    s.Add(Format('%sFull matching image %d of %d: %s',
      [Ind, c + 1, length(FullMatchingImages), FullMatchingImages[c].AsStr]));
  for c := 0 to length(PartialMatchingImages) - 1 do
    s.Add(Format('%sPartial matching image %d of %d: %s',
      [Ind, c + 1, length(PartialMatchingImages),
       PartialMatchingImages[c].AsStr]));
end;

{ TWebLabel }

procedure TWebLabel.Init;
begin
  LabelText := '';
  LanguageCode := '';
end;

procedure TWebLabel.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<string>('label', LabelText) then
    LabelText := '';
  if not Item.TryGetValue<string>('languageCode', LanguageCode) then
    LanguageCode := '';
end;

function TWebLabel.AsStr: string;
begin
  if LabelText.IsEmpty then
    result := 'No label found'
  else if LanguageCode.IsEmpty then
    result := '"' + LabelText + '"'
  else
    result := Format('"%s" language %s',
      [LabelText, TFirebaseHelpers.GetLanguageInEnglishFromCode(LanguageCode)]);
end;

{ TWebDetection }

procedure TWebDetection.Init;
begin
  SetLength(WebEntities, 0);
  SetLength(FullMatchingImages, 0);
  SetLength(PartialMatchingImages, 0);
  SetLength(PagesWithMatchingImages, 0);
  SetLength(VisuallySimilarImages, 0);
  SetLength(BestGuessLabels, 0);
end;

procedure TWebDetection.SetFromJSON(Item: TJSONObject);
var
  A: TJSONArray;
  c: integer;
begin
  if Item.TryGetValue<TJSONArray>('webEntities', A) then
  begin
    SetLength(WebEntities, A.Count);
    for c := 0 to A.Count - 1 do
      WebEntities[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(WebEntities, 0);
  if Item.TryGetValue<TJSONArray>('fullMatchingImages', A) then
  begin
    SetLength(FullMatchingImages, A.Count);
    for c := 0 to A.Count - 1 do
      FullMatchingImages[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(FullMatchingImages, 0);
  if Item.TryGetValue<TJSONArray>('partialMatchingImages', A) then
  begin
    SetLength(PartialMatchingImages, A.Count);
    for c := 0 to A.Count - 1 do
      PartialMatchingImages[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(PartialMatchingImages, 0);
  if Item.TryGetValue<TJSONArray>('visuallySimilarImages', A) then
  begin
    SetLength(VisuallySimilarImages, A.Count);
    for c := 0 to A.Count - 1 do
      VisuallySimilarImages[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(VisuallySimilarImages, 0);
  if Item.TryGetValue<TJSONArray>('bestGuessLabels', A) then
  begin
    SetLength(BestGuessLabels, A.Count);
    for c := 0 to A.Count - 1 do
      BestGuessLabels[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(BestGuessLabels, 0);
end;

procedure TWebDetection.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
  c: integer;
begin
  Ind := StringOfChar(' ', Indent);
  if length(WebEntities) = 0 then
    s.Add(Ind + 'No web entities found')
  else
    for c := 0 to length(WebEntities) - 1 do
      s.Add(Format('%sFull matching image %d of %d: %s',
        [Ind, c + 1, length(WebEntities), WebEntities[c].AsStr]));
  for c := 0 to length(FullMatchingImages) - 1 do
    s.Add(Format('%sFull matching image %d of %d: %s',
      [Ind, c + 1, length(FullMatchingImages), FullMatchingImages[c].AsStr]));
  for c := 0 to length(PartialMatchingImages) - 1 do
    s.Add(Format('%sPartial matching image %d of %d: %s',
      [Ind, c + 1, length(PartialMatchingImages),
       PartialMatchingImages[c].AsStr]));
  for c := 0 to length(VisuallySimilarImages) - 1 do
    s.Add(Format('%sVisually similar image %d of %d: %s',
      [Ind, c + 1, length(VisuallySimilarImages),
       VisuallySimilarImages[c].AsStr]));
  for c := 0 to length(BestGuessLabels) - 1 do
    s.Add(Format('%sBest guess labels %d of %d: %s',
      [Ind, c + 1, length(BestGuessLabels),
       BestGuessLabels[c].AsStr]));
end;

{ TSafeSearchAnnotation }

procedure TSafeSearchAnnotation.Init;
begin
  AdultContent := TLikelihood.lhUnknown;
  Spoof := TLikelihood.lhUnknown;
  MedicalImage := TLikelihood.lhUnknown;
  ViolentContent := TLikelihood.lhUnknown;
  RacyContent := TLikelihood.lhUnknown;
end;

procedure TSafeSearchAnnotation.SetFromJSON(Item: TJSONObject);
var
  s: string;
begin
  if Item.TryGetValue<string>('adult', s) then
    AdultContent := ConvertLikelihood(s)
  else
    AdultContent := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('spoof', s) then
    Spoof := ConvertLikelihood(s)
  else
    Spoof := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('medical', s) then
    MedicalImage := ConvertLikelihood(s)
  else
    MedicalImage := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('violence', s) then
    ViolentContent := ConvertLikelihood(s)
  else
    ViolentContent := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('racy', s) then
    RacyContent := ConvertLikelihood(s)
  else
    RacyContent := TLikelihood.lhUnknown;
end;

procedure TSafeSearchAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
begin
  Ind := StringOfChar(' ', Indent);
  s.Add(Format('%sLikelihood for adult content: %s',
    [Ind, LikelihoodAsStr(AdultContent)]));
  s.Add(Format('%sLikelihood for spoofed (fake) content: %s',
    [Ind, LikelihoodAsStr(Spoof)]));
  s.Add(Format('%sLikelihood for medical image: %s',
    [Ind, LikelihoodAsStr(MedicalImage)]));
  s.Add(Format('%sLikelihood for violent content: %s',
    [Ind, LikelihoodAsStr(ViolentContent)]));
  s.Add(Format('%sLikelihood for racy content: %s',
    [Ind, LikelihoodAsStr(RacyContent)]));
end;

{ TFacePosition }

procedure TFacePosition.Init;
begin
  x := 0;
  y := 0;
  z := 0;
end;

procedure TFacePosition.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<double>('x', x) then
    x := 0;
  if not Item.TryGetValue<double>('y', y) then
    y := 0;
  if not Item.TryGetValue<double>('z', z) then
    z := 0;
end;

function TFacePosition.AsStr: string;
begin
  result := '[';
  if x > 0 then
    result := result + 'x: ' + FloatToStr(x);
  if y > 0 then
  begin
    if not result.EndsWith('[') then
      result := result + ',';
    result := result + 'y: ' + FloatToStr(y);
  end;
  if z > 0 then
  begin
    if not result.EndsWith('[') then
      result := result + ',';
    result := result + 'z: ' + FloatToStr(z);
  end;
  result := result + ']';
end;

{ TFaceLandmark }

procedure TFaceLandmark.Init;
begin
  FaceLandmarkType := TFaceLandmarkType.flmUnkown;
  Position.Init;
end;

procedure TFaceLandmark.SetFromJSON(Item: TJSONObject);
var
  s: string;
  O: TJSONObject;
begin
  if Item.TryGetValue<string>('type', s) then
  begin
    if SameText(s, 'LEFT_EYE') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEye
    else if SameText(s, 'RIGHT_EYE') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEye
    else if SameText(s, 'LEFT_OF_LEFT_EYEBROW') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftOfLeftEyeBrow
    else if SameText(s, 'RIGHT_OF_LEFT_EYEBROW') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightOfLeftEyeBrow
    else if SameText(s, 'LEFT_OF_RIGHT_EYEBROW') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftOfRightEyeBrow
    else if SameText(s, 'RIGHT_OF_RIGHT_EYEBROW') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightOfRightEyeBrow
    else if SameText(s, 'MIDPOINT_BETWEEN_EYES') then
    	FaceLandmarkType := TFaceLandmarkType.flmMidpointBetweenEyes
    else if SameText(s, 'NOSE_TIP') then
    	FaceLandmarkType := TFaceLandmarkType.flmNoseTip
    else if SameText(s, 'UPPER_LIP') then
    	FaceLandmarkType := TFaceLandmarkType.flmUpperLip
    else if SameText(s, 'LOWER_LIP') then
    	FaceLandmarkType := TFaceLandmarkType.flmLowerLip
    else if SameText(s, 'MOUTH_LEFT') then
    	FaceLandmarkType := TFaceLandmarkType.flmMouthLeft
    else if SameText(s, 'MOUTH_RIGHT') then
    	FaceLandmarkType := TFaceLandmarkType.flmMouthRight
    else if SameText(s, 'MOUTH_CENTER') then
    	FaceLandmarkType := TFaceLandmarkType.flmMouthCenter
    else if SameText(s, 'NOSE_BOTTOM_RIGHT') then
    	FaceLandmarkType := TFaceLandmarkType.flmNoseBottomRight
    else if SameText(s, 'NOSE_BOTTOM_LEFT') then
    	FaceLandmarkType := TFaceLandmarkType.flmNoseBottomLeft
    else if SameText(s, 'NOSE_BOTTOM_CENTER') then
    	FaceLandmarkType := TFaceLandmarkType.flmNoseBottomCenter
    else if SameText(s, 'LEFT_EYE_TOP_BOUNDARY') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEyeTopBoundary
    else if SameText(s, 'LEFT_EYE_RIGHT_CORNER') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEyeRightCorner
    else if SameText(s, 'LEFT_EYE_BOTTOM_BOUNDARY') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEyeBottomBoundary
    else if SameText(s, 'LEFT_EYE_LEFT_CORNER') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEyeLeftCorner
    else if SameText(s, 'RIGHT_EYE_TOP_BOUNDARY') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEyeTopBoundary
    else if SameText(s, 'RIGHT_EYE_RIGHT_CORNER') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEyeRightCorner
    else if SameText(s, 'RIGHT_EYE_BOTTOM_BOUNDARY') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEyeBottomBoundary
    else if SameText(s, 'RIGHT_EYE_LEFT_CORNER') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEyeLeftCorner
    else if SameText(s, 'LEFT_EYEBROW_UPPER_MIDPOINT') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEyebrowUpperMidpoint
    else if SameText(s, 'RIGHT_EYEBROW_UPPER_MIDPOINT') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEyebrowUpperMidpoint
    else if SameText(s, 'LEFT_EAR_TRAGION') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEarTragion
    else if SameText(s, 'RIGHT_EAR_TRAGION') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEarTragion
    else if SameText(s, 'LEFT_EYE_PUPIL') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftEyePupil
    else if SameText(s, 'RIGHT_EYE_PUPIL') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightEyePupil
    else if SameText(s, 'FOREHEAD_GLABELLA') then
    	FaceLandmarkType := TFaceLandmarkType.flmForeheadGlabella
    else if SameText(s, 'CHIN_GNATHION') then
    	FaceLandmarkType := TFaceLandmarkType.flmChinGnathion
    else if SameText(s, 'CHIN_LEFT_GONION') then
    	FaceLandmarkType := TFaceLandmarkType.flmChinLeftGonion
    else if SameText(s, 'CHIN_RIGHT_GONION') then
    	FaceLandmarkType := TFaceLandmarkType.flmChinRightGonion
    else if SameText(s, 'LEFT_CHEEK_CENTER') then
    	FaceLandmarkType := TFaceLandmarkType.flmLeftCheekCenter
    else if SameText(s, 'RIGHT_CHEEK_CENTER') then
    	FaceLandmarkType := TFaceLandmarkType.flmRightCheekCenter
    else
      FaceLandmarkType := TFaceLandmarkType.flmUnkown;
  end else
   FaceLandmarkType := TFaceLandmarkType.flmUnkown;
  if Item.TryGetValue<TJSONObject>('position', O) then
    Position.SetFromJSON(O)
  else
    Position.Init;
end;

procedure TFaceLandmark.AddStrings(s: TStrings; Indent: integer);
var
  FacePart: string;
  Ind: string;
begin
  Ind := StringOfChar(' ', Indent);
  FacePart := GetEnumName(TypeInfo(TFaceLandmarkType), ord(FaceLandmarkType)).
    Substring(3);
  s.Add(Format('%sFace landmark %s at %s',
    [Ind, FacePart, Position.AsStr]));
end;

{ TFaceAnnotation }

procedure TFaceAnnotation.Init;
begin
  BoundingPoly.Init;
  FaceDetectionBP.Init;
  SetLength(FaceLandmarks, 0);
  RollAngle := 0;
  PanAngle := 0;
  TiltAngle := 0;
  DetectionConfidence := 0;
  LandmarkingConfidence := 0;
  JoyLikelihood := TLikelihood.lhUnknown;
  SorrowLikelihood := TLikelihood.lhUnknown;
  AngerLikelihood := TLikelihood.lhUnknown;
  SurpriseLikelihood := TLikelihood.lhUnknown;
  UnderExposedLikelihood := TLikelihood.lhUnknown;
  BlurredLikelihood := TLikelihood.lhUnknown;
  HeadwearLikelihood := TLikelihood.lhUnknown;
end;

procedure TFaceAnnotation.SetFromJSON(Item: TJSONObject);
var
  s: string;
  O: TJSONObject;
  A: TJSONArray;
  c: integer;
begin
  if Item.TryGetValue<TJSONObject>('boundingPoly', O) then
    BoundingPoly.SetFromJSON(O)
  else
    BoundingPoly.Init;
  if Item.TryGetValue<TJSONObject>('fdBoundingPoly', O) then
    FaceDetectionBP.SetFromJSON(O)
  else
    FaceDetectionBP.Init;
  if Item.TryGetValue<TJSONArray>('landmarks', A) then
  begin
    SetLength(FaceLandmarks, A.Count);
    for c := 0 to A.Count - 1 do
      FaceLandmarks[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(FaceLandmarks, 0);
  if not Item.TryGetValue<double>('rollAngle', RollAngle) then
    RollAngle := 0;
  if not Item.TryGetValue<double>('panAngle', PanAngle) then
    PanAngle := 0;
  if not Item.TryGetValue<double>('tiltAngle', TiltAngle) then
    TiltAngle := 0;
  if not Item.TryGetValue<double>('detectionConfidence',
                                  DetectionConfidence) then
    DetectionConfidence := 0;
  if not Item.TryGetValue<double>('landmarkingConfidence',
                                  LandmarkingConfidence) then
    LandmarkingConfidence := 0;
  if Item.TryGetValue<string>('joyLikelihood', s) then
    JoyLikelihood := ConvertLikelihood(s)
  else
    JoyLikelihood := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('sorrowLikelihood', s) then
    SorrowLikelihood := ConvertLikelihood(s)
  else
    SorrowLikelihood := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('angerLikelihood', s) then
    AngerLikelihood := ConvertLikelihood(s)
  else
    AngerLikelihood := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('surpriseLikelihood', s) then
    SurpriseLikelihood := ConvertLikelihood(s)
  else
    SurpriseLikelihood := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('underExposedLikelihood', s) then
    UnderExposedLikelihood := ConvertLikelihood(s)
  else
    UnderExposedLikelihood := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('blurredLikelihood', s) then
    BlurredLikelihood := ConvertLikelihood(s)
  else
    BlurredLikelihood := TLikelihood.lhUnknown;
  if Item.TryGetValue<string>('headwearLikelihood', s) then
    HeadwearLikelihood := ConvertLikelihood(s)
  else
    HeadwearLikelihood := TLikelihood.lhUnknown;
end;

procedure TFaceAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
  c: integer;
begin
  Ind := StringOfChar(' ', Indent);
  s.Add(Format('%sFace detection confidence %3.1f%%',
    [Ind, DetectionConfidence * 100]));
  s.Add(Format('%sFace angles roll %d° pan/yaw %d° tilt/pitch %d°',
    [Ind, round(RollAngle), round(PanAngle), round(TiltAngle)]));
  BoundingPoly.AddStrings(s, Indent + 2);
  FaceDetectionBP.AddStrings(s, Indent + 2);
  s.Add(Format('%sLandmarking confidence %3.1f%%',
    [Ind, LandmarkingConfidence * 100]));
  for c := 0 to length(FaceLandmarks) - 1 do
    FaceLandmarks[c].AddStrings(s, Indent + 2);
  s.Add(Format('%sEmotions: joy %s, sorrow %s, anger %s, surprise %s',
    [Ind, LikelihoodAsStr(JoyLikelihood), LikelihoodAsStr(SorrowLikelihood),
     LikelihoodAsStr(AngerLikelihood), LikelihoodAsStr(SurpriseLikelihood)
     ]));
  s.Add(Format(
    '%sFace detection details: under exposed %s, blurred %s, head wear %s',
    [Ind, LikelihoodAsStr(UnderExposedLikelihood),
     LikelihoodAsStr(BlurredLikelihood), LikelihoodAsStr(HeadwearLikelihood)]));
end;

{ TLocalizedObjectAnnotation }

procedure TLocalizedObjectAnnotation.Init;
begin
  Id := '';
  LanguageCode := '';
  Name := '';
  Score := 0;
  BoundingPoly.Init;
end;

procedure TLocalizedObjectAnnotation.SetFromJSON(Item: TJSONObject);
var
  O: TJSONObject;
begin
  if not Item.TryGetValue<string>('mid', Id) then
    Id := '';
  if not Item.TryGetValue<string>('languageCode', LanguageCode) then
    LanguageCode := '';
  if not Item.TryGetValue<string>('name', Name) then
    Name := '';
  if not Item.TryGetValue<double>('score', Score) then
    Score := 0;
  if Item.TryGetValue<TJSONObject>('boundingPoly', O) then
    BoundingPoly.SetFromJSON(O)
  else
    BoundingPoly.Init;
end;

procedure TLocalizedObjectAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  v: string;
begin
  v := StringOfChar(' ', Indent) + '"' + Name + '"';
  if not LanguageCode.IsEmpty then
    v := v + ' language ' +
      TFirebaseHelpers.GetLanguageInEnglishFromCode(LanguageCode);
  if Score > 0 then
    v := Format('%s score %3.1f%%', [v, Score * 100]);
  if not Id.IsEmpty then
    v := Format('%s (mid: %s)', [v,Id]);
  s.Add(v);
  BoundingPoly.AddStrings(s, Indent + 2);
end;

{ TKeyValue }

procedure TKeyValue.Init;
begin
  Key := '';
  Value := '';
end;

procedure TKeyValue.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<string>('key', Key) then
    Key := '';
  if not Item.TryGetValue<string>('mid', Value) then
    Value := '';
end;

function TKeyValue.AsStr: string;
begin
  result := '"' + Key + '"= ' + Value;
end;

{ TProduct }

procedure TProduct.Init;
begin
  Name := '';
  DisplayName := '';
  Description := '';
  ProductCategory := '';
  SetLength(ProductLabels, 0);
end;

procedure TProduct.SetFromJSON(Item: TJSONObject);
var
  A: TJSONArray;
  c: integer;
begin
  if not Item.TryGetValue<string>('name', Name) then
    Name := '';
  if not Item.TryGetValue<string>('displayName', DisplayName) then
    DisplayName := '';
  if not Item.TryGetValue<string>('description', Description) then
    Description := '';
  if not Item.TryGetValue<string>('productCategory', ProductCategory) then
    ProductCategory := '';
  if Item.TryGetValue<TJSONArray>('productLabels', A) then
  begin
    SetLength(ProductLabels, A.Count);
    for c := 0 to A.Count - 1 do
      ProductLabels[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(ProductLabels, 0);
end;

procedure TProduct.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
  c: integer;
begin
  Ind := StringOfChar(' ', Indent);
  s.Add(Ind + 'Product "' + DisplayName + '"');
  if not Name.IsEmpty then
    s.Add(Ind + 'Name: ' + Name);
  if not Description.IsEmpty then
    s.Add(Ind + 'Description: ' + Description);
  if not ProductCategory.IsEmpty then
    s.Add(Ind + 'Product category: ' + ProductCategory);
  for c := 0 to length(ProductLabels) - 1 do
    s.Add(Format('%sLabel %d of %d: %s',
      [Ind, c + 1, length(ProductLabels), ProductLabels[c].AsStr]));
end;

{ TProductResult }

procedure TProductResult.Init;
begin
  Product.Init;
  Score := 0;
  Image := '';
end;

procedure TProductResult.SetFromJSON(Item: TJSONObject);
var
  O: TJSONObject;
begin
  if Item.TryGetValue<TJSONObject>('product', O) then
    Product.SetFromJSON(O)
  else
    Product.Init;
  if not Item.TryGetValue<double>('score', Score) then
    Score := 0;
  if not Item.TryGetValue<string>('image', Image) then
    Image := '';
end;

procedure TProductResult.AddStrings(s: TStrings; Indent: integer);
var
  Ind: string;
begin
  Ind := StringOfChar(' ', Indent);
  Product.AddStrings(s, Indent);
  if not Image.IsEmpty then
    s.Add(Format('%simage %s', [Ind, Image]));
  if Score > 0 then
    s.Add(Format('%sscore %3.1f%%', [Ind, Score * 100]));
end;

{ TObjectAnnotation }

procedure TObjectAnnotation.Init;
begin
  Id := '';
  LanguageCode := '';
  Name := '';
  Score := 0;
end;

procedure TObjectAnnotation.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<string>('mid', Id) then
    Id := '';
  if not Item.TryGetValue<string>('languageCode', LanguageCode) then
    LanguageCode := '';
  if not Item.TryGetValue<string>('name', Name) then
    Name := '';
  if not Item.TryGetValue<double>('score', Score) then
    Score := 0;
end;

procedure TObjectAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  v: string;
begin
  v := StringOfChar(' ', Indent) + '"' + Name + '"';
  if not LanguageCode.IsEmpty then
    v := v + ' language ' +
      TFirebaseHelpers.GetLanguageInEnglishFromCode(LanguageCode);
  if Score > 0 then
    v := Format('%s score %3.1f%%', [v, Score * 100]);
  if not Id.IsEmpty then
    v := Format('%s (mid: %s)', [v,Id]);
  s.Add(v);
end;

{ TGroupedProductResult }

procedure TGroupedProductResult.Init;
begin
  BoundingPoly.Init;
  SetLength(ProductResults, 0);
  SetLength(ObjectAnnotations, 0);
end;

procedure TGroupedProductResult.SetFromJSON(Item: TJSONObject);
var
  O: TJSONObject;
  A: TJSONArray;
  c: integer;
begin
  if Item.TryGetValue<TJSONObject>('boundingPoly', O) then
    BoundingPoly.SetFromJSON(O)
  else
    BoundingPoly.Init;
  if Item.TryGetValue<TJSONArray>('results', A) then
  begin
    SetLength(ProductResults, A.Count);
    for c := 0 to A.Count - 1 do
      ProductResults[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(ProductResults, 0);
  if Item.TryGetValue<TJSONArray>('objectAnnotations', A) then
  begin
    SetLength(ObjectAnnotations, A.Count);
    for c := 0 to A.Count - 1 do
      ObjectAnnotations[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(ObjectAnnotations, 0);
end;

procedure TGroupedProductResult.AddStrings(s: TStrings; Indent: integer);
var
  c: integer;
  Ind: string;
begin
  Ind := StringOfChar(' ', Indent);
  BoundingPoly.AddStrings(s, Indent);
  for c := 0 to length(ProductResults) - 1 do
  begin
    s.Add(Format('%sProduct %d of %d', [Ind, c + 1, length(ProductResults)]));
    ProductResults[c].AddStrings(s, Indent + 2);
  end;
  for c := 0 to length(ObjectAnnotations) - 1 do
  begin
    s.Add(Format('%sObject annotation %d of %d',
      [Ind, c + 1, length(ObjectAnnotations)]));
    ObjectAnnotations[c].AddStrings(s, Indent + 2);
  end;
end;

{ TProductSearchAnnotation }

procedure TProductSearchAnnotation.Init;
begin
  IndexTime := 0;
  SetLength(ProductResults, 0);
  SetLength(GroupedProductResults, 0);
end;

procedure TProductSearchAnnotation.SetFromJSON(Item: TJSONObject);
var
  s: string;
  A: TJSONArray;
  c: integer;
begin
  if Item.TryGetValue<string>('indexTime', s) then
    IndexTime := TFirebaseHelpers.DecodeRFC3339DateTime(s)
  else
    IndexTime := 0;
  if Item.TryGetValue<TJSONArray>('results', A) then
  begin
    SetLength(ProductResults, A.Count);
    for c := 0 to A.Count - 1 do
      ProductResults[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(ProductResults, 0);
  if Item.TryGetValue<TJSONArray>('productGroupedResults', A) then
  begin
    SetLength(GroupedProductResults, A.Count);
    for c := 0 to A.Count - 1 do
      GroupedProductResults[c].SetFromJSON(A[c] as TJSONObject);
  end else
    SetLength(GroupedProductResults, 0);
end;

procedure TProductSearchAnnotation.AddStrings(s: TStrings; Indent: integer);
var
  c: integer;
  Ind: string;
begin
  Ind := StringOfChar(' ', Indent);
  if (IndexTime = 0) and (length(ProductResults) = 0) and
     (length(GroupedProductResults) = 0) then
    s.Add(Ind + 'No products found')
  else begin
    if IndexTime > 0 then
      s.Add(Ind + 'Index time stamp ' + DateTimeToStr(IndexTime));
    for c := 0 to length(ProductResults) - 1 do
    begin
      s.Add(Format('%sProduct %d of %d', [Ind, c + 1, length(ProductResults)]));
      ProductResults[c].AddStrings(s, Indent + 2);
    end;
    for c := 0 to length(GroupedProductResults) - 1 do
    begin
      s.Add(Format('%sGrouped product %d of %d',
        [Ind, c + 1, length(GroupedProductResults)]));
      GroupedProductResults[c].AddStrings(s, Indent + 2);
    end;
  end;
end;

{ TImageAnnotationContext }

procedure TImageAnnotationContext.Init;
begin
  URI := '';
  PageNumber := 0;
end;

procedure TImageAnnotationContext.SetFromJSON(Item: TJSONObject);
begin
  if not Item.TryGetValue<string>('uri', URI) then
    URI := '';
  PageNumber := Item.GetValue<integer>('pageNumber');
end;

procedure TImageAnnotationContext.AddStrings(s: TStrings; Indent: integer);
begin
  s.Add(StringOfChar(' ', Indent) + 'Page number: ' + PageNumber.ToString);
  if not URI.IsEmpty then
    s.Add(StringOfChar(' ', Indent) + 'URI: ' + URI);
end;

end.
