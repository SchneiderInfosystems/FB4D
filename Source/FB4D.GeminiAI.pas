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

unit FB4D.GeminiAI;

interface

uses
  System.Classes, System.Types, System.JSON, System.SysUtils, System.SyncObjs,
  System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  REST.Types,
  {$IFDEF MARKDOWN2HTML}
  MarkdownProcessor,
  {$ENDIF}
  FB4D.Interfaces, FB4D.Response, FB4D.Request;

type
  TGeminiAI = class(TInterfacedObject, IGeminiAI)
  private const
    cModels = 'models/';
  private
    fApiKey: string;
    fAPIVersion: string;
    fModel: string;
    fModelDetails: TDictionary<string, TGeminiModelDetails>;
    function BaseURL(IncludingModel: boolean): string;
    procedure OnFetchModelsResponse(const RequestID: string; Response: IFirebaseResponse);
    procedure OnFetchModelsErrorResp(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
    procedure OnFetchModelDetailResponse(const RequestID: string; Response: IFirebaseResponse);
    procedure OnFetchModelDetailErrorResp(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
    procedure OnGenerateContentResponse(const RequestID: string; Response: IFirebaseResponse);
    procedure OnGenerateContentError(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
    procedure OnCountTokenResponse(const RequestID: string; Response: IFirebaseResponse);
    procedure OnCountTokenError(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
    function CreateBodyByPrompt(const Prompt: string): TJSONObject;
    function GenerateContentSynchronous(Body: TJSONObject): IGeminiAIResponse;
    procedure GenerateContent(Body: TJSONObject; OnResponse: TOnGeminiGenContent);
    function CountTokenSynchronous(Body: TJSONObject; out ErrorMsg: string;
      out CachedContentToken: integer): integer;
    procedure CountToken(Body: TJSONObject; OnResponse: TOnGeminiCountToken);
    function GetModulDetails(Model: TJSONObject): TGeminiModelDetails;
  public
    constructor Create(const ApiKey: string; const Model: string = cGeminiAIDefaultModel;
      APIVersion: TGeminiAPIVersion = cDefaultGeminiAPIVersion);
    destructor Destroy; override;

    class procedure SetListOfAPIVersions(s: TStrings);
    procedure SetAPIVersion(APIVersion: TGeminiAPIVersion);

    procedure FetchListOfModelsSynchronous(ModelNames: TStrings);
    procedure FetchListOfModels(OnFetchModels: TOnGeminiFetchModels);

    function FetchModelDetailsSynchronous(const ModelName: string): TGeminiModelDetails;
    procedure FetchModelDetails(const ModelName: string; OnFetchModelDetail: TOnGeminiFetchModel);

    procedure SetModel(const ModelName: string);

    function GenerateContentByPromptSynchronous(const Prompt: string): IGeminiAIResponse;
    procedure GenerateContentByPrompt(const Prompt: string; OnResponse: TOnGeminiGenContent);

    function GenerateContentByRequestSynchronous(GeminiAIRequest: IGeminiAIRequest): IGeminiAIResponse;
    procedure GenerateContentByRequest(GeminiAIRequest: IGeminiAIRequest; OnResponse: TOnGeminiGenContent);

    procedure CountTokenOfPrompt(const Prompt: string; OnResponse: TOnGeminiCountToken);
    function CountTokenOfPromptSynchronous(const Prompt: string; out ErrorMsg: string;
      out CachedContentToken: integer): integer;

    procedure CountTokenOfRequest(GeminiAIRequest: IGeminiAIRequest; OnResponse: TOnGeminiCountToken);
    function CountTokenOfRequestSynchronous(GeminiAIRequest: IGeminiAIRequest; out ErrorMsg: string;
      out CachedContentToken: integer): integer;
  end;

  TGeminiSchema = class(TInterfacedObject, IGeminiSchema)
  private
    fSchema: TJSONObject;
    function GetJSONObject: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;
    function SetStringType: IGeminiSchema;
    function SetFloatType: IGeminiSchema;
    function SetIntegerType: IGeminiSchema;
    function SetBooleanType: IGeminiSchema;
    function SetEnumType(EnumValues: TStringDynArray): IGeminiSchema;
    function SetArrayType(ArrayElement: IGeminiSchema; MinItems: integer = -1; MaxItems: integer = -1): IGeminiSchema;
    function SetObjectType(RequiredItems: TSchemaItems; OptionalItems: TSchemaItems = nil): IGeminiSchema;
    function SetDescription(const Description: string): IGeminiSchema;
    function SetNullable(IsNullable: boolean): IGeminiSchema;
    // Class helpers
    class function StringType: IGeminiSchema;
    class function FloatType: IGeminiSchema;
    class function IntegerType: IGeminiSchema;
    class function BooleanType: IGeminiSchema;
    class function EnumType(EnumValues: TStringDynArray): IGeminiSchema;
    class function ArrayType(ArrayElement: IGeminiSchema; MinItems: integer = -1; MaxItems: integer = -1): IGeminiSchema;
    class function ObjectType(RequiredItems: TSchemaItems; OptionalItems: TSchemaItems = nil): IGeminiSchema;
  end;

  TGeminiAIRequest = class(TInterfacedObject, IGeminiAIRequest)
  private
    fRequest: TJSONObject;
    fContents: TJSONArray;
    fParts: TJSONArray;
    fGenerationConfig: TJSONObject;
    fSavetySettings: TJSONArray;
    fTools: TJSONArray;
    function AsJSON: TJSONObject;
    procedure CheckAndCreateGenerationConfig;
    procedure CheckAndCreateTools;
  public
    constructor Create;
    destructor Destroy; override;
    function CloneWithoutCfgAndSettings(Request: IGeminiAIRequest): IGeminiAIRequest;
    function Prompt(const PromptText: string): IGeminiAIRequest;
    function PromptWithMediaData(const PromptText, MimeType: string;
      MediaStream: TStream): IGeminiAIRequest;
    {$IF CompilerVersion >= 35} // Delphi 11 and later
    {$IF Defined(FMX) OR Defined(FGX)}
    function PromptWithImgData(const PromptText: string;
      ImgStream: TStream): IGeminiAIRequest;
    {$ENDIF}
    {$ENDIF}
    function ModelParameter(Temperature, TopP: double; MaxOutputTokens,
      TopK: cardinal): IGeminiAIRequest;
    function SetStopSequences(StopSequences: TStrings): IGeminiAIRequest;
    function SetSafety(HarmCat: THarmCategory; LevelToBlock: TSafetyBlockLevel): IGeminiAIRequest;
    function SetJSONResponseSchema(Schema: IGeminiSchema): IGeminiAIRequest;
    procedure AddGroundingByGoogleSearch(Threshold: double);
    procedure AddAnswerForNextRequest(const ResultAsMarkDown: string);
    procedure AddQuestionForNextRequest(const PromptText: string);
  public
    class function SafetyBlockLevelToStr(sbl: TSafetyBlockLevel): string;
  end;

  TGeminiResponse = class(TInterfacedObject, IGeminiAIResponse)
  private
    fContentResponse: TJSONObject;
    fUsageMetaData: TGeminiAIUsageMetaData;
    fResultState: TGeminiAIResultState;
    fFailureDetail: string;
    fResults: array of TGeminiAIResult;
    fFinishReasons: TGeminiAIFinishReasons;
    fModelVersion: string;
    procedure EvaluateResults;
    constructor CreateError(const RequestID, ErrMsg: string);
    function ConvertMarkDownToHTML(const MarkDown: string): string;
  public
    constructor Create(Response: IFirebaseResponse);
    destructor Destroy; override;
    function ResultAsMarkDown: string;
    function ResultAsHTML: string;
    function ResultAsJSON: TJSONValue;
    function NumberOfResults: integer; // Candidates
    function EvalResult(ResultIndex: integer): TGeminiAIResult;
    function UsageMetaData: TGeminiAIUsageMetaData;
    function ResultState: TGeminiAIResultState;
    function ResultStateStr: string;
    function FinishReasons: TGeminiAIFinishReasons;
    function FinishReasonsCommaSepStr: string;
    function IsValid: boolean;
    function FailureDetail: string;
    function ModelVersion: string;
    function RawFormatedJSONResult: string;
    function RawJSONResult: TJSONValue;
    class function HarmCategoryToStr(hc: THarmCategory): string;
    class function HarmCategoryFromStr(const txt: string): THarmCategory;
  end;

implementation

uses
  System.RTTI, System.NetEncoding,
  FB4D.Helpers;

const
  GEMINI_API = 'https://generativelanguage.googleapis.com/%s/models';
  GEMINI_API_4Model = GEMINI_API + '/%s';

{ TGemini }

constructor TGeminiAI.Create(const ApiKey, Model: string; APIVersion: TGeminiAPIVersion);
begin
  fModelDetails := TDictionary<string, TGeminiModelDetails>.Create;
  fApiKey := ApiKey;
  fModel := Model;
  SetAPIVersion(APIVersion);
end;

destructor TGeminiAI.Destroy;
begin
  fModelDetails.Free;
  inherited;
end;

procedure TGeminiAI.SetAPIVersion(APIVersion: TGeminiAPIVersion);
begin
  case APIVersion of
    V1:
      fAPIVersion := 'v1';
    V1BETA:
      fAPIVersion := 'v1beta';
    else
      raise EGeminiAIRequest.CreateFmt('API version %s is currently not implemented',
        [TRttiEnumerationType.GetName(APIVersion)]);
  end;
end;

class procedure TGeminiAI.SetListOfAPIVersions(s: TStrings);
var
  APIVersion: TGeminiAPIVersion;
begin
  s.Clear;
  for ApiVersion := Low(TGeminiAPIVersion) to High(TGeminiAPIVersion) do
    s.Add(TRttiEnumerationType.GetName(APIVersion));
end;

procedure TGeminiAI.SetModel(const ModelName: string);
begin
  fModel := ModelName;
end;

function TGeminiAI.BaseURL(IncludingModel: boolean): string;
begin
  if IncludingModel then
  begin
    if fModel.IsEmpty then
      raise EGeminiAIRequest.Create('SetModel first');
    result := Format(GEMINI_API_4Model, [fAPIVersion, fModel]);
  end else
    result := Format(GEMINI_API, [fAPIVersion]);
end;

procedure TGeminiAI.FetchListOfModelsSynchronous(ModelNames: TStrings);
var
  Params: TQueryParams;
  Response: IFirebaseResponse;
  Resp: TJSONObject;
  Models: TJSONArray;
  Model: TJSONValue;
  ModelName: string;
begin
  ModelNames.Clear;
  Params := TQueryParams.Create;
  try
    Params.Add('key', [fApiKey]);
    Response := TFirebaseRequest.Create(BaseURL(false), 'Gemini.Get.Models').SendRequestSynchronous(
      [], rmGet, nil, Params, tmNoToken);
    if Response.StatusOk and Response.IsJSONObj then
    begin
      Resp := Response.GetContentAsJSONObj;
      try
        Models := Resp.GetValue<TJSONArray>('models');
        for Model in Models do
        begin
          ModelName := (Model as TJSONObject).GetValue<string>('name');
          if ModelName.StartsWith(cModels) then
            ModelNames.Add(Modelname.Substring(length(cModels)));
          fModelDetails.AddOrSetValue(ModelName, GetModulDetails(Model as TJSONObject));
        end;
      finally
        Resp.Free;
      end;
    end;
  finally
    Params.Free;
  end;
end;

procedure TGeminiAI.FetchListOfModels(OnFetchModels: TOnGeminiFetchModels);
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL(false), 'Gemini.Get.Models');
    Params.Add('key', [fApiKey]);
    Request.SendRequest([], rmGet, nil, Params, tmNoToken,
      OnFetchModelsResponse, OnFetchModelsErrorResp,
      TOnSuccess.CreateGeminiFetchModelNames(OnFetchModels));
  finally
    Params.Free;
  end;
end;

procedure TGeminiAI.OnFetchModelsResponse(const RequestID: string; Response: IFirebaseResponse);
var
  Resp: TJSONObject;
  Models: TJSONArray;
  Model: TJSONValue;
  ModelName: string;
  ModelNames: TStringList;
begin
  if Response.StatusOk then
    try
      Response.CheckForJSONObj;
      ModelNames := TStringList.Create;
      Resp := Response.GetContentAsJSONObj;
      try
        Models := Resp.GetValue<TJSONArray>('models');
        for Model in Models do
        begin
          ModelName := (Model as TJSONObject).GetValue<string>('name');
          if ModelName.StartsWith(cModels) then
            ModelName := Modelname.Substring(length(cModels));
          ModelNames.Add(ModelName);
          fModelDetails.AddOrSetValue(ModelName, GetModulDetails(Model as TJSONObject));
        end;
        if assigned(Response.OnSuccess.OnFetchModels) then
          Response.OnSuccess.OnFetchModels(ModelNames, '');
      finally
        ModelNames.Free;
        Resp.Free;
      end;
    except
      on e: exception do
        if assigned(Response.OnSuccess.OnFetchModels) then
          Response.OnSuccess.OnFetchModels(nil, e.Message)
        else
          TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnFetchModelsResponse', RequestID, e.Message]);
    end
  else if assigned(Response.OnSuccess.OnFetchModels) then
    Response.OnSuccess.OnFetchModels(nil, response.ErrorMsg)
  else
    TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnFetchModelsResponse', RequestID, response.ErrorMsg]);
end;

procedure TGeminiAI.OnFetchModelsErrorResp(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
begin
  if assigned(OnSuccess.OnFetchModels) then
    OnSuccess.OnFetchModels(nil, ErrMsg)
  else
    TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnFetchModelsErrorResp', RequestID, ErrMsg]);
end;

function TGeminiAI.FetchModelDetailsSynchronous(const ModelName: string): TGeminiModelDetails;
var
  Params: TQueryParams;
  Response: IFirebaseResponse;
  Model: TJSONObject;
begin
  if not fModelDetails.TryGetValue(ModelName, result) then
  begin
    Params := TQueryParams.Create;
    try
      Params.Add('key', [fApiKey]);
      Response := TFirebaseRequest.Create(BaseURL(false), 'Gemini.Get.Model').SendRequestSynchronous(
        [ModelName], rmGet, nil, Params, tmNoToken);
      if Response.StatusOk and Response.IsJSONObj then
      begin
        Model := Response.GetContentAsJSONObj;
        try
          result := GetModulDetails(Model);
          fModelDetails.AddOrSetValue(ModelName, result);
        finally
          Model.Free;
        end;
      end;
    finally
      Params.Free;
    end;
  end;
end;

function TGeminiAI.GetModulDetails(Model: TJSONObject): TGeminiModelDetails;
var
  GenMethods: TJSONArray;
  GenMethod: TJSONValue;
  c: integer;
begin
  result.Init;
  result.ModelFullName := Model.GetValue<string>('name');
  Model.TryGetValue<string>('baseModelId', result.BaseModelId);
  Model.TryGetValue<string>('version', result.Version);
  Model.TryGetValue<string>('displayName', result.DisplayName);
  Model.TryGetValue<string>('description', result.Description);
  Model.TryGetValue<integer>('inputTokenLimit', result.InputTokenLimit);
  Model.TryGetValue<integer>('outputTokenLimit', result.OutputTokenLimit);
  if Model.TryGetValue<TJSONArray>('supportedGenerationMethods', GenMethods) then
  begin
    SetLength(result.SupportedGenerationMethods, GenMethods.Count);
    c := 0;
    for GenMethod in GenMethods do
    begin
      result.SupportedGenerationMethods[c] := GenMethod.value;
      inc(c);
    end;
  end;
  Model.TryGetValue<double>('temperature', result.Temperature);
  Model.TryGetValue<double>('maxTemperature', result.MaxTemperature);
  Model.TryGetValue<double>('topP', result.TopP);
  Model.TryGetValue<integer>('topK', result.TopK);
end;

procedure TGeminiAI.FetchModelDetails(const ModelName: string; OnFetchModelDetail: TOnGeminiFetchModel);
var
  Params: TQueryParams;
  Detail: TGeminiModelDetails;
begin
  if fModelDetails.TryGetValue(ModelName, Detail) then
  begin
    if assigned(OnFetchModelDetail) then
      OnFetchModelDetail(Detail, '');
  end else begin
    Params := TQueryParams.Create;
    try
      Params.Add('key', [fApiKey]);
      TFirebaseRequest.Create(BaseURL(false), 'Gemini.Get.Model').SendRequest([ModelName], rmGet, nil, Params, tmNoToken,
        OnFetchModelDetailResponse, OnFetchModelDetailErrorResp,
        TOnSuccess.CreateGeminiFetchModelDetail(OnFetchModelDetail));
    finally
      Params.Free;
    end;
  end;
end;

procedure TGeminiAI.OnFetchModelDetailResponse(const RequestID: string; Response: IFirebaseResponse);
var
  Detail: TGeminiModelDetails;
  Model: TJSONObject;
  ModelName: string;
begin
  Detail.Init;
  if Response.StatusOk then
  begin
    Response.CheckForJSONObj;
    Model := Response.GetContentAsJSONObj;
    try
      ModelName := Model.GetValue<string>('name');
      if ModelName.StartsWith(cModels) then
        ModelName := Modelname.Substring(length(cModels));
      Detail := GetModulDetails(Model);
      fModelDetails.AddOrSetValue(ModelName, Detail);
      if assigned(Response.OnSuccess.OnFetchModelDetail) then
        Response.OnSuccess.OnFetchModelDetail(Detail, '');
    finally
      Model.Free;
    end;
  end
  else if assigned(Response.OnSuccess.OnFetchModelDetail) then
    Response.OnSuccess.OnFetchModelDetail(Detail, response.ErrorMsg)
  else
    TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnFetchModelDetailResponse', RequestID, response.ErrorMsg]);
end;

procedure TGeminiAI.OnFetchModelDetailErrorResp(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
var
  Detail: TGeminiModelDetails;
begin
  Detail.Init;
  if assigned(OnSuccess.OnFetchModelDetail) then
    OnSuccess.OnFetchModelDetail(Detail, ErrMsg)
  else
    TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnFetchModelDetailErrorResp', RequestID, ErrMsg]);
end;

function TGeminiAI.GenerateContentSynchronous(Body: TJSONObject): IGeminiAIResponse;
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL(true), 'Gemini.Generate.Content');
    Params.Add('key', [fApiKey]);
    try
      result := TGeminiResponse.Create(Request.SendRequestSynchronous([':generateContent'],
        rmPost, Body, Params, tmNoToken));
    except
      on e: exception do
        result := TGeminiResponse.CreateError('Gemini.Generate.Content', e.Message);
    end;
  finally
    Params.Free;
  end;
end;

function TGeminiAI.CreateBodyByPrompt(const Prompt: string): TJSONObject;
begin
  result := TJSONObject.Create.
    AddPair('contents',
      TJSONArray.Create(
        TJSONObject.Create
          .AddPair('parts',
            TJSONArray.Create(
              TJSONObject.Create
              .AddPair('text', Prompt)))));
end;

function TGeminiAI.GenerateContentByPromptSynchronous(const Prompt: string): IGeminiAIResponse;
var
  Body: TJSONObject;
begin
  Body := CreateBodyByPrompt(Prompt);
  try
    result := GenerateContentSynchronous(Body);
  finally
    Body.Free;
  end;
end;

procedure TGeminiAI.GenerateContent(Body: TJSONObject; OnResponse: TOnGeminiGenContent);
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL(true), 'Gemini.generate.Content');
    Params.Add('key', [fApiKey]);
    Request.SendRequest([':generateContent'], rmPost, Body, Params, tmNoToken,
      OnGenerateContentResponse, OnGenerateContentError,
      TOnSuccess.CreateGeminiGenerateContent(OnResponse));
  finally
    Params.Free;
  end;
end;

procedure TGeminiAI.GenerateContentByPrompt(const Prompt: string;
  OnResponse: TOnGeminiGenContent);
var
  Body: TJSONObject;
begin
  Body := CreateBodyByPrompt(Prompt);
  try
    GenerateContent(Body, OnResponse);
  finally
    Body.Free;
  end;
end;

procedure TGeminiAI.GenerateContentByRequest(GeminiAIRequest: IGeminiAIRequest;
  OnResponse: TOnGeminiGenContent);
begin
  GenerateContent((GeminiAIRequest as TGeminiAIRequest).asJSON, OnResponse);
end;

function TGeminiAI.GenerateContentByRequestSynchronous(GeminiAIRequest: IGeminiAIRequest): IGeminiAIResponse;
begin
  result := GenerateContentSynchronous((GeminiAIRequest as TGeminiAIRequest).asJSON);
end;

procedure TGeminiAI.OnGenerateContentResponse(const RequestID: string;
  Response: IFirebaseResponse);
var
  Res: IGeminiAIResponse;
begin
  try
    Res := TGeminiResponse.Create(Response);
    if assigned(Response.OnSuccess.OnGenerateContent) then
      Response.OnSuccess.OnGenerateContent(Res);
  except
    on e: Exception do
    begin
      if assigned(Response.OnErrorWithSuccess) then
        Response.OnErrorWithSuccess(RequestID, e.Message, Response.OnSuccess)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnGenerateContentResponse', RequestID, e.Message]);
    end;
  end;
end;

procedure TGeminiAI.OnGenerateContentError(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
begin
  if assigned(OnSuccess.OnGenerateContent) then
    OnSuccess.OnGenerateContent(TGeminiResponse.CreateError(RequestID, ErrMsg));
end;

procedure TGeminiAI.CountToken(Body: TJSONObject; OnResponse: TOnGeminiCountToken);
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL(true), 'Gemini.Count.Token');
    Params.Add('key', [fApiKey]);
    Request.SendRequest([':countTokens'], rmPost, Body, Params, tmNoToken,
      OnCountTokenResponse, OnCountTokenError,
      TOnSuccess.CreateGeminiCountToken(OnResponse));
  finally
    Params.Free;
  end;
end;

procedure TGeminiAI.CountTokenOfPrompt(const Prompt: string; OnResponse: TOnGeminiCountToken);
var
  Body: TJSONObject;
begin
  Body := CreateBodyByPrompt(Prompt);
  try
    CountToken(Body, OnResponse);
  finally
    Body.Free;
  end;
end;

procedure TGeminiAI.OnCountTokenError(const RequestID, ErrMsg: string; OnSuccess: TOnSuccess);
begin
  if assigned(OnSuccess.OnCountToken) then
    OnSuccess.OnCountToken(0, 0, ErrMsg);
end;

procedure TGeminiAI.OnCountTokenResponse(const RequestID: string; Response: IFirebaseResponse);
var
  JSONObj: TJSONObject;
  TotalToken,
  CachedContentToken: integer;
begin
  try
    if Response.IsJSONObj then
    begin
      JSONObj := Response.GetContentAsJSONObj;
      try
        TotalToken := JSONObj.GetValue<integer>('totalTokens');
        if not JSONObj.TryGetValue<integer>('cachedContentTokenCount', CachedContentToken) then
          CachedContentToken := 0;
      finally
        JSONObj.Free;
      end;
      if assigned(Response.OnSuccess.OnCountToken) then
        Response.OnSuccess.OnCountToken(TotalToken, CachedContentToken, '');
    end
    else if assigned(Response.OnErrorWithSuccess) then
      Response.OnErrorWithSuccess(RequestID, Response.ContentAsString, Response.OnSuccess)
    else
      TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnCountTokenResponse', RequestID, Response.ContentAsString]);
  except
    on e: Exception do
    begin
      if assigned(Response.OnErrorWithSuccess) then
        Response.OnErrorWithSuccess(RequestID, e.Message, Response.OnSuccess)
      else
        TFirebaseHelpers.LogFmt(rsFBFailureIn, ['Gemini.OnCountTokenResponse', RequestID, e.Message]);
    end;
  end;
end;

procedure TGeminiAI.CountTokenOfRequest(GeminiAIRequest: IGeminiAIRequest; OnResponse: TOnGeminiCountToken);
begin
  CountToken((GeminiAIRequest as TGeminiAIRequest).AsJSON, OnResponse);
end;

function TGeminiAI.CountTokenSynchronous(Body: TJSONObject; out ErrorMsg: string;
  out CachedContentToken: integer): integer;
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
  JSONObj: TJSONObject;
begin
  CachedContentToken := 0;
  result := 0;
  ErrorMsg := '';
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL(true), 'Gemini.Count.Token');
    Params.Add('key', [fApiKey]);
    try
      JSONObj := Request.SendRequestSynchronous([':countTokens'], rmPost, Body, Params, tmNoToken).GetContentAsJSONObj;
      try
        result := JSONObj.GetValue<integer>('totalTokens');
        JSONObj.TryGetValue<integer>('cachedContentTokenCount', CachedContentToken);
      finally
        JSONObj.Free;
      end;
    except
      on e: exception do
        ErrorMsg := e.Message;
    end;
  finally
    Params.Free;
  end;
end;

function TGeminiAI.CountTokenOfPromptSynchronous(const Prompt: string; out ErrorMsg: string;
  out CachedContentToken: integer): integer;
var
  Body: TJSONObject;
begin
  Body := CreateBodyByPrompt(Prompt);
  try
    result := CountTokenSynchronous(Body, ErrorMsg, CachedContentToken);
  finally
    Body.Free;
  end;
end;

function TGeminiAI.CountTokenOfRequestSynchronous(GeminiAIRequest: IGeminiAIRequest; out ErrorMsg: string;
  out CachedContentToken: integer): integer;
begin
  result := CountTokenSynchronous((GeminiAIRequest as TGeminiAIRequest).AsJSON, ErrorMsg, CachedContentToken);
end;

{ TGeminiAIRequest }

constructor TGeminiAIRequest.Create;
begin
  fContents := TJSONArray.Create;
  fParts := TJSONArray.Create;
  fContents.Add(TJSONObject.Create.
    AddPair('parts', fParts).
    AddPair('role', 'user'));
  fRequest := TJSONObject.Create;
  fRequest.AddPair('contents', fContents);
end;

function TGeminiAIRequest.CloneWithoutCfgAndSettings(Request: IGeminiAIRequest): IGeminiAIRequest;
begin
  fRequest := (Request as TGeminiAIRequest).fRequest.Clone as TJSONObject;
  fContents := fRequest.FindValue('contents') as TJSONArray;
  if assigned(fContents) then
    fParts := fContents.Items[fContents.Count - 1].FindValue('parts') as TJSONArray;
  fRequest.RemovePair('generationConfig');
  fGenerationConfig := nil;
  fRequest.RemovePair('safetySettings');
  fSavetySettings := nil;
  fTools := nil;
  result := self;
end;

destructor TGeminiAIRequest.Destroy;
begin
  fRequest.Free;
  inherited;
end;

function TGeminiAIRequest.Prompt(const PromptText: string): IGeminiAIRequest;
begin
  Assert(not assigned(fParts.FindValue('[0].text')), 'Gemini AI support only one prompt per part');
  fParts.Add(
    TJSONObject.Create.
      AddPair('text', PromptText));
  result := self;
end;

function TGeminiAIRequest.PromptWithMediaData(const PromptText, MimeType: string;
  MediaStream: TStream): IGeminiAIRequest;
var
  ms: TStringStream;
  Base64Str: string;
begin
  Assert(not assigned(fParts.FindValue('[0].text')), 'Gemini AI support only one prompt per part');
  Assert(not assigned(fParts.FindValue('[0].inline_data')), 'Gemini AI support only one prompt per part');
  ms := TStringStream.Create;
  try
    MediaStream.Position := 0;
    {$IF CompilerVersion < 35} // Delphi 10.4 and before
    TNetEncoding.Base64.Encode(MediaStream, ms); // Base64String is without LF CR
    Base64Str := StringReplace(ms.DataString, #13#10, '', [rfReplaceAll]);
    {$ELSE}
    TNetEncoding.Base64String.Encode(MediaStream, ms); // Base64String is without LF CR
    Base64Str := ms.DataString;
    {$ENDIF}
  finally
    ms.Free;
  end;
  fParts.Add(
    TJSONObject.Create.
      AddPair('text', PromptText));
  fParts.Add(
    TJSONObject.Create.
      AddPair('inline_data',
        TJSONObject.Create.
          AddPair('mime_type', MimeType).
          AddPair('data', Base64Str)));
  result := self;
end;

{$IF CompilerVersion >= 35} // Delphi 11 and later
{$IF Defined(FMX) OR Defined(FGX)}
function TGeminiAIRequest.PromptWithImgData(const PromptText: string;
  ImgStream: TStream): IGeminiAIRequest;
var
  MimeType: string;
begin
  ImgStream.Position := 0;
  MimeType := TFirebaseHelpers.ImageStreamToContentType(ImgStream);
  if MimeType.IsEmpty then
    raise EGeminiAIRequest.Create('Unknown mime type of image');
  result := PromptWithMediaData(PromptText, MimeType, ImgStream);
end;
{$ENDIF}
{$ENDIF}

procedure TGeminiAIRequest.CheckAndCreateGenerationConfig;
begin
  if not assigned(fGenerationConfig) then
  begin
    fGenerationConfig := TJSONObject.Create;
    fRequest.AddPair('generationConfig', fGenerationConfig);
  end;
end;

procedure TGeminiAIRequest.CheckAndCreateTools;
begin
  if not assigned(fTools) then
  begin
    fTools := TJSONArray.Create;
    fRequest.AddPair('tools', fTools);
  end;
end;

function TGeminiAIRequest.ModelParameter(Temperature, TopP: double;
  MaxOutputTokens, TopK: cardinal): IGeminiAIRequest;
begin
  CheckAndCreateGenerationConfig;
  if (Temperature < 0) and (Temperature > 0) then
    raise EGeminiAIRequest.CreateFmt('Temperatur out of range 0..1: %f',
      [Temperature]);
  if (TopP < 0) and (TopP > 0) then
    raise EGeminiAIRequest.CreateFmt('TopP out of range 0..1: %f', [TopP]);
  {$IF CompilerVersion >= 35} // Delphi 11 and later
  fGenerationConfig.AddPair('temperature', Temperature);
  fGenerationConfig.AddPair('topP', TopP);
  fGenerationConfig.AddPair('maxOutputTokens', MaxOutputTokens);
  fGenerationConfig.AddPair('topK', TopK);
  {$ELSE}
  fGenerationConfig.AddPair('temperature', FloatToStr(Temperature));
  fGenerationConfig.AddPair('topP', FloatToStr(TopP));
  fGenerationConfig.AddPair('maxOutputTokens', IntToStr(MaxOutputTokens));
  fGenerationConfig.AddPair('topK', IntToStr(TopK));
  {$ENDIF}
  result := self;
end;

function TGeminiAIRequest.SetStopSequences(StopSequences: TStrings): IGeminiAIRequest;
var
  Arr: TJSONArray;
  ss: string;
begin
  CheckAndCreateGenerationConfig;
  Arr := TJSONArray.Create;
  for ss in StopSequences do
    Arr.Add(ss);
  fGenerationConfig.AddPair('stopSequences', Arr);
  result := self;
end;

function TGeminiAIRequest.SetJSONResponseSchema(Schema: IGeminiSchema): IGeminiAIRequest;
begin
  CheckAndCreateGenerationConfig;
  {$IF CompilerVersion >= 35} // Delphi 11 and later
  fGenerationConfig.AddPair('response_mime_type', CONTENTTYPE_APPLICATION_JSON);
  {$ELSE}
  fGenerationConfig.AddPair('response_mime_type', 'application/json');
  {$ENDIF}
  fGenerationConfig.AddPair('response_schema', (Schema as TGeminiSchema).GetJSONObject);
end;

function TGeminiAIRequest.SetSafety(HarmCat: THarmCategory; LevelToBlock: TSafetyBlockLevel): IGeminiAIRequest;
begin
  if HarmCat = hcUnspecific then
    exit;
  if not assigned(fSavetySettings) then
  begin
    fSavetySettings := TJSONArray.Create;
    fRequest.AddPair('safetySettings', fSavetySettings);
  end;
  fSavetySettings.AddElement(
    TJSONObject.Create(
      TJSONPair.Create('category', TGeminiResponse.HarmCategoryToStr(HarmCat))).
      AddPair('threshold', SafetyBlockLevelToStr(LevelToBlock)));
  result := self;
end;

procedure TGeminiAIRequest.AddGroundingByGoogleSearch(Threshold: double);
begin
  CheckAndCreateTools;
  fTools.Add(TJSONObject.Create(TJSONPair.Create('google_search_retrieval',
    TJSONObject.Create(TJSONPair.Create('dynamic_retrieval_config',
      TJSONObject.Create(TJSONPair.Create('mode', 'MODE_DYNAMIC')).
      AddPair('dynamic_threshold', Threshold))))));
end;

procedure TGeminiAIRequest.AddAnswerForNextRequest(const ResultAsMarkDown: string);
begin
  fParts := TJSONArray.Create.Add(
    TJSONObject.Create.
      AddPair('text', ResultAsMarkDown));
  fContents.Add(TJSONObject.Create.
    AddPair('role', 'model').
    AddPair('parts', fParts));
  fParts := nil;
end;

procedure TGeminiAIRequest.AddQuestionForNextRequest(const PromptText: string);
begin
  fParts := TJSONArray.Create.Add(
    TJSONObject.Create.
      AddPair('text', PromptText));
  fContents.Add(TJSONObject.Create.
    AddPair('role', 'user').
    AddPair('parts', fParts));
  fParts := nil;
end;

function TGeminiAIRequest.AsJSON: TJSONObject;
begin
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('Request as JSON: ' + fRequest.ToJSON);
  {$ENDIF}
  result := fRequest;
end;

class function TGeminiAIRequest.SafetyBlockLevelToStr(sbl: TSafetyBlockLevel): string;
begin
  case sbl of
    sblNone:
      result := 'BLOCK_NONE';
    sblOnlyHigh:
      result := 'BLOCK_ONLY_HIGH';
    sblMediumAndAbove:
      result := 'BLOCK_MEDIUM_AND_ABOVE';
    sblLowAndAbove:
      result := 'BLOCK_LOW_AND_ABOVE';
    else // sblUseDefault
      result := 'HARM_BLOCK_THRESHOLD_UNSPECIFIED';
  end;
end;

{ TGeminiResponse }

constructor TGeminiResponse.Create(Response: IFirebaseResponse);
begin
  response.CheckForJSONObj;
  fContentResponse := response.GetContentAsJSONObj;
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('Gemini.Feedback: ' + fContentResponse.Format);
  {$ENDIF}
  EvaluateResults;
end;

constructor TGeminiResponse.CreateError(const RequestID, ErrMsg: string);
begin
  fContentResponse := nil;
  fUsageMetaData.Init;
  fResultState := TGeminiAIResultState.grsTransmitError;
  fFailureDetail := ErrMsg;
  SetLength(fResults, 0);
end;

destructor TGeminiResponse.Destroy;
begin
  fContentResponse.Free;
  inherited;
end;

function TGeminiResponse.RawFormatedJSONResult: string;
begin
  if assigned(fContentResponse) then
    result := fContentResponse.Format
  else if not fFailureDetail.IsEmpty then
    result := fFailureDetail
  else
    result := '?';
end;

function TGeminiResponse.RawJSONResult: TJSONValue;
begin
  if assigned(fContentResponse) then
    result := fContentResponse
  else
    result := TJSONNull.Create;
end;

function TGeminiResponse.EvalResult(ResultIndex: integer): TGeminiAIResult;
begin
  if (ResultIndex < 0) or (ResultIndex >= NumberOfResults) then
    raise EFirebaseResponse.CreateFmt(
      'Result index %d out of range 0..%d', [ResultIndex, NumberOfResults - 1]);
  result := fResults[ResultIndex];
end;

function TGeminiResponse.NumberOfResults: integer;
begin
  result := length(fResults);
end;

function TGeminiResponse.ResultState: TGeminiAIResultState;
begin
  result := fResultState;
end;

function TGeminiResponse.ResultStateStr: string;
begin
  result := TRttiEnumerationType.GetName(fResultState).Substring(3);
end;

function TGeminiResponse.IsValid: boolean;
begin
  result := (fResultState = grsValid) and (length(fResults) > 0);
end;

function TGeminiResponse.FailureDetail: string;
begin
  result := '';
  case fResultState of
    grsUnknown,
    grsParseError,
    grsTransmitError:
      result := fFailureDetail;
    grsBlockedBySafety:
      result := 'Blocked by safety';
    grsBlockedbyOtherReason:
      result := 'Blocked by other reason';
  end;
end;

function TGeminiResponse.FinishReasons: TGeminiAIFinishReasons;
begin
  result := fFinishReasons;
end;

function TGeminiResponse.FinishReasonsCommaSepStr: string;
var
  sl: TStringList;
  Reason: TGeminiAIFinishReason;
begin
  sl := TStringList.Create;
  try
    for Reason in fFinishReasons do
      sl.Add(TRttiEnumerationType.GetName(Reason).Substring(3));
    result := sl.CommaText;
  finally
    sl.Free;
  end;
end;

function TGeminiResponse.ResultAsMarkDown: string;
var
  Index: integer;
begin
  result := '';
  if IsValid then
    for Index := 0 to NumberOfResults - 1 do
    begin
      if NumberOfResults > 1 then
        result := result + '# Result candiate ' + IntToStr(Index + 1) +
          sLineBreak;
      result := result + EvalResult(Index).ResultAsMarkDown;
    end;
end;

const
  cHTMLHeader = '<!DOCTYPE html>'#$A'<html>'#$A'<body>'#$A;

function TGeminiResponse.ConvertMarkDownToHTML(const MarkDown: string): string;
{$IFDEF MARKDOWN2HTML}
var
  MDProcessor: TMarkdownProcessor;
begin
  MDProcessor := TMarkdownProcessor.CreateDialect(mdDaringFireball);
  try
    MDProcessor.AllowUnsafe := true; // Allow scripts
    result := MDProcessor.process(MarkDown);
  finally
    MDProcessor.Free;
  end;
end;
{$ELSE}
const
  cInfoForUsingMARKDOWN2HTML = '<h1>MarkDown to HTML converter is disabled in your project!</h1>'#$A +
    '<p>Enable {$DEFINE MARKDOWN2HTML} in the project</p>'#$A'<h2>Unformated result</h2><p>'#$A;
  cEndHTML = #$A'</p></body></html>';
begin
  result := cHTMLHeader + cInfoForUsingMARKDOWN2HTML + MarkDown + cEndHTML;
end;
{$ENDIF}

function TGeminiResponse.ResultAsHTML: string;
const
  cCodeStart = '```html'#$A;
  cCodeEnd = '```';

  function ExtractHTML(var MarkDown: string): string;
  var
    pEnd: integer;
  begin
    result := MarkDown.Substring(cCodeStart.length);
    pEnd := Pos(cCodeEnd, result);
    if pEnd > 0 then
    begin
      result := result.SubString(0, pEnd - 1);
      MarkDown := MarkDown.SubString(cCodeStart.length + pEnd + cCodeEnd.Length);
    end;
  end;

begin
  result := ResultAsMarkDown;
  if result.StartsWith(cCodeStart, true) then
  begin
    result := ExtractHTML(result) + ConvertMarkDownToHTML(result);
  end else
    result := ConvertMarkDownToHTML(result);
end;

function TGeminiResponse.ResultAsJSON: TJSONValue;
begin
  Assert(NumberOfResults = 1, 'Not a single result received');
  result := TJSONValue.ParseJSONValue(EvalResult(0).ResultAsMarkDown);
end;

function TGeminiResponse.UsageMetaData: TGeminiAIUsageMetaData;
begin
  result := fUsageMetaData;
end;

function TGeminiResponse.ModelVersion: string;
begin
  result := fModelVersion;
end;

procedure TGeminiResponse.EvaluateResults;
var
  Candidates, Parts, Arr, Arr2: TJSONArray;
  Ind, Ind2, Ind3: integer;
  Txt: string;
  Candidate, Obj, Obj2: TJSONObject;
  HarmCat: THarmCategory;
begin
  fFinishReasons := [];
  fUsageMetaData.Init;
  try
    fResultState := grsParseError;
    if fContentResponse.TryGetValue<TJSONArray>('candidates', Candidates) then
    begin
      SetLength(fResults, Candidates.Count);
      for Ind := 0 to Candidates.Count - 1 do
      begin
        fResults[Ind].Init;
        fResultState := grsValid;
        Candidate := Candidates.Items[Ind] as TJSONObject;
        if Candidate.TryGetValue<TJSONObject>('content', Obj) then
        begin
          if Obj.TryGetValue<TJSONArray>('parts', Parts) then
          begin
            SetLength(fResults[Ind].PartText, Parts.Count);
            for Ind2 := 0 to Parts.Count - 1 do
              (Parts.Items[Ind2] as TJSONObject).
                TryGetValue<string>('text', fResults[Ind].PartText[Ind2]);
          end;
        end;
        if Candidate.TryGetValue<string>('finishReason', Txt) then
        begin
          if SameText(txt, 'STOP') then
            fResults[Ind].FinishReason := gfrStop
          else if SameText(txt, 'MAX_TOKENS') then
            fResults[Ind].FinishReason := gfrMaxToken
          else if SameText(txt, 'SAFETY') then
            fResults[Ind].FinishReason := gfrSafety
          else if SameText(txt, 'RECITATION') then
            fResults[Ind].FinishReason := gfrRecitation
          else if SameText(txt, 'OTHER') then
            fResults[Ind].FinishReason := gfrOther
          else
            fResults[Ind].FinishReason := gfrUnknown;
          fFinishReasons := fFinishReasons + [fResults[Ind].FinishReason];
        end;
        if Candidate.TryGetValue<TJSONObject>('groundingMetadata', Obj) then
        begin
          fResults[Ind].GroundingMetadata.ActiveGrounding := true;
          if Obj.TryGetValue<TJSONArray>('groundingChunks', Arr) then
          begin
            SetLength(fResults[Ind].GroundingMetadata.Chunks, Arr.Count);
            for Ind2 := 0 to Arr.Count - 1 do
            begin
              if Arr.Items[Ind2].TryGetValue<TJSONObject>('web', Obj2) then
              begin
                Obj2.TryGetValue<string>('uri', fResults[Ind].GroundingMetadata.Chunks[Ind2].Uri);
                Obj2.TryGetValue<string>('title', fResults[Ind].GroundingMetadata.Chunks[Ind2].Title);
              end else begin
                fResults[Ind].GroundingMetadata.Chunks[Ind2].Uri := '';
                fResults[Ind].GroundingMetadata.Chunks[Ind2].Title := '';
              end;
            end;
          end;
          if Obj.TryGetValue<TJSONArray>('groundingSupports', Arr) then
          begin
            SetLength(fResults[Ind].GroundingMetadata.Support, Arr.Count);
            for Ind2 := 0 to Arr.Count - 1 do
            begin
              if Arr.Items[Ind2].TryGetValue<TJSONArray>('groundingChunkIndices', Arr2) then
              begin
                SetLength(fResults[Ind].GroundingMetadata.Support[Ind2].ChunkIndices, Arr2.Count);
                for Ind3 := 0 to Arr2.Count - 1 do
                  fResults[Ind].GroundingMetadata.Support[Ind2].ChunkIndices[Ind3] :=
                    Arr2.Items[Ind3].AsType<integer>;
              end;
              if Arr.Items[Ind2].TryGetValue<TJSONArray>('confidenceScores', Arr2) then
              begin
                SetLength(fResults[Ind].GroundingMetadata.Support[Ind2].ConfidenceScores, Arr2.Count);
                for Ind3 := 0 to Arr2.Count - 1 do
                  fResults[Ind].GroundingMetadata.Support[Ind2].ConfidenceScores[Ind3] :=
                    Arr2.Items[Ind3].AsType<double>;
              end;
              if Arr.Items[Ind2].TryGetValue<TJSONObject>('segment', Obj2) then
              begin
                if not Obj2.TryGetValue<integer>('partIndex',
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.PartIndex) then
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.PartIndex := 0;
                if not Obj2.TryGetValue<integer>('startIndex',
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.StartIndex) then
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.StartIndex := 0;
                if not Obj2.TryGetValue<integer>('endIndex',
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.EndIndex) then
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.EndIndex := 0;
                if not Obj2.TryGetValue<string>('text',
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.Text) then
                  fResults[Ind].GroundingMetadata.Support[Ind2].Segment.Text := '';
              end;
            end;
          end;
          if Obj.TryGetValue<TJSONObject>('searchEntryPoint', Obj2) then
            Obj2.TryGetValue<string>('renderedContent', fResults[Ind].GroundingMetadata.RenderedContent);
          if Obj.TryGetValue<TJSONArray>('webSearchQueries', Arr) then
          begin
            SetLength(fResults[Ind].GroundingMetadata.WebSearchQuery, Arr.Count);
            for Ind2 := 0 to Arr.Count - 1 do
              fResults[Ind].GroundingMetadata.WebSearchQuery[Ind2] :=
                Arr.Items[Ind2].AsType<string>;
          end;
          if Obj.TryGetValue<TJSONObject>('retrievalMetadata', Obj2) then
            Obj2.TryGetValue<Double>('googleSearchDynamicRetrievalScore',
              fResults[Ind].GroundingMetadata.GoogleSearchDynamicRetrievalScore);
        end;
        Candidate.TryGetValue<integer>('index', fResults[Ind].Index);
        if Candidate.TryGetValue<TJSONArray>('safetyRatings', Arr) then
        begin
          for Ind2 := 0 to Arr.Count - 1 do
          begin
            obj := Arr.Items[Ind2] as TJSONObject;
            HarmCat := THarmCategory.hcUnspecific;
            if obj.TryGetValue<string>('category', Txt) then
              HarmCat := HarmCategoryFromStr(Txt);
            fResults[Ind].SafetyRatings[HarmCat].Init;
            if obj.TryGetValue<string>('probability', Txt) then
            begin
              if SameText(Txt, 'NEGLIGIBLE') then
                fResults[Ind].SafetyRatings[HarmCat].Probability := psNEGLIGIBLE
              else if SameText(Txt, 'LOW') then
                fResults[Ind].SafetyRatings[HarmCat].Probability := psLOW
              else if SameText(Txt, 'MEDIUM') then
                fResults[Ind].SafetyRatings[HarmCat].Probability := psMEDIUM
              else if SameText(Txt, 'HIGH') then
                fResults[Ind].SafetyRatings[HarmCat].Probability := psHIGH;
            end;
            if obj.TryGetValue<string>('severity', Txt) then
            begin
              if SameText(Txt, 'NEGLIGIBLE') then
                fResults[Ind].SafetyRatings[HarmCat].Severity := psNEGLIGIBLE
              else if SameText(Txt, 'LOW') then
                fResults[Ind].SafetyRatings[HarmCat].Severity := psLOW
              else if SameText(Txt, 'MEDIUM') then
                fResults[Ind].SafetyRatings[HarmCat].Severity := psMEDIUM
              else if SameText(Txt, 'HIGH') then
                fResults[Ind].SafetyRatings[HarmCat].Severity := psHIGH;
            end;
            obj.TryGetValue<extended>('probabilityScore', fResults[Ind].SafetyRatings[HarmCat].ProbabilityScore);
            obj.TryGetValue<extended>('severityScore', fResults[Ind].SafetyRatings[HarmCat].ProbabilityScore);
          end;
        end;
      end;
    end else begin
      SetLength(fResults, 0);
      fFailureDetail := 'No result candidates found';
    end;
    if fContentResponse.TryGetValue<TJSONObject>('promptFeedback', Obj) then
    begin
      if Obj.tryGetValue<string>('blockReason', Txt) then
      begin
         if SameText(txt, 'SAFETY') then
           fResultState := grsBlockedBySafety
         else if SameText(txt, 'OTHER') then
           fResultState := grsBlockedbyOtherReason
         else begin
           fResultState := grsUnknown;
           fFailureDetail := Txt + '?'
         end;
      end;
    end;
    Obj := fContentResponse.GetValue<TJSONObject>('usageMetadata');
    fUsageMetaData.Init;
    Obj.TryGetValue<integer>('promptTokenCount', fUsageMetaData.PromptTokenCount);
    Obj.TryGetValue<integer>('candidatesTokenCount', fUsageMetaData.GeneratedTokenCount);
    Obj.TryGetValue<integer>('totalTokenCount', fUsageMetaData.TotalTokenCount);
    fModelVersion := fContentResponse.GetValue<string>('modelVersion');
  except
    on e: exception do
    begin
      fResultState := grsParseError;
      fFailureDetail := e.message;
    end;
  end;
end;

class function TGeminiResponse.HarmCategoryToStr(hc: THarmCategory): string;
begin
  case hc of
    hcHateSpeech:
      result := 'HARM_CATEGORY_HATE_SPEECH';
    hcHarassment:
      result := 'HARM_CATEGORY_HARASSMENT';
    hcSexuallyExplicit:
      result := 'HARM_CATEGORY_SEXUALLY_EXPLICIT';
    hcDangerousContent:
      result := 'HARM_CATEGORY_DANGEROUS_CONTENT';
    hcCivicIntegrity:
      result := 'HARM_CATEGORY_CIVIC_INTEGRITY';
    hcDangerous:
      result := 'HARM_CATEGORY_DANGEROUS';
    hcMedicalAdvice:
      result := 'HARM_CATEGORY_MEDICAL';
    hcSexual:
      result := 'HARM_CATEGORY_SEXUAL';
    hcViolence:
      result := 'HARM_CATEGORY_VIOLENCE';
    hcToxicity:
      result := 'HARM_CATEGORY_TOXICITY';
    hcDerogatory:
      result := 'HARM_CATEGORY_DEROGATORY';
    else
      result := '?';
  end;
end;

class function TGeminiResponse.HarmCategoryFromStr(const txt: string): THarmCategory;
var
  hc: THarmCategory;
begin
  result := hcUnspecific;
  for hc := succ(Low(THarmCategory)) to high(THarmCategory) do
    if SameText(Txt, HarmCategoryToStr(hc)) then
      exit(hc);
end;

{ TGeminiSchema }

constructor TGeminiSchema.Create;
begin
  fSchema := TJSONObject.Create;
end;

destructor TGeminiSchema.Destroy;
begin
  FreeAndNil(fSchema);
  inherited;
end;

function TGeminiSchema.GetJSONObject: TJSONObject;
begin
  result := fSchema;
  fSchema := nil;
end;

function TGeminiSchema.SetStringType: IGeminiSchema;
begin
  fSchema.AddPair('type', 'STRING');
  result := self;
end;

function TGeminiSchema.SetIntegerType: IGeminiSchema;
begin
  fSchema.AddPair('type', 'INTEGER');
  result := self;
end;

function TGeminiSchema.SetFloatType: IGeminiSchema;
begin
  fSchema.AddPair('type', 'NUMBER');
  result := self;
end;

function TGeminiSchema.SetBooleanType: IGeminiSchema;
begin
  fSchema.AddPair('type', 'BOOLEAN');
  result := self;
end;

function TGeminiSchema.SetEnumType(EnumValues: TStringDynArray): IGeminiSchema;
var
  Arr: TJSONArray;
  Enum: string;
begin
  fSchema.AddPair('type', 'STRING');
  fSchema.AddPair('format', 'enum');
  Arr := TJSONArray.Create;
  for Enum in EnumValues do
    Arr.Add(Enum);
  fSchema.AddPair('enum', Arr);
  result := self;
end;

function TGeminiSchema.SetDescription(const Description: string): IGeminiSchema;
begin
  fSchema.AddPair('description', Description);
  result := self;
end;

function TGeminiSchema.SetNullable(IsNullable: boolean): IGeminiSchema;
begin
  fSchema.AddPair('nullable', BoolToStr(IsNullable, true).ToLower);
  result := self;
end;

function TGeminiSchema.SetArrayType(ArrayElement: IGeminiSchema; MinItems, MaxItems: integer): IGeminiSchema;
begin
  Assert(assigned(ArrayElement), 'Missing ArrayElement');
  fSchema.AddPair('type', 'ARRAY');
  fSchema.AddPair('items', (ArrayElement as TGeminiSchema).GetJSONObject);
  if MinItems >= 0 then
    fSchema.AddPair('minItems', MinItems);
  if MaxItems > MinItems then
    fSchema.AddPair('maxItems', MaxItems);
  result := self;
end;

function TGeminiSchema.SetObjectType(RequiredItems, OptionalItems: TSchemaItems): IGeminiSchema;
var
  Properties: TJSONObject;
  Required: TJSONArray;
  ObjName: string;
begin
  Assert(assigned(RequiredItems), 'Missing ArrayElement');
  fSchema.AddPair('type', 'OBJECT');
  Properties := TJSONObject.Create;
  Required := TJSONArray.Create;
  for ObjName in RequiredItems.Keys do
  begin
    Properties.AddPair(ObjName, (RequiredItems.Items[ObjName] as TGeminiSchema).GetJSONObject);
    Required.Add(ObjName);
  end;
  if assigned(OptionalItems) then
    for ObjName in OptionalItems.Keys do
      Properties.AddPair(ObjName, (OptionalItems.Items[ObjName] as TGeminiSchema).GetJSONObject);
  fSchema.AddPair('properties', Properties);
  if not Required.IsEmpty then
    fSchema.AddPair('required', Required)
  else
    Required.Free;
  RequiredItems.Free;
  OptionalItems.Free;
  result := self;
end;

class function TGeminiSchema.StringType: IGeminiSchema;
begin
  result := TGeminiSchema.Create.SetStringType;
end;

class function TGeminiSchema.FloatType: IGeminiSchema;
begin
  result := TGeminiSchema.Create.SetFloatType;
end;

class function TGeminiSchema.BooleanType: IGeminiSchema;
begin
  result := TGeminiSchema.Create.SetBooleanType;
end;

class function TGeminiSchema.EnumType(EnumValues: TStringDynArray): IGeminiSchema;
begin
  result := TGeminiSchema.Create.SetEnumType(EnumValues);
end;

class function TGeminiSchema.IntegerType: IGeminiSchema;
begin
  result := TGeminiSchema.Create.SetIntegerType;
end;

class function TGeminiSchema.ObjectType(RequiredItems, OptionalItems: TSchemaItems): IGeminiSchema;
begin
  result := TGeminiSchema.Create.SetObjectType(RequiredItems, OptionalItems);
end;

class function TGeminiSchema.ArrayType(ArrayElement: IGeminiSchema; MinItems, MaxItems: integer): IGeminiSchema;
begin
  result := TGeminiSchema.Create.SetArrayType(ArrayElement, MinItems, MaxItems);
end;

end.
