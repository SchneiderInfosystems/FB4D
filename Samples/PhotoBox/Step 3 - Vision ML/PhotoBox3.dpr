program PhotoBox3;

uses
  System.StartUpCopy,
  FMX.Forms,
  PhotoBoxMainFmx3 in 'PhotoBoxMainFmx3.pas' {fmxMain},
  CameraCaptureFra3 in 'CameraCaptureFra3.pas' {fraCameraCapture3: TFrame},
  PhotoThreads3 in 'PhotoThreads3.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TfmxMain, fmxMain);
  Application.Run;
end.
