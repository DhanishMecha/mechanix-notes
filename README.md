# Mechanix Notes

Notes App for the Mechanix OS

## Overview

Mechanix Notes is a simple and lightweight note-taking application built with Flutter for Mecha Comet devices. It provides an easy way to create, edit, and manage notes with a clean and user-friendly interface.

---

## Install Guide

### Pre-requisites

- [Flutter-Elinux SDK](https://github.com/flutter-elinux/flutter-elinux)
- [Dart SDK](https://dart.dev/get-dart)

### Steps to Run Notes App

1. Clone the repository:

```bash
git clone https://github.com/mecha-org/mechanix-notes
cd mechanix-notes
```

2. Install Flutter dependencies:

For flutter-elinux:

```bash
flutter-elinux pub get
```

3. Run the Application

### Run on eLinux

```bash
flutter-elinux run
```

## Testing

### Run Unit & BLoC Tests

```bash
flutter-elinux test
```

### Run Integration Tests

```bash
flutter-elinux test integration_test/<test-file-name>
```

## Key Features

- **Create Notes**: Quickly create and save notes.
- **Edit Notes**: Update existing notes anytime.
- **Delete Notes**: Remove unwanted notes easily.
- **Search Notes**: Find notes instantly with search functionality.
- **Persistent Storage**: Notes are stored locally on the device.
- **Clean UI**: Minimal and user-friendly interface optimized for Mechanix OS.
- **Rich Text Support**: Basic text formatting support for better note organization.

---