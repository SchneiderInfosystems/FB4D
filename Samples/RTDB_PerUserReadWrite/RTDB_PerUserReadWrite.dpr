program RTDB_PerUserReadWrite;

uses
  System.StartUpCopy,
  FMX.Forms,
  FB4D.PerUserReadWrite in 'FB4D.PerUserReadWrite.pas' {fmxMain},
  FB4D.SelfRegistrationFra in '..\..\GUIPatterns\FMX\FB4D.SelfRegistrationFra.pas' {FraSelfRegistration: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmxMain, fmxMain);
  Application.Run;
end.
