# fitnessapp

A new Flutter project for a fitness app.

## Getting Started

This project is a starting point for a Flutter application that integrates fitness tracking and pose detection.

### Prerequisites

Before running the app, you'll need to set up the server for pose detection. The server code is located in the **Posedetection** repository.

1. Clone the **Posedetection** repository:
    ```bash
    git clone <repository_url>
    ```

2. Navigate to the directory containing the **app.py** file in the **Posedetection** repository.

3. Run the server:
    ```bash
    python app.py
    ```

4. After starting the server, set your system's IP address in the **APP key** within the Flutter app configuration.

### Resources

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Running the App

Once the server is running and the IP is set, you can run the app on your device or emulator:

1. Open the project in your preferred code editor.
2. Use the following command to run the app:
    ```bash
    flutter run
    ```

Now you can start using the app!

## Features

- **Pose Detection**: Tracks and monitors user movements for fitness exercises.
- **Workout Tracking**: Log and track workouts and progress.
- **User Authentication**: Secure login and user management.

## Contributions

Feel free to fork, contribute, or suggest improvements for the app!

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
