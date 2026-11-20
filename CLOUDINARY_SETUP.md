# Cloudinary image upload setup

The dormitory photo upload service is ready for the future Add Dormitory flow.
No Add Dormitory screen or Firestore write was added. The upload service returns
a Cloudinary HTTPS URL, which that flow can add to Dormitory.photoUrls when
saving the dormitory document.

## 1. Create an unsigned upload preset

In the Cloudinary Console, open Settings → Upload → Upload presets and create
a preset with Signing Mode: Unsigned. Use image-only restrictions such as
allowed formats jpg,png,webp, and configure an upload folder and any
transformations in the preset. Keep the preset restrictive: unsigned uploads
are intentionally callable by clients and the preset name is visible in the app.

Get your Cloud name from the Cloudinary Console dashboard.

## 2. App configuration

The app is configured by default with cloud name qnvu74g0 and unsigned preset
Dorm the Explorer, so you do not need to pass Dart defines when running it.
These two values are visible in the client app by design. Never put the
Cloudinary API secret in Flutter or a committed file. Signed uploads require a
trusted backend to generate signatures.

If you need to override the defaults locally, CloudinaryConfig also supports
CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET Dart defines.

## 3. Use it from the future form

The future Add Dormitory flow can call
CloudinaryUploadService.uploadImage(File(pickedImage.path)). Add the returned
secureUrl to the dorm's photoUrls list, then save the dorm metadata and URLs
through the existing repository/database flow. Call close() when the service
owns its lifecycle and is no longer needed.

The app already requests Android internet access and already includes the
http package, so no extra dependency or Android permission change is needed.

## Limits

Cloudinary's current Free image/video plan is listed as free forever with
25 monthly credits. Check Cloudinary's [current pricing page](https://cloudinary.com/pricing)
for current quota and terms. The upload service also applies a default 10 MB
per-image client-side limit; this is only a usability guardrail and can be
changed when constructing the service. Enforce restrictions in Cloudinary as
well, because client-side limits can be bypassed.
