# Smart Bill Manager

A **Group Expense Management and Bill-Splitting Application** built with Flutter and Firebase.

## Architecture

This project follows **Feature-First Clean Architecture** with:

- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Functions, FCM)
- **Local Database**: Drift + SQLite
- **Navigation**: go_router
- **Monitoring**: Sentry + Firebase Crashlytics

## Project Structure

```
lib/
├── app/          → App-wide config, routing, theming
├── core/         → Shared infrastructure (database, errors, utils, etc.)
├── features/     → Feature modules (auth, groups, expenses, etc.)
└── main.dart     → Application entry point
```

Each feature follows Clean Architecture layers:

```
feature/
├── data/           → Data sources, DTOs, mappers, repository implementations
├── domain/         → Entities, repository contracts, use cases
└── presentation/   → Controllers, providers, screens, widgets
```

## Getting Started

1. Ensure Flutter SDK is installed (>=3.27.0)
2. Run `flutter pub get`
3. Configure Firebase using FlutterFire CLI
4. Run `flutter run`

## Commands

```bash
flutter pub get              # Install dependencies
dart analyze                 # Static analysis
flutter test                 # Run tests
dart run build_runner build  # Code generation
```
