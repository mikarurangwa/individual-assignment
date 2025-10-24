Study Planner App
A modern, intuitive task management app built with Flutter. Organize your study schedule, set reminders, and track your progress with a clean, dark-themed interface.

Features
Task Management: Create, edit, and delete tasks with titles and descriptions
Calendar View: Visual calendar interface to view tasks by date
Today View: Quick access to today's tasks and deadlines
Smart Reminders: Set custom reminder times for important tasks
Local Storage: All data stored securely on your device using SharedPreferences
Dark Theme: Modern dark blue interface with yellow accent buttons
Cross-Platform: Runs on both iOS and Android devices
Screenshots
Add screenshots of your app here

Installation
Prerequisites
Flutter SDK (>=3.0.0)
Dart SDK (>=3.0.0)
Android Studio / VS Code
iOS Simulator / Android Emulator
Setup
Clone the repository:
git clone https://github.com/mikaruangwa/individual-assignment.git
cd individual-assignment
Install dependencies:
flutter pub get
Run the app:
flutter run
Dependencies
flutter: SDK for building cross-platform apps
table_calendar: Calendar widget for date selection
shared_preferences: Local data persistence
intl: Date and time formatting
uuid: Unique identifier generation
Architecture
Models: Task data structure with JSON serialization
Services: Storage service for local data persistence
Screens: Three main pages (Today, Calendar, Settings)
Widgets: Reusable UI components like TaskTile
Storage
The app uses SharedPreferences for local storage, ensuring:

Fast data access
Offline functionality
Data persistence between app sessions
No external dependencies or internet required
Contributing
Fork the repository
Create a feature branch (git checkout -b feature/new-feature)
Commit your changes (git commit -am 'Add new feature')
Push to the branch (git push origin feature/new-feature)
Create a Pull Request
By Mika Rurangwa
