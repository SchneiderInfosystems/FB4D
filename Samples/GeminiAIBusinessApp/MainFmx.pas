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

unit MainFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl, FMX.StdCtrls, FMX.ListBox, FMX.Objects,
  FMX.Edit, FMX.Controls.Presentation, FMX.MultiView, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FB4D.Interfaces, FMX.Layouts, FMX.WebBrowser;

type
  TfmxMain = class(TForm)
    TabControl: TTabControl;
    TabInvoice: TTabItem;
    TabCustomerEmailInterpretation: TTabItem;
    TabItemLogisticGoodInspection: TTabItem;
    tabSettings: TTabItem;
    btnSave: TButton;
    cboAPIVersion: TComboBox;
    edtGeminiAPIKey: TEdit;
    rctGeminiAPIKeyDisabled: TRectangle;
    edtModelName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    lblGeminiAPIKey: TLabel;
    btnLoadInvoicePDF: TButton;
    edtInvoicePDF: TEdit;
    memInvoice: TMemo;
    btnStartInvoice: TButton;
    OpenDialogPDF: TOpenDialog;
    memInvoicePrompt: TMemo;
    lblPrompt: TLabel;
    aniInvoice: TAniIndicator;
    Label3: TLabel;
    memCustomerMail: TMemo;
    btnStartMailInterpretation: TButton;
    aniCustomerMail: TAniIndicator;
    btnCreateDemoMail: TButton;
    layCustomerMail: TLayout;
    layMailInterpretation: TLayout;
    Splitter1: TSplitter;
    lblMailTitle: TLabel;
    lblMailDescription: TLabel;
    lblMailSender: TLabel;
    edtMailSender: TEdit;
    memMailSummary: TMemo;
    edtMailDate: TEdit;
    edtMailPrio: TEdit;
    edtCategory: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    edtRef: TEdit;
    Label7: TLabel;
    lstActions: TListBox;
    Label8: TLabel;
    edtRoleTitle: TEdit;
    Label9: TLabel;
    Label10: TLabel;
    edtEmotionality: TEdit;
    edtRefKind: TEdit;
    btnSaveEMail: TButton;
    btnLoadEMail: TButton;
    OpenDialogTxt: TOpenDialog;
    SaveDialogTxt: TSaveDialog;
    cboEMailSubject: TComboBox;
    edtCompanyName: TEdit;
    Rectangle1: TRectangle;
    Text1: TText;
    Rectangle2: TRectangle;
    Text2: TText;
    layInvoiceRequest: TLayout;
    Rectangle3: TRectangle;
    Text3: TText;
    Splitter2: TSplitter;
    layInvoiceResult: TLayout;
    Rectangle4: TRectangle;
    Text4: TText;
    btnClear: TButton;
    Layout1: TLayout;
    aniGoodInspection: TAniIndicator;
    btnCreateItemListAndPhoto: TButton;
    btnStartGoodInspection: TButton;
    Label11: TLabel;
    memPhotoDesc: TMemo;
    btnSavePackage: TButton;
    btnLoadPackage: TButton;
    cboSzenario: TComboBox;
    Rectangle5: TRectangle;
    Text5: TText;
    btnClearPackage: TButton;
    Layout2: TLayout;
    Rectangle6: TRectangle;
    Text6: TText;
    lblOperatorHint: TLabel;
    memGoodInspectionResult: TMemo;
    Splitter3: TSplitter;
    imgPackageContent: TImage;
    edtMimeType: TEdit;
    lstItemList: TListBox;
    CircleState: TCircle;
    GridPanelLayout1: TGridPanelLayout;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    lstMissingItems: TListBox;
    lstFoundItems: TListBox;
    lstSurplusItems: TListBox;
    Layout3: TLayout;
    WebBrowser: TWebBrowser;
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnStartInvoiceClick(Sender: TObject);
    procedure btnLoadInvoicePDFClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCreateDemoMailClick(Sender: TObject);
    procedure btnStartMailInterpretationClick(Sender: TObject);
    procedure btnLoadEMailClick(Sender: TObject);
    procedure btnSaveEMailClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure cboEMailSubjectChange(Sender: TObject);
    procedure btnCreateItemListAndPhotoClick(Sender: TObject);
    procedure btnSavePackageClick(Sender: TObject);
    procedure btnLoadPackageClick(Sender: TObject);
    procedure btnStartGoodInspectionClick(Sender: TObject);
  private
    fGeminiAI: IGeminiAI;
    procedure CreateGeminiAI(const UseAlternativeModelName: string = '');
    procedure SaveSettings;
    function GetSettingFilename: string;
    procedure OnInvoiceInterpreted(Response: IGeminiAIResponse);
    procedure OnCustomerMailCreated(Response: IGeminiAIResponse);
    procedure OnCustomerMailInterpreted(Response: IGeminiAIResponse);
    procedure OnPhotoCreated4GoodInspection(Response: IGeminiAIResponse);
    procedure OnItemListCreated4GoodInspection(Response: IGeminiAIResponse);
    procedure OnGoodInspected(Response: IGeminiAIResponse);
  end;

var
  fmxMain: TfmxMain;

implementation

uses
  System.IniFiles, System.IOUtils, System.JSON, System.NetEncoding,
  REST.Types,
  FB4D.GeminiAI, FB4D.Helpers;

{$R *.fmx}

const
  cDefInvoicePDF = '../../../../DUnitX/TestData/Invoice.pdf';
  cInvoicePrompt =
    '''
    Take from this invoice the reason for payment, the invoice amount with the tax amount and tax rate
    and the currency, the IBAN number and the payment date, the address of the invoice issuer
    and the recipient as well as the invoice number. In case of multiline fields seperate by ; character.
    ''';
  cDefaultCustomerMail = 'Write here a customer email or load one from text file.';
  cCreateCustomerMail =
    '''
    Write a fictitious customer email for the software company Schneider Infosystems Corp
    (support@schneider-infosys.ch) that has a CRM on the market with for the following topic: "%s".
    The email should be written as realistic as possible from a fictitious business customer and be 10 to 20 lines long.
    Add a license number, or a quotation number, or an invoice number, or a support case number for referencing.
    ''';
  cSytemInstruction = #13#10 + 'System Instructions:'#13#10;
  cWriteCompact =
    '''
    Write the email as concisely as possible, avoiding double spaces.
    Do not use placeholders, but use fictitious data everywhere.
    Add always a date of mail, sender name, company name and mail address and mostly a job title too.
    ''';
  cInterpreteCustomerMail =
    '''
    There is customer email in the prompt text that needs to be processed and interpreted.
    Can you interpret the content of the mail and fill the JSON field for further processing in a CRM?
    ''';
  cCreatePhotoOfPackageForLaptop =
    '''
    Create a photorealistic, top-down or slightly angled shot of an opened cardboard shipping box on a neutral surface,
    like a warehouse inspection table. The protective packaging (bubble wrap, foam inserts) is visible, pushed aside.
    The following items are clearly laid out beside or partially in the box:
    A sleek, modern laptop (e.g., silver or dark grey).
    A black laptop power adapter with its neatly coiled cable.
    A premium padded laptop sleeve (e.g., neoprene, dark grey or black).
    A compact USB-C docking station with multiple ports visible.
    A small "Welcome Kit" envelope or thin booklet.
    ''';
  cCreateItemList = 'In addition to the generated image, a linear item list for the product view (without sub-items, titles) is required in the text output. Do not add any explanations and start each line with a "*" character';
  cModelForImagen = 'gemini-2.0-flash-exp-image-generation';
  cGoodInspection = 'Check the following packing list on the enclosed photo of the incoming goods for %s: '#13#10'%s';
  cGoodInspectionInstruction = 'List here the articles that are missing.';

procedure TfmxMain.FormShow(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtGeminiAPIKey.Text := IniFile.ReadString('GeminiAI', 'APIKey', '');
    edtModelName.Text := IniFile.ReadString('GeminiAI', 'ModelName', cGeminiAIPro2_5);
    TGeminiAI.SetListOfAPIVersions(cboAPIVersion.Items);
    cboAPIVersion.ItemIndex := cboAPIVersion.Items.IndexOf(IniFile.ReadString('GeminiAI', 'APIVersion', ''));
    if cboAPIVersion.ItemIndex < 0 then
      cboAPIVersion.ItemIndex := ord(cDefaultGeminiAPIVersion);
    edtInvoicePDF.Text := IniFile.ReadString('Invoice', 'PDFileName', ExpandFileName(cDefInvoicePDF));
    WebBrowser.Navigate('file:/' + StringReplace(edtInvoicePDF.Text, '\', '/', [rfReplaceAll]));
    memInvoicePrompt.Lines.Text := TNetEncoding.URL.Decode(IniFile.ReadString('Invoice', 'Prompt', cInvoicePrompt));
    memCustomerMail.Lines.Text := TNetEncoding.URL.Decode(IniFile.ReadString('CustomerMail', 'Mail', cDefaultCustomerMail));
    if edtGeminiAPIKey.Text.IsEmpty or edtModelName.Text.IsEmpty then
    begin
      TabControl.ActiveTab := tabSettings;
      TabInvoice.Visible := false;
      TabCustomerEmailInterpretation.Visible := false;
      TabItemLogisticGoodInspection.Visible := false;
    end else begin
      TabControl.ActiveTab := TabControl.Tabs[IniFile.ReadInteger('GUI', 'ActiveTab', 0)];
    end;
  finally
    IniFile.Free;
  end;
  btnStartInvoice.Hint := cInvoicePrompt;
  btnCreateDemoMail.Hint := cCreateCustomerMail + cSytemInstruction + cWriteCompact;
  btnStartMailInterpretation.Hint := cInterpreteCustomerMail;
end;

procedure TfmxMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
end;

procedure TfmxMain.btnSaveClick(Sender: TObject);
begin
  SaveSettings;
  TabInvoice.Visible := true;
  TabCustomerEmailInterpretation.Visible := true;
  TabItemLogisticGoodInspection.Visible := true;
  TabControl.ActiveTab := TabInvoice;
end;

function TfmxMain.GetSettingFilename: string;
begin
  result := IncludeTrailingPathDelimiter(
{$IFDEF IOS}
    TPath.GetDocumentsPath
{$ELSE}
    TPath.GetHomePath
{$ENDIF}
    ) + ChangeFileExt(ExtractFileName(ParamStr(0)), '') + TFirebaseHelpers.GetPlatform + '.ini';
end;

procedure TfmxMain.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('GeminiAI', 'APIKey', edtGeminiAPIKey.Text);
    IniFile.WriteString('GeminiAI', 'ModelName', edtModelName.Text);
    if cboAPIVersion.ItemIndex >= 0 then
      IniFile.WriteString('GeminiAI', 'APIVersion', cboAPIVersion.Items[cboAPIVersion.ItemIndex]);
    IniFile.WriteInteger('GUI', 'ActiveTab', TabControl.ActiveTab.Index);
    IniFile.WriteString('Invoice', 'PDFileName', edtInvoicePDF.Text);
    IniFile.WriteString('Invoice', 'Prompt', TNetEncoding.URL.Encode(memInvoicePrompt.Lines.Text));
    IniFile.WriteString('CustomerMail', 'Mail', TNetEncoding.URL.Encode(memCustomerMail.Lines.Text));
  finally
    IniFile.Free;
  end;
end;

procedure TfmxMain.CreateGeminiAI(const UseAlternativeModelName: string = '');
var
  ModelName: string;
begin
  if UseAlternativeModelName.IsEmpty then
    ModelName := edtModelName.Text
  else
    ModelName := UseAlternativeModelName;
  fGeminiAI := TGeminiAI.Create(edtGeminiAPIKey.Text, ModelName, TGeminiAPIVersion(cboAPIVersion.ItemIndex));
end;

{$REGION 'ERP - Invoice Interpretation'}
procedure TfmxMain.btnLoadInvoicePDFClick(Sender: TObject);
begin
  if OpenDialogPDF.Execute then
  begin
    edtInvoicePDF.Text := OpenDialogPDF.FileName;
    WebBrowser.Navigate('file:/' + StringReplace(edtInvoicePDF.Text, '\', '/', [rfReplaceAll]));
  end;
end;

procedure TfmxMain.btnStartInvoiceClick(Sender: TObject);
var
  Request: IGeminiAIRequest;
  FileStream: TFileStream;
begin
  CreateGeminiAI;
  memInvoice.Lines.Clear;
  FileStream := TFileStream.Create(edtInvoicePDF.Text, fmOpenRead);
  try
    Request := TGeminiAIRequest.Create.PromptWithMediaData(memInvoicePrompt.Lines.Text, CONTENTTYPE_APPLICATION_PDF,
      FileStream);
    Request.SetJSONResponseSchema(TGeminiSchema.Create.SetObjectType(TSchemaItems.Create(
      [TSchemaItems.CreateItem('ReasonOfPayment', TGeminiSchema.StringType),
       TSchemaItems.CreateItem('Amount', TGeminiSchema.FloatType),
       TSchemaItems.CreateItem('Currency', TGeminiSchema.StringType),
       TSchemaItems.CreateItem('Tax', TGeminiSchema.FloatType),
       TSchemaItems.CreateItem('TaxRate', TGeminiSchema.FloatType),
       TSchemaItems.CreateItem('IBAN', TGeminiSchema.StringType),
       TSchemaItems.CreateItem('InvoiceIssuerNameAndAddress', TGeminiSchema.StringType),
       TSchemaItems.CreateItem('ReceiverNameAndAddress', TGeminiSchema.StringType),
       TSchemaItems.CreateItem('InvoiceNumber', TGeminiSchema.StringType),
       TSchemaItems.CreateItem('InvoiceDate', TGeminiSchema.StringType),
       TSchemaItems.CreateItem('DateOfPayment', TGeminiSchema.StringType)])));
    fGeminiAI.GenerateContentByRequest(Request, OnInvoiceInterpreted);
    aniInvoice.Enabled := true;
    aniInvoice.visible := true;
  finally
    FileStream.Free;
  end;
end;

procedure TfmxMain.OnInvoiceInterpreted(Response: IGeminiAIResponse);
var
  JO: TJSONObject;
  DelayedScrollDown: integer;
begin
  if not Response.IsValid then
  begin
    memInvoice.Lines.Text := 'Failed: ' + Response.FailureDetail;
    aniInvoice.Enabled := false;
    aniInvoice.visible := false;
  end else begin
    JO := Response.ResultAsJSON as TJSONObject;
    memInvoice.TextSettings.Font.Size := 12;
    memInvoice.Lines.Text := 'JSON = ' + JO.Format;
    DelayedScrollDown := memInvoice.Lines.Count;
    memInvoice.Lines.Add('Invoice processed');
    memInvoice.Lines.Add('Reason of Payment . : ' + JO.GetValue<string>('ReasonOfPayment'));
    memInvoice.Lines.Add('Amount ............ : ' + JO.GetValue<extended>('Amount').ToString + ' ' +
      JO.GetValue<string>('Currency'));
    memInvoice.Lines.Add('Tax and Tax rate .. : ' + JO.GetValue<extended>('Tax').ToString + ' / ' +
      JO.GetValue<extended>('TaxRate').ToString);
    memInvoice.Lines.Add('Invoice issuer .... : ' + JO.GetValue<string>('InvoiceIssuerNameAndAddress'));
    memInvoice.Lines.Add('Receiver .......... : ' + JO.GetValue<string>('ReceiverNameAndAddress'));
    memInvoice.Lines.Add('Due date of payment : ' + JO.GetValue<string>('DateOfPayment'));
    memInvoice.Lines.Add('Interbanking number : ' + JO.GetValue<string>('IBAN'));
    memInvoice.Lines.Add('Invoice Number .... : ' + JO.GetValue<string>('InvoiceNumber'));
    memInvoice.Lines.Add('Invoice Date ...... : ' + JO.GetValue<string>('InvoiceDate'));
    TThread.CreateAnonymousThread(
      procedure
      begin
        for var c := 0 to 10 do
        begin
          Sleep(300);
          if Application.Terminated then
            exit;
        end;
        TThread.Queue(nil,
          procedure
          begin
            aniInvoice.Enabled := false;
            aniInvoice.visible := false;
            memInvoice.TextSettings.Font.Size := 15;
            memInvoice.ScrollBy(0, 9999);
          end);
      end).Start;
  end;
end;
{$ENDREGION}

{$REGION 'CRM - Customer EMail Interpretation'}
procedure TfmxMain.btnLoadEMailClick(Sender: TObject);
begin
  if OpenDialogTxt.Execute then
    memCustomerMail.Lines.LoadFromFile(OpenDialogTxt.FileName);
end;

procedure TfmxMain.btnSaveEMailClick(Sender: TObject);
begin
  if SaveDialogTxt.Execute then
    memCustomerMail.Lines.SaveToFile(SaveDialogTxt.FileName);
end;

procedure TfmxMain.btnClearClick(Sender: TObject);
begin
  memCustomerMail.Lines.Text := cDefaultCustomerMail;
  lblMailTitle.Text :=  '';
  memMailSummary.Lines.Clear;
  edtMailSender.Text := '';
  edtMailDate.Text := '';
  edtCompanyName.Text := '';
  edtRoleTitle.Text := '';
  edtMailPrio.Text := '';
  edtCategory.Text := '';
  edtEmotionality.Text := '';
  edtRef.Text := '';
  edtRefKind.Text := '';
  lstActions.Clear;
end;

procedure TfmxMain.btnCreateDemoMailClick(Sender: TObject);
begin
  CreateGeminiAI;
  fGeminiAI.GenerateContentByRequest(TGeminiAIRequest.Create.Prompt(
    Format(cCreateCustomerMail, [cboEMailSubject.Text]), cWriteCompact),
    OnCustomerMailCreated);
  aniCustomerMail.Enabled := true;
  aniCustomerMail.Visible := true;
end;

procedure TfmxMain.OnCustomerMailCreated(Response: IGeminiAIResponse);
begin
  aniCustomerMail.Enabled := false;
  aniCustomerMail.Visible := false;
  if not Response.IsValid then
    memCustomerMail.Lines.Text := 'Failed: ' + Response.FailureDetail
  else
    memCustomerMail.Lines.Text := Response.ResultAsMarkDown;
end;

procedure TfmxMain.btnStartMailInterpretationClick(Sender: TObject);
var
  Request: IGeminiAIRequest;
begin
  CreateGeminiAI;
  Request := TGeminiAIRequest.Create.Prompt(memCustomerMail.Lines.Text, cInterpreteCustomerMail);
  Request.SetJSONResponseSchema(TGeminiSchema.Create.SetObjectType(TSchemaItems.Create(
    [TSchemaItems.CreateItem('Title', TGeminiSchema.StringType.
       SetDescription('Shall contain a single sentence with max 80 characters')),
     TSchemaItems.CreateItem('Description', TGeminiSchema.StringType.
       SetDescription('Shall summerize the email')),
     TSchemaItems.CreateItem('SenderName', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('CompanyName', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('SenderEmail', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('SenderRoleTitle', TGeminiSchema.StringType),
     TSchemaItems.CreateItem('DateOfEMail', TGeminiSchema.StringType.
       SetDescription('Shall be formated like "19-May-2025"')),
     TSchemaItems.CreateItem('Reference', TGeminiSchema.StringType.
       SetDescription('shall contain the provided customer reference number. See ReferenceKind field about the source')),
     TSchemaItems.CreateItem('ReferenceKind', TGeminiSchema.EnumType(
       ['Invoice Number', 'Quote NumberOrder', 'Customer Number', 'License Number', 'Unknown'])),
     TSchemaItems.CreateItem('Category', TGeminiSchema.EnumType(
       ['Get quote', 'Order', 'Invoice', 'Complaint', 'Technical question', 'Bug Report', 'Others'])),
     TSchemaItems.CreateItem('Emotionality', TGeminiSchema.EnumType(
       ['Neutral-Objective', 'Positive-Supportive', 'Negative-Critical'])),
     TSchemaItems.CreateItem('Priority', TGeminiSchema.EnumType(
       ['management attention', 'urgent', 'normal', 'low']).
       SetDescription('Use "management attention" only if the sale depends on the response to this email; ' +
                      'Use "urgent" in cases where the customer waits for a response and cannot continue working')),
     TSchemaItems.CreateItem('Actions', TGeminiSchema.ArrayType(TGeminiSchema.StringType, 0).
       SetDescription('Shall contain a sorted list of required action in order to processing this customer email'))])));
  fGeminiAI.GenerateContentByRequest(Request, OnCustomerMailInterpreted);
  aniCustomerMail.Enabled := true;
  aniCustomerMail.Visible := true;
end;

procedure TfmxMain.cboEMailSubjectChange(Sender: TObject);
begin
  btnClearClick(nil);
end;

procedure TfmxMain.OnCustomerMailInterpreted(Response: IGeminiAIResponse);
var
  JO: TJSONObject;
  JOArr: TJSONArray;
  c: integer;
begin
  aniCustomerMail.Enabled := false;
  aniCustomerMail.Visible := false;
  if not Response.IsValid then
    memMailSummary.Lines.Text := 'Failed: ' + Response.FailureDetail
  else begin
    JO := Response.ResultAsJSON as TJSONObject;
    {$IFDEF DEBUG}
    FMX.Types.Log.d(JO.Format(4));
    {$ENDIF}
    try
      lblMailTitle.Text :=  JO.GetValue<string>('Title');
      memMailSummary.Lines.Text := JO.GetValue<string>('Description');
      edtMailSender.Text := JO.GetValue<string>('SenderName') + ' <' + JO.GetValue<string>('SenderEmail') + '>';
      edtMailDate.Text := JO.GetValue<string>('DateOfEMail');
      edtCompanyName.Text := JO.GetValue<string>('CompanyName');
      edtRoleTitle.Text := JO.GetValue<string>('SenderRoleTitle');
      edtMailPrio.Text := JO.GetValue<string>('Priority');
      edtCategory.Text := JO.GetValue<string>('Category');
      edtEmotionality.Text := JO.GetValue<string>('Emotionality');
      edtRef.Text := JO.GetValue<string>('Reference');
      edtRefKind.Text := JO.GetValue<string>('ReferenceKind');
      lstActions.Clear;
      JOArr := JO.GetValue<TJSONArray>('Actions');
      for c := 0 to JOArr.Count - 1 do
        lstActions.items.Add(IntToStr(c + 1) + ': ' + JOArr.Items[c].GetValue<string>);
    except
      on e: exception do
        memMailSummary.Lines.Add('Failure in returning JSON object: ' + e.Message);
    end;
  end;
end;
{$ENDREGION}

{$REGION 'ERP - Good Inspection'}
procedure TfmxMain.btnCreateItemListAndPhotoClick(Sender: TObject);
begin
  CreateGeminiAI(cModelForImagen);
  lstItemList.Clear;
  memPhotoDesc.Lines.Clear;
  imgPackageContent.Bitmap.Clear(TAlphaColorRec.White);
  fGeminiAI.GenerateContentByRequest(TGeminiAIRequest.Create.Prompt(
    cCreatePhotoOfPackageForLaptop).
    SetResponseModalities([mText, mImage]), OnPhotoCreated4GoodInspection);
  aniGoodInspection.Enabled := true;
  aniGoodInspection.Visible := true;
end;

procedure TfmxMain.OnPhotoCreated4GoodInspection(Response: IGeminiAIResponse);
var
  AIRes: TGeminiAIResult;
  MimeType: string;
  Media: TStream;
begin
  aniGoodInspection.Enabled := false;
  aniGoodInspection.Visible := false;
  if not Response.IsValid then
    memPhotoDesc.Lines.Text := 'Failed: ' + Response.FailureDetail
  else begin
    memPhotoDesc.Lines.Text := Response.ResultAsMarkDown;
    if Response.NumberOfResults >= 1 then
    begin
      AIRes := Response.EvalResult(0);
      if length(AIRes.PartMediaData) >= 1 then
      begin
        Media := AIRes.ResultingMediaDataStream(MimeType, 0);
        try
          edtMimeType.Text := MimeType;
          if TFirebaseHelpers.IsSupportImageType(MimeType) then
            imgPackageContent.Bitmap.LoadFromStream(Media)
          else
            memPhotoDesc.Lines.Add('Unsupported media data type: ' + MimeType);
        finally
          Media.Free;
        end;
        CreateGeminiAI; // Use again standard model
        fGeminiAI.GenerateContentByRequest(TGeminiAIRequest.Create.Prompt(
          cCreatePhotoOfPackageForLaptop, cCreateItemList),
          OnItemListCreated4GoodInspection);
        aniGoodInspection.Enabled := true;
        aniGoodInspection.Visible := true;
      end;
    end;
  end;
end;

procedure TfmxMain.OnItemListCreated4GoodInspection(Response: IGeminiAIResponse);
begin
  aniGoodInspection.Enabled := false;
  aniGoodInspection.Visible := false;
  if not Response.IsValid then
    lstItemList.Items.Add('Failed: ' + Response.FailureDetail)
  else begin
    lstItemList.Items.Text := Response.ResultAsMarkDown;
  end;
end;

procedure TfmxMain.btnSavePackageClick(Sender: TObject);
var
  FileName: string;
begin
  FileName := StringReplace(cboSzenario.Text, ' ', '-', [rfReplaceAll]);
  if not imgPackageContent.Bitmap.IsEmpty then
    imgPackageContent.Bitmap.SaveToFile(FileName + TFirebaseHelpers.ContentTypeToFileExt(edtMimeType.Text));
  if not lstItemList.Items.Text.IsEmpty then
    lstItemList.Items.SaveToFile(FileName + '.lst');
end;

procedure TfmxMain.btnLoadPackageClick(Sender: TObject);
var
  FileName: string;
begin
  FileName := StringReplace(cboSzenario.Text, ' ', '-', [rfReplaceAll]);
  if FileExists(FileName + '.jpg') then
  begin
    imgPackageContent.Bitmap.LoadFromFile(FileName + '.jpg');
    edtMimeType.Text := TRESTContentType.ctIMAGE_JPEG;
  end
  else if FileExists(FileName + '.png') then
  begin
    imgPackageContent.Bitmap.LoadFromFile(FileName + '.png');
    edtMimeType.Text := TRESTContentType.ctIMAGE_PNG;
  end
  else if FileExists(FileName + '.gif') then
  begin
    imgPackageContent.Bitmap.LoadFromFile(FileName + '.gif');
    edtMimeType.Text := TRESTContentType.ctIMAGE_GIF;
  end;
  if FileExists(FileName + '.lst') then
    lstItemList.Items.LoadFromFile(FileName + '.lst');
end;

procedure TfmxMain.btnStartGoodInspectionClick(Sender: TObject);
var
  ArticleList: string;
  c: integer;
begin
  ArticleList := '';
  for c := 0 to lstItemList.Count -1 do
    ArticleList := ArticleList + '* ' + lstItemList.Items[c];
  if ArticleList.IsEmpty then
    ShowMessage('Articel list is empty. Cannot do the good inspection without a valid articel list!')
  else begin
    CreateGeminiAI;
    fGeminiAI.GenerateContentByRequest(TGeminiAIRequest.Create.Prompt(
      Format(cGoodInspection, [cboSzenario.Text, ArticleList]), cGoodInspectionInstruction).
      SetJSONResponseSchema(TGeminiSchema.Create.SetObjectType(TSchemaItems.Create(
        [TSchemaItems.CreateItem('InspectionState', TGeminiSchema.EnumType(
           ['Ok', 'Failed'])),
         TSchemaItems.CreateItem('FoundItems', TGeminiSchema.ArrayType(TGeminiSchema.StringType)),
         TSchemaItems.CreateItem('MissingItems', TGeminiSchema.ArrayType(TGeminiSchema.StringType)),
         TSchemaItems.CreateItem('SurplusItems', TGeminiSchema.ArrayType(TGeminiSchema.StringType)),
         TSchemaItems.CreateItem('HumanReadableHint', TGeminiSchema.StringType.
           SetDescription('This message will be displayed to the inspector'))]))),
         OnGoodInspected);
    aniGoodInspection.Enabled := true;
    aniGoodInspection.Visible := true;
  end;
end;

procedure TfmxMain.OnGoodInspected(Response: IGeminiAIResponse);
var
  JO: TJSONObject;
  JOArr: TJSONArray;
  c: integer;
begin
  aniGoodInspection.Enabled := false;
  aniGoodInspection.Visible := false;
  lstMissingItems.Clear;
  lstFoundItems.Clear;
  lstSurplusItems.Clear;
  CircleState.Fill.Color := TAlphaColorRec.Gray;
  if not Response.IsValid then
    memGoodInspectionResult.Lines.Text := 'Failed: ' + Response.FailureDetail
  else begin
    JO := Response.ResultAsJSON as TJSONObject;
    {$IFDEF DEBUG}
    FMX.Types.Log.d(JO.Format(4));
    {$ENDIF}
    try
      if JO.GetValue<string>('InspectionState') = 'Ok' then
        CircleState.Fill.Color := TAlphaColorRec.Lime
      else if JO.GetValue<string>('InspectionState') = 'Failed' then
        CircleState.Fill.Color := TAlphaColorRec.Red
      else
        CircleState.Fill.Color := TAlphaColorRec.Yellow;
      memGoodInspectionResult.Lines.Text := JO.GetValue<string>('HumanReadableHint');
      JOArr := JO.GetValue<TJSONArray>('MissingItems');
      for c := 0 to JOArr.Count - 1 do
        lstMissingItems.items.Add(IntToStr(c + 1) + ': ' + JOArr.Items[c].GetValue<string>);
      JOArr := JO.GetValue<TJSONArray>('FoundItems');
      for c := 0 to JOArr.Count - 1 do
        lstFoundItems.items.Add(IntToStr(c + 1) + ': ' + JOArr.Items[c].GetValue<string>);
      JOArr := JO.GetValue<TJSONArray>('SurplusItems');
      for c := 0 to JOArr.Count - 1 do
        lstSurplusItems.items.Add(IntToStr(c + 1) + ': ' + JOArr.Items[c].GetValue<string>);
    except
      on e: exception do
        memGoodInspectionResult.Lines.Add('Failure in returning JSON object: ' + e.Message);
    end;
  end;
end;

{$ENDREGION}
end.
