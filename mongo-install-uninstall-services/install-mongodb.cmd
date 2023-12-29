@echo off


@rem get current home path 
@setlocal EnableExtensions EnableDelayedExpansion
set SCRIPT=%0

for %%I in (%SCRIPT%) do set home=%%~dpI
for %%I in ("%home%..") do set home=%%~dpfI
@endlocal & set MONGO_HOME=%home%


@rem check mongod.exe
if exist "%MONGO_HOME%\bin\mongod.exe" goto checkCfgTemplate
echo [����]�ļ�"%MONGO_HOME%\bin\mongod.exe"������ >&2
goto error

:checkCfgTemplate
@setlocal EnableExtensions EnableDelayedExpansion
set SCRIPT=%0

for %%I in (%SCRIPT%) do set home=%%~dpI
for %%I in ("%home%.") do set home=%%~dpfI
@endlocal & set SCRPIT_HOME=%home%
if exist "%SCRPIT_HOME%\lib\mongod.template.cfg" goto init
echo [����]�ļ�"%SCRPIT_HOME%\lib\mongod.template.cfg"������ >&2
goto error

:init
SET DB_PATH="%MONGO_HOME%\data"
if not exist "%DB_PATH%"  goto :checkLog
echo [����]�ļ���%DB_PATH%�Ѵ���, ��ȷ��MongoDBδ��װ >&2
goto error

:checkLog
SET LOG_PATH="%MONGO_HOME%\log"
if not exist "%LOG_PATH%"  goto :checkCfg
echo [����]�ļ���%LOG_PATH%�Ѵ���, ��ȷ��MongoDBδ��װ >&2
goto error

:checkCfg
SET MONGOD_CFG_TEMPLATE="%SCRPIT_HOME%\lib\mongod.template.cfg"
SET MONGOD_CFG="%MONGO_HOME%\bin\mongod.cfg"
if not exist "%MONGOD_CFG%"  goto :initEnd
echo [����]�ļ�%MONGOD_CFG%�Ѵ���, ��ȷ��MongoDBδ��װ >&2
goto error

:initEnd
mkdir %DB_PATH%
mkdir %LOG_PATH%

powershell -Command "&{Out-File -FilePath \"%LOG_PATH%\mongod.log\" -Encoding 'UTF8';}"

powershell -Command "&{"^
					"$content = Get-Content -Path \"%MONGOD_CFG_TEMPLATE%\" -Encoding UTF8 | "^
					"ForEach-Object {$_ -replace '#storageDbPath#', '%DB_PATH%'} | "^
					"ForEach-Object {$_ -replace '#systemLogPath#', '%LOG_PATH%\mongod.log'}; "^
					"$content | Set-Content -Path \"%MONGOD_CFG%\" -Encoding UTF8 ;"^
					"}"	

:install

echo [��Ϣ]MongoDB��װ·"%MONGO_HOME%" >&2
echo [��Ϣ]MongoDB�����ļ�·��%MONGOD_CFG% >&2

echo [��Ϣ]��ʼ��װMongoDB���� >&2
SET MONGOD_EXE="%MONGO_HOME%\bin\mongod.exe"

%MONGOD_EXE% --config %MONGOD_CFG% --install

echo [��Ϣ]����MongoDB���� >&2

set MONGO_SERVICE="MongoDB"

powershell -Command "&{"^
					"$mongoDB = Get-CimInstance -Class Win32_Service -Filter \"Name='%MONGO_SERVICE%'\";"^
					"If ($mongoDB -ne $null) { "^
					"  Invoke-CimMethod -InputObject $mongoDB -MethodName StartService | Out-Null ;"^
					"}"^
					"}"
					
powershell -Command "&{"^
					"$status=Get-Service -Name \"%MONGO_SERVICE%\" | Select-Object -ExpandProperty 'Status';"^
					"   Write-Output \"[��Ϣ]��ǰ%MONGO_SERVICE%����״̬ $status\";"^
					"}"
goto end 

:error
echo [����]���鰲�������ִ�а�װ
goto end 

:end
cmd /C pause