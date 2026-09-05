# Smart Bill Manager

> A production-ready, cross-platform **Group Expense Management & Bill-Splitting** application built with **Flutter** and **Firebase**.

Smart Bill Manager makes shared-expense management simple for friends, families, roommates, colleagues, and travel groups. Create a group, add registered members, log shared expenses, and let the app automatically calculate each participant's share, track payments, and surface outstanding balances — all presented through a distinctive **hierarchical, formation-style member visualization**.

---

## Table of Contents

- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Security Model](#security-model)
- [Getting Started](#getting-started)
- [Common Commands](#common-commands)
- [Contributing](#contributing)
- [License](#license)

---

## Key Features

- **Authentication & Profiles**
  - Secure sign-in via Firebase Auth (email/password + Google Sign-In)
  - Multi-step registration flow with profile details and verification
  - Phone-number-based user search for adding members

- **Groups**
  - Create and manage multiple independent expense groups (Friends, Family, Roommates, Trip, etc.)
  - Each group is a self-contained financial boundary with its own members, expenses, and balances
  - Add members by searching registered users by mobile number

- **Hierarchical Member Visualization**
  - Members are arranged in a football-formation-inspired layout (without looking like a sports app)
  - Each member node shows avatar, name, amount to pay, and payment status (Paid / Partially Paid / Due)
  - Communicates the group → member → financial-responsibility relationship

- **Expense Management**
  - Create expenses within a group with title, total amount, description, payer, and participants
  - Automatic equal-split calculation (architecture supports future split methods: percentage, exact, shares)
  - Per-expense history with full financial breakdown

- **Payment Tracking**
  - Per-participant payment state: total share, amount paid, remaining, status
  - Request/verify payment workflow
  - Group-level financial overview: total expenses, total paid, total outstanding

- **Dashboard**
  - Cross-group overview of the user's financial position
  - Quick access to recent activity and outstanding balances

- **Notifications**
  - Firebase Cloud Messaging (FCM) for payment requests, verifications, and group updates

- **Settlements & Activity**
  - Settlement tracking between members
  - Activity feed for transparency across groups

- **Production-grade Foundations**
  - Centralized design system, theme, validators, formatters, and error handling
  - Crash & performance monitoring via Sentry + Firebase Crashlytics
  - Offline-friendly local database (Drift/SQLite) alongside Firestore

---

## Tech Stack

| Layer              | Technology                                                         |
| ------------------ | ----------------------------------------------------------------- |
| Framework          | Flutter (Dart SDK `^3.6.0`)                                       |
| State Management   | Riverpod (`flutter_riverpod`)                                     |
| Backend            | Firebase (Auth, Firestore, Storage, Cloud Functions, FCM, App Check) |
| Local Database     | Drift + SQLite (`drift_flutter`)                                  |
| Navigation         | go_router                                                          |
| Serialization      | `json_annotation` / `json_serializable`                           |
| Security           | `flutter_secure_storage`                                          |
| Monitoring         | Sentry Flutter, Firebase Crashlytics                              |
| Charts             | fl_chart                                                          |
| Media              | image_picker, Cloudinary (via `http`)                             |
| Auth providers     | Google Sign-In, country_picker                                    |
| Commit workflow    | Husky + Commitlint + Commitizen (Conventional Commits)            |

---

## Architecture

The app follows **Feature-First Clean Architecture** with strict layer separation:

```
Presentation  →  State Management  →  Business Logic  →  Repositories  →  Data Sources  →  Backend / Database
```

Each feature is an isolated module with three layers:

```
feature/
├── data/           → Data sources, DTOs/models, mappers, repository implementations
├── domain/         → Entities, repository contracts, use cases
└── presentation/   → Riverpod providers/controllers, screens, widgets
```

Shared infrastructure (design system, theme, constants, validators, formatters, error handling, utilities, common widgets) is centralized under `core/` and `app/`, so business rules are never duplicated across screens.

### Feature Modules

`activity`, `auth`, `dashboard`, `expenses`, `groups`, `notifications`, `payments`, `profile`, `settlements`, `showcase`, `users`

---

## Project Structure

```
lib/
├── app/            → App-wide config, routing, theming & design system
├── core/           → Shared infrastructure (database, errors, utils, validators, widgets, ...)
├── features/       → Feature modules (auth, groups, expenses, payments, ...)
└── main.dart       → Application entry point

functions/          → Firebase Cloud Functions (auth, expenses, notifications, payments, settlements)
docs/               → Project description & documentation
firestore.rules     → Firestore security rules (membership-based authorization)
storage.rules       → Firebase Storage security rules
```

---

## Security Model

Authentication alone is **not** treated as authorization. Access is enforced at the database level via `firestore.rules`:

- **Users** — any authenticated user can read user docs (for member search); writes are owner-only.
- **Groups** — only members listed in `member_ids` can read; only the owner can update/delete.
- **Bills** (subcollection under `groups/{groupId}/bills`) — access is gated by parent group membership via `get()`.
- **Default deny** — everything else is closed.

This guarantees that one group's financial data is never exposed to non-members, even if the UI were bypassed.

---

## Getting Started

### Prerequisites

- Flutter SDK (`>= 3.27.0`, Dart `^3.6.0`)
- A configured Firebase project
- Node.js (only for the commit-lint / Husky tooling)

### Setup

1. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

2. **Configure Firebase**

   Use the FlutterFire CLI to wire up platform-specific Firebase config:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Ensure Auth, Firestore, Storage, Cloud Functions, FCM, App Check, and Crashlytics are enabled in the Firebase console, then deploy the rules:

   ```bash
   firebase deploy --only firestore:rules,storage
   ```

3. **Generate code** (Drift, JSON serializable)

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**

   ```bash
   flutter run
   ```

---

## Common Commands

```bash
flutter pub get                              # Install dependencies
dart run build_runner build                  # Run code generation
dart run build_runner watch --delete-conflicting-outputs   # Watch mode codegen
dart analyze                                 # Static analysis
flutter test                                 # Run tests
flutter run                                  # Run the app
npm run commit                               # Interactive Conventional Commit (Commitizen)
firebase deploy --only firestore:rules,storage  # Deploy security rules
```

---

## Contributing

This repo uses **Conventional Commits** enforced via Husky + Commitlint.

- Use `npm run commit` for an interactive commit prompt, or follow the `type(scope): message` format (e.g. `feat(bills): add per-participant payment tracking`).
- Run `dart analyze` and `flutter test` before pushing.
- Keep features isolated under `lib/features/<feature>/` and respect the Clean Architecture layer boundaries.

---

## License

ISC — see the repository metadata. This project is intended as a production reference implementation; please review your organization's licensing requirements before reuse.
