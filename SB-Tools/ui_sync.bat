@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ========== 配置文件路径 ==========
set "CONFIG_FILE=%~dp0ui_sync_config.txt"

:: ========== 检查配置文件 ==========
if not exist "%CONFIG_FILE%" (
    echo [错误] 配置文件不存在: %CONFIG_FILE%
    echo [提示] 请创建配置文件，格式见下方说明
    echo.
    echo 配置文件格式示例:
    echo ========================================
    echo # 源文件路径
    echo SOURCE=D:\我的文档\工作文件.docx
    echo.
    echo # 目标路径列表
    echo DEST=E:\备份\工作文件.docx
    echo DEST=F:\共享\工作文件.docx
    echo DEST=\\NAS\公共\工作文件.docx
    echo ========================================
    pause
    exit /b 1
)

:: ========== 读取配置 ==========
set "SOURCE="
set "DEST_COUNT=0"

for /f "usebackq tokens=1,* delims==" %%a in ("%CONFIG_FILE%") do (
    set "KEY=%%a"
    set "VALUE=%%b"
    
    :: 跳过空行和注释行
    if not "!KEY!"=="" (
        set "FIRST_CHAR=!KEY:~0,1!"
        if not "!FIRST_CHAR!"=="#" (
            if /i "!KEY!"=="SOURCE" (
                set "SOURCE=!VALUE!"
            )
            if /i "!KEY!"=="DEST" (
                set /a DEST_COUNT+=1
                set "DEST[!DEST_COUNT!]=!VALUE!"
            )
        )
    )
)

:: ========== 检查源文件 ==========
if "%SOURCE%"=="" (
    echo [错误] 配置文件中未找到 SOURCE 路径
    pause
    exit /b 1
)

if %DEST_COUNT% equ 0 (
    echo [错误] 配置文件中未找到任何 DEST 路径
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