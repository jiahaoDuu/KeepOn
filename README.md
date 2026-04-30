<p align="center">
  <img src="assets/app_icon.png" alt="KeepOn app icon" width="120">
</p>

# KeepOn

A Flutter task reminder app that helps you keep unfinished work visible and adapt reminders based on device activity.

## Overview

KeepOn is designed for users who want lightweight task tracking combined with smart reminders. Tasks are stored locally, notifications keep incomplete work in view, and reminder frequency adapts when the device stays still.

## Key Features

- Add, edit, complete, and delete tasks
- Persistent local storage with Hive
- Scheduled local notifications for active tasks
- Quiet hours support to avoid unwanted reminders
- Activity-aware reminder frequency using accelerometer data
- Riverpod state management for responsive app behavior

## Built With

- Flutter
- flutter_riverpod
- Hive & hive_flutter
- shared_preferences
- flutter_local_notifications
- sensors_plus
- timezone
- flutter_timezone
- uuid
- intl

## Getting Started

### Prerequisites

- Flutter SDK 3.10 or later
- Android/iOS device or emulator
- Recommended: Visual Studio Code or Android Studio

### Install

1. Open a terminal in the project folder:
   ```bash
   cd KeepOn
   ```
2. Get dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

- `lib/main.dart` — app entry point and service initialization
- `lib/models/` — data models for tasks and settings
- `lib/providers/` — Riverpod providers and task controller logic
- `lib/screens/` — UI pages like task list, editor, settings, splash
- `lib/services/` — notification handling, sensor tracking, storage, settings

## How It Works

- Tasks are saved locally and loaded on startup.
- Notifications are scheduled only for active, incomplete tasks.
- Quiet hours prevent reminders during user-defined sleep times.
- When the device is stationary for a period, reminder frequency is reduced.

## Usage

- Create new tasks with title, optional description, start and end time.
- Mark tasks complete to stop reminders.
- Update settings to adjust reminder interval, enable/disable notifications, and configure quiet hours.

## Notes

- On Android, the app requests notification and exact alarm permissions.
- Timezone handling is managed with `flutter_timezone` and `timezone` packages.

## Contributing

If you want to improve KeepOn, feel free to submit issues or pull requests.

## License

This project is currently private and not published to pub.dev.
