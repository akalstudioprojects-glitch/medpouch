# MedPouch: App Store Submission Kit

Copy-paste text for App Store Connect, plus the compliance decisions behind it.

---

## 1. Listing text

**Name** (30 max): `MedPouch`

**Subtitle** (30 max): `Your Pocket Medical Wallet`

**Category**: Medical (secondary: Health & Fitness)

**Promotional text** (170 max):
> Keep medications, prescriptions, allergies, and emergency contacts for your whole family in one private place, stored only on your iPhone.

**Description**:
> MedPouch keeps your important medical information in your pocket, ready when you need it.
>
> MEDICATIONS & REMINDERS
> • Save the medications you take, with dosage and notes
> • Get gentle reminders: daily, twice daily, three times daily, or weekly
> • Mark essential medications to show on your emergency card
>
> PRESCRIPTIONS
> • Keep a record of each prescription: doctor, pharmacy, refills, and instructions
> • Attach a photo so you always have a copy on hand
>
> EMERGENCY CARD
> • One screen with your blood type, allergies, essential medications, conditions, and emergency contacts
> • Optional QR code that any phone camera can read
> • Save or share the card as an image
>
> FAMILY
> • Keep separate medications, allergies, contacts, and emergency cards for children, parents, and anyone you care for
>
> TRAVEL
> • Build a medication packing list for your trip, with estimated quantities
>
> PRIVATE BY DESIGN
> • Everything is stored only on your iPhone and encrypted when it's locked
> • No accounts, no servers, no ads, no tracking
> • Delete all of your data at any time
>
> MedPouch helps you organize your own information. It does not provide medical advice, diagnosis, or treatment.

**Keywords** (100 max, no spaces after commas):
`medication,reminder,prescription,allergy,emergency,pill,health,wallet,family,ICE,blood type,travel`

**Support URL**: `https://<your-github-username>.github.io/medpouch/`
**Privacy Policy URL**: `https://<your-github-username>.github.io/medpouch/privacy.html`
**Copyright**: `2026 <Your Name>`

---

## 2. App Privacy questionnaire

- "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app**
- Result shown on the store: **Data Not Collected**

This is accurate because nothing ever leaves the device except when the user explicitly shares it (share sheet / QR code), which Apple does not count as collection.

---

## 3. Age rating

Answer **None / No** to everything except the question about **medical or treatment information**, which should be answered honestly (the app stores the user's own medical information). Accept whatever rating App Store Connect calculates.

---

## 4. App Review Information

**Sign-in required**: No

**Notes**:
> MedPouch is a personal medical wallet. No account or login is needed and all data is stored locally on the device with Core Data. There is no backend server.
>
> To review:
> 1. Complete the 4-step welcome (name, blood type, optional reminder permission, disclaimer).
> 2. Home → "Add Medication": choose frequency "Daily" to schedule a local reminder.
> 3. Home → "Add Prescription": optionally attach a photo (camera or photo library).
> 4. Profile → Allergies / Emergency Contacts to add details.
> 5. Emergency tab shows the emergency card with an optional QR code.
> 6. Profile → Family Members to manage another person's records.
> 7. Profile → Privacy & Data shows the medical disclaimer, privacy policy, and "Delete All Data".
>
> The app does not provide medical advice, diagnosis, dosing calculations, or treatment recommendations.

---

## 5. Compliance decisions

| Topic | Decision | Why |
|---|---|---|
| **Backend / database** | None. Core Data on the device only. | Nothing to secure, host, or pay for; no data breach exposure; simplest privacy answers. |
| **iCloud sync** | Not used. | App Store Guideline 5.1.3(ii) says apps may not store personal health information in iCloud. |
| **Encryption at rest** | Core Data store uses `FileProtectionType.completeUnlessOpen`. | Health data is unreadable while the device is locked. |
| **Export compliance** | `ITSAppUsesNonExemptEncryption = NO` in Info.plist. | Only Apple's built-in OS encryption is used. Skips the question on every upload. |
| **Privacy manifest** | `PrivacyInfo.xcprivacy` declares UserDefaults (reason `CA92.1`), no tracking, no collected data. | Required for App Store uploads since May 2024. |
| **Medical disclaimer** | Shown during onboarding (must accept) and in Privacy & Data. | Guideline 1.4.1. |
| **Data deletion** | Profile → Privacy & Data → Delete All Data. | Expected for health apps (Guideline 5.1.1). |
| **Permissions** | Camera only (with usage text). Photo library uses `PhotosPicker`, which needs no permission. Notifications requested in context. | Missing usage strings cause crashes and rejection. |
| **FDA / medical device** | Not a medical device: it stores user-entered records and reminders, with no diagnosis or dosing. | Falls under FDA "enforcement discretion" for medication reminder and personal record apps. Don't add dose calculators or symptom checkers without advice. |
| **HIPAA** | Not applicable. | HIPAA covers healthcare providers, insurers, and their contractors, not a consumer app that never receives data. |
| **GDPR / India DPDP Act** | Minimal obligations. | The developer never collects or processes users' personal data. Keep the privacy policy accurate. |
| **EU Digital Services Act** | Declare trader / non-trader status in App Store Connect → Business. | Required to be listed in EU storefronts. |

**If you ever add** analytics, crash reporting SDKs, accounts, a server, or cloud sync, you must update the privacy manifest, the App Privacy questionnaire, and the privacy policy *before* shipping that version.
