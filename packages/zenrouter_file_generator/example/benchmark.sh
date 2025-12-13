#!/bin/bash

# Comprehensive Deferred Import Benchmark Script
# Tests application-level deferred imports (main_deferred.dart vs main_no_deferred.dart)

set -e

echo "======================================================"
echo "ZenRouter Deferred Import Benchmark"
echo "======================================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build/web"
RESULTS_FILE="$SCRIPT_DIR/benchmark_results.txt"
BUILD_YAML="$SCRIPT_DIR/build.yaml"

# Function to update deferredImport setting in build.yaml
update_deferred_import() {
    local value=$1
    echo -e "${BLUE}Setting deferredImport to $value in build.yaml...${NC}"
    
    # Update the deferredImport value in build.yaml
    sed -i.bak "s/deferredImport: .*/deferredImport: $value/" "$BUILD_YAML"
    
    # Show the updated setting
    grep "deferredImport:" "$BUILD_YAML"
}

# Function to clean build directory
clean_build() {
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
}

# Function to run flutter build with specific target
run_build() {
    local target=$1
    local label=$2
    
    echo -e "${BLUE}Building with target: $target${NC}"
    echo -e "${BLUE}Running flutter clean...${NC}"
    flutter clean
    
    echo -e "${BLUE}Running flutter pub get...${NC}"
    flutter pub get
    
    echo -e "${BLUE}Running build_runner clean...${NC}"
    flutter packages pub run build_runner clean
    
    echo -e "${BLUE}Running build_runner build...${NC}"
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    echo -e "${BLUE}Building web app (target: $target)...${NC}"
    flutter build web --release -t "$target"
}

# Function to measure JS files
measure_js_files() {
    local label=$1
    local total_size=0
    
    echo -e "${GREEN}Measuring JS files for: $label${NC}"
    echo "----------------------------------------"
    
    if [ ! -d "$BUILD_DIR" ]; then
        echo "Error: Build directory not found!"
        return 1
    fi
    
    # Find all .js files and calculate sizes
    while IFS= read -r -d '' file; do
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
        local size_kb=$((size / 1024))
        local filename=$(basename "$file")
        echo "  $filename: ${size_kb} KB"
        total_size=$((total_size + size))
    done < <(find "$BUILD_DIR" -name "*.js" -type f -print0 | sort -z)
    
    local total_kb=$((total_size / 1024))
    local total_mb=$(python3 -c "print(f'{$total_size / 1024 / 1024:.2f}')")
    
    echo "----------------------------------------"
    echo -e "${GREEN}Total JS size: ${total_kb} KB (${total_mb} MB)${NC}"
    
    # Count files
    local file_count=$(find "$BUILD_DIR" -name "*.js" -type f | wc -l | tr -d ' ')
    echo -e "${GREEN}Total JS files: ${file_count}${NC}"
    echo ""
    
    # Return total size
    echo "$total_size"
}

# Initialize results file
echo "ZenRouter Deferred Import Benchmark Results" > "$RESULTS_FILE"
echo "Generated: $(date)" >> "$RESULTS_FILE"
echo "======================================================" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Benchmark 1: main_no_deferred.dart (baseline)
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Test 1: main_no_deferred.dart${NC}"
echo -e "${YELLOW}(Normal import - Baseline)${NC}"
echo -e "${YELLOW}========================================${NC}"
update_deferred_import "false"
clean_build
run_build "lib/main_no_deferred.dart" "No Deferred"
size_no_deferred=$(measure_js_files "main_no_deferred.dart")

echo "Test 1: main_no_deferred.dart (Normal Import - Baseline)" >> "$RESULTS_FILE"
echo "----------------------------------------" >> "$RESULTS_FILE"
find "$BUILD_DIR" -name "*.js" -type f | sort | while read file; do
    echo "  $(basename "$file"): $(($(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null) / 1024)) KB" >> "$RESULTS_FILE"
done
file_count_no_deferred=$(find "$BUILD_DIR" -name "*.js" -type f | wc -l | tr -d ' ')
echo "Total: $((size_no_deferred / 1024)) KB" >> "$RESULTS_FILE"
echo "File count: $file_count_no_deferred" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Benchmark 2: main_deferred.dart
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Test 2: main_deferred.dart${NC}"
echo -e "${YELLOW}(Deferred import with loadLibrary)${NC}"
echo -e "${YELLOW}========================================${NC}"
update_deferred_import "true"
clean_build
run_build "lib/main_deferred.dart" "Deferred"
size_deferred=$(measure_js_files "main_deferred.dart")

echo "Test 2: main_deferred.dart (Deferred Import)" >> "$RESULTS_FILE"
echo "----------------------------------------" >> "$RESULTS_FILE"
find "$BUILD_DIR" -name "*.js" -type f | sort | while read file; do
    echo "  $(basename "$file"): $(($(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null) / 1024)) KB" >> "$RESULTS_FILE"
done
file_count_deferred=$(find "$BUILD_DIR" -name "*.js" -type f | wc -l | tr -d ' ')
echo "Total: $((size_deferred / 1024)) KB" >> "$RESULTS_FILE"
echo "File count: $file_count_deferred" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Calculate difference
echo "======================================================" >> "$RESULTS_FILE"
echo "Comparison" >> "$RESULTS_FILE"
echo "======================================================" >> "$RESULTS_FILE"
difference=$((size_deferred - size_no_deferred))
difference_kb=$((difference / 1024))
percentage=$(python3 -c "print(f'{($difference * 100) / $size_no_deferred:.2f}')")
file_diff=$((file_count_deferred - file_count_no_deferred))

# Calculate main bundle sizes (main.dart.js)
main_no_deferred=$(find "$BUILD_DIR" -name "main.dart.js" 2>/dev/null | head -1)
if [ -n "$main_no_deferred" ]; then
    # Need to rebuild to get accurate main bundle comparison
    echo "Note: For main bundle comparison, check the individual test outputs above" >> "$RESULTS_FILE"
fi

echo "Size without deferred: $((size_no_deferred / 1024)) KB ($file_count_no_deferred files)" >> "$RESULTS_FILE"
echo "Size with deferred: $((size_deferred / 1024)) KB ($file_count_deferred files)" >> "$RESULTS_FILE"
echo "Bundle size difference: ${difference_kb} KB (${percentage}%)" >> "$RESULTS_FILE"
echo "File count difference: ${file_diff} files" >> "$RESULTS_FILE"

# Display summary
echo ""
echo -e "${GREEN}=====================================================${NC}"
echo -e "${GREEN}BENCHMARK SUMMARY${NC}"
echo -e "${GREEN}=====================================================${NC}"
echo -e "main_no_deferred.dart:  $((size_no_deferred / 1024)) KB ($file_count_no_deferred files)"
echo -e "main_deferred.dart:     $((size_deferred / 1024)) KB ($file_count_deferred files)"
echo -e "Bundle difference:      ${difference_kb} KB (${percentage}%)"
echo -e "File difference:        ${file_diff} files"
echo ""
echo -e "${BLUE}Full results saved to: $RESULTS_FILE${NC}"
echo ""
