# Hacking on RevEngi App

This document provides instructions for setting up your development environment and contributing to RevEngi App.

## Prerequisites

Before you begin, ensure you have the following installed:

*   **Flutter SDK:**  Follow the official Flutter installation guide for your operating system: [https://flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install), Unless mentioned otherwise, the latest stable version of Flutter is recommended.
*   **Android SDK:** (If you plan to work on Android-specific features) Install the Android SDK and configure your `ANDROID_HOME` environment variable.
*   **Git:**  Git is required for version control.
*   **A suitable IDE:**  Android Studio, VS Code with the Flutter extension, or your preferred Dart/Flutter IDE.

## Setting Up Your Development Environment

1.  **Fork the Repository:**  Fork the RevEngi App repository to your GitHub account.
    ```shell
    git clone https://github.com/RevEngiSquad/revengi-app.git
    cd revengi-app
    ```
2.  **Configure Flutter:** Ensure Flutter is correctly configured by running:
    ```shell
    flutter doctor
    ```
    Address any issues reported by the doctor.
3.  **Install Dependencies:**  Get all the required Dart packages:
    ```shell
    flutter pub get
    ```

## Building the Application

You can build the application for different platforms:

### Android

**To build a universal APK:**
```shell
flutter build apk
```
**To build an APK for a specific architecture:**
```shell
flutter build apk --split-per-abi --target-platform android-arm,android-arm64
```
**To build APK for all architectures separately:**
```shell
flutter build apk --split-per-abi
```

Now, If you're done with the changes and have added something cool, don't forget to create a pull request.  Make sure to follow the contribution guidelines in the [CONTRIBUTING.md](CONTRIBUTING.md).

That's all here!  Happy coding!

