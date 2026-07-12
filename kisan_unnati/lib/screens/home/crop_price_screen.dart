import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CropPriceScreen extends StatefulWidget {
  const CropPriceScreen({Key? key}) : super(key: key);

  @override
  State<CropPriceScreen> createState() => _CropPriceScreenState();
}

class _CropPriceScreenState extends State<CropPriceScreen> {
  // 🔥 New Dropdown variables to prevent typos
  String? _selectedCrop;
  final List<String> _crops = [
    "Arhar", "Bajra", "Barley", "Copra", "Cotton", "Sesamum", "Gram",
    "Groundnut", "Jowar", "Maize", "Masoor", "Moong", "Niger", "Paddy",
    "Ragi", "Rape", "Jute", "Safflower", "Soyabean", "Sugarcane",
    "Sunflower", "Urad", "Wheat"
  ];

  final TextEditingController _rainfallController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();

  bool _isLoading = false;
  String? _predictedPrice;

  Future<void> _predictPrice() async {
    if (_selectedCrop == null || _rainfallController.text.isEmpty || _tempController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields!"), backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
      _predictedPrice = null;
    });

    try {
      // ✅ Using your Laptop IP and Port
      final String apiUrl = 'http://172.20.88.41:8084/predict';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "crop": _selectedCrop, // Sends the exact dropdown value
          "rainfall": double.parse(_rainfallController.text.trim()),
          "temperature": double.parse(_tempController.text.trim()),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _predictedPrice = "₹${data['predicted_price']} per quintal";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Server Error: ${response.statusCode}"), backgroundColor: Colors.red));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not connect to laptop server."), backgroundColor: Colors.red)
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ML Price Prediction", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppColors.backgroundGreen,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),

            // 🔥 CROP DROPDOWN - Prevents UI Overflow & Typo Errors

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _selectedCrop,
                  hint: const Text("Select Crop"),
                  isExpanded: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.eco, color: AppColors.primaryGreen), border: InputBorder.none),
                  items: _crops.map((crop) => DropdownMenuItem(value: crop, child: Text(crop))).toList(),
                  onChanged: (val) => setState(() => _selectedCrop = val),
                ),
              ),
            ),
            const SizedBox(height: 16),

            _buildInput(_rainfallController, "Expected Rainfall (mm)", Icons.water_drop, Colors.blue),
            const SizedBox(height: 16),
            _buildInput(_tempController, "Average Temp (°C)", Icons.thermostat, Colors.redAccent),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _predictPrice,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Predict Price", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),

            if (_predictedPrice != null) ...[
              const SizedBox(height: 30),
              _buildResultCard(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade200)),
      child: const Row(
        children: [
          Icon(Icons.trending_up, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(child: Text("Select your crop and local conditions to get AI-driven price estimates.", style: TextStyle(color: AppColors.textDark))),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label, IconData icon, Color color) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: color), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.primaryGreen, width: 2)),
      child: Column(
        children: [
          const Text("Estimated Market Value", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          FittedBox(child: Text(_predictedPrice!, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.darkGreen))),
        ],
      ),
    );
  }
}