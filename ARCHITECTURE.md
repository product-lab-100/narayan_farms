# Architecture Guidelines

## 🏗️ Architecture Pattern

This project follows a **Feature-First, Clean Architecture** approach, adapted for Flutter using Bloc. The goal is to separate concerns, making the codebase scalable, testable, and maintainable.

### Layers

1.  **Presentation Layer (`view`)**:
    - Contains Screens and Widgets.
    - **Responsibility**: Render UI based on state and dispatch events to the logic layer.
    - **Rules**: Dumb UI. logic should be minimal. Depends on `view_model`.

2.  **Application Logic Layer (`view_model` / `bloc`)**:
    - Contains Blocs or Cubits.
    - **Responsibility**: Handle business logic, manage UI state, and communicate with repositories.
    - **Rules**: Does not know about UI implementation details (no BuildContext usage ideally). Depends on `model`.

3.  **Domain/Data Layer (`model`)**:
    - Contains Repositories, Data Sources, and Entitites/Models.
    - **Responsibility**: Fetch data from external sources (Firebase, API) and map it to domain models.
    - **Rules**: Independent of UI and State Management.

## 🧩 State Management

We use **[flutter_bloc](https://pub.dev/packages/flutter_bloc)** for state management.

- **Events**: Define what happens (e.g., `LoginButtonPressed`).
- **States**: Define what the UI shows (e.g., `AuthLoading`, `AuthAuthenticated`).
- **Bloc**: Takes Events and emits States.

## 💉 Dependency Injection

Dependency Injection is handled using `RepositoryProvider` and `BlocProvider` from the `flutter_bloc` package.

- **Global Providers**: Defined in `main.dart` (or a dedicated DI file). These are available throughout the app lifecycle.
  ```dart
  MultiRepositoryProvider(
    providers: [
      RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
    ],
    child: ...
  )
  ```
- **Scoped Providers**: Defined at the feature level or route level when a dependency is only needed for a specific subtree.

## 📂 Folder Structure

We organize code primarily by **Feature**, then by **Layer**.

```
lib/
├── core/                  # Core functionality shared across features
│   ├── constants/         # App-wide constants
│   ├── services/          # Infrastructure services (Network, Storage)
│   ├── theme/             # App theming and styling
│   ├── utils/             # Helper functions and extensions
│   └── widgets/           # Reusable generic widgets
│
├── features/
│   └── [feature_name]/    # e.g., auth, inventory
│       ├── model/         # Repositories & Models
│       ├── view/          # Screens & Widgets
│       └── view_model/    # Blocs / Cubits
│
└── main.dart              # Entry point
```

## 🛡️ Best Practices

- **Immutability**: Use `Equatable` for States and Events to ensure proper comparison and avoid unnecessary rebuilds.
- **Strict Typing**: Avoid `dynamic` wherever possible.
- **Async/Await**: properly handle Futures and Streams.
- **Linting**: Follow the rules defined in `analysis_options.yaml`.
