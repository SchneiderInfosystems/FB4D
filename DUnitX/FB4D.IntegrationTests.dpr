program FB4D.IntegrationTests;

// Console Tester not support because a windows event handler is required for
// aysnchrouns functions

{$STRONGLINKTYPES ON}
uses
  System.SysUtils,
  {$IFDEF TESTINSIGHT}
  TestInsight.DUnitX,
  {$ENDIF }
  DUnitX.Loggers.GUI.VCL {GUIVCLTestRunner},
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  UT.Autentication in 'UT.Autentication.pas';

begin
{$IFDEF TESTINSIGHT}
  TestInsight.DUnitX.RunRegisteredTests;
  exit;
{$ENDIF}
  try
    TDUnitX.CheckCommandLine;
    DUnitX.Loggers.GUI.VCL.Run;
  except
    on E: Exception do
      System.Writeln(E.ClassName, ': ', E.Message);
  end;
end.
