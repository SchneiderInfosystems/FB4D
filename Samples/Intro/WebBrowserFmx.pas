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

unit WebBrowserFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.WebBrowser, FMX.Layouts,
  FMX.Objects, FMX.Consts;

  // Workaround for https://embt.atlassian.net/servicedesk/customer/portal/1/RSS-2061

type
  TOnLoaded = procedure(const URL: string; ErrorFlag: boolean) of object;
  TfmxWebBrowser = class(TForm)
    webChrome: TWebBrowser;
    layChrome: TLayout;
    procedure webChromeDidFinishLoad(ASender: TObject);
    procedure webChromeDidFailLoadWithError(ASender: TObject);
  private
    fOnLoaded: TOnLoaded;
    fURL: string;
    fTempFilename: string;
    fZoom: single;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Zoom(Scale: single);
    procedure LoadFromFile(const FileName: string; OnLoaded: TOnLoaded);
    procedure LoadFromStrings(const HTML: string; OnLoaded: TOnLoaded);
    procedure Stop;
  end;

implementation

uses
  System.IOUtils;

{$R *.fmx}

{ TfmxWebBrowser }

constructor TfmxWebBrowser.Create(AOwner: TComponent);
begin
  try
    inherited;
  except
    {$IFDEF MSWINDOWS}
    {$IF CompilerVersion >= 35} // Delphi 11 and later
    on E: Exception do
      if E.Message.EndsWith(SEdgeBrowserEngineUnavailable) then
        raise EWebManagerException.Create('Please install WebView2 SDK or copy WebView2Loader.dll into exe folder in order to use the Edge webbrowser!')
      else
    {$ENDIF}
    {$ENDIF}
    raise;
  end;
  fZoom := 1;
end;

procedure TfmxWebBrowser.LoadFromFile(const FileName: string; OnLoaded: TOnLoaded);
begin
  fOnLoaded := OnLoaded;
  fURL := FileName;
  Stop;
  fTempFileName := TPath.Combine(TPath.GetTempPath, TGUID.NewGuid.ToString);
  TFile.Copy(FileName, fTempFileName);
  webChrome.Navigate('file:/' + StringReplace(fTempFileName, '\', '/', [rfReplaceAll]));
end;

procedure TfmxWebBrowser.LoadFromStrings(const HTML: string; OnLoaded: TOnLoaded);
begin
  fOnLoaded := OnLoaded;
  fURL := '';
  Stop;
  webChrome.LoadFromStrings(HTML, TEncoding.UTF8, '');
end;

procedure TfmxWebBrowser.Stop;
begin
  webChrome.Stop;
  if not fTempFilename.IsEmpty and FileExists(fTempFileName) then
    DeleteFile(fTempFileName);
end;

procedure TfmxWebBrowser.webChromeDidFailLoadWithError(ASender: TObject);
begin
  if fZoom <> 1 then
    Zoom(fZoom);
  if assigned(fOnLoaded) then
    fOnLoaded(fURL, true);
end;

procedure TfmxWebBrowser.webChromeDidFinishLoad(ASender: TObject);
begin
  if assigned(fOnLoaded) then
    fOnLoaded(fURL, false);
  if fZoom <> 1 then
    Zoom(fZoom);
end;

procedure TfmxWebBrowser.Zoom(Scale: single);
begin
  fZoom := Scale;
  if assigned(webChrome) then
    webChrome.EvaluateJavaScript(Format('document.body.style.zoom = "%d%%";', [trunc(Scale * 100)]));
end;

end.
