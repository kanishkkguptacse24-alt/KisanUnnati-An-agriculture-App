import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';

class SellerRequestsScreen extends StatefulWidget {
  final String currentUserName;
  const SellerRequestsScreen({super.key, required this.currentUserName});

  @override
  State<SellerRequestsScreen> createState() => _SellerRequestsScreenState();
}

class _SellerRequestsScreenState extends State<SellerRequestsScreen> {

  // 1. APPROVE ORDER Logic
  void _approveOrder(String orderId, String productId, double requestedQty) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Approved',
      });

      DocumentSnapshot productDoc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (productDoc.exists) {
        double currentStock = (productDoc.data() as Map<String, dynamic>)['stockQuantity'] ?? 0;
        await FirebaseFirestore.instance.collection('products').doc(productId).update({
          'stockQuantity': currentStock - requestedQty,
          'highestBid': null,
        });
      }

      messenger.showSnackBar(const SnackBar(content: Text("Order Approved successfully!"), backgroundColor: AppColors.darkGreen));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // 2. REJECT ORDER Logic
  void _rejectOrder(String orderId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Rejected',
      });
      messenger.showSnackBar(const SnackBar(content: Text("Order Rejected."), backgroundColor: Colors.red));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // 🔥 3. PROPOSE NEW QUANTITY (Sends back to Buyer)
  void _proposeNewQuantity(String orderId, double originalQty, String unit) {
    TextEditingController qtyController = TextEditingController(text: originalQty.toString());

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Counter-Offer Quantity"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Propose a lower quantity. The buyer will need to approve this change before the deal is final.", style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 10),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Quantity to Offer ($unit)", border: const OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
              onPressed: () async {
                double newQty = double.tryParse(qtyController.text) ?? 0.0;
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);

                if (newQty >= originalQty) {
                  messenger.showSnackBar(const SnackBar(content: Text("You must enter a quantity LOWER than requested!"), backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(context);

                try {
                  await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
                    'requestedQuantity': newQty,
                    'status': 'Negotiating',
                  });

                  messenger.showSnackBar(const SnackBar(content: Text("Counter-offer sent to buyer!"), backgroundColor: Colors.blue));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                }
              },
              child: const Text("Send Counter-Offer", style: TextStyle(color: Colors.white)),
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Incoming Requests", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundGreen,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('sellerName', isEqualTo: widget.currentUserName)
            .where('status', isEqualTo: 'Pending') // Once it becomes 'Negotiating', it leaves this screen!
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("No pending requests right now.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final pendingOrders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingOrders.length,
            itemBuilder: (context, index) {
              var doc = pendingOrders[index];
              var data = doc.data() as Map<String, dynamic>;
              bool isBid = data['isBid'] ?? false;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.orange.shade200)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isBid ? Icons.gavel : Icons.shopping_cart, color: Colors.orange.shade800),
                          const SizedBox(width: 8),
                          Text(isBid ? "New Bid Received!" : "New Purchase Request!", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(),
                      Text("Product: ${data['productName']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Buyer: ${data['buyerName']}", style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text("Requested Qty: ${data['requestedQuantity']} ${data['productUnit']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Offered Price: ₹${data['offeredPrice']} / ${data['productUnit']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Total Value: ₹${(data['requestedQuantity'] * data['offeredPrice']).toStringAsFixed(2)}", style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold, fontSize: 16)),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, foregroundColor: Colors.white),
                              onPressed: () => _approveOrder(doc.id, data['productId'], data['requestedQuantity']),
                              child: const Text("Approve"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.blue.shade700, side: BorderSide(color: Colors.blue.shade700)),
                              onPressed: () => _proposeNewQuantity(doc.id, data['requestedQuantity'], data['productUnit']),
                              child: const Text("Adjust Qty"),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _rejectOrder(doc.id),
                          child: const Text("Reject Request"),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}