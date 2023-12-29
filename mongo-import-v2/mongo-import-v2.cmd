@rem �ο��ĵ� https://www.mongodb.com/docs/v4.0/reference/program/mongoimport/
@echo off 

title %0
::::::::
::::::::
@setlocal
set ERROR_CODE=0


@rem get current script path
set DIRNAME=%~dp0
if "%DIRNAME%" == "" set DIRNAME=.
set SCRPIT_HOME=%DIRNAME%
for %%i in ("%SCRPIT_HOME%") do set SCRPIT_HOME=%%~fi


@REM ==== START config VALIDATION ====
SET CONFIG_FILE_NAME=import.conf
SET CONFIG_FILE=%SCRPIT_HOME%%CONFIG_FILE_NAME%
if exist "%CONFIG_FILE%" goto teeExeOk
echo [����]���������ļ�%CONFIG_FILE_NAME%������ >&2
goto error

:teeExeOk
set TEE_EXE=%SCRPIT_HOME%lib\tee-x64.exe
if exist "%TEE_EXE%" goto configFormatValidation
echo [����]����libĿ¼��tee-x64.exe�ļ�������, ����lib�ļ��� >&2
goto error

:configFormatValidation
@setlocal EnableExtensions EnableDelayedExpansion
for /F "tokens=1 delims=:" %%a in ('findstr /n /x /c:[mongo] %CONFIG_FILE%') do set mongoLine=%%a
@endlocal & set mongoLine=%mongoLine%

if not "%mongoLine%" == "" goto checkDatasource
echo [����]���������ļ�mongo�ڵ㲻���ڣ�����mongo�ڵ� >&2
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
if not "%mongodb-home%" == "" goto checkMongoimportExe
echo [����]�����ļ�%CONFIG_FILE_NAME%��, MongoDB���ݰ�װ·������Ϊ�� >&2
goto error

:checkMongoimportExe
if exist "%mongodb-home%\bin\mongoimport.exe" goto mongoimportExeOk
echo [����]����MongoDB���ݿⰲװ·��������һ�������·������������ȷ��MongoDB���ݿⰲװ·�� >&2
goto error

:mongoimportExeOk
SET MONGOIMPORT_EXE=%mongodb-home%\bin\mongoimport.exe
@REM ==== END install VALIDATION ===== 


@REM ===== START READ datasource CONFIG =====
@setlocal EnableExtensions EnableDelayedExpansion
for /F "usebackq eol=# skip=%datasourceLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="host" set HOST=%%B& goto checkHost
)
:checkHost
if not "%HOST%" == "" goto readPort
echo [����]�����ļ�%CONFIG_FILE_NAME%��, �������ݿ�host����Ϊ�� >&2
goto error 

:readPort
for /F "usebackq eol=# skip=%datasourceLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="port" set PORT=%%B& goto checkPort
)
:checkPort
if not "%PORT%" == "" goto endReadDataSourceConfig
echo [����]�����ļ�%CONFIG_FILE_NAME%��, �������ݿ�port����Ϊ�� >&2
goto error

:endReadDataSourceConfig
@REM ===== END read datasource CONFIG =====

set DIRECTORY=%1
if not "%DIRECTORY%" == "" goto checkDirectoryFile
@rem ��ʱδ��ȡ��������ļ���

@REM ===== START READ data CONFIG =====
@setlocal EnableExtensions EnableDelayedExpansion
for /F "usebackq eol=# skip=%dataLine% tokens=1,2 delims==" %%A in ("%CONFIG_FILE%") DO (
    if "%%A"=="directory" set DIRECTORY=%%B& goto checkDirectory
)

:checkDirectory
if not "%DIRECTORY%" == "" goto checkDirectoryFile
echo [����]�����ļ�%CONFIG_FILE_NAME%��, directory����Ϊ��, ����ͨ�����������ļ���λ�� >&2
goto error 

:checkDirectoryFile
@setlocal EnableExtensions EnableDelayedExpansion

set JSON_FILE_ITEMS=
for %%f in ("%DIRECTORY%\*.json") do (
    for /F "tokens=1,2 delims=." %%A in ("%%~nf") DO (
		if "%%B" == "" (
			echo [����]��֧�ָ�ʽΪ`���ݿ���.������.json`���ļ�����
			echo [����]����������"%%f"
		) else (
			if defined JSON_FILE_ITEMS (
				set JSON_FILE_ITEMS=!JSON_FILE_ITEMS!/--db "%%A" --collection "%%B" --file "%%f"
			) else (
				set JSON_FILE_ITEMS=--db "%%A" --collection "%%B" --file "%%f"
			)
		)
    )
)
@endlocal & set JSON_FILE_ITEMS=%JSON_FILE_ITEMS%

if defined JSON_FILE_ITEMS goto import
@rem �˴����κ��ļ���ȡ��
echo [����]"%DIRECTORY%"��û�з����ֿɵ�����ļ�
goto end

:import
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
@rem BUILD a str IMPORT
set IMPORT_LOG=%DIRECTORY%\mongo_import_%NOW%.log

@rem echo JSON_FILE_ITEMS="%JSON_FILE_ITEMS%"
@rem ����`/`���и�JSON_FILE_ITEMS �д����ֵ, ѭ������ִ�м���

set IMPORT_PREFIX="%MONGOIMPORT_EXE%" --host %HOST% --port %PORT% --mode=merge --type=json
set LOG_ACTION="%TEE_EXE%" -a "%IMPORT_LOG%"

:split
for /f "tokens=1,* delims=/" %%i in ("%JSON_FILE_ITEMS%") do (%IMPORT_PREFIX% %%i 2>&1 | %LOG_ACTION% &set JSON_FILE_ITEMS=%%j)
if not "!JSON_FILE_ITEMS!"=="" goto split
goto end

:error 
set ERROR_CODE=1
echo [����]����ִ����ֹ >&2

:end
@endlocal & set ERROR_CODE=%ERROR_CODE%
pause