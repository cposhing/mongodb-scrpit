@echo off 

@setlocal

set ERROR_CODE=0

@rem === check if directly call 
set command=%1

set DIRECTLY_EXIT=1
if "%command%" == "" set DIRECTLY_EXIT=0

@rem only using for script installed MongoDB with service name MongoDB
set MONGO_SERVICE="MongoDB"

@rem ===Validation MongodDB Service ====
@rem check the MongoDB service exists
powershell -Command "&{"^
					"$content=Get-Service | Where-Object {$_.Name -eq \"%MONGO_SERVICE%\"};"^
					"If($content -eq $null){"^
					"  Write-Output '[信息]当前系统服务中不存在%MONGO_SERVICE%服务';"^
					"  exit 1;"^
					"}"^
					"}"

if ERRORLEVEL 1 goto error

@rem check the MongoDB StartType 
powershell -Command "&{"^
					"$startType=Get-Service -Name \"%MONGO_SERVICE%\" | Select-Object -ExpandProperty 'StartType';"^
					"If($startType -eq 'Disabled'){"^
					"  Write-Output '[信息]当前系统服务已禁用%MONGO_SERVICE%服务';"^
					"  exit 1;"^
					"}"^
					"}"
if ERRORLEVEL 1 goto error
@rem ===Validation MongodDB Service End====

@rem you can directly call this scripit with param, such as `service.cmd S` 
if "%DIRECTLY_EXIT%" == "0" goto inputEmpty
goto inputNotEmpty

@rem without call param 
:inputEmpty
@rem print current MongoDB service status

powershell -Command "&{"^
					"$status=Get-Service -Name \"%MONGO_SERVICE%\" | Select-Object -ExpandProperty 'Status';"^
					"   Write-Output \"[信息]当前%MONGO_SERVICE%服务状态 $status\";"^
					"}"

@rem get the user input					
echo [信息]输入[S/s]确认启动MongoDB服务 >&2
echo [信息]输入[D/d]确认关闭MongoDB服务 >&2
echo [信息]输入[R/r]确认重启MongoDB服务 >&2
echo [信息]按任意键取消操作 >&2

set /p choice=[信息]请输入操作指令: >&2

if not "%choice%"=="" SET choice=%choice:~0,1%

if /i "%choice%"=="S" goto start
if /i "%choice%"=="D" goto down
if /i "%choice%"=="R" goto restart
goto cancel

@rem with call param 
:inputNotEmpty
if /i "%command%"=="S" goto start
if /i "%command%"=="D" goto down
if /i "%command%"=="R" goto restart
goto end

:start
powershell -Command "&{Set-Service -Name 'MongoDB' -Status 'Running';}"
if "%DIRECTLY_EXIT%" == "0" goto printStatus
goto end

:down
powershell -Command "&{Set-Service -Name 'MongoDB' -Status 'Stopped';}"
if "%DIRECTLY_EXIT%" == "0" goto printStatus
goto end

:restart
powershell -Command "&{Set-Service -Name 'MongoDB' -Status 'Stopped';}"
powershell -Command "&{Set-Service -Name 'MongoDB' -Status 'Running';}"
if "%DIRECTLY_EXIT%" == "0" goto printStatus
goto end

:error
set ERROR_CODE=1
goto end

:printStatus
@rem print current MongoDB service status
powershell -Command "&{"^
					"$status=Get-Service -Name \"%MONGO_SERVICE%\" | Select-Object -ExpandProperty 'Status';"^
					"   Write-Output \"[信息]当前%MONGO_SERVICE%服务状态 $status\";"^
					"}"
goto end

:cancel
echo [信息]操作已经取消 >&2
goto end

:end
@endlocal & set ERROR_CODE=%ERROR_CODE% & set DIRECTLY_EXIT=%DIRECTLY_EXIT%

if "%DIRECTLY_EXIT%" == "1" exit /B %ERROR_CODE%
cmd /C pause


