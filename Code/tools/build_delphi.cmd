@echo off
setlocal EnableExtensions

set "PROJECT=%~dp0..\UPEdit.dproj"
set "CONFIG=%~1"
if "%CONFIG%"=="" set "CONFIG=Debug"
set "BUILD_PLATFORM=%~2"
if "%BUILD_PLATFORM%"=="" set "BUILD_PLATFORM=Win64"

set "RSVARS="
if defined BDS if exist "%BDS%\bin\rsvars.bat" set "RSVARS=%BDS%\bin\rsvars.bat"
if not defined RSVARS if exist "%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat" set "RSVARS=%ProgramFiles(x86)%\Embarcadero\Studio\23.0\bin\rsvars.bat"
if not defined RSVARS if exist "%ProgramFiles(x86)%\Embarcadero\Studio\22.0\bin\rsvars.bat" set "RSVARS=%ProgramFiles(x86)%\Embarcadero\Studio\22.0\bin\rsvars.bat"
if not defined RSVARS if exist "%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat" set "RSVARS=%ProgramFiles(x86)%\Embarcadero\Studio\21.0\bin\rsvars.bat"
if not defined RSVARS if exist "%ProgramFiles(x86)%\Embarcadero\Studio\20.0\bin\rsvars.bat" set "RSVARS=%ProgramFiles(x86)%\Embarcadero\Studio\20.0\bin\rsvars.bat"

if not defined RSVARS (
  echo [ERROR] Delphi build environment was not found.
  echo [ERROR] Please install Delphi and make sure rsvars.bat is available.
  echo [ERROR] You can also set BDS environment variable to your Delphi root folder.
  exit /b 1
)

echo [INFO] Using rsvars: %RSVARS%
call "%RSVARS%"
if errorlevel 1 exit /b %errorlevel%

echo [INFO] Building %PROJECT% ^(Config=%CONFIG%, Platform=%BUILD_PLATFORM%^) ...
msbuild "%PROJECT%" /t:Build /p:Config=%CONFIG% /p:Platform=%BUILD_PLATFORM% /v:m
exit /b %errorlevel%
