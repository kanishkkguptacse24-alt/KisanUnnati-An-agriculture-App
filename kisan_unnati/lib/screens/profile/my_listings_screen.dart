import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import '../ecommerce/model/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyListingsScreen extends StatefulWidget {
  final String currentUserName;
  const MyListingsScreen({super.key, required this.currentUserName});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {

  // 🔥 1. Manually Delete Item
  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Item?", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to permanently delete ${product.name} from the market?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog first!
              final messenger = ScaffoldMessenger.of(context);

              try {
                await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                messenger.showSnackBar(const SnackBar(content: Text("Item deleted successfully!"), backgroundColor: Colors.red));
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // 🔥 2. Edit stock (With Auto-Delete if stock reaches 0)
  void _editStock(Product product) {
    TextEditingController qtyController = TextEditingController(text: product.stockQuantity.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Stock: ${product.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("If you set the stock to 0, the item will be automatically deleted from the market.", style: TextStyle(fontSize: 12, color: Colors.red)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "New Quantity (${product.unit})", border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
            onPressed: () async {
              double newStock = double.tryParse(qtyController.text) ?? product.stockQuantity;
              Navigator.pop(context); // Close dialog first!
              final messenger = ScaffoldMessenger.of(context);

              try {
                if (newStock <= 0) {
                  // AUTO-DELETE Logic!
                  await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                  messenger.showSnackBar(SnackBar(content: Text("${product.name} auto-deleted (Stock reached 0)."), backgroundColor: Colors.red));
                } else {
                  // Just update the stock
                  await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                    'stockQuantity': newStock,
                  });
                  messenger.showSnackBar(const SnackBar(content: Text("Stock updated successfully!"), backgroundColor: AppColors.darkGreen));
                }
              } catch (e) {
                messenger.showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
              }
            },
            child: const Text("Update Stock", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage My Inventory", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundGreen,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerName', isEqualTo: widget.currentUserName)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Error loading your listings."));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text("You have no active listings.", style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Go to the Market tab to add a product!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final myItems = snapshot.data!.docs.map((doc) {
            return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myItems.length,
            itemBuilder: (context, index) {
              final item = myItems[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                                item.name,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
                                overflow: TextOverflow.ellipsis
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              "₹${item.price} / ${item.unit}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.inventory, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text("Current Stock: ${item.stockQuantity} ${item.unit}", style: const TextStyle(fontSize: 15, color: Colors.black87)),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),

                      // 🔥 Only Inventory Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _editStock(item),
                              icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                              label: const Text("Edit Stock", style: TextStyle(color: Colors.blue)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showDeleteConfirmation(item),
                              icon: const Icon(Icons.delete_forever, size: 18, color: Colors.white),
                              label: const Text("Delete", style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
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