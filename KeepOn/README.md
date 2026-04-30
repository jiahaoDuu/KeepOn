<div align="center">

<img src="assets/app_icon.png" alt="KeepOn app icon" width="120">

# KeepOn

**Stay aware. Finish before time runs out.**

A Flutter task reminder app that keeps unfinished work visible, schedules persistent local notifications, and adapts reminder frequency using device activity.

[![Flutter](https://img.shields.io/badge/Flutter-Android-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![State](https://img.shields.io/badge/state-Riverpod-40B5A4)](#architecture)
[![Storage](https://img.shields.io/badge/storage-Hive%20%2B%20SharedPreferences-F5C84B)](#architecture)
[![Notifications](https://img.shields.io/badge/notifications-local%20scheduled-24786A)](#how-it-works)

UCL CASA0015 - Mobile Systems & Interactions - Individual Coursework 2025/26

</div>

---

## Table Of Contents

- [Problem](#problem)
- [Connected Environments Theme](#connected-environments-theme)
- [User Persona And Storyboard](#user-persona-and-storyboard)
- [Feature Overview](#feature-overview)
- [Sensors Used](#sensors-used)
- [Widget Showcase](#widget-showcase)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Code Navigation](#code-navigation)
- [Getting Started](#getting-started)
- [Permissions](#permissions)
- [How It Works](#how-it-works)
- [Design System](#design-system)
- [Testing And Quality](#testing-and-quality)
- [Known Limitations](#known-limitations)
- [Roadmap](#roadmap)
- [Author](#author)
- [License](#license)

---

## Problem

Task apps are easy to ignore once a task has been written down. A due date in a list helps with planning, but it does not keep the task present while time is passing. Calendar alarms can help, but they are often one-off events: dismiss the notification once and the task quietly disappears from attention.

**KeepOn is designed for time-bound tasks that should stay visible until they are completed or expired.** The app combines a lightweight task list with repeated local reminders, quiet hours, and activity-aware scheduling so unfinished work remains in the user's awareness without becoming a full project-management system.

## Connected Environments Theme

KeepOn fits the Connected Environments brief by responding to the user's device context:

- **On-device sensing:** accelerometer readings are monitored through `sensors_plus`.
- **Context adaptation:** when the device remains stationary for a sustained period, KeepOn reduces reminder frequency by increasing the interval multiplier.
- **Local persistence:** tasks and settings survive app restarts through Hive and SharedPreferences.
- **Local notifications:** reminders are scheduled on-device, so the core reminder loop does not require a cloud service or external API.

The app is intentionally local-first: the task data, settings, sensing logic, and notification scheduling all live on the device.

## User Persona And Storyboard

### Persona - "Alex, the deadline juggler"

Alex is a postgraduate student balancing coursework, admin tasks, and personal errands. They do not need a complex Kanban board, but they do need small tasks to keep resurfacing until they are done. A task like "submit the form before 17:00" should not vanish after a single reminder.

Alex wants:

- a quick way to create a task with a clear time window;
- persistent reminders until completion or expiry;
- a quiet period during sleep hours;
- a simple home screen that answers "what needs attention next?"

### Storyboard

```text
1. LAUNCH
   Splash screen opens with the KeepOn identity.

2. CREATE
   Alex adds a task with a title, optional notes, start time, and end time.

3. TRACK
   The home screen shows the next focus, active/pending counts, urgency colour,
   and time remaining.

4. REMIND
   Local notifications repeat while the task is active and incomplete.

5. ADAPT
   If the device stays stationary, the reminder interval is adjusted.

6. FINISH
   Alex marks the task complete. It leaves the active list and reminders stop.
```

## Feature Overview

| # | Feature | Status | Notes |
|---|---|:---:|---|
| 1 | Splash screen | Done | Branded launch screen before the main task list |
| 2 | Task list dashboard | Done | Next focus panel, active/pending/urgent counts, visible task cards |
| 3 | Create and edit tasks | Done | Title, optional description, start time, end time |
| 4 | Complete and delete tasks | Done | Completed and expired tasks are hidden from the active list |
| 5 | Local persistence | Done | Hive stores tasks; SharedPreferences stores settings |
| 6 | Scheduled notifications | Done | Repeating local reminders for active incomplete tasks |
| 7 | Quiet hours | Done | User-defined start/end times suppress reminders |
| 8 | Activity-aware interval | Done | Accelerometer-based stationary detection changes reminder frequency |
| 9 | Settings page | Done | Notification toggle, interval selector, quiet-hours picker |
| 10 | Riverpod state management | Done | Central task controller keeps UI reactive |
| 11 | Android permissions | Done | Notification, exact alarm, vibration, boot receiver declarations |
| 12 | Tests and analysis | Done | Model tests plus `flutter analyze` |

## Sensors Used

| Sensor | Package | Purpose | Implementation Detail |
|---|---|---|---|
| Accelerometer | `sensors_plus` | Detect whether the device has remained still | `SensorService` compares movement against gravity and marks the device stationary after a 10-minute window |

The stationary state is exposed to the app through Riverpod. When it changes, active task reminders are rescheduled with a different interval multiplier.

## Widget Showcase

KeepOn uses standard Flutter and Material 3 widgets, but combines them into a focused reminder workflow:

- **Navigation:** `MaterialApp`, `Navigator`, `MaterialPageRoute`, `SliverAppBar`
- **Task dashboard:** `CustomScrollView`, `SliverFillRemaining`, `SliverList`, `Card`, `LinearProgressIndicator`
- **Inputs:** `TextFormField`, `showDatePicker`, `showTimePicker`, `DropdownButton`, `SwitchListTile`
- **Actions:** `FloatingActionButton.extended`, `FilledButton.icon`, `PopupMenuButton`, `Checkbox`
- **Feedback:** `SnackBar`, empty state, urgency colour indicators, status pills
- **Assets:** app icon reused in splash, empty state, and README branding

## Architecture

```text
KeepOnApp
  |
  +-- SplashScreen
  |
  +-- TaskListScreen
      |
      +-- TaskEditScreen
      +-- SettingsScreen

ProviderScope
  |
  +-- TaskController (Riverpod Notifier)
      |
      +-- StorageService          -> Hive task box
      +-- SettingsService         -> SharedPreferences
      +-- NotificationService     -> flutter_local_notifications + timezone
      +-- SensorService           -> accelerometer stream
```

### Design Choices

- **Local-first state:** UI updates immediately from Riverpod state; persistence follows through local services.
- **Non-blocking reminders:** task creation updates the list first, while notification scheduling continues in the background.
- **Single source of task truth:** `TaskController` owns task creation, update, deletion, completion, and rescheduling.
- **Time-aware visibility:** completed and expired tasks are filtered out of the active list.
- **Settings-driven scheduling:** notification interval, quiet hours, and notification toggle are read when scheduling reminders.

## Project Structure

```text
keepon/
|-- assets/
|   `-- app_icon.png
|-- lib/
|   |-- main.dart
|   |-- models/
|   |   |-- app_settings.dart
|   |   `-- task.dart
|   |-- providers/
|   |   `-- task_provider.dart
|   |-- screens/
|   |   |-- splash_screen.dart
|   |   |-- task_list_screen.dart
|   |   |-- task_edit_screen.dart
|   |   `-- settings_screen.dart
|   `-- services/
|       |-- notification_service.dart
|       |-- sensor_service.dart
|       |-- settings_service.dart
|       `-- storage_service.dart
|-- test/
|   `-- widget_test.dart
|-- android/
|-- pubspec.yaml
`-- README.md
```

## Code Navigation

| Feature | File | Main Elements |
|---|---|---|
| App startup and dependency overrides | `lib/main.dart` | `KeepOnApp`, `ProviderScope`, service initialization |
| Task state and business logic | `lib/providers/task_provider.dart` | `TaskController`, `AppState`, `nowProvider` |
| Task model and urgency logic | `lib/models/task.dart` | `KeepOnTask`, `TaskStatus`, `urgencyColorAt()` |
| Settings model | `lib/models/app_settings.dart` | `AppSettings.defaults`, `copyWith()` |
| Home task list | `lib/screens/task_list_screen.dart` | `TaskListScreen`, `_AwarenessPanel`, `_TaskCard` |
| Task creation/editing | `lib/screens/task_edit_screen.dart` | form validation, date/time pickers, save flow |
| Settings UI | `lib/screens/settings_screen.dart` | notification toggle, interval dropdown, quiet-hour pickers |
| Local task storage | `lib/services/storage_service.dart` | Hive task loading/saving/deletion |
| Settings storage | `lib/services/settings_service.dart` | SharedPreferences persistence |
| Notification scheduling | `lib/services/notification_service.dart` | local notification initialization and recurring schedules |
| Motion sensing | `lib/services/sensor_service.dart` | accelerometer stream and stationary detection |

## Getting Started

### Prerequisites

- Flutter SDK with Dart 3.10 or later
- Android Studio or Visual Studio Code
- Android device or emulator

### Install

```bash
cd KeepOn
flutter pub get
```

### Run

```bash
flutter run
```

### Test

```bash
dart format lib test
flutter analyze
flutter test
```

### Build Debug APK

```bash
flutter build apk --debug
```

## Permissions

The Android manifest declares the permissions needed for local reminders:

| Permission | Used For |
|---|---|
| `POST_NOTIFICATIONS` | Showing reminders on Android 13+ |
| `SCHEDULE_EXACT_ALARM` | Scheduling precise reminder times |
| `RECEIVE_BOOT_COMPLETED` | Restoring scheduled notifications after reboot |
| `VIBRATE` | Notification vibration feedback |

Notification and exact-alarm permissions are requested during `NotificationService.init()` where Android supports runtime prompts for them.

## How It Works

1. On launch, services are initialized before `KeepOnApp` starts.
2. `TaskController` loads saved tasks and settings.
3. The task list watches Riverpod state and displays only active, pending tasks.
4. Creating a task updates state and saves it locally.
5. Notification scheduling runs in the background for active incomplete tasks.
6. Quiet hours shift reminder times outside the configured quiet window.
7. The accelerometer service monitors stillness and triggers reminder rescheduling when context changes.

## Design System

KeepOn uses a restrained Material 3 visual style:

- seed colour: `0xff24786a`;
- light scaffold background: `0xfff5f7f4`;
- dark green emphasis panels for focus and settings;
- yellow accent blocks for important icons;
- 8 px radius across cards, buttons, panels, and chips;
- urgency colours from the task model: red for near deadlines, amber for medium urgency, green for later tasks.

The UI is intentionally compact and task-focused: the first screen is the usable task dashboard, not a marketing page.

## Testing And Quality

Current automated coverage focuses on task-domain behaviour:

- task status transitions: pending, active, completed, expired;
- urgency colour thresholds based on remaining days.

Quality checks used during development:

```bash
dart format lib test
flutter analyze
flutter test
```

## Known Limitations

- Android is the primary supported target in this repository.
- There is no cloud sync; all data is local to the device.
- Completed and expired tasks are hidden rather than shown in a history page.
- Notification scheduling is local and depends on platform alarm behaviour and permissions.
- The accelerometer adaptation is intentionally simple: it detects stillness, not rich activity categories such as walking, commuting, or sleeping.

## Roadmap

Planned improvements:

1. Add a completed/expired task history view.
2. Add search and filtering for larger task lists.
3. Add notification error feedback when platform permission is denied.
4. Add richer activity modes beyond stationary/not-stationary.
5. Add screenshots and a short demo GIF under `docs/` for final presentation.
6. Prepare a signed release APK for device installation.

## Author

UCL CASA0015 Mobile Systems & Interactions coursework project.

## License

This project is currently private and is not published to pub.dev.
