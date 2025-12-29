# Repository Guidelines

## Project Structure and Module Organization
This is a Flutter app that integrates a Lua VM and Riverpod state management.
- `lib/`: application source. Core Lua engine and providers live under `lib/core/`; UI feature flows are under `lib/features/`.
- `test/`: unit and widget tests (e.g., `test/lua_engine_test.dart`).
- `integration_test/`: end-to-end tests (e.g., `integration_test/app_test.dart`).
- `android/`, `ios/`, `web/`: platform runners and build configs.
- `docs/`: product notes and requirements.
- `LuaDardo/`: local copy of the Dart Lua VM package used by the app; update carefully.

## Build, Test, and Development Commands
Use Flutter tooling from the repo root.
- `flutter pub get`: install Dart/Flutter dependencies.
- `flutter run`: launch on a connected device or simulator.
- `flutter test`: run unit and widget tests.
- `flutter test integration_test/ -d <device_id>`: run integration tests on a target device.
- `flutter test --coverage`: collect coverage from unit/widget tests.
- `flutter analyze`: run static analysis with project lints.
- `flutter build apk` / `flutter build ios` / `flutter build web`: produce release builds.

## Coding Style and Naming Conventions
- Lints: `analysis_options.yaml` enables `flutter_lints`.
- Formatting: use `dart format .` (Dart standard 2-space indentation).
- Naming: `UpperCamelCase` for types, `lowerCamelCase` for variables/functions, `lower_snake_case` for file names.
- Keep Lua-related logic in `lib/core/lua_engine/` and expose state via Riverpod providers in `lib/core/providers/`.

## Testing Guidelines
- Frameworks: `flutter_test` for unit/widget tests; `integration_test` for E2E flows.
- Naming: keep test files as `*_test.dart` under `test/` or `integration_test/`.
- Focus E2E runs with `--plain-name "Use Cases Page"` when targeting a single group.

## Commit and Pull Request Guidelines
- Commit messages in history use short, imperative, sentence-case summaries (e.g., `Add E2E tests for Use Cases Page`).
- Colons appear occasionally for detail (`Initial commit: ...`); no Conventional Commit tags observed.
- PRs should include a clear description, testing notes, and screenshots for UI changes. Link any related issues.
