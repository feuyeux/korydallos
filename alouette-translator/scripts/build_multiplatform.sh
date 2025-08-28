#!/bin/bash

# Alouette TTS - 跨平台分发包打包脚本
# 支持 Android APK/AAB, iOS IPA, macOS APP, Windows EXE, Linux

set -e  # 遇到错误时退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 获取项目版本信息
VERSION=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
BUILD_NUMBER=$(echo $VERSION | cut -d'+' -f2)
VERSION_NAME=$(echo $VERSION | cut -d'+' -f1)

echo -e "${BLUE}===========================================${NC}"
echo -e "${BLUE}    Alouette TTS 跨平台分发包构建工具    ${NC}"
echo -e "${BLUE}===========================================${NC}"
echo -e "${GREEN}版本: ${VERSION_NAME}+${BUILD_NUMBER}${NC}"
echo ""

# 创建输出目录
OUTPUT_DIR="dist"
DATE=$(date +"%Y%m%d_%H%M%S")
RELEASE_DIR="${OUTPUT_DIR}/release_${VERSION_NAME}_${DATE}"

echo -e "${YELLOW}创建输出目录: ${RELEASE_DIR}${NC}"
mkdir -p "${RELEASE_DIR}"

# 函数：显示帮助信息
show_help() {
    echo "用法: $0 [选项] [平台...]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -c, --clean    构建前清理"
    echo "  -a, --all      构建所有支持的平台"
    echo "  --android-apk  构建Android APK"
    echo "  --android-aab  构建Android AAB"
    echo "  --ios          构建iOS IPA (需要macOS)"
    echo "  --macos        构建macOS APP"
    echo "  --windows      构建Windows EXE (需要Windows)"
    echo "  --linux        构建Linux"
    echo "  --web          构建Web版本"
    echo ""
    echo "示例:"
    echo "  $0 --all                    # 构建所有平台"
    echo "  $0 --android-apk --ios      # 只构建Android APK和iOS"
    echo "  $0 -c --android-apk         # 清理后构建Android APK"
    echo ""
}

# 函数：清理构建缓存
clean_build() {
    echo -e "${YELLOW}清理构建缓存...${NC}"
    flutter clean
    flutter pub get
    echo -e "${GREEN}清理完成${NC}"
}

# 函数：构建Android APK
build_android_apk() {
    echo -e "${YELLOW}构建Android APK...${NC}"
    
    flutter build apk --release --split-per-abi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Android APK构建成功${NC}"
        
        # 复制APK文件到输出目录
        mkdir -p "${RELEASE_DIR}/android"
        cp build/app/outputs/flutter-apk/app-*.apk "${RELEASE_DIR}/android/" 2>/dev/null || {
            cp build/app/outputs/flutter-apk/app-release.apk "${RELEASE_DIR}/android/alouette-translator-${VERSION_NAME}.apk" 2>/dev/null
        }
        
        # 生成文件信息
        cd "${RELEASE_DIR}/android"
        for apk in *.apk; do
            if [ -f "$apk" ]; then
                size=$(ls -lh "$apk" | awk '{print $5}')
                echo "  - $apk (${size})" >> ../build_info.txt
            fi
        done
        cd - > /dev/null
        
        echo -e "${GREEN}APK文件已保存到: ${RELEASE_DIR}/android/${NC}"
    else
        echo -e "${RED}Android APK构建失败${NC}"
        return 1
    fi
}

# 函数：构建Android AAB
build_android_aab() {
    echo -e "${YELLOW}构建Android AAB...${NC}"
    
    flutter build appbundle --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Android AAB构建成功${NC}"
        
        # 复制AAB文件到输出目录
        mkdir -p "${RELEASE_DIR}/android"
        cp build/app/outputs/bundle/release/app-release.aab "${RELEASE_DIR}/android/alouette-translator-${VERSION_NAME}.aab"
        
        # 生成文件信息
        size=$(ls -lh "${RELEASE_DIR}/android/alouette-translator-${VERSION_NAME}.aab" | awk '{print $5}')
        echo "  - alouette-translator-${VERSION_NAME}.aab (${size})" >> "${RELEASE_DIR}/build_info.txt"
        
        echo -e "${GREEN}AAB文件已保存到: ${RELEASE_DIR}/android/${NC}"
    else
        echo -e "${RED}Android AAB构建失败${NC}"
        return 1
    fi
}

# 函数：构建iOS IPA
build_ios() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}iOS构建需要在macOS系统上进行${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}构建iOS IPA...${NC}"
    
    # 检查必需的iOS环境变量
    if [ -z "${IOS_DEVELOPMENT_TEAM}" ]; then
        echo -e "${RED}错误: 请设置环境变量 IOS_DEVELOPMENT_TEAM${NC}"
        echo -e "${YELLOW}示例: export IOS_DEVELOPMENT_TEAM=YOUR_TEAM_ID${NC}"
        return 1
    fi
    
    if [ -z "${IOS_BUNDLE_IDENTIFIER}" ]; then
        echo -e "${RED}错误: 请设置环境变量 IOS_BUNDLE_IDENTIFIER${NC}"
        echo -e "${YELLOW}示例: export IOS_BUNDLE_IDENTIFIER=com.yourcompany.app${NC}"
        return 1
    fi
    
    echo -e "${BLUE}使用开发团队: ${IOS_DEVELOPMENT_TEAM}${NC}"
    echo -e "${BLUE}使用Bundle ID: ${IOS_BUNDLE_IDENTIFIER}${NC}"
    
    # 构建iOS归档（无代码签名，用于开发测试）
    flutter build ios --release --no-codesign
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}iOS IPA构建成功${NC}"
        
        # 复制IPA文件到输出目录
        mkdir -p "${RELEASE_DIR}/ios"
        cp build/ios/ipa/*.ipa "${RELEASE_DIR}/ios/alouette-translator-${VERSION_NAME}.ipa" 2>/dev/null || {
            echo -e "${YELLOW}未找到IPA文件，可能需要配置签名证书${NC}"
            # 复制Runner.app
            if [ -d "build/ios/iphoneos/Runner.app" ]; then
                cp -r "build/ios/iphoneos/Runner.app" "${RELEASE_DIR}/ios/alouette-translator-${VERSION_NAME}.app"
                echo -e "${GREEN}iOS APP文件已保存${NC}"
            fi
        }
        
        # 生成文件信息
        cd "${RELEASE_DIR}/ios"
        for file in *; do
            if [ -f "$file" ] || [ -d "$file" ]; then
                if [ -f "$file" ]; then
                    size=$(ls -lh "$file" | awk '{print $5}')
                else
                    size=$(du -sh "$file" | awk '{print $1}')
                fi
                echo "  - $file (${size})" >> ../build_info.txt
            fi
        done
        cd - > /dev/null
        
        echo -e "${GREEN}iOS文件已保存到: ${RELEASE_DIR}/ios/${NC}"
    else
        echo -e "${RED}iOS构建失败${NC}"
        return 1
    fi
}

# 函数：构建macOS APP
build_macos() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo -e "${RED}macOS构建需要在macOS系统上进行${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}构建macOS APP...${NC}"
    
    flutter build macos --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}macOS APP构建成功${NC}"
        
        # 复制APP文件到输出目录
        mkdir -p "${RELEASE_DIR}/macos"
        cp -r build/macos/Build/Products/Release/alouette_translator.app "${RELEASE_DIR}/macos/Alouette-TTS-${VERSION_NAME}.app"
        
        # 生成DMG文件（如果有hdiutil）
        if command -v hdiutil &> /dev/null; then
            echo -e "${YELLOW}创建DMG安装包...${NC}"
            cd "${RELEASE_DIR}/macos"
            hdiutil create -volname "Alouette TTS ${VERSION_NAME}" -srcfolder "Alouette-TTS-${VERSION_NAME}.app" -ov -format UDZO "Alouette-TTS-${VERSION_NAME}.dmg"
            cd - > /dev/null
        fi
        
        # 生成文件信息
        cd "${RELEASE_DIR}/macos"
        for file in *; do
            if [ -f "$file" ] || [ -d "$file" ]; then
                if [ -f "$file" ]; then
                    size=$(ls -lh "$file" | awk '{print $5}')
                else
                    size=$(du -sh "$file" | awk '{print $1}')
                fi
                echo "  - $file (${size})" >> ../build_info.txt
            fi
        done
        cd - > /dev/null
        
        echo -e "${GREEN}macOS文件已保存到: ${RELEASE_DIR}/macos/${NC}"
    else
        echo -e "${RED}macOS构建失败${NC}"
        return 1
    fi
}

# 函数：构建Windows EXE
build_windows() {
    echo -e "${YELLOW}构建Windows EXE...${NC}"
    
    flutter build windows --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Windows EXE构建成功${NC}"
        
        # 复制Windows文件到输出目录
        mkdir -p "${RELEASE_DIR}/windows"
        cp -r build/windows/x64/runner/Release/* "${RELEASE_DIR}/windows/"
        
        # 创建ZIP压缩包
        if command -v zip &> /dev/null; then
            cd "${RELEASE_DIR}"
            zip -r "alouette-translator-windows-${VERSION_NAME}.zip" windows/
            cd - > /dev/null
        fi
        
        # 生成文件信息
        size=$(du -sh "${RELEASE_DIR}/windows" | awk '{print $1}')
        echo "  - windows/ (${size})" >> "${RELEASE_DIR}/build_info.txt"
        if [ -f "${RELEASE_DIR}/alouette-translator-windows-${VERSION_NAME}.zip" ]; then
            zip_size=$(ls -lh "${RELEASE_DIR}/alouette-translator-windows-${VERSION_NAME}.zip" | awk '{print $5}')
            echo "  - alouette-translator-windows-${VERSION_NAME}.zip (${zip_size})" >> "${RELEASE_DIR}/build_info.txt"
        fi
        
        echo -e "${GREEN}Windows文件已保存到: ${RELEASE_DIR}/windows/${NC}"
    else
        echo -e "${RED}Windows构建失败${NC}"
        return 1
    fi
}

# 函数：构建Linux
build_linux() {
    echo -e "${YELLOW}构建Linux...${NC}"
    
    flutter build linux --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Linux构建成功${NC}"
        
        # 复制Linux文件到输出目录
        mkdir -p "${RELEASE_DIR}/linux"
        cp -r build/linux/x64/release/bundle/* "${RELEASE_DIR}/linux/"
        
        # 创建tar.gz压缩包
        if command -v tar &> /dev/null; then
            cd "${RELEASE_DIR}"
            tar -czf "alouette-translator-linux-${VERSION_NAME}.tar.gz" linux/
            cd - > /dev/null
        fi
        
        # 生成文件信息
        size=$(du -sh "${RELEASE_DIR}/linux" | awk '{print $1}')
        echo "  - linux/ (${size})" >> "${RELEASE_DIR}/build_info.txt"
        if [ -f "${RELEASE_DIR}/alouette-translator-linux-${VERSION_NAME}.tar.gz" ]; then
            tar_size=$(ls -lh "${RELEASE_DIR}/alouette-translator-linux-${VERSION_NAME}.tar.gz" | awk '{print $5}')
            echo "  - alouette-translator-linux-${VERSION_NAME}.tar.gz (${tar_size})" >> "${RELEASE_DIR}/build_info.txt"
        fi
        
        echo -e "${GREEN}Linux文件已保存到: ${RELEASE_DIR}/linux/${NC}"
    else
        echo -e "${RED}Linux构建失败${NC}"
        return 1
    fi
}

# 函数：构建Web
build_web() {
    echo -e "${YELLOW}构建Web版本...${NC}"
    
    flutter build web --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Web构建成功${NC}"
        
        # 复制Web文件到输出目录
        mkdir -p "${RELEASE_DIR}/web"
        cp -r build/web/* "${RELEASE_DIR}/web/"
        
        # 创建ZIP压缩包
        if command -v zip &> /dev/null; then
            cd "${RELEASE_DIR}"
            zip -r "alouette-translator-web-${VERSION_NAME}.zip" web/
            cd - > /dev/null
        fi
        
        # 生成文件信息
        size=$(du -sh "${RELEASE_DIR}/web" | awk '{print $1}')
        echo "  - web/ (${size})" >> "${RELEASE_DIR}/build_info.txt"
        if [ -f "${RELEASE_DIR}/alouette-translator-web-${VERSION_NAME}.zip" ]; then
            zip_size=$(ls -lh "${RELEASE_DIR}/alouette-translator-web-${VERSION_NAME}.zip" | awk '{print $5}')
            echo "  - alouette-translator-web-${VERSION_NAME}.zip (${zip_size})" >> "${RELEASE_DIR}/build_info.txt"
        fi
        
        echo -e "${GREEN}Web文件已保存到: ${RELEASE_DIR}/web/${NC}"
    else
        echo -e "${RED}Web构建失败${NC}"
        return 1
    fi
}

# 函数：生成构建报告
generate_report() {
    echo -e "${YELLOW}生成构建报告...${NC}"
    
    cat > "${RELEASE_DIR}/README.md" << EOF
# Alouette TTS 发布包 v${VERSION_NAME}

构建时间: $(date)
版本号: ${VERSION_NAME}+${BUILD_NUMBER}

## 包含文件

EOF
    
    if [ -f "${RELEASE_DIR}/build_info.txt" ]; then
        cat "${RELEASE_DIR}/build_info.txt" >> "${RELEASE_DIR}/README.md"
    fi
    
    cat >> "${RELEASE_DIR}/README.md" << EOF

## 安装说明

### Android
- APK文件可直接安装
- AAB文件需要通过Google Play Console上传

### iOS
- IPA文件可通过TestFlight或App Store Connect安装
- 需要有效的iOS开发者证书

### macOS
- 直接运行.app文件
- 或安装.dmg文件

### Windows
- 解压zip文件并运行alouette_translator.exe

### Linux
- 解压tar.gz文件并运行alouette_translator

### Web
- 解压zip文件并部署到Web服务器
- 或直接访问index.html

## 系统要求

- Android: API 21+ (Android 5.0+)
- iOS: iOS 11.0+
- macOS: macOS 10.14+
- Windows: Windows 7+
- Linux: 64位系统

EOF
    
    echo -e "${GREEN}构建报告已生成: ${RELEASE_DIR}/README.md${NC}"
}

# 主函数
main() {
    local clean_flag=false
    local build_all=false
    local build_android_apk_flag=false
    local build_android_aab_flag=false
    local build_ios_flag=false
    local build_macos_flag=false
    local build_windows_flag=false
    local build_linux_flag=false
    local build_web_flag=false
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -c|--clean)
                clean_flag=true
                shift
                ;;
            -a|--all)
                build_all=true
                shift
                ;;
            --android-apk)
                build_android_apk_flag=true
                shift
                ;;
            --android-aab)
                build_android_aab_flag=true
                shift
                ;;
            --ios)
                build_ios_flag=true
                shift
                ;;
            --macos)
                build_macos_flag=true
                shift
                ;;
            --windows)
                build_windows_flag=true
                shift
                ;;
            --linux)
                build_linux_flag=true
                shift
                ;;
            --web)
                build_web_flag=true
                shift
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定任何平台，显示帮助
    if [ "$build_all" = false ] && [ "$build_android_apk_flag" = false ] && [ "$build_android_aab_flag" = false ] && [ "$build_ios_flag" = false ] && [ "$build_macos_flag" = false ] && [ "$build_windows_flag" = false ] && [ "$build_linux_flag" = false ] && [ "$build_web_flag" = false ]; then
        show_help
        exit 0
    fi
    
    # 设置构建全部平台的标志
    if [ "$build_all" = true ]; then
        build_android_apk_flag=true
        build_android_aab_flag=true
        build_ios_flag=true
        build_macos_flag=true
        build_windows_flag=true
        build_linux_flag=true
        build_web_flag=true
    fi
    
    # 清理构建缓存
    if [ "$clean_flag" = true ]; then
        clean_build
    fi
    
    # 初始化构建信息文件
    echo "Alouette TTS v${VERSION_NAME} 构建文件:" > "${RELEASE_DIR}/build_info.txt"
    echo "" >> "${RELEASE_DIR}/build_info.txt"
    
    local success_count=0
    local total_count=0
    
    # 构建各平台
    if [ "$build_android_apk_flag" = true ]; then
        ((total_count++))
        if build_android_apk; then
            ((success_count++))
        fi
        echo ""
    fi
    
    if [ "$build_android_aab_flag" = true ]; then
        ((total_count++))
        if build_android_aab; then
            ((success_count++))
        fi
        echo ""
    fi
    
    if [ "$build_ios_flag" = true ]; then
        ((total_count++))
        if build_ios; then
            ((success_count++))
        fi
        echo ""
    fi
    
    if [ "$build_macos_flag" = true ]; then
        ((total_count++))
        if build_macos; then
            ((success_count++))
        fi
        echo ""
    fi
    
    if [ "$build_windows_flag" = true ]; then
        ((total_count++))
        if build_windows; then
            ((success_count++))
        fi
        echo ""
    fi
    
    if [ "$build_linux_flag" = true ]; then
        ((total_count++))
        if build_linux; then
            ((success_count++))
        fi
        echo ""
    fi
    
    if [ "$build_web_flag" = true ]; then
        ((total_count++))
        if build_web; then
            ((success_count++))
        fi
        echo ""
    fi
    
    # 生成构建报告
    generate_report
    
    # 构建总结
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${BLUE}           构建完成统计                    ${NC}"
    echo -e "${BLUE}===========================================${NC}"
    echo -e "${GREEN}成功: ${success_count}/${total_count}${NC}"
    echo -e "${YELLOW}输出目录: ${RELEASE_DIR}${NC}"
    echo ""
    
    if [ $success_count -eq $total_count ]; then
        echo -e "${GREEN}🎉 所有构建任务成功完成！${NC}"
        exit 0
    else
        echo -e "${RED}⚠️  部分构建任务失败，请检查错误信息${NC}"
        exit 1
    fi
}

# 检查是否在Flutter项目根目录
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}错误: 请在Flutter项目根目录下运行此脚本${NC}"
    exit 1
fi

# 检查Flutter是否已安装
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}错误: 未找到Flutter命令，请确保Flutter已正确安装并添加到PATH${NC}"
    exit 1
fi

# 运行主函数
main "$@"
