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

unit FB4D.VisionMLFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.IniFiles, System.JSON,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ListBox, FMX.Edit, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, FMX.Objects, FMX.Layouts, FMX.EditBox, FMX.SpinBox,
  FMX.Menus,
  FB4D.Interfaces;

type
  TVisionMLFra = class(TFrame)
    bntLoadML: TButton;
    btnClearML: TButton;
    btnVisionMLAnotateFile: TButton;
    btnVisionMLAnotateStorage: TButton;
    edtAnotateFileType: TEdit;
    edtRefStorage: TEdit;
    gpbMaxResultSet: TGroupBox;
    spbMaxFeatures: TSpinBox;
    gpbMLModel: TGroupBox;
    rdbLatestModel: TRadioButton;
    rdbStableModel: TRadioButton;
    rdbUnsetModel: TRadioButton;
    gpbMLResult: TGroupBox;
    rdbResAsJSON: TRadioButton;
    rdbResAsText: TRadioButton;
    Label40: TLabel;
    layResult: TLayout;
    sptMLVision: TSplitter;
    lstVisionML: TListBox;
    rctBackgroundML: TRectangle;
    imgAnotateFile: TImage;
    pathAnotateFile: TPath;
    lstFeatures: TListBox;
    lbiLabelDetection: TListBoxItem;
    lbiObjectLocalization: TListBoxItem;
    lbiTextDetection: TListBoxItem;
    lbiDocTextDetection: TListBoxItem;
    lbiFaceDetection: TListBoxItem;
    lbiLogoDetection: TListBoxItem;
    lbiLandmarkDetection: TListBoxItem;
    lbiWebDetection: TListBoxItem;
    lbiImageProp: TListBoxItem;
    lbiCropHints: TListBoxItem;
    lbiSafeSearch: TListBoxItem;
    lbiProductSearch: TListBoxItem;
    memAnnotateFile: TMemo;
    OpenDialogFileAnnotate: TOpenDialog;
    SaveDialog: TSaveDialog;
    popMLList: TPopupMenu;
    mniMLListExport: TMenuItem;
    procedure rdbResAsChange(Sender: TObject);
    procedure bntLoadMLClick(Sender: TObject);
    procedure btnClearMLClick(Sender: TObject);
    procedure btnVisionMLAnotateFileClick(Sender: TObject);
    procedure btnVisionMLAnotateStorageClick(Sender: TObject);
    procedure rctBackgroundMLResized(Sender: TObject);
    procedure lstVisionMLItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure mniMLListExportClick(Sender: TObject);
    procedure memAnnotateFileChange(Sender: TObject);
  private
    fVisionML: IVisionML;
    fMLResultAsJSON: TStringList;
    fMLResultAsEvaluatedText: TStringList;
    fMLMarkers: array of TPointF;
    function GetMLFileName: string;
    function CheckAndCreateMLVisionClass: boolean;
    procedure EvaluateMLVision(Res: IVisionMLResponse);
    procedure MLVisionError(const RequestID, ErrMsg: string);
    function CheckPreconditionForAnotateFile: boolean;
    function GetVisionMLFeatures: TVisionMLFeatures;
    function GetMLModel: TVisionModel;
    function CalcMLPreviewImgRect: TRectF;
    procedure SetMLMarkers(Points: array of TPointF; w, h: single);
    procedure RePosMLMarker;
    function ReconstructImage: boolean;
  public
    procedure LoadSettingsFromIniFile(IniFile: TIniFile);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
  end;

implementation

uses
  System.IOUtils, System.NetEncoding, System.StrUtils,
  {$IFDEF MACOS}
  Posix.Unistd,
  {$ENDIF}
  REST.Types,
  FB4D.VisionMLDefinition, FB4D.VisionML,
  FB4D.AuthFra, FB4D.DemoFmx;

{$R *.fmx}

{ TVisionMLFra }

{$REGION 'Class Handling'}

function TVisionMLFra.CheckAndCreateMLVisionClass: boolean;
begin
  if assigned(fVisionML) then
    exit(true);
  fmxFirebaseDemo.edtProjectID.ReadOnly := true;
  fmxFirebaseDemo.rctProjectIDDisabled.Visible := true;
  fmxFirebaseDemo.edtKey.ReadOnly := true;
  fmxFirebaseDemo.rctKeyDisabled.Visible := true;
  fVisionML := TVisionML.Create(fmxFirebaseDemo.edtProjectID.Text,
    fmxFirebaseDemo.edtKey.Text, fmxFirebaseDemo.AuthFra.Auth);
  result := true;
end;

{$ENDREGION}

{$REGION 'Settings'}

function TVisionMLFra.GetMLFileName: string;
begin
  result := IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    ChangeFileExt(ExtractFileName(ParamStr(0)), '.MLVision.txt');
end;

procedure TVisionMLFra.LoadSettingsFromIniFile(IniFile: TIniFile);
begin
  edtAnotateFileType.Text := IniFile.ReadString('MLVision', 'AnnotateFileType', '');
  edtRefStorage.Text := IniFile.ReadString('MLVision', 'AnnotateStorage', '');
  lbiTextDetection.IsChecked := IniFile.ReadBool('MLVision', 'FeatTD', true);
  lbiObjectLocalization.IsChecked := IniFile.ReadBool('MLVision', 'FeatOL', true);
  lbiLabelDetection.IsChecked := IniFile.ReadBool('MLVision', 'FeatLD', true);
  lbiCropHints.IsChecked := IniFile.ReadBool('MLVision', 'FeatCH', false);
  lbiLandmarkDetection.IsChecked := IniFile.ReadBool('MLVision', 'FeatLM', false);
  lbiFaceDetection.IsChecked := IniFile.ReadBool('MLVision', 'FeatFD', false);
  lbiDocTextDetection.IsChecked := IniFile.ReadBool('MLVision', 'FeatDD', false);
  lbiLogoDetection.IsChecked := IniFile.ReadBool('MLVision', 'FeatLO', false);
  lbiImageProp.IsChecked := IniFile.ReadBool('MLVision', 'FeatIP', false);
  lbiWebDetection.IsChecked := IniFile.ReadBool('MLVision', 'FeatWD', false);
  lbiProductSearch.IsChecked := IniFile.ReadBool('MLVision', 'FeatPS', false);
  lbiSafeSearch.IsChecked := IniFile.ReadBool('MLVision', 'FeatSS', false);
  if FileExists(GetMLFileName) then
  begin
    memAnnotateFile.BeginUpdate;
    try
      memAnnotateFile.Lines.LoadFromFile(GetMLFileName);
    finally
      memAnnotateFile.EndUpdate;
    end;
    rctBackgroundML.Visible := ReconstructImage;
    sptMLVision.Visible := rctBackgroundML.Visible;
  end;
  btnVisionMLAnotateFile.Enabled := CheckPreconditionForAnotateFile;
end;

procedure TVisionMLFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('MLVision', 'AnnotateStorage', edtRefStorage.Text);
  IniFile.WriteString('MLVision', 'AnnotateFileType', edtAnotateFileType.Text);
  IniFile.WriteBool('MLVision', 'FeatTD', lbiTextDetection.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatOL', lbiObjectLocalization.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatLD', lbiLabelDetection.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatCH', lbiCropHints.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatLM', lbiLandmarkDetection.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatFD', lbiFaceDetection.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatDD', lbiDocTextDetection.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatLO', lbiLogoDetection.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatIP', lbiImageProp.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatWD', lbiWebDetection.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatPS', lbiProductSearch.IsChecked);
  IniFile.WriteBool('MLVision', 'FeatSS', lbiSafeSearch.IsChecked);
  if memAnnotateFile.Lines.Count > 0 then
    memAnnotateFile.Lines.SaveToFile(GetMLFileName)
  else
    System.SysUtils.DeleteFile(GetMLFileName);
  FreeAndNil(fMLResultAsJSON);
  FreeAndNil(fMLResultAsEvaluatedText);
end;

{$ENDREGION}

procedure TVisionMLFra.rdbResAsChange(Sender: TObject);
begin
  lstVisionML.BeginUpdate;
  try
    if rdbResAsText.IsChecked then
      lstVisionML.Items.Assign(fMLResultAsEvaluatedText)
    else if rdbResAsJSON.IsChecked then
      lstVisionML.Items.Assign(fMLResultAsJSON);
  finally
    lstVisionML.EndUpdate;
  end;
end;

function TVisionMLFra.GetMLModel: TVisionModel;
begin
  if rdbLatestModel.IsChecked then
    result := TVisionModel.vmLatest
  else if rdbStableModel.IsChecked then
    result := TVisionModel.vmStable
  else
    result := TVisionModel.vmUnset;
end;

procedure TVisionMLFra.bntLoadMLClick(Sender: TObject);
var
  fs: TFileStream;
  ms: TStringStream;
  ext: string;
begin
  if OpenDialogFileAnnotate.Execute then
  begin
    fs := TFileStream.Create(OpenDialogFileAnnotate.FileName, fmOpenRead);
    ms := TStringStream.Create;
    try
      TNetEncoding.Base64.Encode(fs, ms);
      memAnnotateFile.Text := ms.DataString;
      ext := ExtractFileExt(OpenDialogFileAnnotate.FileName);
      if SameText('.tiff', ext) or SameText('.tif', ext) then
        edtAnotateFileType.Text := CONTENTTYPE_IMAGE_TIFF
      else if SameText('.gif', ext) then
        edtAnotateFileType.Text := CONTENTTYPE_IMAGE_GIF
      else if SameText('.pdf', ext) then
        edtAnotateFileType.Text := CONTENTTYPE_APPLICATION_PDF
      else
        edtAnotateFileType.Text := '?';
      btnVisionMLAnotateFile.Enabled := CheckPreconditionForAnotateFile;
    finally
      ms.Free;
      fs.Free;
    end;
    lstVisionML.Clear;
    pathAnotateFile.Visible := false;
    if (edtAnotateFileType.Text = CONTENTTYPE_IMAGE_TIFF) or
       (edtAnotateFileType.Text = CONTENTTYPE_IMAGE_GIF) then
    begin
      imgAnotateFile.Bitmap.LoadFromFile(OpenDialogFileAnnotate.FileName);
      rctBackgroundML.Visible := true;
      sptMLVision.Visible := true;
    end else begin
      rctBackgroundML.Visible := false;
      sptMLVision.Visible := false;
    end;
    gpbMLResult.Enabled := false;
  end;
end;

function TVisionMLFra.ReconstructImage: boolean;
var
  msIn, msOut: TStringStream;
begin
  result := false;
  if not memAnnotateFile.Text.IsEmpty and
     ((edtAnotateFileType.Text = CONTENTTYPE_IMAGE_TIFF) or
      (edtAnotateFileType.Text = CONTENTTYPE_IMAGE_GIF)) then
  begin
    msIn := TStringStream.Create(memAnnotateFile.Text);
    msOut := TStringStream.Create;
    try
      TNetEncoding.Base64.Decode(msIn, msOut);
      msOut.Position := 0;
      if msOut.Size > 0 then
      begin
        imgAnotateFile.Bitmap.LoadFromStream(msOut);
        result := true;
      end;
    finally
      msOut.Free;
      msIn.free;
    end;
  end;
end;

procedure TVisionMLFra.btnClearMLClick(Sender: TObject);
begin
  edtAnotateFileType.Text := '';
  memAnnotateFile.Lines.Clear;
  btnVisionMLAnotateFile.Enabled := false;
  lstVisionML.Clear;
  pathAnotateFile.Visible := false;
  rctBackgroundML.Visible := false;
  sptMLVision.Visible := false;
  gpbMLResult.Enabled := false;
end;

function TVisionMLFra.CheckPreconditionForAnotateFile: boolean;
begin
  result :=
    not(memAnnotateFile.Text.IsEmpty and edtAnotateFileType.Text.IsEmpty) and
    (edtAnotateFileType.Text <> '?');
end;

procedure TVisionMLFra.btnVisionMLAnotateFileClick(Sender: TObject);
begin
  CheckAndCreateMLVisionClass;
  FreeAndNil(fMLResultAsJSON);
  FreeAndNil(fMLResultAsEvaluatedText);
  fMLResultAsJSON := TStringList.Create;
  fMLResultAsEvaluatedText := TStringList.Create;
  lstVisionML.Items.Clear;
  btnVisionMLAnotateFile.Enabled := false;
  fVisionML.AnnotateFile(memAnnotateFile.Text, edtAnotateFileType.Text,
    GetVisionMLFeatures, EvaluateMLVision,  MLVisionError, TimeToStr(now),
      trunc(spbMaxFeatures.Value), GetMLModel);
end;

procedure TVisionMLFra.btnVisionMLAnotateStorageClick(Sender: TObject);
var
  ext: string;
  ContentType: TRESTContentType;
begin
  CheckAndCreateMLVisionClass;
  FreeAndNil(fMLResultAsJSON);
  FreeAndNil(fMLResultAsEvaluatedText);
  fMLResultAsJSON := TStringList.Create;
  fMLResultAsEvaluatedText := TStringList.Create;
  lstVisionML.Items.Clear;
  btnVisionMLAnotateStorage.Enabled := false;
  rctBackgroundML.Visible := false;
  sptMLVision.Visible := false;
  ext := ExtractFileExt(edtRefStorage.Text);
  if SameText('.tiff', ext) or SameText('.tif', ext) then
    ContentType := TRESTContentType.ctIMAGE_TIFF
  else if SameText('.gif', ext) then
    ContentType := TRESTContentType.ctIMAGE_GIF
  else if SameText('.pdf', ext) then
    ContentType := TRESTContentType.ctAPPLICATION_PDF
  else
    ContentType := edtAnotateFileType.Text;
  fVisionML.AnnotateStorage(edtRefStorage.Text, ContentType,
    GetVisionMLFeatures, EvaluateMLVision,  MLVisionError,
    trunc(spbMaxFeatures.Value), GetMLModel);
end;

procedure TVisionMLFra.EvaluateMLVision(Res: IVisionMLResponse);
var
  Page, Ind: integer;
  Status: TErrorStatus;
  Annotations: TAnnotationList;
  TextAnnotation: TTextAnnotation;
  FaceAnnotations: TFaceAnnotationList;
  LocalizedObjects: TLocalizedObjectList;
  ImagePropAnnotation: TImagePropertiesAnnotation;
  CropHintsAnnotation: TCropHintsAnnotation;
  WebDetection: TWebDetection;
  SafeSearchAnnotation: TSafeSearchAnnotation;
  ProductSearchAnnotation: TProductSearchAnnotation;
  ImageAnnotationContext: TImageAnnotationContext;
begin
  for Page := 0 to Res.GetNoPages - 1 do
  begin
    fMLResultAsEvaluatedText.Add(Format('Page: %d of %d',
      [Page + 1, Res.GetNoPages]));
    Status := Res.GetError(Page);
    if Status.ErrorFound then
      fMLResultAsEvaluatedText.Add('  ' + Status.AsStr);
    ImageAnnotationContext := res.ImageAnnotationContext(Page);
    ImageAnnotationContext.AddStrings(fMLResultAsEvaluatedText, 2);
    if lbiFaceDetection.IsChecked then
    begin
      FaceAnnotations := Res.FaceAnnotation(Page);
      if length(FaceAnnotations) = 0 then
        fMLResultAsEvaluatedText.Add('  No faces found')
      else begin
        for Ind := 0 to length(FaceAnnotations) - 1 do
        begin
          fMLResultAsEvaluatedText.Add(Format('  Face %d of %d',
              [Ind + 1, length(FaceAnnotations)]));
          FaceAnnotations[Ind].AddStrings(fMLResultAsEvaluatedText, 4);
        end;
      end;
    end;
    if lbiLabelDetection.IsChecked then
    begin
      Annotations := Res.LabelAnnotations(Page);
      if length(Annotations) = 0 then
        fMLResultAsEvaluatedText.Add('  No labels found')
      else begin
        for Ind := 0 to length(Annotations) - 1 do
        begin
          fMLResultAsEvaluatedText.Add(Format('  Label %d of %d',
            [Ind + 1, length(Annotations)]));
          Annotations[Ind].AddStrings(fMLResultAsEvaluatedText, 4);
        end;
      end;
    end;
    if lbiObjectLocalization.IsChecked then
    begin
      LocalizedObjects := Res.LocalizedObjectAnnotation(Page);
      if length(LocalizedObjects) = 0 then
        fMLResultAsEvaluatedText.Add('  No localized objects found')
      else begin
        for Ind := 0 to length(LocalizedObjects) - 1 do
        begin
          fMLResultAsEvaluatedText.Add(Format('  Localized objects %d of %d',
            [Ind + 1, length(LocalizedObjects)]));
          LocalizedObjects[Ind].AddStrings(fMLResultAsEvaluatedText, 4);
        end;
      end;
    end;
    if lbiLandmarkDetection.IsChecked then
    begin
      Annotations := Res.LandmarkAnnotations(Page);
      if length(Annotations) = 0 then
        fMLResultAsEvaluatedText.Add('  No landmarks found')
      else begin
        for Ind := 0 to length(Annotations) - 1 do
        begin
          fMLResultAsEvaluatedText.Add(Format('  Landmark %d of %d',
            [Ind + 1, length(Annotations)]));
          Annotations[Ind].AddStrings(fMLResultAsEvaluatedText, 4);
        end;
      end;
    end;
    if lbiLogoDetection.IsChecked then
    begin
      Annotations := Res.LogoAnnotations(Page);
      if length(Annotations) = 0 then
        fMLResultAsEvaluatedText.Add('  No logo found')
      else begin
        for Ind := 0 to length(Annotations) - 1 do
        begin
          fMLResultAsEvaluatedText.Add(Format('  Logo %d of %d',
            [Ind + 1, length(Annotations)]));
          Annotations[Ind].AddStrings(fMLResultAsEvaluatedText, 4);
        end;
      end;
    end;
    if lbiTextDetection.IsChecked then
    begin
      Annotations := Res.TextAnnotations(Page);
      for Ind := 0 to length(Annotations) - 1 do
      begin
        fMLResultAsEvaluatedText.Add(Format('  Text %d of %d',
          [Ind + 1, length(Annotations)]));
        Annotations[Ind].AddStrings(fMLResultAsEvaluatedText, 4);
      end;
    end;
    if lbiDocTextDetection.IsChecked or lbiTextDetection.IsChecked then
    begin
      TextAnnotation := Res.FullTextAnnotations(Page);
      TextAnnotation.AddStrings(fMLResultAsEvaluatedText, 2);
    end;
    if lbiImageProp.IsChecked then
    begin
      fMLResultAsEvaluatedText.Add('  Image properties');
      ImagePropAnnotation := Res.ImagePropAnnotation(Page);
      ImagePropAnnotation.AddStrings(fMLResultAsEvaluatedText, 4);
    end;
    if lbiCropHints.IsChecked then
    begin
      fMLResultAsEvaluatedText.Add('  Image crop hints');
      CropHintsAnnotation := Res.CropHintsAnnotation(Page);
      CropHintsAnnotation.AddStrings(fMLResultAsEvaluatedText, 4);
    end;
    if lbiWebDetection.IsChecked then
    begin
      fMLResultAsEvaluatedText.Add('  Web detection');
      WebDetection := Res.WebDetection(Page);
      WebDetection.AddStrings(fMLResultAsEvaluatedText, 4);
    end;
    if lbiSafeSearch.IsChecked then
    begin
      fMLResultAsEvaluatedText.Add('  Safe search annotation');
      SafeSearchAnnotation := Res.SafeSearchAnnotation(Page);
      SafeSearchAnnotation.AddStrings(fMLResultAsEvaluatedText, 4);
    end;
    if lbiProductSearch.IsChecked then
    begin
      fMLResultAsEvaluatedText.Add('  Product search annotation');
      ProductSearchAnnotation := Res.ProductSearchAnnotation(Page);
      ProductSearchAnnotation.AddStrings(fMLResultAsEvaluatedText, 4);
    end;
  end;
  fMLResultAsJSON.Text := Res.GetFormatedJSON;
  gpbMLResult.Enabled := true;
  if rdbResAsText.IsChecked then
    lstVisionML.Items.Assign(fMLResultAsEvaluatedText)
  else if rdbResAsJSON.IsChecked then
    lstVisionML.Items.Assign(fMLResultAsJSON);
  btnVisionMLAnotateFile.Enabled := CheckPreconditionForAnotateFile;
end;

procedure TVisionMLFra.MLVisionError(const RequestID, ErrMsg: string);
begin
  gpbMLResult.Enabled := false;
  lstVisionML.Items.Text := 'Error while asynchronous anotate for ' + RequestID;
  lstVisionML.Items.Add('Error: ' + ErrMsg);
  btnVisionMLAnotateFile.Enabled := CheckPreconditionForAnotateFile;
end;

procedure TVisionMLFra.mniMLListExportClick(Sender: TObject);
begin
  SaveDialog.Filename := 'ML-Results.txt';
  if SaveDialog.Execute then
    lstVisionML.Items.SaveToFile(SaveDialog.FileName);
end;

function TVisionMLFra.GetVisionMLFeatures: TVisionMLFeatures;
begin
  result := [];
  if lbiFaceDetection.IsChecked then
    result := result + [vmlFaceDetection];
  if lbiLandmarkDetection.IsChecked then
    result := result + [vmlLandmarkDetection];
  if lbiLogoDetection.IsChecked then
    result := result + [vmlLogoDetection];
  if lbiLabelDetection.IsChecked then
    result := result + [vmlLabelDetection];
  if lbiTextDetection.IsChecked then
    result := result + [vmlTextDetection];
  if lbiDocTextDetection.IsChecked then
    result := result + [vmlDocTextDetection];
  if lbiSafeSearch.IsChecked then
    result := result + [vmlSafeSearchDetection];
  if lbiImageProp.IsChecked then
    result := result + [vmlImageProperties];
  if lbiCropHints.IsChecked then
    result := result + [vmlCropHints];
  if lbiWebDetection.IsChecked then
    result := result + [vmlWebDetection];
  if lbiProductSearch.IsChecked then
    result := result + [vmlProductSearch];
  if lbiObjectLocalization.IsChecked then
    result := result + [vmlObjectLocalization];
end;

function TVisionMLFra.CalcMLPreviewImgRect: TRectF;
var
  RatioFrame, RatioImg: double;
  Offset, Dim: TPointF;
begin
  RatioFrame := imgAnotateFile.Width / imgAnotateFile.Height;
  RatioImg := imgAnotateFile.Bitmap.Width / imgAnotateFile.Bitmap.Height;
  if RatioFrame > RatioImg then
  begin
    Dim.X := RatioImg * imgAnotateFile.Height;
    Dim.Y := imgAnotateFile.Height;
    Offset.X := (imgAnotateFile.Width - Dim.X) / 2;
    Offset.Y := 0;
  end else begin
    Dim.X := imgAnotateFile.Width;
    Dim.Y := imgAnotateFile.Width / RatioImg;
    Offset.X := 0;
    Offset.Y := (imgAnotateFile.Height - Dim.Y) / 2;
  end;
  result.Create(Offset.X, Offset.Y, Offset.X + Dim.X, Offset.Y + Dim.Y);
end;

procedure TVisionMLFra.SetMLMarkers(Points: array of TPointF; w, h: single);
var
  c: integer;
begin
  SetLength(fMLMarkers, length(Points));
  for c := 0 to length(Points) - 1 do
    fMLMarkers[c] := TPointF.Create(Points[c].X / w, Points[c].Y / h);
  RePosMLMarker;
end;

procedure TVisionMLFra.RePosMLMarker;
var
  Bounds: TRectF;
  p: TPointF;
  Inital: boolean;
begin
  Bounds := CalcMLPreviewImgRect;
  pathAnotateFile.Position.X := Bounds.Left;
  pathAnotateFile.Position.Y := Bounds.Top;
  pathAnotateFile.Width := Bounds.Width;
  pathAnotateFile.Height := Bounds.Height;
  pathAnotateFile.Data.Clear;
  pathAnotateFile.Data.MoveTo(PointF(0, 0));
  pathAnotateFile.Data.MoveTo(PointF(1, 1));
  if length(fMLMarkers) > 1 then
  begin
    Inital := true;
    for p in fMLMarkers do
    begin
      if Inital then
        pathAnotateFile.Data.MoveTo(p)
      else
        pathAnotateFile.Data.LineTo(p);
      Inital := false;
    end;
    pathAnotateFile.Data.ClosePath;
  end
  else if length(fMLMarkers) = 1 then
  begin
    p := fMLMarkers[0];
    pathAnotateFile.Data.AddEllipse(
      RectF(p.X - 0.01, p.Y - 0.01,
            p.X + 0.01, p.Y + 0.01));
  end;
  pathAnotateFile.Visible := true;
end;

procedure TVisionMLFra.rctBackgroundMLResized(Sender: TObject);
begin
  if pathAnotateFile.Visible then
    RePosMLMarker;
end;

procedure TVisionMLFra.lstVisionMLItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);

  function ConvertToPoint(s: string): TPointF;
  var
    p1, p2: integer;
    X, Y: double;
  begin
    p1 := Pos('x: ', s);
    p2 := Pos(',', s);
    X := StrToFloat(s.Substring(p1 + 2, p2 - p1 - 3));
    s := s.Substring(p2);
    p1 := Pos('y: ', s);
    p2 := Pos(',', s);
    if p2 <= 0 then
      p2 := Pos(']', s);
    Y := StrToFloat(s.Substring(p1 + 2, p2 - p1 - 3));
    result := PointF(X, Y);
  end;

var
  Line: string;
  Vertices: TStringDynArray;
begin
  if not imgAnotateFile.visible then
    exit;
  Line := Trim(Item.Text);
  if Line.StartsWith('Vertices: ') then
  begin
    Vertices := SplitString(Line, '[');
    if length(Vertices) = 5 then
      SetMLMarkers(
        [ConvertToPoint(Vertices[1]),
         ConvertToPoint(Vertices[2]),
         ConvertToPoint(Vertices[3]),
         ConvertToPoint(Vertices[4])],
        imgAnotateFile.Bitmap.Width,
        imgAnotateFile.Bitmap.Height);
  end
  else if Line.StartsWith('Normalized Vertices: ') then
  begin
    Line := Line.SubString(length('Normalized Vertices: '));
    Vertices := SplitString(Line, '[');
    if length(Vertices) = 5 then
      SetMLMarkers(
        [ConvertToPoint(Vertices[1]),
         ConvertToPoint(Vertices[2]),
         ConvertToPoint(Vertices[3]),
         ConvertToPoint(Vertices[4])],
        1, 1);
  end
  else if Line.Contains('Face landmark ') and Line.Contains(' at [') then
  begin
    Line := Line.Substring(Pos(' at [', Line) + 2);
    SetMLMarkers([ConvertToPoint(Line)],
      imgAnotateFile.Bitmap.Width,
      imgAnotateFile.Bitmap.Height);
  end else
    pathAnotateFile.Visible := false;
end;

procedure TVisionMLFra.memAnnotateFileChange(Sender: TObject);
begin
  btnVisionMLAnotateFile.Enabled := CheckPreconditionForAnotateFile;
end;

end.
