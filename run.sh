#!/bin/bash

# Alouette Applications Runner Script
# 支持运行所有Alouette应用的统一脚本

set -e  # 遇到错误时退出

# 脚本配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_step() {
    echo -e "${CYAN}🔄 $1${NC}"
}

log_title() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# 过滤Flutter输出的函数
filter_flutter_output() {
    grep -v "DebugService: Error serving requests" | \
    grep -v "Cannot send Null" | \
    grep -v "Unsupported operation" | \
    sed 's/^/    /' || true
}

# 应用配置
declare -A APPS=(
    ["trans"]="alouette-app-trans"
    ["tts"]="alouette-app-tts" 
    ["app"]="alouette-app"
)

declare -A APP_NAMES=(
    ["trans"]="Alouette Translator"
    ["tts"]="Alouette TTS"
    ["app"]="Alouette Base App"
)

# 帮助信息
show_help() {
    echo -e "${BLUE}Alouette Applications Runner${NC}"
    echo -e "${BLUE}================================${NC}"
    echo ""
    echo "Usage: $0 [APP] [PLATFORM] [OPTIONS]"
    echo ""
    echo -e "${YELLOW}Available Apps:${NC}"
    echo "  trans     - Alouette Translator (翻译应用)"
    echo "  tts       - Alouette TTS (语音合成应用)"
    echo "  app       - Alouette Base App (基础应用)"
    echo ""
    echo -e "${YELLOW}Available Platforms:${NC}"
    echo "  macos     - macOS desktop application"
    echo "  chrome    - Web application in Chrome"
    echo "  web       - Web application (default browser)"
    echo "  ios       - iOS simulator (requires Xcode)"
    echo "  android   - Android emulator/device"
    echo ""
    echo -e "${YELLOW}Options:${NC}"
    echo "  --debug   - Run in debug mode (default)"
    echo "  --release - Run in release mode"
    echo "  --profile - Run in profile mode"
    echo "  --clean   - Clean build before running"
    echo "  --pub     - Run 'flutter pub get' before building"
    echo "  --help    - Show this help message"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  $0 trans macos           # Run translator on macOS"
    echo "  $0 tts chrome --clean    # Clean build and run TTS on Chrome"
    echo "  $0 app ios --release     # Run base app on iOS in release mode"
    echo "  $0 trans                 # Run translator (will prompt for platform)"
}

# 检查Flutter是否可用
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        echo -e "${RED}❌ Flutter not found in PATH${NC}"
        echo "Please install Flutter and add it to your PATH"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Flutter found: $(flutter --version | head -n 1)${NC}"
}

# 检查并设置环境
setup_environment() {
    # 确保Homebrew在PATH中 (修复CocoaPods问题)
    if [[ "$OSTYPE" == "darwin"* ]] && [[ -d "/opt/homebrew/bin" ]]; then
        export PATH="/opt/homebrew/bin:$PATH"
        echo -e "${GREEN}✅ Added Homebrew to PATH${NC}"
    fi
    
    # 检查pod命令 (macOS需要)
    if [[ "$1" == "macos" ]] || [[ "$1" == "ios" ]]; then
        if command -v pod &> /dev/null; then
            echo -e "${GREEN}✅ CocoaPods found: $(pod --version)${NC}"
        else
            echo -e "${YELLOW}⚠️  CocoaPods not found, may cause issues with macOS/iOS builds${NC}"
        fi
    fi
}

# 获取可用设备
get_available_devices() {
    echo -e "${BLUE}📱 Available devices:${NC}"
    flutter devices
    echo ""
}

# 选择平台
choose_platform() {
    echo -e "${YELLOW}Please choose a platform:${NC}"
    echo "1) macOS"
    echo "2) Chrome (Web)"
    echo "3) Web (Default Browser)"
    echo "4) iOS Simulator"
    echo "5) Android"
    echo "6) Show available devices"
    echo ""
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1) echo "macos" ;;
        2) echo "chrome" ;;
        3) echo "web" ;;
        4) echo "ios" ;;
        5) echo "android" ;;
        6) 
            get_available_devices
            choose_platform
            ;;
        *) 
            echo -e "${RED}Invalid choice${NC}"
            choose_platform
            ;;
    esac
}

# 运行应用
run_app() {
    local app_key="$1"
    local platform="$2"
    local mode="$3"
    local clean="$4"
    local pub_get="$5"
    
    local app_dir="${APPS[$app_key]}"
    local app_name="${APP_NAMES[$app_key]}"
    local app_path="$PROJECT_ROOT/$app_dir"
    
    log_title "Starting $app_name"
    log_info "Directory: $app_path"
    log_info "Platform: $platform"
    log_info "Mode: $mode"
    echo ""
    
    # 检查应用目录是否存在
    if [[ ! -d "$app_path" ]]; then
        log_error "App directory not found: $app_path"
        exit 1
    fi
    
    # 切换到应用目录
    cd "$app_path"
    
    # 检查pubspec.yaml
    if [[ ! -f "pubspec.yaml" ]]; then
        log_error "pubspec.yaml not found in $app_path"
        exit 1
    fi
    
    # 清理构建 (如果需要)
    if [[ "$clean" == "true" ]]; then
        log_step "Cleaning build..."
        flutter clean 2>&1 | filter_flutter_output
        log_success "Build cleaned"
    fi
    
    # 获取依赖 (如果需要)
    if [[ "$pub_get" == "true" ]]; then
        log_step "Getting dependencies..."
        flutter pub get 2>&1 | filter_flutter_output
        log_success "Dependencies updated"
    fi
    
    # 构建并运行
    local flutter_args=""
    case $mode in
        "release") flutter_args="--release" ;;
        "profile") flutter_args="--profile" ;;
        *) flutter_args="--debug" ;;
    esac
    
    # Web平台特殊处理
    if [[ "$platform" == "chrome" ]] || [[ "$platform" == "web" ]]; then
        flutter_args="$flutter_args --web-renderer html"
        log_warning "Web平台运行时可能会有调试信息，这是正常现象"
    fi
    
    log_step "Building and launching application..."
    log_info "Command: flutter run -d $platform $flutter_args"
    echo ""
    
    # 运行Flutter并过滤输出
    {
        flutter run -d "$platform" $flutter_args 2>&1 | \
        while IFS= read -r line; do
            # 过滤掉调试服务错误
            if [[ "$line" =~ "DebugService: Error serving requests" ]] || \
               [[ "$line" =~ "Cannot send Null" ]] || \
               [[ "$line" =~ "Unsupported operation" ]]; then
                continue
            fi
            
            # 格式化重要信息
            if [[ "$line" =~ "✓ Built" ]]; then
                log_success "${line#*✓ }"
            elif [[ "$line" =~ "Running pod install" ]]; then
                log_step "${line}"
            elif [[ "$line" =~ "Launching" ]]; then
                log_step "${line}"
            elif [[ "$line" =~ "Flutter run key commands" ]]; then
                echo ""
                log_info "应用已启动! 可用命令:"
                echo -e "    ${GREEN}r${NC} - 热重载 🔥"
                echo -e "    ${GREEN}R${NC} - 热重启 🔄"
                echo -e "    ${GREEN}h${NC} - 显示帮助"
                echo -e "    ${GREEN}q${NC} - 退出应用"
                echo ""
            elif [[ "$line" =~ "Dart VM Service" ]] || [[ "$line" =~ "Flutter DevTools" ]]; then
                log_info "${line}"
            else
                # 其他输出直接显示，但添加缩进
                echo "    $line"
            fi
        done
    }
}

# 主逻辑
main() {
    local app_key=""
    local platform=""
    local mode="debug"
    local clean="false"
    local pub_get="false"
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help|-h)
                show_help
                exit 0
                ;;
            --debug)
                mode="debug"
                shift
                ;;
            --release)
                mode="release"
                shift
                ;;
            --profile)
                mode="profile"
                shift
                ;;
            --clean)
                clean="true"
                shift
                ;;
            --pub)
                pub_get="true"
                shift
                ;;
            trans|tts|app)
                app_key="$1"
                shift
                ;;
            macos|chrome|web|ios|android)
                platform="$1"
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
    
    # 显示标题
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════╗"
    echo "║        Alouette App Runner           ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    # 检查Flutter
    check_flutter
    
    # 选择应用 (如果未指定)
    if [[ -z "$app_key" ]]; then
        echo -e "${YELLOW}Please choose an application:${NC}"
        echo "1) Translator (trans)"
        echo "2) TTS (tts)"
        echo "3) Base App (app)"
        echo ""
        read -p "Enter your choice (1-3): " choice
        
        case $choice in
            1) app_key="trans" ;;
            2) app_key="tts" ;;
            3) app_key="app" ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                exit 1
                ;;
        esac
    fi
    
    # 验证应用key
    if [[ -z "${APPS[$app_key]}" ]]; then
        echo -e "${RED}❌ Unknown app: $app_key${NC}"
        echo "Available apps: ${!APPS[@]}"
        exit 1
    fi
    
    # 选择平台 (如果未指定)
    if [[ -z "$platform" ]]; then
        platform=$(choose_platform)
    fi
    
    # 设置环境
    setup_environment "$platform"
    
    # 运行应用
    run_app "$app_key" "$platform" "$mode" "$clean" "$pub_get"
}

# 运行主函数
main "$@"