<div align="center">
  <br>
  <img src="assets/images/DormTheExplorer_Logo.png" alt="Dorm the Explorer logo" width="180" />
  <h1>Dorm the Explorer</h1>
  <p><strong>Find a dorm in Batangas City. Manage your listings. All in one app.</strong></p>

  <p>
    <img alt="Flutter" src="https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white" />
    <img alt="Dart" src="https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white" />
    <img alt="Firebase" src="https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black" />
    <img alt="Cloudinary" src="https://img.shields.io/badge/Cloudinary-3448C5?logo=cloudinary&logoColor=white" />
  </p>

  <p>
    <a href="#features">Features</a> •
    <a href="#tech-stack">Tech Stack</a> •
    <a href="#quick-start">Quick Start</a> •
    <a href="#project-structure">Structure</a> •
    <a href="#testing">Testing</a> •
    <a href="#troubleshooting">Troubleshooting</a>
  </p>
</div>

---

Dorm the Explorer is a Flutter app with role-based accounts. **Students** search, filter, and compare dormitories on a map. **Landlords** publish and manage their own listings. Every account must verify its email before entering the app.

## Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Quick Start](#quick-start)
- [Setup](#setup)
  - [Requirements](#requirements)
  - [Install dependencies](#install-dependencies)
  - [Configure Firebase](#configure-firebase)
  - [Configure Cloudinary](#configure-cloudinary)
  - [Deploy Firestore rules](#deploy-firestore-rules)
- [Run the App](#run-the-app)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Security Notes](#security-notes)

## Features

### For students

- Browse approved listings with rent, photos, room types, amenities, availability, location, and landlord contact details.
- Search by name or address.
- Filter by price, available slots, room type, amenities, and campus.
- View dorm locations on a map and get route information.
- Review a dormitory or report a listing.

### For landlords

- Create, edit, and manage dormitory listings.
- Upload listing photos and a profile photo.
- Set monthly rent, room capacity, and available slots.
- Update availability from the landlord dashboard.

### Listing limits

| Field | Maximum |
| --- | --- |
| Monthly rent | ₱99,999 |
| Capacity | 99 slots |

The listing forms enforce these limits, and the Firestore rules validate them again whenever a listing is created or either value is updated.

## Tech Stack

| Area | Technology |
| --- | --- |
| App | Flutter, Dart |
| Authentication | Firebase Authentication (Email/Password) |
| Database and access control | Cloud Firestore and Firestore Security Rules |
| Image hosting | Cloudinary unsigned uploads |
| Maps and location | `flutter_map`, `latlong2`, `geolocator` |
| Route information | OSRM |

## Quick Start

If you already have Flutter, a Firebase project, and a Cloudinary preset ready:

```bash
git clone https://github.com/shirokase/Dorm-the-Explorer.git
cd Dorm-the-Explorer
flutter pub get
flutter run
```

New to the project? Follow the full [Setup](#setup) first.

## Setup

### Requirements

- Flutter SDK with Dart **3.14.0 or later**
- A Firebase project with **Email/Password Authentication** and **Cloud Firestore** enabled
- A Cloudinary account with an **unsigned image upload preset**
- Android Studio (or another Flutter-compatible IDE) and an Android emulator or device

### Install dependencies

```bash
git clone https://github.com/shirokase/Dorm-the-Explorer.git
cd Dorm-the-Explorer
flutter pub get
```

### Configure Firebase

The app initializes Firebase from `lib/firebase_options.dart`. Android also reads `android/app/google-services.json`.

To point the app at your own Firebase project, use the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project <firebase-project-id>
```

Then, in the Firebase Console:

1. Enable **Email/Password** under Authentication providers.
2. Create a Cloud Firestore database.
3. [Deploy the Firestore rules](#deploy-firestore-rules).

> [!TIP]
> Make sure the generated configuration files all belong to the same Firebase project you plan to use. Project settings are described in `firebase.json`.

### Configure Cloudinary

Dormitory and profile images are uploaded straight to Cloudinary with an unsigned upload preset.

1. In Cloudinary, create an **unsigned** image upload preset.
2. Allow only the image formats you need and set size limits on the preset itself.
3. Provide your values at runtime (defaults live in `lib/config/cloudinary_config.dart`):

**macOS / Linux**

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
```

**Windows (PowerShell)**

```powershell
flutter run `
  --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> `
  --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
```

> [!WARNING]
> Unsigned upload settings are visible to anyone who uses the app. **Never put a Cloudinary API secret in the Flutter app.** If you need signed uploads, use a trusted backend.

### Deploy Firestore rules

Rules live in [`firestore.rules`](firestore.rules). Deploy them with the Firebase CLI:

```bash
npx -y firebase-tools@latest deploy --only firestore:rules --project <firebase-project-id>
```

Double-check the target project before deploying. The rules require an authenticated landlord who owns the listing for any listing write, and they validate supported fields plus the rent and capacity limits.

## Run the App

Run on the default connected device or emulator:

```bash
flutter run
```

Or pick a device explicitly:

```bash
flutter devices
flutter run -d <device-id>
```

## Testing

```bash
flutter test
```

## Project Structure

The app is organized by feature. Data access lives in repositories and services, domain models hold listing and search data, and presentation screens handle the UI.

```text
lib/
├── config/                 # Public client configuration (e.g., Cloudinary)
├── features/
│   ├── auth/
│   │   └── presentation/   # Sign-in, sign-up, email verification UI
│   └── dormitories/
│       ├── data/           # Firestore repositories, uploads, location, routing
│       ├── domain/         # Dormitory, review, route, and search models
│       └── presentation/   # Dashboards, listing forms, details, filters
├── services/               # Shared authentication services
├── theme/                  # App theme
├── firebase_options.dart   # Firebase platform configuration
└── main.dart               # App entry point and authentication gate
```

Other key files: `firebase.json` (Firebase project config) and `firestore.rules` (Firestore security rules).

## Troubleshooting

| Problem | What to try |
| --- | --- |
| **Permission denied** when creating or editing a listing | Confirm the signed-in account has the landlord role and owns the listing, and that the latest `firestore.rules` are deployed. |
| **Email verification doesn't let me in** | Open the newest verification link, return to the app, and refresh the verification state. |
| **Cloudinary uploads fail** | Check the cloud name and unsigned preset, confirm the preset allows the file format, and make sure the image is within the size limit. |
| **Location is unavailable** | Grant location permission and turn on device location services. Map tiles and route info also need a network connection. |

## Security Notes

- Firestore rules are part of the app's security boundary. Review and deploy them for whichever Firebase project you use.
- Cloudinary unsigned presets are public client configuration. Restrict the preset and enforce upload limits in Cloudinary.
- Never commit service-account files, private API secrets, or other credentials.
