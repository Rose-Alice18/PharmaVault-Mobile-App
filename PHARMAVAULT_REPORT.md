# ASHESI UNIVERSITY

## PharmaVault

### CS 443: MOBILE DEVELOPMENT

**Roseline Dzidzeme Tsatsu**

Lecturer: Mr. David A. Sampah

April 2026

---

# PharmaVault — Mobile Application Development Report

---

## Activity 1: Planning, Case Scenario and Contract

### 1.1 Background Information

Access to medicines in Ghana and across sub-Saharan Africa is fragmented. Patients often visit multiple pharmacies looking for a specific drug, compare prices verbally, or rely on word-of-mouth to find nearby pharmacies with stock. There is no centralized, real-time digital channel connecting patients to verified pharmacies, their inventories, and their pricing.

PharmaVault was conceived as a direct solution to this problem. It is a mobile application built for patients and healthcare consumers in Ghana that allows them to browse medicines, compare prices across partner pharmacies, upload prescriptions for fulfillment, add medicines to a cart, and place delivery orders — all from a single app. Partner pharmacies are onboarded as profiles on the platform and manage their own product listings and pricing.

The target organisation is any pharmacy chain, independent pharmacy, or patient-facing health service operating in Ghana. The application is designed for individual patient use. Its principal purpose is to reduce the time and cost of accessing medicines by making pharmacy inventory and pricing transparent and delivery-enabled.

---

### 1.2 Target Market

- Individual patients and healthcare consumers in Ghana
- Patients managing chronic conditions (diabetes, hypertension, malaria) who need regular medicine refills
- Caregivers purchasing medicines on behalf of family members
- Patients in urban and peri-urban areas with limited mobility
- Partner pharmacies seeking a digital storefront and order management channel

---

### 1.3 Principal Services the App Provides

- Browse medicines by category, brand, or keyword search
- View real-time pharmacy pricing and stock levels per product
- Compare prices across multiple pharmacies for the same medicine
- View partner pharmacy profiles with location, contact, and operating hours
- GPS-based distance display from user to each pharmacy
- Upload prescriptions for pharmacist review and fulfillment
- Add medicines to a cart and place delivery orders
- Track order status in real-time (Pending → Confirmed → Dispatched → Delivered)
- Receive in-app push notifications on order and prescription status changes
- Manage profile, delivery address, and contact information
- Secure authentication via email/password or Google Sign-In

---

### 1.4 Functional and Non-Functional Requirements

#### 1.4.1 Functional Requirements

- The app shall allow a user to create an account and log in securely
- The app shall support Google Sign-In as an authentication option
- The app shall display a browsable, searchable catalogue of medicines
- The app shall show which pharmacies carry each medicine and at what price
- The app shall allow users to filter medicines by category
- The app shall display partner pharmacies with name, city, rating, and distance from user
- The app shall allow users to add medicines to a cart and adjust quantities
- The app shall allow users to place orders with a delivery address and contact
- The app shall generate a unique invoice number for each order
- The app shall allow users to view their order history and order details
- The app shall allow users to upload a prescription image for pharmacy review
- The app shall send in-app push notifications when order status changes
- The app shall send in-app push notifications when prescription status is updated
- The app shall display the user's real GPS location in the home screen header
- The app shall open Google Maps for directions to a selected pharmacy
- The app shall allow users to update their profile name, contact, and city
- The app shall persist all data to Supabase across reinstalls and device changes

#### 1.4.2 Non-Functional Requirements

- All data storage and authentication must be handled by Supabase (no separate backend server)
- Authentication must be secure — passwords are never stored in plain text
- User data must be isolated — Row Level Security ensures users can only access their own cart, orders, and prescriptions
- The app must respond within 2 seconds for all local and cached operations
- The app must work on Android 8.0 (API 26) and above
- The UI must be usable on screen sizes from 5 to 7 inches
- The app must gracefully handle no-internet conditions with appropriate error messages

---

### 1.5 Local Resources Used

PharmaVault makes direct use of on-device hardware and operating system resources to deliver its core functionality. Each resource requires an explicit Android runtime permission and is accessed through a dedicated Flutter package.

| Resource | Package Used | Usage in PharmaVault |
|---|---|---|
| GPS / Location | geolocator ^13.0.2 | Getting user's real-time coordinates for city display and pharmacy distance |
| Reverse Geocoding | geocoding ^3.0.0 | Converting GPS coordinates to a human-readable city name |
| Camera / Gallery | image_picker ^1.1.2 | Capturing or selecting prescription images for upload |
| Push Notifications | flutter_local_notifications ^18.0.1 | Displaying order and prescription status update banners |
| Maps / Directions | url_launcher ^6.3.1 | Opening Google Maps with navigation to a selected pharmacy |
| Network Images | cached_network_image ^3.4.1 | Loading and caching product and pharmacy images from Supabase Storage |

#### 1.5.1 Required Android Permissions

PharmaVault declares the following permissions in `AndroidManifest.xml`:

| Permission | Purpose |
|---|---|
| INTERNET | All Supabase API calls, image loading, and real-time subscriptions |
| ACCESS_FINE_LOCATION | Precise GPS coordinates for distance-to-pharmacy calculation |
| ACCESS_COARSE_LOCATION | Fallback coarse location for city name display |
| POST_NOTIFICATIONS | Displaying order and prescription update notification banners (Android 13+) |
| READ_MEDIA_IMAGES | Gallery access for selecting prescription photos |
| READ_EXTERNAL_STORAGE | Legacy gallery access for Android 12 and below |
| CAMERA | Capturing prescription photos directly from the app |

---

## Activity 2: Prototyping, Specification, Architecture and Design

### 2.1 Application Overview

PharmaVault follows a two-layer client-cloud architecture. The Flutter mobile app acts as the client. Supabase provides authentication, a PostgreSQL cloud database, real-time subscriptions, and file storage — eliminating the need for a separate backend server. All business logic runs inside Flutter providers and Supabase Row Level Security policies.

---

### 2.2 High-Level Architecture / Communication Flow

```
Layer 1 — Client (Mobile App)
Flutter Mobile App (Android)

Splash → Onboarding → Auth → Main App
Home | Search | Cart | Orders | Profile
Product Detail | Pharmacy Detail | Order Detail
Upload Prescription | Notifications | Settings

         ↕ Supabase Flutter SDK (REST + Realtime + Storage)

Layer 2 — Cloud (Supabase)

┌─────────────────┬──────────────────┬────────────────────┐
│  Supabase Auth  │  PostgreSQL DB   │  Supabase Storage  │
│  Email + Google │  10 tables + RLS │  prescriptions     │
│  OAuth          │  Realtime subs   │  bucket            │
└─────────────────┴──────────────────┴────────────────────┘
```

---

### 2.3 Three-Layer Architecture

| Layer | Responsibility | Key Technologies |
|---|---|---|
| Presentation Layer | All UI screens, widgets, navigation flows, and user input handling | Flutter Widgets, Material 3, NavigationBar, CustomScrollView |
| Logic Layer | State management, Supabase queries, GPS fetching, notification triggering, cart operations, order creation | Provider (AuthProvider, ProductProvider, CartProvider, OrderProvider, LocationProvider, NotificationProvider, PrescriptionProvider) |
| Data Layer | Data models, Supabase reads/writes, Realtime subscriptions, SharedPreferences, local file handling | supabase_flutter, Dart model classes, shared_preferences |

---

### 2.4 Key Modules

| Module | Description |
|---|---|
| Authentication | Email/password signup & login, Google Sign-In via `google_sign_in` + Supabase `signInWithIdToken`, profile creation on registration |
| Home Screen | Greeting with real GPS city, search bar, prescription upload banner, category chips, horizontal product cards with Rx badges, pharmacy cards with distance and delivery tags |
| Search Screen | Tabbed Medicines / Pharmacies search with live filtering, category filter chips, result count, pull-to-refresh |
| Product Detail | Full product info, dosage, side effects, "Available At" section showing real pharmacies with per-pharmacy pricing and stock |
| Pharmacy Detail | Pharmacy header with rating and hours, list of pharmacy-specific products with their prices and stock counts, Directions button opening Google Maps |
| Cart | Item listing with quantity controls, total calculation, persistent across sessions via Supabase |
| Checkout & Orders | Delivery address form, order placement with invoice generation, order history, order detail with itemised breakdown |
| Prescriptions | Upload prescription photo (camera or gallery) to Supabase Storage, view upload history and status |
| Notifications | In-app notification history from Supabase Realtime, unread count badge, mark-all-read |
| Profile | View and update name, contact, city; logout |
| Location Service | GPS permission flow, reverse geocoding to city name, distance calculation to pharmacies |
| Pharmacy–Product Linking | `pharmacy_products` table links pharmacies to their products with per-pharmacy pricing and stock |

---

### 2.5 Users and Use Case Diagram

PharmaVault has two actors: the **Customer** (patient using the app) and the **Pharmacy** (a partner pharmacy whose profile and inventory is in the system). There is no admin interface in the mobile app — pharmacy inventory and order status management is currently done directly in Supabase.

```
Customer
├── Register / Login / Google Sign-In
├── Browse Medicines
│   ├── Filter by Category
│   ├── Search by Name or Brand
│   └── View Product Detail
│       └── See Available Pharmacies + Prices
├── Browse Pharmacies
│   ├── View Distance from Location
│   └── View Pharmacy Detail
│       ├── See Pharmacy Products + Prices
│       └── Get Directions (Google Maps)
├── Cart
│   ├── Add / Remove Items
│   ├── Adjust Quantities
│   └── Checkout → Place Order
├── Orders
│   ├── View Order History
│   └── View Order Detail
├── Upload Prescription
│   └── Track Prescription Status
├── Receive Notifications
│   ├── Order Status Update
│   └── Prescription Status Update
└── Manage Profile
    └── Update Name / Contact / City
```

---

### 2.6 Database Schema (Supabase PostgreSQL)

PharmaVault uses ten tables in Supabase PostgreSQL. Row Level Security is enabled on all tables.

#### Table: profiles
| Field | Type | Description |
|---|---|---|
| id | UUID (PK, FK → auth.users) | User identifier |
| customer_name | TEXT | Full name |
| customer_email | TEXT | Email address |
| customer_type | TEXT | 'customer' or 'pharmacy' |
| customer_contact | TEXT | Phone number |
| customer_city | TEXT | City |
| customer_image | TEXT | Profile image URL |
| lat | DOUBLE PRECISION | GPS latitude (pharmacies only) |
| lng | DOUBLE PRECISION | GPS longitude (pharmacies only) |

#### Table: categories
| Field | Type | Description |
|---|---|---|
| cat_id | SERIAL (PK) | Category ID |
| cat_name | TEXT | Category name (e.g. Pain Relief, Antibiotics) |

#### Table: brands
| Field | Type | Description |
|---|---|---|
| brand_id | SERIAL (PK) | Brand ID |
| brand_name | TEXT | Brand name (e.g. Panadol, Ampiclox) |

#### Table: products
| Field | Type | Description |
|---|---|---|
| product_id | SERIAL (PK) | Product ID |
| product_title | TEXT | Medicine name and dosage |
| product_description | TEXT | Description |
| product_price | DECIMAL(10,2) | Base price in GHS |
| product_stock | INTEGER | Global stock count |
| product_image | TEXT | Image URL |
| product_keywords | TEXT | Tags including 'rx' for prescription-only |
| cat_id | INTEGER (FK → categories) | Category |
| brand_id | INTEGER (FK → brands) | Brand |

#### Table: pharmacy_products
| Field | Type | Description |
|---|---|---|
| id | SERIAL (PK) | Row ID |
| pharmacy_id | UUID (FK → profiles) | Pharmacy |
| product_id | INTEGER (FK → products) | Product |
| pharmacy_price | DECIMAL(10,2) | This pharmacy's price for this product |
| stock_count | INTEGER | This pharmacy's current stock |
| is_available | BOOLEAN | Whether currently listed |

#### Table: cart
| Field | Type | Description |
|---|---|---|
| cart_id | SERIAL (PK) | Cart row ID |
| c_id | UUID (FK → profiles) | Customer |
| p_id | INTEGER (FK → products) | Product |
| cart_qty | INTEGER | Quantity |

#### Table: orders
| Field | Type | Description |
|---|---|---|
| order_id | SERIAL (PK) | Order ID |
| invoice_no | TEXT | Unique invoice (e.g. INV-2026-1234567) |
| c_id | UUID (FK → profiles) | Customer |
| order_total | DECIMAL(10,2) | Total amount in GHS |
| order_status | TEXT | pending / confirmed / processing / dispatched / delivered / cancelled |
| is_paid | BOOLEAN | Payment status |
| payment_amount | DECIMAL(10,2) | Amount paid |
| delivery_notes | JSONB | Address, city, contact |
| order_date | TIMESTAMPTZ | Timestamp of order placement |

#### Table: order_items
| Field | Type | Description |
|---|---|---|
| item_id | SERIAL (PK) | Item ID |
| order_id | INTEGER (FK → orders) | Parent order |
| p_id | INTEGER (FK → products) | Product |
| item_qty | INTEGER | Quantity ordered |
| item_price | DECIMAL(10,2) | Price at time of order |

#### Table: prescriptions
| Field | Type | Description |
|---|---|---|
| prescription_id | SERIAL (PK) | Prescription ID |
| c_id | UUID (FK → profiles) | Customer |
| prescription_image | TEXT | Supabase Storage URL |
| prescription_status | TEXT | pending / reviewing / approved / rejected |
| prescription_notes | TEXT | Pharmacist notes |
| created_at | TIMESTAMPTZ | Upload timestamp |

---

## Activity 3: Implementation

### 3.1 Overview

PharmaVault is built entirely on Flutter + Supabase with no separate backend server. All state is managed via the Provider pattern. Supabase handles authentication, all database reads and writes, real-time order/prescription status subscriptions, and prescription image storage. The app uses GPS for real-time location and `flutter_local_notifications` for in-app notification banners.

---

### 3.2 Tools, Libraries, Frameworks, and Services

#### 3.2.1 Mobile Frontend

| Tool / Library | Version | Purpose |
|---|---|---|
| Flutter | 3.x | Cross-platform mobile UI framework |
| Dart | 3.x | Programming language |
| provider | ^6.1.2 | State management across 7 providers |
| supabase_flutter | ^2.8.4 | Auth, database, real-time, and storage client |
| google_sign_in | ^6.2.1 | Native Google OAuth sign-in |
| geolocator | ^13.0.2 | GPS coordinates for location and distance |
| geocoding | ^3.0.0 | Reverse geocoding coordinates → city name |
| url_launcher | ^6.3.1 | Opening Google Maps for pharmacy directions |
| cached_network_image | ^3.4.1 | Efficient network image loading and caching |
| image_picker | ^1.1.2 | Camera and gallery for prescription photos |
| flutter_local_notifications | ^18.0.1 | In-app notification banners |
| intl | ^0.19.0 | Date, time, and currency formatting |
| shared_preferences | ^2.3.3 | Onboarding seen flag, local settings |
| cupertino_icons | ^1.0.8 | iOS-style icons |

#### 3.2.2 Backend and Cloud Services

| Service | Purpose |
|---|---|
| Supabase (PostgreSQL) | Cloud-hosted relational database — 10 tables storing all app data |
| Supabase Auth | Email/password and Google OAuth authentication |
| Supabase Realtime | Live subscriptions on orders and prescriptions tables for notification triggering |
| Supabase Storage | `prescriptions` bucket storing uploaded prescription images |
| Google Cloud Console | Web OAuth client ID for Google Sign-In (`serverClientId`) |

---

### 3.3 Implementation Description

#### Authentication Flow

- **Email/password registration:** `Supabase.auth.signUp()` creates the auth user. A profile row is immediately upserted to the `profiles` table (using upsert rather than insert to handle the auto-trigger that creates a partial row). Email confirmation is disabled for development. On success, the user is navigated directly to `/main`.
- **Email/password login:** `signInWithPassword()` is called. On success, the cart is fetched and the Supabase Realtime subscription for notifications is started.
- **Google Sign-In:** `GoogleSignIn(serverClientId: webClientId).signIn()` retrieves an ID token. This is passed to `supabase.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: ...)`. No `google-services.json` or Google Services Gradle plugin is required — only the web OAuth client ID is needed. On first sign-in, a profile row is created.

#### Product & Pharmacy Data Flow

Products are fetched from the `products` table with joined `brands` and `categories`. Pharmacies are fetched from the `profiles` table filtered by `customer_type = 'pharmacy'`. The `pharmacy_products` table links each pharmacy to its own product subset with pharmacy-specific pricing and stock counts. Product detail queries `pharmacy_products` joined with `profiles` to show which pharmacies carry that medicine and at what price, ordered cheapest first.

#### Cart & Order Flow

1. User taps "Add to Cart" → `cart` row inserted/quantity incremented in Supabase
2. Cart screen fetches all cart rows with product joins
3. Checkout screen collects delivery address, city, contact
4. `OrderProvider.createOrder()` fetches cart, calculates total, generates invoice number (`INV-{year}-{milliseconds}`), inserts order row, inserts order_items rows, clears cart, fires a local notification "Order Placed!"
5. Order history fetched from `orders` table filtered by `c_id = auth.uid()`

#### GPS & Location Flow

1. `LocationProvider.fetchLocation()` is called at app startup via `..fetchLocation()` cascade in `main.dart`
2. Checks location service enabled → requests permission if needed
3. On grant: `Geolocator.getCurrentPosition()` gets coordinates → `placemarkFromCoordinates()` reverse geocodes to city name
4. Home screen header displays real city name (falls back to "Accra, Ghana" if denied)
5. Pharmacy cards show distance using `Geolocator.distanceBetween()` comparing user position to pharmacy lat/lng stored in `profiles`
6. Directions button in pharmacy detail launches `https://www.google.com/maps/dir/?api=1&destination={lat},{lng}` via `url_launcher`

#### Notification Flow

1. `NotificationService.initialize()` runs at app startup — creates Android notification channel "PharmaVault Notifications" with high importance, requests `POST_NOTIFICATIONS` permission on Android 13+
2. After login/register, `NotificationProvider.subscribe(userId)` opens two Supabase Realtime channels:
   - `orders` table `UPDATE` where `c_id = userId` → fires `showOrderUpdate()` banner
   - `prescriptions` table `UPDATE` where `c_id = userId` → fires `showPrescriptionUpdate()` banner
3. Order placement triggers `showOrderPlaced()` immediately
4. `NotificationsScreen` reads from `NotificationProvider.items` — real-time list with unread dots, timestamps, and mark-all-read

---

### 3.4 Key Design Decisions and Challenges

**No separate backend server:** Unlike typical e-commerce apps that require a Node.js or Python API server, PharmaVault runs entirely on Supabase. All queries, joins, and business logic are expressed as Supabase client calls with PostgreSQL-level RLS policies enforcing data isolation. This eliminated deployment complexity and infrastructure cost.

**Pharmacy–Product linking table:** The `pharmacy_products` table was introduced after initial development showed that the pharmacy detail screen was incorrectly showing all products to all pharmacies. The linking table gives each pharmacy its own product subset, price, and stock count independently.

**`upsert` for profile creation:** Supabase's `on_auth_user_created` database trigger creates a partial profile row immediately when a user signs up. The Flutter app's initial `insert` call was failing with a primary key conflict. Changing to `upsert` resolved this silently, with the app's data overwriting the empty trigger row.

**Google Sign-In without `google-services.json`:** The `google_sign_in` package supports a `serverClientId` parameter that allows Google OAuth to function using only the web client ID. The Google Services Gradle plugin (which requires `google-services.json`) is not needed. This was discovered after a build failure caused by attempting to add the plugin, and resolved by removing it entirely.

**RLS blocking profile insert on signup:** When Supabase email confirmation is enabled, `auth.uid()` returns null in the session immediately after `signUp()`, which caused the RLS policy `auth.uid() = id` to block the profile insert. This was resolved by disabling email confirmation for development, allowing the session to be active immediately after signup.

**FK constraint on pharmacy seed data:** The `profiles` table has a foreign key `profiles_id_fkey` referencing `auth.users`. Inserting seed pharmacy profiles with `gen_random_uuid()` IDs failed because those UUIDs had no corresponding auth users. Resolved by dropping the FK constraint before seeding, since pharmacy profiles are platform-managed data, not real user accounts.

**Supabase Realtime for notifications:** Rather than polling for order status changes, Supabase Realtime channels provide instant push-style updates while the app is open. The `NotificationProvider` opens one channel per table (orders, prescriptions) filtered to the authenticated user's ID, ensuring no cross-user data leakage.

---

### 3.5 Security Considerations

| Area | Implementation |
|---|---|
| Credentials | Supabase anon/publishable key (`sb_publishable_*`) is safe to expose client-side by design. The service role key is never in the Flutter app. |
| Row Level Security | All 10 tables have RLS enabled. Customers can only read/write their own cart, orders, and prescriptions. Products and pharmacy_products are publicly readable (SELECT only). |
| Pharmacy data isolation | Pharmacy profiles are readable by all (needed for the browse feature), but only the pharmacy's own row is updatable. |
| Google Sign-In | Uses `serverClientId` only — no Firebase service account credentials are in the app. |
| Input validation | All form fields are trimmed and validated client-side before any Supabase call. |
| Image uploads | Prescription images go to a private Supabase Storage bucket. Public read is intentionally disabled — only the authenticated user can access their own files. |

---

### 3.6 Screens Implemented

| Screen | Description |
|---|---|
| SplashScreen | Animated logo, checks Supabase session, routes to Home or Onboarding |
| OnboardingScreen | First-time user introduction slides |
| LoginScreen | Email/password login + Google Sign-In button |
| RegisterScreen | Full registration form (name, email, password, contact, city) |
| MainScreen | 5-tab NavigationBar shell (Home, Search, Cart, Orders, Profile) |
| HomeScreen | White header with GPS city + notification bell, greeting, search bar, prescription upload banner, category chips, horizontal product cards (with Rx badge), pharmacy cards (with distance + delivery tags) |
| SearchScreen | Large "Search" title, tabbed Medicines/Pharmacies, category filter chips, result count, pull-to-refresh |
| ProductDetailScreen | Product image, description, dosage, side effects, "Available At" (real pharmacies with per-pharmacy price and stock, sorted cheapest first), quantity selector, Add to Cart |
| PharmacyDetailScreen | Pharmacy header (rating, hours, Open badge), pharmacy-specific product list with individual prices and stock, Directions button (opens Google Maps), Call button |
| CartScreen | Cart items with quantity controls, subtotal, checkout button |
| CheckoutScreen | Delivery address, city, contact form; order confirmation |
| OrdersScreen | Order history list with invoice numbers, status badges, totals |
| OrderDetailScreen | Itemised order breakdown, delivery details, status timeline |
| UploadPrescriptionScreen | Camera/gallery picker, prescription image preview, upload to Supabase Storage |
| PrescriptionsScreen | List of uploaded prescriptions with status (pending/reviewing/approved/rejected) |
| NotificationsScreen | Real-time notification history from Supabase Realtime, unread dots, mark-all-read, empty state |
| ProfileScreen | View and edit name, contact, city; tap avatar to upload profile photo from gallery (stored in Supabase Storage `avatars` bucket); logout |
| SettingsScreen | App settings |
| HelpSupportScreen | Help and FAQ |
| SavedAddressesScreen | Saved delivery addresses |
| SavedPharmaciesScreen | Bookmarked partner pharmacies |

---

## Activity 4: Testing, Deployment and Presentation

### 4.1 Overview

PharmaVault is deployed entirely on Supabase cloud infrastructure. There is no self-hosted server. The Flutter app is distributed as an Android APK for testing on physical devices.

---

### 4.2 Deployment

#### 4.2.1 Database and Auth
- Hosted on **Supabase** (managed PostgreSQL + Auth + Storage + Realtime)
- Project URL: `https://sbjmzumtejbzwnrbjrdr.supabase.co`
- Row Level Security enabled on all 10 tables
- `prescriptions` storage bucket created for prescription image uploads
- Realtime enabled on `orders` and `prescriptions` tables

#### 4.2.2 Mobile App
- Debug APK: `build/app/outputs/flutter-apk/app-debug.apk`
- Release APK: `build/app/outputs/flutter-apk/app-release.apk`
- Build command: `flutter build apk --release`
- Min SDK: Android 6.0 (API 23) | Target SDK: Android 14 (API 34)

---

### 4.3 Test Cases

| No | Feature | Test | Expected Result |
|---|---|---|---|
| T1 | Registration | Register with valid name, email, password, contact, city | Account created, profile saved to Supabase, user navigated to Home |
| T2 | Login | Login with correct credentials | User navigated to Home with name shown in greeting |
| T3 | Login | Login with wrong password | Error snackbar displayed |
| T4 | Google Sign-In | Tap "Continue with Google" on physical device | Google account picker opens, user signs in, profile created |
| T5 | Browse Products | Open Home screen | Products load from Supabase with names and prices |
| T6 | Category Filter | Tap a category chip in Search | Product list filters to that category |
| T7 | Pharmacy List | Open Search → Pharmacies tab | 4 partner pharmacies shown with distance labels |
| T8 | Pharmacy Detail | Tap a pharmacy card | Only that pharmacy's products shown at its specific prices |
| T9 | Product Detail | Tap a product | "Available At" shows real pharmacies carrying it, sorted cheapest first |
| T10 | GPS Location | Open Home screen (location permitted) | Header shows real city name (e.g. "Accra, Ghana") |
| T11 | Distance | View pharmacy cards | Distance from user shown (e.g. "12.3 km") |
| T12 | Directions | Tap Directions on pharmacy detail | Google Maps opens with navigation to pharmacy coordinates |
| T13 | Add to Cart | Tap Add on a product | Product added to cart, cart badge increments |
| T14 | Place Order | Complete checkout with address | Order created with unique invoice number, "Order Placed!" notification fires |
| T15 | Order History | Open Orders tab | All previous orders shown with status badges |
| T16 | Upload Prescription | Upload a prescription image | Image uploaded to Supabase Storage, appears in Prescriptions screen |
| T17 | Notification — Order | Update order status in Supabase DB | In-app notification banner fires with correct status message |
| T18 | Notification — Prescription | Update prescription status in Supabase DB | In-app notification banner fires |
| T19 | Notifications Screen | Open Notifications | Real notification history shown with unread dots |
| T20 | Pull to Refresh | Pull down on Search screen | Pharmacies and products re-fetched from Supabase |
| T21 | Logout | Tap Logout in Profile | Session cleared, user returned to Login screen |
| T22 | Data Persistence | Reinstall app and log in | Cart, orders, prescriptions all restored from Supabase |
| T23 | Profile Photo | Tap avatar on Profile screen, select image from gallery | Photo uploaded to Supabase Storage `avatars` bucket, displayed immediately in profile header |
| T24 | Edit Profile | Tap "Edit Profile", change name/contact/city, tap Save | Profile updated in Supabase, new values reflected instantly in UI |
| T25 | Order Timeline | Open any order detail | 5-step timeline shows current status highlighted, completed steps in green, upcoming steps greyed out |

---

## Activity 5: Pending & Planned Features

The following features are planned but not yet implemented:

| Feature | Description |
|---|---|
| ~~Payment Integration~~ | ~~Paystack or MTN Mobile Money for Ghana~~ — **Implemented** via `flutter_paystack_plus`. Card payments (Visa, Mastercard, bank transfer) + Cash on Delivery option. |
| Background Push Notifications | FCM integration for notifications when app is fully closed |
| ~~Pharmacy Dashboard~~ | ~~A separate interface for pharmacy staff~~ — **Implemented**. 3-tab NavigationBar (Orders, Inventory, Profile). Orders tab shows all orders with tap-to-update status picker. Inventory tab shows per-pharmacy products with stock editing and availability toggle. |
| ~~Order Tracking Timeline~~ | ~~Visual status timeline on order detail~~ — **Implemented** |
| App Store Submission | Change application ID from `com.example.pharmavault_app`, generate production signing keystore, submit to Google Play |

---

## Technology Stack Summary

| Category | Technology |
|---|---|
| Mobile Framework | Flutter 3.x (Dart 3.x) |
| State Management | Provider (7 providers) |
| Backend / Database | Supabase (PostgreSQL + Auth + Realtime + Storage) |
| Authentication | Supabase Auth (email/password + Google OAuth) |
| Location | Geolocator + Geocoding |
| Notifications | flutter_local_notifications + Supabase Realtime |
| Image Loading | cached_network_image |
| Navigation | Named routes + NavigationBar (Material 3) |
| Platform | Android (min API 23, target API 34) |

---

## Repository

GitHub: `https://github.com/Rose-Alice18/PharmaVault-Mobile-App`

---

*PharmaVault — Your Digital Pharmacy Companion*
