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

unit FB4D.GeminiAIFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.IniFiles,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.WebBrowser, FMX.ScrollBox, FMX.Memo, FMX.Edit, FMX.ExtCtrls, 
  FMX.Controls.Presentation, FMX.ListBox, FMX.Objects, FMX.TabControl, FMX.Layouts,
  FMX.Ani, 
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
    memMetaData: TMemo;
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
    layRequest: TLayout;
    memStopSequences: TMemo;
    Label17: TLabel;
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
    chbUseGoogleSearch: TCheckBox;
    trbGoogleSearchThreshold: TTrackBar;
    layGoogleSearch: TLayout;
    Label30: TLabel;
    Label31: TLabel;
    Label32: TLabel;
    cboAPIVersion: TComboBox;
    expSystemInstruction: TExpander;
    layPrompt: TLayout;
    layCommandBar: TLayout;
    memSystemInstruction: TMemo;
    Splitter3: TSplitter;
    btnModelDetails: TButton;
    CalloutPanel: TCalloutPanel;
    txtModelInfo: TText;
    rctCalloutPanelBack: TRectangle;
    txtModelTitle: TText;
    FloatAnimationCallout: TFloatAnimation;
    chbSetResponseModalities: TCheckBox;
    layModalities: TLayout;
    chbModalityText: TCheckBox;
    chbModalityImage: TCheckBox;
    chbModalityAudio: TCheckBox;
    tabMediaData: TTabItem;
    imgMediaRes: TImage;
    SaveDialogImgFile: TSaveDialog;
    Panel1: TPanel;
    btnSaveImageToFile: TButton;
    cboSelectMediaFile: TComboBox;
    chbUseNewGoogleSearch: TCheckBox;
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
    procedure memMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);
    procedure cboGeminiModelChange(Sender: TObject);
    procedure edtGeminiAPIKeyExit(Sender: TObject);
    procedure chbUseGoogleSearchChange(Sender: TObject);
    procedure cboAPIVersionChange(Sender: TObject);
    procedure expSystemInstructionCheckChange(Sender: TObject);
    procedure expSystemInstructionExpandedChanged(Sender: TObject);
    procedure memSystemInstructionChange(Sender: TObject);
    procedure btnModelDetailsClick(Sender: TObject);
    procedure FloatAnimationCalloutFinish(Sender: TObject);
    procedure chbSetResponseModalitiesChange(Sender: TObject);
    procedure chbModalityTextChange(Sender: TObject);
    procedure chbModalityImageOrAudioChange(Sender: TObject);
    procedure btnSaveImageToFileClick(Sender: TObject);
    procedure cboSelectMediaFileChange(Sender: TObject);
    procedure chbUseNewGoogleSearchChange(Sender: TObject);
  private
    fGeminiAI: IGeminiAI;
    fModelName: string;
    fRequest: IGeminiAIRequest;
    fMediaStream: TFileStream;
    fPDFBrowser: TfmxWebBrowser;
    fHTMLResultBrowser: TfmxWebBrowser;
    fImages: array of TBitmap;
    function CheckAndCreateGeminiAIClass: boolean;
    procedure ClearMediaCache;
    procedure OnGeminiFetchModels(Models: TStrings; const ErrorMsg: string);
    procedure OnGeminiFetchModel(Detail: TGeminiModelDetails; const ErrorMsg: string);
    procedure OnGeminiAIGenContent(Response: IGeminiAIResponse);
    procedure OnGeminiAITokenCount(PromptToken, CachedContentToken: integer; const ErrMsg: string);
    procedure OnHTMLLoaded(const FileName: string; ErrorFlag: boolean);
    procedure OnPDFLoaded(const FileName: string; ErrorFlag: boolean);
  public
    destructor Destroy; override;
    procedure LoadSettingsFromIniFile(IniFile: TIniFile);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
    procedure FetchModelNameList;
    procedure FetchModelDetails(AutoClose: boolean);
  end;

implementation

uses
  System.IOUtils, System.NetEncoding,
  REST.Types,
  FB4D.GeminiAI, FB4D.Helpers;

{$R *.fmx}

resourcestring
  rsDefaultPrompt = 'Explain how Gemini AI works?';
  rsImage = 'Image';

{ TGeminiAIFra }

{$REGION 'Class Handling'}
function TGeminiAIFra.CheckAndCreateGeminiAIClass: boolean;
begin
  if edtGeminiAPIKey.Text.IsEmpty then
    exit(false);
  if assigned(fGeminiAI) then
    exit(true);
  fGeminiAI := TGeminiAI.Create(edtGeminiAPIKey.Text, fModelName, TGeminiAPIVersion(cboAPIVersion.ItemIndex));
  fRequest := nil;
  edtGeminiAPIKey.ReadOnly := true;
  rctGeminiApiKeyDisabled.Visible := true;
  result := true;
end;

procedure TGeminiAIFra.ClearMediaCache;
var
  c: integer;
begin
  for c := Low(fImages) to High(fImages) do
    fImages[c].Free;
  SetLength(fImages, 0);
  cboSelectMediaFile.Clear;
end;

destructor TGeminiAIFra.Destroy;
begin
  FreeAndNil(fMediaStream);
  ClearMediaCache;
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
  fModelName := IniFile.ReadString('GeminiAI', 'ModelName', cGeminiAIDefaultModel);
  TGeminiAI.SetListOfAPIVersions(cboAPIVersion.Items);
  cboAPIVersion.ItemIndex := cboAPIVersion.Items.IndexOf(IniFile.ReadString('GeminiAI', 'APIVersion', ''));
  if cboAPIVersion.ItemIndex < 0 then
    cboAPIVersion.ItemIndex := ord(cDefaultGeminiAPIVersion);
  chbUseModelParams.IsChecked := IniFile.ReadBool('GeminiAI', 'UseModeParams', false);
  chbUseSafetySettings.IsChecked := IniFile.ReadBool('GeminiAI', 'UseSafetySettings', false);
  chbUseGoogleSearch.IsChecked := IniFile.ReadBool('GeminiAI', 'UseGoogleSearch', false);
  expGeminiCfg.IsExpanded := edtGeminiAPIKey.Text.IsEmpty;
    // or chbUseModelParams.IsChecked or chbUseSafetySettings.IsChecked;
  trbMaxOutputToken.Value := IniFile.ReadInteger('GeminiAI', 'MaxOutToken', 640);
  trbTemperature.Value := IniFile.ReadInteger('GeminiAI', 'Temperature', 70);
  trbTopP.Value := IniFile.ReadInteger('GeminiAI', 'TopP', 70);
  trbTopK.Value := IniFile.ReadInteger('GeminiAI', 'TopK', 1);
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
  memSystemInstruction.Lines.Text := TNetEncoding.URL.Decode(IniFile.ReadString('GeminiAI', 'SystemInstructions', ''));
  expSystemInstruction.IsChecked := not memSystemInstruction.Lines.IsEmpty;
  expSystemInstruction.IsExpanded := expSystemInstruction.IsChecked;
  trbGoogleSearchThreshold.Value := IniFile.ReadFloat('GeminiAI', 'GoogleSearchThreshold', 0.3);
  chbModalityText.IsChecked := IniFile.ReadBool('GeminiAI', 'ModalityText', true);
  chbModalityImage.IsChecked := IniFile.ReadBool('GeminiAI', 'ModalityImage', false);
  chbModalityAudio.IsChecked := IniFile.ReadBool('GeminiAI', 'ModalityAudio', false);
  chbSetResponseModalities.IsChecked := not chbModalityText.IsChecked or chbModalityImage.IsChecked or
    chbModalityAudio.IsChecked;
  memGeminiPrompt.Lines.Text := TNetEncoding.URL.Decode(IniFile.ReadString('GeminiAI', 'Prompt', rsDefaultPrompt));
  lblGeminiPrompt.visible := memGeminiPrompt.Lines.Text.IsEmpty;
  memGeminiPrompt.TextSettings.Font.Size := IniFile.ReadInteger('GeminiAI', 'FontSize', 12);
  memRawJSONResult.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
  memMarkdown.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
  memMetaData.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
  memSystemInstruction.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
  if expSystemInstruction.IsExpanded then
    expSystemInstruction.Height := expSystemInstruction.cDefaultHeaderHeight + memSystemInstruction.Lines.Count *
      (memSystemInstruction.TextSettings.Font.Size + 10);
  txtFile.Text := IniFile.ReadString('GeminiAI', 'MediaFile', '');
  if not txtFile.Text.IsEmpty then
  begin
    if not FileExists(txtFile.Text) then
      txtFile.Text := ''
    else if SameText(ExtractFileExt(txtFile.Text), '.pdf') then
    begin
      txtNoAttachment.Text := 'PDF loading...';
      txtNoAttachment.visible := true;
      aniPDF.Enabled := true;
      if not assigned(fPDFBrowser) then
        fPDFBrowser := TfmxWebBrowser.Create(self);
      fPDFBrowser.LoadFromFile(txtFile.Text, OnPDFLoaded);
      fPDFBrowser.layChrome.Parent := rctImage;
      fMediaStream := TFileStream.Create(txtFile.Text, fmOpenRead);
      edtMediaFileType.Text := TRESTContentType.ctAPPLICATION_PDF;
    end else begin
      txtNoAttachment.visible := false;
      imgMediaFile.Bitmap.LoadFromFile(txtFile.Text);
      imgMediaFile.Visible := true;
      fMediaStream := TFileStream.Create(txtFile.Text, fmOpenRead);
      edtMediaFileType.Text := TFirebaseHelpers.ImageStreamToContentType(fMediaStream);
    end;
  end;
  chbUseModelParamsChange(nil);
  chbUseSafetySettingsChange(nil);
  chbUseGoogleSearchChange(nil);
  chbSetResponseModalitiesChange(nil);
  trbMaxOutputTokenChange(nil);
  trbTemperatureChange(nil);
  trbTopKChange(nil);
  trbTopPChange(nil);
  tabMediaData.visible := false;
  TabControlResult.ActiveTab := tabMetadata;
  FetchModelNameList;
end;

procedure TGeminiAIFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('GeminiAI', 'APIKey', edtGeminiAPIKey.Text);
  IniFile.WriteString('GeminiAI', 'ModelName', fModelName);
  if cboAPIVersion.ItemIndex >= 0 then
    IniFile.WriteString('GeminiAI', 'APIVersion', cboAPIVersion.Items[cboAPIVersion.ItemIndex]);
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
  IniFile.WriteString('GeminiAI', 'SystemInstructions', TNetEncoding.URL.Encode(trim(memSystemInstruction.Lines.Text)));
  IniFile.WriteBool('GeminiAI', 'UseGoogleSearch', chbUseGoogleSearch.IsChecked);
  IniFile.WriteFloat('GeminiAI', 'GoogleSearchThreshold', trbGoogleSearchThreshold.Value);
  IniFile.WriteBool('GeminiAI', 'ModalityText', chbModalityText.IsChecked);
  IniFile.WriteBool('GeminiAI', 'ModalityImage', chbModalityImage.IsChecked);
  IniFile.WriteBool('GeminiAI', 'ModalityAudio', chbModalityAudio.IsChecked);
  IniFile.WriteString('GeminiAI', 'Prompt', TNetEncoding.URL.Encode(memGeminiPrompt.Lines.Text));
  IniFile.WriteInteger('GeminiAI', 'FontSize', trunc(memGeminiPrompt.TextSettings.Font.Size));
  IniFile.WriteString('GeminiAI', 'MediaFile', txtFile.Text);
end;
{$ENDREGION}

{$REGION 'Model Configuration'}
procedure TGeminiAIFra.FetchModelNameList;
begin
  cboGeminiModel.Clear;
  if CheckAndCreateGeminiAIClass then
    fGeminiAI.FetchListOfModels(OnGeminiFetchModels);
end;

procedure TGeminiAIFra.OnGeminiFetchModels(Models: TStrings; const ErrorMsg: string);
begin
  if assigned(Models) then
  begin
    cboGeminiModel.Items.AddStrings(Models);
    cboGeminiModel.ItemIndex := cboGeminiModel.Items.IndexOf(fModelName);
  end else begin
    memMetaData.Lines.Text := 'Fetch of model list failed: ' + ErrorMsg;
    tabMetadata.visible := true;
    TabControlResult.ActiveTab := tabMetadata;
  end;
end;

procedure TGeminiAIFra.edtGeminiAPIKeyExit(Sender: TObject);
begin
  FetchModelNameList;
end;

procedure TGeminiAIFra.expSystemInstructionCheckChange(Sender: TObject);
begin
  expSystemInstruction.IsExpanded := expSystemInstruction.IsChecked;
  Fmx.Types.Log.d('expSystemInstructionCheckChange');
end;

procedure TGeminiAIFra.expSystemInstructionExpandedChanged(Sender: TObject);
begin
  expSystemInstruction.IsChecked := expSystemInstruction.IsExpanded;
  Fmx.Types.Log.d('expSystemInstructionExpandedChanged');
end;

procedure TGeminiAIFra.cboAPIVersionChange(Sender: TObject);
begin
  if assigned(fGeminiAI) then
    fGeminiAI.SetAPIVersion(TGeminiAPIVersion(cboAPIVersion.ItemIndex));
  FetchModelNameList;
end;

procedure TGeminiAIFra.cboGeminiModelChange(Sender: TObject);
var
  ModelVersion: double;
  ModelNameParts: TStringDynArray;
begin
  if cboGeminiModel.ItemIndex < 0 then
    exit;
  CheckAndCreateGeminiAIClass;
  fModelName := cboGeminiModel.Items[cboGeminiModel.ItemIndex];
  fGeminiAI.SetModel(fModelName);
  btnModelDetails.Enabled := true;
  FetchModelDetails(not CalloutPanel.Visible);
  ModelNameParts := fModelName.Split(['-']);
  if (length(ModelNameParts) > 1) and SameText(ModelNameParts[0], 'gemini') then
    ModelVersion := StrToFloatDef(ModelNameParts[1], 0)
  else
    ModelVersion := 0;
  if chbUseGoogleSearch.IsChecked and (ModelVersion >= 2.0) then
    chbUseNewGoogleSearch.IsChecked := true
  else if chbUseNewGoogleSearch.IsChecked and (ModelVersion = 1.5) then
    chbUseGoogleSearch.IsChecked := true;
  if ModelVersion = 1.0 then
  begin
    chbUseNewGoogleSearch.IsChecked := false;
    chbUseGoogleSearch.IsChecked := false;
  end;
end;

procedure TGeminiAIFra.btnModelDetailsClick(Sender: TObject);
begin
  if not CalloutPanel.Visible then
    FetchModelDetails(false)
  else
    FloatAnimationCalloutFinish(nil);
end;

procedure TGeminiAIFra.FetchModelDetails(AutoClose: boolean);
begin
  Assert(not fModelName.IsEmpty, 'Missing model name');
  txtModelInfo.Text := 'processing...';
  FloatAnimationCalloutFinish(nil);
  if AutoClose then
    FloatAnimationCallout.Start;
  CalloutPanel.Visible := true;
  fGeminiAI.FetchModelDetails(fModelName, OnGeminiFetchModel);
end;

procedure TGeminiAIFra.FloatAnimationCalloutFinish(Sender: TObject);
begin
  if sender = nil then
    FloatAnimationCallout.Stop;
  CalloutPanel.Visible := false;
  rctCalloutPanelBack.Opacity := 1;
end;

procedure TGeminiAIFra.OnGeminiFetchModel(Detail: TGeminiModelDetails;
  const ErrorMsg: string);
var
  Info: string;
begin
  txtModelTitle.Text := Detail.DisplayName;
  if SameText(txtModelTitle.Text, Detail.Description) then
    Info := ''
  else
    Info := Detail.Description;
  Info := Info + LineFeed +
    'Full Name: ' + Detail.ModelFullName + LineFeed +
    'Version: ' + Detail.Version + LineFeed +
    'Supported methods: ' +
      TFirebaseHelpers.ArrStrToCommaStr(Detail.SupportedGenerationMethods, true) + LineFeed +
    'Limits of token: input ' + Detail.InputTokenLimit.ToString +
      ', output ' + Detail.OutputTokenLimit.ToString + LineFeed;
  if not Detail.BaseModelId.IsEmpty then
    Info := Info + 'Base Model Id: ' + Detail.BaseModelId;
  Info := Info + 'Default values for temp: ' + Detail.Temperature.ToString +
    ' ,topP: ' + Detail.TopP.ToString + ' ,topK: ' + Detail.TopK.ToString + LineFeed +
    'Max temperature: ' + Detail.MaxTemperature.ToString;
  txtModelInfo.Text := Info;
  CalloutPanel.Height := txtModelInfo.Position.Y + txtModelInfo.Canvas.TextHeight(Info);
end;

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

procedure TGeminiAIFra.chbUseGoogleSearchChange(Sender: TObject);
begin
  layGoogleSearch.Enabled := chbUseGoogleSearch.IsChecked;
  if chbUseGoogleSearch.IsChecked then
    chbUseNewGoogleSearch.IsChecked := false;
end;

procedure TGeminiAIFra.chbUseNewGoogleSearchChange(Sender: TObject);
begin
  if chbUseNewGoogleSearch.IsChecked then
    chbUseGoogleSearch.IsChecked := false;
end;

procedure TGeminiAIFra.chbSetResponseModalitiesChange(Sender: TObject);
begin
  layModalities.Enabled := chbSetResponseModalities.IsChecked;
end;

// Prevent empty Modalities
procedure TGeminiAIFra.chbModalityImageOrAudioChange(Sender: TObject);
begin
  if not chbModalityImage.IsChecked and not chbModalityAudio.IsChecked then
    chbModalityText.IsChecked := true;
end;

procedure TGeminiAIFra.chbModalityTextChange(Sender: TObject);
begin
  if not chbModalityText.IsChecked and not chbModalityAudio.IsChecked then
    chbModalityImage.IsChecked := true;
end;
{$ENDREGION}

{$REGION 'Gemini Prompt'}
procedure TGeminiAIFra.memGeminiPromptKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  lblGeminiPrompt.visible := memGeminiPrompt.Lines.Text.IsEmpty;
end;

procedure TGeminiAIFra.memMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer;
  var Handled: Boolean);
begin
  if ssCtrl in Shift then
  begin
    if WheelDelta > 0 then
    begin
      if memGeminiPrompt.TextSettings.Font.Size < 32 then
        memGeminiPrompt.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size + 1
    end else begin
      if memGeminiPrompt.TextSettings.Font.Size > 8 then
        memGeminiPrompt.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size - 1;
    end;
    memSystemInstruction.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
    memRawJSONResult.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
    memMarkdown.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
    memMetaData.TextSettings.Font.Size := memGeminiPrompt.TextSettings.Font.Size;
    if assigned(fHTMLResultBrowser) then
      fHTMLResultBrowser.Zoom(memGeminiPrompt.TextSettings.Font.Size / 12);
    Handled := true;
  end;
end;

procedure TGeminiAIFra.memSystemInstructionChange(Sender: TObject);
begin
  expSystemInstruction.IsChecked := length(trim(memSystemInstruction.Lines.Text)) > 0;
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
    edtMediaFileType.Text := TFirebaseHelpers.ImageStreamToContentType(fMediaStream);
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
  Modalities: TModalities;
begin
  CheckAndCreateGeminiAIClass;
  ClearMediaCache;
  if not assigned(fHTMLResultBrowser) then
  begin
    fHTMLResultBrowser := TfmxWebBrowser.Create(self);
    fHTMLResultBrowser.layChrome.Parent := tabHTMLRes;
    fHTMLResultBrowser.Zoom(memGeminiPrompt.TextSettings.Font.Size / 12);
  end else begin
    fHTMLResultBrowser.Stop;
    fRequest := nil; // Discard fromer request
  end;
  memMetaData.Lines.Clear;
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
  if expSystemInstruction.IsChecked then
    fRequest.SetSystemInstruction(memSystemInstruction.Lines.Text);
  if chbUseModelParams.IsChecked then
    fRequest.ModelParameter(trbTemperature.Value / 100, trbTopP.Value / 100, round(trbMaxOutputToken.Value),
      round(trbTopK.Value));
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
    if memStopSequences.Lines.Count > 0 then
      fRequest.SetStopSequences(memStopSequences.Lines);
  end;
  if chbUseGoogleSearch.IsChecked then
    fRequest.SetGroundingByGoogleSearch(trbGoogleSearchThreshold.Value)
  else if chbUseNewGoogleSearch.IsChecked then
    fRequest.SetNewGroundingByGoogleSearch;

  if chbSetResponseModalities.IsChecked then
  begin
    Modalities := [];
    if chbModalityText.IsChecked then
      Include(Modalities, mText);
    if chbModalityImage.IsChecked then
      Include(Modalities, mImage);
    if chbModalityAudio.IsChecked then
      Include(Modalities, mAudio);
    fRequest.SetResponseModalities(Modalities);
  end;
  tabHTMLRes.Visible := true;
  TabControlResult.ActiveTab := tabHTMLRes;
  fHTMLResultBrowser.LoadFromStrings(Format(cProcessingHTML, [Info]), OnHTMLLoaded);
  memMetaData.Lines.Text := 'Question: "' + memGeminiPrompt.Lines.Text + '"';
  fGeminiAI.generateContentByRequest(fRequest, OnGeminiAIGenContent);
  aniHTML.Visible := true;
  aniHTML.Enabled := true;
end;

procedure TGeminiAIFra.OnGeminiAIGenContent(Response: IGeminiAIResponse);
var
  c, d, ImageInd: integer;
  AIRes: TGeminiAIResult;
  Indent, s: string;
  Media: TStream;
begin
  tabHTMLRes.Visible := true;
  tabRawResult.Visible := true;
  tabMetadata.Visible := true;
  tabMarkdownRes.Visible := true;
  tabMediaData.visible := true;
  memRawJSONResult.Lines.Text := Response.RawFormatedJSONResult;
  fHTMLResultBrowser.Stop;
  if Response.IsValid then
  begin
    memMetaData.Lines.Add('Usage');
    memMetaData.Lines.Add('  Prompt token count: ' +
      Response.UsageMetaData.PromptTokenCount.ToString);
    memMetaData.Lines.Add('  Generated token count: ' +
      Response.UsageMetaData.GeneratedTokenCount.ToString);
    memMetaData.Lines.Add('  Total token count: ' +
      Response.UsageMetaData.TotalTokenCount.ToString);
    memMetaData.Lines.Add('Result state: ' + Response.ResultStateStr);
    memMetaData.Lines.Add('Finish reason(s): ' + Response.FinishReasonsCommaSepStr);
    if Response.NumberOfResults > 1 then
    begin
      memMetaData.Lines.Add(Response.NumberOfResults.ToString + ' result candidates');
      Indent := '  ';
    end else begin
      memMetaData.Lines.Add('Only one result without candidates');
      Indent := '';
    end;
    for c := 0 to Response.NumberOfResults - 1 do
    begin
      if Response.NumberOfResults > 1 then
        memMetaData.Lines.Add(Format('%sCandidate %d', [Indent, c + 1]));
      AIRes := Response.EvalResult(c);
      memMetaData.Lines.Add(Indent + 'Finish reason: ' + AIRes.FinishReasonAsStr);
      memMetaData.Lines.Add(Indent + 'Number of text parts: ' + length(AIRes.PartText).ToString);
      if length(AIRes.PartText) > 1 then
        for d := 0 to length(AIRes.PartText) - 1 do
          if AIRes.PartText[d].Length > 80 then
            memMetaData.Lines.Add(Indent + Indent + 'Part text[' + IntToStr(1 + d) + '] starts with: ' +
              AIRes.GetPartText(d, true).Substring(0, 80) + '..')
          else
            memMetaData.Lines.Add(Indent + Indent + 'Part text[' + IntToStr(1 + d) + ']: ' + AIRes.GetPartText(d, true));
      memMetaData.Lines.Add(Indent + 'Number of media data parts: ' + length(AIRes.PartMediaData).ToString);
      for d := 0 to length(AIRes.PartMediaData) - 1 do
      begin
        Media := AIRes.ResultingMediaDataStream(s, d);
        try
          if TFirebaseHelpers.IsSupportImageType(s) then
          begin
            memMetaData.Lines.Add(Indent + Indent + 'Media data type: ' + s);
            ImageInd := length(fImages);
            SetLength(fImages, ImageInd + 1);
            fImages[ImageInd] := TBitmap.Create;
            fImages[ImageInd].LoadFromStream(Media);
            if ImageInd = 0 then
              imgMediaRes.Bitmap.Assign(fImages[ImageInd]);
            cboSelectMediaFile.Items.Add(Format(rsImage + ' %d', [ImageInd + 1]));
          end else
            memMetaData.Lines.Add(Indent + Indent + 'Unsupported media data type: ' + s);
        finally
          Media.Free;
        end;
      end;
      memMetaData.Lines.Add(Indent + 'Finish reason: ' + AIRes.FinishReasonAsStr);
      memMetaData.Lines.Add(Indent + 'Index: ' + AIRes.Index.ToString);
      memMetaData.Lines.Add(Indent + 'SafetyRating');
      if AIRes.SafetyRatings[hcHateSpeech].Probability > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Hate speech: Probability is ' +
          AIRes.SafetyRatings[hcHateSpeech].ProbabilityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcHateSpeech].ProbabilityScore));
      if AIRes.SafetyRatings[hcHateSpeech].Severity > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Hate speech: Severity is ' +
          AIRes.SafetyRatings[hcHateSpeech].SeverityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcHateSpeech].SeverityScore));
      if AIRes.SafetyRatings[hcHarassment].Probability > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Harassment: Probability is ' +
          AIRes.SafetyRatings[hcHarassment].ProbabilityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcHarassment].ProbabilityScore));
      if AIRes.SafetyRatings[hcHarassment].Severity > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Harassment: Severity is ' +
          AIRes.SafetyRatings[hcHarassment].SeverityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcHarassment].SeverityScore));
      if AIRes.SafetyRatings[hcSexuallyExplicit].Probability > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Sexually Explicit: Probability is ' +
          AIRes.SafetyRatings[hcSexuallyExplicit].ProbabilityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcSexuallyExplicit].ProbabilityScore));
      if AIRes.SafetyRatings[hcSexuallyExplicit].Severity > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Sexually Explicit: Severity is ' +
          AIRes.SafetyRatings[hcSexuallyExplicit].SeverityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcSexuallyExplicit].SeverityScore));
      if AIRes.SafetyRatings[hcDangerousContent].Probability > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Dangerous Content: Probability is ' +
          AIRes.SafetyRatings[hcDangerousContent].ProbabilityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcDangerousContent].ProbabilityScore));
      if AIRes.SafetyRatings[hcDangerousContent].Severity > psUnknown then
        memMetaData.Lines.Add(Indent + Indent + 'Dangerous Content: Severity is ' +
          AIRes.SafetyRatings[hcDangerousContent].SeverityAsStr + ', Score: ' +
          FloatToStr(AIRes.SafetyRatings[hcDangerousContent].SeverityScore));
      if AIRes.GroundingMetadata.ActiveGrounding then
      begin
        if length(AIRes.GroundingMetadata.WebSearchQuery) > 0 then
        begin
          memMetaData.Lines.Add(Indent + 'WebSearchQuery');
          for s in AIRes.GroundingMetadata.WebSearchQuery do
            memMetaData.Lines.Add(Indent + Indent + s);
        end;
      end;
    end;
    memMetaData.Lines.Add('Model version: ' + Response.ModelVersion);
{$IFDEF DEBUG}
    var NowStr: string := FormatDateTime('yymmdd_hhnnss', now);
    TFile.WriteAllText(Format('GeminiAI%s.md', [NowStr]), Response.ResultAsMarkDown);
    TFile.WriteAllText(Format('GeminiAI%s.html', [NowStr]), Response.ResultAsHTML);
{$ENDIF}
    memMarkdown.Lines.Text := Response.ResultAsMarkDown;
    fRequest.AddAnswerForNextRequest(Response.ResultAsMarkDown);
    btnNextQuestionInChat.Enabled := true;
    btnCalcRequestInChat.Enabled := true;
    if length(fImages) > 0 then
    begin
      cboSelectMediaFile.visible := length(fImages) > 1;
      cboSelectMediaFile.ItemIndex := 0;
      imgMediaRes.visible := true;
      tabMediaData.visible := true;
      TabControlResult.ActiveTab := tabMediaData;
    end;
    if not(gfrMaxToken in Response.FinishReasons) then
      fHTMLResultBrowser.LoadFromStrings(Response.ResultAsHTML, OnHTMLLoaded)
    else begin
      aniHTML.Enabled := false;
      aniHTML.Visible := false;
      tabHTMLRes.Visible := false;
      memMetaData.Lines.Insert(0, 'Increase max output token in the model parameters!');
      TabControlResult.ActiveTab := tabMetadata;
    end;
  end else begin
    TabControlResult.ActiveTab := tabRawResult;
    fHTMLResultBrowser.LoadFromStrings('<h1>REST API Call failed</h1><p>' + Response.FailureDetail + '</p>',
      OnHTMLLoaded);
  end;
  aniHTML.Enabled := false;
  aniHTML.Visible := false;
end;

procedure TGeminiAIFra.OnHTMLLoaded(const FileName: string; ErrorFlag: boolean);
begin
  if ErrorFlag and not memMarkdown.Lines.Text.IsEmpty then
    TabControlResult.ActiveTab := tabMarkdownRes
  else if length(fImages) = 0 then
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
  memMetaData.Lines.Add('Next question in chat: "' + memGeminiPrompt.Lines.Text + '"');
  fGeminiAI.generateContentByRequest(fRequest, OnGeminiAIGenContent);
end;
{$ENDREGION}

{$REGION 'Result handling'}
procedure TGeminiAIFra.btnSaveImageToFileClick(Sender: TObject);
begin
  if SaveDialogImgFile.Execute then
    imgMediaRes.Bitmap.SaveToFile(SaveDialogImgFile.FileName);
end;

procedure TGeminiAIFra.cboSelectMediaFileChange(Sender: TObject);
var
  s: string;
  Ind: integer;
begin
  s := cboSelectMediaFile.Items[cboSelectMediaFile.ItemIndex];
  Ind := StrToIntDef(s.Substring(pos(' ', s)), 0) - 1;
  if s.StartsWith(rsImage) then
  begin
    if (Ind >= 0) and (Ind < length(fImages)) then
      imgMediaRes.Bitmap.Assign(fImages[Ind]);
  end;
end;
{$ENDREGION}

{$REGION 'Calc Prompt Token'}
procedure TGeminiAIFra.btnCalcPromptTokenClick(Sender: TObject);
var
  Request: IGeminiAIRequest;
begin
  CheckAndCreateGeminiAIClass;
  if assigned(fHTMLResultBrowser) then
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
  if expSystemInstruction.IsChecked then
    Request.SetSystemInstruction(memSystemInstruction.Lines.Text);
  if chbUseGoogleSearch.IsChecked then
    Request.SetGroundingByGoogleSearch(trbGoogleSearchThreshold.Value);
  fGeminiAI.CountTokenOfRequest(Request, OnGeminiAITokenCount);
  tabHTMLRes.Visible := false;
  tabRawResult.Visible := false;
  tabMarkdownRes.Visible := false;
  tabMetadata.Visible := true;
  memMetaData.Lines.Text := 'Calculating...';
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
  memMetaData.Lines.Text := 'Calculating...';
end;

procedure TGeminiAIFra.OnGeminiAITokenCount(PromptToken, CachedContentToken: integer; const ErrMsg: string);
begin
  TabControlResult.ActiveTab := tabMetadata;
  memMetaData.Lines.Clear;
  if ErrMsg.IsEmpty then
  begin
    memMetaData.Lines.Add('Prompt token count: ' + PromptToken.ToString);
    memMetaData.Lines.Add('Cached content token count: ' + CachedContentToken.ToString);
  end else
    memMetaData.Lines.Add('Error: ' + ErrMsg);
end;
{$ENDREGION}

end.
