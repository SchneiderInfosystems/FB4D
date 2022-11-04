unit PhotoThreads;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Threading, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.ListBox, FMX.StdCtrls,
  FMX.Consts,
  REST.Types,
  FB4D.Interfaces, FB4D.VisionMLDefinition;

type
  TPhotoInterpretation = class;

  TPhotoThread = class(TThread)
  public const
    cCollectionID = 'photos';
    cStorageFolder = 'photos';
  public type
    TOnSuccess = procedure(Item: TListBoxItem) of object;
    TOnFailed = procedure(Item: TListBoxItem; const Msg: string) of object;
    TDirection = (Upload, Download);
  private const
    {$IFDEF MSWINDOWS}
    cVisionMLFileExt = STIFFImageExtension;
    cVisionMLContentType = CONTENTTYPE_IMAGE_TIFF;
    {$ENDIF}
    {$IFDEF ANDROID}
    cVisionMLFileExt = SGIFImageExtension;
    cVisionMLContentType = CONTENTTYPE_IMAGE_GIF;
    {$ENDIF}
    cMaxResults = 5;
  private
    fConfig: IFirebaseConfiguration;
    fDirection: TDirection;
    fDocID: string;
    fUID: string;
    fBase64: string;
    fItem: TListBoxItem;
    fImage: TMemoryStream;
    fThumbnail: TBitmap;
    fContentType: TRESTContentType;
    fPhotoInterpretation: TPhotoInterpretation;
    fOnSuccess: TOnSuccess;
    fOnFailed: TOnFailed;
    // For Upload
    procedure UploadPhotoInThread;
    procedure VisionML;
    function CreateDocument(Item: TListBoxItem): IFirestoreDocument;
    procedure UploadImageToStorage;
    function ConvertImageForImageClass(Bmp: TBitmap;
      const Ext: string): TMemoryStream;
    // For Download
    procedure DownloadPhotoInThread;
    function DownloadImageFromStorage: TBitmap;
  protected
    procedure Execute; override;
  public
    constructor CreateForUpload(const Config: IFirebaseConfiguration;
      const UID: string; Image: TBitmap; Item: TListBoxItem);
    constructor CreateForDownload(const Config: IFirebaseConfiguration;
      const UID: string; lstPhotoList: TListBox;  Doc: IFirestoreDocument);
    destructor Destroy; override;
    procedure StartThread(OnSuccess: TOnSuccess; fOnFailed: TOnFailed);
    class function ThumbSize: TPoint;
    class function SearchItem(lstPhotoList: TListBox;
      const DocID: string): TListBoxItem;
    class function CreateThumbnail(Bmp: TBitmap): TBitmap;
    class function GetStorageObjName(const DocID, UID: string): string;
  end;

  TPhotoInterpretation = class
  private const
    cMinScore = 0.66;
  private
    fLabels: TStringList;
    fTexts: TStringList;
    class var FRefList: TList<TPhotoInterpretation>;
    function GetLabelInfo: string;
    function GetFullInfo: string;
  public
    class constructor ClassCreate;
    class destructor ClassDestroy;
    constructor Create(Labels: TAnnotationList; FullText: TTextAnnotation);
      overload;
    constructor Create(Labels, Texts: TStringDynArray); overload;
    destructor Destroy; override;
    procedure SetLabels(Labels: TStringDynArray);
    procedure SetTexts(Texts: TStringDynArray);
    property FullInfo: string read GetFullInfo;
    property LabelInfo: string read GetLabelInfo;
    property Labels: TStringList read fLabels;
    property Texts: TStringList read fTexts;
  end;

implementation

uses
  System.SyncObjs, System.NetEncoding, System.JSON,
  FMX.Surfaces,
  FB4D.VisionML, FB4D.Helpers, FB4D.Document;

resourcestring
  rsVisionMLFailed = 'Vision ML failed: ';
  rsVisionMLNotAvailable = 'Vision ML not available';
  rsLabels = 'Labels: ';
  rsNoLabels = 'No labels found';
  rsTexts = 'Texts: ';
  rsNoTexts = 'No texts found';

{ TPhotoThread }

{$REGION 'Helpers as class functions'}
class function TPhotoThread.ThumbSize: TPoint;
const
  Size: TPoint = (X: 256; Y: 256);
begin
  result := Size;
end;

class function TPhotoThread.CreateThumbnail(Bmp: TBitmap): TBitmap;
var
  W, H: single;
begin
  Assert(Bmp.Width > 0, 'CreateThumbnail failed by width <= 0');
  Assert(Bmp.Height > 0, 'CreateThumbnail failed by height <= 0');
  if Bmp.Width / Bmp.Height > ThumbSize.X / ThumbSize.Y then
  begin
    // Larger width than height
    W := ThumbSize.X;
    H := Bmp.Height / Bmp.Width * W;
  end else begin
    // Larger height than width
    H := ThumbSize.Y;
    W := Bmp.Width / Bmp.Height * H;
  end;
  Result := TBitmap.Create(trunc(W), trunc(H));
  if Result.Canvas.BeginScene then
  begin
    try
      Result.Canvas.DrawBitmap(Bmp, RectF(0, 0, Bmp.Width, Bmp.Height),
        RectF(0, 0, W, H), 1);
    finally
      Result.Canvas.EndScene;
    end;
  end;
end;

class function TPhotoThread.SearchItem(lstPhotoList: TListBox;
  const DocID: string): TListBoxItem;
var
  c: integer;
begin
  result := nil;
  for c := 0 to lstPhotoList.Items.Count  - 1 do
    if lstPhotoList.ItemByIndex(c).TagString = DocID then
      exit(lstPhotoList.ItemByIndex(c));
end;
{$ENDREGION}

{$REGION 'Upload'}
constructor TPhotoThread.CreateForUpload(const Config: IFirebaseConfiguration;
  const UID: string; Image: TBitmap; Item: TListBoxItem);
var
  Img: TMemoryStream;
  Base64: TStringStream;
begin
  inherited Create(true);
  fConfig := Config;
  fDirection := Upload;
  fUID := UID;
  fItem := Item;
  fImage := TMemoryStream.Create;
  Image.SaveToStream(fImage);
  fImage.Position := 0;
  fContentType := TFirebaseHelpers.ImageStreamToContentType(fImage);
  if length(fContentType) = 0 then
  begin
    // Unsupported image type: Convert to JPG!
    fImage.Free;
    fImage := ConvertImageForImageClass(Image, SJPGImageExtension);
    fContentType := TRESTContentType.ctIMAGE_JPEG;
  end;
  try
    Img := ConvertImageForImageClass(Image, cVisionMLFileExt);
    Base64 := TStringStream.Create;
    try
      if assigned(Img) then
      begin
        Img.Position := 0;
        TNetEncoding.Base64.Encode(Img, Base64);
        fBase64 := Base64.DataString;
      end;
    finally
      Img.Free;
      Base64.Free;
    end;
  except
    fBase64 := '';
  end;
  FreeOnTerminate := true;
end;

function TPhotoThread.ConvertImageForImageClass(Bmp: TBitmap;
  const Ext: string): TMemoryStream;
var
  Surface: TBitmapSurface;
begin
  result := TMemoryStream.Create;
  Surface := TBitmapSurface.Create;
  try
    Surface.Assign(Bmp);
    if not TBitmapCodecManager.SaveToStream(result, Surface, Ext) then
      FreeAndNil(result);
  finally
    Surface.Free;
  end;
end;

procedure TPhotoThread.VisionML;
var
  Resp: IVisionMLResponse;
begin
  if fBase64.IsEmpty then
    fPhotoInterpretation := TPhotoInterpretation.Create([],
      [rsVisionMLNotAvailable])
  else begin
    try
      Resp := fConfig.VisionML.AnnotateFileSynchronous(fBase64,
        cVisionMLContentType, [vmlLabelDetection, vmlDocTextDetection],
        cMaxResults);
      fPhotoInterpretation := TPhotoInterpretation.Create(Resp.LabelAnnotations,
        Resp.FullTextAnnotations);
    except
      on e: exception do
        // fall back when ML fails
        fPhotoInterpretation := TPhotoInterpretation.Create([],
          [rsVisionMLFailed + e.Message]);
    end;
  end;
end;

function TPhotoThread.CreateDocument(Item: TListBoxItem): IFirestoreDocument;
var
  Arr: TFirestoreArr;
  c: integer;
begin
  Assert(assigned(fPhotoInterpretation), 'PhotoInterpretation missing');
  fDocID := TFirebaseHelpers.CreateAutoID(PUSHID);
  TThread.Synchronize(nil,
    procedure
    begin
      if not Application.Terminated then
        Item.TagString := fDocID;
    end);
  result := TFirestoreDocument.Create(fDocID);
  result.AddOrUpdateField(TJSONObject.SetString('fileName', Item.Text));
  SetLength(Arr, fPhotoInterpretation.Labels.Count);
  for c := 0 to length(Arr) - 1 do
    Arr[c] := TJSONObject.SetStringValue(fPhotoInterpretation.Labels[c]);
  result.AddOrUpdateField(TJSONObject.SetArray('labels', Arr));
  SetLength(Arr, fPhotoInterpretation.Texts.Count);
  for c := 0 to length(Arr) - 1 do
    Arr[c] := TJSONObject.SetStringValue(fPhotoInterpretation.Texts[c]);
  result.AddOrUpdateField(TJSONObject.SetArray('texts', Arr));
  result.AddOrUpdateField(TJSONObject.SetString('createdBy', fUID));
  result.AddOrUpdateField(TJSONObject.SetTimeStamp('DateTime', now));
  {$IFDEF DEBUG}
  TFirebaseHelpers.Log('Doc: ' + result.AsJSON.ToJSON);
  {$ENDIF}
end;

procedure TPhotoThread.UploadImageToStorage;
var
  Obj: IStorageObject;
  Path: string;
begin
  Path := GetStorageObjName(fDocID, fUID);
  Obj := fConfig.Storage.UploadSynchronousFromStream(fImage, Path, fContentType);
end;

procedure TPhotoThread.UploadPhotoInThread;
var
  Doc: IFirestoreDocument;
begin
  // 1st: Analyse image by VisionML
  VisionML;
  // 2nd: Create document
  Doc := CreateDocument(fItem);
  // 3rd: Upload storage
  UploadImageToStorage;
  // 4th: Upload document
  fConfig.Database.InsertOrUpdateDocumentSynchronous(
    [cCollectionID, Doc.DocumentName(false)], Doc);
end;
{$ENDREGION}

{$REGION 'Download'}
constructor TPhotoThread.CreateForDownload(const Config: IFirebaseConfiguration;
  const UID: string; lstPhotoList: TListBox; Doc: IFirestoreDocument);
var
  PhotoInterpretation: TPhotoInterpretation;
begin
  inherited Create(true);
  fConfig := Config;
  fDirection := Download;
  fDocID := Doc.DocumentName(false);
  fUID := UID;
  fItem := SearchItem(lstPhotoList, fDocID);
  if assigned(fItem) then
  begin
    fItem.Text := Doc.GetStringValue('fileName');
    if assigned(fItem.Data) then
    begin
      PhotoInterpretation := fItem.Data as TPhotoInterpretation;
      PhotoInterpretation.SetLabels(Doc.GetArrayStringValues('labels'));
      PhotoInterpretation.SetTexts(Doc.GetArrayStringValues('texts'));
    end else begin
      PhotoInterpretation := TPhotoInterpretation.Create(
        Doc.GetArrayStringValues('labels'),
        Doc.GetArrayStringValues('texts'));
      fItem.Data := PhotoInterpretation;
    end;
    fItem.ItemData.Detail := PhotoInterpretation.GetLabelInfo;
  end else begin
    fItem := TListBoxItem.Create(lstPhotoList);
    fItem.Text := Doc.GetStringValue('fileName');
    PhotoInterpretation := TPhotoInterpretation.Create(
      Doc.GetArrayStringValues('labels'),
      Doc.GetArrayStringValues('texts'));
    fItem.Data := PhotoInterpretation;
    fItem.ItemData.Detail := PhotoInterpretation.GetLabelInfo;
    fItem.TagString := Doc.DocumentName(false);
    lstPhotoList.AddObject(fItem); // add new item to end of list
  end;
  fImage := TMemoryStream.Create;
  FreeOnTerminate := true;
end;

function TPhotoThread.DownloadImageFromStorage: TBitmap;
var
  Obj: IStorageObject;
  Path: string;
begin
  Path := GetStorageObjName(fDocID, fUID);
  Obj := fConfig.Storage.GetAndDownloadSynchronous(Path, fImage);
  result := TBitmap.Create;
  fImage.Position := 0;
  result.LoadFromStream(fImage);
end;

procedure TPhotoThread.DownloadPhotoInThread;
var
  Image: TBitmap;
begin
  Image := DownloadImageFromStorage;
  try
    fThumbnail := CreateThumbnail(Image);
  finally
    Image.Free;
  end;
end;
{$ENDREGION}

{$REGION 'Upload and Download'}
destructor TPhotoThread.Destroy;
begin
  fThumbnail.Free;
  fImage.Free;
  inherited;
end;

class function TPhotoThread.GetStorageObjName(const DocID, UID: string): string;
begin
  result := cStorageFolder + '/' + UID + '/' + DocID;
end;

procedure TPhotoThread.StartThread(OnSuccess: TOnSuccess; fOnFailed: TOnFailed);
begin
  fOnSuccess := OnSuccess;
  fOnFailed := fOnFailed;
  Start;
end;

procedure TPhotoThread.Execute;
begin
  inherited;
  try
    case fDirection of
      Upload:
        UploadPhotoInThread;
      Download:
        DownloadPhotoInThread;
    end;
    if not Application.Terminated then
      TThread.Synchronize(nil,
        procedure
        begin
          case fDirection of
            Upload:
              begin
                fItem.Data := fPhotoInterpretation;
                fItem.ItemData.Detail := fPhotoInterpretation.GetLabelInfo;
              end;
            Download:
              begin
                fItem.ItemData.Bitmap.Assign(fThumbnail);
              end;
          end;
          fOnSuccess(fItem);
        end);
  except
    on e: exception do
      if not Application.Terminated then
        TThread.Synchronize(nil,
          procedure
          begin
            fOnFailed(fItem, e.Message);
          end);
  end;
end;
{$ENDREGION}

{ TPhotoInterpretation }

class constructor TPhotoInterpretation.ClassCreate;
begin
  FRefList := TList<TPhotoInterpretation>.Create;
end;

class destructor TPhotoInterpretation.ClassDestroy;
var
  PI: TPhotoInterpretation;
begin
  for PI in FRefList do
    PI.Free;
  FRefList.Free;
end;

constructor TPhotoInterpretation.Create(Labels: TAnnotationList;
  FullText: TTextAnnotation);
const
  cMinConf = 0.66;
var
  Ent: TEntityAnnotation;
begin
  fLabels := TStringList.Create;
  fTexts := TStringList.Create;
  for Ent in Labels do
    if Ent.Score > cMinScore then
      fLabels.Add(Ent.Description);
  fTexts.Text := FullText.GetText(cMinConf);
  FRefList.Add(self); // Automatically destroy this object at application end
end;

constructor TPhotoInterpretation.Create(Labels, Texts: TStringDynArray);
var
  s: string;
begin
  fLabels := TStringList.Create;
  fTexts := TStringList.Create;
  for s in Labels do
    fLabels.Add(s);
  for s in Texts do
    fTexts.Add(s);
  FRefList.Add(self); // Automatically destroy this object at application end
end;

destructor TPhotoInterpretation.Destroy;
begin
  fTexts.Free;
  fLabels.Free;
  inherited;
end;

procedure TPhotoInterpretation.SetLabels(Labels: TStringDynArray);
var
  s: string;
begin
  fLabels.Clear;
  for s in Labels do
    fLabels.Add(s);
end;

procedure TPhotoInterpretation.SetTexts(Texts: TStringDynArray);
var
  s: string;
begin
  fTexts.Clear;
  for s in Texts do
    fTexts.Add(s);
end;

function TPhotoInterpretation.GetFullInfo: string;
begin
  if fLabels.Count > 0 then
    result := rsLabels + fLabels.CommaText
  else
    result := rsNoLabels;
  result := result + #13#10;
  if fTexts.Count = 0 then
    result := result + rsNoTexts
  else
    result := result + rsTexts + #13#10 + fTexts.Text;
end;

function TPhotoInterpretation.GetLabelInfo: string;
begin
  fLabels.Delimiter := ',';
  fLabels.QuoteChar := #0;
  result := fLabels.DelimitedText;
  if fTexts.Count > 0 then
  begin
    if not result.IsEmpty then
      result := result + ',';
    result := result + 'Text: "' + trim(fTexts[0]) + '"';
  end;
end;

end.
