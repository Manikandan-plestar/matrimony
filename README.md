# Vows & Souls — Matrimony Application

A modern, elegant Matrimonial Application built with **Flutter**, **Material 3**, and **Provider** state management, featuring an **image-first discovery deck**, **custom swipe animations**, and a **3-phase profile publishing wizard**.

---

## Quick Start

### Run on Android Emulator
```bash
flutter run -d emulator-5554
```

### Run on Connected Device or Desktop
```bash
flutter run
```

### Analyze Code
```bash
flutter analyze
```

---

## Application Highlights

- **Image-First Discovery:** Full-card photography with minimal badges on the initial card; progressive disclosure reveals full personal, educational, family, and partner preference details on demand.
- **Swipe Gesture Deck (`MatrimonyTinderDeck`):** Horizontal drag physics with proportional rotation and depth cards underneath. Swipe left to Pass, swipe right to Express Interest.
- **Curved Bottom Navigation (`CurvedMatrimonyBottomNav`):** Three primary destinations:
  - **Left:** Groom discovery feed.
  - **Center:** Elevated, pulsating button alternating between a heart icon and `+` add icon to launch the Publishing Wizard.
  - **Right:** Bride discovery feed.
- **3-Phase Publishing Wizard (`PublishWizardScreen`):** Step-by-step wizard (Personal $\rightarrow$ Career & Location $\rightarrow$ Partner Preferences & Live Review) with phase-by-phase validation.
- **Account & Profile Hub (`SettingsProfileScreen`):** Accessed via the top-right user avatar, organizing My Profile, Saved Profiles, Interests (Sent & Received), Matches, Profile Visitors, Privacy Settings, and Notifications.

---

## Documentation

Comprehensive architecture, data models, state providers, and function-by-function documentation are available in:

👉 **[`docs/ARCHITECTURE_AND_FLOW.md`](docs/ARCHITECTURE_AND_FLOW.md)**

---

## Project Structure

```text
lib/
├── config/                  # Color palette (Burgundy, Rose, Cream, Gold) & option lists
├── models/                  # Candidate profiles, user accounts, interactions & alerts
├── providers/               # Reactive state (Discovery, Profile, Interactions, Filters, Alerts)
├── services/mock/           # Realistic dummy candidates and notification data
├── widgets/                 # Reusable cards, swipe deck, bottom nav, app bar, modals
└── screens/                 # Full-page views (Feeds, Wizard, Hub, Interests, Matches, etc.)
```

---

## Phase 1 Status

- **Frontend First:** 100% complete with realistic dummy data.
- **Flutter Analysis:** `No issues found! (0 errors, 0 warnings)`
- **Future Phase 2:** Node.js/Express backend, MySQL database, Nodemailer OTP, and JWT authentication will be implemented after frontend approval.
