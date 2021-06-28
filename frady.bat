CLS
@ECHO OFF
REM FRIDAREADY : Go-To Automation Script
REM This project have created to enable ease of use in connecting frida with mobile devices
REM especially Android while performing mobile application vulnerability assessment
REM Main Features:
REM - Installing Frida if it doesn't exist
REM - Download Frida server in exact version if it is already downloaded
REM - Setting-up Frida server in mobile device and run in background

::Global
SET version=Beta 0.1a
SET devicemodel=Unknown
SET androidversion=Unknown
SET rooted=Unknown
SET devicestate=Unknown
SET cpuarch=Unknown
SET defaultagentpath=/data/local/tmp/frida-server
SET agent=No
SET fridasrv=
SET fridafile=frida-server-VERSION-android-ABI.xz

TITLE READYFRIDA : Frida Automation Script (Android Only)
:main
CALL :banner
adb version > nul 2>&1 || (ECHO. [^!] adb not found. Please install adb-platforms tool first. & goto :EOF)
ECHO. [+] Getting Device Information
CALL :GetDeviceInfo
ECHO. [^-] Status: %devicestate%
if "%devicestate%" neq "Online" (ECHO. [^!] Your device is %devicestate%. Please reconnect! & goto :EOF)
ECHO. [^-] Model: %devicemodel%
ECHO. [^-] Android Version: %androidversion%
ECHO. [^-] CPU Architecture: %cpuarch%
ECHO. [^-] Is Rooted: %rooted%
if "%rooted%" neq "Yes" (ECHO. [^!] Please root your mobile device. & goto :EOF)
ECHO. [+] Checking System Requirement
python --version > nul 2>&1 || (ECHO. [^!] python not found. Please install python3 first. & goto :EOF)
7z > nul 2>&1 || (ECHO. [^!] 7z not found. Please install 7zip and configure PATH. & goto :EOF)
frida --version > nul 2>&1 || (ECHO. [^!] frida not found. & ECHO. [+] Now Installing Frida ... & pip install frida-tools)
ECHO. [+] Attempting to Install Frida Agent in Device
ECHO. [^-] Checking if Frida Agent is already in Device
CALL :checkAgentFile

ECHO. ENDing

goto :EOF

:banner
ECHO. ++++++++++++++++++++++++++++++++++++++++++++++++++++
ECHO. + [FridaReADY] Frida Automation Script for Android +
ECHO. ++++++++++++++++++++++++++++++++++++++++++++++++++++
ECHO. Version: %version%
GOTO :EOF

:checkBinary bin
%1 > nul 2>&1
set ret=%ERRORLEVEL%
if "%ret%" equ "9009" (ECHO. [^!] %1 not found. Please install it first. & exit /b "")
goto :EOF

:checkAgentFile
SET ret=
SET devicestate=Offline
FOR /F "delims=" %%i in ('adb shell su -c "'ls /data/local/tmp/frida-server'"') do SET ret=%%i
if "%ret%" equ "%defaultagentpath%" (ECHO. [^-] Found Frida Agent file at %ret% & set agent=Yes)
if "%agent%" equ "No" (ECHO. [^-] Not found Frida Agent installed at %defaultagentpath:frida-server=%^ & goto :getAgent)
goto :runFridaSrv

:getAgent
cd /d %~dp0
set fridaver=
FOR /F "tokens=* delims=" %%i in ('frida --version') do SET fridaver=%%i
FOR /F "tokens=* delims=" %%i in ('echo frida-server-%fridaver%-android-%cpuarch%.xz') do SET fridafile=%%i
dir %fridafile:.xz=% > nul 2>&1 && (ECHO. [^!] Found already downloaded %fridafile:.xz=% in local folder^! & goto :installAgent)
ECHO. [+] Start Downloading Frida Server Agent file from Github
SET dlurl=https://github.com/frida/frida/releases/download/%fridaver%/%fridafile%
curl -s -L %dlurl% -o %fridafile%
::echo %dlurl%
ECHO. [^-] Extracting Frida Server file ...
7z x %fridafile% > nul 2>&1
goto :installAgent

:installAgent
ECHO. [^-] Installing Frida Server Agent to Device ...
adb push %fridafile:.xz=% /data/local/tmp/frida-server > nul 2>&1
adb shell su -c "chmod 775 /data/local/tmp/frida-server"
goto :runFridaSrv

:runFridaSrv
ECHO. [+] Executing Frida Server Agent ...
ECHO. [^!] Check frida-ps -aU in another terminal^!
::adb shell su -c "/data/local/tmp/frida-server &"
adb shell su -c "/data/local/tmp/frida-server"
ECHO. [+] Check Frida
frida-ps -aU
goto :EOF
::Credit to Kyaw Swar Thwin for getDeviceInfo Code 
:getDeviceInfo
SET ret=
SET devicestate=Offline
FOR /F "skip=1 tokens=* delims=" %%i in ('adb devices') do SET ret=%%i
if "%ret%" neq "" set devicestate=Online
if "%devicestate%" equ "Online" goto :getDeviceInfo_ADB
goto :EOF

:getDeviceInfo_ADB
set ret=
set rooted=No
for /f "tokens=* delims=" %%i in ('adb shell "getprop ro.product.model"') do set devicemodel=%%i
for /f "tokens=* delims=" %%i in ('adb shell "getprop ro.build.version.release"') do set androidversion=%%i
for /f "tokens=* delims=" %%i in ('adb shell "getprop ro.product.cpu.abi"') do set cpuarch=%%i
for /f "tokens=* delims=" %%i in ('adb shell "su -c \"echo Root Checker\""') do set ret=%%i
if "%ret%" equ "Root Checker" set rooted=Yes
goto :EOF
