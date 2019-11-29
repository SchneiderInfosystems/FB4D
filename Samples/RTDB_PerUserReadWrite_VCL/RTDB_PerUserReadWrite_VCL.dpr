program RTDB_PerUserReadWrite_VCL;

uses
  Vcl.Forms,
  FB4D.VCL.PerUserReadWrite in 'FB4D.VCL.PerUserReadWrite.pas' {frmMain},
  FB4D.SelfRegistrationFra in '..\..\GUIPatterns\VCL\FB4D.SelfRegistrationFra.pas' {FraSelfRegistration: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
