program DemoFB4D;

{$WARN DUPLICATE_CTOR_DTOR OFF}

uses
  {$IFDEF DEBUG}
  FastMM4,
  {$ENDIF }
  System.StartUpCopy,
  FMX.Forms,
  FB4D.DemoFmx in 'FB4D.DemoFmx.pas' {fmxFirebaseDemo},
  FB4D.Interfaces in '..\..\Source\FB4D.Interfaces.pas',
  FB4D.Authentication in '..\..\Source\FB4D.Authentication.pas',
  FB4D.OAuth in '..\..\Source\FB4D.OAuth.pas',
  FB4D.Response in '..\..\Source\FB4D.Response.pas',
  FB4D.Request in '..\..\Source\FB4D.Request.pas',
  FB4D.Firestore in '..\..\Source\FB4D.Firestore.pas',
  FB4D.Document in '..\..\Source\FB4D.Document.pas',
  FB4D.Functions in '..\..\Source\FB4D.Functions.pas',
  FB4D.Helpers in '..\..\Source\FB4D.Helpers.pas',
  FB4D.Storage in '..\..\Source\FB4D.Storage.pas',
  FB4D.RealTimeDB in '..\..\Source\FB4D.RealTimeDB.pas';

{$R *.res}

begin
  {$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := true;
  {$ENDIF}
  Application.Initialize;
  Application.CreateForm(TfmxFirebaseDemo, fmxFirebaseDemo);
  Application.Run;
end.
