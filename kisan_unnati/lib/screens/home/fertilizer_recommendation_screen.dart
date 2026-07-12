import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FertilizerRecommendationScreen extends StatefulWidget {
  const FertilizerRecommendationScreen({Key? key}) : super(key: key);

  @override
  State<FertilizerRecommendationScreen> createState() => _FertilizerRecommendationScreenState();
}

class _FertilizerRecommendationScreenState extends State<FertilizerRecommendationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Numerical Input Controllers
  final TextEditingController _tempController = TextEditingController(text: "26");
  final TextEditingController _humidityController = TextEditingController(text: "52");
  final TextEditingController _moistureController = TextEditingController(text: "38");
  final TextEditingController _nController = TextEditingController(text: "37");
  final TextEditingController _pController = TextEditingController(text: "0");
  final TextEditingController _kController = TextEditingController(text: "0");

  // Dropdown Variables (Default values matching your CSV)
  String _selectedSoil = "Sandy";
  String _selectedCrop = "Maize";

  // The lists of valid words directly from your CSV file
  final List<String> _soilTypes = ["Sandy", "Loamy", "Black", "Red", "Clayey"];
  final List<String> _cropTypes = [
    "Maize", "Sugarcane", "Cotton", "Tobacco", "Paddy", "Barley",
    "Wheat", "Millets", "Oil seeds", "Pulses", "Ground Nuts"
  ];

  bool _isLoading = false;
  String _recommendedFertilizer = "";

  Future<void> _predictFertilizer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _recommendedFertilizer = "";
    });

    try {
      final response = await http.post(
        Uri.parse('http://172.20.88.41:8082/predict_fertilizer'), // Note: Port 8082!
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "temperature": _tempController.text,
          "humidity": _humidityController.text,
          "moisture": _moistureController.text,
          "soil_type": _selectedSoil,
          "crop_type": _selectedCrop,
          "nitrogen": _nController.text,
          "potassium": _kController.text,  // K is Potassium
          "phosphorous": _pController.text // P is Phosphorous
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _recommendedFertilizer = data['fertilizer'];
        });
      } else {
        _showError("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
      _showError("Connection Failed. Ensure API is running on port 8082.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Fertilizer Recommender')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enter your field conditions to find the exact fertilizer needed for your crop.",
                style: TextStyle(fontSize: 15, color: AppColors.textGrey),
              ),
              const SizedBox(height: 25),

              // --- FIELD SETTINGS (Dropdowns) ---
              _sectionHeader("Field Settings"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildDropdown("Soil Type", _soilTypes, _selectedSoil, (val) => setState(() => _selectedSoil = val!))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildDropdown("Crop Type", _cropTypes, _selectedCrop, (val) => setState(() => _selectedCrop = val!))),
                ],
              ),
              const SizedBox(height: 20),

              // --- ENVIRONMENT ---
              _sectionHeader("Environment & Moisture"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField("Temp (°C)", _tempController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Humidity (%)", _humidityController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Moisture", _moistureController)),
                ],
              ),
              const SizedBox(height: 20),

              // --- SOIL NUTRIENTS ---
              _sectionHeader("Current Soil Nutrients"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField("Nitrogen (N)", _nController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Phosphorous (P)", _pController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Potassium (K)", _kController)),
                ],
              ),
              const SizedBox(height: 35),

              // --- PREDICT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _predictFertilizer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.darkGreen)
                      : const Text(
                    "Find Fertilizer",
                    style: TextStyle(fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- RESULT CARD ---
              if (_recommendedFertilizer.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppColors.primaryGreen),
                  ),
                  child: Column(
                    children: [
                      const Text("Best Fertilizer for your Field:",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen)),
                      const SizedBox(height: 15),
                      Text(
                        _recommendedFertilizer.toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen, letterSpacing: 0.5),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdown(String label, List<String> items, String selectedValue, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
      items: items.map((String item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))).toList(),
      onChanged: onChanged,
    );
  }
}