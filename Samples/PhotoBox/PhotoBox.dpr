program PhotoBox;

uses
  System.StartUpCopy,
  FMX.Forms,
  PhotoBoxMainFmx in 'PhotoBoxMainFmx.pas' {fmxMain},
  CameraCaptureFra in 'CameraCaptureFra.pas' {fraCameraCapture: TFrame},
  PhotoThreads in 'PhotoThreads.pas',
  FB4D.SelfRegistrationFra in '..\..\GUIPatterns\FMX\FB4D.SelfRegistrationFra.pas' {FraSelfRegistration: TFrame};

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TfmxMain, fmxMain);
  Application.Run;
end.
