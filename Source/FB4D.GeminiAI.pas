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
  System.Classes, System.JSON, System.SysUtils, System.SyncObjs,
  System.Net.HttpClient, System.Net.URLClient, System.Generics.Collections,
  REST.Types,
  {$IFDEF MARKDOWN2HTML}
  MarkdownProcessor,
  {$ENDIF}
  FB4D.Interfaces, FB4D.Response, FB4D.Request;

type
  TGeminiAI = class(TInterfacedObject, IGeminiAI)
  private
    fApiKey: string;
    fModel: string;

    function BaseURL: string;
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
  public
    constructor Create(const ApiKey: string; const Model: string = cGeminiAIDefaultModel);
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

  TGeminiAIRequest = class(TInterfacedObject, IGeminiAIRequest)
  private
    fRequest: TJSONObject;
    fContents: TJSONArray;
    fParts: TJSONArray;
    fGenerationConfig: TJSONObject;
    fSavetySettings: TJSONArray;
    function AsJSON: TJSONObject;
  public
    constructor Create;
    destructor Destroy; override;
    function CloneWithoutCfgAndSettings(Request: IGeminiAIRequest): IGeminiAIRequest;
    function Prompt(const PromptText: string): IGeminiAIRequest;
    function PromptWithMediaData(const PromptText, MimeType: string;
      MediaStream: TStream): IGeminiAIRequest;
    {$IF Defined(FMX) OR Defined(FGX)}
    function PromptWithImgData(const PromptText: string;
      ImgStream: TStream): IGeminiAIRequest;
    {$ENDIF}
    function ModelParameter(Temperature, TopP: double; MaxOutputTokens,
      TopK: cardinal): IGeminiAIRequest;
    function SetStopSequences(StopSequences: TStrings): IGeminiAIRequest;
    function SetSafety(HarmCat: THarmCategory; LevelToBlock: TSafetyBlockLevel): IGeminiAIRequest;
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
    procedure EvaluateResults;
    constructor CreateError(const RequestID, ErrMsg: string);
    function ConvertMarkDownToHTML(const MarkDown: string): string;
  public
    constructor Create(Response: IFirebaseResponse);
    destructor Destroy; override;
    function FormatedJSON: string;
    function NumberOfResults: integer; // Candidates
    function EvalResult(ResultIndex: integer): TGeminiAIResult;
    function UsageMetaData: TGeminiAIUsageMetaData;
    function ResultState: TGeminiAIResultState;
    function ResultStateStr: string;
    function FinishReasons: TGeminiAIFinishReasons;
    function FinishReasonsCommaSepStr: string;
    function IsValid: boolean;
    function FailureDetail: string;
    function ResultAsMarkDown: string;
    function ResultAsHTML: string;
    class function HarmCategoryToStr(hc: THarmCategory): string;
    class function HarmCategoryFromStr(const txt: string): THarmCategory;
  end;

implementation

uses
  System.RTTI, System.NetEncoding,
  FB4D.Helpers;

const
  GEMINI_API = 'https://generativelanguage.googleapis.com/v1beta/models/%s';

{ TGemini }

constructor TGeminiAI.Create(const ApiKey, Model: string);
begin
  fApiKey := ApiKey;
  fModel := Model;
end;

function TGeminiAI.BaseURL: string;
begin
  result := Format(GEMINI_API, [fModel]);
end;

function TGeminiAI.GenerateContentSynchronous(Body: TJSONObject): IGeminiAIResponse;
var
  Params: TQueryParams;
  Request: IFirebaseRequest;
begin
  Params := TQueryParams.Create;
  try
    Request := TFirebaseRequest.Create(BaseURL, 'Gemini.Generate.Content');
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
    Request := TFirebaseRequest.Create(BaseURL, 'Gemini.generate.Content');
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
    Request := TFirebaseRequest.Create(BaseURL, 'Gemini.Count.Token');
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
    Request := TFirebaseRequest.Create(BaseURL, 'Gemini.Count.Token');
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
  result := self
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

function TGeminiAIRequest.ModelParameter(Temperature, TopP: double;
  MaxOutputTokens, TopK: cardinal): IGeminiAIRequest;
begin
  if not assigned(fGenerationConfig) then
  begin
    fGenerationConfig := TJSONObject.Create;
    fRequest.AddPair('generationConfig', fGenerationConfig);
  end;
  if (Temperature < 0) and (Temperature > 0) then
    raise EGeminiAIRequest.CreateFmt('Temperatur out of range 0..1: %f',
      [Temperature]);
  fGenerationConfig.AddPair('temperature', Temperature);
  if (TopP < 0) and (TopP > 0) then
    raise EGeminiAIRequest.CreateFmt('TopP out of range 0..1: %f', [TopP]);
  fGenerationConfig.AddPair('topP', TopP);
  fGenerationConfig.AddPair('maxOutputTokens', MaxOutputTokens);
  fGenerationConfig.AddPair('topK', TopK);
  result := self;
end;

function TGeminiAIRequest.SetStopSequences(StopSequences: TStrings): IGeminiAIRequest;
var
  Arr: TJSONArray;
  ss: string;
begin
  if not assigned(fGenerationConfig) then
  begin
    fGenerationConfig := TJSONObject.Create;
    fRequest.AddPair('generationConfig', fGenerationConfig);
  end;
  Arr := TJSONArray.Create;
  for ss in StopSequences do
    Arr.Add(ss);
  fGenerationConfig.AddPair('stopSequences', Arr);
  result := self;
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
  fFailureDetail := 'REST API Call failed for ' + RequestID + ': ' + ErrMsg;
  SetLength(fResults, 0);
end;

destructor TGeminiResponse.Destroy;
begin
  fContentResponse.Free;
  inherited;
end;

function TGeminiResponse.FormatedJSON: string;
begin
  if assigned(fContentResponse) then
    result := fContentResponse.Format
  else if not fFailureDetail.IsEmpty then
    result := fFailureDetail
  else
    result := '?';
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
    grsParseError:
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

function TGeminiResponse.UsageMetaData: TGeminiAIUsageMetaData;
begin
  result := fUsageMetaData;
end;

procedure TGeminiResponse.EvaluateResults;
var
  Candidates, Parts, saftyRatings: TJSONArray;
  Ind, Ind2: integer;
  Txt: string;
  Candidate, Obj: TJSONObject;
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
        Candidate.TryGetValue<integer>('index', fResults[Ind].Index);
        if Candidate.TryGetValue<TJSONArray>('safetyRatings', saftyRatings) then
        begin
          for Ind2 := 0 to saftyRatings.Count - 1 do
          begin
            obj := saftyRatings.Items[Ind2] as TJSONObject;
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

end.
