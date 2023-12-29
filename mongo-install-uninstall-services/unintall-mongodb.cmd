@echo off 

@rem === ACTION confirm ===
echo [警告]此操作将会删除MongoDB根路径下data，log文件夹 >&2
echo [警告]此操作将会删除Windows服务中的MongodDB服务 >&2
echo [警告]请确认是否执行？>&2

set choice=
set /p choice=[警告]输入[Y/y]确认操作，其他任意输入取消操作
IF NOT "%Choice%"=="" SET Choice=%Choice:~0,1%
if /i "%choice%"=="Y" goto dorpYes

@rem 其他按键都是cancel状态
:dropCancel
echo [警告]删除操作取消 >&2
goto end 

@rem 只有输入Y时执行到这里
:dorpYes
@setlocal EnableExtensions EnableDelayedExpansion
set SCRIPT=%0
for %%I in (%SCRIPT%) do set home=%%~dpI
for %%I in ("%home%.") do set home=%%~dpfI
@endlocal & set SCRIPT_DIR=%home%

@rem http://www.maddogsw.com/cmdutils/

if exist "%SCRIPT_DIR%\lib\Recycle.exe" goto init
echo [错误]删除程序%RECYCLE_EXE%未找到 >&2
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


	
echo [警告]文件夹%DB_PATH%已被移动至回收站 >&2
echo [警告]文件夹%LOG_PATH%已被移动至回收站 >&2
echo [警告]文件%MONGO_CONF%已被移动至回收站 >&2

goto delCommit

:initError
echo [警告]删除操作出现错误，请检查错误后再次执行 >&2
goto end

:delCommit
echo [警告]删除操作已经完成 >&2
goto end

:end
pause
