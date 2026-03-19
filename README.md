# RideLink Mobile App

A real-time carpooling platform for daily commuters in Addis Ababa, built with Flutter.

---

## Quick Start

### Prerequisites

- **Flutter SDK** 3.9.0 or higher — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Android Studio** or **VS Code** with Flutter/Dart plugins
- **Android Emulator** (API 21+) or a physical Android device
- **iOS Simulator** (macOS only) or a physical iOS device

Verify your setup:

```bash
flutter doctor
```

### Clone & Run

```bash
git clone https://github.com/RideLinkGC/mobile.git
cd mobile
flutter pub get
flutter run
```

If running on an Android emulator, the app is pre-configured to connect to a backend at `http://10.0.2.2:5000/api` (which maps to `localhost:5000` on your host machine).

---

## Demo Login (No Backend Needed)

The app has a **Demo Mode** so you can explore the full UI without running the backend.

On the login screen, scroll down to the "or try demo" section and tap either:

- **Passenger** — opens the passenger flow (search trips, book rides, track driver, chat, etc.)
- **Driver** — opens the driver flow (create trips, manage bookings, start tracking, etc.)

Demo mode uses mock data for all screens so you can see every feature.

---

## Real Backend Login

To test with the real backend:

1. **Start the backend** — ask the backend team for setup instructions, or run:
   ```bash
   cd ../backend
   npm install
   npx prisma generate
   npx prisma db push
   npm run dev
   ```
   The backend should be running on `http://localhost:5000`.

2. **Start Convex** (for real-time features):
   ```bash
   cd ../backend
   npx convex dev
   ```

3. **Register a new account** on the app's Register screen, or sign in with an existing account.

4. If the backend is running on a different machine/IP, update `baseUrl` in:
   ```
   lib/core/constants/app_constants.dart
   ```

---

## Project Structure

```
lib/
├── core/                      # Shared infrastructure
│   ├── constants/             # App constants, enums, Convex function names
│   ├── network/               # ApiClient (Dio), endpoints, interceptors
│   ├── router/                # GoRouter configuration
│   ├── services/              # Storage, Location, Maps, Chapa services
│   ├── theme/                 # Colors, typography, themes
│   └── widgets/               # Reusable widgets (AppButton, AppCard, MapWidget, etc.)
│
├── features/                  # Feature modules
│   ├── auth/                  # Login, Register, Onboarding, Splash
│   │   ├── models/            # UserModel
│   │   ├── providers/         # AuthProvider
│   │   └── screens/           # LoginScreen, RegisterScreen, etc.
│   │
│   ├── driver/                # Driver-specific features
│   │   ├── home/screens/      # DriverHomeScreen
│   │   └── trip/              # Trip CRUD, Series, Booking Requests
│   │       ├── models/        # TripModel, TripSeriesModel
│   │       ├── providers/     # TripProvider, TripSeriesProvider
│   │       └── screens/       # CreateTrip, TripDetail, BookingRequests, CreateSeries
│   │
│   ├── passenger/             # Passenger-specific features
│   │   ├── home/screens/      # PassengerHomeScreen
│   │   ├── search/            # Search trips, view driver details
│   │   │   ├── providers/     # SearchProvider
│   │   │   └── screens/       # SearchScreen, SearchResults, DriverDetail
│   │   └── booking/           # Booking management
│   │       ├── models/        # BookingModel, TripSubscriptionModel
│   │       ├── providers/     # BookingProvider
│   │       └── screens/       # BookingConfirm, ActiveBooking, MySubscriptions
│   │
│   ├── chat/                  # Real-time chat (Convex)
│   ├── notifications/         # Real-time notifications (Convex)
│   ├── tracking/              # Live GPS tracking (Convex)
│   ├── emergency/             # SOS alert system (Convex)
│   ├── feedback/              # Ratings & reports
│   ├── payment/               # Chapa payment & subscription
│   └── profile/               # Profile, settings, verification
│
├── l10n/                      # Localization (English + Amharic)
├── app.dart                   # Root MaterialApp widget
└── main.dart                  # Entry point with provider setup
```

---

## Architecture

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **State Management** | Provider | All app state via ChangeNotifier providers |
| **Navigation** | GoRouter | Declarative routing with shell routes for bottom nav |
| **REST API** | Dio | HTTP client with auth interceptor for backend calls |
| **Real-Time** | Convex Flutter SDK | Chat, notifications, tracking, SOS via WebSocket subscriptions |
| **Maps** | Gebeta Maps (Mapbox GL) | Ethiopian map tiles, geocoding, routing |
| **Payments** | Chapa SDK | In-app mobile payments (Telebirr, CBEBirr, etc.) |
| **Auth** | Better Auth (backend) | Session-based auth with JWT for Convex |
| **Storage** | SharedPreferences + FlutterSecureStorage | Tokens, user prefs, recent searches |
| **Localization** | flutter_localizations + ARB | English and Amharic |

---

## Key Configuration

All config values are in `lib/core/constants/app_constants.dart`:

| Constant | Description | When to Change |
|----------|-------------|---------------|
| `baseUrl` | Backend API URL | Change if backend runs on a different host/port |
| `convexUrl` | Convex deployment URL | Change if using a different Convex project |
| `gebetaMapsApiKey` | Gebeta Maps API key | Change if key expires or for a new project |
| `chapaPublicKey` | Chapa test public key | Change for production or a different Chapa account |

---

## Screens Overview

### Passenger Flow
| Screen | Route | Description |
|--------|-------|-------------|
| Home | `/passenger` | Map, search bar, active & past bookings |
| Search | `/search` | Origin/destination input with recent searches |
| Search Results | `/search-results` | Trip list with sorting & filtering |
| Driver Detail | `/driver-detail/:tripId` | Trip info, driver reviews, book/subscribe |
| Booking Confirm | `/booking-confirm/:tripId` | Pickup/dropoff, price breakdown, confirm |
| Active Booking | `/active-booking/:tripId` | Booking status, driver contact, actions |
| Live Tracking | `/tracking/:tripId` | Real-time driver location on map |
| Payment | `/payment/:bookingId` | Chapa or cash payment |
| Subscription | `/subscription/:tripId` | Weekly/monthly subscription plans |
| My Subscriptions | `/my-subscriptions` | Manage active subscriptions |

### Driver Flow
| Screen | Route | Description |
|--------|-------|-------------|
| Home | `/driver` | Trip list, stats (scheduled, active, earnings) |
| Create Trip | `/create-trip` | Form with map route selection |
| Trip Detail | `/trip-detail/:tripId` | Trip info, passengers, start/complete/cancel |
| Booking Requests | `/booking-requests/:tripId` | Accept/decline pending bookings |
| Create Series | `/create-series` | Recurring trip setup |
| Live Tracking | `/tracking/:tripId` | Broadcast location to passengers |

### Shared
| Screen | Route | Description |
|--------|-------|-------------|
| Chat List | `/chat-list` | All conversations |
| Chat | `/chat/:conversationId` | Real-time messaging |
| Notifications | `/notifications` | All alerts with badge count |
| Profile | `/profile` | User info, stats, actions |
| SOS | `/sos/:tripId` | Emergency alert with countdown |
| Rating | `/rating/:tripId` | Rate a driver after trip |
| Report | `/report/:targetId` | Report a user |

---

## Useful Commands

```bash
# Run the app
flutter run

# Run on a specific device
flutter run -d <device_id>

# Run in release mode
flutter run --release

# Analyze code for issues
flutter analyze

# Run tests
flutter test

# Generate localization files
flutter gen-l10n

# Clean build
flutter clean && flutter pub get
```

---

## Git Workflow

We follow a feature-branch workflow:

```bash
# Create a new branch for your work
git checkout -b feature/your-feature-name

# Make changes, then commit
git add .
git commit -m "Add: description of what you did"

# Push your branch
git push -u origin feature/your-feature-name

# Create a Pull Request on GitHub for review
```

**Branch naming:**
- `feature/` — new features
- `fix/` — bug fixes
- `ui/` — UI-only changes

---

## Backend Repository

The backend is in a separate repo managed by the backend team. The Flutter app communicates with it via:

- **REST API** (`/api/*`) — for CRUD operations (trips, bookings, auth, feedback)
- **Convex** — for real-time features (chat, notifications, tracking, SOS)

See `backend_tasks.md` in the project root for pending backend features.
