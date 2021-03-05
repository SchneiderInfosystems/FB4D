program FSSimpleChat;

uses
  System.StartUpCopy,
  FMX.Forms,
  ChatMainFmx in 'ChatMainFmx.pas' {fmxChatMain},
  FB4D.Interfaces in '..\..\Source\FB4D.Interfaces.pas',
  FB4D.Configuration in '..\..\Source\FB4D.Configuration.pas',
  FB4D.Authentication in '..\..\Source\FB4D.Authentication.pas',
  FB4D.Document in '..\..\Source\FB4D.Document.pas',
  FB4D.Firestore in '..\..\Source\FB4D.Firestore.pas',
  FB4D.FireStore.Listener in '..\..\Source\FB4D.FireStore.Listener.pas',
  FB4D.Helpers in '..\..\Source\FB4D.Helpers.pas',
  FB4D.Request in '..\..\Source\FB4D.Request.pas',
  FB4D.Response in '..\..\Source\FB4D.Response.pas',
  FB4D.RealTimeDB in '..\..\Source\FB4D.RealTimeDB.pas',
  FB4D.Storage in '..\..\Source\FB4D.Storage.pas',
  FB4D.Functions in '..\..\Source\FB4D.Functions.pas',
  FB4D.SelfRegistrationFra in '..\..\GUIPatterns\FMX\FB4D.SelfRegistrationFra.pas' {FraSelfRegistration: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmxChatMain, fmxChatMain);
  Application.Run;
end.
