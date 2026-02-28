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

unit GeminiAI;

interface

uses
  System.Classes, System.SysUtils, System.JSON, System.Hash, System.NetEncoding,
  DUnitX.TestFramework,
  REST.Types,
  FB4D.Interfaces, FB4D.Helpers, FB4D.GeminiAI;

{$M+}
type
  [TestFixture]
  UT_GeminiAI = class
  strict private
    fGeminiAI: IGeminiAI;
  public
    [Setup]
    procedure SetUp;
    [TearDown]
    procedure TearDown;
  published
    procedure TestSimpleMathPrompt;
    procedure TestSimpleColorPrompt;
    procedure TestImageInterpretation;
    procedure TestJSONObjectCreation;
    procedure TestPDFInterpretationAsJSONObject;
  end;

implementation

{$I FBConfig.inc}

{ UT_FirebaseStorage }

procedure UT_GeminiAI.SetUp;
begin
  fGeminiAI := TGeminiAI.Create(cGeminiAI);
end;

procedure UT_GeminiAI.TearDown;
begin
  fGeminiAI := nil;
end;

procedure UT_GeminiAI.TestSimpleMathPrompt;
const
  cMathCalc = 'Calculate the sum of 3 and 6. Provide only a number as result.';
var
  Resp: IGeminiAIResponse;
  Res: string;
begin
  Resp := fGeminiAI.GenerateContentByPromptSynchronous(cMathCalc);
  Assert.IsTrue(Resp.IsValid, 'Gemini AI result is not valid: ' + Resp.FailureDetail);
  Res := trim(Resp.ResultAsMarkDown);
  Status('Result of "' + cMathCalc + '": ' + Res);
  Assert.AreEqual(Res, '9', 'Unexpected result of 3+6');
  Assert.IsTrue(Resp.UsageMetaData.PromptTokenCount > 14, 'PromptTokenCount to small: ' +
    Resp.UsageMetaData.PromptTokenCount.ToString);
  Assert.IsTrue(Resp.UsageMetaData.PromptTokenCount < 30, 'PromptTokenCount to large: ' +
    Resp.UsageMetaData.PromptTokenCount.ToString);
  Status('PromptTokenCount: ' + Resp.UsageMetaData.PromptTokenCount.ToString);
  Assert.IsTrue(Resp.UsageMetaData.GeneratedTokenCount > 0, 'GeneratedTokenCount to small: ' +
    Resp.UsageMetaData.GeneratedTokenCount.ToString);
  Assert.IsTrue(Resp.UsageMetaData.GeneratedTokenCount < 3, 'GeneratedTokenCount to large: ' +
    Resp.UsageMetaData.GeneratedTokenCount.ToString);
  Status('GeneratedTokenCount: ' + Resp.UsageMetaData.GeneratedTokenCount.ToString);
  // TotalTokenCount may include thinking tokens (Gemini 2.5+)
  Assert.IsTrue(Resp.UsageMetaData.TotalTokenCount >= Resp.UsageMetaData.PromptTokenCount +
    Resp.UsageMetaData.GeneratedTokenCount, 'TotalTokenCount below Prompt+Generated: ' + Resp.UsageMetaData.TotalTokenCount.ToString);
  Status('Simple math calc prompt succeded');
end;

procedure UT_GeminiAI.TestSimpleColorPrompt;
const
  cColorTheory = 'What color do you get when you mix pure green and blue? Provide only one word of the color.';
var
  Resp: IGeminiAIResponse;
  Res: string;
begin
  Resp := fGeminiAI.GenerateContentByPromptSynchronous(cColorTheory);
  Assert.IsTrue(Resp.IsValid, 'Gemini AI result is not valid: ' + Resp.FailureDetail);
  Res := trim(Resp.ResultAsMarkDown).ToLower;
  Status('Result of "' + cColorTheory + '": ' + Res);
  Assert.AreEqual(Res, 'cyan', 'Unexpected result of green mixed with blue (cyan)');
  Assert.IsTrue(Resp.UsageMetaData.PromptTokenCount > 20, 'PromptTokenCount to small: ' +
    Resp.UsageMetaData.PromptTokenCount.ToString);
  Assert.IsTrue(Resp.UsageMetaData.PromptTokenCount < 40, 'PromptTokenCount to large: ' +
    Resp.UsageMetaData.PromptTokenCount.ToString);
  Status('PromptTokenCount: ' + Resp.UsageMetaData.PromptTokenCount.ToString);
  Assert.IsTrue(Resp.UsageMetaData.GeneratedTokenCount > 0, 'GeneratedTokenCount to small: ' +
    Resp.UsageMetaData.GeneratedTokenCount.ToString);
  Assert.IsTrue(Resp.UsageMetaData.GeneratedTokenCount < 4, 'GeneratedTokenCount to large: ' +
    Resp.UsageMetaData.GeneratedTokenCount.ToString);
  Status('GeneratedTokenCount: ' + Resp.UsageMetaData.GeneratedTokenCount.ToString);
  // TotalTokenCount may include thinking tokens (Gemini 2.5+)
  Assert.IsTrue(Resp.UsageMetaData.TotalTokenCount >= Resp.UsageMetaData.PromptTokenCount +
    Resp.UsageMetaData.GeneratedTokenCount, 'TotalTokenCount below Prompt+Generated: ' + Resp.UsageMetaData.TotalTokenCount.ToString);
  Status('Simple color prompt succeded');
end;

procedure UT_GeminiAI.TestImageInterpretation;
const
  cTestImageFile = '../../TestData/FB4D_UT.png';
  cOCRPrompt = 'What text is in the picture? Replace all line breaks by a ";" character.';
  cExpectedOCR = 'FB4D;Unit;Test';
var
  Request: IGeminiAIRequest;
  Resp: IGeminiAIResponse;
  FileName: string;
  FileStream: TFileStream;
  Res: string;
begin
  FileName := ExpandFileName(ExtractFilePath(ParamStr(0)) + cTestImageFile);
  Assert.IsTrue(FileExists(Filename), 'Test file not found' + FileName);
  FileStream := TFileStream.Create(FileName, fmOpenRead);
  try
    Request := TGeminiAIRequest.Create.PromptWithMediaData(cOCRPrompt, CONTENTTYPE_IMAGE_PNG, FileStream);
    Resp := fGeminiAI.GenerateContentByRequestSynchronous(Request);
    Assert.IsTrue(Resp.IsValid, 'Gemini AI result is not valid: ' + Resp.FailureDetail);
    Res := trim(Resp.ResultAsMarkDown);
    Status('Result of "' + cOCRPrompt + '": ' + Res);
    Assert.IsTrue(SameText(Res, cExpectedOCR), 'Unexpected result: ' + Res);
    Status('PromptTokenCount: ' + Resp.UsageMetaData.PromptTokenCount.ToString);
    Status('GeneratedTokenCount: ' + Resp.UsageMetaData.GeneratedTokenCount.ToString);
    // TotalTokenCount may include thinking tokens (Gemini 2.5+)
    Assert.IsTrue(Resp.UsageMetaData.TotalTokenCount >= Resp.UsageMetaData.PromptTokenCount +
      Resp.UsageMetaData.GeneratedTokenCount, 'TotalTokenCount below Prompt+Generated: ' + Resp.UsageMetaData.TotalTokenCount.ToString);
  finally
    FileStream.Free;
  end;
end;

procedure UT_GeminiAI.TestJSONObjectCreation;
const
  cCreateJSONFormulaOk = 'Create a JSON Object for the following math formula: A * A = A^2';
  cCreateJSONFormulaFail = 'Create a JSON Object for the following math formula: A + B = 2A';
var
  Request: IGeminiAIRequest;
  Resp: IGeminiAIResponse;
  Res: string;
  JO: TJSONObject;
begin
  Request := TGeminiAIRequest.Create.Prompt(cCreateJSONFormulaOk);
  Request.SetJSONResponseSchema(TGeminiSchema.Create.SetObjectType(TSchemaItems.Create(
    [TSchemaItems.CreateItem('FirstFactor', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('SecondFactor', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('ResultingTerm', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('NumberOfFactors', TGeminiSchema.IntegerType),
     TSchemaItems.CreateItem('IsFormulaCorrect', TGeminiSchema.BooleanType)])));
  Resp := fGeminiAI.GenerateContentByRequestSynchronous(Request);
  Assert.IsTrue(Resp.IsValid, 'Gemini AI result is not valid: ' + Resp.FailureDetail);
  Res := trim(Resp.ResultAsMarkDown);
  Status('Result of "' + cCreateJSONFormulaOk + '": ' + Res);
  JO := Resp.ResultAsJSON as TJSONObject;
  Assert.AreEqual(JO.GetValue<string>('FirstFactor'), 'A',
    'Unexpected first factor: ' + JO.GetValue<string>('FirstFactor'));
  Assert.AreEqual(JO.GetValue<string>('SecondFactor'), 'A',
    'Unexpected second factor: ' + JO.GetValue<string>('SecondFactor'));
  Assert.AreEqual(JO.GetValue<string>('ResultingTerm'), 'A^2',
    'Unexpected resulting term: ' + JO.GetValue<string>('ResultingTerm'));
  Assert.AreEqual(JO.GetValue<integer>('NumberOfFactors'), 2,
    'Unexpected number of factors: ' + JO.GetValue<integer>('NumberOfFactors').ToString);
  Assert.IsTrue(JO.GetValue<boolean>('IsFormulaCorrect'), 'Unexpected answer to "is this formula correct');

  Request := TGeminiAIRequest.Create.Prompt(cCreateJSONFormulaFail);
  Request.SetJSONResponseSchema(TGeminiSchema.Create.SetObjectType(TSchemaItems.Create(
    [TSchemaItems.CreateItem('FirstAddend', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('SecondAddend', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('ResultingTerm', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('NumberOfAddends', TGeminiSchema.IntegerType),
     TSchemaItems.CreateItem('IsFormulaCorrect', TGeminiSchema.BooleanType)])));
  Resp := fGeminiAI.GenerateContentByRequestSynchronous(Request);
  Assert.IsTrue(Resp.IsValid, 'Gemini AI result is not valid: ' + Resp.FailureDetail);
  Status('Result of "' + cCreateJSONFormulaFail + '": ' + Resp.ResultAsMarkDown);
  JO := Resp.ResultAsJSON as TJSONObject;
  Assert.AreEqual(JO.GetValue<string>('FirstAddend'), 'A',
    'Unexpected first addend: ' + JO.GetValue<string>('FirstAddend'));
  Assert.AreEqual(JO.GetValue<string>('SecondAddend'), 'B',
    'Unexpected second addend: ' + JO.GetValue<string>('SecondAddend'));
  Assert.AreEqual(JO.GetValue<string>('ResultingTerm'), '2A',
    'Unexpected resulting term: ' + JO.GetValue<string>('ResultingTerm'));
  Assert.AreEqual(JO.GetValue<integer>('NumberOfAddends'), 2,
    'Unexpected number of addends: ' + JO.GetValue<integer>('NumberOfAddends').ToString);
  Assert.IsFalse(JO.GetValue<boolean>('IsFormulaCorrect'), 'Unexpected answer to "is this formula correct');
end;

procedure UT_GeminiAI.TestPDFInterpretationAsJSONObject;
const
  cTestPDFFile = '../../TestData/Invoice.pdf';
  cOCRPrompt =
    '''
    Take from this invoice the reason for payment, the invoice amount
    with the tax amount and tax rate and the currency, the IBAN
    number and the payment date, the address of the invoice issuer
    and the recipient as well as the invoice number. In case of multiline
    fields seperate by ; character.
    ''';
var
  Request: IGeminiAIRequest;
  Resp: IGeminiAIResponse;
  FileName: string;
  FileStream: TFileStream;
  JO: TJSONObject;
  Reason, Addr: string;
  sl: TStringList;
begin
  FileName := ExpandFileName(ExtractFilePath(ParamStr(0)) + cTestPDFFile);
  Assert.IsTrue(FileExists(Filename), 'Test file not found' + FileName);
  FileStream := TFileStream.Create(FileName, fmOpenRead);
  try
    Request := TGeminiAIRequest.Create.PromptWithMediaData(cOCRPrompt, CONTENTTYPE_APPLICATION_PDF, FileStream);
    Request.SetJSONResponseSchema(TGeminiSchema.Create.SetObjectType(TSchemaItems.Create(
        [TSchemaItems.CreateItem('ReasonOfPayment', TGeminiSchema.StringType),
         TSchemaItems.CreateItem('Amount', TGeminiSchema.FloatType),
         TSchemaItems.CreateItem('Currency', TGeminiSchema.StringType),
         TSchemaItems.CreateItem('Tax', TGeminiSchema.FloatType),
         TSchemaItems.CreateItem('TaxRate', TGeminiSchema.FloatType),
         TSchemaItems.CreateItem('IBAN', TGeminiSchema.StringType),
         TSchemaItems.CreateItem('InvoiceIssuerNameAndAddress', TGeminiSchema.StringType),
         TSchemaItems.CreateItem('ReceiverNameAndAddress', TGeminiSchema.StringType),
         TSchemaItems.CreateItem('InvoiceNumber', TGeminiSchema.IntegerType),
         TSchemaItems.CreateItem('InvoiceDate', TGeminiSchema.StringType),
         TSchemaItems.CreateItem('DateOfPayment', TGeminiSchema.StringType)])));
    Resp := fGeminiAI.GenerateContentByRequestSynchronous(Request);
    JO := Resp.ResultAsJSON as TJSONObject;
    Status('Resulting JSON object');
    sl := TStringList.Create;
    try
      sl.Text := Resp.ResultAsJSON.Format;
      for var line in sl do
        Status(line);
    finally
      sl.Free;
    end;
    Reason := StringReplace(JO.GetValue<string>('ReasonOfPayment'), #$A, ' ', [rfReplaceAll]);
    Reason := Trim(StringReplace(StringReplace(Reason, ';', ' ', [rfReplaceAll]), '  ', ' ', [rfReplaceAll]));
    if SameText(Reason, 'Software Consulting') or
       Reason.ToLower.Contains('integration of gemini') or
       Reason.ToLower.Contains('supporting the integration') then
    else
      Assert.Fail( 'Unexpected reason of payment: ' + Reason);
    Assert.AreEqual(JO.GetValue<extended>('Amount'), 8442.60,
      'Unexpected Amount: ' + JO.GetValue<string>('Amount'));
    Assert.AreEqual(JO.GetValue<string>('Currency'), 'CHF',
      'Unexpected Currency: ' + JO.GetValue<string>('Currency'));
    Addr := StringReplace(JO.GetValue<string>('InvoiceIssuerNameAndAddress'), #$A, ';', [rfReplaceAll]);
    Addr := StringReplace(Addr, '; ', ';', [rfReplaceAll]);
    Assert.AreEqual(Addr, 'Schneider Infosystems AG;Mühlegasse 18;CH-6340 Baar',
      'Unexpected InvoiceIssuerNameAndAddress: ' + Addr);
    Addr := StringReplace(JO.GetValue<string>('ReceiverNameAndAddress'), #$A, ';', [rfReplaceAll]);
    Addr := StringReplace(Addr, '; ', ';', [rfReplaceAll]);
    Assert.AreEqual(Addr, 'Northern Lights Software Inc.;Mr. James Bob;100 King Street West;M5X 1A9 Toronto, ON;Canada',
      'Unexpected ReceiverNameAndAddress: ' + Addr);
    Assert.AreEqual(JO.GetValue<string>('DateOfPayment'), '18-Feb-2025',
      'Unexpected DateOfPayment: ' + JO.GetValue<string>('DateOfPayment'));
    Assert.AreEqual(JO.GetValue<string>('IBAN'), 'CH32 0078 7000 4729 3960 9',
      'Unexpected IBAN: ' + JO.GetValue<string>('IBAN'));
    Assert.AreEqual(JO.GetValue<string>('InvoiceDate'), '8-Feb-2025',
      'Unexpected InvoiceDate: ' + JO.GetValue<string>('InvoiceDate'));
    Assert.AreEqual(JO.GetValue<integer>('InvoiceNumber'), 4711,
      'Unexpected InvoiceNumber: ' + JO.GetValue<string>('InvoiceNumber'));
    Assert.AreEqual(JO.GetValue<extended>('Tax'), 632.60,
      'Unexpected Tax: ' + JO.GetValue<string>('Tax'));
    Assert.AreEqual(JO.GetValue<extended>('TaxRate'), 8.1,
      'Unexpected Tax: ' + JO.GetValue<string>('TaxRate'));
    Status('All JSON field check passed');
    Status('PromptTokenCount: ' + Resp.UsageMetaData.PromptTokenCount.ToString);
    Status('GeneratedTokenCount: ' + Resp.UsageMetaData.GeneratedTokenCount.ToString);
    // TotalTokenCount may include thinking tokens (Gemini 2.5+)
    Assert.IsTrue(Resp.UsageMetaData.TotalTokenCount >= Resp.UsageMetaData.PromptTokenCount +
      Resp.UsageMetaData.GeneratedTokenCount, 'TotalTokenCount below Prompt+Generated: ' + Resp.UsageMetaData.TotalTokenCount.ToString);
  finally
    FileStream.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(UT_GeminiAI);
end.
