# Matrimony Flutter

Production-grade Flutter frontend for the matrimony backend in this workspace.

## Stack

- Flutter 3
- Dart 3
- Riverpod for state management
- Dio and http for API access
- GoRouter for navigation
- flutter_secure_storage for auth/session storage
- image_picker and cached_network_image for media flows

## Features

- Authentication and OTP login
- Profile dashboard and account entry points
- Profile preferences and partner discovery filters
- Media upload and verification flows
- Shared theme, language, and navigation shells
- Riverpod-based repository and state layers

## Prerequisites

- Flutter stable
- Dart 3+
- Android Studio / Xcode depending on target platform
- Backend API running locally

## Setup

Install dependencies:

```bash
flutter pub get
```

If you are using a device that cannot reach `localhost`, point the app at the backend base URL with a Dart define.

## Running

Local device or simulator:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

iOS simulator:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

## Quality checks

Analyze:

```bash
flutter analyze
```

Test:

```bash
flutter test
```

## Project structure

```text
lib/src/
├── app.dart
├── core/          # API client, config, app bootstrap
├── features/
│   ├── auth/      # login, OTP, session state
│   ├── discovery/ # search and match browsing
│   ├── media/     # profile photos and verification
│   ├── account/   # profile, preferences, privacy entry points
│   ├── interests/ # interest pages and flows
│   └── search/    # search surface
└── shared/        # reusable widgets and shells
```

## Backend contracts used

- `POST /api/auth/register`
- `POST /api/auth/login/password`
- `GET /api/common/static-data`
- `GET /api/v1/profile`
- `GET /api/v1/media/profile-pictures`

The app is structured so additional backend endpoints can be added without changing the feature layout.

## Notes for production

- Keep the backend API URL configurable with `--dart-define`.
- Never commit secrets or environment-specific tokens.
- Run `flutter analyze` and `flutter test` before merging.
- Verify key flows on at least one mobile device/emulator before release.
