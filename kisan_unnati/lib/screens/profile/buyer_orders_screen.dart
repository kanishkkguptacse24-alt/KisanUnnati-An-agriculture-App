import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';

class BuyerOrdersScreen extends StatefulWidget {
  final String currentUserName;
  const BuyerOrdersScreen({super.key, required this.currentUserName});

  @override
  State<BuyerOrdersScreen> createState() => _BuyerOrdersScreenState();
}

class _BuyerOrdersScreenState extends State<BuyerOrdersScreen> {

  // 🔥 1. BUYER ACCEPTS THE NEW QUANTITY
  void _acceptNegotiation(String orderId, String productId, double finalQty) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Approve the order
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Approved',
      });

      // Deduct the stock from the Seller's product
      DocumentSnapshot prodDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (prodDoc.exists) {
        double currentStock = (prodDoc.data() as Map<String, dynamic>)['stockQuantity'] ?? 0;
        await FirebaseFirestore.instance.collection('products').doc(productId).update({
          'stockQuantity': currentStock - finalQty,
          'highestBid': null,
        });
      }
      messenger.showSnackBar(const SnackBar(content: Text("Deal Finalized!"), backgroundColor: AppColors.darkGreen));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // 🔥 2. BUYER REJECTS THE NEW QUANTITY
  void _rejectNegotiation(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Rejected',
      });
      messenger.showSnackBar(const SnackBar(content: Text("Counter-offer rejected. Order cancelled."), backgroundColor: Colors.red));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Purchases & Bids", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundGreen,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('buyerName', isEqualTo: widget.currentUserName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("You haven't made any requests yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var doc = orders[index];
              var data = doc.data() as Map<String, dynamic>;

              String status = data['status'] ?? 'Pending';
              bool isNegotiating = status == 'Negotiating';
              bool isBid = data['isBid'] ?? false;

              // Smart color coding based on status
              Color statusColor = status == "Approved" ? Colors.green :
              (status == "Rejected" ? Colors.red :
              (status == "Negotiating" ? Colors.blue : Colors.orange));

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isNegotiating ? BorderSide(color: Colors.blue.shade300, width: 2) : BorderSide.none,
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(isBid ? Icons.gavel : Icons.shopping_cart, color: statusColor),
                      ),
                      title: Text(data['productName'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Qty: ${data['requestedQuantity']} ${data['productUnit']}\nTotal: ₹${(data['requestedQuantity'] * data['offeredPrice']).toStringAsFixed(2)}"),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            isNegotiating ? "Action Required" : status,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)
                        ),
                      ),
                    ),

                    // 🔥 IF NEGOTIATING: Show these action buttons to the buyer!
                    if (isNegotiating)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.info_outline, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(child: Text("Seller proposed a lower quantity. Do you accept?", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white),
                                    onPressed: () => _acceptNegotiation(doc.id, data['productId'], data['requestedQuantity']),
                                    child: const Text("Accept Deal"),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                    onPressed: () => _rejectNegotiation(doc.id),
                                    child: const Text("Cancel Order"),
                                  ),
                                )
                              ],
                            )
                          ],
                        ),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}