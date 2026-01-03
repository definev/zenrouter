# ZenRouter Documentation

Interactive documentation application for ZenRouter - teaching the Coordinator pattern and file-based routing by embodying these patterns in its own architecture.

## Overview

This Flutter web application serves as the official documentation for ZenRouter, demonstrating best practices and patterns through its own implementation.

## Development

### Running the App

```bash
flutter run -d chrome
```

### Building for Web

```bash
flutter build web
```

## Assets & Icons

### Logo Files

The project includes two logo variants:
- `assets/logo_light.png` - Light theme logo (512x512)
- `assets/logo_dark.png` - Dark theme logo (512x512)

### Generating App Icons & Favicons

This project uses [`icons_launcher`](https://pub.dev/packages/icons_launcher) to automatically generate app icons and favicons for all platforms from the logo.

To regenerate icons after updating the logo:

```bash
dart run icons_launcher:create
```

This will generate:
- **Android**: App icons for all densities (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- **iOS**: App icons for all required sizes (iPhone, iPad, App Store)
- **Web**: Favicons (16x16, 32x32, 48x48) and PWA icons (192x192, 512x512)

### Icon Configuration

The icon configuration is defined in `pubspec.yaml`:

```yaml
icons_launcher:
  image_path: "assets/logo_light.png"
  platforms:
    android:
      enable: true
    ios:
      enable: true
    web:
      enable: true
      favicon:
        enable: true
```

## Architecture

This documentation app practices what it preaches by using:
- **ZenRouter** for file-based routing
- **Coordinator Pattern** for navigation flow management
- **Literary Programming Style** inspired by Trollope and Knuth

## Related Packages

- [zenrouter](../zenrouter) - Core routing package
- [zenrouter_file_generator](../zenrouter_file_generator) - Code generation for file-based routes
- [zenrouter_devtools](../zenrouter_devtools) - DevTools extension for debugging

## License

See [LICENSE](LICENSE) file for details.
