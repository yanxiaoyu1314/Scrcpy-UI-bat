@echo off
setlocal enabledelayedexpansion

REM 设置scrcpy和adb的路径
set scrcpy_path=scrcpy\scrcpy.exe
set adb_path=scrcpy\adb.exe

REM 配置文件路径
set config_file=scrcpy-config.ini
REM 定义当前版本字符串
set current_version=0.3.5
set version_url=https://raw.githubusercontent.com/yanxiaoyu1314/Scrcpy-UI-bat/refs/heads/main/info.json


REM ==================================================
REM 版本历史
REM v0.3.5 - 关闭后自动关闭ADB链接
REM v0.3.0 - 完成无线链接方式
REM v0.2.0 - 重构整个菜单以及逻辑
REM v0.1.0 - 初始版本，基本功能实现
REM ==================================================

echo ↓↓↓当前版本（%current_version%）更新内容↓↓↓
echo 关闭后自动关闭ADB链接
echo 重构整个菜单以及逻辑
echo 完成无线链接方式
echo 初始版本，基本功能实现
echo ↑↑↑当前版本更新内容↑↑↑




echo 正在检查更新...

REM 调用 PowerShell 检查更新
powershell -Command ^
"$currentVersion = '%current_version%'; ^
 $versionUrl = '%version_url%'; ^
 $wc = New-Object System.Net.WebClient; ^
 $wc.Encoding = [System.Text.Encoding]::UTF8; ^
 try { ^
     $json = $wc.DownloadString($versionUrl); ^
     Add-Type -AssemblyName System.Web.Extensions; ^
     $ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer; ^
     $data = $ser.DeserializeObject($json); ^
     $latestVersion = $data['version']; ^
     if (-not $latestVersion) { Write-Host '更新信息错误'; exit 3 }; ^
     function Compare-Version($v1, $v2) { ^
         $v1Parts = $v1 -split '\.'; ^
         $v2Parts = $v2 -split '\.'; ^
         for ($i = 0; $i -lt [Math]::Max($v1Parts.Length, $v2Parts.Length); $i++) { ^
             $v1Part = if ($i -lt $v1Parts.Length) { [int]$v1Parts[$i] } else { 0 }; ^
             $v2Part = if ($i -lt $v2Parts.Length) { [int]$v2Parts[$i] } else { 0 }; ^
             if ($v1Part -lt $v2Part) { return $true } ^
             if ($v1Part -gt $v2Part) { return $false } ^
         }; return $false ^
     }; ^
     $needsUpdate = Compare-Version $currentVersion $latestVersion; ^
     if ($needsUpdate) { ^
         Write-Host ('发现新版本 {0}，当前版本 {1}' -f $latestVersion, $currentVersion); ^
         Write-Host ('更新时间: {0}' -f $data['updateTime']); ^
         Write-Host ('更新地址: {0}' -f $data['url']); ^
         exit 2 ^
     } else { ^
         Write-Host ('当前已是最新版本 ({0})' -f $currentVersion); ^
         exit 1 ^
     } ^
 } catch { ^
     $errorMsg = $_.Exception.Message; ^
     if ($errorMsg -match '未能解析此远程名称') {  ^
         Write-Host '检查更新失败: 无法连接到更新服务器，请检查网络连接或稍后再试'; ^
         Write-Host '可能原因: 网络未连接、防火墙阻止或GitHub域名无法访问'; ^
     } elseif ($errorMsg -match '连接超时') {  ^
         Write-Host '检查更新失败: 连接更新服务器超时，请检查网络连接速度'; ^
     } elseif ($errorMsg -match '无法连接到远程服务器') {  ^
         Write-Host '检查更新失败: 无法连接到更新服务器，请确认您的网络连接正常'; ^
     } else {  ^
         Write-Host ('检查更新失败: {0}' -f $errorMsg); ^
     } ^
     exit 3 ^
 }"

REM 根据退出码处理
pause


REM 如果配置文件存在则加载
call :read_config

REM 检查scrcpy是否存在
if not exist "%scrcpy_path%" (
echo 错误：找不到scrcpy.exe。请确保它在scrcpy文件夹中。
pause
exit /b 1
)

REM 检查adb是否存在
if not exist "%adb_path%" (
echo 错误：找不到adb.exe。请确保它在scrcpy文件夹中。
pause
exit /b 1
)

REM 设备序列号全局变量
set device_serial=

echo 正在检查已连接的设备...
"%adb_path%" devices
if %errorlevel% neq 0 (
echo 警告：检测设备时出错。您可能需要安装驱动程序。
pause
)

REM 主菜单
:main_menu
cls
echo ==========================================================================
echo                          SCRCPY 简易使用界面                          
echo ==========================================================================
echo 作者：烟小雨 ^| 版本：%current_version% ^| 基于scrcpy v3.3.2 版本进行编写

echo 请勿直接关闭窗口，将无法释放ADB资源，请使用菜单中使用退出功能
echo 若已经关闭退出，则重新打开后再使用退出功能即可

echo 当前已连接设备：
"%adb_path%" devices | findstr /v "List"
if errorlevel 1 (
echo 未检测到设备。请确保已启用USB调试并连接设备。
echo 提示：在Android设备上，进入设置 ^> 关于手机 ^> 点击版本号7次以启用开发者选项
echo 然后进入设置 ^> 开发者选项 ^> 启用USB调试
)

echo.
echo ^[功能选择^]
echo 1. 基本连接（无特殊参数）
echo 2. 使用默认参数连接
echo 3. 自定义参数连接
echo 4. 无线连接设置
echo 5. 默认参数设置
echo 6. 请作者喝杯奶茶
echo 7. 清理ADB进程并退出
echo ==========================================================================
set /p choice=请输入选项 (1-7)：

REM 根据用户选择执行相应操作
if "%choice%"=="1" goto basic_connect
if "%choice%"=="2" goto default_connect
if "%choice%"=="3" goto custom_params
if "%choice%"=="4" goto wireless_connect
if "%choice%"=="5" goto default_settings
if "%choice%"=="6" goto DrinkMilkTea
if "%choice%"=="7" goto exit_script

echo 无效选项。请重试。
pause
goto main_menu


@REM 请作者喝奶茶
:DrinkMilkTea
start "" "resource/DrinkMilkTea.png"
echo 感谢大佬的投喂！！！
pause
goto main_menu

REM 基本连接
:basic_connect
cls
echo 基本连接模式（无特殊参数）
echo.

REM 调用设备选择函数
call :select_device_function
if errorlevel 1 (
    echo 设备选择失败，返回主菜单。
    pause
goto main_menu
)

REM 启动scrcpy
call :start_scrcpy %selected_device% ""
goto after_start

:single_device
echo 正在启动基本连接...
for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
    start "scrcpy" "%scrcpy_path%" -s %%a
)
goto after_start

REM 使用默认参数连接
:default_connect
cls
echo 当前默认参数：
if not "%default_resolution%"=="" (
echo 分辨率：%default_resolution%
) else (
echo 分辨率：默认
)
if not "%default_fps%"=="" (
echo 帧率：%default_fps%
) else (
echo 帧率：默认
)
if not "%default_audio_bitrate%"=="" (
echo 音频比特率：%default_audio_bitrate%
) else (
echo 音频比特率：默认
)
if not "%default_audio_source%"=="" (
echo 音频源：%default_audio_source%
) else (
echo 音频源：默认
)
if not "%default_device%"=="" (
echo 设备：%default_device%
) else (
echo 设备：自动选择
)
echo.

REM 构建默认参数
set params=
if not "%default_resolution%"=="" set params=%params% --max-size=%default_resolution%
if not "%default_fps%"=="" set params=%params% --max-fps=%default_fps%
if not "%default_audio_bitrate%"=="" set params=%params% --audio-bit-rate=%default_audio_bitrate%
if not "%default_audio_source%"=="" (
    if not "%default_audio_source%"==" " (
        set params=%params% --audio-source=%default_audio_source%
    )
)

REM 检查是否设置了默认设备
if not "%default_device%"=="" (
    if not "%default_device%"==" " (
        set selected_device=%default_device%
        echo 正在使用默认设备启动连接...
        call :start_scrcpy %selected_device% "%params%"
        goto after_start
    )
)

REM 没有默认设备，调用设备选择函数
call :select_device_function
if errorlevel 1 (
    echo 设备选择失败，返回主菜单。
    pause
    goto main_menu
)

REM 启动scrcpy
call :start_scrcpy %selected_device% "%params%"
goto after_start

:single_device
echo 正在启动基本连接...
for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
    start "scrcpy" "%scrcpy_path%" -s %%a
)
goto after_start

REM 使用默认参数连接
REM 重复标签已删除 - 请保留第186行的标签
cls
echo 当前默认参数：
if not "%default_resolution%"=="" (
echo 分辨率：%default_resolution%
) else (
echo 分辨率：默认
)
if not "%default_fps%"=="" (
echo 帧率：%default_fps%
) else (
echo 帧率：默认
)
if not "%default_audio_bitrate%"=="" (
echo 音频比特率：%default_audio_bitrate%
) else (
echo 音频比特率：默认
)
if not "%default_audio_source%"=="" (
echo 音频源：%default_audio_source%
) else (
echo 音频源：默认
)
if not "%default_device%"=="" (
echo 设备：%default_device%
) else (
echo 设备：自动选择
)
echo.

echo.
echo 当前已连接设备：
"%adb_path%" devices > devices.txt
type devices.txt | findstr /v "List" | findstr /v "offline"
if errorlevel 1 (
echo 未检测到设备。请确保已启用USB调试并连接设备。
pause
goto main_menu
)

REM 统计设备数量
set device_count=0
for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
    set /a device_count+=1
)

REM 如果设置了默认设备，直接使用
set "default_device=%default_device%"
if "%default_device%"=="" (
    goto check_device_count
) else if "%default_device%"==" " (
    goto check_device_count
) else (
    set selected_device=%default_device%
    echo 正在使用默认设备启动连接...
    goto start_default_connection
)

:check_device_count
REM 判断设备数量
if %device_count% gtr 1 goto default_multiple_devices
goto default_single_device

:default_multiple_devices
echo 检测到多个设备，请选择要连接的设备：
echo.
set /a counter=1
for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
    echo !counter!. %%a
    set device_!counter!=%%a
    set /a counter+=1
)
echo.
set /p device_choice=请选择设备 (1-%device_count%)：
if "%device_choice%"=="" (
    pause
    goto default_connect
)
call set device_check=%%device_%device_choice%%
if defined device_check (
    set /a line_num=%device_choice%
    for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
        if !line_num! equ 1 (
            set selected_device=%%a
            set line_num=0
        ) else (
            set /a line_num-=1
        )
    )
    if defined selected_device (
        echo 已选择设备：!selected_device!
        echo 正在使用默认参数启动连接...
        goto start_default_connection
    ) else (
        echo 无效选择。
        pause
        goto default_connect
    )
) else (
    echo 无效选择。
    pause
    goto default_connect
)

:default_single_device
echo 正在使用默认参数启动连接...
for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
    set selected_device=%%a
)

REM 如果没有设置默认设备，使用基本连接逻辑
if "%default_device%"=="" (
    echo 未设置默认设备，使用基本连接逻辑...
    set params=
    if not "%default_resolution%"=="" set params=%params% --max-size=%default_resolution%
    if not "%default_fps%"=="" set params=%params% --max-fps=%default_fps%
    if not "%default_audio_bitrate%"=="" set params=%params% --audio-bit-rate=%default_audio_bitrate%
    if not "%default_audio_source%"=="" set params=%params% --audio-source=%default_audio_source%
    
    if not "%selected_device%"=="" (
        echo 正在使用默认参数连接到设备：%selected_device%
        start "scrcpy" "%scrcpy_path%" -s %selected_device% %params%
    ) else (
        echo 正在使用默认参数连接...
        start "scrcpy" "%scrcpy_path%" %params%
    )
    goto after_start
)

:start_default_connection
set params=
if not "%default_resolution%"=="" set params=%params% --max-size=%default_resolution%
if not "%default_fps%"=="" set params=%params% --max-fps=%default_fps%
if not "%default_audio_bitrate%"=="" set params=%params% --audio-bit-rate=%default_audio_bitrate%
if not "%default_audio_source%"=="" (
    if not "%default_audio_source%"==" " (
        set params=%params% --audio-source=%default_audio_source%
    )
)

call :start_scrcpy "%selected_device%" "%params%"
goto after_start

REM 设置分辨率连接
:set_resolution
cls
echo 设置最大分辨率（例如：1080, 720, 480）
if not "%default_resolution%"=="" (
echo 提示：默认分辨率为 %default_resolution%，按回车使用默认值
)
set /p resolution=分辨率：

if "%resolution%"=="" (
if not "%default_resolution%"=="" (
echo 使用默认分辨率：%default_resolution%
set resolution=%default_resolution%
) else (
echo 未提供分辨率，使用默认值。
set resolution=
)
) else (
REM 询问是否保存为默认分辨率
echo.
echo 是否将此设置为默认分辨率？(y/n)
set /p save_as_default=选择：
if /i "%save_as_default%"=="y" (
    echo 正在保存默认分辨率...
    if exist "%config_file%" (
        findstr /v "default_resolution=" "%config_file%" > "%config_file%.tmp"
        echo default_resolution=%resolution% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo default_resolution=%resolution% > "%config_file%"
    )
    echo 默认分辨率已保存为：%resolution%
    set default_resolution=%resolution%
    )
    pause
    goto default_settings

echo 设置默认帧率
:set_default_fps
cls
echo 设置默认帧率（例如：30, 60）
if not "%default_fps%"=="" (
echo 当前默认帧率：%default_fps%
)
set /p fps=帧率：

if "%fps%"=="" (
if not "%default_fps%"=="" (
echo 使用默认帧率：%default_fps%
set fps=%default_fps%
) else (
echo 未提供帧率，使用默认值。
set fps=
)
) else (
REM 询问是否保存为默认帧率
echo.
echo 是否将此设置为默认帧率？(y/n)
set /p save_as_default=选择：
if /i "%save_as_default%"=="y" (
    echo 正在保存默认帧率...
    if exist "%config_file%" (
        findstr /v "default_fps=" "%config_file%" > "%config_file%.tmp"
        echo default_fps=%fps% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo default_fps=%fps% > "%config_file%"
    )
    echo 默认帧率已保存为：%fps%
    set default_fps=%fps%
    )
    pause
    goto default_settings

echo 设置默认音频参数
:set_default_audio
cls
echo 音频参数设置

REM 音频比特率设置
if not "%default_audio_bitrate%"=="" (
echo 当前默认音频比特率：%default_audio_bitrate%
) else (
echo 当前无默认音频比特率设置
)
echo 推荐范围：
echo - 低比特率：64K-128K（网络较差时）
echo - 标准比特率：128K-256K（平衡音质和带宽）
echo - 高比特率：256K-320K（更好的音质，但需要更多带宽）
echo - 极致比特率：8M（非常好的音质，但需要很多带宽）
set /p temp_bitrate=输入音频比特率（例如：128K, 256K, 320K, 1M）：

REM 音频源设置
echo.
if not "%default_audio_source%"=="" (
echo 当前默认音频源：%default_audio_source%
) else (
echo 当前无默认音频源设置
)
echo 音频源选项：
echo 1. output: 转发整个音频输出，并禁用设备上的播放
echo 2. playback: 捕获音频播放
echo 3. mic: 捕获麦克风
echo 4. mic-unprocessed: 捕获未处理的麦克风声音
echo 5. mic-camcorder: 捕获为视频录制调优的麦克风
echo 6. mic-voice-recognition: 捕获为语音识别调优的麦克风
echo 7. mic-voice-communication: 捕获为语音通信调优的麦克风
set /p audio_source_choice=选择音频源 (1-7，或直接按回车使用默认值)：

if not "%temp_bitrate%"=="" (
call :save_config_item default_audio_bitrate %temp_bitrate%
echo 默认音频比特率已保存为：%temp_bitrate%
set default_audio_bitrate=%temp_bitrate%
)

if not "%audio_source_choice%"=="" (
if "%audio_source_choice%"=="1" set audio_source=output
if "%audio_source_choice%"=="2" set audio_source=playback
if "%audio_source_choice%"=="3" set audio_source=mic
if "%audio_source_choice%"=="4" set audio_source=mic-unprocessed
if "%audio_source_choice%"=="5" set audio_source=mic-camcorder
if "%audio_source_choice%"=="6" set audio_source=mic-voice-recognition
if "%audio_source_choice%"=="7" set audio_source=mic-voice-communication

call :save_config_item default_audio_source %audio_source%
echo 默认音频源已保存为：%audio_source%
set default_audio_source=%audio_source%
)

pause
goto default_settings

REM 设置默认设备
:set_default_device
cls
echo 可用设备：
"%adb_path%" devices > devices.txt
type devices.txt | findstr /v "List"

echo.
if not "%default_device%"=="" (
echo 当前默认设备：%default_device%
)
echo 请输入设备序列号，或按回车返回
set /p device_serial_input=设备序列号：

if not "%device_serial_input%"=="" (
set device_serial=%device_serial_input%
echo 已选择设备：%device_serial%

REM 询问是否保存为默认设备
echo.
echo 是否将此设置为默认设备？(y/n)
set /p save_as_default=选择：
if /i "%save_as_default%"=="y" (
    echo 正在保存默认设备...
    if exist "%config_file%" (
        findstr /v "default_device=" "%config_file%" > "%config_file%.tmp"
        echo default_device=%device_serial% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo default_device=%device_serial% > "%config_file%"
    )
    echo 默认设备已保存。
)
pause
goto main_menu
) else if not "%default_device%"=="" (
echo 使用默认设备：%default_device%
set device_serial=%default_device%
pause
goto main_menu
) else (
goto main_menu
)

REM 增强音频
:enhance_audio
cls
echo 音频增强设置

REM 音频比特率设置
set audio_bitrate=
if not "%default_audio_bitrate%"=="" (
echo 默认音频比特率：%default_audio_bitrate%，按回车使用默认值
) else (
echo 默认音频比特率：8M，按回车使用默认值或输入自定义值
)
echo 推荐范围：
echo - 低比特率：64K-128K（网络较差时）
echo - 标准比特率：128K-256K（平衡音质和带宽）
echo - 高比特率：256K-320K（更好的音质，但需要更多带宽）
echo - 极致比特率：8M（非常好的音质，但需要很多带宽）
echo 提示：比特率越高，音质和音量通常越好，但需要更稳定的连接
set /p temp_bitrate=输入音频比特率（例如：128K, 256K, 320K, 1M）：
if not "%temp_bitrate%"=="" (
set audio_bitrate=%temp_bitrate%
) else if not "%default_audio_bitrate%"=="" (
echo 使用默认音频比特率：%default_audio_bitrate%
set audio_bitrate=%default_audio_bitrate%
) else (
echo 使用默认音频比特率：8M
set audio_bitrate=8M
)

REM 询问是否保存为默认音频比特率
echo.
echo 是否将此设置为默认音频比特率？(y/n)
set /p save_as_default=选择：
if /i "%save_as_default%"=="y" (
    echo 正在保存默认音频比特率...
    if exist "%config_file%" (
        findstr /v "default_audio_bitrate=" "%config_file%" > "%config_file%.tmp"
        echo default_audio_bitrate=%audio_bitrate% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo default_audio_bitrate=%audio_bitrate% > "%config_file%"
    )
    echo 默认音频比特率已保存。
)

REM 音频源设置
echo.
set audio_source=
if not "%default_audio_source%"=="" (
echo 默认音频源：%default_audio_source%，按回车使用默认值
) else (
echo 默认音频源：output，按回车使用默认值
)
echo 音频源选项：
echo 1. output: 转发整个音频输出，并禁用设备上的播放
echo 2. playback: 捕获音频播放
echo 3. mic: 捕获麦克风
echo 4. mic-unprocessed: 捕获未处理的麦克风声音
echo 5. mic-camcorder: 捕获为视频录制调优的麦克风
echo 6. mic-voice-recognition: 捕获为语音识别调优的麦克风
echo 7. mic-voice-communication: 捕获为语音通信调优的麦克风
set /p audio_source_choice=选择音频源 (1-7，或直接按回车使用默认值)：

if not "%audio_source_choice%"=="" (
if "%audio_source_choice%"=="1" set audio_source=output
if "%audio_source_choice%"=="2" set audio_source=playback
if "%audio_source_choice%"=="3" set audio_source=mic
if "%audio_source_choice%"=="4" set audio_source=mic-unprocessed
if "%audio_source_choice%"=="5" set audio_source=mic-camcorder
if "%audio_source_choice%"=="6" set audio_source=mic-voice-recognition
if "%audio_source_choice%"=="7" set audio_source=mic-voice-communication
) else if not "%default_audio_source%"=="" (
echo 使用默认音频源：%default_audio_source%
set audio_source=%default_audio_source%
) else (
echo 使用默认音频源：output
set audio_source=output
)

REM 询问是否保存为默认音频源
echo.
echo 是否将此设置为默认音频源？(y/n)
set /p save_audio_source=选择：
if /i "%save_audio_source%"=="y" (
    echo 正在保存默认音频源...
    if exist "%config_file%" (
        findstr /v "default_audio_source=" "%config_file%" > "%config_file%.tmp"
        echo default_audio_source=%audio_source% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo default_audio_source=%audio_source% > "%config_file%"
    )
    echo 默认音频源已保存。
)

REM 构建音频参数
echo 正在启动增强音频的连接...
set audio_params=--audio-bit-rate=%audio_bitrate% --audio-source=%audio_source%

if not "%device_serial%"=="" (
start "scrcpy" "%scrcpy_path%" -s %device_serial% %audio_params%
) else (
start "scrcpy" "%scrcpy_path%" %audio_params%
)
goto after_start

REM 摄像头镜像
:camera_mirror
cls
echo 摄像头镜像功能（需要Android 12+）
echo 1. 后置摄像头
echo 2. 前置摄像头
set /p camera_choice=选择摄像头 (1-2)：

set camera_facing=back
if "%camera_choice%"=="2" set camera_facing=front

echo 正在启动摄像头镜像（%camera_facing%）...
if not "%device_serial%"=="" (
start "scrcpy" "%scrcpy_path%" -s %device_serial% --video-source=camera --camera-facing=%camera_facing%
) else (
start "scrcpy" "%scrcpy_path%" --video-source=camera --camera-facing=%camera_facing%
)
goto after_start

REM 自定义参数组合
:custom_params
cls
echo 自定义参数设置

REM 使用select_device_function和start_scrcpy函数替换自定义参数连接部分的重复设备选择和启动逻辑，简化代码结构。
:custom_params
cls
echo 自定义参数设置

REM 使用select_device_function进行设备选择
call :select_device_function selected_device
if "%selected_device%"=="" (
    pause
    goto main_menu
)

echo 已选择设备：%selected_device%

goto custom_params_settings

:custom_params_settings
echo.
echo 自定义参数设置

REM 分辨率设置
set custom_resolution=
if not "%default_resolution%"=="" (
echo 默认分辨率：%default_resolution%，按回车使用默认值
) else (
echo 默认无限制分辨率，按回车跳过
)
set /p temp_res=输入最大分辨率（例如：1080, 720）：
if not "%temp_res%"=="" set custom_resolution=%temp_res%

REM 帧率设置
set custom_fps=
if not "%default_fps%"=="" (
echo 默认帧率：%default_fps%，按回车使用默认值
) else (
echo 默认无限制帧率，按回车跳过
)
set /p temp_fps=输入最大帧率（例如：30, 60）：
if not "%temp_fps%"=="" set custom_fps=%temp_fps%

REM 音频设置
echo 禁用音频？(y/n，默认：启用)
set /p disable_audio_input=选择：
set audio_param=
if /i "%disable_audio_input%"=="y" set audio_param=--no-audio

REM 音频比特率设置
set custom_audio_bitrate=
if not "%default_audio_bitrate%"=="" (
echo 默认音频比特率：%default_audio_bitrate%，按回车使用默认值或跳过
) else (
echo 默认无自定义音频比特率，按回车跳过
)
echo 推荐范围：64K-320K（默认8M）
echo 提示：增加比特率可以提升音质和音量
set /p temp_audio_bitrate=输入音频比特率（例如：128K, 256K, 320K, 1M）：
if not "%temp_audio_bitrate%"=="" set custom_audio_bitrate=%temp_audio_bitrate%

REM 屏幕状态设置
echo 关闭设备屏幕？(y/n，默认：开启)
set /p turn_screen_off_input=选择：
set screen_param=
if /i "%turn_screen_off_input%"=="y" set screen_param=--turn-screen-off

REM 全屏设置
echo 全屏模式启动？(y/n，默认：窗口模式)
set /p fullscreen_input=选择：
set fullscreen_param=
if /i "%fullscreen_input%"=="y" set fullscreen_param=--fullscreen

REM 保持唤醒设置
echo 保持设备唤醒？(y/n，默认：正常)
set /p stay_awake_input=选择：
set awake_param=
if /i "%stay_awake_input%"=="y" set awake_param=--stay-awake

REM 构建参数
echo.
echo 正在构建自定义参数...
set params=
if not "%custom_resolution%"=="" set params=%params% --max-size=%custom_resolution%
if not "%custom_fps%"=="" set params=%params% --max-fps=%custom_fps%
if not "%custom_audio_bitrate%"=="" set params=%params% --audio-bit-rate=%custom_audio_bitrate%
set params=%params% %audio_param%
set params=%params% %screen_param%
set params=%params% %fullscreen_param%
set params=%params% %awake_param%

echo 自定义参数：%params%

REM 启动scrcpy
call :start_scrcpy %selected_device% "%params%"
goto after_start

REM ===========================
REM 无线连接设置
REM ===========================
:wireless_connect
cls
echo ===========================
echo        无线连接设置        
echo ===========================
echo 1. 初始化无线连接（首次需要USB连接）
echo 2. 通过已保存的IP连接设备
echo 3. 手动输入IP连接设备
echo 4. 断开无线连接
echo 5. 返回主菜单
echo ==========================================================================
set /p wireless_choice=请输入选项 (1-5)：

if "%wireless_choice%"=="1" goto init_wireless
if "%wireless_choice%"=="2" goto connect_saved_ip
if "%wireless_choice%"=="3" goto connect_manual_ip
if "%wireless_choice%"=="4" goto disconnect_wireless
if "%wireless_choice%"=="5" goto main_menu

echo 无效选项。请重试。
pause
goto wireless_connect

:init_wireless
echo 正在检查USB连接的设备...
"%adb_path%" devices | findstr /r "device$" >nul
if errorlevel 1 (
    echo 未检测到USB连接的设备，请先用数据线连接手机。
    pause
    goto wireless_connect
)

echo 请确保设备已连接到Wi-Fi网络。

echo 正在获取设备IP地址...
set device_ip=

:: 方法1：从 wlan0 获取 inet 字段
for /f "tokens=2 delims= " %%a in ('cmd /c "%adb_path%" shell ip -f inet addr show wlan0 ^| findstr inet') do (
    set device_ip=%%a
)

:: 如果方法1失败，尝试备选方案（有些设备可能使用不同的网络接口名称）
if "!device_ip!"=="" (
    echo 尝试使用备选方法获取IP地址...
    for /f "tokens=2 delims= " %%a in ('cmd /c "%adb_path%" shell ip -f inet addr show ^| findstr "wlan\|inet"') do (
        set device_ip=%%a
    )
)

:: 兜底，手动输入
if "!device_ip!"=="" (
    echo 自动获取IP失败，请手动输入设备WiFi IP（如：192.168.0.110）
    set /p device_ip=请输入设备IP：
    :: 验证IP地址格式
    echo !device_ip! | findstr /r "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
    if errorlevel 1 (
        echo 请输入有效的IP地址！
        pause
        goto wireless_connect
    )
) else (
    :: 清理IP地址，去除掩码部分（如192.168.1.100/24 -> 192.168.1.100）
    for /f "tokens=1 delims=/" %%i in ("!device_ip!") do set device_ip=%%i
)

echo 检测到设备IP: !device_ip!

echo 正在将ADB切换到TCP/IP模式...
"%adb_path%" tcpip 5555

echo.
echo 请断开USB连接，然后按任意键继续...
pause >nul

:: 使用 device_ip 进行 adb connect
"%adb_path%" connect !device_ip!:5555
if errorlevel 1 (
    echo 无线连接失败，请检查IP是否正确或设备是否在同一WiFi网络
    pause
    goto wireless_connect
)

echo 无线连接成功！
set device_serial=

:: 保存默认IP
set /p save_wireless=是否将此设备IP保存为默认无线设备？(y/n)：
if /i "%save_wireless%"=="y" (
    findstr /v "default_wireless_ip=" "%config_file%" > "%config_file%.tmp"
    echo default_wireless_ip=!device_ip! >> "%config_file%.tmp"
    move /y "%config_file%.tmp" "%config_file%" >nul
    echo 默认无线设备IP已保存。
)
pause
goto wireless_connect

:connect_saved_ip
if "%default_wireless_ip%"=="" (
    echo 未找到已保存的无线设备IP。
    pause
    goto wireless_connect
)
echo 正在通过已保存的IP连接设备：%default_wireless_ip%
echo 调试信息：原始IP地址=[%default_wireless_ip%]
:: 去除IP地址中的所有空格
set clean_ip=%default_wireless_ip: =%
echo 调试信息：清理后的IP地址=[%clean_ip%]
"%adb_path%" connect %clean_ip%:5555
if errorlevel 1 (
    echo 连接失败：请确保设备已开启且在同一WiFi网络中
    pause
    goto wireless_connect
)
echo 无线连接成功！
set device_serial=
pause
goto wireless_connect

:connect_manual_ip
echo 请输入设备的IP地址（如：192.168.1.100）
set /p manual_ip=IP地址：
if "%manual_ip%"=="" (
    pause
    goto wireless_connect
)
echo 正在通过IP %manual_ip% 连接设备...
"%adb_path%" connect %manual_ip%:5555
if errorlevel 1 (
    echo 连接失败：请确保设备已开启且在同一WiFi网络中
    pause
    goto wireless_connect
)
echo 无线连接成功！
set device_serial=
set /p save_manual_ip=是否保存此IP地址？(y/n)：
if /i "%save_manual_ip%"=="y" (
    findstr /v "default_wireless_ip=" "%config_file%" > "%config_file%.tmp"
    echo default_wireless_ip=%manual_ip% >> "%config_file%.tmp"
    move /y "%config_file%.tmp" "%config_file%" >nul
    echo 默认无线设备IP已保存。
)
pause
goto wireless_connect

:disconnect_wireless
echo 正在断开所有无线连接...
"%adb_path%" disconnect
echo 已断开所有无线连接。
pause
goto wireless_connect


REM 显示快捷键
:show_shortcuts
cls
echo ===========================
echo         SCRCPY 快捷键       
echo ===========================
echo 注意：默认MOD键是Alt或Super键
echo.
echo MOD+f          - 切换全屏模式
echo MOD+h / 鼠标中键 - 点击HOME
echo MOD+b / 退格键 / 鼠标右键 - 点击BACK
echo MOD+s          - 点击APP_SWITCH
echo MOD+m          - 点击MENU
echo MOD+p          - 点击POWER（开关屏幕）
echo MOD+o          - 关闭设备屏幕（保持镜像）打开需要MOD+shift+o
echo MOD+r          - 旋转设备屏幕
echo MOD+n          - 展开通知面板
echo MOD+c          - 复制到剪贴板
echo MOD+v          - 将电脑剪贴板内容粘贴到设备
echo MOD+g          - 将窗口调整为1:1比例
echo MOD+w          - 调整窗口以移除黑边
echo Ctrl+点击并拖动 - 捏合缩放和旋转
echo 拖动APK文件     - 安装应用
echo 拖动其他文件    - 推送文件到设备
echo ===========================
pause
goto main_menu

REM ===========================
REM 默认参数设置菜单
REM ===========================
:default_settings
cls
echo ==========================================================================
echo                        默认参数设置                                
echo ==========================================================================
echo 1. 设置默认分辨率
echo 2. 设置默认帧率
echo 3. 设置默认音频参数
echo 4. 设置默认设备
echo 5. 显示快捷键
echo 6. 返回主菜单
echo ==========================================================================
set /p settings_choice=请输入选项 (1-6)：

if "%settings_choice%"=="1" goto set_default_resolution
if "%settings_choice%"=="2" goto set_default_fps
if "%settings_choice%"=="3" goto set_default_audio
if "%settings_choice%"=="4" goto set_default_device
if "%settings_choice%"=="5" goto show_shortcuts
if "%settings_choice%"=="6" goto main_menu

echo 无效选项。请重试。
pause
goto default_settings

REM 设置默认分辨率
:set_default_resolution
cls
echo 设置默认分辨率（例如：1080, 720, 480）
if not "%default_resolution%"=="" (
echo 当前默认分辨率：%default_resolution%
)
set /p resolution=分辨率：

if "%resolution%"=="" (
echo 未提供分辨率，保持原设置。
) else (
call :save_config_item default_resolution %resolution%
echo 默认分辨率已保存为：%resolution%
set default_resolution=%resolution%
)
pause
goto default_settings

REM 设置默认帧率
:set_default_fps
cls
echo 设置默认帧率（例如：30, 60）
if not "%default_fps%"=="" (
echo 当前默认帧率：%default_fps%
)
set /p fps=帧率：

if "%fps%"=="" (
echo 未提供帧率，保持原设置。
) else (
call :save_config_item default_fps %fps%
echo 默认帧率已保存为：%fps%
set default_fps=%fps%
)
pause
goto default_settings

REM 设置默认音频参数
:set_default_audio
cls
echo 音频参数设置

REM 音频比特率设置
if not "%default_audio_bitrate%"=="" (
echo 当前默认音频比特率：%default_audio_bitrate%
) else (
echo 当前无默认音频比特率设置
)
echo 推荐范围：
echo - 低比特率：64K-128K（网络较差时）
echo - 标准比特率：128K-256K（平衡音质和带宽）
echo - 高比特率：256K-320K（更好的音质，但需要更多带宽）
echo - 极致比特率：8M（非常好的音质，但需要很多带宽）
set /p temp_bitrate=输入音频比特率（例如：128K, 256K, 320K, 1M）：

REM 音频源设置
echo.
if not "%default_audio_source%"=="" (
echo 当前默认音频源：%default_audio_source%
) else (
echo 当前无默认音频源设置
)
echo 音频源选项：
echo 1. output: 转发整个音频输出，并禁用设备上的播放
echo 2. playback: 捕获音频播放
echo 3. mic: 捕获麦克风
echo 4. mic-unprocessed: 捕获未处理的麦克风声音
echo 5. mic-camcorder: 捕获为视频录制调优的麦克风
echo 6. mic-voice-recognition: 捕获为语音识别调优的麦克风
echo 7. mic-voice-communication: 捕获为语音通信调优的麦克风
set /p audio_source_choice=选择音频源 (1-7，或直接按回车使用默认值)：

if not "%temp_bitrate%"=="" (
    echo 正在保存默认音频比特率...
    if exist "%config_file%" (
        findstr /v "default_audio_bitrate=" "%config_file%" > "%config_file%.tmp"
        echo default_audio_bitrate=%temp_bitrate% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo default_audio_bitrate=%temp_bitrate% > "%config_file%"
    )
    echo 默认音频比特率已保存为：%temp_bitrate%
    set default_audio_bitrate=%temp_bitrate%
)

if not "%audio_source_choice%"=="" (
    if "%audio_source_choice%"=="1" set audio_source=output
    if "%audio_source_choice%"=="2" set audio_source=playback
    if "%audio_source_choice%"=="3" set audio_source=mic
    if "%audio_source_choice%"=="4" set audio_source=mic-unprocessed
    if "%audio_source_choice%"=="5" set audio_source=mic-camcorder
    if "%audio_source_choice%"=="6" set audio_source=mic-voice-recognition
    if "%audio_source_choice%"=="7" set audio_source=mic-voice-communication
    
    echo 正在保存默认音频源...
    if exist "%config_file%" (
        findstr /v "default_audio_source=" "%config_file%" > "%config_file%.tmp"
        echo default_audio_source=%audio_source% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo default_audio_source=%audio_source% >> "%config_file%"
    )
    echo 默认音频源已保存为：%audio_source%
    set default_audio_source=%audio_source%
)

pause
goto default_settings

REM 设置默认设备
:set_default_device
cls
echo 可用设备：
"%adb_path%" devices > devices.txt
type devices.txt | findstr /v "List"

if errorlevel 1 (
    echo 未检测到设备。
    pause
    goto default_settings
)

echo.
if not "%default_device%"=="" (
echo 当前默认设备：%default_device%
)

REM 调用设备选择函数，让用户通过序号选择设备
call :select_device_function
if errorlevel 1 (
    echo 设备选择失败。
    pause
    goto default_settings
)

REM 询问是否保存为默认设备
echo.
echo 是否将此设置为默认设备？(y/n)
set /p save_as_default=选择：
if /i "%save_as_default%"=="y" (
call :save_config_item default_device %selected_device%
echo 默认设备已保存为：%selected_device%
set default_device=%selected_device%
)
pause
goto default_settings

REM 启动后处理
:after_start
pause
goto main_menu




REM ==================================================
REM 公共函数定义
REM ==================================================

REM 函数: 选择设备
REM 参数: 无
REM 返回: selected_device 变量将包含所选设备的序列号
:select_device_function
    cls
    echo 可用设备：
    "%adb_path%" devices > devices.txt
    type devices.txt | findstr /v "List"
    
    if errorlevel 1 (
        echo 未检测到设备。请确保已启用USB调试并连接设备。
        set selected_device=
        pause
        exit /b 1
    )
    
    REM 统计设备数量
    set device_count=0
    for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
        set /a device_count+=1
    )
    
    REM 如果只有一个设备，直接选择
    if %device_count% equ 1 (
        for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
            set selected_device=%%a
        )
        echo 自动选择设备：%selected_device%
        exit /b 0
    )
    
    REM 多个设备，让用户选择
    echo 检测到多个设备，请选择要连接的设备：
    echo.
    set /a counter=1
    for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
        echo !counter!. %%a
        set device_!counter!=%%a
        set /a counter+=1
    )
    echo.
    set /p device_choice=请选择设备 (1-%device_count%)：
    
    if "%device_choice%"=="" (
        echo 未选择设备。
        set selected_device=
        pause
        exit /b 1
    )
    
    call set device_check=%%device_%device_choice%%%
    if defined device_check (
        set /a line_num=%device_choice%
        for /f "tokens=1" %%a in ('type devices.txt ^| findstr /v "List" ^| findstr /v "offline" ^| findstr /r ".*"') do (
            if !line_num! equ 1 (
                set selected_device=%%a
                set line_num=0
            ) else (
                set /a line_num-=1
            )
        )
        echo 已选择设备：!selected_device!
        exit /b 0
    ) else (
        echo 无效选择。
        set selected_device=
        pause
        exit /b 1
    )

REM 函数: 读取配置文件
REM 参数: 无
REM 返回: 所有配置项将被设置为环境变量
:read_config
    if exist "%config_file%" (
        echo 正在加载配置...
        for /f "tokens=1,2 delims==" %%a in ('type "%config_file%"') do (
            if "%%a"=="default_device" set default_device=%%b
            if "%%a"=="default_resolution" set default_resolution=%%b
            if "%%a"=="default_fps" set default_fps=%%b
            if "%%a"=="default_audio_bitrate" set default_audio_bitrate=%%b
            if "%%a"=="default_audio_source" set default_audio_source=%%b
            if "%%a"=="default_wireless_ip" set default_wireless_ip=%%b
        )
    )
    exit /b 0

REM 函数: 保存配置项
REM 参数: 1=配置项名称, 2=配置项值
REM 返回: 无
:save_config_item
    set config_name=%~1
    set config_value=%~2
    
    if exist "%config_file%" (
        findstr /v "%config_name%=" "%config_file%" > "%config_file%.tmp"
        echo %config_name%=%config_value% >> "%config_file%.tmp"
        move /y "%config_file%.tmp" "%config_file%" >nul
    ) else (
        echo %config_name%=%config_value% > "%config_file%"
    )
    exit /b 0

REM 函数: 启动scrcpy
REM 参数: 1=设备序列号, 2=参数列表
REM 返回: 无
:start_scrcpy
    set device=%~1
    set params=%~2
    
    if not "%device%"=="" (
        echo 正在启动scrcpy连接到设备：%device%
        start "scrcpy" "%scrcpy_path%" -s %device% %params%
    ) else (
        echo 正在启动scrcpy...
        start "scrcpy" "%scrcpy_path%" %params%
    )
    exit /b 0

REM ==================================================
REM 退出脚本
REM ==================================================
:exit_script
cls
echo ==========================================================================
echo                        清理ADB进程并退出                                
echo ==========================================================================
echo 正在查找并清理ADB进程...

REM 尝试断开所有无线连接
echo 正在断开无线连接...
"%adb_path%" disconnect

REM 查找并结束adb.exe进程
echo 正在结束adb.exe进程...
taskkill /f /im adb.exe >nul 2>&1

@REM 检查是否还有残留的adb进程
echo 检查是否还有残留的adb进程...
tasklist | findstr /i "adb.exe" >nul
if %errorlevel% equ 0 (
    echo 警告：仍有adb.exe进程在运行，可能需要手动关闭
    echo 您可以尝试以下方法：
    echo 1. 重启电脑
    echo 2. 手动在任务管理器中结束adb.exe进程
) else (
    echo ADB进程已成功清理
)

echo.
echo 按任意键退出...
pause >nul
exit /b 0