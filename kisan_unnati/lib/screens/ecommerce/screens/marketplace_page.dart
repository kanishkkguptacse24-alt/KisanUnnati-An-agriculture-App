import 'package:flutter/material.dart';
import 'dart:io';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kisan_unnati/auth/auth_service.dart';
import '../model/product_model.dart';

class MarketplacePage extends StatefulWidget {
  final String userRole;
  const MarketplacePage({super.key, required this.userRole});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  String _selectedFilter = 'Sell';

  // --- 1. PURCHASE DIALOG (Creates an Order in Firebase) ---
  void _showPurchaseDialog(Product product) {
    double quantityToBuy = 1.0;
    int rentalDuration = 1;

    // 🔥 New Controllers for typing directly
    TextEditingController qtyController = TextEditingController(text: "1");
    TextEditingController durationController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            double totalPrice = product.listingType == 'Rent'
                ? (quantityToBuy * rentalDuration * product.price)
                : (quantityToBuy * product.price);

            return AlertDialog(
              title: Text(product.listingType == 'Rent' ? "Rent ${product.name}" : "Buy ${product.name}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Available Stock: ${product.stockQuantity}", style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 20),
                    Text(product.listingType == 'Rent' ? "Quantity to Rent:" : "Select Quantity (${product.unit}):"),

                    // 🔥 UPGRADED QUANTITY ROW
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: AppColors.primaryGreen, size: 32),
                          onPressed: quantityToBuy > 1 ? () {
                            setDialogState(() {
                              quantityToBuy--;
                              qtyController.text = quantityToBuy.toStringAsFixed(0);
                            });
                          } : null,
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(border: UnderlineInputBorder()),
                            onChanged: (val) {
                              double? newQty = double.tryParse(val);
                              if (newQty != null && newQty > 0) {
                                setDialogState(() {
                                  // Cap it at maximum stock so they can't order a million!
                                  if (newQty > product.stockQuantity) {
                                    quantityToBuy = product.stockQuantity;
                                    qtyController.text = product.stockQuantity.toStringAsFixed(0);
                                  } else {
                                    quantityToBuy = newQty;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: AppColors.primaryGreen, size: 32),
                          onPressed: quantityToBuy < product.stockQuantity ? () {
                            setDialogState(() {
                              quantityToBuy++;
                              qtyController.text = quantityToBuy.toStringAsFixed(0);
                            });
                          } : null,
                        ),
                      ],
                    ),

                    if (product.listingType == 'Rent') ...[
                      const SizedBox(height: 16),
                      Text("Duration (${product.unit}s):"),
                      // 🔥 UPGRADED DURATION ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.blue, size: 32),
                            onPressed: rentalDuration > 1 ? () {
                              setDialogState(() {
                                rentalDuration--;
                                durationController.text = rentalDuration.toString();
                              });
                            } : null,
                          ),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: durationController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(border: UnderlineInputBorder()),
                              onChanged: (val) {
                                int? newDur = int.tryParse(val);
                                if (newDur != null && newDur > 0) {
                                  setDialogState(() => rentalDuration = newDur);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
                            onPressed: () {
                              setDialogState(() {
                                rentalDuration++;
                                durationController.text = rentalDuration.toString();
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text("Total: ₹${totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending request to seller...")));

                    try {
                      var userDoc = await AuthService().getUserProfile();
                      String buyerName = userDoc.exists && userDoc.data() != null
                          ? (userDoc.data() as Map<String, dynamic>)['fullName'] ?? "Buyer"
                          : "Buyer";

                      await FirebaseFirestore.instance.collection('orders').add({
                        'productId': product.id,
                        'productName': product.name,
                        'productUnit': product.unit,
                        'sellerName': product.sellerName,
                        'buyerName': buyerName,
                        'requestedQuantity': quantityToBuy,
                        'offeredPrice': product.price,
                        'status': 'Pending',
                        'isBid': false,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Request sent to ${product.sellerName}!"), backgroundColor: AppColors.darkGreen)
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  child: const Text("Confirm Request", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- 2. BIDDING DIALOG (Creates a Bid Order in Firebase) ---
  void _showBiddingDialog(Product product) {
    final _bidController = TextEditingController();

    // 🔥 New Controller for Quantity
    double quantityToBuy = 1.0;
    TextEditingController qtyController = TextEditingController(text: "1");

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Place Bid: ${product.name}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "AI Insight: Optimal bid is ₹${(product.price * 1.05).toStringAsFixed(0)} - ₹${(product.price * 1.15).toStringAsFixed(0)}.",
                              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text("Base Price: ₹${product.price} / ${product.unit}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      product.highestBid != null ? "Current Highest Bid: ₹${product.highestBid}" : "No bids yet!",
                      style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text("Amount you want:", style: TextStyle(fontWeight: FontWeight.bold)),

                    // 🔥 UPGRADED QUANTITY ROW FOR BIDS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.orange, size: 32),
                          onPressed: quantityToBuy > 1 ? () {
                            setDialogState(() {
                              quantityToBuy--;
                              qtyController.text = quantityToBuy.toStringAsFixed(0);
                            });
                          } : null,
                        ),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(border: UnderlineInputBorder()),
                            onChanged: (val) {
                              double? newQty = double.tryParse(val);
                              if (newQty != null && newQty > 0) {
                                setDialogState(() {
                                  if (newQty > product.stockQuantity) {
                                    quantityToBuy = product.stockQuantity;
                                    qtyController.text = product.stockQuantity.toStringAsFixed(0);
                                  } else {
                                    quantityToBuy = newQty;
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.orange, size: 32),
                          onPressed: quantityToBuy < product.stockQuantity ? () {
                            setDialogState(() {
                              quantityToBuy++;
                              qtyController.text = quantityToBuy.toStringAsFixed(0);
                            });
                          } : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _bidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Your Bid (₹)", prefixIcon: Icon(Icons.gavel, color: Colors.orange)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  onPressed: () async {
                    double? newBid = double.tryParse(_bidController.text);
                    if (newBid == null || newBid <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid bid"), backgroundColor: Colors.red));
                      return;
                    }

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Submitting bid...")));

                    try {
                      var userDoc = await AuthService().getUserProfile();
                      String buyerName = userDoc.exists && userDoc.data() != null
                          ? (userDoc.data() as Map<String, dynamic>)['fullName'] ?? "Buyer"
                          : "Buyer";

                      await FirebaseFirestore.instance.collection('orders').add({
                        'productId': product.id,
                        'productName': product.name,
                        'productUnit': product.unit,
                        'sellerName': product.sellerName,
                        'buyerName': buyerName,
                        'requestedQuantity': quantityToBuy,
                        'offeredPrice': newBid,
                        'status': 'Pending',
                        'isBid': true,
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                      if (product.highestBid == null || newBid > product.highestBid!) {
                        await FirebaseFirestore.instance.collection('products').doc(product.id).update({
                          'highestBid': newBid
                        });
                      }

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Bid placed successfully!"), backgroundColor: AppColors.darkGreen),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  child: const Text("Submit Bid"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Marketplace", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundGreen,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("For Sale", style: TextStyle(fontWeight: FontWeight.bold)),
                  selected: _selectedFilter == 'Sell',
                  selectedColor: AppColors.primaryGreen.withOpacity(0.3),
                  onSelected: (bool selected) => setState(() => _selectedFilter = 'Sell'),
                ),
                const SizedBox(width: 16),
                ChoiceChip(
                  label: const Text("For Rent", style: TextStyle(fontWeight: FontWeight.bold)),
                  selected: _selectedFilter == 'Rent',
                  selectedColor: AppColors.primaryGreen.withOpacity(0.3),
                  onSelected: (bool selected) => setState(() => _selectedFilter = 'Rent'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('products').snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading market."));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("The market is currently empty. Check back later!", style: TextStyle(color: Colors.grey)));
                  }

                  List<Product> allProducts = snapshot.data!.docs.map((doc) {
                    return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                  }).toList();

                  List<Product> filteredItems = allProducts.where((item) => item.listingType == _selectedFilter).toList();

                  if (filteredItems.isEmpty) {
                    return Center(child: Text("No items available for $_selectedFilter right now.", style: const TextStyle(color: Colors.grey)));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.50,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final product = filteredItems[index];
                      final isOutOfStock = product.stockQuantity <= 0;

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isOutOfStock ? Colors.grey.shade300 : AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: product.imagePath != null
                                    ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.file(File(product.imagePath!), fit: BoxFit.cover),
                                )
                                    : Icon(Icons.eco, size: 50, color: isOutOfStock ? Colors.grey : AppColors.primaryGreen),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                                        child: Text(product.sellerRole, style: const TextStyle(fontSize: 10, color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
                                      ),
                                      if (product.isBiddable) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
                                          child: const Text("AUCTION", style: TextStyle(fontSize: 10, color: Colors.deepOrange)),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text("Base: ₹${product.price} / ${product.unit}", style: const TextStyle(color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
                                  if (product.isBiddable)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        product.highestBid != null ? "Top Bid: ₹${product.highestBid}" : "No bids yet",
                                        style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Text(isOutOfStock ? "Out of Stock" : "Stock: ${product.stockQuantity}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isOutOfStock ? Colors.red : Colors.blueGrey)),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isOutOfStock
                                          ? null
                                          : () {
                                        if (product.isBiddable) {
                                          _showBiddingDialog(product);
                                        } else {
                                          _showPurchaseDialog(product);
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isOutOfStock ? Colors.grey : (product.isBiddable ? Colors.orange : AppColors.darkGreen),
                                        foregroundColor: Colors.white,
                                      ),
                                      child: Text(isOutOfStock ? "Unavailable" : (product.isBiddable ? "Place Bid" : (product.listingType == 'Rent' ? "Rent" : "Request"))),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
            ),
          ),
        ],
      ),
    );
  }
}