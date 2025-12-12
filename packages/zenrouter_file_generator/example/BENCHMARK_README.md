# Deferred Import Benchmark

This document explains the benchmark script created to measure the impact of the `deferredImport` setting on generated JavaScript file sizes.

## Quick Start

Run the benchmark from the example directory:

```bash
./benchmark_deferred.sh
```

This will:
1. Build the app with `deferredImport: false`
2. Measure the JS file sizes
3. Build the app with `deferredImport: true`
4. Measure the JS file sizes
5. Generate a comparison report

## Results

The benchmark will create `benchmark_results.txt` with:
- Individual JS file sizes for each configuration
- Total sizes for both configurations
- Difference in KB and percentage

## Manual Testing

If you want to manually test a specific configuration:

### Set deferredImport to false
```bash
cat > build.yaml << EOF
targets:
  \$default:
    builders:
      zenrouter_file_generator|zen_coordinator:
        options:
          deferredImport: false
EOF

flutter pub get
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter build web --release
```

### Set deferredImport to true
```bash
cat > build.yaml << EOF
targets:
  \$default:
    builders:
      zenrouter_file_generator|zen_coordinator:
        options:
          deferredImport: true
EOF

flutter pub get
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs
flutter build web --release
```

### Measure sizes
```bash
find build/web -name "*.js" -type f -exec bash -c 'echo "$(basename {}): $(($(stat -f%z "{}" 2>/dev/null || stat -c%s "{}" 2>/dev/null) / 1024)) KB"' \;
```

## Expected Outcomes

- **With `deferredImport: true`**: The app should split routes into separate JS chunks that load on demand, potentially resulting in a smaller initial bundle size but more total files.
- **With `deferredImport: false`**: All routes are included in the main bundle, resulting in fewer files but potentially a larger initial bundle.
