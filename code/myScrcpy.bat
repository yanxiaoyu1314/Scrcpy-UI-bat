@echo off
REM 设置scrcpy和adb的路径
set srcpy_path=scrcpy.exe
set sadb_path=adb.exe

REM 配置文件路径
set config_file=scrcpy-config.ini
REM 定义当前版本字符串
set current_version=0.2.0
set version_url=https://raw.githubusercontent.com/yanxiaoyu1314/Scrcpy-UI-bat/refs/heads/main/info.json


echo ↓↓↓当前版本（%current_version%）更新内容↓↓↓
echo 这是初始化版本
echo 完成USB链接方式
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
     Write-Host ('检查更新失败: {0}' -f $_.Exception.Message); ^
     exit 3 ^
 }"

REM 根据退出码处理
pause


REM 如果配置文件存在则加载
if exist "%config_file%" (
echo 正在加载配置...
for /f "tokens=1,2 delims==" %%a in ('type "%config_file%"') do (
if "%%a"=="default_device" set default_device=%%b
if "%%a"=="default_resolution" set default_resolution=%%b
if "%%a"=="default_fps" set default_fps=%%b
)
)

REM 检查scrcpy是否存在
if not exist "%srcpy_path%" (
echo 错误：找不到scrcpy.exe。请确保它在scrcpy文件夹中。
pause
exit /b 1
)

REM 检查adb是否存在
if not exist "%sadb_path%" (
echo 错误：找不到adb.exe。请确保它在scrcpy文件夹中。
pause
exit /b 1
)

REM 设备序列号全局变量
set device_serial=

echo 正在检查已连接的设备...
"%sadb_path%" devices
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


echo 当前已连接设备：
"%sadb_path%" devices | findstr /v "List"
if errorlevel 1 (
echo 未检测到设备。请确保已启用USB调试并连接设备。
echo 提示：在Android设备上，进入设置 ^> 关于手机 ^> 点击版本号7次以启用开发者选项
echo 然后进入设置 ^> 开发者选项 ^> 启用USB调试
)

echo.
echo ^[功能选择^]
echo 1. 基本连接（无特殊参数）
echo 2. 设置最大分辨率（提升性能）
echo 3. 设置最大帧率（更流畅体验）
echo 4. 禁用音频（减少延迟）
echo 5. 关闭设备屏幕（保持镜像）
echo 6. 开始屏幕录制
echo 7. 全屏模式启动
echo 8. 保持设备唤醒
echo 9. 显示快捷键
echo 10. 选择特定设备
echo 11. 使用摄像头镜像（Android 12^+）
echo 12. 自定义参数组合
echo 13. 退出
echo ==========================================================================
set /p choice=请输入选项 (1-13)：

REM 根据用户选择执行相应操作
if "%choice%"=="1" goto basic_connect
if "%choice%"=="2" goto set_resolution
if "%choice%"=="3" goto set_fps
if "%choice%"=="4" goto disable_audio
if "%choice%"=="5" goto turn_screen_off
if "%choice%"=="6" goto start_recording
if "%choice%"=="7" goto fullscreen
if "%choice%"=="8" goto stay_awake
if "%choice%"=="9" goto show_shortcuts
if "%choice%"=="10" goto select_device
if "%choice%"=="11" goto camera_mirror
if "%choice%"=="12" goto custom_params
if "%choice%"=="13" exit /b 0

echo 无效选项。请重试。
pause
goto main_menu

REM 基本连接
:basic_connect
echo 正在启动基本连接...
if not "%device_serial%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial%
) else (
start "scrcpy" "%srcpy_path%"
)
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
echo default_resolution=%resolution% > "%config_file%"
if not "%default_device%"=="" (
echo default_device=%default_device% >> "%config_file%"
)
if not "%default_fps%"=="" (
echo default_fps=%default_fps% >> "%config_file%"
)
echo 默认分辨率已保存。
)
)

echo 正在启动指定分辨率的连接...
if not "%device_serial%"=="" (
if not "%resolution%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% --max-size=%resolution%
) else (
start "scrcpy" "%srcpy_path%" -s %device_serial%
)
) else (
if not "%resolution%"=="" (
start "scrcpy" "%srcpy_path%" --max-size=%resolution%
) else (
start "scrcpy" "%srcpy_path%"
)
)
goto after_start

REM 设置帧率连接
:set_fps
cls
echo 设置最大帧率（例如：30, 60）
if not "%default_fps%"=="" (
echo 提示：默认帧率为 %default_fps%，按回车使用默认值
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
echo default_fps=%fps% > "%config_file%"
if not "%default_device%"=="" (
echo default_device=%default_device% >> "%config_file%"
)
if not "%default_resolution%"=="" (
echo default_resolution=%default_resolution% >> "%config_file%"
)
echo 默认帧率已保存。
)
)

echo 正在启动指定帧率的连接...
if not "%device_serial%"=="" (
if not "%fps%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% --max-fps=%fps%
) else (
start "scrcpy" "%srcpy_path%" -s %device_serial%
)
) else (
if not "%fps%"=="" (
start "scrcpy" "%srcpy_path%" --max-fps=%fps%
) else (
start "scrcpy" "%srcpy_path%"
)
)
goto after_start

REM 禁用音频连接
:disable_audio
echo 正在启动禁用音频的连接...
if not "%device_serial%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% --no-audio
) else (
start "scrcpy" "%srcpy_path%" --no-audio
)
goto after_start

REM 关闭设备屏幕
:turn_screen_off
echo 正在启动连接并关闭设备屏幕...
if not "%device_serial%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% --turn-screen-off
) else (
start "scrcpy" "%srcpy_path%" --turn-screen-off
)
goto after_start

REM 开始屏幕录制
:start_recording
cls
echo 请输入录制文件名（默认：scrcpy-record.mp4）
set /p record_file=文件名：
if "%record_file%"=="" set record_file=scrcpy-record.mp4
echo 正在开始录制...
if not "%device_serial%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% --record="%record_file%"
) else (
start "scrcpy" "%srcpy_path%" --record="%record_file%"
)
goto after_start

REM 全屏模式启动
:fullscreen
echo 正在全屏模式启动...
if not "%device_serial%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% --fullscreen
) else (
start "scrcpy" "%srcpy_path%" --fullscreen
)
goto after_start

REM 保持设备唤醒
:stay_awake
echo 正在启动并保持设备唤醒...
if not "%device_serial%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% --stay-awake
) else (
start "scrcpy" "%srcpy_path%" --stay-awake
)
goto after_start

REM 选择特定设备
:select_device
cls
echo 可用设备：
"%sadb_path%" devices > devices.txt
type devices.txt | findstr /v "List"

echo.
echo 请输入设备序列号，或按回车返回主菜单
if not "%default_device%"=="" (
echo 提示：默认设备是 %default_device%，按回车使用默认值
)
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
echo default_device=%device_serial% > "%config_file%"
if not "%default_resolution%"=="" (
echo default_resolution=%default_resolution% >> "%config_file%"
)
if not "%default_fps%"=="" (
echo default_fps=%default_fps% >> "%config_file%"
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
start "scrcpy" "%srcpy_path%" -s %device_serial% --video-source=camera --camera-facing=%camera_facing%
) else (
start "scrcpy" "%srcpy_path%" --video-source=camera --camera-facing=%camera_facing%
)
goto after_start

REM 自定义参数组合
:custom_params
cls
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
set params=%params% %audio_param%
set params=%params% %screen_param%
set params=%params% %fullscreen_param%
set params=%params% %awake_param%

echo 自定义参数：%params%

REM 启动scrcpy
echo.
echo 正在启动scrcpy...
if not "%device_serial%"=="" (
start "scrcpy" "%srcpy_path%" -s %device_serial% %params%
) else (
start "scrcpy" "%srcpy_path%" %params%
)
goto after_start

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
echo MOD+o          - 关闭设备屏幕（保持镜像）
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

REM 启动后处理
:after_start
pause
goto main_menu
