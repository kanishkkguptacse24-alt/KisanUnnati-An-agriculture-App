import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherService {
  // 1. Fetch Current Weather + Extra Details
  Future<Map<String, dynamic>?> fetchLiveWeather() async {
    try {
      Position position = await _getPosition();
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return null;

      final url = 'https://api.openweathermap.org/data/2.5/weather?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'temp': data['main']['temp'].round().toString(),
          'city': data['name'],
          'condition': data['weather'][0]['main'],
          'humidity': data['main']['humidity'].toString(), // NEW
          'wind': data['wind']['speed'].toString(),
          'rain': data['rain'] != null ? data['rain']['1h'].toString() : "0",
        };
      }
      return null;
    } catch (e) {
      print('🚨 Weather Error: $e');
      return null;
    }
  }

  // 2. Fetch 5-Day Forecast
  Future<List<Map<String, dynamic>>?> fetch5DayForecast() async {
    try {
      Position position = await _getPosition();
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return null;

      // Notice the endpoint is /forecast instead of /weather
      final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['list'];
        List<Map<String, dynamic>> dailyForecast = [];

        // The API gives data every 3 hours. We filter it to grab the forecast for 12:00 PM each day.
        for (var item in list) {
          if (item['dt_txt'].contains('12:00:00')) {
            dailyForecast.add({
              // Format date from "2026-04-05 12:00:00" to "04-05"
              'date': item['dt_txt'].toString().substring(5, 10),
              'temp': item['main']['temp'].round().toString(),
              'condition': item['weather'][0]['main'],
            });
          }
        }
        return dailyForecast;
      }
      return null;
    } catch (e) {
      print('🚨 Forecast Error: $e');
      return null;
    }
  }

  // New helper to get Rainfall for the next 24 hours
  Future<double> fetchExpectedRainfall() async {
    try {
      Position position = await _getPosition();
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];

      // We use the 5-day / 3-hour forecast API
      final url = 'https://api.openweathermap.org/data/2.5/forecast?lat=${position.latitude}&lon=${position.longitude}&appid=$apiKey&units=metric';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double totalRain = 0.0;

        // Sum up the rain for the first 8 timestamps (approx 24 hours)
        for (var i = 0; i < 8; i++) {
          var forecast = data['list'][i];
          if (forecast['rain'] != null && forecast['rain']['3h'] != null) {
            totalRain += forecast['rain']['3h'];
          }
        }
        return totalRain > 0 ? totalRain : 50.0; // Return 50mm as a safe baseline if no rain
      }
    } catch (e) {
      print("Rainfall Fetch Error: $e");
    }
    return 100.0; // Default fallback
  }

  // Helper to get location so we don't repeat code
  Future<Position> _getPosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }
}