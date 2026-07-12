import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';

class SellerOrderHistoryScreen extends StatelessWidget {
  final String currentUserName;
  const SellerOrderHistoryScreen({super.key, required this.currentUserName});

  // 🔥 Dialog to show the detailed Profit breakdown when an order is clicked
  void _showOrderDetails(BuildContext context, Map<String, dynamic> data) {
    double qty = (data['requestedQuantity'] ?? 0).toDouble();
    double sellingPrice = (data['offeredPrice'] ?? 0).toDouble();

    // Revenue is Quantity * Price
    double totalRevenue = qty * sellingPrice;

    // Demo Hack: If we didn't save a cost price when adding the product, assume cost was 75% of the sale price
    double costPerUnit = data['costPrice'] != null ? data['costPrice'].toDouble() : (sellingPrice * 0.75);
    double totalCost = qty * costPerUnit;

    // Profit = Revenue - Cost
    double totalProfit = totalRevenue - totalCost;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Order Details: ${data['productName']}", style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Buyer:", data['buyerName'] ?? "Unknown"),
              _buildDetailRow("Quantity Sold:", "$qty ${data['productUnit']}"),
              const Divider(height: 30),

              // Financial Breakdown
              _buildDetailRow("Total Revenue:", "₹${totalRevenue.toStringAsFixed(2)}", color: Colors.blue.shade700),
              _buildDetailRow("Total Cost Price:", "₹${totalCost.toStringAsFixed(2)}", color: Colors.red.shade700),
              const Divider(),

              // The Profit!
              _buildDetailRow("Total Profit:", "₹${totalProfit.toStringAsFixed(2)}", color: AppColors.darkGreen, isBold: true),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(color: Colors.grey))
            ),
          ],
        )
    );
  }

  // Helper widget for the dialog text
  Widget _buildDetailRow(String label, String value, {Color? color, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          Text(
              value,
              style: TextStyle(
                color: color ?? Colors.black,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: isBold ? 18 : 15,
              )
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sales History & Profits", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkGreen, // Darker green for financial stuff
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundGreen,

      // 🔥 StreamBuilder to fetch ONLY 'Approved' orders for this seller
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerName', isEqualTo: currentUserName)
            .where('status', isEqualTo: 'Approved') // Only show finalized deals!
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading sales history."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("No approved sales yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text("Approve some pending requests to see them here!", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            );
          }

          final pastOrders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pastOrders.length,
            itemBuilder: (context, index) {
              var doc = pastOrders[index];
              var data = doc.data() as Map<String, dynamic>;

              double qty = (data['requestedQuantity'] ?? 0).toDouble();
              double price = (data['offeredPrice'] ?? 0).toDouble();
              double revenue = qty * price;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green, // Solid green for approved money!
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text(data['productName'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Sold to: ${data['buyerName']}\nRevenue: ₹${revenue.toStringAsFixed(2)}"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  isThreeLine: true,
                  onTap: () => _showOrderDetails(context, data), // Open the details dialog!
                ),
              );
            },
          );
        },
      ),
    );
  }
}