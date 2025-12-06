# 🎨 PaintlyRef: The Offline Moodboard App

## About PaintlyRef

**PaintlyRef** is a high-performance, **cross-device mobile application** (iOS and Android) designed for artists, designers, and creatives who require a dedicated tool to build and manage **digital mood boards** or reference collages on **phones and tablets**.

The core philosophy of **PaintlyRef** is **complete offline functionality**, ensuring continuous workflow without dependence on network connectivity. Users can effortlessly import images from their device's gallery and external web sources, arranging them on an **interactive canvas** using intuitive drag-and-drop gestures.

## 🛠️ Technologies and Dependencies

This project is built using **Flutter** and utilizes a modern, stable set of packages for efficiency and performance:

| Package | Purpose |
| :--- | :--- |
| **Flutter (Dart)** | The core cross-platform UI toolkit. |
| **`Riverpod`** | The robust and scalable solution for application state management. |
| **`hive`** | Used as a fast, persistent key-value database for local storage of all board data and user settings. |
| **`photomanager`** | For securely and efficiently accessing and importing images from the local device gallery. |
| **`super_drag_and_drop`** | Enables advanced drag-and-drop features, crucial for both internal canvas interaction and external imports. |

## ✨ Core Features

  * **📴 100% Offline Mode**: All features, from creation to editing and viewing, are fully operational without any internet connection.
  * **📱 Tablet & Phone Support**: The UI is designed to be **responsive**, providing an optimal experience and efficient canvas utilization on both small phone screens and large tablet displays.
  * **🖥️ Streamlined Navigation**: The application is structured around two key screens for focused interaction:
    1.  **Board Overview Screen**: A view to manage (create, rename, delete) all saved mood boards.
    2.  **The Board Canvas Screen**: The primary editing interface where images are arranged and manipulated.
  * **🖼️ Versatile Image Import**: Images can be added through multiple methods:
      * **Local Gallery Access**: Secure import via `photomanager`.
      * **External Drag & Drop**: Drag images directly from **web browsers (e.g., Pinterest)** onto the Canvas Screen (via `super_drag_and_drop`).
  * **💾 Persistent Local Storage**: All board layouts and image references are reliably stored locally using the **`hive`** database.
  * **📐 Interactive Canvas**: Supports essential manipulations including image placement, scaling, and rotation.

## 🚀 Getting Started

### Prerequisites

  * Flutter SDK (Stable Channel)
  * A connected device or emulator for testing.

### Installation

1.  **Clone the Repository:**

    ```bash
    git clone https://github.com/adonaitewolde/paintlyRef.git
    cd paintlyRef
    ```

2.  **Install Dependencies:**

    ```bash
    flutter pub get
    ```

3.  **Run the Application:**

    ```bash
    flutter run
    ```

### 🔒 Platform Specific Configuration

Since this application utilizes device resources (`photomanager`) and advanced gestures, ensure that necessary platform-specific configurations (e.g., photo library access permissions in `AndroidManifest.xml` and `Info.plist`) are correctly set up.

## 🏗️ Project Structure

The codebase is organized following best practices for Flutter and **Riverpod** architecture:

  * `lib/models`: Data structures for mood boards and images, including **Hive** type adapters.
  * `lib/services`: Service classes for external communication and utilities (e.g., `PhotoService`, `HiveStorageService`).
  * `lib/screens`: The two main user interfaces (`BoardOverviewScreen`, `CanvasScreen`).
  * `lib/widgets`: Reusable UI components, often split into responsive widgets to handle different form factors.
  * `lib/state`: All **Riverpod** providers and state logic (e.g., `boardListProvider`, `canvasStateProvider`).

-----

*(Note: This project is proprietary and not open source. The codebase is managed internally.)*