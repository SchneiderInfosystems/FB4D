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

unit FB4D.FunctionsFra;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants, System.IniFiles, System.JSON,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ListBox, FMX.Edit, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation,
  FB4D.Interfaces;

type
  TFunctionsFra = class(TFrame)
    Label31: TLabel;
    memFunctionResp: TMemo;
    edtParam4: TEdit;
    Label38: TLabel;
    edtParam4Val: TEdit;
    Label39: TLabel;
    edtParam3: TEdit;
    Label36: TLabel;
    edtParam3Val: TEdit;
    Label37: TLabel;
    edtParam2: TEdit;
    Label34: TLabel;
    edtParam2Val: TEdit;
    Label35: TLabel;
    edtParam1: TEdit;
    Label32: TLabel;
    edtParam1Val: TEdit;
    Label33: TLabel;
    edtFunctionName: TEdit;
    lblFunctionName: TLabel;
    cboParams: TComboBox;
    btnCallFunctionSynchronous: TButton;
    btnCallFunctionAsynchronous: TButton;
    procedure btnCallFunctionSynchronousClick(Sender: TObject);
    procedure btnCallFunctionAsynchronousClick(Sender: TObject);
    procedure cboParamsChange(Sender: TObject);
  private
    fFirebaseFunction: IFirebaseFunctions;

    function CheckAndCreateFunctionClass: boolean;

    procedure OnFunctionSuccess(const Info: string; ResultObj: TJSONObject);
    procedure OnFunctionError(const RequestID, ErrMsg: string);
  public
    procedure LoadSettingsFromIniFile(IniFile: TIniFile);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
  end;

implementation

{$R *.fmx}

uses
  FB4D.Functions,
  FB4D.AuthFra, FB4D.DemoFmx;

{ TFunctionsFra }

{$REGION 'Class Handling'}

function TFunctionsFra.CheckAndCreateFunctionClass: boolean;
begin
  if assigned(fFirebaseFunction) then
    exit(true)
  else if not fmxFirebaseDemo.AuthFra.CheckSignedIn(memFunctionResp) then
    exit(false);
  fFirebaseFunction := TFirebaseFunctions.Create(
    fmxFirebaseDemo.edtProjectID.Text, fmxFirebaseDemo.AuthFra.Auth);
  fmxFirebaseDemo.edtProjectID.ReadOnly := true;
  fmxFirebaseDemo.rctProjectIDDisabled.Visible := true;
  result := true;
end;

{$ENDREGION}

{$REGION 'Settings'}

procedure TFunctionsFra.LoadSettingsFromIniFile(IniFile: TIniFile);
begin
  edtFunctionName.Text := IniFile.ReadString('Function', 'FuncName', '');
  cboParams.ItemIndex := IniFile.ReadInteger('Function', 'ParamCount', 0);
  edtParam1.Text := IniFile.ReadString('Function', 'Param1', '');
  edtParam1Val.Text := IniFile.ReadString('Function', 'Param1Val', '');
  edtParam2.Text := IniFile.ReadString('Function', 'Param2', '');
  edtParam2Val.Text := IniFile.ReadString('Function', 'Param2Val', '');
  edtParam3.Text := IniFile.ReadString('Function', 'Param3', '');
  edtParam3Val.Text := IniFile.ReadString('Function', 'Param3Val', '');
  edtParam4.Text := IniFile.ReadString('Function', 'Param4', '');
  edtParam4Val.Text := IniFile.ReadString('Function', 'Param4Val', '');
  cboParamsChange(nil);
end;

procedure TFunctionsFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('Function', 'FuncName', edtFunctionName.Text);
  IniFile.WriteInteger('Function', 'ParamCount', cboParams.ItemIndex);
  IniFile.WriteString('Function', 'Param1', edtParam1.Text);
  IniFile.WriteString('Function', 'Param1Val', edtParam1Val.Text);
  IniFile.WriteString('Function', 'Param2', edtParam2.Text);
  IniFile.WriteString('Function', 'Param2Val', edtParam2Val.Text);
  IniFile.WriteString('Function', 'Param3', edtParam3.Text);
  IniFile.WriteString('Function', 'Param3Val', edtParam3Val.Text);
  IniFile.WriteString('Function', 'Param4', edtParam4.Text);
  IniFile.WriteString('Function', 'Param4Val', edtParam4Val.Text);
end;

{$ENDREGION}

{$REGION 'Function Call'}

procedure TFunctionsFra.cboParamsChange(Sender: TObject);
begin
  edtParam1.Visible := cboParams.ItemIndex > 0;
  edtParam2.Visible := cboParams.ItemIndex > 1;
  edtParam3.Visible := cboParams.ItemIndex > 2;
  edtParam4.Visible := cboParams.ItemIndex > 3;
end;

procedure TFunctionsFra.btnCallFunctionSynchronousClick(Sender: TObject);
var
  Data, Res: TJSONObject;
begin
  if not CheckAndCreateFunctionClass then
    exit;
  memFunctionResp.Lines.Add('Call: ' + edtFunctionName.Text);
  try
    Data := TJSONObject.Create;
    if cboParams.ItemIndex > 0 then
    begin
      Data.AddPair(edtParam1.Text, edtParam1Val.Text);
      if cboParams.ItemIndex > 1 then
      begin
        Data.AddPair(edtParam2.Text, edtParam2Val.Text);
        if cboParams.ItemIndex > 2 then
        begin
          Data.AddPair(edtParam3.Text, edtParam3Val.Text);
          if cboParams.ItemIndex > 3 then
            Data.AddPair(edtParam4.Text, edtParam4Val.Text);
        end;
      end;
    end;
    Res := fFirebaseFunction.CallFunctionSynchronous(edtFunctionName.Text, Data);
    try
      memFunctionResp.Lines.Add('Result: ' + Res.ToJSON);
    finally
      Res.Free;
    end;
  except
    on e: exception do
      memFunctionResp.Lines.Add('Call ' + edtFunctionName.Text + ' failed: ' +
        e.Message);
  end;
end;


procedure TFunctionsFra.btnCallFunctionAsynchronousClick(Sender: TObject);
var
  Data: TJSONObject;
begin
  if not CheckAndCreateFunctionClass then
    exit;
  memFunctionResp.Lines.Add('Call: ' + edtFunctionName.Text);
  try
    Data := TJSONObject.Create;
    if cboParams.ItemIndex > 0 then
    begin
      Data.AddPair(edtParam1.Text, edtParam1Val.Text);
      if cboParams.ItemIndex > 1 then
      begin
        Data.AddPair(edtParam2.Text, edtParam2Val.Text);
        if cboParams.ItemIndex > 2 then
        begin
          Data.AddPair(edtParam3.Text, edtParam3Val.Text);
          if cboParams.ItemIndex > 3 then
            Data.AddPair(edtParam4.Text, edtParam4Val.Text);
        end;
      end;
    end;
    fFirebaseFunction.CallFunction(onFunctionSuccess, OnFunctionError,
      edtFunctionName.Text, Data);
  except
    on e: exception do
      memFunctionResp.Lines.Add('Call ' + edtFunctionName.Text +
        ' failed: ' + e.Message);
  end;
end;

procedure TFunctionsFra.OnFunctionSuccess(const Info: string;
  ResultObj: TJSONObject);
begin
  memFunctionResp.Lines.Add('Result of ' + Info + ': ' + ResultObj.ToJSON);
end;

procedure TFunctionsFra.OnFunctionError(const RequestID, ErrMsg: string);
begin
  memFunctionResp.Lines.Add('Call of ' + RequestID + ' failed: ' + ErrMsg);
end;

{$ENDREGION}

end.
