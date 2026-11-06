program Auth_SelfReg;

uses
  System.StartUpCopy,
  FMX.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  FB4D.SelfRegistrationFra in '..\..\GUIPatterns\FMX\FB4D.SelfRegistrationFra.pas' {FraSelfRegistration: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

