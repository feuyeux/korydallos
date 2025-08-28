@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM Alouette TTS - 跨平台分发包打包脚本 (Windows版本)
REM 支持 Android APK/AAB, Windows EXE, Web

title Alouette TTS 跨平台分发包构建工具

REM 获取项目版本信息
for /f "tokens=2 delims= " %%a in ('findstr "version:" pubspec.yaml') do set VERSION_FULL=%%a
for /f "tokens=1 delims=+" %%a in ("!VERSION_FULL!") do set VERSION_NAME=%%a
for /f "tokens=2 delims=+" %%a in ("!VERSION_FULL!") do set BUILD_NUMBER=%%a

echo ==========================================
echo     Alouette TTS 跨平台分发包构建工具
echo ==========================================
echo 版本: !VERSION_NAME!+!BUILD_NUMBER!
echo.

REM 创建输出目录
set OUTPUT_DIR=dist
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do set DATE=%%c%%a%%b
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set TIME=%%a%%b
set TIME=!TIME: =0!
set TIME=!TIME::=!
set RELEASE_DIR=!OUTPUT_DIR!\release_!VERSION_NAME!_!DATE!_!TIME!

echo 创建输出目录: !RELEASE_DIR!
if not exist "!RELEASE_DIR!" mkdir "!RELEASE_DIR!"

REM 显示帮助信息
:show_help
if "%1"=="help" (
    echo 用法: %0 [选项]
    echo.
    echo 选项:
    echo   help              显示帮助信息
    echo   clean             构建前清理
    echo   all               构建所有支持的平台
    echo   android-apk       构建Android APK
    echo   android-aab       构建Android AAB
    echo   windows           构建Windows EXE
    echo   web               构建Web版本
    echo.
    echo 示例:
    echo   %0 all                    # 构建所有平台
    echo   %0 android-apk            # 只构建Android APK
    echo   %0 clean windows          # 清理后构建Windows版本
    echo.
    pause
    exit /b 0
)

REM 解析命令行参数
set CLEAN_FLAG=false
set BUILD_ALL=false
set BUILD_ANDROID_APK=false
set BUILD_ANDROID_AAB=false
set BUILD_WINDOWS=false
set BUILD_WEB=false

:parse_args
if "%1"=="" goto end_parse
if "%1"=="clean" set CLEAN_FLAG=true
if "%1"=="all" set BUILD_ALL=true
if "%1"=="android-apk" set BUILD_ANDROID_APK=true
if "%1"=="android-aab" set BUILD_ANDROID_AAB=true
if "%1"=="windows" set BUILD_WINDOWS=true
if "%1"=="web" set BUILD_WEB=true
shift
goto parse_args
:end_parse

REM 如果没有指定任何平台，显示帮助并构建所有支持的平台
if "%BUILD_ALL%"=="false" if "%BUILD_ANDROID_APK%"=="false" if "%BUILD_ANDROID_AAB%"=="false" if "%BUILD_WINDOWS%"=="false" if "%BUILD_WEB%"=="false" (
    set BUILD_ALL=true
    echo 未指定构建平台，将构建所有支持的平台
    echo.
)

REM 设置构建全部平台的标志
if "%BUILD_ALL%"=="true" (
    set BUILD_ANDROID_APK=true
    set BUILD_ANDROID_AAB=true
    set BUILD_WINDOWS=true
    set BUILD_WEB=true
)

REM 检查Flutter是否已安装
flutter --version >nul 2>&1
if errorlevel 1 (
    echo 错误: 未找到Flutter命令，请确保Flutter已正确安装并添加到PATH
    pause
    exit /b 1
)

REM 检查是否在Flutter项目根目录
if not exist "pubspec.yaml" (
    echo 错误: 请在Flutter项目根目录下运行此脚本
    pause
    exit /b 1
)

REM 清理构建缓存
if "%CLEAN_FLAG%"=="true" (
    echo 清理构建缓存...
    flutter clean
    flutter pub get
    echo 清理完成
    echo.
)

REM 初始化构建信息文件
echo Alouette TTS v!VERSION_NAME! 构建文件: > "!RELEASE_DIR!\build_info.txt"
echo. >> "!RELEASE_DIR!\build_info.txt"

set SUCCESS_COUNT=0
set TOTAL_COUNT=0

REM 构建Android APK
if "%BUILD_ANDROID_APK%"=="true" (
    echo 构建Android APK...
    set /a TOTAL_COUNT+=1
    
    flutter build apk --release --split-per-abi
    if not errorlevel 1 (
        echo Android APK构建成功
        
        REM 复制APK文件到输出目录
        if not exist "!RELEASE_DIR!\android" mkdir "!RELEASE_DIR!\android"
        copy "build\app\outputs\flutter-apk\app-*.apk" "!RELEASE_DIR!\android\" >nul 2>&1
        if errorlevel 1 (
            copy "build\app\outputs\flutter-apk\app-release.apk" "!RELEASE_DIR!\android\alouette-tts-!VERSION_NAME!.apk" >nul 2>&1
        )
        
        REM 生成文件信息
        for %%f in ("!RELEASE_DIR!\android\*.apk") do (
            echo   - %%~nxf >> "!RELEASE_DIR!\build_info.txt"
        )
        
        echo APK文件已保存到: !RELEASE_DIR!\android\
        set /a SUCCESS_COUNT+=1
    ) else (
        echo Android APK构建失败
    )
    echo.
)

REM 构建Android AAB
if "%BUILD_ANDROID_AAB%"=="true" (
    echo 构建Android AAB...
    set /a TOTAL_COUNT+=1
    
    flutter build appbundle --release
    if not errorlevel 1 (
        echo Android AAB构建成功
        
        REM 复制AAB文件到输出目录
        if not exist "!RELEASE_DIR!\android" mkdir "!RELEASE_DIR!\android"
        copy "build\app\outputs\bundle\release\app-release.aab" "!RELEASE_DIR!\android\alouette-tts-!VERSION_NAME!.aab"
        
        REM 生成文件信息
        echo   - alouette-tts-!VERSION_NAME!.aab >> "!RELEASE_DIR!\build_info.txt"
        
        echo AAB文件已保存到: !RELEASE_DIR!\android\
        set /a SUCCESS_COUNT+=1
    ) else (
        echo Android AAB构建失败
    )
    echo.
)

REM 构建Windows EXE
if "%BUILD_WINDOWS%"=="true" (
    echo 构建Windows EXE...
    set /a TOTAL_COUNT+=1
    
    flutter build windows --release
    if not errorlevel 1 (
        echo Windows EXE构建成功
        
        REM 复制Windows文件到输出目录
        if not exist "!RELEASE_DIR!\windows" mkdir "!RELEASE_DIR!\windows"
        
        REM 检查源文件是否存在
        if exist "build\windows\x64\runner\Release\alouette-tts.exe" (
            echo Copying files from build\windows\x64\runner\Release\...
            xcopy "build\windows\x64\runner\Release\*" "!RELEASE_DIR!\windows\" /E /I /Y
            echo Windows files copied successfully
        ) else (
            echo ERROR: Could not find built exe file
            echo Looking for files in build directory...
            dir "build\windows\x64\runner\" /s
            goto skip_windows_zip
        )
        
        REM 创建ZIP压缩包（如果有7z或WinRAR）
        pushd "!RELEASE_DIR!"
        where 7z >nul 2>&1
        if not errorlevel 1 (
            7z a "alouette-tts-windows-!VERSION_NAME!.zip" windows\ >nul
            echo 已创建ZIP压缩包
        ) else (
            where winrar >nul 2>&1
            if not errorlevel 1 (
                winrar a "alouette-tts-windows-!VERSION_NAME!.zip" windows\ >nul
                echo 已创建ZIP压缩包
            ) else (
                echo 注意: 未找到7z或WinRAR，跳过ZIP压缩包创建
            )
        )
        popd
        
        :skip_windows_zip
        REM 生成文件信息
        echo   - windows/ >> "!RELEASE_DIR!\build_info.txt"
        if exist "!RELEASE_DIR!\alouette-tts-windows-!VERSION_NAME!.zip" (
            echo   - alouette-tts-windows-!VERSION_NAME!.zip >> "!RELEASE_DIR!\build_info.txt"
        )
        
        echo Windows文件已保存到: !RELEASE_DIR!\windows\
        set /a SUCCESS_COUNT+=1
    ) else (
        echo Windows构建失败
    )
    echo.
)

REM 构建Web
if "%BUILD_WEB%"=="true" (
    echo 构建Web版本...
    set /a TOTAL_COUNT+=1
    
    flutter build web --release
    if not errorlevel 1 (
        echo Web构建成功
        
        REM 复制Web文件到输出目录
        if not exist "!RELEASE_DIR!\web" mkdir "!RELEASE_DIR!\web"
        xcopy "build\web\*" "!RELEASE_DIR!\web\" /E /I /Y >nul
        
        REM 创建ZIP压缩包（如果有7z或WinRAR）
        cd "!RELEASE_DIR!"
        where 7z >nul 2>&1
        if not errorlevel 1 (
            7z a "alouette-tts-web-!VERSION_NAME!.zip" web\ >nul
        ) else (
            where winrar >nul 2>&1
            if not errorlevel 1 (
                winrar a "alouette-tts-web-!VERSION_NAME!.zip" web\ >nul
            )
        )
        cd ..
        
        REM 生成文件信息
        echo   - web/ >> "!RELEASE_DIR!\build_info.txt"
        if exist "!RELEASE_DIR!\alouette-tts-web-!VERSION_NAME!.zip" (
            echo   - alouette-tts-web-!VERSION_NAME!.zip >> "!RELEASE_DIR!\build_info.txt"
        )
        
        echo Web文件已保存到: !RELEASE_DIR!\web\
        set /a SUCCESS_COUNT+=1
    ) else (
        echo Web构建失败
    )
    echo.
)

REM 生成构建报告
echo 生成构建报告...

(
echo # Alouette TTS 发布包 v!VERSION_NAME!
echo.
echo 构建时间: %date% %time%
echo 版本号: !VERSION_NAME!+!BUILD_NUMBER!
echo.
echo ## 包含文件
echo.
) > "!RELEASE_DIR!\README.md"

type "!RELEASE_DIR!\build_info.txt" >> "!RELEASE_DIR!\README.md"

(
echo.
echo ## 安装说明
echo.
echo ### Android
echo - APK文件可直接安装
echo - AAB文件需要通过Google Play Console上传
echo.
echo ### Windows
echo - 解压zip文件并运行alouette_tts.exe
echo - 或直接运行windows文件夹中的exe文件
echo.
echo ### Web
echo - 解压zip文件并部署到Web服务器
echo - 或直接访问index.html
echo.
echo ## 系统要求
echo.
echo - Android: API 21+ ^(Android 5.0+^)
echo - Windows: Windows 7+
echo.
) >> "!RELEASE_DIR!\README.md"

echo 构建报告已生成: !RELEASE_DIR!\README.md

REM 构建总结
echo ==========================================
echo            构建完成统计
echo ==========================================
echo 成功: !SUCCESS_COUNT!/!TOTAL_COUNT!
echo 输出目录: !RELEASE_DIR!
echo.

if !SUCCESS_COUNT! equ !TOTAL_COUNT! (
    echo 🎉 所有构建任务成功完成！
    echo.
) else (
    echo ⚠️  部分构建任务失败，请检查错误信息
    echo.
)

pause
