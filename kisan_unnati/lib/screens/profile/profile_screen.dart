import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:kisan_unnati/auth/auth_service.dart';
import 'package:kisan_unnati/auth/login_screen.dart';
import 'package:kisan_unnati/screens/profile/seller_order_history_screen.dart';
// 🔥 Import all three of our new profile screens!
import 'package:kisan_unnati/screens/profile/my_listings_screen.dart';
import 'package:kisan_unnati/screens/profile/buyer_orders_screen.dart';
import 'package:kisan_unnati/screens/profile/seller_requests_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  // --- Pop-up for About Kisaan Unnati ---
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("About Kisaan Unnati", style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
        content: const Text(
          "Kisaan Unnati is a comprehensive digital ecosystem designed to empower farmers and agricultural traders. "
              "By bridging the gap between traditional farming and modern technology, we provide AI-driven crop insights, "
              "a transparent digital marketplace, and easy access to government schemes.\n\n"
              "Our mission: Empowering agriculture, elevating lives.",
          style: TextStyle(height: 1.5, fontSize: 15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  // --- Pop-up for Support & Help ---
  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Support & Help", style: TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Need help? Reach out to our support team 24/7.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.email, color: AppColors.primaryGreen),
                SizedBox(width: 15),
                Text("support@kisaanunnati.in", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: const [
                Icon(Icons.phone, color: AppColors.primaryGreen),
                SizedBox(width: 15),
                Text("+91 98765 43210", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _authService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.darkGreen));
          }

          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(
              child: Text("Profile not found in Database.\nTry registering again!",
                  textAlign: TextAlign.center),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          // 🔥 Extract variables to use for our smart routing
          String role = data['role'] ?? "Grahak";
          String fullName = data['fullName'] ?? "User";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Profile Avatar & Name
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primaryGreen,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.darkGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    role,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 30),

                // 2. Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(Icons.email, "Email", data['email']),
                      const Divider(),
                      _buildInfoRow(Icons.phone, "Phone", data['phone']),
                      const Divider(),
                      _buildInfoRow(Icons.location_on, "Address", data['address'] ?? "Not Provided"),
                      const Divider(),
                      _buildInfoRow(Icons.credit_card, "Aadhar", data['aadhar'] ?? "Not Provided"),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Settings/Options (🔥 SMART ROUTING BASED ON ROLE)

                // Everyone can buy things, so everyone gets the Order History button
                _buildOptionTile(context, Icons.shopping_bag, "My Purchases & Bids", () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BuyerOrdersScreen(currentUserName: fullName)
                      )
                  );
                }),

                // Only Sellers (Kisan / Vyapari) get to see the shop management tools!
                if (role == 'Kisan' || role == 'Vyapari') ...[
                  _buildOptionTile(context, Icons.inbox, "Incoming Orders & Requests", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SellerRequestsScreen(currentUserName: fullName)
                        )
                    );
                  }),
                  _buildOptionTile(context, Icons.storefront, "Manage My Shop Inventory", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MyListingsScreen(currentUserName: fullName)
                        )
                    );
                  }),

                  _buildOptionTile(context, Icons.account_balance_wallet, "Sales History & Profits", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SellerOrderHistoryScreen(currentUserName: fullName)
                        )
                    );
                  }),

                ],

                const SizedBox(height: 20),

                // 🔥 Linked the Support Dialog
                _buildOptionTile(context, Icons.help_outline, "Support & Help", () {
                  _showSupportDialog(context);
                }),

                // 🔥 Linked the About Dialog
                _buildOptionTile(context, Icons.info_outline, "About Kisaan Unnati", () {
                  _showAboutDialog(context);
                }),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen, size: 20),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.darkGreen),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}