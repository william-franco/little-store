# Changelog

All notable changes to this project are documented in this file.

## 2026-11-22

- `Future<void> main()` so integration_test can await startup without analyze errors.
- Commit: Fix Future<void> main for CI flutter analyze.
  - integration_test can await app.main() without await_only_futures / use_of_void_result.
- Linux CI E2E runs under xvfb-run for headless GitHub Actions runners.
- Flutter CI E2E smoke (CI_SMOKE); await app.main() in integration_test.
- Full-stack Flutter CI uses CI_SMOKE (login screen only); live API E2E is local with backend up.

- Commit: Added backend Docker/Kiri, .NET integration E2E, Flutter Linux E2E, and CI jobs.
  - Flutter integration_test on Linux, app CI E2E step, and refreshed linux host for desktop tests.
- Commit: Use material_ui in integration_test to fix Flutter analyze deprecation.
  - Replaced legacy material.dart imports in integration tests for current Flutter stable analyze.

## 2026-11-14

- Commit: Updated toolchain to Dart SDK ^3.14.0, Gradle 9.5.0, Android Gradle Plugin 9.3.1 and Kotlin 2.4.20.
  - Migrated Material imports to material_ui and upgraded dependencies to their latest major versions.

## 2026-11-07

- Commit: Added url_launcher and a GitHub button to the About dialog.
  - Added the url_launcher ^6.3.3 dependency and a GitHub button inside the About dialog that opens https://github.com/william-franco.

## 2026-11-01

- Commit: Updated Dart SDK to ^3.13.7 and documented Gradle 9.3.1.
  - Aligned the Dart SDK constraint with the test_version reference and updated the README stack table with the Gradle version.

## 2026-10-10

- Commit: Updated Flutter SDK and dependencies.
  - Refreshed dependency versions and related build configuration to keep the project current.

## 2026-09-26

- Commit: Versioned API at /api/v1 with CORS, refresh UI and outlined icons.
  - Applied the change described by this commit and integrated it into the project history.

## 2026-09-19

- Commit: Updated dependencies.
  - Refreshed dependency versions and related build configuration to keep the project current.

## 2026-09-12

- Commit: Standardized README License section.
  - Improved the project documentation and clarified how the project is used or maintained.
- Commit: Updated project documentation.
  - Improved the project documentation and clarified how the project is used or maintained.

## 2026-09-07

- Commit: Re-enabled flutter analyze in CI, propagated ResultPattern and added clean arch tests.
  - Improved automated build, analysis, testing, or delivery checks for the project.

## 2026-08-30

- Commit: Updated dependencies.
  - Refreshed dependency versions and related build configuration to keep the project current.

## 2026-08-22

- Commit: Use == instead of identical in emitState.
  - Applied the change described by this commit and integrated it into the project history.
- Commit: Updated dependencies.
  - Refreshed dependency versions and related build configuration to keep the project current.

## 2026-08-16

- Commit: Updated dependencies.
  - Refreshed dependency versions and related build configuration to keep the project current.
- Commit: Updated dependencies and native folders.
  - Refreshed dependency versions and related build configuration to keep the project current.
- Commit: Updated Android build configuration and removed duplicate reference code.
  - Updated the affected project files and kept the implementation aligned with the current requirements.

## 2026-07-05

- Commit: Corrige CI do Flutter movendo workflow para a raiz do monorepo.
  - Improved automated build, analysis, testing, or delivery checks for the project.
- Commit: Added CI build system.
  - Improved automated build, analysis, testing, or delivery checks for the project.
- Commit: Initial commit.
  - Established the initial project structure and baseline implementation.
