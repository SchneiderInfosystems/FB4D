{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2025 Christoph Schneider                                 }
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

unit FB4D.VisionML;

interface

uses
  System.Classes, System.JSON, System.SysUtils, System.SyncObjs,
  System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  REST.Types,
  FB4D.Interfaces, FB4D.Response, FB4D.Request, FB4D.VisionMLDefinition;

type
  TVisionML = class(TInterfacedObject, IVisionML)
  private
    fProjectID: string;
    fApiKey: string;
    fServerRegion: string;
    fAuth: IFirebaseAuthentication;
    function BaseURL: string;
    function GetFeaturesJSONArr(Features: TVisionMLFeatures;
      MaxResults: integer; Model: TVisionModel): TJSONArray;
    procedure OnGetResponse(const RequestID: string;
      Response: IFirebaseResponse);
  public
    constructor Create(const ProjectID, ApiKey: string;
      Auth: IFirebaseAuthentication = nil;
      const ServerRegion: string = cRegionUSCent1);
    function AnnotateFileSynchronous(const FileAsBase64,
      ContentType: string; Features: TVisionMLFeatures;
      MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable): IVisionMLResponse;
    procedure AnnotateFile(const FileAsBase64,
      ContentType: string; Features: TVisionMLFeatures;
      OnAnnotate: TOnAnnotate; OnAnnotateError: TOnRequestError;
      const RequestID: string = ''; MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable);
    function AnnotateStorageSynchronous(const RefStorageCloudURI,
      ContentType: string; Features: TVisionMLFeatures;
      MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable): IVisionMLResponse;
    procedure AnnotateStorage(const RefStorageCloudURI,
      ContentType: string; Features: TVisionMLFeatures;
      OnAnnotate: TOnAnnotate; OnAnnotateError: TOnRequestError;
      MaxResultsPerFeature: integer = 50;
      Model: TVisionModel = vmStable);
  end;

  TVisionMLResponse = class(TInterfacedObject, IVisionMLResponse)
  private
    fResp: TJSONObject;
    fPages: TList<TJSONObject>;
    function GetAnnotations(PageNo: integer;
      const AnnotationName: string): TAnnotationList;
  public
    constructor Create(Response: IFirebaseResponse);
    destructor Destroy; override;
    function GetFormatedJSON: string;
    function GetNoPages: integer;
    function GetError(PageNo: integer = 0): TErrorStatus;
    function GetPageAsFormatedJSON(PageNo: integer = 0): string;
    function LabelAnnotations(PageNo: integer = 0): TAnnotationList;
    function LandmarkAnnotations(PageNo: integer = 0): TAnnotationList;
    function LogoAnnotations(PageNo: integer = 0): TAnnotationList;
    function TextAnnotations(PageNo: integer = 0): TAnnotationList;
    function FullTextAnnotations(PageNo: integer = 0): TTextAnnotation;
    function ImagePropAnnotation(
      PageNo: integer = 0): TImagePropertiesAnnotation;
    function CropHintsAnnotation(PageNo: integer = 0): TCropHintsAnnotation;
    function WebDetection(PageNo: integer  = 0): TWebDetection;
    function SafeSearchAnnotation(PageNo: integer  = 0): TSafeSearchAnnotation;
    function FaceAnnotation(PageNo: integer  = 0): TFaceAnnotationList;
    function LocalizedObjectAnnotation(
      PageNo: integer = 0): TLocalizedObjectList;
    function ProductSearchAnnotation(
      PageNo: integer = 0): TProductSearchAnnotation;
    function ImageAnnotationContext(
      PageNo: integer = 0): TImageAnnotationContext;
  end;

implementation

uses
  REST.Json,
  FB4D.Helpers;

{ TVisionML }

const
  VISION_API = 'https://vision.googleapis.com/v1';

resourcestring
  rsFunctionCall = 'Function call %s';
  rsUnexpectedResult = 'Unexpected result received: %s';

function TVisionML.BaseURL: string;
begin
  result := VISION_API;
end;

constructor TVisionML.Create(const ProjectID, ApiKey: string;
  Auth: IFirebaseAuthentication; const ServerRegion: string);
begin
  fProjectID := ProjectID;
  fApiKey := ApiKey;
  fServerRegion := ServerRegion;
  fAuth := Auth;
end;

function TVisionML.GetFeaturesJSONArr(Features: TVisionMLFeatures;
  MaxResults: integer; Model: TVisionModel): TJSONArray;

  function FeatureAsStr(Feature: TVisionMLFeature): string;
  begin
    case Feature of
      vmlUnspecific:
        result := 'TYPE_UNSPECIFIED';
      vmlFaceDetection:
        result := 'FACE_DETECTION';
      vmlLandmarkDetection:
        result := 'LANDMARK_DETECTION';
      vmlLogoDetection:
        result := 'LOGO_DETECTION';
      vmlLabelDetection:
        result := 'LABEL_DETECTION';
      vmlTextDetection:
        result := 'TEXT_DETECTION';
      vmlDocTextDetection:
        result := 'DOCUMENT_TEXT_DETECTION';
      vmlSafeSearchDetection:
        result := 'SAFE_SEARCH_DETECTION';
      vmlImageProperties:
        result := 'IMAGE_PROPERTIES';
      vmlCropHints:
        result := 'CROP_HINTS';
      vmlWebDetection:
        result := 'WEB_DETECTION';
      vmlProductSearch:
        result := 'PRODUCT_SEARCH';
      vmlObjectLocalization:
        result := 'OBJECT_LOCALIZATION';
      else
        raise EVisionML.Create('Unknown feature ' + ord(Feature).ToString);
    end;
  end;

  function ModelAsStr: string;
  begin
    case Model of
      vmStable:
        result := 'builtin/stable';
      vmLatest:
        result := 'builtin/latest';
      else
        result := '';
    end;
  end;

var
  Feature: TVisionMLFeature;
begin
  result := TJSONArray.Create;
  for Feature in Features do
    if Model = vmUnset then
      result.Add(TJSONObject.Create
        .AddPair(TJSONPair.Create('type', FeatureAsStr(Feature)))
        .AddPair(TJSONPair.Create('maxResults', TJSONNumber.Create(MaxResults))))
    else
      result.Add(TJSONObject.Create
        .AddPair(TJSONPair.Create('type', FeatureAsStr(Feature)))
        .AddPair(TJSONPair.Create('maxResults', TJSONNumber.Create(MaxResults)))
        .AddPair(TJSONPair.Create('model', ModelAsStr)));
end;

function TVisionML.AnnotateFileSynchronous(const FileAsBase64,
  ContentType: string; Features: TVisionMLFeatures;
  MaxResultsPerFeature: integer; Model: TVisionModel): IVisionMLResponse;
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL, 'Vision ML Annotate');
    Body.AddPair('requests',
      TJSONArray.Create(
        TJSONObject.Create
          .AddPair('inputConfig',
            TJSONObject.Create
              .AddPair('content', FileAsBase64)
              .AddPair('mimeType', ContentType))
          .AddPair('features',
            GetFeaturesJSONArr(Features, MaxResultsPerFeature, Model))));
    Params.Add('key', [fApiKey]);
    result := TVisionMLResponse.Create(Request.SendRequestSynchronous(
      ['files:annotate'], rmPost, Body, Params, tmNoToken));
  finally
    Params.Free;
    Body.Free;
  end;
end;

procedure TVisionML.AnnotateFile(const FileAsBase64, ContentType: string;
  Features: TVisionMLFeatures; OnAnnotate: TOnAnnotate;
  OnAnnotateError: TOnRequestError; const RequestID: string;
  MaxResultsPerFeature: integer; Model: TVisionModel);
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL, RequestID);
    Body.AddPair('requests',
      TJSONArray.Create(
        TJSONObject.Create
          .AddPair('inputConfig',
            TJSONObject.Create
              .AddPair('content', FileAsBase64)
              .AddPair('mimeType', ContentType))
          .AddPair('features',
            GetFeaturesJSONArr(Features, MaxResultsPerFeature, Model))));
    Params.Add('key', [fApiKey]);
    Request.SendRequest(['files:annotate'], rmPost, Body, Params, tmNoToken,
      OnGetResponse, OnAnnotateError, TOnSuccess.CreateVisionML(OnAnnotate));
  finally
    Params.Free;
    Body.Free;
  end;
end;

procedure TVisionML.OnGetResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Res: IVisionMLResponse;
begin
  try
    Res := TVisionMLResponse.Create(Response);
    if assigned(Response.OnSuccess.OnAnnotate) then
      Response.OnSuccess.OnAnnotate(Res);
  except
    on e: Exception do
    begin
      if assigned(Response.OnError) then
        Response.OnError(RequestID, e.Message)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn,
          ['VisionML.OnGetResponse', RequestID, e.Message]);
    end;
  end;
end;

function TVisionML.AnnotateStorageSynchronous(const RefStorageCloudURI,
  ContentType: string; Features: TVisionMLFeatures;
  MaxResultsPerFeature: integer; Model: TVisionModel): IVisionMLResponse;
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL, 'Vision ML Annotate');
    Body.AddPair('requests',
      TJSONArray.Create(
        TJSONObject.Create
          .AddPair('inputConfig',
            TJSONObject.Create
              .AddPair('gcsSource',
                TJSONObject.Create(TJSONPair.Create('uri', RefStorageCloudURI)))
              .AddPair('mimeType', ContentType))
          .AddPair('features',
            GetFeaturesJSONArr(Features, MaxResultsPerFeature, Model))));
    Params.Add('key', [fApiKey]);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log('Storage.annotate: ' + Body.ToJSON);
    {$ENDIF}
    result := TVisionMLResponse.Create(Request.SendRequestSynchronous(
      ['files:annotate'], rmPost, Body, Params, tmBearer));
  finally
    Params.Free;
    Body.Free;
  end;
end;

procedure TVisionML.AnnotateStorage(const RefStorageCloudURI,
  ContentType: string; Features: TVisionMLFeatures; OnAnnotate: TOnAnnotate;
  OnAnnotateError: TOnRequestError; MaxResultsPerFeature: integer;
  Model: TVisionModel);
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
  Body: TJSONObject;
begin
  Body := TJSONObject.Create;
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL, RefStorageCloudURI);
    Body.AddPair('requests',
      TJSONArray.Create(
        TJSONObject.Create
          .AddPair('inputConfig',
            TJSONObject.Create
              .AddPair('gcsSource',
                TJSONObject.Create(TJSONPair.Create('uri', RefStorageCloudURI)))
              .AddPair('mimeType', ContentType))
          .AddPair('features',
            GetFeaturesJSONArr(Features, MaxResultsPerFeature, Model))));
    Params.Add('key', [fApiKey]);
    {$IFDEF DEBUG}
    TFirebaseHelpers.Log('Storage.annotate: ' + Body.ToJSON);
    {$ENDIF}
    Request.SendRequest(['files:annotate'], rmPost, Body, Params, tmNoToken,
      OnGetResponse, OnAnnotateError, TOnSuccess.CreateVisionML(OnAnnotate));
  finally
    Params.Free;
    Body.Free;
  end;
end;

{ TVisionMLResponse }

constructor TVisionMLResponse.Create(Response: IFirebaseResponse);
var
  Responses, Pages: TJSONArray;
  MainResp: TJSONObject;
  c: cardinal;
begin
  fPages := TList<TJSONObject>.Create;
  Response.CheckForJSONObj;
  fResp := Response.GetContentAsJSONObj;
  Responses := fResp.GetValue('responses') as TJSONArray;
  if Responses.Count <> 1 then
    raise EVisionML.CreateFmt(
      'ML Vision does not return one object as expected, but %d',
      [Responses.Count]);
  MainResp := Responses.Items[0] as TJSONObject;
  Pages := MainResp.GetValue('responses') as TJSONArray;
  for c := 0 to Pages.Count - 1 do
    fPages.Add(Pages.Items[c].AsType<TJSONObject>);
end;

destructor TVisionMLResponse.Destroy;
begin
  fResp.Free;
  fPages.Free;
  inherited;
end;

function TVisionMLResponse.GetFormatedJSON: string;
begin
  result := fResp.Format;
end;

function TVisionMLResponse.GetNoPages: integer;
begin
  result := fPages.Count;
end;

function TVisionMLResponse.GetPageAsFormatedJSON(PageNo: integer): string;
begin
  result := '';
  if PageNo < fPages.Count then
    result := fPages[PageNo].Format;
end;

function TVisionMLResponse.GetError(PageNo: integer): TErrorStatus;
var
  Error: TJSONObject;
begin
  result.Init;
  if PageNo < fPages.Count then
    if fPages[PageNo].TryGetValue<TJSONObject>('error', Error) then
      result.SetFromJSON(Error);
end;

function TVisionMLResponse.GetAnnotations(PageNo: integer;
  const AnnotationName: string): TAnnotationList;
var
  L: TJSONArray;
  c: cardinal;
begin
  SetLength(result, 0);
  if PageNo < fPages.Count then
  begin
    if fPages[PageNo].TryGetValue<TJSONArray>(AnnotationName, L) then
    begin
      SetLength(result, L.Count);
      for c := 0 to L.Count - 1 do
        result[c].SetFromJSON(L.Items[c] as TJSONObject);
    end;
  end;
end;

function TVisionMLResponse.LabelAnnotations(PageNo: integer): TAnnotationList;
begin
  result := GetAnnotations(PageNo, 'labelAnnotations');
end;

function TVisionMLResponse.LandmarkAnnotations(PageNo: integer): TAnnotationList;
begin
  result := GetAnnotations(PageNo, 'landmarkAnnotations');
end;

function TVisionMLResponse.LogoAnnotations(PageNo: integer): TAnnotationList;
begin
  result := GetAnnotations(PageNo, 'logoAnnotations');
end;

function TVisionMLResponse.TextAnnotations(PageNo: integer): TAnnotationList;
begin
  result := GetAnnotations(PageNo, 'textAnnotations');
end;

function TVisionMLResponse.FaceAnnotation(PageNo: integer): TFaceAnnotationList;
var
  A: TJSONArray;
  c: cardinal;
begin
  SetLength(result, 0);
  if (PageNo < fPages.Count) and fPages[PageNo].
     TryGetValue<TJSONArray>('faceAnnotations', A) then
  begin
    SetLength(result, A.Count);
    for c := 0 to A.Count - 1 do
      result[c].SetFromJSON(A.Items[c] as TJSONObject);
  end;
end;

function TVisionMLResponse.LocalizedObjectAnnotation(
  PageNo: integer): TLocalizedObjectList;
var
  A: TJSONArray;
  c: cardinal;
begin
  SetLength(result, 0);
  if (PageNo < fPages.Count) and fPages[PageNo].
     TryGetValue<TJSONArray>('localizedObjectAnnotations', A) then
  begin
    SetLength(result, A.Count);
    for c := 0 to A.Count - 1 do
      result[c].SetFromJSON(A.Items[c] as TJSONObject);
  end;
end;

function TVisionMLResponse.FullTextAnnotations(PageNo: integer): TTextAnnotation;
var
  O: TJSONObject;
begin
  result.Init;
  if (PageNo < fPages.Count) and
     fPages[PageNo].TryGetValue<TJSONObject>('fullTextAnnotation', O) then
    result.SetFromJSON(O);
end;

function TVisionMLResponse.ImagePropAnnotation(
  PageNo: integer): TImagePropertiesAnnotation;
var
  O: TJSONObject;
begin
  result.Init;
  if (PageNo < fPages.Count) and fPages[PageNo].TryGetValue<TJSONObject>(
     'imagePropertiesAnnotation', O) then
    result.SetFromJSON(O);
end;

function TVisionMLResponse.CropHintsAnnotation(
  PageNo: integer): TCropHintsAnnotation;
var
  O: TJSONObject;
begin
  result.Init;
  if (PageNo < fPages.Count) and
     fPages[PageNo].TryGetValue<TJSONObject>('cropHintsAnnotation', O) then
    result.SetFromJSON(O);
end;

function TVisionMLResponse.WebDetection(PageNo: integer): TWebDetection;
var
  O: TJSONObject;
begin
  result.Init;
  if (PageNo < fPages.Count) and
     fPages[PageNo].TryGetValue<TJSONObject>('webDetection', O) then
    result.SetFromJSON(O);
end;

function TVisionMLResponse.SafeSearchAnnotation(
  PageNo: integer): TSafeSearchAnnotation;
var
  O: TJSONObject;
begin
  result.Init;
  if (PageNo < fPages.Count) and
     fPages[PageNo].TryGetValue<TJSONObject>('safeSearchAnnotation', O) then
    result.SetFromJSON(O);
end;

function TVisionMLResponse.ProductSearchAnnotation(
  PageNo: integer): TProductSearchAnnotation;
var
  O: TJSONObject;
begin
  result.Init;
  if (PageNo < fPages.Count) and
     fPages[PageNo].TryGetValue<TJSONObject>('productSearchResults', O) then
    result.SetFromJSON(O);
end;

function TVisionMLResponse.ImageAnnotationContext(
  PageNo: integer): TImageAnnotationContext;
var
  O: TJSONObject;
begin
  result.Init;
  if (PageNo < fPages.Count) and
     fPages[PageNo].TryGetValue<TJSONObject>('context', O) then
    result.SetFromJSON(O);
end;

end.
