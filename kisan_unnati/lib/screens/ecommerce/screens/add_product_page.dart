import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'dart:io';
import 'package:kisan_unnati/auth/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Added Firestore
import '../model/product_model.dart';

class AddProductPage extends StatefulWidget {
  final String userName;
  final String userRole;
  const AddProductPage({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController();

  String _listingType = 'Sell';
  String _selectedUnit = 'kg'; // Default for 'Sell'

  bool _isBiddable = false;
  DateTime? _biddingEndDate;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryGreen,
              onPrimary: Colors.white,
              onSurface: AppColors.darkGreen,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _biddingEndDate) {
      setState(() {
        _biddingEndDate = picked;
      });
    }
  }

  // 🔥 COMPLETELY UPGRADED TO SAVE TO FIREBASE
  void _publishProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_isBiddable && _biddingEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a bidding end date"), backgroundColor: Colors.red),
      );
      return;
    }

    // Grab the real name from Firebase!
    var userDoc = await AuthService().getUserProfile();
    String realName = userDoc.exists && userDoc.data() != null
        ? (userDoc.data() as Map<String, dynamic>)['fullName'] ?? widget.userName
        : widget.userName;

    // 🔥 Generate a real, unique ID from Firebase
    String productId = FirebaseFirestore.instance.collection('products').doc().id;

    final newProduct = Product(
      id: productId, // Use the generated ID
      name: _nameController.text,
      price: double.parse(_priceController.text),
      unit: _selectedUnit,
      sellerName: realName,
      stockQuantity: double.parse(_quantityController.text),
      imagePath: _selectedImage?.path,
      address: _addressController.text,
      sellerRole: widget.userRole,
      listingType: widget.userRole == 'Vyapari' ? _listingType : 'Sell',
      isBiddable: _isBiddable,
      biddingEndDate: _isBiddable ? _biddingEndDate : null,
      highestBid: _isBiddable ? (double.parse(_priceController.text) + 5) : null, // Fake bid for hackathon testing
    );

    try {
      // 🔥 SEND DIRECTLY TO THE CLOUD
      await FirebaseFirestore.instance.collection('products').doc(productId).set(newProduct.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Live on Digital Mandi!"), backgroundColor: AppColors.darkGreen),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving to database: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = widget.userRole == 'Kisan' ? "List Your Crop" : "List Shop Inventory";
    String nameHint = widget.userRole == 'Kisan' ? "Crop Name (e.g. Wheat)" : "Product Name (e.g. Tractor, Seeds)";

    // DYNAMIC UNITS LOGIC
    List<String> currentUnits = _listingType == 'Rent' ? ['day', 'hour'] : ['kg', 'quintal', 'piece'];

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.5)),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.add_a_photo, size: 50, color: AppColors.primaryGreen),
                    SizedBox(height: 8),
                    Text("Add Photo", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (widget.userRole == 'Vyapari') ...[
              DropdownButtonFormField<String>(
                value: _listingType,
                decoration: const InputDecoration(labelText: "Listing Type", prefixIcon: Icon(Icons.handshake, color: AppColors.primaryGreen)),
                items: ['Sell', 'Rent'].map((String type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) {
                  setState(() {
                    _listingType = val!;
                    // Safety check
                    if (_listingType == 'Rent' && !['day', 'hour'].contains(_selectedUnit)) {
                      _selectedUnit = 'day';
                    } else if (_listingType == 'Sell' && !['kg', 'quintal', 'piece'].contains(_selectedUnit)) {
                      _selectedUnit = 'kg';
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: nameHint, prefixIcon: const Icon(Icons.eco, color: AppColors.primaryGreen)),
            ),

            // --- AI PRICE SUGGESTION WIDGET ---
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameController,
              builder: (context, value, child) {
                final text = value.text.toLowerCase();
                if (text.isNotEmpty && (text.contains('wheat') || text.contains('tomato'))) {
                  String suggestedPrice = text.contains('wheat') ? "2200 / quintal" : "40 / kg";
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _priceController.text = text.contains('wheat') ? "2200" : "40";
                          _selectedUnit = text.contains('wheat') ? "quintal" : "kg";
                          _listingType = 'Sell';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: Colors.purple, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "AI Market Suggestion: ₹$suggestedPrice. Tap to apply.",
                                style: TextStyle(color: Colors.purple.shade800, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: "Pickup Address / Location", prefixIcon: Icon(Icons.location_on, color: AppColors.primaryGreen)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Total Stock Quantity", prefixIcon: Icon(Icons.inventory, color: AppColors.primaryGreen)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Base Price (₹)", prefixIcon: Icon(Icons.currency_rupee, color: AppColors.primaryGreen)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    decoration: const InputDecoration(labelText: "Unit"),
                    items: currentUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (val) => setState(() => _selectedUnit = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
              child: SwitchListTile(
                title: const Text("Enable Bidding", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Allow buyers to place bids on this item."),
                activeColor: AppColors.primaryGreen,
                value: _isBiddable,
                onChanged: (bool value) => setState(() => _isBiddable = value),
              ),
            ),

            if (_isBiddable) ...[
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColors.primaryGreen.withOpacity(0.3))),
                tileColor: AppColors.primaryGreen.withOpacity(0.05),
                leading: const Icon(Icons.calendar_today, color: AppColors.primaryGreen),
                title: Text(
                  _biddingEndDate == null
                      ? "Select Bidding End Date"
                      : "Ends: ${_biddingEndDate!.day}/${_biddingEndDate!.month}/${_biddingEndDate!.year}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primaryGreen),
                onTap: () => _selectDate(context),
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _publishProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Publish Listing", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}