import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:kisan_unnati/screens/profile/profile_screen.dart';
import 'package:kisan_unnati/screens/ecommerce/screens/ecommerce_hub.dart';

class BuyerDashboardScreen extends StatefulWidget {
  final String role; // We pass the role so you know if it's a Vyapari or Grahak

  const BuyerDashboardScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen> {
  int _currentIndex = 0;

  // List of screens for the navigation (Home and Schemes removed!)
  late final List<Widget> _screens = [
    const EcommerceHub(userName: "Buyer", userRole: "Vyapari"),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kisaan Unnati - ${widget.role}', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Hides the back button since it's a home screen
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
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
          backgroundColor: Colors.white, // Using standard white to match your theme
          selectedItemColor: AppColors.darkGreen,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Market'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}