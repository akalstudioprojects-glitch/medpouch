# MedPouch

A personal medical wallet for iPhone: medications with reminders, prescriptions with photos, allergies, emergency contacts, family members, a travel packing list, and an emergency card with a QR code.

- **Platform:** iPhone, iOS 17+
- **Tech:** SwiftUI, Core Data (on-device only), local notifications
- **Backend:** none. All data stays on the device.

## Opening the project

You need a Mac with **Xcode 26** or later.

1. Copy this whole `Medpouch` folder to the Mac.
2. Double-click `MedPouch.xcodeproj`.
3. Select the **MedPouch** target → **Signing & Capabilities** → choose your **Team**.
4. If `com.akalstudio.medpouch` is already taken, change the **Bundle Identifier**.
5. Pick an iPhone simulator and press **⌘R**.

Files inside `MedPouch/` are picked up automatically (Xcode folder sync), so there is nothing to add by hand.

## Before submitting to the App Store

1. Host the pages in `docs/` (for example with GitHub Pages). The contact email is akalstudioprojects@gmail.com.
2. Put the privacy policy URL in `MedPouch/Views/Profile/PrivacyAndDataView.swift` (search for `TODO`).
3. Follow `docs/APP_STORE_SUBMISSION.md` for listing text, privacy answers, and reviewer notes.

## Project layout

```
MedPouch/
  App/            App entry point, tab bar
  Data/           Core Data model, persistence, helpers
  Services/       Notifications, QR codes, image handling
  Views/
    Home/         Dashboard, setup checklist
    Medications/  Medications list, add/edit
    Prescriptions/
    Profile/      Profile, allergies, contacts, privacy & data
    Family/       Family members and their records
    Emergency/    Emergency card, travel meds
    Onboarding/
  Assets.xcassets App icon, accent colour
  PrivacyInfo.xcprivacy
docs/             Privacy policy, support page, App Store submission kit
Info.plist        Export compliance flag (merged with generated Info.plist)
```

## Manual test checklist

Run through on a real iPhone before each release:

- [ ] Fresh install → onboarding → can't finish without accepting the disclaimer
- [ ] Add a medication (Daily) → reminder permission prompt → reminder arrives at 9:00 AM
- [ ] Edit medication to "As needed" → reminder is cancelled
- [ ] Untick "Essential" → medication stays in the list (no star) and leaves the emergency card
- [ ] Add prescription with camera photo and with library photo
- [ ] Add allergy, "No Known Allergies", and emergency contact; tap the call button
- [ ] Emergency card shows everything; QR code scans with another phone's camera; share image works
- [ ] Add a family member with their own medication, allergy, contact; their card shows only their data
- [ ] Delete a family member → their records and reminders are gone
- [ ] Travel Meds quantities update with trip length; share list works
- [ ] Privacy & Data → Delete All Data → app returns to onboarding with everything empty
- [ ] Lock the phone while the app is open, unlock → data still loads
