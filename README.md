# Dorm the Explorer

![Dorm the Explorer logo](assets/images/Dorm_the_Explorer_Logo.png)

**Dorm the Explorer** helps students discover dormitories in Batangas City and gives landlords tools to publish and manage listings.

## Contents

- [What the app does](#what-the-app-does)
- [Technology](#technology)
- [How the app is organized](#how-the-app-is-organized)
- [Requirements](#requirements)
- [Get started](#get-started)
- [Configure Firebase](#configure-firebase)
- [Configure Cloudinary](#configure-cloudinary)
- [Run the app](#run-the-app)
- [Firestore rules](#firestore-rules)
- [Run tests](#run-tests)
- [Troubleshooting](#troubleshooting)
- [Security notes](#security-notes)

## What the app does

Dorm the Explorer has role-based accounts for students and landlords. Email verification is required before an account can enter the app.

### Students

- Browse approved dormitory listings and view rent, photos, room types, amenities, availability, location, and landlord contact details.
- Search by name or address and filter by price, available slots, room type, amenities, and campus.
- View map locations and route information.
- Review a dormitory or report a listing.

### Landlords

- Create, edit, and manage dormitory listings.
- Upload listing photos and a profile photo.
- Set monthly rent, room capacity, and available slots.
- Manage listing availability from the landlord dashboard.

Listing forms enforce a maximum monthly rent of **₱99,999** and a maximum capacity of **99 slots**. Firestore rules also validate these limits when listings are created or those values are updated.

## Technology

| Area | Technology |
| --- | --- |
| App | Flutter, Dart |
| Authentication | Firebase Authentication |
| Database and access control | Cloud Firestore and Firestore Security Rules |
| Image hosting | Cloudinary unsigned image uploads |
| Maps and location | `flutter_map`, `latlong2`, `geolocator` |
| Route information | OSRM |

## How the app is organized

The app is organized by feature. Dormitory data access is kept in repositories and services, domain models hold listing and search data, and presentation screens handle the user interface.

```text
lib/
├── config/                 # Public client configuration, including Cloudinary
├── features/
│   ├── auth/presentation/  # Sign-in, account creation, email verification UI
│   └── dormitories/
│       ├── data/           # Firestore repositories, uploads, location, routing
│       ├── domain/         # Dormitory, review, route, and search models
│       └── presentation/  # Dashboards, listing forms, details, and filters
├── services/               # Shared authentication services
├── theme/                  # App theme
├── firebase_options.dart   # Firebase platform configuration
└── main.dart               # App entry point and authentication gate
```

The Firebase project configuration is described by `firebase.json`; Firestore rules live in `firestore.rules`.

## Requirements

- Flutter SDK with Dart **3.14.0 or later**
- A Firebase project with Email/Password Authentication and Cloud Firestore enabled
- A Cloudinary account with an unsigned image upload preset
- Android Studio or another Flutter-compatible IDE, plus an Android emulator or device for Android development

## Get started

Clone the repository and install its dependencies:

```bash
git clone https://github.com/shirokase/Dorm-the-Explorer.git
cd Dorm-the-Explorer
flutter pub get
```

Then configure Firebase and Cloudinary before running the app.

## Configure Firebase

The app initializes Firebase using `lib/firebase_options.dart`. Android also uses `android/app/google-services.json`.

For a different Firebase project, install and run the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup):

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project <firebase-project-id>
```

In the Firebase Console:

1. Enable **Email/Password** in Authentication providers.
2. Create a Cloud Firestore database.
3. Deploy the repository's Firestore rules as described in [Firestore rules](#firestore-rules).

Keep the generated platform configuration aligned with the Firebase project you intend to use.

## Configure Cloudinary

The app uploads dormitory and profile images directly to Cloudinary using an unsigned upload preset. Create an image upload preset in Cloudinary, allow only the image formats you need, and configure upload restrictions in Cloudinary itself.

The app has default Cloudinary values in `lib/config/cloudinary_config.dart`. You can override them at runtime:

```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=<cloud-name> \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=<unsigned-preset>
```

Unsigned upload settings are visible to app users. **Never place a Cloudinary API secret in the Flutter application.** Use a trusted backend if you need signed uploads.

## Run the app

Start the app on the default connected device or emulator:

```bash
flutter run
```

To choose a device explicitly:

```bash
flutter devices
flutter run -d <device-id>
```

## Firestore rules

Rules are stored in [`firestore.rules`](firestore.rules). Deploy them to your Firebase project with the Firebase CLI:

```bash
npx -y firebase-tools@latest deploy --only firestore:rules --project <firebase-project-id>
```

Review the target project before deployment. Listing writes require an authenticated landlord who owns the listing; the rules also validate supported listing fields and rent/capacity limits.

## Run tests

Run the project's test suite with:

```bash
flutter test
```

## Troubleshooting

- **Permission denied when creating or editing a listing:** Confirm the signed-in account has the landlord role, owns the listing, and that the current `firestore.rules` have been deployed.
- **Email verification does not let the account continue:** Open the latest verification link, return to the app, and refresh the verification state.
- **Cloudinary uploads fail:** Verify the Cloud name and unsigned preset, check that the preset allows the selected format, and ensure the image is within the configured size limit.
- **Location is unavailable:** Grant the app location permission and enable device location services. Map tiles and route information also require network access.

## Security notes

- Firestore rules are part of the app's security boundary; deploy and review them for the Firebase project you use.
- Cloudinary unsigned presets are public client configuration. Restrict the preset and enforce upload limits in Cloudinary.
- Never commit service-account files, private API secrets, or other credentials.
