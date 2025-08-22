# Roulette Web Application

A Flutter web application for decision-making through a digital roulette wheel. Users can add items to the roulette, spin the wheel, and share their lists via URL.

## Development Setup

### Prerequisites
- Flutter SDK 3.8.0 or higher
- Chrome or another web browser for testing

### Getting Started

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate required code:**
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

3. **Run the application:**
   ```bash
   flutter run -d chrome
   # or for web server
   flutter run -d web-server --web-port 8080
   ```

## Code Generation

This project uses automatic code generation for:
- **Freezed models** (`*.freezed.dart`) - Immutable data classes
- **JSON serialization** (`*.g.dart`) - JSON serialization/deserialization  
- **Localization** (`app_localizations*.dart`) - Internationalization files

### Important Notes

- **Generated files are not committed** to version control
- Code generation runs automatically during CI/CD builds
- You must run code generation locally after changes to annotated files

### When to Run Code Generation

Run code generation when you modify files containing:
- `@freezed` annotations
- `@JsonSerializable` annotations  
- Localization files (`*.arb`)

### Commands

```bash
# Generate code (development)
flutter packages pub run build_runner build --delete-conflicting-outputs

# Clean and regenerate (if needed)
flutter packages pub run build_runner clean
flutter packages pub run build_runner build --delete-conflicting-outputs

# Watch mode (regenerates on file changes)
flutter packages pub run build_runner watch
```

## Build Process

The build process includes:

1. **Install dependencies:** `flutter pub get`
2. **Generate code:** `flutter packages pub run build_runner build --delete-conflicting-outputs`
3. **Build application:** `flutter build web --release`

This ensures all generated files are up-to-date and the build is reproducible.

## CI/CD Integration

All workflows automatically include code generation:
- **Analysis workflow** - Generates code before running `flutter analyze`
- **Test workflow** - Generates code before running `flutter test`  
- **Build/Deploy workflow** - Generates code before building for production

## Development Notes

This was all vibe coded, please don't judge code quality D:
