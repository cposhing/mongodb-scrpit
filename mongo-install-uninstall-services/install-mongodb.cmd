@echo off


@rem get current home path 
@setlocal EnableExtensions EnableDelayedExpansion
set SCRIPT=%0

for %%I in (%SCRIPT%) do set home=%%~dpI
for %%I in ("%home%..") do set home=%%~dpfI
@endlocal & set MONGO_HOME=%home%


@rem check mongod.exe
if exist "%MONGO_HOME%\bin\mongod.exe" goto checkCfgTemplate
echo [错误]文件"%MONGO_HOME%\bin\mongod.exe"不存在 >&2
goto error

:checkCfgTemplate
@setlocal EnableExtensions EnableDelayedExpansion
set SCRIPT=%0

for %%I in (%SCRIPT%) do set home=%%~dpI
for %%I in ("%home%.") do set home=%%~dpfI
@endlocal & set SCRPIT_HOME=%home%
if exist "%SCRPIT_HOME%\lib\mongod.template.cfg" goto init
echo [错误]文件"%SCRPIT_HOME%\lib\mongod.template.cfg"不存在 >&2
goto error

:init
SET DB_PATH="%MONGO_HOME%\data"
if not exist "%DB_PATH%"  goto :checkLog
echo [错误]文件夹%DB_PATH%已存在, 请确认MongoDB未安装 >&2
goto error

:checkLog
SET LOG_PATH="%MONGO_HOME%\log"
if not exist "%LOG_PATH%"  goto :checkCfg
echo [错误]文件夹%LOG_PATH%已存在, 请确认MongoDB未安装 >&2
goto error

:checkCfg
SET MONGOD_CFG_TEMPLATE="%SCRPIT_HOME%\lib\mongod.template.cfg"
SET MONGOD_CFG="%MONGO_HOME%\bin\mongod.cfg"
if not exist "%MONGOD_CFG%"  goto :initEnd
echo [错误]文件%MONGOD_CFG%已存在, 请确认MongoDB未安装 >&2
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

echo [信息]MongoDB安装路"%MONGO_HOME%" >&2
echo [信息]MongoDB配置文件路径%MONGOD_CFG% >&2

echo [信息]开始安装MongoDB服务 >&2
SET MONGOD_EXE="%MONGO_HOME%\bin\mongod.exe"

%MONGOD_EXE% --config %MONGOD_CFG% --install

echo [信息]启动MongoDB服务 >&2

set MONGO_SERVICE="MongoDB"

powershell -Command "&{"^
					"$mongoDB = Get-CimInstance -Class Win32_Service -Filter \"Name='%MONGO_SERVICE%'\";"^
					"If ($mongoDB -ne $null) { "^
					"  Invoke-CimMethod -InputObject $mongoDB -MethodName StartService | Out-Null ;"^
					"}"^
					"}"
					
powershell -Command "&{"^
					"$status=Get-Service -Name \"%MONGO_SERVICE%\" | Select-Object -ExpandProperty 'Status';"^
					"   Write-Output \"[信息]当前%MONGO_SERVICE%服务状态 $status\";"^
					"}"
goto end 

:error
echo [错误]请检查安错误后再执行安装
goto end 

:end
cmd /C pause