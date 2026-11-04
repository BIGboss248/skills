# Flutter Architecture Deep Dive & BLoC Patterns

## 1. Directory Structure

```
lib/
├── main.dart
└── src/
    ├── app.dart
    ├── core/
    │   ├── theme/
    │   │   ├── app_theme.dart
    │   │   └── color_schemes.dart
    │   └── logging/
    │       └── app_logger.dart
    ├── data/
    │   ├── models/
    │   ├── providers/
    │   └── repositories/
    ├── logic/
    │   └── file_sorter/
    │       ├── file_sorter_bloc.dart
    │       ├── file_sorter_event.dart
    │       └── file_sorter_state.dart
    └── presentation/
        ├── screens/
        └── widgets/
```

## 2. BLoC Rules & Immutability

- **Events**: Represent explicit user intents (e.g., `PickFolderRequested`, `PickExcelFileRequested`, `StartSortingProcess`).
- **States**: Immutable snapshots of the UI (e.g., `FileSorterInitial`, `FileSorterReady`, `FileSorterInProgress`, `FileSorterSuccess`, `FileSorterFailure`).
- **Equatable**: Use `package:equatable` for states and events to prevent unnecessary widget rebuilds.
- **Worker Isolates**: Execute long-running file reading, parsing, and zip operations inside `Isolate.run()` to prevent freezing the main UI isolate on desktop.
