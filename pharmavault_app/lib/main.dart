import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'constants/app_colors.dart';
import 'constants/supabase_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/order_provider.dart';
import 'providers/prescription_provider.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/pharmacy_pending_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/cart/checkout_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/home/product_detail_screen.dart';
import 'screens/main_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/pharmacy_detail_screen.dart';
import 'screens/prescriptions/prescriptions_screen.dart';
import 'screens/prescriptions/upload_prescription_screen.dart';
import 'screens/saved_addresses_screen.dart';
import 'screens/saved_pharmacies_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/pharmacy/pharmacy_main_screen.dart';
import 'screens/pharmacy/pharmacy_order_detail_screen.dart';
import 'screens/prescriptions/prescription_detail_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConstants.projectUrl,
    anonKey: SupabaseConstants.anonKey,
  );

  await NotificationService.initialize();

  runApp(const PharmaVaultApp());
}

class PharmaVaultApp extends StatelessWidget {
  const PharmaVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        // Auth is self-contained — reads Supabase session internally
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => LocationProvider()..fetchLocation(),
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),

        // Data providers no longer need a token passed in —
        // they call Supabase.instance.client directly and read auth.currentUser
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => PrescriptionProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (_, themeProvider, __) => MaterialApp(
          title: 'PharmaVault',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.mode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: AppColors.surface,
              background: AppColors.background,
              error: AppColors.error,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            scaffoldBackgroundColor: AppColors.background,
            cardColor: Colors.white,
            dividerColor: const Color(0xFFD1D5DB),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: AppColors.primary,
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.white,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              labelStyle: const TextStyle(color: Color(0xFF6B7280)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              secondary: AppColors.secondary,
              surface: Color(0xFF111827),
              background: Color(0xFF0B1221),
              error: AppColors.error,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            scaffoldBackgroundColor: const Color(0xFF0B1221),
            cardColor: const Color(0xFF111827),
            dividerColor: const Color(0xFF2E3748),
            dialogTheme: DialogThemeData(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Color(0xFF111827),
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: AppColors.primary,
              contentTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1F2937),
              labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Color(0xFFE2E8F0)),
              bodyMedium: TextStyle(color: Color(0xFFE2E8F0)),
              bodySmall: TextStyle(color: Color(0xFF94A3B8)),
              titleLarge: TextStyle(color: Color(0xFFF1F5F9)),
              titleMedium: TextStyle(color: Color(0xFFF1F5F9)),
              titleSmall: TextStyle(color: Color(0xFFE2E8F0)),
              labelLarge: TextStyle(color: Color(0xFFE2E8F0)),
              labelSmall: TextStyle(color: Color(0xFF94A3B8)),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF111827),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
          ),
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/onboarding': (_) => const OnboardingScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/pharmacy-pending': (_) => const PharmacyPendingScreen(),
            '/admin-panel': (_) => const AdminPanelScreen(),
            '/main': (_) => const MainScreen(),
            '/pharmacy-main': (_) => const PharmacyMainScreen(),
            '/product-detail': (_) => const ProductDetailScreen(),
            '/checkout': (_) => const CheckoutScreen(),
            '/order-detail': (_) => const OrderDetailScreen(),
            '/upload-prescription': (_) => const UploadPrescriptionScreen(),
            '/prescriptions': (_) => const PrescriptionsScreen(),
            '/pharmacy-detail': (_) => const PharmacyDetailScreen(),
            '/notifications': (_) => const NotificationsScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/help-support': (_) => const HelpSupportScreen(),
            '/saved-addresses': (_) => const SavedAddressesScreen(),
            '/saved-pharmacies': (_) => const SavedPharmaciesScreen(),
            '/search': (_) => const SearchScreen(),
            '/pharmacy-order-detail': (_) => const PharmacyOrderDetailScreen(),
            '/prescription-detail': (_) => const PrescriptionDetailScreen(),
          },
        ),
      ),
    );
  }
}
