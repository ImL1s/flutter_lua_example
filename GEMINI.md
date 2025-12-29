# Flutter Lua Example

## Project Overview

A Flutter application demonstrating the integration of a Lua scripting engine using a pure Dart VM ([LuaDardo](https://pub.dev/packages/lua_dardo)). This project serves as a reference implementation for adding dynamic script execution capabilities to Flutter apps, supporting Android, iOS, and Web platforms without native dependencies.

**Key Features:**
*   **Pure Dart Lua VM:** Cross-platform support via `LuaDardo` (Lua 5.3 compatible).
*   **Bidirectional Interop:** Flutter can call Lua functions, and Lua can invoke native Dart callbacks.
*   **State Management:** Deep integration with **Riverpod 3.x** for reactive state synchronization.
*   **Sandbox Mode:** Secure execution environment with potentially dangerous Lua libraries disabled.
*   **Event System:** Custom event emission from Lua to Flutter (e.g., logs, navigation, toasts).

## Architecture

The project follows a clean architecture pattern, separating the core engine logic from feature-specific implementations.

*   `lib/core/lua_engine/`: Contains the abstract `LuaEngine` interface and its concrete implementation (`LuaEngineDart`). This layer handles the low-level VM interactions, type marshalling, and event bridging.
*   `lib/core/providers/`: Riverpod providers that expose the Lua engine and its state to the UI.
*   `lib/features/`: UI implementation and business logic.
    *   `demo/`: Basic interactive playground for testing Lua commands.
    *   `use_cases/`: Real-world scenarios (e.g., form validation, pricing engines) showing practical applications of embedded scripting.
*   `LuaDardo/`: A vendored/embedded package containing the pure Dart implementation of the Lua VM.

## Building and Running

### Prerequisites
*   Flutter SDK 3.9.2+
*   Dart SDK 3.9.2+

### Key Commands

*   **Install Dependencies:**
    ```bash
    flutter pub get
    ```

*   **Run Application:**
    ```bash
    flutter run
    ```

*   **Run Unit & Widget Tests:**
    ```bash
    flutter test
    ```

*   **Run Integration Tests:**
    ```bash
    # Runs all integration tests on a connected device/emulator
    flutter test integration_test/
    ```

## Development Conventions

*   **State Management:** Use **Riverpod** for all application state. The Lua engine itself is exposed via a `NotifierProvider`.
*   **Lua Integration:**
    *   Always use the `LuaEngine` abstract interface rather than the concrete class.
    *   Communication between Lua and Dart should primarily happen through `registerFunction` (for logic) and `emit` (for events).
    *   Lua scripts should be treated as untrusted input; the sandbox mode is enabled by default.
*   **Testing:**
    *   Logic involving the Lua VM should be tested in `test/lua_engine_test.dart`.
    *   Full user flows involving script execution should be covered in `integration_test/`.
*   **Style:** Follow standard Dart/Flutter linting rules (`flutter_lints`).
