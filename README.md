# Narayan Farms

Welcome to the **Narayan Farms** application repository. This project is a Flutter-based mobile application powered by Firebase, designed to manage farm operations and customer interactions.

## 🚀 Project Overview

Narayan Farms is built to provide a seamless experience for users, leveraging modern mobile development practices. The application currently features a robust Authentication system and is structured to scale with additional domains such as inventory management, ordering, and logistics.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK ^3.10.4)
- **Language**: [Dart](https://dart.dev/)
- **Backend/Services**: [Firebase](https://firebase.google.com/)
  - Firebase Core
  - Firebase Auth
  - Cloud Firestore
- **State Management**: [Bloc / Cubit](https://pub.dev/packages/flutter_bloc)
- **Dependency Injection**: `RepositoryProvider` (from `flutter_bloc`)
- **Equality Comparison**: [Equatable](https://pub.dev/packages/equatable)

## 🏁 Getting Started

### Prerequisites

- **Flutter SDK**: Ensure you have Flutter installed (version 3.10.4 or higher).
- **Dart SDK**: Included with Flutter.
- **Firebase CLI**: Required for configuring Firebase services.

### Installation

1.  **Clone the repository:**

    ```bash
    git clone <repository-url>
    cd narayan_farms
    ```

2.  **Install Dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Firebase Configuration:**
    Ensure `firebase_options.dart` is present in `lib/`. If not, run:
    ```bash
    flutterfire configure
    ```

### Running the App

To run the application in debug mode:

```bash
flutter run
```

## 📂 Project Structure

The project follows a **Feature-First** architecture with a clear separation between core utilities and feature-specific logic.

```
lib/
├── core/                # Shared utilities, constants, themes, and widgets
├── features/            # Feature modules (e.g., Auth)
│   └── auth/            # Authentication feature
│       ├── model/       # Data models and repositories
│       ├── view/        # UI Screens and Widgets
│       └── view_model/  # Bloc/Cubit for state management
├── main.dart            # Application entry point and DI setup
├── firebase_options.dart # Firebase configuration
└── dependency_injection/ # Global dependency injection setup
```

## 📦 Dependencies

Major dependencies used in this project:

| Package           | Version | Purpose                    |
| :---------------- | :------ | :------------------------- |
| `flutter_bloc`    | ^9.1.1  | State management and DI    |
| `firebase_auth`   | ^6.1.3  | User authentication        |
| `cloud_firestore` | ^6.1.1  | NoSQL Database             |
| `equatable`       | ^2.0.8  | Value equality for objects |

---

_Generated for Narayan Farms Project_
