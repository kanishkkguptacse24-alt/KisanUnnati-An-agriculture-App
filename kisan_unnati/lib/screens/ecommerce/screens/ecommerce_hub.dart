import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart'; // 🔥 Added your custom theme!
import 'marketplace_page.dart';
import 'add_product_page.dart';

class EcommerceHub extends StatelessWidget {
  final String userName;
  final String userRole;

  const EcommerceHub({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Digital Mandi", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen, // Updated to brand color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        color: AppColors.backgroundGreen, // Updated to brand background
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $userName", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkGreen)), // Updated
            const SizedBox(height: 8),
            const Text("What would you like to do today?", style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),

            _buildActionCard(
              context,
              title: "Browse Market & Live Bids",
              subtitle: "Buy crops, bid on auctions, or rent equipment.",
              icon: Icons.storefront,
              color: AppColors.primaryGreen, // Swapped from generic blue to your primary green
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarketplacePage(userRole: userRole),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            _buildActionCard(
              context,
              title: userRole == 'Kisan' ? "List Crop for Sale" : "List Equipment/Inventory",
              subtitle: userRole == 'Kisan'
                  ? "Sell your harvest directly to buyers."
                  : "List machinery for rent or seeds for sale.",
              icon: Icons.add_business,
              color: AppColors.darkGreen, // Swapped from generic green to your dark green
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductPage(
                      userName: userName,
                      userRole: userRole,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}