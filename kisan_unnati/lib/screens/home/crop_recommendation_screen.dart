import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:kisan_unnati/services/weather_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CropRecommendationScreen extends StatefulWidget {
  const CropRecommendationScreen({Key? key}) : super(key: key);

  @override
  State<CropRecommendationScreen> createState() => _CropRecommendationScreenState();
}

class _CropRecommendationScreenState extends State<CropRecommendationScreen> {
  final _formKey = GlobalKey<FormState>();
  final WeatherService _weatherService = WeatherService();

  // Controllers for soil and weather data
  final TextEditingController _nController = TextEditingController();
  final TextEditingController _pController = TextEditingController();
  final TextEditingController _kController = TextEditingController();
  final TextEditingController _phController = TextEditingController();
  final TextEditingController _tempController = TextEditingController();
  final TextEditingController _humidityController = TextEditingController();
  final TextEditingController _rainfallController = TextEditingController();

  bool _isLoading = false;

  // This stores the list of top crops with confidence scores
  List<dynamic> _recommendations = [];

  @override
  void initState() {
    super.initState();
    _autoFillData();
  }

  /// Fetches GPS Weather and sets Alluvial Soil (Varanasi region) averages
  Future<void> _autoFillData() async {
    setState(() => _isLoading = true);

    // 1. Scientific Averages for Northern Indian Soil (kg/ha)
    _nController.text = "140";
    _pController.text = "35";
    _kController.text = "190";
    _phController.text = "7.2";

    try {
      // 2. Fetch live GPS weather
      final weatherData = await _weatherService.fetchLiveWeather();
      final double rainAmount = await _weatherService.fetchExpectedRainfall();

      if (mounted) {
        setState(() {
          _tempController.text = weatherData?['temp'] ?? "25";
          _humidityController.text = weatherData?['humidity'] ?? "60";
          _rainfallController.text = rainAmount.toStringAsFixed(1);
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS Weather & Soil Averages Loaded!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
      }
    } catch (e) {
      print("Weather Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sends the 7 parameters to the Python ML API
  Future<void> _predictCrop() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _recommendations = [];
    });

    try {
      final response = await http.post(
        Uri.parse('http://172.20.88.41:8081/predict_crop'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "n": _nController.text,
          "p": _pController.text,
          "k": _kController.text,
          "temp": _tempController.text,
          "humidity": _humidityController.text,
          "ph": _phController.text,
          "rainfall": _rainfallController.text,
        }),
      );

      if (response.statusCode == 200) {
        // We receive a JSON List from Python and decode it directly
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _recommendations = data;
        });
      } else {
        _showErrorSnackBar("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 ML API Connection Error: $e");
      _showErrorSnackBar("Connection Failed. Ensure Python server is running on port 8081.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Crop Recommender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _autoFillData,
            tooltip: "Refresh Weather",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Our Random Forest AI suggests the best crops based on your current location and soil quality.",
                style: TextStyle(fontSize: 15, color: AppColors.textGrey),
              ),
              const SizedBox(height: 25),

              // --- SOIL SECTION ---
              _sectionHeader("Soil Nutrients (kg/ha)"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField("Nitrogen (N)", _nController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Phosphorus (P)", _pController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Potassium (K)", _kController)),
                ],
              ),
              const SizedBox(height: 20),

              // --- ENVIRONMENT SECTION ---
              _sectionHeader("Environment & Soil pH"),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildInputField("pH Level", _phController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Temp (°C)", _tempController)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInputField("Humidity (%)", _humidityController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField("Rainfall (mm)", _rainfallController)),
                ],
              ),
              const SizedBox(height: 35),

              // --- PREDICT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _predictCrop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.darkGreen)
                      : const Text(
                    "Get AI Recommendation",
                    style: TextStyle(
                        fontSize: 18,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- UPGRADED RESULT LIST ---
              if (_recommendations.isNotEmpty) ...[
                _sectionHeader("Top AI Recommendations"),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: _recommendations.map((item) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.primaryGreen,
                          child: Icon(Icons.eco, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          item['crop'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.darkGreen
                          ),
                        ),
                        subtitle: const Text("Ideal match for your soil"),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.darkGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${item['confidence']}%",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: AppColors.darkGreen,
          letterSpacing: 0.5
      ),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }
}