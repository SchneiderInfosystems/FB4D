program Auth_SelfReg_VCL;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  FB4D.SelfRegistrationFra in '..\..\GUIPatterns\VCL\FB4D.SelfRegistrationFra.pas' {FraSelfRegistration: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
