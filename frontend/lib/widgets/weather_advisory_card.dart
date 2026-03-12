// lib/widgets/weather_advisory_card.dart
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;
import '../services/weather_service.dart';

/// A card that shows spray-weather advisories on the treatment screen.
class WeatherAdvisoryCard extends StatefulWidget {
  const WeatherAdvisoryCard({super.key});

  @override
  State<WeatherAdvisoryCard> createState() => _WeatherAdvisoryCardState();
}

class _WeatherAdvisoryCardState extends State<WeatherAdvisoryCard> {
  WeatherAdvisory? _advisory;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    try {
      double? lat, lng;
      try {
        final location = loc.Location();
        final perm = await location.hasPermission();
        if (perm == loc.PermissionStatus.granted ||
            perm == loc.PermissionStatus.grantedLimited) {
          final locData = await location.getLocation();
          lat = locData.latitude;
          lng = locData.longitude;
        }
      } catch (_) {
        // Fall through to IP-based lookup
      }
      final advisory = await WeatherService.getSprayAdvisory(
        latitude: lat,
        longitude: lng,
      );
      if (mounted) {
        setState(() {
          _advisory = advisory;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Weather unavailable';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_error != null || _advisory == null) {
      return const SizedBox.shrink();
    }

    final adv = _advisory!;
    final isSafe = adv.isSafeToSpray;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSafe
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.orange.shade50, Colors.red.shade50],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSafe ? Colors.green.shade300 : Colors.orange.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isSafe ? Icons.check_circle : Icons.warning_amber_rounded,
                color: isSafe ? Colors.green : Colors.orange,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSafe
                      ? 'Good Conditions to Spray'
                      : 'Spray Advisory \u26a0\ufe0f',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isSafe
                        ? Colors.green.shade800
                        : Colors.orange.shade800,
                  ),
                ),
              ),
              Text(
                '${adv.locationName} ${adv.tempC.toStringAsFixed(0)}\u00b0C',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Weather stats row
          Row(
            children: [
              _statChip(Icons.air, '${adv.windKph.toStringAsFixed(0)} kph',
                  adv.isWindy ? Colors.red : Colors.green),
              const SizedBox(width: 8),
              _statChip(
                  Icons.water_drop,
                  '${adv.rainChancePct.toStringAsFixed(0)}%',
                  adv.isRainy ? Colors.red : Colors.green),
              const SizedBox(width: 8),
              _statChip(Icons.water, '${adv.humidity}% RH', Colors.blue),
            ],
          ),

          // Warnings
          if (adv.windWarning != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.air, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(adv.windWarning!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ],
          if (adv.rainWarning != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.umbrella, color: Colors.red, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(adv.rainWarning!,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.red)),
                ),
              ],
            ),
          ],

          // Best spray hour
          if (adv.bestSprayHour != null) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule,
                      color: Colors.green, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Best spray time: ${adv.bestSprayHour}',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
