import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:kisan_unnati/screens/home/home_screen.dart';
import 'package:kisan_unnati/screens/schemes/government_schemes_screen.dart';
import 'package:kisan_unnati/screens/ecommerce/screens/ecommerce_hub.dart';
import 'package:kisan_unnati/screens/profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // List of screens for the navigation
  final List<Widget> _screens = [
    const HomeScreen(),
     GovernmentSchemesScreen(), // Placeholder
    const EcommerceHub(userName: "Farmer", userRole: "Kisan"),
    const ProfileScreen(),            // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cardWhite,
          selectedItemColor: AppColors.darkGreen,
          unselectedItemColor: AppColors.textGrey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Schemes'),
            BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}