{******************************************************************************}
{                                                                              }
{  Delphi FB4D Library                                                         }
{  Copyright (c) 2018-2024 Christoph Schneider                                 }
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

unit FB4D.RTDBFra;

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
  TRTDBFra = class(TFrame)
    edtFirebaseURL: TEdit;
    txtFirebaseURL: TText;
    edtPath: TEdit;
    Label3: TLabel;
    TabControlRTDB: TTabControl;
    tabGet: TTabItem;
    btnGetRT: TButton;
    btnGetRTSynch: TButton;
    Label13: TLabel;
    aniGetRT: TAniIndicator;
    Label14: TLabel;
    edtColumnName: TEdit;
    cboOrderBy: TComboBox;
    Label15: TLabel;
    spbLimitToFirst: TSpinBox;
    Label16: TLabel;
    spbLimitToLast: TSpinBox;
    Label17: TLabel;
    edtColumnValue: TEdit;
    lblEqualTo: TLabel;
    tabPut: TTabItem;
    btnPutRTSynch: TButton;
    edtPutKeyName: TEdit;
    Label8: TLabel;
    edtPutKeyValue: TEdit;
    Label12: TLabel;
    lstDBNode: TListBox;
    btnAddUpdateNode: TButton;
    btnClearNode: TButton;
    btnPutRTAsynch: TButton;
    aniPutRT: TAniIndicator;
    Label18: TLabel;
    tabPatch: TTabItem;
    btnPatchRTSynch: TButton;
    Label19: TLabel;
    edtPatchKeyName: TEdit;
    Label20: TLabel;
    edtPatchKeyValue: TEdit;
    Label21: TLabel;
    btnPatchRTAsynch: TButton;
    aniPatchRT: TAniIndicator;
    tabPost: TTabItem;
    btnPostRTSynch: TButton;
    Label22: TLabel;
    edtPostKeyName: TEdit;
    Label23: TLabel;
    edtPostKeyValue: TEdit;
    Label24: TLabel;
    aniPostRT: TAniIndicator;
    btnPostRTAsynch: TButton;
    tabDelete: TTabItem;
    btnDelRTSynch: TButton;
    Label25: TLabel;
    btnDelRTAsynch: TButton;
    aniDeleteRT: TAniIndicator;
    tabServerVars: TTabItem;
    btnGetServerTimeStamp: TButton;
    memRTDB: TMemo;
    rctFBURLDisabled: TRectangle;
    tabListener: TTabItem;
    btnNotifyEvent: TButton;
    lstRunningListener: TListBox;
    popRTDBLog: TPopupMenu;
    mniClear: TMenuItem;
    btnStopListener: TButton;
    imlTabStatus: TImageList;
    procedure cboOrderByChange(Sender: TObject);
    procedure spbLimitToFirstChange(Sender: TObject);
    procedure spbLimitToLastChange(Sender: TObject);
    procedure btnGetRTSynchClick(Sender: TObject);
    procedure btnGetRTClick(Sender: TObject);
    procedure btnAddUpdateNodeClick(Sender: TObject);
    procedure btnClearNodeClick(Sender: TObject);
    procedure btnPutRTSynchClick(Sender: TObject);
    procedure btnPutRTAsynchClick(Sender: TObject);
    procedure btnPostRTSynchClick(Sender: TObject);
    procedure btnPostRTAsynchClick(Sender: TObject);
    procedure btnPatchRTSynchClick(Sender: TObject);
    procedure btnPatchRTAsynchClick(Sender: TObject);
    procedure btnDelRTSynchClick(Sender: TObject);
    procedure btnDelRTAsynchClick(Sender: TObject);
    procedure btnGetServerTimeStampClick(Sender: TObject);
    procedure btnNotifyEventClick(Sender: TObject);
    procedure mniClearClick(Sender: TObject);
    procedure lstRunningListenerChange(Sender: TObject);
    procedure btnStopListenerClick(Sender: TObject);
  private
    fRealTimeDB: IRealTimeDB;
    fFirebaseEvents: TDictionary<string {DBPath}, IFirebaseEvent>;
    function GetRTDBPath: TStringDynArray;
    function GetPathFromResParams(ResParams: TRequestResourceParam): string;
    function GetOptions: TQueryParams;
    procedure ShowRTNode(ResourceParams: TRequestResourceParam;
      Val: TJSONValue);
    // Async Get
    procedure OnGetError(const RequestID, ErrMsg: string);
    procedure OnGetResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    // Asynch Put
    procedure OnPutResp(ResourceParams: TRequestResourceParam; Val: TJSONValue);
    procedure OnPutError(const RequestID, ErrMsg: string);
    // Asynch Patch
    procedure OnPatchError(const RequestID, ErrMsg: string);
    procedure OnPatchResp(ResourceParams: TRequestResourceParam;
      Val: TJSONValue);
    // Asynch Post
    procedure OnPostError(const RequestID, ErrMsg: string);
    procedure OnPostResp(ResourceParams: TRequestResourceParam;
      Val: TJSONValue);
    // Aynch Delete
    procedure OnDeleteError(const RequestID, ErrMsg: string);
    procedure OnDeleteResp(Params: TRequestResourceParam; Success: boolean);
    // Listener
    procedure OnRecData(const Event: string; Params: TRequestResourceParam;
      JSONObj: TJSONObject);
    procedure OnRecDataError(const Info, ErrMsg: string);
    procedure OnRecDataStop(const RequestID: string);
  public
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure LoadSettingsFromIniFile(IniFile: TIniFile;
      const ProjectID: string);
    procedure SaveSettingsIntoIniFile(IniFile: TIniFile);
    function CheckAndCreateRealTimeDBClass: boolean;
    function GetDatabase: string;
    procedure StopAllListener;

    property RealTimeDB: IRealTimeDB read fRealTimeDB;
  end;

implementation

uses
  FB4D.RealTimeDB, FB4D.Helpers,
  FB4D.DemoFmx;

{$R *.fmx}

resourcestring
  rsHintToDBRules = 'For first steps setup the Realtime Database Rules to '#13 +
    '{'#13'  "rules": {'#13'     ".read": "auth != null",'#13'     ".write": ' +
    '"auth != null"'#13'  }'#13'}';

const
  sUnauthorized = 'Unauthorized';

{ TRTDBFra }

{$REGION 'Class Handling'}

procedure TRTDBFra.AfterConstruction;
begin
  inherited;
  fFirebaseEvents := TDictionary<string {DBPath}, IFirebaseEvent>.Create;
end;

destructor TRTDBFra.Destroy;
begin
  fFirebaseEvents.Free;
  inherited;
end;

function TRTDBFra.CheckAndCreateRealTimeDBClass: boolean;
begin
  if edtFirebaseURL.Text.IsEmpty then
  begin
    memRTDB.Lines.Add('Please enter your Firebase URL first');
    memRTDB.GoToTextEnd;
    edtFirebaseURL.SetFocus;
    exit(false);
  end;
  if not assigned(fRealTimeDB) then
  begin
    fRealTimeDB := TRealTimeDB.CreateByURL(edtFirebaseURL.Text,
      fmxFirebaseDemo.AuthFra.Auth);
    edtFirebaseURL.ReadOnly := true;
    rctFBURLDisabled.Visible := true;
  end;
  result := true;
end;

{$ENDREGION}

{$REGION 'Settings'}
procedure TRTDBFra.LoadSettingsFromIniFile(IniFile: TIniFile;
  const ProjectID: string);
begin
  if not ProjectID.IsEmpty then
   // Downward compatibility for databases created before 2021
    edtFirebaseURL.Text := IniFile.ReadString('RTDB', 'FirebaseURL',
      Format(GOOGLE_FIREBASE, [ProjectID]))
  else
    edtFirebaseURL.Text := IniFile.ReadString('RTDB', 'FirebaseURL', '');
  edtPath.Text := IniFile.ReadString('RTDB', 'DBPath', 'TestNode');
end;

procedure TRTDBFra.SaveSettingsIntoIniFile(IniFile: TIniFile);
begin
  IniFile.WriteString('RTDB', 'FirebaseURL', edtFirebaseURL.Text);
  IniFile.WriteString('RTDB', 'DBPath', edtPath.Text);
end;

{$ENDREGION}

{$REGION 'Misc Getters'}
function TRTDBFra.GetRTDBPath: TStringDynArray;
begin
  result := SplitString(edtPath.Text.Replace('\', '/'), '/');
end;

function TRTDBFra.GetDatabase: string;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit('');
  result := fRealTimeDB.GetDatabaseID;
end;

function TRTDBFra.GetPathFromResParams(ResParams: TRequestResourceParam): string;
var
  i: integer;
begin
  result := '';
  for i := low(ResParams) to high(ResParams) do
    if i = low(ResParams) then
      result := ResParams[i]
    else
      result := result + '/' + ResParams[i];
end;

function TRTDBFra.GetOptions: TQueryParams;
begin
  result := nil;
  if (cboOrderBy.ItemIndex = 1) and (not edtColumnName.Text.IsEmpty) then
    result := TQueryParams.CreateQueryParams.AddOrderBy(edtColumnName.Text)
  else if (cboOrderBy.ItemIndex = 2) and (not edtColumnName.Text.IsEmpty) and
          (not edtColumnValue.Text.IsEmpty) then
    result := TQueryParams.CreateQueryParams.AddOrderByAndEqualTo(
      edtColumnName.Text, edtColumnValue.Text)
  else if cboOrderBy.ItemIndex > 2 then
    result := TQueryParams.CreateQueryParams.AddOrderByType(
      cboOrderBy.Items[cboOrderBy.ItemIndex]);
  if spbLimitToFirst.Value > 0 then
    result := TQueryParams.CreateQueryParams(result).
      AddLimitToFirst(trunc(spbLimitToFirst.Value));
  if spbLimitToLast.Value > 0 then
    result := TQueryParams.CreateQueryParams(result).
      AddLimitToLast(trunc(spbLimitToLast.Value));
end;

{$ENDREGION}

{$REGION 'Get from Realtime DB'}

procedure TRTDBFra.ShowRTNode(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
var
  Obj: TJSONObject;
  c: integer;
begin
  try
    if Val is TJSONObject then
    begin
      Obj := Val as TJSONObject;
      for c := 0 to Obj.Count - 1 do
      begin
        if Obj.Pairs[c].JsonValue is TJSONString then
          memRTDB.Lines.Add(Obj.Pairs[c].JsonString.Value + ': ' +
            Obj.Pairs[c].JsonValue.ToString)
        else
          memRTDB.Lines.Add(Obj.Pairs[c].JsonString.Value + ': ' +
            Obj.Pairs[c].JsonValue.ToJSON);
      end;
    end
    else if not(Val is TJSONNull) then
      memRTDB.Lines.Add(Val.ToString)
    else
      memRTDB.Lines.Add(Format('Path "%s" not found or invalid Firebase URL',
        [GetPathFromResParams(ResourceParams)]));
  except
    on e: exception do
      memRTDB.Lines.Add('Show RT Node failed: ' + e.Message);
  end
end;

procedure TRTDBFra.cboOrderByChange(Sender: TObject);
begin
  edtColumnName.Visible := cboOrderBy.ItemIndex in [1, 2];
  edtColumnValue.Visible := cboOrderBy.ItemIndex = 2;
  lblEqualTo.Visible := cboOrderBy.ItemIndex = 2;
end;

procedure TRTDBFra.spbLimitToFirstChange(Sender: TObject);
begin
  spbLimitToLast.Value := 0;
end;

procedure TRTDBFra.spbLimitToLastChange(Sender: TObject);
begin
  spbLimitToFirst.Value := 0;
end;

procedure TRTDBFra.btnGetRTSynchClick(Sender: TObject);
var
  Val: TJSONValue;
  Query: TQueryParams;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  try
    Query := GetOptions;
    try
      Val := fRealTimeDB.GetSynchronous(GetRTDBPath, Query);
      try
        ShowRTNode(GetRTDBPath, Val);
      finally
        Val.Free;
      end;
    finally
      Query.Free;
    end;
  except
    on e: exception do
      memRTDB.Lines.Add('Get ' + GetPathFromResParams(GetRTDBPath) +
        ' failed: ' + e.Message);
  end;
end;

procedure TRTDBFra.btnGetRTClick(Sender: TObject);
var
  Query: TQueryParams;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  Query := GetOptions;
  try
    fRealTimeDB.Get(GetRTDBPath, OnGetResp, OnGetError, Query);
  finally
    Query.Free;
  end;
  aniGetRT.Enabled := true;
  aniGetRT.Visible := true;
end;

procedure TRTDBFra.OnGetResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniGetRT.Visible := false;
  aniGetRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TRTDBFra.OnGetError(const RequestID, ErrMsg: string);
begin
  aniGetRT.Enabled := false;
  aniGetRT.Visible := false;
  memRTDB.Lines.Add('Get ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(rsHintToDBRules);
end;

{$ENDREGION}

{$REGION 'Put to Realtime DB'}

procedure TRTDBFra.btnAddUpdateNodeClick(Sender: TObject);
begin
  if edtPutKeyName.Text.IsEmpty then
    edtPutKeyName.SetFocus
  else if edtPutKeyValue.Text.IsEmpty then
    edtPutKeyValue.SetFocus
  else begin
    if lstDBNode.Items.IndexOfName(edtPutKeyName.Text) < 0 then
      lstDBNode.Items.AddPair(edtPutKeyName.Text, edtPutKeyValue.Text)
    else
      lstDBNode.Items.Values[edtPutKeyName.Text] := edtPutKeyValue.Text;
  end;
end;

procedure TRTDBFra.btnClearNodeClick(Sender: TObject);
begin
  lstDBNode.Clear;
end;

procedure TRTDBFra.btnPutRTSynchClick(Sender: TObject);
var
  Data: TJSONObject;
  Val: TJSONValue;
  c: integer;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  if lstDBNode.Items.Count = 0 then
  begin
    memRTDB.Lines.Add('Add first elements to the node');
    exit;
  end;
  Data := TJSONObject.Create;
  Val := nil;
  try
    for c := 0 to lstDBNode.Items.Count - 1 do
      Data.AddPair(lstDBNode.Items.Names[c], lstDBNode.Items.ValueFromIndex[c]);
    try
      Val := fRealTimeDB.PutSynchronous(GetRTDBPath, Data);
      ShowRTNode(GetRTDBPath, Val);
    except
      on e: exception do
        memRTDB.Lines.Add('Put ' + GetPathFromResParams(GetRTDBPath) +
          ' failed: ' + e.Message);
    end;
  finally
    Val.Free;
    Data.Free;
  end;
end;

procedure TRTDBFra.btnPutRTAsynchClick(Sender: TObject);
var
  Data: TJSONObject;
  c: integer;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  if lstDBNode.Items.Count = 0 then
  begin
    memRTDB.Lines.Add('Add first elements to the node');
    exit;
  end;
  Data := TJSONObject.Create;
  try
    for c := 0 to lstDBNode.Items.Count - 1 do
      Data.AddPair(lstDBNode.Items.Names[c], lstDBNode.Items.ValueFromIndex[c]);
    fRealTimeDB.Put(GetRTDBPath, Data, OnPutResp, OnPutError);
  finally
    Data.Free;
  end;
  aniPutRT.Enabled := true;
  aniPutRT.Visible := true;
end;

procedure TRTDBFra.OnPutResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniPutRT.Visible := false;
  aniPutRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TRTDBFra.OnPutError(const RequestID, ErrMsg: string);
begin
  aniPutRT.Visible := false;
  aniPutRT.Enabled := false;
  memRTDB.Lines.Add('Put ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(rsHintToDBRules);
end;

{$ENDREGION}

{$REGION 'Patch to Realtime DB'}

procedure TRTDBFra.btnPatchRTSynchClick(Sender: TObject);
var
  Data: TJSONObject;
  Val: TJSONValue;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  Data := TJSONObject.Create;
  Val := nil;
  try
    Data.AddPair(edtPatchKeyName.Text, edtPatchKeyValue.Text);
    try
      Val := fRealTimeDB.PatchSynchronous(GetRTDBPath, Data);
      ShowRTNode(GetRTDBPath, Val);
    except
      on e: exception do
        memRTDB.Lines.Add('Post ' + GetPathFromResParams(GetRTDBPath) +
          ' failed: ' + e.Message);
    end;
  finally
    Val.Free;
    Data.Free;
  end;
end;

procedure TRTDBFra.btnPatchRTAsynchClick(Sender: TObject);
var
  Data: TJSONObject;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  Data := TJSONObject.Create;
  try
    Data.AddPair(edtPatchKeyName.Text, edtPatchKeyValue.Text);
    fRealTimeDB.Patch(GetRTDBPath, Data, OnPatchResp, OnPatchError);
  finally
    Data.Free;
  end;
  aniPatchRT.Enabled := true;
  aniPatchRT.Visible := true;
end;

procedure TRTDBFra.OnPatchResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniPatchRT.Visible := false;
  aniPatchRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TRTDBFra.OnPatchError(const RequestID, ErrMsg: string);
begin
  aniPatchRT.Visible := false;
  aniPatchRT.Enabled := false;
  memRTDB.Lines.Add('Patch ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(rsHintToDBRules);
end;

{$ENDREGION}

{$REGION 'Post to Realtime DB'}

procedure TRTDBFra.btnPostRTSynchClick(Sender: TObject);
var
  Data: TJSONValue;
  Val: TJSONValue;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  Val := nil;
  if edtPostKeyName.Text.IsEmpty then
    Data := TJSONString.Create(edtPostKeyValue.Text)
  else
    Data := TJSONObject.Create(TJSONPair.Create(
      edtPostKeyName.Text, edtPostKeyValue.Text));
  try
    try
      Val := fRealTimeDB.PostSynchronous(GetRTDBPath, Data);
      ShowRTNode(GetRTDBPath, Val);
    except
      on e: exception do
        memRTDB.Lines.Add('Post ' + GetPathFromResParams(GetRTDBPath) +
          ' failed: ' + e.Message);
    end;
  finally
    Val.Free;
    Data.Free;
  end;
end;

procedure TRTDBFra.btnPostRTAsynchClick(Sender: TObject);
var
  Data: TJSONValue;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  if edtPostKeyName.Text.IsEmpty then
    Data := TJSONString.Create(edtPostKeyValue.Text)
  else
    Data := TJSONObject.Create(TJSONPair.Create(
      edtPostKeyName.Text, edtPostKeyValue.Text));
  try
    fRealTimeDB.Post(GetRTDBPath, Data, OnPostResp, OnPostError);
  finally
    Data.Free;
  end;
  aniPostRT.Enabled := true;
  aniPostRT.Visible := true;
end;

procedure TRTDBFra.OnPostResp(ResourceParams: TRequestResourceParam;
  Val: TJSONValue);
begin
  aniPostRT.Visible := false;
  aniPostRT.Enabled := false;
  ShowRTNode(ResourceParams, Val);
end;

procedure TRTDBFra.OnPostError(const RequestID, ErrMsg: string);
begin
  aniPostRT.Visible := false;
  aniPostRT.Enabled := false;
  memRTDB.Lines.Add('Post ' + RequestID + ' failed: ' + ErrMsg);
  if SameText(ErrMsg, sUnauthorized) then
    memRTDB.Lines.Add(rsHintToDBRules);
end;

{$ENDREGION}

{$REGION 'Delete from Realtime DB'}

procedure TRTDBFra.btnDelRTSynchClick(Sender: TObject);
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  try
    if fRealTimeDB.DeleteSynchronous(GetRTDBPath) then
      memRTDB.Lines.Add('Delete ' +
        GetPathFromResParams(GetRTDBPath) +
        ' passed')
    else
      memRTDB.Lines.Add('Path ' +
        GetPathFromResParams(GetRTDBPath) +
        ' not found');
  except
    on e: exception do
      memRTDB.Lines.Add('Delete ' + GetPathFromResParams(GetRTDBPath) +
        ' failed: ' + e.Message);
  end;
end;

procedure TRTDBFra.btnDelRTAsynchClick(Sender: TObject);
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  fRealTimeDB.Delete(GetRTDBPath, OnDeleteResp, OnDeleteError);
  aniDeleteRT.Enabled := true;
  aniDeleteRT.Visible := true;
end;

procedure TRTDBFra.OnDeleteResp(Params: TRequestResourceParam;
  Success: boolean);
begin
  aniDeleteRT.Enabled := false;
  aniDeleteRT.Visible := false;
  if Success then
    memRTDB.Lines.Add('Delete ' + GetPathFromResParams(GetRTDBPath) + ' passed')
  else
    memRTDB.Lines.Add('Path ' + GetPathFromResParams(GetRTDBPath) +
      ' not found');
end;

procedure TRTDBFra.OnDeleteError(const RequestID, ErrMsg: string);
begin
  aniDeleteRT.Enabled := false;
  aniDeleteRT.Visible := false;
  memRTDB.Lines.Add('Delete ' + RequestID + ' failed: ' + ErrMsg);
end;

{$ENDREGION}

{$REGION 'Listener for Realtime DB'}

procedure TRTDBFra.btnNotifyEventClick(Sender: TObject);
var
  Path: string;
  FirebaseEvent: IFirebaseEvent;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  Path := edtPath.Text.Replace('\', '/');
  lstRunningListener.ItemIndex := lstRunningListener.Items.IndexOf(Path);
  if lstRunningListener.ItemIndex >= 0 then
    memRTDB.Lines.Add('Listener for "' + Path + '" is already running')
  else begin
    FirebaseEvent := fRealTimeDB.ListenForValueEvents(SplitString(Path, '/'),
      OnRecData, OnRecDataStop, OnRecDataError);
    if assigned(FirebaseEvent) then
    begin
      memRTDB.Lines.Add(TimeToStr(now) + ': Event handler started for ' +
        TFirebaseHelpers.ArrStrToCommaStr(FirebaseEvent.GetResourceParams));
      lstRunningListener.Items.Add(Path);
      fFirebaseEvents.Add(Path, FirebaseEvent);
      tabListener.ImageIndex := 1;
    end else
      memRTDB.Lines.Add(TimeToStr(now) + ': Event handler start failed');
  end;
end;

procedure TRTDBFra.OnRecData(const Event: string;
  Params: TRequestResourceParam; JSONObj: TJSONObject);
var
  par, p: string;
begin
  par := '[';
  for p in Params do
  begin
    if par.Length > 1 then
      par := par + ', ' + p
    else
      par := par + p;
  end;
  memRTDB.Lines.Add(TimeToStr(now) + ': ' + Event + par + '] = ' +
    JSONObj.ToJSON);
end;

procedure TRTDBFra.OnRecDataError(const Info, ErrMsg: string);
begin
  memRTDB.Lines.Add(TimeToStr(now) + ': Error in ' + Info + ': ' + ErrMsg);
end;

procedure TRTDBFra.OnRecDataStop(const RequestID: string);
var
  Ind: integer;
begin
  memRTDB.Lines.Add(TimeToStr(now) + ': Event handler for ' + RequestID +
    ' stopped');
  tabListener.ImageIndex := 0;
  Ind := lstRunningListener.Items.IndexOf(RequestID);
  if Ind >= 0 then
    lstRunningListener.Items.Delete(Ind)
  else
    memRTDB.Lines.Add('Running listener not found: ' + RequestID);
  if fFirebaseEvents.ContainsKey(RequestID) then
    fFirebaseEvents.Remove(RequestID)
  else
    memRTDB.Lines.Add('Event not found: ' + RequestID);
end;

procedure TRTDBFra.lstRunningListenerChange(Sender: TObject);
begin
  btnStopListener.Enabled := lstRunningListener.ItemIndex >= 0;
end;

procedure TRTDBFra.btnStopListenerClick(Sender: TObject);
var
  FirebaseEvent: IFirebaseEvent;
begin
  if lstRunningListener.ItemIndex < 0 then
    exit;
  if fFirebaseEvents.TryGetValue(
    lstRunningListener.Items[lstRunningListener.ItemIndex], FirebaseEvent) then
    FirebaseEvent.StopListening;
end;

procedure TRTDBFra.StopAllListener;
var
  Event: string;
begin
  if assigned(fRealTimeDB) and (fFirebaseEvents.Count > 0) then
  begin
    for Event in fFirebaseEvents.Keys do
      fFirebaseEvents.Items[Event].StopListening;
    fFirebaseEvents.Clear;
    lstRunningListener.Items.Clear;
  end;
end;

{$ENDREGION}

{$REGION 'Server Variables of Realtime DB'}

procedure TRTDBFra.btnGetServerTimeStampClick(Sender: TObject);
var
  ServerTime: TJSONValue;
begin
  if not CheckAndCreateRealTimeDBClass then
    exit;
  ServerTime := fRealTimeDB.GetServerVariablesSynchronous(
    cServerVariableTimeStamp, []);
  try
    memRTDB.Lines.Add('ServerTime (local time): ' +
      DateTimeToStr(TFirebaseHelpers.ConvertTimeStampToLocalDateTime(
        (ServerTime as TJSONNumber).AsInt64)));
  finally
    ServerTime.Free;
  end;
end;

{$ENDREGION}

{$REGION 'Misc GUI'}

procedure TRTDBFra.mniClearClick(Sender: TObject);
begin
  memRTDB.Lines.Clear;
end;

{$ENDREGION}

end.
