import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_prescriptions_screen.dart';
import 'pharmacy_inventory_screen.dart';
import 'pharmacy_profile_screen.dart';

class PharmacyMainScreen extends StatefulWidget {
  const PharmacyMainScreen({super.key});

  @override
  State<PharmacyMainScreen> createState() => _PharmacyMainScreenState();
}

class _PharmacyMainScreenState extends State<PharmacyMainScreen> {
  int _currentIndex = 0;

  final _screens = const [
    PharmacyOrdersScreen(),
    PharmacyPrescriptionsScreen(),
    PharmacyInventoryScreen(),
    PharmacyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primaryLight,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon:         Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label:        'Orders',
          ),
          NavigationDestination(
            icon:         Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description_rounded),
            label:        'Prescriptions',
          ),
          NavigationDestination(
            icon:         Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label:        'Inventory',
          ),
          NavigationDestination(
            icon:         Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store_rounded),
            label:        'Profile',
          ),
        ],
      ),
    );
  }
}
