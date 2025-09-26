@echo off
echo Build Batch for FB4D Samples with Delphi 12
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild.exe "%~dp0\FB4D Samples.groupproj" /p:Config=Debug;Platform=Win64
if %errorlevel% neq 0 goto Abort
msbuild.exe "%~dp0\FB4D Samples VCL.groupproj" /p:Config=Debug;Platform=Win64
pause
exit 0
:Abort
echo Build failed
pause