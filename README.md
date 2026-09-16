# EventHub - Event Discovery & Booking Mobile App

A complete, production-grade cross-platform mobile application developed with **Flutter (Dart)** for discovering, booking, and managing events. Built following official Flutter documentation, Material 3 design principles, and robust architecture patterns.

---

## 🌟 Features

### 1. User & Organizer Authentication
- **Role-Based Accounts**: Register and authenticate as a standard **User** (discover & book events) or **Organizer** (publish & manage events).
- **Session Persistence**: Automated auto-login via `shared_preferences` and secure session tracking.
- **Form Validation**: Strict regex validation for emails, strong passwords (6+ chars, letter + number), 10-digit phone numbers, and matching passwords.
- **Profile Management**: View and edit user details, phone number, profile picture, and change passwords.

### 2. Event Discovery & Browsing
- **Responsive Layout**: Adaptive GridView rendering (2 columns on mobile, 3 columns on tablet/desktop) via `LayoutBuilder`.
- **Search & Filter**: Real-time search across event titles, locations, and descriptions. Category chips for `Music`, `Sports`, `Tech`, `Food`, `Art`, `Education`, and `Other`.
- **Sorting Options**: Sort by date (asc/desc), ticket price (low/high), or popularity.
- **Real-Time Badges**: Dynamic indicators for **"Sold Out"** (`availableSeats == 0`) and **"Few seats left"** (`availableSeats <= 5`).
- **Pull-to-Refresh**: Seamless gesture updates for the latest seat availability and listings.
- **Local Favorites**: Toggle and save favorite events locally with **Hive** offline storage.

### 3. Comprehensive Event Details
- **Hero Transitions**: Smooth image transitions from cards into the detailed view.
- **Rich Meta Information**: Interactive category chips, formatted dates & times, venue location, organizer profiles, and interactive map placeholder.
- **Related Events**: Intelligent recommendations showcasing other events in the same category.
- **Native Sharing**: Share event details directly with other apps.

### 4. Step-by-Step Booking System
- **Pre-Booking Availability Check**: Verifies live seat availability directly against `GET /events/:id` to prevent overbooking.
- **Interactive Ticket Stepper**: Dynamically selects seats with real-time total price calculation.
- **Pre-filled Details**: Automatically prefills user contact information from the active profile.
- **Booking Reference Generation**: Generates unique alphanumeric booking codes (e.g. `EVH-847291`).
- **Immediate Notifications**: Dispatches local push notifications for confirmed bookings and cancellations.
- **Offline Cache**: Automatically caches bookings in Hive for offline ticket review.

### 5. My Bookings Management
- **Tabbed Interface**: Segmented view separating **Upcoming** from **Past** events.
- **Status Indicators**: Badges for `Confirmed`, `Cancelled`, and `Completed`.
- **Self-Service Cancellation**: Safely cancel upcoming bookings with confirmation dialogs, restoring seats back to the event pool.

### 6. Organizer Dashboard & Event Publishing
- **Dedicated Organizer Hub**: Track published events, filter active vs. past events, and inspect total tickets sold.
- **Add / Edit Event Studio**: Full form with image URL live preview, Material 3 Date and Time pickers, category dropdowns, geo-coordinates, and seat allocations.
- **Attendee Tracking**: Detailed list of attendees per event with contact info, seats booked, total revenue, and export feedback.
- **Event Deletion**: Safe deletion with warning if active bookings are registered.

### 7. Offline Resilience & Notifications
- **Hive Storage**: High-performance NoSQL offline persistence for favorite events and booking caches.
- **Local Notifications**: Handled via `flutter_local_notifications` for booking confirmations, cancellations, reminders, and welcome messages.
- **Adaptive Theme**: Toggle between Light and Dark modes with persistent storage.

---

## 📸 Screenshots

| Splash & Onboarding | Event Discovery | Event Details |
|:---:|:---:|:---:|
| *(Screenshot Placeholder: Splash)* | *(Screenshot Placeholder: Home)* | *(Screenshot Placeholder: Details)* |

| Booking Stepper | My Bookings (Tickets) | Organizer Dashboard |
|:---:|:---:|:---:|
| *(Screenshot Placeholder: Booking)* | *(Screenshot Placeholder: My Bookings)* | *(Screenshot Placeholder: Organizer)* |

---

## 🛠️ Technologies Used

- **Framework**: Flutter (Dart 3.x)
- **State Management**: `provider` (ChangeNotifier, Consumer, Selector)
- **Networking**: `dio` with Interceptors, Timeouts (10s), and Retry logic
- **Local Storage**: `shared_preferences` (session & settings) + `hive` / `hive_flutter` (favorites & offline cache)
- **Local Notifications**: `flutter_local_notifications`
- **Images**: `cached_network_image`
- **Typography & UI**: `google_fonts` (Poppins), Material Icons, Material 3 Design
- **Formatting**: `intl`
- **Backend**: `json-server` (Mock REST API)

---

## 📂 Project Structure

```
eventhub/
├── pubspec.yaml
├── .gitignore
├── README.md
├── db.json
└── lib/
    ├── main.dart
    ├── models/
    │   ├── user_model.dart
    │   ├── event_model.dart
    │   ├── booking_model.dart
    │   └── notification_model.dart
    ├── services/
    │   ├── api_service.dart
    │   ├── auth_service.dart
    │   ├── event_service.dart
    │   ├── booking_service.dart
    │   ├── local_storage_service.dart
    │   └── notification_service.dart
    ├── providers/
    │   ├── auth_provider.dart
    │   ├── event_provider.dart
    │   ├── booking_provider.dart
    │   └── theme_provider.dart
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── auth/
    │   │   ├── login_screen.dart
    │   │   └── register_screen.dart
    │   ├── home/
    │   │   ├── home_screen.dart
    │   │   └── main_navigation.dart
    │   ├── events/
    │   │   ├── event_list_screen.dart
    │   │   ├── event_detail_screen.dart
    │   │   └── event_search_screen.dart
    │   ├── bookings/
    │   │   ├── my_bookings_screen.dart
    │   │   └── booking_form_screen.dart
    │   ├── organizer/
    │   │   ├── organizer_dashboard.dart
    │   │   ├── add_edit_event_screen.dart
    │   │   └── event_bookings_screen.dart
    │   ├── profile/
    │   │   ├── profile_screen.dart
    │   │   └── edit_profile_screen.dart
    │   └── favourites/
    │       └── favourites_screen.dart
    ├── widgets/
    │   ├── event_card.dart
    │   ├── booking_card.dart
    │   ├── custom_button.dart
    │   ├── custom_textfield.dart
    │   ├── loading_widget.dart
    │   ├── empty_state.dart
    │   ├── error_widget.dart
    │   └── app_drawer.dart
    └── utils/
        ├── constants.dart
        ├── validators.dart
        ├── theme.dart
        └── routes.dart
```

---

## 🚀 Setup & Execution Guide

### Prerequisites
1. **Flutter SDK**: Install the latest Flutter SDK (>= 3.0.0). Verify via:
   ```bash
   flutter doctor
   ```
2. **Node.js & npm**: Install Node.js (for `json-server`).

### 1. Start the Mock REST API (json-server)
Install and run `json-server` from the root directory:
```bash
# Option A: Run directly via npx
npx json-server --watch db.json --port 3000

# Option B: Install globally and run
npm install -g json-server
json-server --watch db.json --port 3000
```
> **Note for Android Emulators**: Android emulators map host `localhost:3000` to `http://10.0.2.2:3000`. The app handles this automatically in `lib/utils/constants.dart`.

### 2. Run the Flutter Mobile App
In another terminal:
```bash
# Get dependencies
flutter pub get

# Run on connected device, emulator, or Chrome
flutter run
```

---

## 🔑 Test Credentials

The database (`db.json`) comes pre-populated with ready-to-test user accounts:

| Role | Email | Password | Details |
|:---|:---|:---|:---|
| **Regular User** | `user@test.com` | `Test@123` | Can discover, favorite, and book events. 4 sample bookings. |
| **Organizer** | `organizer@test.com` | `Test@123` | Can publish, edit, delete events, and view attendee lists. |
| **Organizer 2** | `organizer2@test.com` | `Test@123` | Additional organizer account with active events. |

*(Quick test-credential filler buttons are also integrated directly into the Login screen for instant one-tap testing).*

---

## 📤 Git Submission Commands

To submit or push this project to a remote Git repository:
```bash
git init
git add .
git commit -m "Initial commit: EventHub cross-platform app"
git branch -M main
git remote add origin <repo-url>
git push -u origin main
```
