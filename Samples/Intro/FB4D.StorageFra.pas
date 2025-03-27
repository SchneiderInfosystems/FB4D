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

unit FB4D.StorageFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.IniFiles, System.StrUtils, System.JSON,
  System.Generics.Collections, System.ImageList,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Edit, FMX.Memo.Types,
  FMX.ScrollBox, FMX.Memo, FMX.Layouts, FMX.ListBox, FMX.EditBox, FMX.SpinBox,
  FMX.TabControl, FMX.ImgList, FMX.Menus,
  FB4D.Interfaces;

type
  TStorageFra = class(TFrame)
    edtStorageBucket: TEdit;
    rctBucketDisabled: TRectangle;
    memStorageResp: TMemo;
    btnUploadAsynch: TButton;
    btnUploadSynch: TButton;
    btnGetStorageAsynch: TButton;
    btnDownloadAsync: TButton;
    btnDeleteAsync: TButton;
    btnDeleteSync: TButton;
    btnDownloadSync: TButton;
    btnGetStorageSynch: TButton;
    edtStoragePath: TEdit;
    Label11: TLabel;
    edtStorageObject: TEdit;
    Label10: TLabel;
    Label9: TLabel;
    OpenDialog: TOpenDialog;
    SaveDialog: TSaveDialog;
    procedure btnGetStorageSynchClick(Sender: TObject);
    procedure btnGetStorageAsynchClick(Sender: TObject);
    procedure btnDownloadSyncClick(Sender: TObject);
    procedure btnDownloadAsyncClick(Sender: TObject);
    procedure btnUploadSynchClick(Sender: TObject);
    procedure btnUploadAsynchClick(Sender: TObject);
    procedure btnDeleteSyncClick(Sender: TObject);
    procedure btnDeleteAsyncClick(Sender: TObject);
  private
    fStorageObject: IStorageObject;
    fDownloadStream: TFileStream;
    fStorage: IFirebaseStorage;
    fUploadStream: TFileStream;
    function CheckAndCreateStorageClass: boolean;

    // Get Storage Object
    function GetStorageFileName: string;
    procedure ShowFirestoreObject(Obj: IStorageObject);
    procedure OnGetStorage(Obj: IStorageObject);
    procedure OnGetStorageError(const ObjectName, ErrMsg: string);

    // Download Storage Object
    procedure OnDownload(Obj: IStorageObject);
    procedure OnDownloadError(Obj: IStorageObject; const ErrorMsg: string);

    // Upload Storage Object
    procedure OnUpload(Obj: IStorageObject);
    procedure OnUploadError(const ObjectName, ErrorMsg: string);

    // Delete Storage Object
    procedure OnDeleteStorage(const ObjectName: TObjectName);
    procedure OnDeleteStorageError(const ObjectName, ErrorMsg: string);
  public
    procedure LoadSettingsFromIniFile(IniFile: TIniFile);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
  end;

implementation

uses
  REST.Types,
  FB4D.Storage, FB4D.Helpers,
  FB4D.DemoFmx;

{$R *.fmx}

{ TFraStorage }

{$REGION 'Class Handling'}

function TStorageFra.CheckAndCreateStorageClass: boolean;
begin
  if assigned(fStorage) then
    exit(true)
  else if edtStorageBucket.Text.IsEmpty then
  begin
    memStorageResp.Lines.Add('Please enter the Storage bucket first!');
    memStorageResp.GoToTextEnd;
    edtStorageBucket.SetFocus;
    exit(false);
  end;
  fStorage := TFirebaseStorage.Create(edtStorageBucket.Text,
    fmxFirebaseDemo.AuthFra.Auth);
  edtStorageBucket.ReadOnly := true;
  rctBucketDisabled.Visible := true;
  OpenDialog.Filter := TBitmapCodecManager.GetFilterString;
  result := true;
end;

{$ENDREGION}

{$REGION 'Settings'}

procedure TStorageFra.LoadSettingsFromIniFile(IniFile: TIniFile);
begin
  edtStorageBucket.Text := IniFile.ReadString('Storage', 'Bucket', '');
  edtStorageObject.Text := IniFile.ReadString('Storage', 'Object', '');
  edtStoragePath.Text := IniFile.ReadString('Storage', 'Path', '');
end;

procedure TStorageFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('Storage', 'Bucket', edtStorageBucket.Text);
  IniFile.WriteString('Storage', 'Object', edtStorageObject.Text);
  IniFile.WriteString('Storage', 'Path', edtStoragePath.Text);
end;

{$ENDREGION}

{$REGION 'Get Storage Object'}

procedure TStorageFra.btnGetStorageSynchClick(Sender: TObject);
begin
  if not CheckAndCreateStorageClass then
    exit;
  fStorageObject := fStorage.GetSynchronous(GetStorageFileName);
  memStorageResp.Lines.Text := 'Storage object synchronous retrieven';
  ShowFirestoreObject(fStorageObject);
  if assigned(fStorageObject) then
    btnDownloadSync.Enabled := fStorageObject.DownloadToken > ''
  else
    btnDownloadSync.Enabled := false;
  btnDownloadAsync.Enabled := btnDownloadSync.Enabled;
  btnDeleteSync.Enabled := btnDownloadSync.Enabled;
  btnDeleteAsync.Enabled := btnDeleteSync.Enabled;
end;

function TStorageFra.GetStorageFileName: string;
begin
  result := edtStoragePath.Text;
  if (result.Length > 0) and (result[High(result)] <> '/') then
    result := result + '/';
  result := result + edtStorageObject.Text;
end;

procedure TStorageFra.ShowFirestoreObject(Obj: IStorageObject);
var
  sizeInBytes: extended;
begin
  if assigned(Obj) then
  begin
    memStorageResp.Lines.Add('ObjectName: ' + Obj.ObjectName(false));
    memStorageResp.Lines.Add('Path: ' + Obj.Path);
    memStorageResp.Lines.Add('Type: ' + Obj.ContentType);
    sizeInBytes := Obj.Size;
    memStorageResp.Lines.Add('Size: ' + Format('%.0n bytes', [SizeInBytes]));
    memStorageResp.Lines.Add('Created: ' +
      DateTimeToStr(Obj.createTime));
    memStorageResp.Lines.Add('Updated: ' +
      DateTimeToStr(Obj.updateTime));
    memStorageResp.Lines.Add('Download URL: ' + Obj.DownloadUrl);
    memStorageResp.Lines.Add('Download Token: ' + Obj.DownloadToken);
    memStorageResp.Lines.Add('MD5 hash code: ' + Obj.MD5HashCode);
    memStorageResp.Lines.Add('E-Tag: ' + Obj.etag);
    memStorageResp.Lines.Add('Generation: ' + IntTostr(Obj.generation));
    memStorageResp.Lines.Add('StorageClass: ' + Obj.storageClass);
    memStorageResp.Lines.Add('Meta Generation: ' +
      IntTostr(Obj.metaGeneration));
  end else
    memStorageResp.Lines.Text := 'No Storage object';
end;

procedure TStorageFra.btnGetStorageAsynchClick(Sender: TObject);
begin
  if not CheckAndCreateStorageClass then
    exit;
  fStorage.Get(GetStorageFileName, OnGetStorage, OnGetStorageError);
end;

procedure TStorageFra.OnGetStorage(Obj: IStorageObject);
begin
  memStorageResp.Lines.Text := 'Storage object asynchronous retrieven';
  ShowFirestoreObject(Obj);
  if assigned(Obj) then
    btnDownloadSync.Enabled := Obj.DownloadToken > ''
  else
    btnDownloadSync.Enabled := false;
  btnDownloadAsync.Enabled := btnDownloadSync.Enabled;
  btnDeleteSync.Enabled := btnDownloadSync.Enabled;
  btnDeleteAsync.Enabled := btnDeleteSync.Enabled;
  fStorageObject := Obj;
end;

procedure TStorageFra.OnGetStorageError(const ObjectName, ErrMsg: string);
begin
  memStorageResp.Lines.Text := 'Error while asynchronous get for ' + ObjectName;
  memStorageResp.Lines.Add('Error: ' + ErrMsg);
end;

{$ENDREGION}

{$REGION 'Download Storage Object'}

procedure TStorageFra.btnDownloadSyncClick(Sender: TObject);
var
  Stream: TFileStream;
begin
  Assert(assigned(fStorageObject), 'Storage object is missing');
  SaveDialog.FileName := fStorageObject.ObjectName(false);
  if SaveDialog.Execute then
  begin
    Stream := TFileStream.Create(SaveDialog.FileName, fmCreate);
    try
      fStorageObject.DownloadToStreamSynchronous(Stream);
      memStorageResp.Lines.Add(fStorageObject.ObjectName(true) +
        ' downloaded to ' + SaveDialog.FileName);
    finally
      Stream.Free;
    end;
  end;
end;

procedure TStorageFra.btnDownloadAsyncClick(Sender: TObject);
begin
  Assert(assigned(fStorageObject), 'Storage object is missing');
  SaveDialog.FileName := fStorageObject.ObjectName(false);
  if SaveDialog.Execute then
  begin
    FreeAndNil(fDownloadStream);
    fDownloadStream := TFileStream.Create(SaveDialog.FileName, fmCreate);
    fStorageObject.DownloadToStream(fDownloadStream, OnDownload,
      OnDownloadError);
    memStorageResp.Lines.Add(fStorageObject.ObjectName(true) +
      ' download started');
  end;
end;

procedure TStorageFra.OnDownload(Obj: IStorageObject);
begin
  memStorageResp.Lines.Add(Obj.ObjectName(true) + ' downloaded to ' +
    SaveDialog.FileName + ' passed');
  FreeAndNil(fDownloadStream);
end;

procedure TStorageFra.OnDownloadError(Obj: IStorageObject;
  const ErrorMsg: string);
begin
  memStorageResp.Lines.Add(Obj.ObjectName(true) + ' downloaded to ' +
    SaveDialog.FileName + ' failed: ' + ErrorMsg);
  FreeAndNil(fDownloadStream);
end;

{$ENDREGION}

{$REGION 'Upload Storage Object'}

procedure TStorageFra.btnUploadSynchClick(Sender: TObject);
var
  fs: TFileStream;
  ExtType: string;
  ContentType: TRESTContentType;
  ObjectName: string;
  Obj: IStorageObject;
begin
  if not CheckAndCreateStorageClass then
    exit;
  if OpenDialog.Execute then
  begin
    ExtType := LowerCase(ExtractFileExt(OpenDialog.FileName).Substring(1));
    if (ExtType = 'jpg') or (ExtType = 'jpeg') then
      ContentType := TRESTContentType.ctIMAGE_JPEG
    else if ExtType = 'png' then
      ContentType := TRESTContentType.ctIMAGE_PNG
    else if ExtType = 'gif' then
      ContentType := TRESTContentType.ctIMAGE_GIF
    else if ExtType = 'tiff' then
      ContentType := TRESTContentType.ctIMAGE_TIFF
    else if ExtType = 'mp4' then
      ContentType := TRESTContentType.ctVIDEO_MP4
    else
      ContentType := TRESTContentType.ctNone;
    edtStorageObject.Text := ExtractFilename(OpenDialog.FileName);
    ObjectName := GetStorageFileName;
    fs := TFileStream.Create(OpenDialog.FileName, fmOpenRead);
    try
      Obj := fStorage.UploadSynchronousFromStream(fs, ObjectName, ContentType);
      memStorageResp.Lines.Text := 'Object synchronous uploaded';
      ShowFirestoreObject(Obj);
    finally
      fs.Free;
    end;
  end;
end;

procedure TStorageFra.btnUploadAsynchClick(Sender: TObject);
var
  ExtType: string;
  ContentType: TRESTContentType;
  ObjectName: string;
begin
  if not CheckAndCreateStorageClass then
    exit;
  if assigned(fUploadStream) then
  begin
    memStorageResp.Lines.Add('Wait until previous upload is finisehd');
    memStorageResp.GoToTextEnd;
  end;
  if OpenDialog.Execute then
  begin
    ExtType := LowerCase(ExtractFileExt(OpenDialog.FileName).Substring(1));
    if (ExtType = 'jpg') or (ExtType = 'jpeg') then
      ContentType := TRESTContentType.ctIMAGE_JPEG
    else if ExtType = 'png' then
      ContentType := TRESTContentType.ctIMAGE_PNG
    else if ExtType = 'gif' then
      ContentType := TRESTContentType.ctIMAGE_GIF
    else if ExtType = 'mp4' then
      ContentType := TRESTContentType.ctVIDEO_MP4
    else
      ContentType := TRESTContentType.ctNone;
    edtStorageObject.Text := ExtractFilename(OpenDialog.FileName);
    ObjectName := GetStorageFileName;
    fUploadStream := TFileStream.Create(OpenDialog.FileName, fmOpenRead);
    fStorage.UploadFromStream(fUploadStream, ObjectName, ContentType,
      OnUpload, OnUploadError);
  end;
end;

procedure TStorageFra.OnUpload(Obj: IStorageObject);
begin
  memStorageResp.Lines.Text := 'Object asynchronous uploaded: ' +
    Obj.ObjectName(true);
  ShowFirestoreObject(Obj);
  FreeAndNil(fUploadStream);
end;

procedure TStorageFra.OnUploadError(const ObjectName, ErrorMsg: string);
begin
  memStorageResp.Lines.Text := 'Error while asynchronous upload of ' +
    ObjectName;
  memStorageResp.Lines.Add('Error: ' + ErrorMsg);
  FreeAndNil(fUploadStream);
end;

{$ENDREGION}

{$REGION 'Delete Storage Object'}

procedure TStorageFra.btnDeleteSyncClick(Sender: TObject);
begin
  if not CheckAndCreateStorageClass then
    exit;
  fStorage.DeleteSynchronous(GetStorageFileName);
  memStorageResp.Lines.Text := GetStorageFileName + ' synchronous deleted';
  btnDownloadSync.Enabled := false;
  btnDownloadAsync.Enabled :=  false;
  btnDeleteSync.Enabled := false;
  btnDeleteAsync.Enabled := false;
end;

procedure TStorageFra.btnDeleteAsyncClick(Sender: TObject);
begin
  if not CheckAndCreateStorageClass then
    exit;
  fStorage.Delete(GetStorageFileName, OnDeleteStorage, OnDeleteStorageError);
end;

procedure TStorageFra.OnDeleteStorage(const ObjectName: TObjectName);
begin
  memStorageResp.Lines.Text := ObjectName + ' asynchronous deleted';
  btnDownloadSync.Enabled := false;
  btnDownloadAsync.Enabled :=  false;
  btnDeleteSync.Enabled := false;
  btnDeleteAsync.Enabled := false;
end;

procedure TStorageFra.OnDeleteStorageError(const ObjectName,
  ErrorMsg: string);
begin
  memStorageResp.Lines.Text := 'Error while asynchronous delete of ' + ObjectName;
  memStorageResp.Lines.Add('Error: ' + ErrorMsg);
end;

{$ENDREGION}

end.
