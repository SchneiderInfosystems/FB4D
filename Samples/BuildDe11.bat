@echo off
echo Build Batch for FB4D Samples with Delphi 11
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat"
msbuild.exe "FB4D Samples.groupproj" /p:Config=Debug;Platform=Win64
if %errorlevel% neq 0 goto Abort
msbuild.exe "FB4D Samples VCL.groupproj" /p:Config=Debug;Platform=Win64
pause
exit 0
:Abort
echo Build failed
pause