@echo off
echo Build Batch for FB4D Unit Test with Delphi 12
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
msbuild.exe FB4D.IntegrationTests.dproj /t:Rebuild /p:Config=Debug;Platform=Win32
call ".\Win32\Debug\FB4D.IntegrationTests.exe"