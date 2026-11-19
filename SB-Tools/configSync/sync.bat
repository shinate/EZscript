@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ========== 配置文件路径 ==========
if "%~1"=="" (
    echo [错误] 请传入 INI 配置文件路径
    echo [用法] %~nx0 "配置文件.ini"
    echo.
    echo 配置文件格式示例:
    echo [Sync]
    echo SOURCE=D:\我的文档\工作文件.docx
    echo DEST=E:\备份\工作文件.docx
    echo DEST=F:\共享\工作文件.docx
    pause
    exit /b 1
)
set "CONFIG_FILE=%~1"

:: ========== 检查配置文件 ==========
if not exist "%CONFIG_FILE%" (
    echo [错误] 配置文件不存在: %CONFIG_FILE%
    pause
    exit /b 1
)

:: ========== 读取配置 ==========
set "SOURCE="
set "DEST_COUNT=0"
set "IN_SYNC_SECTION=0"

for /f "usebackq eol=; tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    set "KEY=%%a"
    set "VALUE=%%b"

    if not "!KEY!"=="" (
        if "!KEY:~0,1!"=="[" (
            if /i "!KEY!"=="[Sync]" (
                set "IN_SYNC_SECTION=1"
            ) else (
                set "IN_SYNC_SECTION=0"
            )
        ) else if "!KEY:~0,1!"=="#" (
            rem Ignore hash-prefixed comments.
        ) else if "!IN_SYNC_SECTION!"=="1" (
            if /i "!KEY!"=="SOURCE" (
                set "SOURCE=!VALUE!"
            ) else if /i "!KEY!"=="DEST" (
                if not "!VALUE!"=="" (
                    set /a DEST_COUNT+=1
                    set "DEST[!DEST_COUNT!]=!VALUE!"
                )
            )
        )
    )
)

:: ========== 检查源文件 ==========
if "%SOURCE%"=="" (
    echo [错误] 配置文件的 [Sync] 区段中未找到 SOURCE 路径
    pause
    exit /b 1
)

if %DEST_COUNT% equ 0 (
    echo [错误] 配置文件的 [Sync] 区段中未找到任何 DEST 路径
    pause
    exit /b 1
)

if not exist "%SOURCE%" (
    echo [错误] 源文件不存在: %SOURCE%
    pause
    exit /b 1
)

:: ========== 获取源文件信息 ==========
for %%A in ("%SOURCE%") do (
    set "SOURCE_FILE=%%~nxA"
    set "SOURCE_SIZE=%%~zA"
)

echo ========================================
echo [文件同步工具 - 强制覆盖模式]
echo 源文件: %SOURCE%
echo 文件名称: %SOURCE_FILE%
echo 文件大小: !SOURCE_SIZE! 字节
echo 目标数量: %DEST_COUNT%
echo ========================================
echo.

:: ========== 开始分发 ==========
set "SUCCESS=0"
set "SKIP=0"
set "FAIL=0"

for /l %%i in (1,1,%DEST_COUNT%) do (
    set "DEST_PATH=!DEST[%%i]!"
    call :SYNC_ONE "!DEST_PATH!"
)

:: ========== 显示结果 ==========
echo.
echo ========================================
echo 执行完成！ [成功:%SUCCESS%] [跳过:%SKIP%] [失败:%FAIL%]
echo ========================================
pause
exit /b 0

:: ========== 同步单个文件 ==========
:SYNC_ONE
set "DEST_PATH=%~1"

if "%DEST_PATH%"=="" goto :eof

:: 获取目标目录
for %%A in ("%DEST_PATH%") do set "DEST_DIR=%%~dpA"

:: 检查目标目录是否存在，不存在则跳过
if not exist "%DEST_DIR%" (
    echo [跳过-目录不存在] %DEST_PATH%
    echo [提示] 目标目录: %DEST_DIR%
    set /a SKIP+=1
    goto :eof
)

:: 直接覆盖复制（不检查时间）
copy /y "%SOURCE%" "%DEST_PATH%" >nul 2>&1

if !errorlevel! equ 0 (
    echo [成功] %DEST_PATH%
    set /a SUCCESS+=1
) else (
    echo [失败] %DEST_PATH%
    set /a FAIL+=1
)

goto :eof