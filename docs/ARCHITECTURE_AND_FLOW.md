# Vows & Souls Matrimony App — Complete Architecture & Flow Documentation

---

## 1. Executive Summary & Design Direction

**Vows & Souls** is a mobile matrimonial application built using **Flutter (Dart)** and **Material 3**, architected with an **image-first discovery paradigm**, **provider-based state management**, and an offline **mock data layer**.

### Core Philosophy
- **Image-First Discovery:** Discovery cards prioritize photography, age, verification status, and essential bio points, avoiding information overload on the initial swipe deck.
- **Progressive Disclosure:** Comprehensive personal, educational, family, and partner preference details are gracefully revealed on demand via smooth bottom-sheet modals.
- **3-Phase Publishing Wizard:** Creating a candidate profile is separated into three distinct steps with validation, draft preservation, and preview before publishing.
- **Decoupled Architecture:** Clean separation between models, services, providers, reusable widgets, and UI screens ensures a smooth transition to a real backend in Phase 2.

---

## 2. Visual Architecture & Flow Diagram

```
                             ┌────────────────────────────────────────┐
                             │               main.dart                │
                             │      Initializes 6 MultiProviders      │
                             └───────────────────┬────────────────────┘
                                                 │
                                                 ▼
                             ┌────────────────────────────────────────┐
                             │              MainScreen                │
                             │  CustomAppBar  •  CurvedBottomNav      │
                             └───────┬────────────────────────┬───────┘
                                     │                        │
             ┌───────────────────────┴──────────┐             └──────────────────────────┐
             ▼                                  ▼                                        ▼
 ┌───────────────────────┐          ┌───────────────────────┐               ┌────────────────────────┐
 │    GroomFeedScreen    │          │    BrideFeedScreen    │               │  PublishWizardScreen   │
 │  (Filtered Groom Feed)│          │  (Filtered Bride Feed)│               │    (3-Phase Wizard)    │
 └───────────┬───────────┘          └───────────┬───────────┘               └───────────┬────────────┘
             │                                  │                                       │
             └─────────────────┬────────────────┘                                       │
                               ▼                                                        ▼
               ┌───────────────────────────────┐                        ┌───────────────────────────────┐
               │      MatrimonyTinderDeck      │                        │        ProfileProvider        │
               │   Smooth Gestures & Rotation  │                        │  Drafts -> Publishes Profile  │
               └───────────────┬───────────────┘                        └───────────────┬───────────────┘
                               │                                                        │
                               ▼                                                        ▼
               ┌───────────────────────────────┐                        ┌───────────────────────────────┐
               │      ProfileDetailsModal      │                        │       DiscoveryProvider       │
               │  Image-First Expandable Bio   │                        │  Inserts New Profile to Feed  │
               └───────────────┬───────────────┘                        └───────────────────────────────┘
                               │
                               ▼
               ┌───────────────────────────────┐
               │      InteractionProvider      │
               │ Saved • Interests • Matches   │
               └───────────────────────────────┘
```

---

## 3. Directory Structure

```text
E:\Mani dev\Mat\
├── pubspec.yaml                       # Package dependencies & assets
├── analysis_options.yaml              # Lint configuration rules
├── README.md                          # Project quick-start & overview
├── docs/
│   └── ARCHITECTURE_AND_FLOW.md       # This comprehensive specification
├── android/                           # Native Android wrapper (Gradle, Manifest)
├── web/                               # Web runner assets
├── windows/                           # Windows desktop runner
└── lib/
    ├── main.dart                      # App entrypoint & routing table
    ├── config/
    │   ├── theme.dart                 # Color palette & Material 3 styling
    │   └── constants.dart             # Dropdown dictionaries & presets
    ├── models/
    │   ├── matrimony_profile_model.dart # Candidate profile data contract
    │   ├── user_model.dart            # Logged-in user account entity
    │   ├── interaction_model.dart     # Interests, Matches, Visitors
    │   └── notification_model.dart    # User alerts & read state
    ├── providers/
    │   ├── auth_provider.dart         # Mock authentication & user profile
    │   ├── discovery_provider.dart    # Groom/Bride feeds & deck indexes
    │   ├── profile_provider.dart      # User profile & 3-phase wizard draft
    │   ├── interaction_provider.dart  # Saved profiles, interests & matches
    │   ├── notification_provider.dart # Unread notification counter & list
    │   └── search_filter_provider.dart# Real-time multi-filter engine
    ├── services/
    │   └── mock/
    │       └── mock_data.dart         # Realistic sample profiles & alerts
    ├── widgets/
    │   ├── cards/
    │   │   ├── matrimony_card_view.dart   # Image-first candidate card
    │   │   └── matrimony_tinder_deck.dart # Drag physics & card stack engine
    │   ├── common/
    │   │   ├── curved_bottom_nav.dart     # Groom, Animated Publish, Bride
    │   │   └── custom_app_bar.dart        # Header with unread badge & avatar
    │   └── modals/
    │       ├── profile_details_modal.dart # Expandable matrimonial bio sheet
    │       └── search_filter_sheet.dart   # Multi-filter modal sheet
    └── screens/
        ├── main_screen.dart           # Persistent shell with bottom nav
        ├── groom_feed_screen.dart     # Groom discovery feed
        ├── bride_feed_screen.dart     # Bride discovery feed
        ├── publish_wizard_screen.dart # 3-Phase step-by-step wizard
        ├── notifications_screen.dart  # Inbox with read/unread tracking
        ├── settings_profile_screen.dart# Account & profile hub
        ├── my_profile_screen.dart     # My profile with inline edit mode
        ├── saved_profiles_screen.dart # Bookmarked profiles
        ├── interests_screen.dart      # Dual-tab: Sent & Received
        ├── matches_screen.dart        # Mutual compatibility matches
        ├── visitors_screen.dart       # Profile visitors log
        └── static_settings_screen.dart# Privacy, notifications, help, about
```

---

## 4. File-by-File & Function-by-Function Catalog

### 4.1 Entry Point & Setup

#### `lib/main.dart`
- **Purpose:** Central coordinator that launches the Flutter runtime.
- **What it does:**
  - Calls `WidgetsFlutterBinding.ensureInitialized()`.
  - Configures edge-to-edge transparent system navigation bar and status bar via `SystemUiOverlayStyle`.
  - Injects all 6 `ChangeNotifierProvider`s at the root level via `MultiProvider`.
  - Configures `onGenerateRoute` with named routes (`/`, `/notifications`, `/account-hub`, `/my-profile`, `/publish-wizard`, `/saved-profiles`, `/interests`, `/matches`, `/visitors`, etc.).

---

### 4.2 Configuration Layer (`lib/config/`)

#### `lib/config/theme.dart`
- **Purpose:** Centralized theme system defining the romantic matrimonial color palette.
- **Key Color Tokens:**
  - `AppTheme.burgundy` (`#7E1029`): Primary buttons, titles, and active badges.
  - `AppTheme.rose` (`#E11D48`): Heart icons, express interest actions, and unread badges.
  - `AppTheme.gold` (`#D4AF37`): Compatibility score stars and verified highlights.
  - `AppTheme.cream` (`#FFFDF9`): Warm background surfaces and card fills.
  - `AppTheme.background` (`#F9F6F0`): Warm canvas background.
- **Key Function:**
  - `static ThemeData get lightTheme`: Constructs `ThemeData` specifying `CardThemeData`, `ElevatedButtonThemeData`, `InputDecorationTheme`, and typography.

#### `lib/config/constants.dart`
- **Purpose:** Curated dropdown option lists ensuring consistent terminology across screens.
- **Key Lists:**
  - `profileCreatedForOptions`: Self, Son, Daughter, Brother, Sister, Relative, Friend.
  - `maritalStatusOptions`: Never Married, Divorced, Awaiting Divorce, Widowed.
  - `religionOptions`, `motherTongueOptions`, `educationOptions`, `occupationOptions`, `annualIncomeOptions`, `heightOptions`.
  - `popularCities`: Preset city filters (Chennai, Bangalore, Hyderabad, Mumbai, etc.).

---

### 4.3 Models Layer (`lib/models/`)

#### `lib/models/matrimony_profile_model.dart`
- **Purpose:** Data model representing a complete matrimonial candidate profile.
- **Attributes:**
  - *Personal:* `id`, `profileId`, `createdFor`, `fullName`, `gender`, `dateOfBirth`, `age`, `height`, `maritalStatus`, `motherTongue`, `religion`, `community`, `dietaryPreference`.
  - *Career:* `highestEducation`, `occupation`, `company`, `annualIncome`.
  - *Location:* `country`, `state`, `city`, `locality`.
  - *Family:* `familyType`, `familyBackground`, `familyValues`.
  - *Preferences:* `prefAgeMin`, `prefAgeMax`, `prefLocation`, `prefEducation`, `partnerExpectations`.
  - *Metadata:* `bio`, `profilePhotoUrl`, `compatibilityScore`, `isVerified`, `isPremium`, `isSaved`, `isInterestSent`.
- **Key Method:**
  - `copyWith(...)`: Immutably clones the profile with updated fields.

#### `lib/models/user_model.dart`
- Represents the authenticated user account (`id`, `fullName`, `email`, `phone`, `profilePhotoUrl`, `activeProfileId`).

#### `lib/models/interaction_model.dart`
- Models user interactions:
  - `InterestItem`: Request status (`pending`, `accepted`, `declined`), direction (`isReceived`), and timestamp.
  - `MatchItem`: Mutual match with `compatibilityScore` (e.g., 95%) and `matchingFactors` (e.g., *Location: Chennai*, *Values: Traditional*).
  - `VisitorItem`: Recent profile viewer with timestamp and view count.

#### `lib/models/notification_model.dart`
- In-app alerts: `type` (`interestReceived`, `profileLiked`, `newMatchFound`, `profileViewed`), title, message, timestamp, `isRead` flag, and optional `relatedProfile`.

---

### 4.4 Services Layer (`lib/services/mock/`)

#### `lib/services/mock/mock_data.dart`
- **Purpose:** Standalone in-memory repository providing realistic matrimonial candidates.
- **Datasets:**
  - `currentUser`: Logged-in user account.
  - `currentUserProfile`: Prepopulated user matrimonial profile.
  - `initialGroomProfiles`: Diverse groom profiles (Software Architects, Doctors, Product Managers, CAs).
  - `initialBrideProfiles`: Diverse bride profiles (Designers, Orthodontists, Cloud Architects, Corporate Lawyers).
  - `initialNotifications`, `initialMatches`, `initialVisitors`.

---

### 4.5 State Management Providers (`lib/providers/`)

#### `lib/providers/discovery_provider.dart`
- **Purpose:** Manages the Groom and Bride feeds and swipe deck card index.
- **Key Functions:**
  - `setTabIndex(int index)`: Toggles between Groom (`0`) and Bride (`2`) without rebuilding feeds.
  - `setGroomCardIndex(int index)` / `setBrideCardIndex(int index)`: Synchronizes active swipe positions.
  - `addNewProfile(MatrimonyProfileModel profile)`: Inserts newly published profiles at the front of the feed.
  - `toggleInterestSent(profile)` / `toggleSaveProfile(profile)`: Updates local interaction state.

#### `lib/providers/search_filter_provider.dart`
- **Purpose:** Powers the search bar and filter sheet.
- **Key Functions:**
  - `activeFilterCount`: Getter returning count of applied filters (powers the app bar badge).
  - `updateFilters(...)`: Applies city, age range, religion, marital status, or education filters.
  - `clearAllFilters()`: Resets all filters back to default.
  - `filterProfiles(List<MatrimonyProfileModel> list)`: Runs the filter query engine against candidate lists.

#### `lib/providers/interaction_provider.dart`
- **Purpose:** Coordinates saved bookmarks, interests, matches, and visitors.
- **Key Functions:**
  - `isProfileSaved(profileId)`: Returns boolean bookmark status.
  - `toggleSaveProfile(profile)`: Adds or removes candidate from `_savedProfiles`.
  - `expressInterest(profile)`: Adds candidate to `_sentInterests`.
  - `acceptInterest(item)`: Moves candidate from `_receivedInterests` to mutual `_matches`.
  - `declineInterest(item)`: Declines an incoming request.

#### `lib/providers/profile_provider.dart`
- **Purpose:** Manages the user's profile and the multi-phase publishing wizard.
- **Key Functions:**
  - `setWizardPhase(int phase)`: Changes active wizard step (`1`, `2`, or `3`).
  - `resetWizard()`: Clears all draft input fields.
  - `updateMyProfile(updated)`: Persists inline edits from `MyProfileScreen`.
  - `publishWizardProfile()`: Simulates asynchronous profile publishing, creates a new `MatrimonyProfileModel`, and inserts it into the discovery feed.

#### `lib/providers/notification_provider.dart`
- **Purpose:** Handles notification count and inbox read status.
- **Key Functions:**
  - `unreadCount`: Getter returning count of unread items.
  - `markAsRead(id)` & `markAllAsRead()`: Clears unread indicators.
  - `removeNotification(id)`: Deletes an alert from the inbox.

#### `lib/providers/auth_provider.dart`
- **Purpose:** Holds mock login/logout state and account information.

---

### 4.6 Custom Reusable Widgets (`lib/widgets/`)

#### `lib/widgets/cards/matrimony_tinder_deck.dart`
- **Purpose:** Custom gesture engine with card rotation and stack depth.
- **Key Functions:**
  - `_onPanUpdate(DragUpdateDetails details)`: Tracks horizontal drag offset and rotates the card proportionally.
  - `_onPanEnd(DragEndDetails details)`: Determines swipe outcome based on drag distance ($> 25\%$ width) or velocity ($> 450\text{ px/s}$).
  - `_animateSwipe(targetOffset, targetAngle, isNext)`: Triggers smooth translation and rotation offscreen.
  - `_animateBackToCenter()`: Rebounds card back to center if swipe threshold was not met.
  - `_manualPass()` & `_manualInterest()`: Handles button tap triggers.

#### `lib/widgets/cards/matrimony_card_view.dart`
- **Purpose:** The image-first candidate card.
- **Key Elements:**
  - Dominant profile photograph with fallback monogram.
  - Dark gradient overlay for readable text.
  - Top badges for compatibility score and profile ID.
  - Summary row (Name, Age, Occupation, Location, Community).
  - Reveal full bio prompt bar.
  - Action buttons: Pass (X), Bookmark, Details (Info), and Express Interest (Heart).

#### `lib/widgets/common/curved_bottom_nav.dart`
- **Purpose:** Persistent bottom navigation bar with animated center action.
- **Key Elements:**
  - Left: Groom tab.
  - Right: Bride tab.
  - Center: Elevated circular button with continuous scale pulse and a 3-second cycle timer alternating between a pulsating heart icon and an `+` add icon.

#### `lib/widgets/common/custom_app_bar.dart`
- **Purpose:** Header bar.
- **Key Elements:**
  - Brand identity: "Vows & Souls".
  - Filter button with dynamic active filter count badge.
  - Notification icon with unread badge counter.
  - User avatar with gold ring opening the Account Hub.

#### `lib/widgets/modals/profile_details_modal.dart`
- **Purpose:** Expandable bottom sheet for full profile inspection.
- **Sections:**
  - About/Bio.
  - Personal Details (Gender, Age, DOB, Marital Status, Height, Religion, Caste, Diet).
  - Education & Career (Degree, Profession, Workplace, Annual Income).
  - Location & Residence (City, Locality, State, Country).
  - Family Background (Family Type, Values, Heritage).
  - Partner Preferences (Age range, Marital Status, Location, Education, Expectations).

#### `lib/widgets/modals/search_filter_sheet.dart`
- **Purpose:** Filter sheet allowing users to set Age Range (slider), City (chips), Religion (chips), and Marital Status (chips).

---

### 4.7 Application Screens (`lib/screens/`)

| Screen File | Destination / Purpose | Connected Providers |
| :--- | :--- | :--- |
| `main_screen.dart` | Root shell managing `IndexedStack` between feeds and navigation. | `DiscoveryProvider`, `SearchFilterProvider` |
| `groom_feed_screen.dart` | Scrollable/swipeable feed of groom candidates. | `DiscoveryProvider`, `SearchFilterProvider`, `InteractionProvider` |
| `bride_feed_screen.dart` | Scrollable/swipeable feed of bride candidates. | `DiscoveryProvider`, `SearchFilterProvider`, `InteractionProvider` |
| `publish_wizard_screen.dart` | 3-Phase step-by-step profile publishing wizard. | `ProfileProvider`, `DiscoveryProvider` |
| `notifications_screen.dart` | Inbox with read/unread tracking and tap-to-view profile. | `NotificationProvider` |
| `settings_profile_screen.dart` | Account Hub with user photo and grouped menu options. | `AuthProvider`, `ProfileProvider`, `InteractionProvider` |
| `my_profile_screen.dart` | User's own profile view with inline edit mode. | `ProfileProvider` |
| `saved_profiles_screen.dart` | Bookmarked profiles list with remove-from-saved action. | `InteractionProvider` |
| `interests_screen.dart` | Dual tabs: Interests Sent & Interests Received (with Accept/Decline). | `InteractionProvider` |
| `matches_screen.dart` | Mutual compatibility matches with matching criteria tags. | `InteractionProvider` |
| `visitors_screen.dart` | Profile visitors log with view counts and timestamps. | `InteractionProvider` |
| `static_settings_screen.dart` | Privacy settings, notification preferences, help & about. | Static State |

---

## 5. End-to-End User Interaction Flows

### Flow 1: Profile Discovery & Expressing Interest
1. User browses candidate cards on `GroomFeedScreen` or `BrideFeedScreen`.
2. Card initially shows large photo, name, age, occupation, and compatibility score.
3. User can tap the card or select *"Tap to Reveal Full Matrimonial Bio"* $\rightarrow$ opens `ProfileDetailsModal` displaying all personal, family, and partner preference sections.
4. User swipes right or taps the heart button:
   - `InteractionProvider.expressInterest(profile)` marks interest as sent.
   - Candidate is added to the user's `Interests Sent` list.
   - Feedback snackbar appears.

### Flow 2: 3-Phase Publishing Wizard
1. User taps the animated center button in the bottom navigation bar.
2. `PublishWizardScreen` opens at **Phase 1 of 3**:
   - User inputs ownership, candidate name, gender, DOB, marital status, height, religion, and reviews photo preview.
   - Validates required fields before proceeding.
3. User advances to **Phase 2 of 3**:
   - User inputs education, occupation, income, city, locality, family type, and family background.
4. User advances to **Phase 3 of 3**:
   - User sets partner age range, preferred location, expectations, and personal bio.
   - Live preview card renders how other candidates will see the profile.
5. User taps **"Publish Profile"**:
   - `ProfileProvider.publishWizardProfile()` simulates submission.
   - Profile is inserted into the active discovery feed.
   - Wizard closes with a success confirmation.

### Flow 3: Managing Received Interests & Mutual Matches
1. User opens top-right avatar $\rightarrow$ **Account Hub** $\rightarrow$ **Interests Received**.
2. User reviews candidates who expressed interest.
3. Tapping **"Accept Interest"**:
   - Updates status to *Accepted*.
   - Automatically promotes candidate into **My Matches** with compatibility tags.
4. Tapping **"Decline"**:
   - Marks request as declined.

---

## 6. Phase 2 Backend Integration Roadmap

When you are ready to implement the Node.js backend:
1. **Authentication API:** Passwordless 6-digit Email OTP via Nodemailer with rate limiting and JWT tokens.
2. **Profile APIs:** REST endpoints for `POST /api/matrimony-profiles`, `GET /api/matrimony-profiles/feed`, and `PUT /api/matrimony-profiles/my`.
3. **Interests & Matching Engine:** Endpoints for `POST /api/interests/express`, `POST /api/interests/:id/respond`, and `GET /api/matches`.
4. **Relational MySQL Database:** Normalized tables for `users`, `email_otp`, `matrimony_profiles`, `saved_profiles`, `interests`, `matches`, and `notifications`.
