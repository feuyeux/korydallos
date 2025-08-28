#!/bin/bash

# Alouette TTS - CI/CD自动化构建脚本
# 专为持续集成/持续部署环境设计

set -e  # 遇到错误时退出

# 环境变量检查
check_env() {
    local required_vars=("CI" "FLUTTER_VERSION")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "❌ 缺少必需的环境变量: ${missing_vars[*]}"
        echo "请设置以下环境变量:"
        echo "  CI=true"
        echo "  FLUTTER_VERSION=stable (或指定版本号)"
        echo "  可选变量:"
        echo "  ANDROID_SIGNING_KEY_ALIAS=<签名密钥别名>"
        echo "  ANDROID_SIGNING_KEY_PASSWORD=<签名密钥密码>"
        echo "  ANDROID_SIGNING_STORE_PASSWORD=<签名存储密码>"
        echo "  IOS_CERTIFICATE_PASSWORD=<iOS证书密码>"
        exit 1
    fi
}

# 设置Flutter环境
setup_flutter() {
    echo "📦 设置Flutter环境..."
    
    if ! command -v flutter &> /dev/null; then
        echo "❌ Flutter未找到，请在CI环境中安装Flutter"
        exit 1
    fi
    
    echo "📋 Flutter版本信息:"
    flutter --version
    
    echo "📥 获取依赖..."
    flutter pub get
    
    echo "🔍 检查Flutter配置..."
    flutter doctor -v
}

# 代码质量检查
quality_check() {
    echo "🔍 代码质量检查..."
    
    # 代码分析
    echo "📊 运行代码分析..."
    flutter analyze
    
    # 代码格式检查
    echo "📝 检查代码格式..."
    dart format --set-exit-if-changed .
    
    # 运行测试
    echo "🧪 运行单元测试..."
    if [ -d "test" ]; then
        flutter test --coverage
        
        # 上传代码覆盖率（如果有相关工具）
        if command -v codecov &> /dev/null; then
            codecov -f coverage/lcov.info
        fi
    else
        echo "⚠️  未找到测试目录，跳过测试"
    fi
}

# 构建Android
build_android_ci() {
    echo "🤖 构建Android..."
    
    # 检查Android签名配置
    if [ -n "$ANDROID_SIGNING_KEY_ALIAS" ]; then
        echo "🔐 使用Android签名配置"
        # 这里可以添加签名配置的设置逻辑
    fi
    
    # 构建APK
    echo "📱 构建Android APK..."
    flutter build apk --release --split-per-abi
    
    # 构建AAB
    echo "📦 构建Android AAB..."
    flutter build appbundle --release
    
    # 复制构建产物
    mkdir -p artifacts/android
    cp build/app/outputs/flutter-apk/*.apk artifacts/android/ || true
    cp build/app/outputs/bundle/release/*.aab artifacts/android/ || true
}

# 构建iOS (仅在macOS上)
build_ios_ci() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "⏭️  跳过iOS构建 (非macOS环境)"
        return 0
    fi
    
    echo "🍎 构建iOS..."
    
    # 检查iOS证书配置
    if [ -n "$IOS_CERTIFICATE_PASSWORD" ]; then
        echo "🔐 使用iOS签名配置"
        # 这里可以添加证书安装逻辑
    fi
    
    # 构建iOS
    echo "📱 构建iOS IPA..."
    flutter build ios --release --no-codesign
    
    # 如果有签名配置，构建IPA
    if [ -n "$IOS_CERTIFICATE_PASSWORD" ]; then
        flutter build ipa --release
        mkdir -p artifacts/ios
        cp build/ios/ipa/*.ipa artifacts/ios/ || true
    fi
}

# 构建Web
build_web_ci() {
    echo "🌐 构建Web..."
    
    flutter build web --release
    
    # 复制构建产物
    mkdir -p artifacts/web
    cp -r build/web/* artifacts/web/
    
    # 创建压缩包
    cd artifacts
    tar -czf "alouette-translator-web.tar.gz" web/
    cd ..
}

# 构建桌面平台
build_desktop_ci() {
    local platform=$1
    
    case $platform in
        "macos")
            if [[ "$OSTYPE" != "darwin"* ]]; then
                echo "⏭️  跳过macOS构建 (非macOS环境)"
                return 0
            fi
            echo "🖥️  构建macOS..."
            flutter build macos --release
            mkdir -p artifacts/macos
            cp -r build/macos/Build/Products/Release/*.app artifacts/macos/
            ;;
        "windows")
            if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
                echo "🖥️  构建Windows..."
                flutter build windows --release
                mkdir -p artifacts/windows
                cp -r build/windows/x64/runner/Release/* artifacts/windows/
            else
                echo "⏭️  跳过Windows构建 (非Windows环境)"
            fi
            ;;
        "linux")
            if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                echo "🖥️  构建Linux..."
                flutter build linux --release
                mkdir -p artifacts/linux
                cp -r build/linux/x64/release/bundle/* artifacts/linux/
                cd artifacts
                tar -czf "alouette-translator-linux.tar.gz" linux/
                cd ..
            else
                echo "⏭️  跳过Linux构建 (非Linux环境)"
            fi
            ;;
    esac
}

# 上传构建产物
upload_artifacts() {
    echo "📤 准备上传构建产物..."
    
    if [ ! -d "artifacts" ]; then
        echo "❌ 未找到构建产物目录"
        return 1
    fi
    
    # 显示构建产物
    echo "📋 构建产物列表:"
    find artifacts -type f -exec ls -lh {} \;
    
    # 根据CI环境上传到不同的位置
    case "${CI_PLATFORM:-unknown}" in
        "github")
            echo "📤 准备GitHub Actions artifact上传"
            # GitHub Actions会自动处理artifacts目录
            ;;
        "gitlab")
            echo "📤 准备GitLab CI artifact上传"
            # GitLab CI会根据.gitlab-ci.yml配置处理
            ;;
        "jenkins")
            echo "📤 准备Jenkins artifact上传"
            # Jenkins会根据Jenkinsfile配置处理
            ;;
        *)
            echo "📤 未知CI平台，构建产物保存在 artifacts/ 目录"
            ;;
    esac
}

# 生成发布说明
generate_release_notes() {
    local version=$(grep "version:" pubspec.yaml | sed 's/version: //' | tr -d ' ')
    local version_name=$(echo $version | cut -d'+' -f1)
    local build_number=$(echo $version | cut -d'+' -f2)
    
    cat > artifacts/RELEASE_NOTES.md << EOF
# Alouette TTS v${version_name} 发布说明

**版本:** ${version_name}+${build_number}
**构建时间:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**提交:** ${CI_COMMIT_SHA:-$(git rev-parse HEAD 2>/dev/null || echo "未知")}

## 构建环境信息

- **CI平台:** ${CI_PLATFORM:-未知}
- **构建代理:** ${CI_RUNNER:-未知}
- **Flutter版本:** $(flutter --version | head -n1)
- **Dart版本:** $(dart --version)

## 包含的构建产物

EOF
    
    # 列出所有构建产物
    find artifacts -name "*.apk" -o -name "*.aab" -o -name "*.ipa" -o -name "*.app" -o -name "*.tar.gz" -o -name "*.zip" | while read file; do
        size=$(ls -lh "$file" | awk '{print $5}')
        echo "- $(basename "$file") (${size})" >> artifacts/RELEASE_NOTES.md
    done
    
    cat >> artifacts/RELEASE_NOTES.md << EOF

## 系统要求

- **Android:** API 21+ (Android 5.0+)
- **iOS:** iOS 11.0+
- **macOS:** macOS 10.14+
- **Windows:** Windows 7+
- **Linux:** 64位系统

## 安装方法

请参考项目README.md中的安装说明。

---
*此发布包由自动化CI/CD流水线生成*
EOF
    
    echo "📝 发布说明已生成: artifacts/RELEASE_NOTES.md"
}

# 主函数
main() {
    echo "🚀 Alouette TTS CI/CD构建开始"
    echo "============================================"
    
    # 获取构建配置
    local build_platforms="${BUILD_PLATFORMS:-android,web}"
    local skip_quality_check="${SKIP_QUALITY_CHECK:-false}"
    
    echo "📋 构建配置:"
    echo "  - 构建平台: $build_platforms"
    echo "  - 跳过质量检查: $skip_quality_check"
    echo ""
    
    # 环境检查
    check_env
    
    # 设置Flutter环境
    setup_flutter
    
    # 代码质量检查
    if [ "$skip_quality_check" != "true" ]; then
        quality_check
    else
        echo "⏭️  跳过代码质量检查"
    fi
    
    # 创建构建产物目录
    mkdir -p artifacts
    
    # 根据配置构建不同平台
    IFS=',' read -ra PLATFORMS <<< "$build_platforms"
    for platform in "${PLATFORMS[@]}"; do
        case "$platform" in
            "android")
                build_android_ci
                ;;
            "ios")
                build_ios_ci
                ;;
            "web")
                build_web_ci
                ;;
            "macos"|"windows"|"linux")
                build_desktop_ci "$platform"
                ;;
            *)
                echo "⚠️  未知平台: $platform"
                ;;
        esac
        echo ""
    done
    
    # 生成发布说明
    generate_release_notes
    
    # 上传构建产物
    upload_artifacts
    
    echo "============================================"
    echo "✅ CI/CD构建完成"
    echo "📦 构建产物保存在 artifacts/ 目录"
}

# 检查是否在Flutter项目根目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误: 请在Flutter项目根目录下运行此脚本"
    exit 1
fi

# 运行主函数
main "$@"
