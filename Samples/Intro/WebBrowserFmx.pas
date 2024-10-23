unit WebBrowserFmx;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.WebBrowser, FMX.Layouts;

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
    procedure LoadFromFile(const FileName: string; OnLoaded: TOnLoaded);
    procedure LoadFromStrings(const HTML: string; OnLoaded: TOnLoaded);
    procedure Stop;
  end;

implementation

uses
  System.IOUtils;

{$R *.fmx}

{ TfmxWebBrowser }

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
