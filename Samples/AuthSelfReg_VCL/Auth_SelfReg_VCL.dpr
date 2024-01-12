program Auth_SelfReg_VCL;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  FB4D.SelfRegistrationFra in '..\..\GUIPatterns\VCL\FB4D.SelfRegistrationFra.pas' {FraSelfRegistration: TFrame},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Windows10');
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
