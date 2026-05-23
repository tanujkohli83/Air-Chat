# Velvet Chat

Velvet Chat is a Flutter chat application backed by Firebase. It supports email/password authentication, profile setup with avatar selection, searchable users, direct chats, group chats, unread counts, typing indicators, and Firebase Cloud Messaging token registration.

## Tech Stack

- Flutter and Dart
- Riverpod for state management
- Firebase Authentication
- Cloud Firestore
- Firebase Cloud Messaging
- Image Picker
- Google Fonts

## Features

- Sign up and sign in with email and password
- Profile setup with display name and avatar
- Realtime inbox powered by Firestore streams
- Search users by display name
- Start one-to-one conversations
- Create group conversations
- Send realtime text messages
- Typing indicators
- Unread message counts
- Device token registration for push notifications
- Responsive mobile-first UI with custom theme and reusable widgets

## Project Structure

```text
lib/
  app.dart
  main.dart
  firebase_options.dart        # generated locally by FlutterFire CLI
  core/
    models/                    # chat, user, and conversation models
    services/                  # Firebase repositories and notification service
    theme/                     # app colors and theme
    utils/                     # shared helpers
    widgets/                   # reusable UI components
  features/
    auth/                      # sign in and sign up
    chat/                      # chat providers and room UI
    dashboard/                 # inbox
    profile_setup/             # profile completion flow
    search_user/               # user search and chat creation
```

## Requirements

- Flutter SDK compatible with Dart `^3.11.0`
- A Firebase project
- Firebase Authentication with Email/Password enabled
- Cloud Firestore enabled
- Firebase Cloud Messaging configured for the platforms you run
- FlutterFire CLI if you need to regenerate Firebase options

## Setup

1. Install dependencies:

   ```bash
   flutter pub get
   ```

2. Configure Firebase for your local project:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   This generates `lib/firebase_options.dart` and platform Firebase config files such as `android/app/google-services.json`. These files are ignored by git because they are project-specific.

3. Run the app:

   ```bash
   flutter run
   ```

4. Run tests:

   ```bash
   flutter test
   ```

## Firestore Data Model

The app expects these top-level collections:

- `users`: user profile, online status, avatar data, and FCM token
- `chats`: direct and group conversation metadata
- `chats/{chatId}/messages`: text messages for each conversation

Direct chat IDs are generated from sorted participant IDs. Group chats use an auto-generated Firestore document ID.

## Private Files

Do not commit Firebase config, local environment files, signing keys, build outputs, or IDE metadata. The `.gitignore` is configured for those files.

If any private file was already committed before it was added to `.gitignore`, remove it from git tracking without deleting the local file:

```bash
git rm --cached lib/firebase_options.dart
git rm --cached android/app/google-services.json
```

Then commit the `.gitignore` update.
