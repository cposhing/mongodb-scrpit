@echo off 

@rem === ACTION confirm ===
echo [����]�˲�������ɾ��MongoDB��·����data��log�ļ��� >&2
echo [����]�˲�������ɾ��Windows�����е�MongodDB���� >&2
echo [����]��ȷ���Ƿ�ִ�У�>&2

set choice=
set /p choice=[����]����[Y/y]ȷ�ϲ�����������������ȡ������
IF NOT "%Choice%"=="" SET Choice=%Choice:~0,1%
if /i "%choice%"=="Y" goto dorpYes

@rem ������������cancel״̬
:dropCancel
echo [����]ɾ������ȡ�� >&2
goto end 

@rem ֻ������Yʱִ�е�����
:dorpYes
@setlocal EnableExtensions EnableDelayedExpansion
set SCRIPT=%0
for %%I in (%SCRIPT%) do set home=%%~dpI
for %%I in ("%home%.") do set home=%%~dpfI
@endlocal & set SCRIPT_DIR=%home%

@rem http://www.maddogsw.com/cmdutils/

if exist "%SCRIPT_DIR%\lib\Recycle.exe" goto init
echo [����]ɾ������%RECYCLE_EXE%δ�ҵ� >&2
goto initError

:init
set RECYCLE_EXE="%SCRIPT_DIR%\lib\Recycle.exe"

@setlocal EnableExtensions EnableDelayedExpansion
set SCRIPT=%0

for %%I in (%SCRIPT%) do set home=%%~dpI
for %%I in ("%home%..") do set home=%%~dpfI
@endlocal & set MONGO_HOME=%home%

SET DB_PATH="%MONGO_HOME%\data"
SET LOG_PATH="%MONGO_HOME%\log"
SET MONGO_CONF="%MONGO_HOME%\bin\mongod.cfg"

@rem stop and delete the service 
powershell -Command "&{"^
					"$mongoDB = Get-CimInstance -Class Win32_Service -Filter \"Name='MongoDB'\";"^
					"If ($mongoDB -ne $null) { "^
					"  Invoke-CimMethod -InputObject $mongoDB -MethodName StopService | Out-Null ;"^
					"  Invoke-CimMethod -InputObject $mongoDB -MethodName Delete | Out-Null ;"^
					"}"^
					"}"	

@rem remove the data and log file to the recycle bin
%RECYCLE_EXE%^
	-f %MONGO_CONF%
	
%RECYCLE_EXE%^
	-f %DB_PATH%

%RECYCLE_EXE%^
	-f %LOG_PATH%


	
echo [����]�ļ���%DB_PATH%�ѱ��ƶ�������վ >&2
echo [����]�ļ���%LOG_PATH%�ѱ��ƶ�������վ >&2
echo [����]�ļ�%MONGO_CONF%�ѱ��ƶ�������վ >&2

goto delCommit

:initError
echo [����]ɾ���������ִ������������ٴ�ִ�� >&2
goto end

:delCommit
echo [����]ɾ�������Ѿ���� >&2
goto end

:end
pause
