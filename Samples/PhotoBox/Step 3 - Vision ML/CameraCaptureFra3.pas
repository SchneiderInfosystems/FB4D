unit CameraCaptureFra3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Threading, System.SyncObjs, System.Permissions,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Media;

type
  TOnPhotoCaptured = procedure(Image: TBitmap; const FileName: string) of object;
  TfraCameraCapture3 = class(TFrame)
    imgCameraPreview: TImage;
    CameraComponent: TCameraComponent;
    rctBackgroundImg: TRectangle;
    btnTakePhotoFromCamera: TButton;
    btnTake: TButton;
    btnRestart: TButton;
    OpenDialogPictures: TOpenDialog;
    SaveDialogPictures: TSaveDialog;
    procedure CameraComponentSampleBufferReady(Sender: TObject;
      const ATime: TMediaTime);
    procedure btnTakePhotoFromCameraClick(Sender: TObject);
    procedure btnRestartClick(Sender: TObject);
    procedure btnTakeClick(Sender: TObject);
  private
    fCSForCamAccess: TCriticalSection;
    fBitmapFromCam: TBitmap;
    fOnPhotoCaptured: TOnPhotoCaptured;
    procedure DisplayCameraPreviewFrame;
    procedure StopCapture;
    procedure SetInitialDir(const Dir: string);
    function GetInitialDir: string;
  private
    {$REGION 'Platform specific stuff'}
    {$IFDEF ANDROID}
    fAppPermissions: TArray<string>;
    procedure RequestPermissionsResultEvent(Sender: TObject;
      const APermissions: TClassicStringDynArray;
      const AGrantResults: TClassicPermissionStatusDynArray);
    procedure DoDidFinishTakePhotoOnAndroid(Image: TBitmap);
    procedure StartCaptureOnAndroid;
    procedure StartTakePhotoFromLibOnAndroid;
    {$ENDIF}
    {$IFDEF MSWINDOWS}
    procedure StartCaptureOnWindows;
    procedure StartTakePhotoFromLibOnWindows;
    procedure SaveImageToFileOnWindows(Img: TStream; const ContentType: string);
    {$ENDIF}
    {$ENDREGION}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartCapture(OnPhotoCaptured: TOnPhotoCaptured = nil);
    procedure StartTakePhotoFromLib(OnPhotoCaptured: TOnPhotoCaptured);
    procedure SaveImageToFile(Image: TStream; const ContentType: string);
    function Bitmap: TBitmap;
    procedure ToastMsg(const Msg: string);
    property InitialDir: string read GetInitialDir write SetInitialDir;
    function GetFileName: string;
  end;

implementation

{$R *.fmx}

uses
  {$IFDEF ANDROID}
  Androidapi.Helpers, Androidapi.JNI.Os, Androidapi.JNI.JavaTypes,
  Androidapi.JNI.Toast,
  FMX.MediaLibrary, FMX.Platform,
  {$ENDIF}
  FB4D.Helpers,
  PhotoBoxMainFmx3;

resourcestring
  rsWaitForCam = 'Wait for Camera';
  rsFileName = 'Photo from %s';
  rsImgFilter = 'Image file (*%s)|*%s';
  rsDeviceDoesNotSupportCam = 'This device does not support the camera service';
  rsNotSupportedOnThisPlatform = 'Not supported on this platform';

{ TfraCameraCapture }

constructor TfraCameraCapture3.Create(AOwner: TComponent);
begin
  inherited;
  fCSForCamAccess := TCriticalSection.Create;
  fBitmapFromCam := nil;
  {$IFDEF ANDROID}
  fAppPermissions := [JStringToString(TJManifest_permission.JavaClass.CAMERA),
    JStringToString(TJManifest_permission.JavaClass.READ_EXTERNAL_STORAGE),
    JStringToString(TJManifest_permission.JavaClass.WRITE_EXTERNAL_STORAGE)];
  {$ENDIF}
end;

destructor TfraCameraCapture3.Destroy;
begin
  CameraComponent.Active := false;
  FreeAndNil(fBitmapFromCam);
  fCSForCamAccess.Free;
  inherited;
end;

procedure TfraCameraCapture3.SetInitialDir(const Dir: string);
begin
  OpenDialogPictures.InitialDir := Dir;
  SaveDialogPictures.InitialDir := Dir;
end;

function TfraCameraCapture3.GetInitialDir: string;
begin
  result := OpenDialogPictures.InitialDir;
end;

procedure TfraCameraCapture3.StartCapture(OnPhotoCaptured: TOnPhotoCaptured);
begin
  if assigned(OnPhotoCaptured) then
    fOnPhotoCaptured := OnPhotoCaptured;
  {$IFDEF MSWINDOWS}
  StartCaptureOnWindows;
  {$ENDIF}
  {$IFDEF ANDROID}
  StartCaptureOnAndroid;
  {$ENDIF}
end;

{$IFDEF MSWINDOWS}
procedure TfraCameraCapture3.StartCaptureOnWindows;
begin
  fmxMain.WipeToTab(fmxMain.tabCaptureImg);
  fCSForCamAccess.Acquire;
  try
    if not assigned(fBitmapFromCam) then
      fBitmapFromCam := TBitmap.Create(640, 480)
    else begin
      fBitmapFromCam.Width := 640;
      fBitmapFromCam.Height := 480;
    end;
    fBitmapFromCam.Canvas.BeginScene;
    fBitmapFromCam.Clear(TAlphaColors.White);
    fBitmapFromCam.Canvas.Fill.Kind := TBrushKind.Solid;
    fBitmapFromCam.Canvas.Fill.Color := TAlphaColorRec.Red;
    fBitmapFromCam.Canvas.Font.Size := 20;
    fBitmapFromCam.Canvas.FillText(
      RectF(10, 10, fBitmapFromCam.Width - 10, fBitmapFromCam.Height - 10),
      rsWaitForCam, false, 1, [], TTextAlign.Center, TTextAlign.Center);
    fBitmapFromCam.Canvas.EndScene;
    imgCameraPreview.Bitmap.Assign(fBitmapFromCam);
  finally
    fCSForCamAccess.Release;
  end;
  btnTake.Visible := false;
  btnRestart.Visible := false;
  btnTakePhotoFromCamera.Visible := true;
  TThread.Queue(nil,
    procedure
    begin
      Application.ProcessMessages;
      CameraComponent.Active := true;
    end);
end;
{$ENDIF}

procedure TfraCameraCapture3.StopCapture;
begin
  CameraComponent.Active := false;
  btnTake.Visible := true;
  btnRestart.Visible := true;
  btnTakePhotoFromCamera.Visible := false;
end;

function TfraCameraCapture3.Bitmap: TBitmap;
begin
  fCSForCamAccess.Acquire;
  try
    result := fBitmapFromCam;
  finally
    fCSForCamAccess.Release;
  end;
end;

procedure TfraCameraCapture3.btnRestartClick(Sender: TObject);
begin
  StartCapture;
end;

procedure TfraCameraCapture3.btnTakeClick(Sender: TObject);
begin
  if assigned(fOnPhotoCaptured) then
    fOnPhotoCaptured(Bitmap, GetFileName);
end;

procedure TfraCameraCapture3.btnTakePhotoFromCameraClick(Sender: TObject);
begin
  StopCapture;
end;

procedure TfraCameraCapture3.CameraComponentSampleBufferReady(Sender: TObject;
  const ATime: TMediaTime);
begin
  if Application.Terminated then
    exit;
  Assert(assigned(fCSForCamAccess), 'Critical section missing');
  fCSForCamAccess.Acquire;
  try
    if not assigned(fBitmapFromCam) then
      fBitmapFromCam := TBitmap.Create(CameraComponent.GetCaptureSetting.Width,
        CameraComponent.GetCaptureSetting.Height);
    CameraComponent.SampleBufferToBitmap(fBitmapFromCam, true);
  finally
    fCSForCamAccess.Release;
  end;
  TThread.Queue(nil, DisplayCameraPreviewFrame);
end;

procedure TfraCameraCapture3.DisplayCameraPreviewFrame;
begin
  fCSForCamAccess.Acquire;
  try
    imgCameraPreview.Bitmap.Assign(fBitmapFromCam);
  finally
    fCSForCamAccess.Release;
  end;
end;

procedure TfraCameraCapture3.StartTakePhotoFromLib(
  OnPhotoCaptured: TOnPhotoCaptured);
begin
  fOnPhotoCaptured := OnPhotoCaptured;
  {$IFDEF MSWINDOWS}
  StartTakePhotoFromLibOnWindows;
  {$ENDIF}
  {$IFDEF ANDROID}
  StartTakePhotoFromLibOnAndroid;
  {$ENDIF}
end;

procedure TfraCameraCapture3.SaveImageToFile(Image: TStream;
  const ContentType: string);
begin
  {$IFDEF MSWINDOWS}
  SaveImageToFileOnWindows(Image, ContentType);
  {$ENDIF}
  {$IFDEF ANDROID}
  ToastMsg(rsNotSupportedOnThisPlatform);
  {$ENDIF}
end;

function TfraCameraCapture3.GetFileName: string;
var
  dt: string;
begin
  DateTimeToString(dt, 'dd/mm/yyyy HH:MM', now);
  result := Format(rsFileName, [dt]);
end;

{$REGION 'Platform specific stuff'}
procedure TfraCameraCapture3.ToastMsg(const Msg: string);
begin
  {$IFDEF MSWINDOWS}
  fmxMain.lblStatus.Text := Msg;
  {$ENDIF}
  {$IFDEF ANDROID}
  Toast(Msg);
  {$ENDIF}
end;

{$IFDEF ANDROID}
procedure TfraCameraCapture3.StartCaptureOnAndroid;
var
  Service: IFMXCameraService;
  Params: TParamsPhotoQuery;
begin
  PermissionsService.RequestPermissions(fAppPermissions,
    RequestPermissionsResultEvent);
  if TPlatformServices.Current.SupportsPlatformService(IFMXCameraService,
    Service) then
  begin
    Params.Editable := false;
    Params.NeedSaveToAlbum := false;
    Params.RequiredResolution := TSize.Create(1920, 1080);
    Params.OnDidFinishTaking := DoDidFinishTakePhotoOnAndroid;
    Service.TakePhoto(fmxMain.btnCaptureImg, Params);
  end else
    Toast(rsDeviceDoesNotSupportCam, LongToast);
end;

procedure TfraCameraCapture3.RequestPermissionsResultEvent(Sender: TObject;
  const APermissions: TClassicStringDynArray;
  const AGrantResults: TClassicPermissionStatusDynArray);
begin
  // nothing to do
end;

procedure TfraCameraCapture3.StartTakePhotoFromLibOnAndroid;
var
  Service: IFMXTakenImageService;
  Params: TParamsPhotoQuery;
begin
  PermissionsService.RequestPermissions(fAppPermissions,
    RequestPermissionsResultEvent);
  if TPlatformServices.Current.SupportsPlatformService(IFMXTakenImageService,
    Service) then
  begin
    Params.Editable := true;
    Params.RequiredResolution := TSize.Create(1920, 1080);
    Params.OnDidFinishTaking := DoDidFinishTakePhotoOnAndroid;
    Service.TakeImageFromLibrary(fmxMain.btnPhotoLib, Params);
  end else
    Toast(rsDeviceDoesNotSupportCam, LongToast);
end;

procedure TfraCameraCapture3.DoDidFinishTakePhotoOnAndroid(Image: TBitmap);
begin
  if assigned(fOnPhotoCaptured) then
    fOnPhotoCaptured(Image, GetFileName);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}
procedure TfraCameraCapture3.StartTakePhotoFromLibOnWindows;
var
  Bitmap: TBitmap;
begin
  OpenDialogPictures.Filter := TBitmapCodecManager.GetFilterString;
  if OpenDialogPictures.Execute then
  begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.LoadFromFile(OpenDialogPictures.FileName);
      if assigned(fOnPhotoCaptured) then
        fOnPhotoCaptured(Bitmap, ExtractFileName(OpenDialogPictures.FileName));
      OpenDialogPictures.InitialDir :=
        ExtractFilePath(OpenDialogPictures.FileName);
    finally
      Bitmap.Free;
    end;
  end;
end;

procedure TfraCameraCapture3.SaveImageToFileOnWindows(Img: TStream;
  const ContentType: string);
var
  Ext: string;
  FileStream: TFileStream;
begin
  Ext := TFirebaseHelpers.ContentTypeToFileExt(ContentType);
  SaveDialogPictures.DefaultExt := Ext;
  SaveDialogPictures.Filter := Format(rsImgFilter,
    [SaveDialogPictures.DefaultExt, SaveDialogPictures.DefaultExt]);
  if SaveDialogPictures.Execute then
  begin
    FileStream := TFileStream.Create(SaveDialogPictures.FileName, fmCreate);
    try
      FileStream.CopyFrom(Img);
    finally
      FileStream.Free;
    end;
  end;
end;
{$ENDIF}
{$ENDREGION}

end.
