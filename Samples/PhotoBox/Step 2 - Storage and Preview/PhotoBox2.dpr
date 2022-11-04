program PhotoBox2;

uses
  System.StartUpCopy,
  FMX.Forms,
  PhotoBoxMainFmx2 in 'PhotoBoxMainFmx2.pas' {fmxMain},
  CameraCaptureFra2 in 'CameraCaptureFra2.pas' {fraCameraCapture2: TFrame},
  PhotoThreads2 in 'PhotoThreads2.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TfmxMain, fmxMain);
  Application.Run;
end.
