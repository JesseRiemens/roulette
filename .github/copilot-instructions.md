# Roulette Web Application
A Flutter web application for decision-making through a digital roulette wheel. Users can add items to the roulette, spin the wheel, and share their lists via URL. Built with Flutter, using BLoC state management and deployed to GitHub Pages.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Prerequisites and Setup
- Install Flutter SDK 3.8.0 or higher: `https://docs.flutter.dev/get-started/install`
- Ensure you have Chrome or another web browser for testing
- For development, Docker with `ghcr.io/cirruslabs/flutter:stable` image can be used

### Bootstrap, Build, and Test Commands
```bash
# Install dependencies - takes 30-60 seconds
flutter pub get

# **NOTE**: Code generation files are already committed to the repository
# If you need to regenerate (only after modifying @freezed or @JsonSerializable files):
# dart run build_runner build --delete-conflicting-outputs
# This command may fail in some environments - the generated files are already present

# NEVER CANCEL: Build for web release - takes 3-5 minutes
# Set timeout to 10+ minutes
# Requires network access to download Flutter Web SDK
flutter build web --release --base-href /roulette/

# NEVER CANCEL: Build for web debug (faster) - takes 2-3 minutes
# Set timeout to 8+ minutes
# Also requires network access for Flutter Web SDK download
flutter build web --debug

# NEVER CANCEL: Run tests - takes 1-2 minutes
# Set timeout to 5+ minutes
# May fail due to dependency resolution issues in containerized environments
flutter test

# Run analysis (linting) - takes 10-30 seconds
# Clean output with no issues when dependencies are properly resolved
flutter analyze

# Format the code
dart format

# Clean build artifacts when needed
flutter clean
```

### Run the Application
```bash
# ALWAYS run pub get first
flutter pub get

# Run in debug mode on web - takes 30-60 seconds to start
# Set timeout to 3+ minutes
# Note: Runs on http://localhost:8080 with auto-generated auth code
flutter run -d web-server --web-port 8080

# Or run in Chrome
flutter run -d chrome
```

### Development Server
- Local development server runs on `http://localhost:8080` when using `--web-port 8080`
- Without specifying port, Flutter assigns a random port
- Server includes auto-generated authentication for security
- Hot reload is supported during development
- Application loads instantly once server is running

## Validation

### NEVER CANCEL Warnings
- **Build commands**: Web builds may take 3-5 minutes. NEVER CANCEL builds. Set timeouts to 10+ minutes.
- **Tests**: Test suite takes 1-2 minutes. NEVER CANCEL. Set timeout to 5+ minutes.
- **Code generation**: build_runner may take 60-120 seconds. NEVER CANCEL.

### Manual Validation Scenarios
Always test these scenarios after making changes:

1. **Basic Functionality Test**:
   - Open the application in a web browser
   - Add at least 2 items to the roulette using the text field
   - Verify items appear in the numbered list with drag handles, edit, and remove buttons
   - Spin the roulette wheel and verify a result is displayed
   - Test the "Copy URL" button and verify the URL contains the items

2. **Item Management Test**:
   - Add multiple items (test with 5+ items)
   - Edit an existing item using the pencil icon
   - Remove an item using the trash icon
   - Reorder items by dragging the drag handles
   - Verify the roulette wheel updates with changes

3. **URL Sharing Test**:
   - Add items to the roulette
   - Copy the URL and open it in a new tab/window
   - Verify the items are restored from the URL parameters

4. **Localization Test**:
   - Verify English text displays correctly
   - Check that Dutch localization exists (though may have untranslated messages)

### Required Pre-commit Validation
- **Critical**: Verify the application builds successfully with either:
  - `flutter build web --debug` (faster build)
  - `flutter build web --release` (production build)
  - `dart format`
  - `flutter analyze`
  - `flutter test`
- **Manual**: Always test the application functionality using the validation scenarios above

## Common Tasks

### Code Generation (Files Currently Committed)
The project uses freezed and json_serializable for code generation. **The generated files are currently committed to the repository but there are plans to remove them and generate on-the-fly during builds** unless you modify files with @freezed or @JsonSerializable annotations:

```bash
# Only run if you modify storage_bloc.dart or other annotated files
# This command may fail in containerized environments
dart run build_runner build --delete-conflicting-outputs

# Alternative: Clean generated files first (if needed)
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Adding New Features
- State management uses BLoC pattern with `StorageCubit` in `lib/bloc/storage_bloc.dart`
- UI components are in `lib/widgets/` (editing_widget.dart, roulette_widget.dart)
- Main screen is `lib/screens/roulette_screen.dart`
- Localization files are in `lib/l10n/`

### Testing
- All widget tests are in the `test/` directory
- Uses `test_helpers.dart` for mock storage setup
- Run specific test: `flutter test test/specific_test.dart`
- Tests cover: widget functionality, BLoC integration, screen behavior

## Architecture and Key Files

### IDE Configuration
- **VS Code**: Launch configurations provided in `.vscode/launch.json`
  - Standard debug mode
  - Profile mode for performance testing  
  - Release mode for production testing
- **Analysis Options**: `analysis_options.yaml` includes Flutter lints
- **Localization Config**: `l10n.yaml` configures internationalization

### Project Structure
```
lib/
├── bloc/                 # BLoC state management
│   ├── storage_bloc.dart
│   ├── storage_bloc.freezed.dart  # Generated - DO NOT EDIT
│   └── storage_bloc.g.dart        # Generated - DO NOT EDIT
├── data/                 # Data layer with conditional imports
│   ├── uri_storage.dart
│   ├── uri_storage_stub.dart      # Non-web implementation
│   └── uri_storage_web.dart       # Web-specific implementation
├── l10n/                 # Internationalization
│   ├── app_localizations.dart     # Generated - DO NOT EDIT
│   ├── app_localizations_en.dart  # Generated - DO NOT EDIT
│   ├── app_localizations_nl.dart  # Generated - DO NOT EDIT
│   ├── intl_en.arb
│   └── int_nl.arb
├── screens/
│   └── roulette_screen.dart       # Main application screen
├── widgets/
│   ├── editing_widget.dart        # Item management UI
│   └── roulette_widget.dart       # Roulette wheel component
└── main.dart                      # Application entry point

.github/
└── workflows/
    └── flutter.yml               # CI/CD pipeline

.vscode/
└── launch.json                   # VS Code debug configurations

test/                             # Comprehensive widget tests
├── editing_widget_test.dart
├── roulette_screen_test.dart
├── main_app_test.dart
└── test_helpers.dart            # Mock storage for tests
```

### Dependencies
Key dependencies in pubspec.yaml:
- `flutter_bloc`: State management
- `hydrated_bloc`: Persistent state
- `roulette`: Roulette wheel widget
- `freezed`: Code generation for data classes
- `json_annotation`: JSON serialization
- `google_fonts`: Typography
- `flutter_localizations`: Internationalization

### Build Pipeline
GitHub Actions workflow (`.github/workflows/flutter.yml`):
1. Uses `ghcr.io/cirruslabs/flutter:stable` container
2. Runs `flutter pub get`
3. Builds with `flutter build web --release --base-href /roulette/`
4. Deploys to GitHub Pages

## Known Issues and Limitations

### Environment-Specific Issues
- **Code Generation**: `dart run build_runner` may fail in some containerized environments
  - Generated files are already committed, so regeneration is typically not needed
  - Only regenerate if you modify @freezed or @JsonSerializable annotated files
  
- **Web Builds**: Both debug and release builds require network access to download Flutter Web SDK
  - May fail in environments with restricted network access
  - No offline alternative available for web builds
  
- **Testing**: Tests may fail in containerized environments due to dependency resolution
  - Tests work in standard Flutter development environments
  - CI has tests commented out due to these dependency issues

### Network Dependencies
- All web builds (debug and release) require network access to download Flutter Web SDK
- Docker container `ghcr.io/cirruslabs/flutter:stable` can be used for builds

### Dependency Constraints
- 31 packages have newer versions with incompatible constraints
- Run `flutter pub outdated` to see available updates
- Dutch localization has 1 untranslated message

### Build Environment
- Builds successfully in Linux environment with Flutter container
- Web deployment target is GitHub Pages with base path `/roulette/`
- Application is responsive and works on mobile browsers

## Troubleshooting

### Common Issues
1. **"Target of URI doesn't exist" errors**: Run `flutter pub get` first
2. **Build failures**: Clean and retry with `flutter clean && flutter pub get`
3. **Code generation errors**: Run `dart run build_runner clean` then `dart run build_runner build`
4. **Test failures**: Ensure mock storage is initialized in test setup

### Recovery Commands
```bash
# Full clean and rebuild
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build web --debug
```

## Performance Expectations
- **Project size**: 21 Dart files total (14 in lib/, 7 in test/)
- Dependency installation: 30-60 seconds
- Code generation: 60-120 seconds (usually not needed)
- Debug web build: 2-3 minutes
- Release web build: 3-5 minutes
- Test suite: 1-2 minutes
- Analysis: 10-30 seconds
- Hot reload during development: 1-3 seconds

## Quick Start Checklist
1. Ensure Flutter SDK 3.8.0+ is installed
2. Run `flutter pub get` (30-60 seconds)
3. Run `flutter build web --debug` to verify build works (2-3 minutes) 
4. Run `flutter run -d web-server` to start development server
5. Open browser to `http://localhost:8080`
6. Test basic functionality: add items, spin roulette, copy URL