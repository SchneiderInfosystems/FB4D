unit PhotoThreads2;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Threading, System.Generics.Collections,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.ListBox, FMX.StdCtrls,
  FMX.Consts,
  REST.Types,
  FB4D.Interfaces, FB4D.VisionMLDefinition;

type
  TPhotoThread = class(TThread)
  public const
    cCollectionID = 'photo2';
    cStorageFolder = 'photo2';
  public type
    TOnSuccess = procedure(Item: TListBoxItem) of object;
    TOnFailed = procedure(Item: TListBoxItem; const Msg: string) of object;
    TDirection = (Upload, Download);
  private
    fConfig: IFirebaseConfiguration;
    fDirection: TDirection;
    fDocID: string;
    fUID: string;
    fItem: TListBoxItem;
    fImage: TMemoryStream;
    fThumbnail: TBitmap;
    fContentType: TRESTContentType;
    fOnSuccess: TOnSuccess;
    fOnFailed: TOnFailed;
    // For Upload
    procedure UploadPhotoInThread;
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

implementation

uses
  System.SyncObjs, System.NetEncoding, System.JSON,
  FMX.Surfaces,
  FB4D.Helpers, FB4D.Document;

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

function TPhotoThread.CreateDocument(Item: TListBoxItem): IFirestoreDocument;
begin
  fDocID := TFirebaseHelpers.CreateAutoID(PUSHID);
  TThread.Synchronize(nil,
    procedure
    begin
      if not Application.Terminated then
        Item.TagString := fDocID;
    end);
  result := TFirestoreDocument.Create(fDocID);
  result.AddOrUpdateField(TJSONObject.SetString('fileName', Item.Text));
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
  // 1st: Create document
  Doc := CreateDocument(fItem);
  // 2nd: Upload storage
  UploadImageToStorage;
  // 3rd: Upload document
  fConfig.Database.InsertOrUpdateDocumentSynchronous(
    [cCollectionID, Doc.DocumentName(false)], Doc);
end;
{$ENDREGION}

{$REGION 'Download'}
constructor TPhotoThread.CreateForDownload(const Config: IFirebaseConfiguration;
  const UID: string; lstPhotoList: TListBox; Doc: IFirestoreDocument);
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
  end else begin
    fItem := TListBoxItem.Create(lstPhotoList);
    fItem.Text := Doc.GetStringValue('fileName');
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

end.
