unit FB4D.GeminiAIFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IniFiles,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.WebBrowser, FMX.ScrollBox, FMX.Memo, FMX.Edit,
  FMX.Controls.Presentation, FMX.ListBox, FMX.Objects, FMX.TabControl, FMX.Layouts,
  WebBrowserFmx,
  FB4D.Interfaces;

type
  TGeminiAIFra = class(TFrame)
    lblGeminiAPIKey: TLabel;
    edtGeminiAPIKey: TEdit;
    lblGeminiPrompt: TLabel;
    memGeminiPrompt: TMemo;
    btnGeminiGenerateContent: TButton;
    cboGeminiModel: TComboBox;
    rctGeminiAPIKeyDisabled: TRectangle;
    imgMediaFile: TImage;
    edtMediaFileType: TEdit;
    bntLoadImage: TButton;
    OpenDialogImgFile: TOpenDialog;
    rctImage: TRectangle;
    TabControlResult: TTabControl;
    tabHTMLRes: TTabItem;
    tabRawResult: TTabItem;
    memRawJSONResult: TMemo;
    tabMetadata: TTabItem;
    lstMetaData: TListBox;
    tabMarkdownRes: TTabItem;
    memMarkdown: TMemo;
    expGeminiCfg: TExpander;
    chbUseModelParams: TCheckBox;
    Label1: TLabel;
    Label2: TLabel;
    trbTemperature: TTrackBar;
    lblTempValue: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    trbMaxOutputToken: TTrackBar;
    lblMaxOutToken: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    layModelParams: TLayout;
    Label7: TLabel;
    trbTopK: TTrackBar;
    lblTopK: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    trbTopP: TTrackBar;
    lblTopP: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    layPrompt: TLayout;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    memStopSequences: TMemo;
    Label17: TLabel;
    Label18: TLabel;
    chbUseSafetySettings: TCheckBox;
    laySafetySettings: TLayout;
    cboHateSpeech: TComboBox;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    cboHarassment: TComboBox;
    cboSexuallyExplicit: TComboBox;
    cboDangerousContent: TComboBox;
    cboMedical: TComboBox;
    Label23: TLabel;
    cboToxicity: TComboBox;
    cboDerogatory: TComboBox;
    cboSexual: TComboBox;
    cboDangerous: TComboBox;
    cboViolence: TComboBox;
    Label24: TLabel;
    Label25: TLabel;
    Label26: TLabel;
    Label27: TLabel;
    Label28: TLabel;
    cboCivicIntegrity: TComboBox;
    Label29: TLabel;
    btnLoadPDF: TButton;
    OpenDialogPDF: TOpenDialog;
    txtNoAttachment: TText;
    Splitter1: TSplitter;
    layMedia: TLayout;
    Splitter2: TSplitter;
    txtFile: TText;
    aniPDF: TAniIndicator;
    aniHTML: TAniIndicator;
    btnCalcPromptToken: TButton;
    btnClearMedia: TButton;
    btnNextQuestionInChat: TButton;
    btnCalcRequestInChat: TButton;
    procedure btnGeminiGenerateContentClick(Sender: TObject);
    procedure bntLoadImageClick(Sender: TObject);
    procedure trbMaxOutputTokenChange(Sender: TObject);
    procedure chbUseModelParamsChange(Sender: TObject);
    procedure trbTemperatureChange(Sender: TObject);
    procedure trbTopPChange(Sender: TObject);
    procedure trbTopKChange(Sender: TObject);
    procedure chbUseSafetySettingsChange(Sender: TObject);
    procedure btnLoadPDFClick(Sender: TObject);
    procedure btnCalcPromptTokenClick(Sender: TObject);
    procedure btnClearMediaClick(Sender: TObject);
    procedure memGeminiPromptKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure btnNextQuestionInChatClick(Sender: TObject);
    procedure btnCalcRequestInChatClick(Sender: TObject);
  private
    fGeminiAI: IGeminiAI;
    fRequest: IGeminiAIRequest;
    fMediaStream: TFileStream;
    fPDFBrowser: TfmxWebBrowser;
    fHTMLResultBrowser: TfmxWebBrowser;
    function CheckAndCreateGeminiAIClass: boolean;
    procedure OnGeminiAIGenContent(Response: IGeminiAIResponse);
    procedure OnGeminiAITokenCount(PromptToken, CachedContentToken: integer; const ErrMsg: string);
    procedure OnHTMLLoaded(const FileName: string; ErrorFlag: boolean);
    procedure OnPDFLoaded(const FileName: string; ErrorFlag: boolean);
  public
    destructor Destroy; override;
    procedure LoadSettingsFromIniFile(IniFile: TIniFile);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
  end;

implementation

uses
  System.IOUtils, System.NetEncoding,
  REST.Types,
  FB4D.GeminiAI, FB4D.Helpers;

{$R *.fmx}

resourcestring
  rsDefaultPrompt = 'Explain how Gemini AI works?';

{ TGeminiAIFra }

{$REGION 'Class Handling'}
function TGeminiAIFra.CheckAndCreateGeminiAIClass: boolean;
begin
  if assigned(fGeminiAI) then
    exit(true);
  fGeminiAI := TGeminiAI.Create(edtGeminiAPIKey.Text,
    cboGeminiModel.Items[cboGeminiModel.ItemIndex]);
  fRequest := nil;
  edtGeminiAPIKey.ReadOnly := true;
  rctGeminiApiKeyDisabled.Visible := true;
  cboGeminiModel.Enabled := false;
  result := true;
end;

destructor TGeminiAIFra.Destroy;
begin
  FreeAndNil(fMediaStream);
  if assigned(fPDFBrowser) then
    fPDFBrowser.Stop;
  if assigned(fHTMLResultBrowser) then
    fHTMLResultBrowser.Stop;
  inherited;
end;
{$ENDREGION}

{$REGION 'Settings'}
procedure TGeminiAIFra.LoadSettingsFromIniFile(IniFile: TIniFile);
begin
  edtGeminiAPIKey.Text := IniFile.ReadString('GeminiAI', 'APIKey', '');
  cboGeminiModel.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Model', 0);
  chbUseModelParams.IsChecked := IniFile.ReadBool('GeminiAI', 'UseModeParams', false);
  chbUseSafetySettings.IsChecked := IniFile.ReadBool('GeminiAI', 'UseSafetySettings', false);
  expGeminiCfg.IsExpanded := edtGeminiAPIKey.Text.IsEmpty;
    // or chbUseModelParams.IsChecked or chbUseSafetySettings.IsChecked;
  trbMaxOutputToken.Value := IniFile.ReadInteger('GeminiAI', 'MaxOutToken', 640);
  trbTemperature.Value := IniFile.ReadInteger('GeminiAI', 'Temperature', 70);
  trbTopP.Value := IniFile.ReadInteger('GeminiAI', 'TopP', 70);
  trbTopK.Value := IniFile.ReadInteger('GeminiAI', 'TopK', 1);
  chbUseModelParamsChange(nil);
  trbMaxOutputTokenChange(nil);
  trbTemperatureChange(nil);
  trbTopKChange(nil);
  trbTopPChange(nil);
  cboHateSpeech.ItemIndex := IniFile.ReadInteger('GeminiAI', 'HateSpeech', 4);
  cboHarassment.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Harassment', 4);
  cboSexuallyExplicit.ItemIndex := IniFile.ReadInteger('GeminiAI', 'SexuallyExplicit', 4);
  cboDangerousContent.ItemIndex := IniFile.ReadInteger('GeminiAI', 'DangerousContent', 4);
  cboCivicIntegrity.ItemIndex := IniFile.ReadInteger('GeminiAI', 'CivicIntegrity', 4);
  cboMedical.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Medical', 4);
  cboToxicity.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Toxicity', 4);
  cboDerogatory.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Derogatory', 4);
  cboSexual.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Sexual', 4);
  cboDangerous.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Dangerous', 4);
  cboViolence.ItemIndex := IniFile.ReadInteger('GeminiAI', 'Violence', 4);
  memGeminiPrompt.Lines.Text :=  TNetEncoding.URL.Decode(IniFile.ReadString('GeminiAI', 'Prompt', rsDefaultPrompt));
  lblGeminiPrompt.visible := memGeminiPrompt.Lines.Text.IsEmpty;
  TabControlResult.ActiveTab := tabMetadata;
end;

procedure TGeminiAIFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('GeminiAI', 'APIKey', edtGeminiAPIKey.Text);
  IniFile.WriteInteger('GeminiAI', 'Model', cboGeminiModel.ItemIndex);
  IniFile.WriteBool('GeminiAI', 'UseModeParams', chbUseModelParams.IsChecked);
  IniFile.WriteInteger('GeminiAI', 'MaxOutToken', round(trbMaxOutputToken.Value));
  IniFile.WriteInteger('GeminiAI', 'Temperature', round(trbTemperature.Value));
  IniFile.WriteInteger('GeminiAI', 'TopP', round(trbTopP.Value));
  IniFile.WriteInteger('GeminiAI', 'TopK', round(trbTopK.Value));
  IniFile.WriteBool('GeminiAI', 'UseSafetySettings', chbUseSafetySettings.IsChecked);
  IniFile.WriteInteger('GeminiAI', 'HateSpeech', cboHateSpeech.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'Harassment', cboHarassment.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'SexuallyExplicit', cboSexuallyExplicit.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'DangerousContent', cboDangerousContent.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'CivicIntegrity', cboCivicIntegrity.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'Medical', cboMedical.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'Toxicity', cboToxicity.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'Derogatory', cboDerogatory.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'Sexual', cboSexual.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'Dangerous', cboDangerous.ItemIndex);
  IniFile.WriteInteger('GeminiAI', 'Violence', cboViolence.ItemIndex);
  IniFile.WriteString('GeminiAI', 'Prompt', TNetEncoding.URL.Encode(memGeminiPrompt.Lines.Text));
end;
{$ENDREGION}

{$REGION 'Model Configuration'}
procedure TGeminiAIFra.chbUseModelParamsChange(Sender: TObject);
begin
  layModelParams.Enabled := chbUseModelParams.IsChecked;
end;

procedure TGeminiAIFra.trbMaxOutputTokenChange(Sender: TObject);
begin
  lblMaxOutToken.Text := IntToStr(round(trbMaxOutputToken.Value));
end;

procedure TGeminiAIFra.trbTemperatureChange(Sender: TObject);
begin
  lblTempValue.Text := Format('%d%%', [round(trbTemperature.Value)]);
end;

procedure TGeminiAIFra.trbTopKChange(Sender: TObject);
begin
  lblTopK.Text := IntToStr(round(trbTopK.Value));
end;

procedure TGeminiAIFra.trbTopPChange(Sender: TObject);
begin
  lblTopP.Text := Format('%d%%', [round(trbTopP.Value)]);
end;

procedure TGeminiAIFra.chbUseSafetySettingsChange(Sender: TObject);
begin
  laySafetySettings.Enabled := chbUseSafetySettings.IsChecked;
end;
{$ENDREGION}

{$REGION 'Gemini Prompt'}
procedure TGeminiAIFra.memGeminiPromptKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  lblGeminiPrompt.visible := memGeminiPrompt.Lines.Text.IsEmpty;
end;

procedure TGeminiAIFra.bntLoadImageClick(Sender: TObject);
begin
  if OpenDialogImgFile.Execute then
  begin
    FreeAndNil(fMediaStream);
    if assigned(fPDFBrowser) then
      FreeAndNil(fPDFBrowser);
    txtFile.Text := OpenDialogImgFile.FileName;
    txtNoAttachment.visible := false;
    imgMediaFile.Bitmap.LoadFromFile(OpenDialogImgFile.FileName);
    imgMediaFile.Visible := true;
    fMediaStream := TFileStream.Create(OpenDialogImgFile.FileName, fmOpenRead);
    edtMediaFileType.Text := TFirebaseHelpers.ImageStreamToContentType(
      fMediaStream);
  end;
end;

procedure TGeminiAIFra.btnLoadPDFClick(Sender: TObject);
begin
  if OpenDialogPDF.Execute then
  begin
    FreeAndNil(fMediaStream);
    txtNoAttachment.visible := false;
    imgMediaFile.Visible := false;
    txtFile.Text := OpenDialogPDF.FileName;
    aniPDF.Enabled := true;
    txtNoAttachment.Text := 'PDF loading...';
    txtNoAttachment.visible := true;
    if not assigned(fPDFBrowser) then
      fPDFBrowser := TfmxWebBrowser.Create(self);
    fPDFBrowser.LoadFromFile(OpenDialogPDF.FileName, OnPDFLoaded);
    fPDFBrowser.layChrome.Parent := rctImage;
    fMediaStream := TFileStream.Create(OpenDialogPDF.FileName, fmOpenRead);
    edtMediaFileType.Text := TRESTContentType.ctAPPLICATION_PDF;
  end;
end;

procedure TGeminiAIFra.OnPDFLoaded(const FileName: string; ErrorFlag: boolean);
begin
  aniPDF.Visible := false;
  aniPDF.Enabled := false;
  if ErrorFlag then
    txtNoAttachment.Text := 'PDF load failed'
  else
    txtNoAttachment.visible := false;
end;

procedure TGeminiAIFra.btnClearMediaClick(Sender: TObject);
begin
  aniPDF.Visible := false;
  imgMediaFile.Visible := false;
  if assigned(fPDFBrowser) then
    FreeAndNil(fPDFBrowser);
  FreeAndNil(fMediaStream);
  txtFile.Text := '';
  txtNoAttachment.Text := 'No media file';
  txtNoAttachment.visible := true;
  edtMediaFileType.Text := '';
end;
{$ENDREGION}

{$REGION 'Generate Content'}
procedure TGeminiAIFra.btnGeminiGenerateContentClick(Sender: TObject);
const
  cProcessingHTML = '<html><body><h1>Processing %s...</h1></body></html>';
var
  Info: string;
begin
  CheckAndCreateGeminiAIClass;
  if not assigned(fHTMLResultBrowser) then
  begin
    fHTMLResultBrowser := TfmxWebBrowser.Create(self);
    fHTMLResultBrowser.layChrome.Parent := tabHTMLRes;
  end else begin
    fHTMLResultBrowser.Stop;
    fRequest := nil; // Discard fromer request
  end;
  lstMetaData.Clear;
  TabControlResult.ActiveTab := tabHTMLRes;
  if assigned(fMediaStream) then
  begin
    if imgMediaFile.Visible then
    begin
      Info := 'prompt with image media';
      fRequest := TGeminiAIRequest.Create.PromptWithImgData(
        memGeminiPrompt.Text, fMediaStream);
    end else begin
      Info := 'prompt with PDF media';
      fRequest := TGeminiAIRequest.Create.PromptWithMediaData(
        memGeminiPrompt.Text, TRESTContentType.ctAPPLICATION_PDF, fMediaStream);
    end;
  end else begin
    Info := 'prompt';
    fRequest := TGeminiAIRequest.Create.Prompt(memGeminiPrompt.Text);
  end;
  if chbUseModelParams.IsChecked then
  begin
    fRequest.ModelParameter(trbTemperature.Value / 100, trbTopP.Value / 100, round(trbMaxOutputToken.Value),
      round(trbTopK.Value));
    if memStopSequences.Lines.Count > 0 then
      fRequest.SetStopSequences(memStopSequences.Lines);
  end;
  if chbUseSafetySettings.IsChecked then
  begin
    fRequest.SetSafety(hcHateSpeech, TSafetyBlockLevel(cboHateSpeech.ItemIndex));
    fRequest.SetSafety(hcHarassment, TSafetyBlockLevel(cboHarassment.ItemIndex));
    fRequest.SetSafety(hcSexuallyExplicit, TSafetyBlockLevel(cboSexuallyExplicit.ItemIndex));
    fRequest.SetSafety(hcDangerousContent, TSafetyBlockLevel(cboDangerousContent.ItemIndex));
    fRequest.SetSafety(hcCivicIntegrity, TSafetyBlockLevel(cboCivicIntegrity.ItemIndex));
// Currently documented but not supported in API:
// https://ai.google.dev/api/generate-content?authuser=8&hl=de#v1beta.HarmCategory
//    fRequest.SetSafety(hcSexual, TSafetyBlockLevel(cboSexual.ItemIndex));
//    fRequest.SetSafety(hcDangerous, TSafetyBlockLevel(cboDangerous.ItemIndex));
//    fRequest.SetSafety(hcMedicalAdvice, TSafetyBlockLevel(cboMedical.ItemIndex));
//    fRequest.SetSafety(hcToxicity, TSafetyBlockLevel(cboToxicity.ItemIndex));
//    fRequest.SetSafety(hcDerogatory, TSafetyBlockLevel(cboDerogatory.ItemIndex));
//    fRequest.SetSafety(hcViolence, TSafetyBlockLevel(cboViolence.ItemIndex));
  end;
  aniHTML.Enabled := true;
  aniHTML.Visible := true;
  tabHTMLRes.Visible := true;
  TabControlResult.ActiveTab := tabHTMLRes;
  fHTMLResultBrowser.LoadFromStrings(Format(cProcessingHTML, [Info]), OnHTMLLoaded);
  lstMetaData.Items.Text := 'Question: "' + memGeminiPrompt.Lines.Text + '"';
  fGeminiAI.generateContentByRequest(fRequest, OnGeminiAIGenContent);
end;

procedure TGeminiAIFra.OnGeminiAIGenContent(Response: IGeminiAIResponse);
var
  c: integer;
  Indent: string;
begin
  tabHTMLRes.Visible := true;
  tabRawResult.Visible := true;
  tabMetadata.Visible := true;
  tabMarkdownRes.Visible := true;
  memRawJSONResult.Lines.Text := Response.FormatedJSON;
  fHTMLResultBrowser.Stop;
  if Response.IsValid then
  begin
    lstMetaData.Items.Add('Usage');
    lstMetaData.Items.Add('  Prompt token count: ' +
      Response.UsageMetaData.PromptTokenCount.ToString);
    lstMetaData.Items.Add('  Generated token count: ' +
      Response.UsageMetaData.GeneratedTokenCount.ToString);
    lstMetaData.Items.Add('  Total token count: ' +
      Response.UsageMetaData.TotalTokenCount.ToString);
    lstMetaData.Items.Add('Result state: ' + Response.ResultStateStr);
    lstMetaData.Items.Add('Finish reason(s): ' + Response.FinishReasonsCommaSepStr);
    if Response.NumberOfResults > 1 then
    begin
      lstMetaData.Items.Add(Response.NumberOfResults.ToString + ' result candidates');
      Indent := '  ';
    end else begin
      lstMetaData.Items.Add('Only one result without candidates');
      Indent := '';
    end;
    for c := 0 to Response.NumberOfResults - 1 do
    begin
      if Response.NumberOfResults > 1 then
        lstMetaData.Items.Add(Format('%sCandidate %d', [Indent, c + 1]));
      lstMetaData.Items.Add(Indent + 'Finish reason: ' + Response.EvalResult(c).FinishReasonAsStr);
      lstMetaData.Items.Add(Indent + 'Index: ' + Response.EvalResult(c).Index.ToString);
      lstMetaData.Items.Add(Indent + 'SafetyRating');
      if Response.EvalResult(c).SafetyRatings[hcHateSpeech].Probability > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Hate speech: Probability is ' +
          Response.EvalResult(c).SafetyRatings[hcHateSpeech].ProbabilityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcHateSpeech].ProbabilityScore));
      if Response.EvalResult(c).SafetyRatings[hcHateSpeech].Severity > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Hate speech: Severity is ' +
          Response.EvalResult(c).SafetyRatings[hcHateSpeech].SeverityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcHateSpeech].SeverityScore));
      if Response.EvalResult(c).SafetyRatings[hcHarassment].Probability > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Harassment: Probability is ' +
          Response.EvalResult(c).SafetyRatings[hcHarassment].ProbabilityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcHarassment].ProbabilityScore));
      if Response.EvalResult(c).SafetyRatings[hcHarassment].Severity > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Harassment: Severity is ' +
          Response.EvalResult(c).SafetyRatings[hcHarassment].SeverityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcHarassment].SeverityScore));
      if Response.EvalResult(c).SafetyRatings[hcSexuallyExplicit].Probability > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Sexually Explicit: Probability is ' +
          Response.EvalResult(c).SafetyRatings[hcSexuallyExplicit].ProbabilityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcSexuallyExplicit].ProbabilityScore));
      if Response.EvalResult(c).SafetyRatings[hcSexuallyExplicit].Severity > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Sexually Explicit: Severity is ' +
          Response.EvalResult(c).SafetyRatings[hcSexuallyExplicit].SeverityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcSexuallyExplicit].SeverityScore));
      if Response.EvalResult(c).SafetyRatings[hcDangerousContent].Probability > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Dangerous Content: Probability is ' +
          Response.EvalResult(c).SafetyRatings[hcDangerousContent].ProbabilityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcDangerousContent].ProbabilityScore));
      if Response.EvalResult(c).SafetyRatings[hcDangerousContent].Severity > psUnknown then
        lstMetaData.Items.Add(Indent + Indent + 'Dangerous Content: Severity is ' +
          Response.EvalResult(c).SafetyRatings[hcDangerousContent].SeverityAsStr + ', Score: ' +
          FloatToStr(Response.EvalResult(c).SafetyRatings[hcDangerousContent].SeverityScore));
    end;
{$IFDEF DEBUG}
    var NowStr: string := FormatDateTime('yymmdd_hhnnss', now);
    TFile.WriteAllText(Format('GeminiAI%s.md', [NowStr]), Response.ResultAsMarkDown);
    TFile.WriteAllText(Format('GeminiAI%s.html', [NowStr]), Response.ResultAsHTML);
{$ENDIF}
    memMarkdown.Lines.Text := Response.ResultAsMarkDown;
    fRequest.AddAnswerForNextRequest(Response.ResultAsMarkDown);
    btnNextQuestionInChat.Enabled := true;
    btnCalcRequestInChat.Enabled := true;
    if not(gfrMaxToken in Response.FinishReasons) then
      fHTMLResultBrowser.LoadFromStrings(Response.ResultAsHTML, OnHTMLLoaded)
    else begin
      aniHTML.Enabled := false;
      aniHTML.Visible := false;
      tabHTMLRes.Visible := false;
      lstMetaData.Items.Insert(0, 'Increase max output token in the model parameters!');
      TabControlResult.ActiveTab := tabMetadata;
    end;
  end else
    fHTMLResultBrowser.LoadFromStrings('<h1>Failed</h1><p>' + Response.FailureDetail + '</p>', OnHTMLLoaded);
end;

procedure TGeminiAIFra.OnHTMLLoaded(const FileName: string; ErrorFlag: boolean);
begin
  aniHTML.Enabled := false;
  aniHTML.Visible := false;
  if ErrorFlag then
    TabControlResult.ActiveTab := tabMarkdownRes
  else
    TabControlResult.ActiveTab := tabHTMLRes;
end;

procedure TGeminiAIFra.btnNextQuestionInChatClick(Sender: TObject);
const
  cProcessingHTML = '<html><body><h1>Wait to response from Gemini AI...</h1></body></html>';
begin
  fRequest.AddQuestionForNextRequest(memGeminiPrompt.Lines.Text);
  aniHTML.Enabled := true;
  aniHTML.Visible := true;
  tabHTMLRes.Visible := true;
  TabControlResult.ActiveTab := tabHTMLRes;
  fHTMLResultBrowser.LoadFromStrings(cProcessingHTML, OnHTMLLoaded);
  lstMetaData.Items.Add('Next question in chat: "' + memGeminiPrompt.Lines.Text + '"');
  fGeminiAI.generateContentByRequest(fRequest, OnGeminiAIGenContent);
end;
{$ENDREGION}

{$REGION 'Calc Prompt Token'}
procedure TGeminiAIFra.btnCalcPromptTokenClick(Sender: TObject);
var
  Request: IGeminiAIRequest;
begin
  CheckAndCreateGeminiAIClass;
  fHTMLResultBrowser.Stop;
  if assigned(fMediaStream) then
  begin
    if imgMediaFile.Visible then
      Request := TGeminiAIRequest.Create.PromptWithImgData(
        memGeminiPrompt.Text, fMediaStream)
    else
      Request := TGeminiAIRequest.Create.PromptWithMediaData(
        memGeminiPrompt.Text, TRESTContentType.ctAPPLICATION_PDF, fMediaStream);
  end else
    Request := TGeminiAIRequest.Create.Prompt(memGeminiPrompt.Text);
  fGeminiAI.CountTokenOfRequest(Request, OnGeminiAITokenCount);
  tabHTMLRes.Visible := false;
  tabRawResult.Visible := false;
  tabMarkdownRes.Visible := false;
  tabMetadata.Visible := true;
  lstMetaData.Items.Text := 'Calculating...';
end;

procedure TGeminiAIFra.btnCalcRequestInChatClick(Sender: TObject);
var
  Request: IGeminiAIRequest;
begin
  Request := fRequest.CloneWithoutCfgAndSettings(fRequest);
  Request.AddQuestionForNextRequest(memGeminiPrompt.Lines.Text);
  fGeminiAI.CountTokenOfRequest(Request, OnGeminiAITokenCount);
  tabHTMLRes.Visible := false;
  tabRawResult.Visible := false;
  tabMarkdownRes.Visible := false;
  tabMetadata.Visible := true;
  lstMetaData.Items.Text := 'Calculating...';
end;

procedure TGeminiAIFra.OnGeminiAITokenCount(PromptToken, CachedContentToken: integer; const ErrMsg: string);
begin
  TabControlResult.ActiveTab := tabMetadata;
  lstMetaData.Clear;
  if ErrMsg.IsEmpty then
  begin
    lstMetaData.Items.Add('Prompt token count: ' + PromptToken.ToString);
    lstMetaData.Items.Add('Cached content token count: ' + CachedContentToken.ToString);
  end else
    lstMetaData.Items.Add('Error: ' + ErrMsg);
end;
{$ENDREGION}

end.
