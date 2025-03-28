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

unit Obj2DocTest;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.IOUtils, System.IniFiles,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Edit,
  FB4D.Interfaces,  FB4D.Firestore, FB4D.Document, FB4D.Helpers,
  FB4D.Configuration;

type
  TMyFirestoreDocument = class(TFirestoreDocument)
  private
    fMyPrivateFlag: boolean;
  public
    MyStringField: string;
    MyIntField: integer;
  end;

  TfmxObj2Doc = class(TForm)
    edtMyStringField: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    edtMyIntField: TEdit;
    btnWriteDoc: TButton;
    edtCollection: TEdit;
    edtDocId: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    edtProjectID: TEdit;
    btnCreateDB: TButton;
    btnReadDoc: TButton;
    chbSupressSaveDefVal: TCheckBox;
    GroupBox1: TGroupBox;
    chbEliminateFieldPrefixF: TCheckBox;
    chbSupressSavePrivateFields: TCheckBox;
    chbSupressSaveProtectedFields: TCheckBox;
    chbSupressSavePublicFields: TCheckBox;
    chbSupressSavePublishedFields: TCheckBox;
    chbMyPrivateFlag: TCheckBox;
    procedure btnCreateDBClick(Sender: TObject);
    procedure btnWriteDocClick(Sender: TObject);
    procedure btnReadDocClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    fDatabase: IFirestoreDatabase;
    function GetSettingFileName: string;
    function GetOptions: TOTDMapperOptions;
  end;

var
  fmxObj2Doc: TfmxObj2Doc;

implementation

{$R *.fmx}

procedure TfmxObj2Doc.FormCreate(Sender: TObject);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    edtProjectID.Text :=
      IniFile.ReadString('FBProjectSettings', 'ProjectID', '');
    chbSupressSaveDefVal.IsChecked :=
      IniFile.ReadBool('OTDMOpt', 'SuppressDelVal', true);
    chbSupressSavePrivateFields.IsChecked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSavePrivateFields', true);
    chbSupressSaveProtectedFields.IsChecked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSaveProtectedFields', false);
    chbSupressSavePublicFields.IsChecked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSavePublicFields', false);
    chbSupressSavePublishedFields.IsChecked :=
      IniFile.ReadBool('OTDMOpt', 'SupressSavePublishedFields', false);
    chbEliminateFieldPrefixF.IsChecked :=
      IniFile.ReadBool('OTDMOpt', 'EliminateFieldPrefixF', false);
  finally
    IniFile.Free;
  end;
  Caption := Caption + ' [' + TFirebaseConfiguration.GetLibVersionInfo + ']';
end;

procedure TfmxObj2Doc.FormClose(Sender: TObject; var Action: TCloseAction);
var
  IniFile: TIniFile;
begin
  IniFile := TIniFile.Create(GetSettingFilename);
  try
    IniFile.WriteString('FBProjectSettings', 'ProjectID', edtProjectID.Text);
    IniFile.WriteBool('OTDMOpt', 'SuppressDelVal',
      chbSupressSaveDefVal.IsChecked);
    IniFile.WriteBool('OTDMOpt', 'SupressSavePrivateFields',
      chbSupressSavePrivateFields.IsChecked);
    IniFile.WriteBool('OTDMOpt', 'SupressSaveProtectedFields',
      chbSupressSaveProtectedFields.IsChecked);
    IniFile.WriteBool('OTDMOpt', 'SupressSavePublicFields',
      chbSupressSavePublicFields.IsChecked);
    IniFile.WriteBool('OTDMOpt', 'SupressSavePublishedFields',
      chbSupressSavePublishedFields.IsChecked);
    IniFile.WriteBool('OTDMOpt', 'EliminateFieldPrefixF',
      chbEliminateFieldPrefixF.IsChecked);
  finally
    IniFile.Free;
  end;
end;

function TfmxObj2Doc.GetSettingFileName: string;
var
  FileName: string;
begin
  FileName := ChangeFileExt(ExtractFileName(ParamStr(0)), '.ini');
  result := TPath.Combine(TPath.GetHomePath, FileName);
end;

procedure TfmxObj2Doc.btnCreateDBClick(Sender: TObject);
begin
  fDatabase := TFirestoreDatabase.Create(edtProjectID.Text, nil);
  btnCreateDB.Enabled := false;
  btnReadDoc.Enabled := true;
  btnWriteDoc.Enabled := true;
end;

procedure TfmxObj2Doc.btnReadDocClick(Sender: TObject);
var
  Docs: IFirestoreDocuments;
  Obj: TMyFirestoreDocument;
begin
  Docs := fDatabase.GetSynchronous([edtCollection.Text, edtDocId.Text]);
  if Docs.Count = 1 then
  begin
    Obj := TMyFirestoreDocument.LoadObjectFromDocument(Docs.Document(0),
      GetOptions);
    try
      edtMyStringField.Text := Obj.MyStringField;
      edtMyIntField.Text := Obj.MyIntField.ToString;
      chbMyPrivateFlag.IsChecked := Obj.fMyPrivateFlag;
    finally
      Obj.Free;
    end;
  end;
end;

procedure TfmxObj2Doc.btnWriteDocClick(Sender: TObject);
var
  Doc: TMyFirestoreDocument;
begin
  Doc := TMyFirestoreDocument.Create([edtCollection.Text, edtDocId.Text], fDatabase);
  try
    Doc.fMyPrivateFlag := chbMyPrivateFlag.IsChecked;
    Doc.MyStringField := edtMyStringField.Text;
    Doc.MyIntField := StrToInt(edtMyIntField.Text);
    fDatabase.InsertOrUpdateDocumentSynchronous(
      Doc.SaveObjectToDocument(GetOptions));
  finally
    Doc.Free;
  end;
end;

function TfmxObj2Doc.GetOptions: TOTDMapperOptions;
begin
  result := [];
  if chbSupressSaveDefVal.IsChecked then
    result := result + [omSupressSaveDefVal];
  if chbSupressSavePrivateFields.IsChecked then
    result := result + [omSupressSavePrivateFields];
  if chbSupressSaveProtectedFields.IsChecked then
    result := result + [omSupressSaveProtectedFields];
  if chbSupressSavePublicFields.IsChecked then
    result := result + [omSupressSavePublicFields];
  if chbSupressSavePublishedFields.IsChecked then
    result := result + [omSupressSavePublishedFields];
  if chbEliminateFieldPrefixF.IsChecked then
    result := result + [omEliminateFieldPrefixF];
end;

end.
