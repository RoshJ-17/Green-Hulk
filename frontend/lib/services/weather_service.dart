// lib/services/weather_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = '506643b44bfd47fabfe190218261003';
  static const String _baseUrl = 'https://api.weatherapi.com/v1';

  static const double windWarningKph = 15.0;
  static const double rainWarningPct = 40.0;

  static Future<WeatherAdvisory> getSprayAdvisory({
    double? latitude,
    double? longitude,
  }) async {
    final query = (latitude != null && longitude != null)
        ? '$latitude,$longitude'
        : 'auto:ip';

    final uri = Uri.parse(
      '$_baseUrl/forecast.json?key=$_apiKey&q=${Uri.encodeComponent(query)}&days=1&aqi=no&alerts=no',
    );

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        throw Exception('Weather API error: ${response.statusCode}');
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      return _parseAdvisory(data);
    } catch (e) {
      debugPrint('WeatherService error: $e');
      rethrow;
    }
  }

  static WeatherAdvisory _parseAdvisory(Map<String, dynamic> data) {
    final current = data['current'] as Map<String, dynamic>;
    final forecast = data['forecast']['forecastday'][0] as Map<String, dynamic>;
    final hours = forecast['hour'] as List<dynamic>;
    final location = data['location'] as Map<String, dynamic>;

    final windKph = (current['wind_kph'] as num).toDouble();
    final humidity = (current['humidity'] as num).toInt();
    final tempC = (current['temp_c'] as num).toDouble();
    final condition = current['condition']['text'] as String;

    final now = DateTime.now();
    double maxRainChance = 0;
    for (final h in hours) {
      final hourTime = DateTime.parse(h['time'] as String);
      if (hourTime.isAfter(now) &&
          hourTime.isBefore(now.add(const Duration(hours: 6)))) {
        final chance = (h['chance_of_rain'] as num).toDouble();
        if (chance > maxRainChance) maxRainChance = chance;
      }
    }

    String? bestHour;
    double bestScore = double.infinity;
    for (final h in hours) {
      final hourTime = DateTime.parse(h['time'] as String);
      if (hourTime.isBefore(now)) continue;
      final hh = hourTime.hour;
      if (hh < 6 || hh > 18) continue;

      final hWind = (h['wind_kph'] as num).toDouble();
      final hRain = (h['chance_of_rain'] as num).toDouble();
      final score = hWind + (hRain * 0.5);

      if (score < bestScore &&
          hWind < windWarningKph &&
          hRain < rainWarningPct) {
        bestScore = score;
        bestHour = '${hourTime.hour.toString().padLeft(2, '0')}:00';
      }
    }

    return WeatherAdvisory(
      locationName: location['name'] as String,
      tempC: tempC,
      windKph: windKph,
      humidity: humidity,
      condition: condition,
      rainChancePct: maxRainChance,
      isWindy: windKph > windWarningKph,
      isRainy: maxRainChance > rainWarningPct,
      bestSprayHour: bestHour,
      windWarning: windKph > windWarningKph
          ? 'Wind ${windKph.toStringAsFixed(0)} kph \u2014 spray will drift'
          : null,
      rainWarning: maxRainChance > rainWarningPct
          ? 'Rain ${maxRainChance.toStringAsFixed(0)}% in 6h \u2014 spray will wash off'
          : null,
    );
  }
}

class WeatherAdvisory {
  final String locationName;
  final double tempC;
  final double windKph;
  final int humidity;
  final String condition;
  final double rainChancePct;
  final bool isWindy;
  final bool isRainy;
  final String? bestSprayHour;
  final String? windWarning;
  final String? rainWarning;

  const WeatherAdvisory({
    required this.locationName,
    required this.tempC,
    required this.windKph,
    required this.humidity,
    required this.condition,
    required this.rainChancePct,
    required this.isWindy,
    required this.isRainy,
    this.bestSprayHour,
    this.windWarning,
    this.rainWarning,
  });

  bool get isSafeToSpray => !isWindy && !isRainy;
}
