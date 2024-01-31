@rem �ο��ĵ� https://www.mongodb.com/docs/v4.0/reference/program/mongoexport/
@echo off 

title %0
::::::::
::::::::
@setlocal
set ERROR_CODE=0

if not exist "%ProgramFiles(x86)%" (
	echo [����]�˽ű�ֻ����x86_64λϵͳ >&2
	goto error
)

@rem get current script path
set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set SCRPIT_HOME=%DIRNAME%
for %%i in ("%SCRPIT_HOME%") do set SCRPIT_HOME=%%~fi

@REM ==== START config VALIDATION ====
SET CONFIG_FILE=%SCRPIT_HOME%export.conf
if exist %CONFIG_FILE% goto configFormatValidation
echo [����]���������ļ�export.conf������ >&2
goto error

:configFormatValidation
@setlocal EnableExtensions EnableDelayedExpansion
for /F "tokens=1 delims=:" %%a in ('findstr /n /x /c:[mongo] %CONFIG_FILE%') do set mongoLine=%%a
@endlocal & set mongoLine=%mongoLine%

if not "%mongoLine%" == "" goto checkSettings
echo [����]���������ļ�mongo�ڵ㲻���ڣ�����mongo�ڵ� >&2
goto error

:checkSettings
@setlocal EnableExtensions EnableDelayedExpansion
for /F "tokens=1 delims=:" %%a in ('findstr /n /x /c:[settings] %CONFIG_FILE%') do set settingsLine=%%a
@endlocal & set settingsLine=%settingsLine%

if not "%settingsLine%" == "" goto checkDatasource
echo [����]���������ļ�settings�ڵ㲻���ڣ�����settings�ڵ� >&2
goto error

:checkDatasource
@setlocal EnableExtensions EnableDelayedExpansion
for /F "tokens=1 delims=:" %%a in ('findstr /n /x /c:[datasource] %CONFIG_FILE%') do set datasourceLine=%%a
@endlocal & set datasourceLine=%datasourceLine%

if not "%datasourceLine%" == "" goto checkData
echo [����]���������ļ�datasource�ڵ㲻���ڣ�����datasource�ڵ� >&2
goto error

:checkData
@setlocal EnableExtensions EnableDelayedExpansion
for /F "tokens=1 delims=:" %%a in ('findstr /n /x /c:[data] %CONFIG_FILE%') do set dataLine=%%a
@endlocal & set dataLine=%dataLine%

if not "%dataLine%" == "" goto EndConfigFormatValidation
echo [����]���������ļ�data�ڵ㲻���ڣ�����data�ڵ� >&2
goto error

:EndConfigFormatValidation
@REM ==== END config VALIDATION ====

@REM ==== START install VALIDATION ===== 
@setlocal EnableExtensions EnableDelayedExpansion
for /F "usebackq eol=# skip=%mongoLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="mongodb-home" set mongodb-home=%%B& goto checkMongodbHome
)

:checkMongodbHome
if not "%mongodb-home%" == "" goto checkMongoexportExe
echo [����]MongoDB���ݰ�װ·������Ϊ�� >&2
goto error

:checkMongoexportExe
if exist "%mongodb-home%\bin\mongoexport.exe" goto OkMongoexportExe
echo [����]����MongoDB���ݿⰲװ·��������һ�������·������������ȷ��MongoDB���ݿⰲװ·�� >&2
goto error

:OkMongoexportExe
SET MONGOEXPORT_EXE=%mongodb-home%\bin\mongoexport.exe
@REM ==== END install VALIDATION ===== 


@REM ===== START READ datasource CONFIG =====
@setlocal EnableExtensions EnableDelayedExpansion
for /F "usebackq eol=# skip=%datasourceLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="host" set HOST=%%B& goto checkHost
)
:checkHost
if not "%HOST%" == "" goto readPort
echo [����]�������ݿ�host����Ϊ�� >&2
goto error 

:readPort
for /F "usebackq eol=# skip=%datasourceLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="port" set PORT=%%B& goto checkPort
)
:checkPort
if not "%PORT%" == "" goto endReadConfig
echo [����]�������ݿ�port����Ϊ�� >&2
goto error

:endReadConfig
@REM ===== END read datasource CONFIG =====


@rem ==== START BUILD now FORMAT ====
@setlocal EnableExtensions EnableDelayedExpansion
for /f "tokens=2 delims==" %%G in ('wmic OS Get localdatetime /value') do set "dt=%%G"
set "year=%dt:~0,4%"
set "month=%dt:~4,2%"
set "day=%dt:~6,2%"
set "hour=%dt:~8,2%"
set "minute=%dt:~10,2%"
set "second=%dt:~12,2%"
@endlocal & set "NOW=%year%_%month%_%day%_%hour%_%minute%_%second%"
@rem ==== END BUILD now FORMAT ====

@rem BUILD a str EXPORT
set EXPORT=mongo_%NOW%

@rem ==== START READ settings CONFIG ====
@setlocal EnableExtensions EnableDelayedExpansion
for /F "usebackq eol=# skip=%settingsLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="exportEndExit" set exportEndExit=%%B& goto buildEndAction
)

:buildEndAction
set endAction=pause
if "%exportEndExit%" == "true" (
	set endAction=exit
)
set /A settingsStartLine=%settingsLine%
set /A settingsEndLine=%datasourceLine%
set /A currentLine=%settingsLine%
for /F "usebackq eol=# skip=%settingsStartLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
	set /A currentLine+=1
	if "%%A"=="directory" set directory=%%B& goto checkDirectory
	if "!currentLine!" == "%settingsEndLine%" goto directoryNotFind
)

:directoryNotFind
echo [����]�������ݿ�directory���ò����� >&2
goto error

:checkDirectory
if "%directory%" == "" set directory=%userprofile%\Desktop
@endlocal & set DIRECTORY=%directory%\%EXPORT%&set endAction=%endAction%
@rem ==== END READ settings CONFIG ====

@rem ==== START READ data CONFIG ====
@setlocal EnableExtensions EnableDelayedExpansion
for /F "usebackq eol=# skip=%dataLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="db" set DB=%%B& goto checkSchema
)
:checkSchema
if not "%DB%" == "" goto readCollections
echo [����]�������ݿ�db����Ϊ�� >&2
goto error

:readCollections
for /F "tokens=1 delims=:" %%a in ('findstr /n /x /c:"collections=" %CONFIG_FILE%') do set collectionsLine=%%a

if not "%collectionsLine%" == "" goto checkLib
echo [����]����collections����Ϊ�� >&2
goto error

:checkLib
set "TEE_EXE=%SCRPIT_HOME%lib\tee-x64.exe"
if exist "%TEE_EXE%" goto createDir
echo [����]����libĿ¼��tee-x64.exe�ļ�������, ����lib�ļ��� >&2
goto error

@rem ==== START CREATE DIRECTORY ====
:createDir
if not exist "%DIRECTORY%" mkdir "%DIRECTORY%" 2>nul
if not ERRORLEVEL 1 goto export
echo [����]����"%DIRECTORY%"�ļ���ʧ�ܣ�ϵͳ�Ҳ���ָ���������� >&2
goto error
@rem ==== END CREATE DIRECTORY  ====

echo ����·��: %DIRECTORY%

:export
for /F "usebackq eol=# skip=%collectionsLine%" %%a in ("%CONFIG_FILE%") do (
"%MONGOEXPORT_EXE%" ^
 --host %HOST% ^
 --port %PORT% ^
 --collection "%%a" ^
 --db "%DB%" ^
 --out "%DIRECTORY%\%DB%.%%a.json" 2>&1 | %TEE_EXE% -a "%DIRECTORY%\mongo_export_%NOW%.log
)

if ERRORLEVEL 1 goto error
set skip=%1
if "%skip%" == "skipZip" goto end
goto archive

:error 
set ERROR_CODE=1
echo [����]����ִ����ֹ >&2
goto end

:archive
SET SEVEN_ZA_EXE=%SCRIPT_HOME%lib\7za.exe
if not exist "%SEVEN_ZA_EXE%" goto skipArchive
for %%I in ("%DIRECTORY%.") do set ZIP_DIRECTORY=%%~dpI
for %%I in ("%DIRECTORY%.") do set ZIP_NAME=%%~nxI
"%SEVEN_ZA_EXE%" a -tzip "%ZIP_DIRECTORY%%ZIP_NAME%.zip" "%DIRECTORY%\*.*"

if ERRORLEVEL 1 goto zipNotSuccess
rd /s /q "%DIRECTORY%"
goto end

:zipNotSuccess
echo [����]ѹ��ʱ��������, ����ѹ�� >&2
goto end

:skipArchive
echo [����]ѹ�����%SEVEN_ZA_EXE%������, ����ѹ�� >&2

:end
@endlocal & cmd /C %endAction% /B %ERROR_CODE%