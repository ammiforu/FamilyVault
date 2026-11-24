# FamilyVault 🛡️

A secure, offline-first family credential and document vault for **Android** and **iOS**, featuring **Google Sheets spreadsheet table view**, instant CSV import/export, master PIN protection, and an emergency (ICE) hub.

---

## 📱 Releases & Install

### Android (Ready to install)
The pre-compiled release APK is available directly in this project:
- **Location**: `FamilyVault-release.apk` (or `build/app/outputs/flutter-apk/app-release.apk`)
- **How to install**:
  1. Transfer `FamilyVault-release.apk` to your Android phone (via USB, Google Drive, WhatsApp, or email).
  2. Tap the `.apk` file and select **Install** (enable "Install unknown apps" if prompted).
  3. Launch **FamilyVault** and create your 4–6 digit Master PIN!

### iPhone / iOS Version
Apple requires macOS & Xcode to compile native iOS binaries (`.ipa`). You have two instant options:

#### Option 1: Automated Cloud Build via GitHub Actions (Free & No Mac required)
This repository includes a pre-configured GitHub Actions workflow (`.github/workflows/build-all.yml`).
1. Push this project to your GitHub repository.
2. Go to **Actions** → **Build FamilyVault (Android APK & iOS)** → click **Run workflow**.
3. It compiles on Apple macOS runners and produces downloadable artifacts:
   - `FamilyVault-Android-APK`
   - `FamilyVault-iOS-IPA`

#### Option 2: Build with Xcode on Mac
If you or a colleague have a Mac:
```bash
flutter pub get
cd ios && pod install && cd ..
flutter build ipa --no-codesign
```
Or open `ios/Runner.xcworkspace` in Xcode, select your connected iPhone or Simulator, and click **Run**.

---

## ✨ Features Included

### 1. 📊 Spreadsheet View (Google Sheets & Excel Compatible)
- **Interactive Data Table**: View all your passwords, cards, and documents in a table format with columns:
  - *Title / Service Name*
  - *Category*
  - *Assigned Family Member*
  - *Username / Email*
  - *Password / Secret* (masked with 1-tap unmask / copy)
  - *URL / Location*
  - *Expiry / Renewal Date*
  - *Notes*
- **Sorting & Filtering**: Sort by column and filter by category or search query.
- **CSV Import from Google Sheets**: Copy rows directly from Google Sheets and paste into the vault to import.
- **CSV Export**: 1-tap export to clipboard or file, formatted for Google Sheets.

### 2. 🔐 Vault Categories & Quick Access
- **Accounts & Logins**: Streaming (Netflix, Disney+), social, email, utilities.
- **Banking & Cards**: Credit/debit cards with masked CVV and PIN.
- **IDs & Documents**: Passports, driver licenses, health insurance policies.
- **Wi-Fi & Home**: Network SSIDs, passwords, router gateways, smart locks.
- **Secure Notes**: Safe deposit codes, alarms, wills, and private records.

### 3. 🚨 Emergency (ICE) Hub
- In Case of Emergency contact cards for family members.
- Instant access to emergency numbers (911, Poison Control), pediatricians, doctors, blood types, and allergy warnings.

### 4. ⚡ Secure Password Generator
- Customizable length (8 to 32 characters).
- Uppercase, lowercase, numbers, and special symbols toggles.
- Live strength meter and 1-tap copy.

### 5. 🔒 Security & Privacy
- **Master PIN Protection**: 4–6 digit numeric passcode screen.
- **Encrypted Local Storage**: Scrambled with derived PIN key; no data is ever sent to third-party servers.
