unit PhotoBoxMainFmx1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.TabControl, FMX.StdCtrls, FMX.Objects,
  FMX.Edit, FMX.Layouts, FMX.Media, FMX.ListBox, FMX.ExtCtrls,
  FB4D.Interfaces, FB4D.Configuration,
  CameraCaptureFra1, PhotoThreads1;

type
  TfmxMain = class(TForm)
    TabControl: TTabControl;
    tabRegister: TTabItem;
    tabBox: TTabItem;
    layFBConfig: TLayout;
    edtKey: TEdit;
    Text2: TText;
    edtProjectID: TEdit;
    Text3: TText;
    lblVersionInfo: TLabel;
    tabCaptureImg: TTabItem;
    layToolbar: TLayout;
    lstPhotoList: TListBox;
    btnCaptureImg: TButton;
    fraCameraCapture: TfraCameraCapture1;
    btnPhotoLib: TButton;
    sptPreview: TSplitter;
    StatusBar: TStatusBar;
    lblStatus: TLabel;
    btnStart: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnCaptureImgClick(Sender: TObject);
    procedure btnPhotoLibClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    fConfig: IFirebaseConfiguration;
    function GetSettingFilename: string;
    procedure SaveSettings;
    procedure OnPhotoCaptured(Image: TBitmap; const FileName: string);
    procedure OnChangedColDocument(Document: IFirestoreDocument);
    procedure OnDeletedColDocument(const DeleteDocumentPath: string;
      TimeStamp: TDateTime);
    procedure OnListenerError(const RequestID, ErrMsg: string);
    procedure OnStopListening(Sender: TObject);
    procedure OnUploaded(Item: TListBoxItem);
    procedure OnUploadFailed(Item: TListBoxItem; const Msg: string);
    procedure OnDownloaded(Item: TListBoxItem);
    procedure OnDownloadFailed(Item: TListBoxItem; const Msg: string);
  public
    procedure WipeToTab(ActiveTab: TTabItem);
  end;

var
  fmxMain: TfmxMain;

implementation

{$R *.fmx}

uses
  System.IniFiles, System.IOUtils,
  FB4D.Helpers, FB4D.Firestore;

resourcestring
  rsListenerError = 'Database listener error: %s (%s)';
  rsListenerStopped = 'Database listener stopped';
  rsUploaded = ' uploaded';
  rsUploadFailed = ' upload failed: ';
  rsDownloaded = ' downloaded';
  rsDownloadFailed = ' download failed: ';

{$REGION 'Form Handling'}
procedure TfmxMain.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtKey.Text := IniFile.ReadString('FBProjectSettings', 'APIKey', '');
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    fraCameraCapture.InitialDir := IniFile.ReadString('Path', 'ImageLib',
      TPath.GetPicturesPath);
  finally
    IniFile.Free;
  end;
  TabControl.ActiveTab := tabRegister;
  {$IFDEF ANDROID}
  btnPhotoLib.StyleLookup := 'organizetoolbutton';
  {$ENDIF}
  if edtProjectID.Text.IsEmpty then
    edtProjectID.SetFocus;
end;

procedure TfmxMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
end;

function TfmxMain.GetSettingFilename: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '');
  result := IncludeTrailingPathDelimiter(TPath.GetHomePath) +
    FileName + TFirebaseHelpers.GetPlatform + '.ini';
end;

procedure TfmxMain.SaveSettings;
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'APIKey', edtKey.Text);
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteString('Path', 'ImageLib', fraCameraCapture.InitialDir);
  finally
    IniFile.Free;
  end;
end;

procedure TfmxMain.WipeToTab(ActiveTab: TTabItem);
var
  c: integer;
begin
  if TabControl.ActiveTab <> ActiveTab then
  begin
    ActiveTab.Visible := true;
{$IFDEF ANDROID}
    TabControl.ActiveTab := ActiveTab;
{$ELSE}
    TabControl.GotoVisibleTab(ActiveTab.Index, TTabTransition.Slide,
      TTabTransitionDirection.Normal);
{$ENDIF}
    for c := 0 to TabControl.TabCount - 1 do
      TabControl.Tabs[c].Visible := TabControl.Tabs[c] = ActiveTab;
  end;
end;
{$ENDREGION}

{$REGION 'User Login'}
procedure TfmxMain.btnStartClick(Sender: TObject);
var
  Query: IStructuredQuery;
begin
  fConfig := TFirebaseConfiguration.Create(edtKey.Text, edtProjectID.Text);
  layFBConfig.Visible := false;
  Query := TStructuredQuery.CreateForCollection(TPhotoThread.cCollectionID);
  fConfig.Database.SubscribeQuery(Query, OnChangedColDocument,
    OnDeletedColDocument);
  fConfig.Database.StartListener(OnStopListening, OnListenerError);
  WipeToTab(tabBox);
end;
{$ENDREGION}

procedure TfmxMain.btnCaptureImgClick(Sender: TObject);
begin
  fraCameraCapture.StartCapture(OnPhotoCaptured);
end;

procedure TfmxMain.btnPhotoLibClick(Sender: TObject);
begin
  fraCameraCapture.StartTakePhotoFromLib(OnPhotoCaptured);
end;

procedure TfmxMain.OnPhotoCaptured(Image: TBitmap; const FileName: string);
var
  Item: TListBoxItem;
  Upload: TPhotoThread;
  Thumbnail: TBitmap;
begin
  if TabControl.ActiveTab <> tabBox then
    WipeToTab(tabBox);
  Item := TListBoxItem.Create(lstPhotoList);
  Item.Text := FileName;
  Thumbnail := TPhotoThread.CreateThumbnail(Image);
  try
    Item.ItemData.Bitmap.Assign(Thumbnail);
  finally
    Thumbnail.Free;
  end;
  lstPhotoList.AddObject(Item);
  lstPhotoList.ItemIndex := Item.Index;
  Upload := TPhotoThread.CreateForUpload(fConfig, Image, Item);
  Upload.StartThread(OnUploaded, OnUploadFailed);
end;

procedure TfmxMain.OnUploaded(Item: TListBoxItem);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsUploaded);
end;

procedure TfmxMain.OnUploadFailed(Item: TListBoxItem; const Msg: string);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsUploadFailed + Msg);
end;

procedure TfmxMain.OnDownloaded(Item: TListBoxItem);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsDownloaded);
end;

procedure TfmxMain.OnDownloadFailed(Item: TListBoxItem; const Msg: string);
begin
  fraCameraCapture.ToastMsg(Item.Text + ' ' + rsDownloadFailed + Msg);
end;

procedure TfmxMain.OnChangedColDocument(Document: IFirestoreDocument);
var
  Download: TPhotoThread;
begin
  Download := TPhotoThread.CreateForDownload(fConfig, lstPhotoList, Document);
  Download.StartThread(OnDownloaded, OnDownloadFailed);
end;

procedure TfmxMain.OnDeletedColDocument(const DeleteDocumentPath: string;
  TimeStamp: TDateTime);
begin
  // Todo
end;

procedure TfmxMain.OnListenerError(const RequestID, ErrMsg: string);
begin
  if not Application.Terminated then
    fraCameraCapture.ToastMsg(Format(rsListenerError, [ErrMsg, RequestID]));
end;

procedure TfmxMain.OnStopListening(Sender: TObject);
begin
  if not Application.Terminated then
    fraCameraCapture.ToastMsg(rsListenerStopped);
end;

end.
