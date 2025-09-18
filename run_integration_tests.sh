#!/bin/bash

# Alouette Integration Test Runner
# This script runs integration tests for all Alouette applications

set -e

# Default values
PLATFORM="auto"
APP="all"
VERBOSE=false
COVERAGE=false
OUTPUT_DIR="test_results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -p, --platform PLATFORM    Target platform (auto, windows, android, web, etc.)"
    echo "  -a, --app APP              Application to test (all, main, trans, tts)"
    echo "  -v, --verbose              Enable verbose output"
    echo "  -c, --coverage             Enable coverage reporting"
    echo "  -o, --output DIR           Output directory for test results"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                         # Run all tests on auto-detected platform"
    echo "  $0 -p android -a main      # Run main app tests on Android"
    echo "  $0 -v -c                   # Run all tests with verbose output and coverage"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -a|--app)
            APP="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -c|--coverage)
            COVERAGE=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

print_color $CYAN "🚀 Alouette Integration Test Runner"
print_color $CYAN "================================="

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Function to run tests for a specific app
run_app_tests() {
    local app_name=$1
    local app_path=$2
    local test_platform=$3
    
    print_color $YELLOW "\n📱 Testing $app_name Application"
    print_color $GRAY "Path: $app_path"
    print_color $GRAY "Platform: $test_platform"
    
    pushd "$app_path" > /dev/null
    
    # Get dependencies
    print_color $BLUE "📦 Getting dependencies..."
    if ! flutter pub get; then
        print_color $RED "❌ Failed to get dependencies for $app_name"
        popd > /dev/null
        return 1
    fi
    
    # Build test command
    local test_cmd="flutter test integration_test/test_runner.dart"
    
    if [[ "$test_platform" != "auto" ]]; then
        test_cmd="$test_cmd -d $test_platform"
    fi
    
    if [[ "$VERBOSE" == "true" ]]; then
        test_cmd="$test_cmd --verbose"
    fi
    
    if [[ "$COVERAGE" == "true" ]]; then
        test_cmd="$test_cmd --coverage"
    fi
    
    # Add output file
    local output_file="$(pwd)/../$OUTPUT_DIR/${app_name}_test_results.json"
    test_cmd="$test_cmd --reporter=json"
    
    print_color $BLUE "🧪 Running integration tests..."
    print_color $GRAY "Command: $test_cmd"
    
    # Run tests and capture output
    if $test_cmd > "$output_file" 2>&1; then
        print_color $GREEN "✅ $app_name tests passed!"
        popd > /dev/null
        return 0
    else
        print_color $RED "❌ $app_name tests failed!"
        print_color $GRAY "Output saved to: $output_file"
        popd > /dev/null
        return 1
    fi
}

# Function to detect available platforms
get_available_platforms() {
    print_color $BLUE "🔍 Detecting available platforms..."
    
    local platforms=()
    
    # Check for connected devices
    local devices_json=$(flutter devices --machine 2>/dev/null || echo "[]")
    
    # Parse JSON and extract device IDs
    if command -v jq >/dev/null 2>&1; then
        # Use jq if available
        while IFS= read -r device_id; do
            if [[ -n "$device_id" ]]; then
                platforms+=("$device_id")
                local device_name=$(echo "$devices_json" | jq -r ".[] | select(.id == \"$device_id\") | .name")
                print_color $GRAY "  📱 Found: $device_name ($device_id)"
            fi
        done < <(echo "$devices_json" | jq -r '.[].id')
    else
        # Fallback parsing without jq
        if echo "$devices_json" | grep -q '"id"'; then
            print_color $GRAY "  📱 Found devices (install jq for detailed info)"
            platforms+=("chrome") # Default fallback
        fi
    fi
    
    # Add common platforms as fallback
    if [[ ${#platforms[@]} -eq 0 ]]; then
        platforms+=("chrome")
        print_color $GRAY "  📱 Using fallback: chrome"
    fi
    
    echo "${platforms[@]}"
}

# Main execution
start_time=$(date +%s)

# Detect platform if auto
if [[ "$PLATFORM" == "auto" ]]; then
    available_platforms=($(get_available_platforms))
    
    if [[ ${#available_platforms[@]} -eq 0 ]]; then
        print_color $RED "❌ No platforms detected. Please ensure Flutter is installed and devices are connected."
        exit 1
    fi
    
    # Use first available platform
    PLATFORM="${available_platforms[0]}"
    print_color $GREEN "🎯 Auto-selected platform: $PLATFORM"
fi

# Define applications to test
declare -A applications
applications["Main"]="alouette-app"
applications["Translation"]="alouette-app-trans"
applications["TTS"]="alouette-app-tts"

# Filter applications based on APP parameter
declare -A filtered_apps
case "$APP" in
    "all")
        filtered_apps["Main"]="alouette-app"
        filtered_apps["Translation"]="alouette-app-trans"
        filtered_apps["TTS"]="alouette-app-tts"
        ;;
    "main")
        filtered_apps["Main"]="alouette-app"
        ;;
    "trans")
        filtered_apps["Translation"]="alouette-app-trans"
        ;;
    "tts")
        filtered_apps["TTS"]="alouette-app-tts"
        ;;
    *)
        print_color $RED "❌ Invalid app parameter: $APP"
        show_usage
        exit 1
        ;;
esac

# Run tests for each application
declare -A results
total_tests=${#filtered_apps[@]}
passed_tests=0

for app_name in "${!filtered_apps[@]}"; do
    app_path="${filtered_apps[$app_name]}"
    
    print_color $CYAN "\n$(printf '=%.0s' {1..50})"
    print_color $CYAN "Testing: $app_name Application"
    print_color $CYAN "$(printf '=%.0s' {1..50})"
    
    if run_app_tests "$app_name" "$app_path" "$PLATFORM"; then
        results["$app_name"]="PASSED"
        ((passed_tests++))
    else
        results["$app_name"]="FAILED"
    fi
done

# Generate summary report
end_time=$(date +%s)
duration=$((end_time - start_time))
duration_formatted=$(printf "%02d:%02d" $((duration/60)) $((duration%60)))

print_color $CYAN "\n$(printf '=%.0s' {1..50})"
print_color $CYAN "📊 TEST SUMMARY"
print_color $CYAN "$(printf '=%.0s' {1..50})"

print_color $GRAY "Platform: $PLATFORM"
print_color $GRAY "Duration: $duration_formatted"
print_color $GRAY "Results Directory: $OUTPUT_DIR"

echo -e "\nResults:"
for app_name in "${!results[@]}"; do
    status="${results[$app_name]}"
    if [[ "$status" == "PASSED" ]]; then
        print_color $GREEN "  $app_name: ✅ PASSED"
    else
        print_color $RED "  $app_name: ❌ FAILED"
    fi
done

echo -e "\nOverall: $passed_tests/$total_tests tests passed"

if [[ $passed_tests -eq $total_tests ]]; then
    print_color $GREEN "🎉 All integration tests passed!"
    exit_code=0
else
    print_color $RED "💥 Some integration tests failed!"
    exit_code=1
fi

# Generate HTML report
html_report="<!DOCTYPE html>
<html>
<head>
    <title>Alouette Integration Test Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { margin: 20px 0; }
        .passed { color: green; }
        .failed { color: red; }
        .details { margin-top: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class=\"header\">
        <h1>Alouette Integration Test Results</h1>
        <p><strong>Platform:</strong> $PLATFORM</p>
        <p><strong>Duration:</strong> $duration_formatted</p>
        <p><strong>Timestamp:</strong> $(date '+%Y-%m-%d %H:%M:%S')</p>
    </div>
    
    <div class=\"summary\">
        <h2>Summary</h2>
        <p><strong>Overall Result:</strong> $passed_tests/$total_tests tests passed</p>
    </div>
    
    <div class=\"details\">
        <h2>Detailed Results</h2>
        <table>
            <tr><th>Application</th><th>Status</th><th>Details</th></tr>"

for app_name in "${!results[@]}"; do
    status="${results[$app_name]}"
    class=$(echo "$status" | tr '[:upper:]' '[:lower:]')
    details_file="${app_name}_test_results.json"
    
    html_report="$html_report
            <tr>
                <td>$app_name</td>
                <td class=\"$class\">$status</td>
                <td><a href=\"$details_file\">View Details</a></td>
            </tr>"
done

html_report="$html_report
        </table>
    </div>
</body>
</html>"

html_report_path="$OUTPUT_DIR/test_report.html"
echo "$html_report" > "$html_report_path"

print_color $BLUE "\n📄 HTML report generated: $html_report_path"

exit $exit_code