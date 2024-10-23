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
  public
    constructor Create(AOwner: TComponent); override;
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
    on E: Exception do
      if E.Message.EndsWith(SEdgeBrowserEngineUnavailable) then
        raise Exception.Create('Please install WebView2 SDK or copy WebView2Loader.dll into exe folder in order to use the Edge webbrowser!')
      else
    {$ENDIF}
    raise;
  end;
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
  webChrome.LoadFromStrings(HTML, '');
end;

procedure TfmxWebBrowser.Stop;
begin
  webChrome.Stop;
  if not fTempFilename.IsEmpty and FileExists(fTempFileName) then
    DeleteFile(fTempFileName);
end;

procedure TfmxWebBrowser.webChromeDidFailLoadWithError(ASender: TObject);
begin
  if assigned(fOnLoaded) then
    fOnLoaded(fURL, true);
end;

procedure TfmxWebBrowser.webChromeDidFinishLoad(ASender: TObject);
begin
  if assigned(fOnLoaded) then
    fOnLoaded(fURL, false);
end;

end.
