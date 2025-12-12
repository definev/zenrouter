#!/bin/bash

# Benchmark script to measure the impact of deferredImport on JS file sizes
# This script toggles deferredImport between true and false, builds the web app,
# and measures the resulting JS file sizes

set -e

echo "======================================"
echo "Deferred Import Benchmark Script"
echo "======================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_YAML="$SCRIPT_DIR/build.yaml"
BUILD_DIR="$SCRIPT_DIR/build/web"
RESULTS_FILE="$SCRIPT_DIR/benchmark_results.txt"

# Function to update build.yaml with deferredImport value
update_build_yaml() {
    local value=$1
    echo -e "${BLUE}Updating build.yaml with deferredImport: $value${NC}"
    
    cat > "$BUILD_YAML" << EOF
targets:
  \$default:
    builders:
      zenrouter_file_generator|zen_coordinator:
        options:
          deferredImport: $value
EOF
}

# Function to clean build directory
clean_build() {
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    if [ -d "$BUILD_DIR" ]; then
        rm -rf "$BUILD_DIR"
    fi
}

# Function to run flutter build
run_build() {
    echo -e "${BLUE}Running flutter pub get...${NC}"
    flutter pub get
    
    echo -e "${BLUE}Running build_runner clean...${NC}"
    flutter packages pub run build_runner clean
    
    echo -e "${BLUE}Running build_runner build...${NC}"
    flutter packages pub run build_runner build --delete-conflicting-outputs
    
    echo -e "${BLUE}Building web app...${NC}"
    flutter build web --release
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
    done < <(find "$BUILD_DIR" -name "*.js" -type f -print0)
    
    local total_kb=$((total_size / 1024))
    local total_mb=$(echo "scale=2; $total_size / 1024 / 1024" | bc)
    
    echo "----------------------------------------"
    echo -e "${GREEN}Total JS size: ${total_kb} KB (${total_mb} MB)${NC}"
    echo ""
    
    # Return total size
    echo "$total_size"
}

# Initialize results file
echo "Deferred Import Benchmark Results" > "$RESULTS_FILE"
echo "Generated: $(date)" >> "$RESULTS_FILE"
echo "======================================" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Benchmark with deferredImport: false
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Benchmark 1: deferredImport = false${NC}"
echo -e "${YELLOW}========================================${NC}"
clean_build
update_build_yaml "false"
run_build
size_without_deferred=$(measure_js_files "deferredImport = false")

echo "deferredImport: false" >> "$RESULTS_FILE"
echo "----------------------------------------" >> "$RESULTS_FILE"
find "$BUILD_DIR" -name "*.js" -type f -exec bash -c 'echo "  $(basename {}): $(($(stat -f%z "{}" 2>/dev/null || stat -c%s "{}" 2>/dev/null) / 1024)) KB"' \; >> "$RESULTS_FILE"
echo "Total: $((size_without_deferred / 1024)) KB" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Benchmark with deferredImport: true
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Benchmark 2: deferredImport = true${NC}"
echo -e "${YELLOW}========================================${NC}"
clean_build
update_build_yaml "true"
run_build
size_with_deferred=$(measure_js_files "deferredImport = true")

echo "deferredImport: true" >> "$RESULTS_FILE"
echo "----------------------------------------" >> "$RESULTS_FILE"
find "$BUILD_DIR" -name "*.js" -type f -exec bash -c 'echo "  $(basename {}): $(($(stat -f%z "{}" 2>/dev/null || stat -c%s "{}" 2>/dev/null) / 1024)) KB"' \; >> "$RESULTS_FILE"
echo "Total: $((size_with_deferred / 1024)) KB" >> "$RESULTS_FILE"
echo "" >> "$RESULTS_FILE"

# Calculate difference
echo "======================================" >> "$RESULTS_FILE"
echo "Comparison" >> "$RESULTS_FILE"
echo "======================================" >> "$RESULTS_FILE"
difference=$((size_with_deferred - size_without_deferred))
difference_kb=$((difference / 1024))
percentage=$(echo "scale=2; ($difference * 100) / $size_without_deferred" | bc)

echo "Size without deferred: $((size_without_deferred / 1024)) KB" >> "$RESULTS_FILE"
echo "Size with deferred: $((size_with_deferred / 1024)) KB" >> "$RESULTS_FILE"
echo "Difference: ${difference_kb} KB (${percentage}%)" >> "$RESULTS_FILE"

# Display summary
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}BENCHMARK SUMMARY${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "deferredImport=false: $((size_without_deferred / 1024)) KB"
echo -e "deferredImport=true:  $((size_with_deferred / 1024)) KB"
echo -e "Difference:           ${difference_kb} KB (${percentage}%)"
echo ""
echo -e "${BLUE}Full results saved to: $RESULTS_FILE${NC}"
echo ""
