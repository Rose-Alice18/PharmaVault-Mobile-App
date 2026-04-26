# ASHESI UNIVERSITY
## PharmaVault
### CS 443: MOBILE DEVELOPMENT

**Roseline Dzidzeme Tsatsu**

Lecturer: Mr. David A. Sampah

April 2026

---

# PharmaVault - Mobile Application Development Report

---

## Activity 1: Planning, Case Scenario and Contract

### 1.1. Background Information

Access to medicines in Ghana and across sub-Saharan Africa is fragmented. Patients often visit multiple pharmacies looking for a specific drug, compare prices verbally, or rely on word-of-mouth to find nearby pharmacies with stock. There is no centralised, real-time digital channel connecting patients to verified pharmacies, their inventories, and their pricing.

PharmaVault was conceived as a direct solution to this problem. It is a mobile application built for patients and healthcare consumers in Ghana that allows them to browse medicines, compare prices across partner pharmacies, upload prescriptions for fulfillment, add medicines to a cart, and place delivery orders, all from a single app. Partner pharmacies are onboarded through an in-app registration and verification flow, manage their own product listings and pricing through a dedicated pharmacy dashboard, and fulfill customer orders through their own portal. A superadmin account can approve or reject pharmacy applications directly from within the app.

The target organisation is any pharmacy chain, independent pharmacy, or patient-facing health service operating in Ghana. The application is designed for individual patient use and for pharmacy staff. Its principal purpose is to reduce the time and cost of accessing medicines by making pharmacy inventory and pricing transparent and delivery-enabled.

---

### 1.2. Target Market

PharmaVault is designed to serve the following user segments:

- Individual patients and healthcare consumers in Ghana
- Patients managing chronic conditions such as diabetes, hypertension, and malaria who need regular medicine refills
- Caregivers purchasing medicines on behalf of family members
- Patients in urban and peri-urban areas with limited mobility
- Partner pharmacies seeking a digital storefront and order management channel
- Pharmacy staff managing inventory, orders, and prescription fulfillment

---

### 1.3. Principal Services the App Provides

The table below summarises the principal services that PharmaVault provides to its users.

| Service |
|---|
| Browse medicines by category, brand, or keyword search |
| Voice-to-text medicine search using the device microphone |
| View real-time pharmacy pricing and stock levels per product |
| Compare prices across multiple pharmacies for the same medicine |
| View partner pharmacy profiles with location, contact, and operating hours |
| GPS-based distance display from user to each pharmacy |
| Save favourite pharmacies as bookmarks for quick access |
| Upload prescriptions for pharmacist review and fulfillment |
| Add medicines to a cart and place delivery orders |
| Pay for orders via Paystack card payment or Cash on Delivery |
| Track order status in real-time: Pending, Confirmed, Processing, Dispatched, Delivered |
| Receive in-app push notifications on order and prescription status changes |
| Manage profile, saved delivery addresses, and contact information |
| Secure authentication via email and password or Google Sign-In |
| Reset password via email link |
| Toggle dark mode from the profile screen |
| Pharmacy staff: manage incoming orders, update order statuses |
| Pharmacy staff: manage inventory with stock and price editing |
| Pharmacy staff: review and verify customer prescriptions |
| Admin: approve or reject pharmacy registration applications from within the app |

---

### 1.4. Functional and Non-Functional Requirements

#### 1.4.1. Functional Requirements

The functional requirements define the specific behaviours the application must support. The table below lists all functional requirements for PharmaVault.

| Functional Requirement |
|---|
| The app shall allow a user to create a Customer or Pharmacy account |
| Pharmacy accounts shall require admin approval before accessing the pharmacy dashboard |
| The app shall support Google Sign-In as an authentication option |
| The app shall allow users to reset their password via an email link |
| The app shall display a browsable, searchable catalogue of medicines |
| The app shall support voice-to-text input in the medicine search bar |
| The app shall show which pharmacies carry each medicine and at what price |
| The app shall allow users to filter medicines by category |
| The app shall display partner pharmacies with name, city, rating, and distance from user |
| The app shall allow users to bookmark and unbookmark pharmacies |
| The app shall allow users to add medicines to a cart and adjust quantities |
| The app shall allow users to place orders with a delivery address and contact |
| The app shall support Paystack card payment and Cash on Delivery at checkout |
| The app shall generate a unique invoice number for each order |
| The app shall allow users to view their order history and order details |
| The app shall allow users to copy their order and prescription reference numbers to clipboard |
| The app shall allow users to upload a prescription image for pharmacy review |
| The app shall send in-app push notifications when order status changes |
| The app shall send in-app push notifications when prescription status is updated |
| The app shall display the user's real GPS location in the home screen header |
| The app shall open Google Maps for directions to a selected pharmacy |
| The app shall allow users to update their profile name, contact, and city from a validated Ghana cities list |
| The app shall support a dark mode toggled from the Profile screen |
| The app shall persist notification and privacy settings across sessions |
| The app shall allow pharmacies to view and update order statuses from their dashboard |
| The app shall allow pharmacies to manage their product inventory including stock, price, and availability |
| The app shall allow pharmacies to verify or reject prescription submissions |
| The app shall allow the superadmin to approve or reject pharmacy applications from within the app |
| The app shall persist all data to Supabase across reinstalls and device changes |

#### 1.4.2. Non-Functional Requirements

The non-functional requirements define the quality and operational constraints the application must satisfy.

| Non-Functional Requirement |
|---|
| All data storage and authentication must be handled by Supabase with no separate backend server |
| Authentication must be secure, and passwords must never be stored in plain text |
| User data must be isolated through Row Level Security, ensuring users can only access their own cart, orders, and prescriptions |
| The app must respond within 2 seconds for all local and cached operations |
| The app must work on Android 8.0 (API 26) and above |
| The UI must be usable on screen sizes from 5 to 7 inches |
| The app must gracefully handle no-internet conditions with appropriate error messages |
| City input must be restricted to a validated dropdown of Ghanaian cities with no free-text entry permitted |

---

### 1.5. Local Resources Used

PharmaVault makes direct use of on-device hardware and operating system resources to deliver its core functionality. Each resource requires an explicit Android runtime permission and is accessed through a dedicated Flutter package. The table below documents each local resource, the package used, and its purpose in the application.

| Resource | Package Used | Usage in PharmaVault |
|---|---|---|
| GPS / Location | geolocator ^13.0.2 | Getting the user's real-time coordinates for city display and pharmacy distance |
| Reverse Geocoding | geocoding ^3.0.0 | Converting GPS coordinates to a human-readable city name |
| Camera / Gallery | image_picker ^1.1.2 | Capturing or selecting prescription images and profile photos for upload |
| Push Notifications | flutter_local_notifications ^18.0.1 | Displaying order and prescription status update banners |
| Microphone / Speech | speech_to_text ^7.0.0 | Voice-to-text input in the medicine search bar |
| Maps / Directions | url_launcher ^6.3.1 | Opening Google Maps with navigation to a selected pharmacy; tel: and mailto: links in Help & Support |
| Network Images | cached_network_image ^3.4.1 | Loading and caching product and pharmacy images from Supabase Storage |
| Clipboard | flutter/services.dart (built-in) | Copying order and prescription reference numbers to clipboard with haptic feedback |

#### 1.5.1. Required Android Permissions

The table below lists the Android permissions declared in AndroidManifest.xml and the purpose of each permission.

| Permission | Purpose |
|---|---|
| INTERNET | All Supabase API calls, image loading, and real-time subscriptions |
| ACCESS_FINE_LOCATION | Precise GPS coordinates for distance-to-pharmacy calculation |
| ACCESS_COARSE_LOCATION | Fallback coarse location for city name display |
| POST_NOTIFICATIONS | Displaying order and prescription update notification banners on Android 13 and above |
| READ_MEDIA_IMAGES | Gallery access for selecting prescription photos |
| READ_EXTERNAL_STORAGE | Legacy gallery access for Android 12 and below |
| CAMERA | Capturing prescription photos directly from the app |
| RECORD_AUDIO | Microphone access for voice-to-text search |

---

## Activity 2: Prototyping, Specification, Architecture and Design

### 2.1. Application Overview

PharmaVault follows a two-layer client-cloud architecture. The Flutter mobile app acts as the client. Supabase provides authentication, a PostgreSQL cloud database, real-time subscriptions, and file storage, eliminating the need for a separate backend server. All business logic runs inside Flutter providers and Supabase Row Level Security policies.

The app supports three distinct user roles: Customer (the patient-facing experience), Pharmacy (a dedicated portal for pharmacy staff), and Admin/Superadmin (a single privileged account identified by a hardcoded UUID for approving pharmacy registrations). Each role routes to a completely separate screen stack on login.

---

### 2.2. High-Level Architecture / Communication Flow

PharmaVault is built on a two-layer architecture. The Flutter mobile app acts as the client and communicates with Supabase directly using the Supabase Flutter SDK over REST and Realtime protocols. The diagram below illustrates how these two layers interact during a typical session.

[IMAGE PLACEHOLDER]

Fig 1: PharmaVault System Architecture Diagram

---

### 2.3. Three-Layer Architecture

The internal architecture of PharmaVault is organised into three distinct layers. The table below describes each layer, its responsibilities, and the key technologies used.

| Layer | Responsibility | Key Technologies |
|---|---|---|
| Presentation Layer | All UI screens, widgets, navigation flows, and user input handling | Flutter Widgets, Material 3, NavigationBar, CustomScrollView |
| Logic Layer | State management, Supabase queries, GPS fetching, notification triggering, cart operations, order creation, and theme management | Provider pattern with AuthProvider, ProductProvider, CartProvider, OrderProvider, LocationProvider, NotificationProvider, PrescriptionProvider, and ThemeProvider |
| Data Layer | Data models, Supabase reads and writes, Realtime subscriptions, SharedPreferences, and local file handling | supabase_flutter, Dart model classes, shared_preferences |

---

### 2.4. Key Modules

The application is divided into functional modules. The table below describes each module and its role within PharmaVault.

| Module | Description |
|---|---|
| Authentication | Email and password signup and login with password strength meter and deferred validation, Google Sign-In, password reset via email link, Customer vs Pharmacy registration toggle with pharmacy pending and approval flow |
| Home Screen | Greeting with real GPS city, voice-enabled search bar, prescription upload banner, category chips, horizontal product cards with Rx badges, and pharmacy cards with distance labels |
| Search Screen | Tabbed Medicines and Pharmacies search with live filtering, voice-to-text input, category filter chips, result count, and pull-to-refresh |
| Product Detail | Full product information, dosage, side effects, and an Available At section showing real pharmacies with per-pharmacy pricing and stock sorted cheapest first |
| Pharmacy Detail | Pharmacy header with rating and hours, list of pharmacy-specific products with prices and stock, bookmark toggle, Directions button opening Google Maps, and Call button |
| Cart | Item listing with quantity controls, total calculation, and persistent cart state via Supabase |
| Checkout and Orders | Delivery address form, Paystack card payment or Cash on Delivery, order placement with invoice generation, order history, and order detail with itemised breakdown and copyable reference number |
| Prescriptions | Upload prescription photo from camera or gallery to Supabase Storage, view upload history and status, copyable reference number |
| Notifications | In-app notification history from Supabase Realtime, unread count badge, and mark-all-read functionality |
| Profile | View and update name, contact, and city from a Ghana cities dropdown; avatar upload; dark mode toggle; saved addresses CRUD; saved pharmacy bookmarks; logout |
| Settings | Notification and privacy toggles all persisted via SharedPreferences |
| Help and Support | Working call and email buttons via url_launcher, expandable FAQ, and live chat placeholder |
| Pharmacy Portal | Orders management with search, status filter chips, and status picker; inventory management with availability toggle and stock and price editing; prescription review with image viewer and verify or reject actions; pharmacy profile editor |
| Admin Panel | Pending pharmacy applications list with approve and reject actions and confirmation dialogs, accessible only to the superadmin account |
| Location Service | GPS permission flow, reverse geocoding to city name, and distance calculation to pharmacies |
| Theme | Dark and light mode toggle from the profile screen, persisted with SharedPreferences, applied via ThemeMode to MaterialApp |
| Pharmacy-Product Linking | The pharmacy_products table links pharmacies to their products with per-pharmacy pricing and stock |

---

### 2.5. Users and Use Case Diagram

PharmaVault has three actors: the Customer who is the patient using the app, the Pharmacy which is a partner pharmacy with their own dedicated dashboard, and the Admin who is the superadmin account that approves pharmacy applications from within the app. The diagram below maps all interactions to their corresponding use cases.

[IMAGE PLACEHOLDER]

Fig 2: PharmaVault Use Case Diagram

```
Customer
├── Register / Login / Google Sign-In / Forgot Password
├── Browse Medicines
│   ├── Filter by Category
│   ├── Search by Name or Brand (including voice search)
│   └── View Product Detail → See Available Pharmacies + Prices
├── Browse Pharmacies
│   ├── View Distance from Location
│   ├── Bookmark / Unbookmark Pharmacies
│   └── View Pharmacy Detail → Get Directions / Call
├── Cart → Checkout (Paystack or Cash on Delivery)
├── Orders → View Order Detail (copy invoice number)
├── Upload Prescription → Track Status (copy reference)
├── Receive Notifications
└── Manage Profile
    ├── Update Name / Contact / City
    ├── Upload Profile Photo
    ├── Manage Saved Addresses
    ├── View Saved Pharmacies
    └── Toggle Dark Mode

Pharmacy
├── Register as Pharmacy (with license number)
├── Await Admin Approval
├── Login → Pharmacy Dashboard
│   ├── Manage Orders (search, filter, update status)
│   ├── Manage Prescriptions (view image, verify or reject)
│   ├── Manage Inventory (toggle availability, edit stock and price)
│   └── Edit Pharmacy Profile / Sign Out

Admin
├── Login as Customer
└── Access Admin Panel from Profile Tab
    ├── View Pending Pharmacy Applications
    ├── Approve → customer_type set to pharmacy
    └── Reject → customer_type set to pharmacy_rejected
```

---

### 2.6. Application Prototype (Figma)

A high-fidelity prototype of the PharmaVault application was designed using Figma, demonstrating the interaction flow between key screens including authentication, home, search, product detail, pharmacy detail, cart, checkout, prescriptions, notifications, and profile screens. The prototype can be accessed at:

https://github.com/Rose-Alice18/PharmaVault-Mobile-App

[IMAGE PLACEHOLDER]

Fig 3: PharmaVault Figma Prototype Screens

---

### 2.7. Database Schema (Supabase PostgreSQL)

PharmaVault uses ten tables in Supabase PostgreSQL. Row Level Security is enabled on all tables to ensure that each user can only access their own data.

**Table: profiles**

The profiles table stores information for customer, pharmacy, and pending pharmacy accounts.

| Field | Type | Description |
|---|---|---|
| id | UUID (PK, FK to auth.users) | User identifier |
| customer_name | TEXT | Full name or pharmacy name |
| customer_email | TEXT | Email address |
| customer_type | TEXT | customer, pharmacy, pharmacy_pending, or pharmacy_rejected |
| customer_contact | TEXT | Phone number |
| customer_city | TEXT | City |
| customer_image | TEXT | Profile image URL |
| license_number | TEXT | Pharmacy license or registration number (pharmacy accounts only) |
| lat | DOUBLE PRECISION | GPS latitude (pharmacies only) |
| lng | DOUBLE PRECISION | GPS longitude (pharmacies only) |

**Table: categories**

| Field | Type | Description |
|---|---|---|
| cat_id | SERIAL (PK) | Category ID |
| cat_name | TEXT | Category name such as Pain Relief or Antibiotics |

**Table: brands**

| Field | Type | Description |
|---|---|---|
| brand_id | SERIAL (PK) | Brand ID |
| brand_name | TEXT | Brand name such as Panadol or Ampiclox |

**Table: products**

| Field | Type | Description |
|---|---|---|
| product_id | SERIAL (PK) | Product ID |
| product_title | TEXT | Medicine name and dosage |
| product_description | TEXT | Description |
| product_price | DECIMAL(10,2) | Base price in GHS |
| product_stock | INTEGER | Global stock count |
| product_image | TEXT | Image URL |
| product_keywords | TEXT | Tags including rx for prescription-only products |
| cat_id | INTEGER (FK to categories) | Category |
| brand_id | INTEGER (FK to brands) | Brand |

**Table: pharmacy_products**

| Field | Type | Description |
|---|---|---|
| id | SERIAL (PK) | Row ID |
| pharmacy_id | UUID (FK to profiles) | Pharmacy |
| product_id | INTEGER (FK to products) | Product |
| pharmacy_price | DECIMAL(10,2) | This pharmacy's price for this product |
| stock_count | INTEGER | This pharmacy's current stock |
| is_available | BOOLEAN | Whether the product is currently listed |

**Table: cart**

| Field | Type | Description |
|---|---|---|
| cart_id | SERIAL (PK) | Cart row ID |
| c_id | UUID (FK to profiles) | Customer |
| p_id | INTEGER (FK to products) | Product |
| cart_qty | INTEGER | Quantity |

**Table: orders**

| Field | Type | Description |
|---|---|---|
| order_id | SERIAL (PK) | Order ID |
| invoice_no | TEXT | Unique invoice number formatted as INV-YEAR-MILLISECONDS |
| c_id | UUID (FK to profiles) | Customer |
| order_total | DECIMAL(10,2) | Total amount in GHS |
| order_status | TEXT | pending, confirmed, processing, dispatched, delivered, or cancelled |
| is_paid | BOOLEAN | Payment status |
| payment_amount | DECIMAL(10,2) | Amount paid |
| delivery_notes | JSONB | Address, city, and contact details |
| order_date | TIMESTAMPTZ | Timestamp of order placement |

**Table: order_items**

| Field | Type | Description |
|---|---|---|
| item_id | SERIAL (PK) | Item ID |
| order_id | INTEGER (FK to orders) | Parent order |
| p_id | INTEGER (FK to products) | Product |
| item_qty | INTEGER | Quantity ordered |
| item_price | DECIMAL(10,2) | Price at time of order |

**Table: prescriptions**

| Field | Type | Description |
|---|---|---|
| prescription_id | SERIAL (PK) | Prescription ID |
| c_id | UUID (FK to profiles) | Customer |
| prescription_number | TEXT | Unique reference number |
| prescription_image | TEXT | Supabase Storage URL |
| status | TEXT | pending, verified, rejected, or expired |
| doctor_name | TEXT | Prescribing doctor's name |
| doctor_license | TEXT | Doctor's license number |
| issue_date | DATE | Date the prescription was issued |
| expiry_date | DATE | Prescription expiry date |
| prescription_notes | TEXT | Patient or pharmacist notes |
| allow_pharmacy_access | BOOLEAN | Whether pharmacies can view this prescription |
| uploaded_at | TIMESTAMPTZ | Upload timestamp |

[IMAGE PLACEHOLDER]

Fig 4: PharmaVault Entity Relationship Diagram

---

## Activity 3: Implementation

### 3.1. Overview

PharmaVault is built entirely on Flutter and Supabase with no separate backend server. All state is managed via the Provider pattern across eight providers. Supabase handles authentication, all database reads and writes, real-time order and prescription status subscriptions, and file storage for prescription images and profile photos. The app uses the device GPS for real-time location, speech_to_text for voice search, flutter_local_notifications for in-app notification banners, and flutter_paystack_plus for card payments.

---

### 3.2. Tools, Libraries, Frameworks, and Services

#### 3.2.1. Mobile Frontend

| Tool / Library | Version | Purpose |
|---|---|---|
| Flutter | 3.x | Cross-platform mobile UI framework |
| Dart | 3.x | Programming language |
| provider | ^6.1.2 | State management across 8 providers |
| supabase_flutter | ^2.8.4 | Auth, database, real-time, and storage client |
| google_sign_in | ^6.2.1 | Native Google OAuth sign-in |
| geolocator | ^13.0.2 | GPS coordinates for location and distance |
| geocoding | ^3.0.0 | Reverse geocoding coordinates to city name |
| url_launcher | ^6.3.1 | Opening Google Maps, tel: and mailto: links |
| cached_network_image | ^3.4.1 | Efficient network image loading and caching |
| image_picker | ^1.1.2 | Camera and gallery for prescription and profile photos |
| speech_to_text | ^7.0.0 | Voice-to-text input in the medicine search bar |
| flutter_local_notifications | ^18.0.1 | In-app notification banners |
| flutter_paystack_plus | ^2.0.0 | Paystack card payment at checkout |
| intl | ^0.19.0 | Date, time, and currency formatting |
| shared_preferences | ^2.3.3 | Dark mode, notification settings, saved addresses, and pharmacy bookmarks |
| cupertino_icons | ^1.0.8 | iOS-style icons |

#### 3.2.2. Backend and Cloud Services

| Service | Purpose |
|---|---|
| Supabase (PostgreSQL) | Cloud-hosted relational database with 10 tables storing all application data |
| Supabase Auth | Email and password authentication, Google OAuth, and password reset emails |
| Supabase Realtime | Live subscriptions on the orders and prescriptions tables for notification triggering |
| Supabase Storage | prescriptions bucket for prescription images and avatars bucket for profile photos |
| Google Cloud Console | Web OAuth client ID for Google Sign-In via serverClientId |

---

### 3.3. Implementation Description

#### Authentication Flow

The authentication system handles multiple distinct flows as described below.

**Email and password registration:** A Customer or Pharmacy toggle at the top of the registration form determines the account type. Pharmacy mode adds a license number field and a warning banner explaining the verification requirement. Password fields include a four-bar strength meter that scores uppercase, lowercase, digit, special character, and length criteria, and a real-time confirm password mismatch indicator. Form validation is deferred so errors only appear after the first submit attempt. On submit, Supabase.auth.signUp() creates the auth user and a profile row is upserted with customer_type set to customer or pharmacy_pending. Pharmacy accounts are routed to PharmacyPendingScreen while customer accounts go directly to the main screen.

**Email and password login:** signInWithPassword() is called. Routing checks customer_type: pharmacy_pending routes to PharmacyPendingScreen, pharmacy routes to PharmacyMainScreen, and all other accounts route to MainScreen.

**Google Sign-In:** GoogleSignIn(serverClientId: webClientId).signIn() retrieves an ID token passed to supabase.auth.signInWithIdToken(). No google-services.json is required.

**Password reset:** ForgotPasswordScreen calls auth.resetPasswordForEmail(). On success, a confirmation view showing the email address is displayed with guidance to check spam.

#### Pharmacy Registration and Approval Flow

The pharmacy onboarding flow works as follows. The user selects the Pharmacy tab on the register screen and provides pharmacy name, email, password, contact, city, and license number. On submit the profile is created with customer_type set to pharmacy_pending. The user is shown PharmacyPendingScreen with a Check Again button that re-fetches their profile status. The superadmin sees an Admin Panel tile in their Profile tab. The Admin Panel lists all pharmacy_pending profiles with their details. Approving sets customer_type to pharmacy and rejecting sets it to pharmacy_rejected. The pharmacy user taps Check Again and is routed to PharmacyMainScreen on approval.

#### Voice Search Flow

The user taps the microphone icon in the search bar. The speech_to_text package initialises the device's built-in speech recognition engine and requests microphone permission. A Listening indicator appears below the search bar and the icon changes to a red stop button. Recognised text is placed into the search field automatically. Listening stops after 15 seconds or when the user taps the stop button.

#### Product and Pharmacy Data Flow

Products are fetched from the products table with joined brands and categories data. Pharmacies are fetched from the profiles table filtered by customer_type equal to pharmacy. The pharmacy_products table links each pharmacy to its own product subset with pharmacy-specific pricing and stock counts. Product detail queries pharmacy_products joined with profiles to show which pharmacies carry that medicine and at what price, ordered cheapest first.

#### Cart and Order Flow

The cart and order flow follows the steps described below.

- The user taps Add to Cart and a cart row is inserted or the quantity is incremented in Supabase
- The Cart screen fetches all cart rows with product joins
- The Checkout screen collects the delivery address, city, contact, and payment method
- For Paystack payment, flutter_paystack_plus launches a secure card payment sheet and sets is_paid to true on success
- For Cash on Delivery, the order is placed immediately with is_paid set to false
- OrderProvider.createOrder() generates an invoice number, inserts the order and order_items rows, clears the cart, and fires a local notification confirming order placement

#### GPS and Location Flow

Location is resolved at app startup through the following steps.

- LocationProvider.fetchLocation() is called at app startup via a cascade in main.dart
- The app checks whether the location service is enabled and requests permission if needed
- On grant, Geolocator.getCurrentPosition() retrieves coordinates and placemarkFromCoordinates() reverse geocodes them to a city name
- The home screen header displays the real city name and falls back to Accra, Ghana if permission is denied
- Pharmacy cards display distance using Geolocator.distanceBetween()
- The Directions button launches the Google Maps navigation URL via url_launcher

#### Notification Flow

In-app notifications are delivered through the following pipeline.

- NotificationService.initialize() runs at app startup, creates the Android notification channel with high importance, and requests POST_NOTIFICATIONS permission on Android 13 and above
- After login or registration, NotificationProvider.subscribe(userId) opens two Supabase Realtime channels watching orders and prescriptions table UPDATE events filtered to the authenticated user's ID
- Order placement triggers a local notification immediately
- The Notifications screen reads from NotificationProvider.items showing a real-time list with unread indicators, timestamps, and a mark-all-read option

#### Dark Mode Flow

ThemeProvider is created at app startup and reads the saved preference from SharedPreferences. MaterialApp is wrapped in a Consumer widget and uses themeMode from the provider. Both a light and dark ThemeData are defined with matching colour schemes, scaffold backgrounds, card colours, input decoration themes, and dialog colours. The Profile screen has a Dark Mode switch tile that calls ThemeProvider.toggle() and the preference is immediately saved to SharedPreferences.

[IMAGE PLACEHOLDER]

Fig 5: PharmaVault Notification and Order Processing Flow

---

### 3.4. Key Design Decisions and Challenges

| Decision / Challenge | Resolution |
|---|---|
| No separate backend server | PharmaVault runs entirely on Supabase. All queries and business logic are expressed as Supabase client calls with PostgreSQL-level RLS policies enforcing data isolation. This eliminated deployment complexity and infrastructure cost. |
| Pharmacy-product linking table | The pharmacy_products table was introduced after initial development showed that the pharmacy detail screen was incorrectly showing all products to all pharmacies. The linking table gives each pharmacy its own product subset, price, and stock count. |
| upsert for profile creation | Supabase's on_auth_user_created trigger creates a partial profile row immediately when a user signs up. The initial insert call was failing with a primary key conflict. Changing to upsert resolved this silently. |
| Google Sign-In without google-services.json | The google_sign_in package supports a serverClientId parameter that allows Google OAuth to function using only the web client ID. The Google Services Gradle plugin is not needed. This was discovered after a build failure caused by attempting to add the plugin. |
| RLS blocking profile insert on signup | When Supabase email confirmation is enabled, auth.uid() returns null immediately after signUp(), causing the RLS policy to block the profile insert. Resolved by disabling email confirmation for development. |
| FK constraint on pharmacy seed data | The profiles table has a foreign key referencing auth.users. Inserting seed pharmacy profiles with generated UUIDs failed because those UUIDs had no corresponding auth users. Resolved by dropping the FK constraint before seeding. |
| Supabase Realtime for notifications | Rather than polling for order status changes, Supabase Realtime channels provide instant push-style updates while the app is open. The NotificationProvider opens one channel per table filtered to the authenticated user's ID. |
| setState called during build crash | The home screen's didChangeDependencies() was calling ProductProvider.fetchProducts() synchronously, which immediately called notifyListeners() before any async work, triggering a rebuild during Flutter's build phase. Fixed by wrapping provider calls in WidgetsBinding.instance.addPostFrameCallback() to defer until after the current frame completes. |
| speech_to_text build failure on Android | The speech_to_text package at version 6.6.2 caused an Android build failure with an unresolved reference to Registrar due to a breaking API change. Resolved by upgrading to version 7.0.0. |
| Saved pharmacies fetching all records | The initial saved pharmacies screen fetched all pharmacy profiles from Supabase. This was redesigned so bookmarks are stored locally in SharedPreferences as a list of IDs using PharmacyBookmarkService, and only those specific profiles are fetched using inFilter(). |
| City and country validation | Free-text city input allowed invalid entries. Both the registration screen and profile edit sheet now use a DropdownButtonFormField populated from a curated list of 42 Ghanaian cities. Country is hardcoded to Ghana with a locked display field since the app is Ghana-specific. |
| Pharmacy approval without database access | Initially, promoting a pharmacy user required editing customer_type directly in the Supabase dashboard. An in-app Admin Panel was built so the superadmin can approve or reject applications within the app without any direct database access. |

---

### 3.5. Security Considerations

| Area | Implementation |
|---|---|
| Credentials | The Supabase anon publishable key is safe to expose client-side by design. The service role key is never included in the Flutter application. |
| Row Level Security | All 10 tables have RLS enabled. Customers can only read and write their own cart, orders, and prescriptions. Products and pharmacy_products are publicly readable with SELECT only. |
| Pharmacy data isolation | Pharmacy profiles are readable by all users, which is required for the browse feature, but only the pharmacy's own row is updatable. |
| Admin access | The superadmin is identified by a hardcoded UUID check in the Flutter app. The Admin Panel only calls standard Supabase update operations that respect existing RLS policies. |
| Google Sign-In | Uses serverClientId only. No Firebase service account credentials are included in the application. |
| Input validation | All form fields are trimmed and validated client-side before any Supabase call is made. City input is restricted to a curated dropdown. Supabase parameterised queries prevent SQL injection. |
| Image uploads | Prescription images are stored in a private prescriptions bucket. Profile photos go to an avatars bucket. |
| Password strength | Registration enforces a minimum of 8 characters including at least one letter and one number. A visual strength meter encourages stronger passwords. |

---

### 3.6. Screens Implemented

The table below lists all screens implemented in PharmaVault together with a description of each screen's purpose.

**Auth Screens**

| Screen | Description |
|---|---|
| SplashScreen | Animated logo that checks the Supabase session and routes by customer_type to the correct stack |
| LoginScreen | Email and password login with Google Sign-In button and Forgot Password link, with deferred validation |
| RegisterScreen | Customer and Pharmacy toggle, password strength meter, confirm password field, Ghana city dropdown, pharmacy license field |
| ForgotPasswordScreen | Email input form that sends a Supabase password reset link, with a success confirmation view |
| PharmacyPendingScreen | Shown to pharmacy_pending users with a Check Again button that re-fetches status and routes to the dashboard on approval |

**Customer Screens**

| Screen | Description |
|---|---|
| OnboardingScreen | First-time user introduction slides shown once on first install |
| MainScreen | 5-tab NavigationBar shell hosting Home, Search, Cart, Orders, and Profile |
| HomeScreen | GPS city header, voice search bar, prescription upload banner, category chips, product cards with Rx badges, pharmacy cards with distance |
| SearchScreen | Tabbed Medicines and Pharmacies views, voice-to-text input, category filter chips, and pull-to-refresh |
| ProductDetailScreen | Product image, description, dosage, side effects, Available At pharmacies sorted cheapest first, quantity selector, and Add to Cart |
| PharmacyDetailScreen | Pharmacy header with rating, hours, and Open badge, pharmacy-specific products, bookmark toggle, Call and Directions buttons |
| CartScreen | Cart items with quantity controls, subtotal calculation, and checkout button |
| CheckoutScreen | Delivery address form, Paystack card payment or Cash on Delivery, and order confirmation |
| OrdersScreen | Order history with Active and Past tabs, invoice numbers, status badges, and totals |
| OrderDetailScreen | Itemised order breakdown, delivery details, status timeline, and copyable invoice reference |
| UploadPrescriptionScreen | Camera and gallery picker, doctor info form, issue and expiry dates, pharmacy access toggle |
| PrescriptionsScreen | Prescription list with status badges and upload FAB |
| PrescriptionDetailScreen | Image display, prescription metadata, status badge, copyable reference, and re-upload option |
| NotificationsScreen | Real-time notification history from Supabase Realtime with unread dots and mark-all-read |
| ProfileScreen | Avatar with upload, order and prescription stats, dark mode toggle, admin tile for superadmin, and all menu items |
| SettingsScreen | Notification and privacy toggles all persisted with SharedPreferences |
| HelpSupportScreen | Working call and email buttons via url_launcher, expandable FAQ, and live chat placeholder |
| SavedAddressesScreen | Add, edit, and delete delivery addresses with home, office, and other icon types, fully persisted via SharedPreferences |
| SavedPharmaciesScreen | Bookmark-based screen that fetches only user-saved pharmacies from Supabase |

**Pharmacy Screens**

| Screen | Description |
|---|---|
| PharmacyMainScreen | 4-tab NavigationBar shell hosting Orders, Prescriptions, Inventory, and Profile |
| PharmacyOrdersScreen | All orders list with invoice search, status filter chips, pending count badge, and tap to view detail |
| PharmacyOrderDetailScreen | Customer info, delivery address, itemised products, total, and Update Status bottom sheet picker |
| PharmacyInventoryScreen | Product list with availability toggle switch and edit bottom sheet for stock count and price |
| PharmacyPrescriptionsScreen | Prescriptions shared by customers with status filter, image viewer bottom sheet, and verify or reject actions |
| PharmacyProfileScreen | Pharmacy name, city, and contact display with edit profile sheet and sign out |

**Admin Screen**

| Screen | Description |
|---|---|
| AdminPanelScreen | Pending pharmacy applications list with name, email, contact, city, and license details per card, approve and reject actions with confirmation dialogs, and pending count badge in the AppBar |

---

## Activity 4: Testing, Deployment and Presentation

### 4.1. Overview

PharmaVault is deployed entirely on Supabase cloud infrastructure. There is no self-hosted server. The Flutter application is distributed as an Android APK for testing on physical devices. Testing was performed on a Samsung Galaxy A14 (SM-A145F, Android 14).

---

### 4.2. Deployment

#### 4.2.1. Database and Auth

The cloud infrastructure for PharmaVault is hosted on Supabase as described below.

- Hosted on Supabase with managed PostgreSQL, Auth, Storage, and Realtime
- Project URL: https://sbjmzumtejbzwnrbjrdr.supabase.co
- Row Level Security enabled on all 10 tables
- prescriptions and avatars storage buckets created for image uploads
- Realtime enabled on the orders and prescriptions tables

#### 4.2.2. Mobile App

| Item | Details |
|---|---|
| Debug APK | build/app/outputs/flutter-apk/app-debug.apk |
| Release APK | build/app/outputs/flutter-apk/app-release.apk |
| Build Command | flutter build apk --release |
| Min SDK | Android 6.0 (API 23) |
| Target SDK | Android 14 (API 34) |
| Test Device | Samsung Galaxy A14 (SM-A145F, Android 14) |

---

### 4.3. Test Cases

| No. | Feature | Test | Expected Result |
|---|---|---|---|
| T1 | Customer Registration | Register with valid name, email, password, contact, and city | Account created, profile saved to Supabase, user navigated to Home |
| T2 | Pharmacy Registration | Register as Pharmacy with license number | Account created as pharmacy_pending, user routed to PharmacyPendingScreen |
| T3 | Admin Approval | Admin taps Approve on a pending pharmacy application | customer_type set to pharmacy; pharmacy can log in to dashboard |
| T4 | Admin Rejection | Admin taps Reject on a pending pharmacy application | customer_type set to pharmacy_rejected |
| T5 | Login — Customer | Login with correct customer credentials | User routed to MainScreen |
| T6 | Login — Pharmacy | Login with approved pharmacy credentials | User routed to PharmacyMainScreen |
| T7 | Login — Wrong Password | Login with incorrect password | Error snackbar displayed |
| T8 | Forgot Password | Enter email on ForgotPasswordScreen | Reset email sent, success confirmation view shown |
| T9 | Google Sign-In | Tap Continue with Google on a physical device | Google account picker opens, user signs in, profile created |
| T10 | Browse Products | Open Home screen | Products load from Supabase with names and prices |
| T11 | Category Filter | Tap a category chip in Search | Product list filters to that category |
| T12 | Voice Search | Tap microphone icon in search bar | Listening indicator shows, spoken words fill the search field |
| T13 | Pharmacy List | Open Search and navigate to Pharmacies tab | Partner pharmacies shown with distance labels |
| T14 | Pharmacy Detail | Tap a pharmacy card | Only that pharmacy's products shown at its specific prices |
| T15 | Bookmark Pharmacy | Tap bookmark icon on pharmacy detail | Pharmacy saved and appears in Saved Pharmacies screen |
| T16 | Product Detail | Tap a product | Available At section shows real pharmacies sorted cheapest first |
| T17 | GPS Location | Open Home screen with location permitted | Header shows real city name |
| T18 | Distance | View pharmacy cards | Distance from user shown in kilometres |
| T19 | Directions | Tap Directions on pharmacy detail | Google Maps opens with navigation to pharmacy |
| T20 | Add to Cart | Tap Add on a product | Product added to cart and badge increments |
| T21 | Paystack Payment | Complete checkout with card payment | Order created with is_paid true and Order Placed notification fires |
| T22 | Cash on Delivery | Complete checkout with COD | Order created with is_paid false |
| T23 | Order History | Open Orders tab | All previous orders shown with status badges |
| T24 | Copy Reference | Tap copy icon on order or prescription detail AppBar | Reference number copied to clipboard, snackbar confirms |
| T25 | Upload Prescription | Upload a prescription image with doctor details | Image uploaded to Supabase Storage and appears in Prescriptions screen |
| T26 | Notification — Order | Pharmacy updates order status | In-app notification banner fires with correct status |
| T27 | Notification — Prescription | Pharmacy verifies or rejects prescription | In-app notification banner fires |
| T28 | Notifications Screen | Open Notifications | Real notification history shown with unread dots |
| T29 | Pharmacy Orders | Login as pharmacy and open Orders tab | All customer orders listed with invoice, customer name, and total |
| T30 | Update Order Status | Pharmacy taps Update Status on order detail | Status picker opens and selection updates the order in Supabase |
| T31 | Pharmacy Inventory | Open Inventory tab | All pharmacy_products listed with stock, price, and availability |
| T32 | Toggle Availability | Pharmacy taps availability switch on a product | is_available toggled in Supabase; product shown or hidden to customers |
| T33 | Edit Stock and Price | Pharmacy taps edit on an inventory item | Bottom sheet opens and new stock and price are saved to Supabase |
| T34 | Pharmacy Prescriptions | Open Prescriptions tab in pharmacy portal | Prescriptions with allow_pharmacy_access set to true are shown |
| T35 | Verify Prescription | Pharmacy taps Verify on a pending prescription | Status updated to verified and customer is notified |
| T36 | Dark Mode | Toggle Dark Mode switch in Profile | App switches to dark theme instantly and preference is saved across restarts |
| T37 | City Dropdown | Open Register or Edit Profile | City field shows dropdown of 42 Ghana cities and free text is not accepted |
| T38 | Saved Addresses | Add, edit, and delete addresses in Saved Addresses screen | All changes persisted via SharedPreferences across app restarts |
| T39 | Profile Photo | Tap avatar on Profile screen and select image from gallery | Photo uploaded to Supabase Storage avatars bucket and displayed immediately |
| T40 | Edit Profile | Change name, contact, and city and tap Save | Profile updated in Supabase and new values reflected instantly in UI |
| T41 | Pull to Refresh | Pull down on any list screen | Data re-fetched from Supabase |
| T42 | Logout | Tap Sign Out in Profile | Session cleared and user returned to Login screen |
| T43 | Data Persistence | Reinstall app and log in | Cart, orders, and prescriptions all restored from Supabase |

---

## Activity 5: Pending and Planned Features

### 5.1. Overview

The table below documents the features that were planned at the start of the project, their current implementation status, and any remaining work.

| Feature | Status | Notes |
|---|---|---|
| Payment Integration | ✅ Implemented | Paystack card payment and Cash on Delivery via flutter_paystack_plus |
| Pharmacy Dashboard | ✅ Implemented | 4-tab portal covering Orders, Prescriptions, Inventory, and Profile — all fully functional |
| Admin Panel | ✅ Implemented | In-app approve and reject pharmacy applications accessible only to the superadmin account |
| Order Tracking Timeline | ✅ Implemented | Visual step-by-step status timeline in order detail screen |
| Profile Photo Upload | ✅ Implemented | Users can upload a profile photo stored in the Supabase Storage avatars bucket |
| Background Push Notifications | ⏳ Pending | Requires FCM integration and google-services.json. In-app Realtime notifications are working. |
| App Store Submission | ⏳ Pending | Requires changing the application ID from com.example.pharmavault_app, generating a production signing keystore, and submitting to Google Play |

---

## Technology Stack Summary

| Category | Technology |
|---|---|
| Mobile Framework | Flutter 3.x (Dart 3.x) |
| State Management | Provider with 8 providers |
| Backend / Database | Supabase (PostgreSQL, Auth, Realtime, and Storage) |
| Authentication | Supabase Auth with email and password, Google OAuth, and password reset |
| Payment | flutter_paystack_plus (Paystack card payment and Cash on Delivery) |
| Location | Geolocator and Geocoding |
| Voice Input | speech_to_text |
| Notifications | flutter_local_notifications and Supabase Realtime |
| Image Loading | cached_network_image |
| Local Storage | shared_preferences for dark mode, settings, addresses, and bookmarks |
| Navigation | Named routes and NavigationBar (Material 3) |
| Platform | Android, minimum API 23, target API 34 |
| Test Device | Samsung Galaxy A14 (SM-A145F, Android 14) |

---

GitHub: https://github.com/Rose-Alice18/PharmaVault-Mobile-App

YouTube: www.youtube.com/@roselinetsatsu5075

---

*PharmaVault — Your Digital Pharmacy Companion*
