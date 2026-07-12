import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:kisan_unnati/core/theme/app_colors.dart';

class DiseaseDetectionScreen extends StatefulWidget {
  const DiseaseDetectionScreen({Key? key}) : super(key: key);

  @override
  State<DiseaseDetectionScreen> createState() => _DiseaseDetectionScreenState();
}

class _DiseaseDetectionScreenState extends State<DiseaseDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes; // For web/mobile image display

  bool _isAnalyzing = false;

  // New variables to catch the Keras API response
  String _diseaseName = "";
  String _confidence = "";
  String _description = "";
  String _errorMessage = "";

  // 1. Pick Image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          // Clear old results when a new image is picked
          _diseaseName = "";
          _confidence = "";
          _description = "";
          _errorMessage = "";
        });
      }
    } catch (e) {
      print("🚨 Image Picker Error: $e");
    }
  }

  // 2. Send to New Python Keras API
  Future<void> _analyzeLeaf() async {
    if (_imageBytes == null) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = "";
      _diseaseName = "";
    });

    try {
      // 🔥 FIX 1: Point exactly to the new /predict_disease route
      var apiUrl = Uri.parse('http://172.20.88.41:8080/predict_disease');

      // 🔥 FIX 2: Use MultipartRequest to send it as an actual file, not Base64 text
      var request = http.MultipartRequest('POST', apiUrl);

      request.files.add(
        http.MultipartFile.fromBytes(
          'file', // This matches request.files['file'] in Python!
          _imageBytes!,
          filename: 'leaf_scan.jpg',
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          // 🔥 FIX 3: Read the new dictionary keys we made in Python
          _diseaseName = data['disease'] ?? "Unknown";
          _confidence = data['confidence'].toString();
          _description = data['description'] ?? "No details available.";
        });
      } else {
        setState(() => _errorMessage = "Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("🚨 API Error: $e");
      setState(() => _errorMessage = "Connection Failed. Is Python running on 8080?");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plant Doctor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              "Upload a clear photo of the sick leaf to detect the disease instantly.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 20),

            // Image Preview Box
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryGreen, width: 2),
              ),
              child: _imageBytes != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(_imageBytes!, fit: BoxFit.cover),
              )
                  : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.energy_savings_leaf, size: 60, color: AppColors.primaryGreen),
                  SizedBox(height: 10),
                  Text("No image selected", style: TextStyle(color: AppColors.textGrey)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text("Camera", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, color: AppColors.darkGreen),
                  label: const Text("Gallery", style: TextStyle(color: AppColors.darkGreen)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cardWhite,
                    side: const BorderSide(color: AppColors.darkGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Analyze Button
            if (_imageBytes != null)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isAnalyzing ? null : _analyzeLeaf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentYellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _isAnalyzing
                      ? const CircularProgressIndicator(color: AppColors.darkGreen)
                      : const Text("Analyze Leaf", style: TextStyle(fontSize: 18, color: AppColors.textDark, fontWeight: FontWeight.bold)),
                ),
              ),

            const SizedBox(height: 30),

            // --- ERROR MESSAGE BOX ---
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),

            // --- THE NEW RESULT CARD ---
            if (_diseaseName.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Make it green if healthy, red if diseased!
                  color: _diseaseName.toLowerCase().contains("healthy") ? AppColors.primaryGreen.withOpacity(0.2) : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _diseaseName.toLowerCase().contains("healthy") ? AppColors.darkGreen : Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                            _diseaseName.toLowerCase().contains("healthy") ? Icons.check_circle : Icons.warning_amber_rounded,
                            color: _diseaseName.toLowerCase().contains("healthy") ? AppColors.darkGreen : Colors.red,
                            size: 28
                        ),
                        const SizedBox(width: 10),
                        Text(
                            _diseaseName.toLowerCase().contains("healthy") ? "Plant is Healthy!" : "Disease Detected",
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _diseaseName.toLowerCase().contains("healthy") ? AppColors.darkGreen : Colors.red
                            )
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Disease Name
                    Text(
                      _diseaseName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 5),

                    // Confidence Level
                    Text(
                      "AI Confidence: $_confidence%",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _diseaseName.toLowerCase().contains("healthy") ? AppColors.darkGreen : Colors.red.shade700
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(),
                    ),

                    // The Detailed Description
                    const Text(
                      "About this scan:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _description,
                      style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}