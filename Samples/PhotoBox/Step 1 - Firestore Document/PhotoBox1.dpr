program PhotoBox1;

uses
  System.StartUpCopy,
  FMX.Forms,
  PhotoBoxMainFmx1 in 'PhotoBoxMainFmx1.pas' {fmxMain},
  CameraCaptureFra1 in 'CameraCaptureFra1.pas' {fraCameraCapture1: TFrame},
  PhotoThreads1 in 'PhotoThreads1.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TfmxMain, fmxMain);
  Application.Run;
end.
