import 'package:flutter/material.dart';
import 'package:kisan_unnati/core/theme/app_colors.dart';
import 'package:kisan_unnati/screens/home/sakha_chat_screen.dart';
import 'package:kisan_unnati/services/weather_service.dart';
import 'package:kisan_unnati/screens/home/disease_detection_screen.dart';
import 'package:kisan_unnati/screens/home/crop_recommendation_screen.dart';
import 'package:kisan_unnati/screens/home/fertilizer_recommendation_screen.dart';
import 'package:kisan_unnati/screens/home/crop_price_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _weatherService = WeatherService();

  // Default fallback values
  String _temperature = "--";
  String _cityName = "Locating...";
  String _condition = "Loading";
  String _humidity = "--";
  String _wind = "--";
  String _rainfall = "--"; // 🔥 Added Rainfall variable
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    final weatherData = await _weatherService.fetchLiveWeather();

    if (weatherData != null && mounted) {
      setState(() {
        _temperature = weatherData['temp']!;
        _cityName = weatherData['city']!;
        _condition = weatherData['condition']!;
        _humidity = weatherData['humidity']!;
        _wind = weatherData['wind']!;
        _rainfall = weatherData['rain'] ?? "0"; // 🔥 Get rainfall from service
        _isLoadingWeather = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _cityName = "Api Key Error";
          _temperature = "--";
          _isLoadingWeather = false;
        });
      }
    }
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.toLowerCase().contains('cloud')) return Icons.cloud;
    if (condition.toLowerCase().contains('rain')) return Icons.water_drop;
    return Icons.wb_sunny;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGreen,
      appBar: AppBar(
        title: const Text('KisanUnnati', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active_outlined), onPressed: () {})
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome, Kisan!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 20),

            // 1. Live Weather Box
            GestureDetector(
              onTap: () => _showForecastSheet(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.primaryGreen, AppColors.darkGreen]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Live Local Weather', style: TextStyle(fontSize: 16, color: Colors.white70)),
                            const SizedBox(height: 4),
                            _isLoadingWeather
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text('$_temperature°C', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(_cityName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16)),
                          ],
                        ),
                        Icon(_getWeatherIcon(_condition), color: Colors.amber, size: 70),
                      ],
                    ),
                    const Divider(color: Colors.white54, height: 30, thickness: 1),
                    // 🔥 Updated Extra Details Row to include Rainfall
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildWeatherDetail(Icons.water_drop, 'Humid: $_humidity%'),
                        _buildWeatherDetail(Icons.air, 'Wind: $_wind m/s'),
                        _buildWeatherDetail(Icons.umbrella, 'Rain: $_rainfall mm'),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Smart Farm Tools',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGreen),
            ),
            const SizedBox(height: 15),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.95,
              children: [
                _buildToolCard(
                  context: context,
                  title: 'Disease\nDetection',
                  icon: Icons.document_scanner,
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DiseaseDetectionScreen())),
                ),
                _buildToolCard(
                  context: context,
                  title: 'Fertilizer\nRecommendation',
                  icon: Icons.science,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FertilizerRecommendationScreen())),
                ),
                _buildToolCard(
                  context: context,
                  title: 'Crop\nRecommendation',
                  icon: Icons.eco,
                  color: AppColors.primaryGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropRecommendationScreen())),
                ),
                _buildToolCard(
                  context: context,
                  title: 'Crop Price\nPrediction',
                  icon: Icons.trending_up,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CropPriceScreen())),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SakhaChatScreen()));
        },
        backgroundColor: AppColors.darkGreen,
        icon: const Icon(Icons.psychology, color: Colors.white),
        label: const Text('Ask Sakha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 🔥 Helper for Weather Details (Icons + Text)
  Widget _buildWeatherDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              // 🔥 Changed text color to AppColors.darkGreen as requested
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkGreen),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  void _showForecastSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return FutureBuilder<List<Map<String, dynamic>>?>(
            future: _weatherService.fetch5DayForecast(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)));
              }
              if (!snapshot.hasData || snapshot.data == null || snapshot.data!.isEmpty) {
                return const SizedBox(height: 300, child: Center(child: Text("Could not load forecast.")));
              }

              final forecast = snapshot.data!;

              return Container(
                padding: const EdgeInsets.all(20),
                height: 350,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('5-Day Forecast', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                    const SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        itemCount: forecast.length,
                        itemBuilder: (context, index) {
                          final day = forecast[index];
                          return ListTile(
                            leading: Icon(_getWeatherIcon(day['condition']), color: AppColors.darkGreen, size: 30),
                            title: Text('Date: ${day['date']}', style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.darkGreen)),
                            trailing: Text('${day['temp']}°C', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                            subtitle: Text(day['condition'], style: const TextStyle(color: Colors.grey)),
                          );
                        },
                      ),
                    )
                  ],
                ),
              );
            },
          );
        }
    );
  }
}