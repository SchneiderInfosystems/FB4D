@echo off
echo Build Batch for FB4D Integration Tests with Delphi 13.0
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild.exe FB4D.IntegrationTests.dproj /t:Rebuild /p:Config=Debug;Platform=Win32 /clp:ErrorsOnly
if errorlevel 1 (
  echo.
  echo *** BUILD FAILED - see output above ***
  pause
  exit /b 1
)

echo.
echo Build succeeded. Launching VCL test runner...
echo NOTE: Test runner opens its own window with full results.
echo       Close the test window to return here.
echo.
start /wait "" ".\Win32\Debug\FB4D.IntegrationTests.exe"
echo.
echo Test run complete.
pause