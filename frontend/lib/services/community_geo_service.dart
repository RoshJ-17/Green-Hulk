// lib/services/community_geo_service.dart
//
// Mock data service for:
//   • Disease outbreak pins
//   • Soil info by GPS
//   • Local shop listings
//   • Community tips feed
//   • Weekly disease summary

import 'dart:math';

class OutbreakPin {
  final String id;
  final double lat;
  final double lng;
  final String disease;
  final String crop;
  final int reports;
  final DateTime reportedAt;
  final bool isVerified;
  final String contributorBadge; // anonymized

  const OutbreakPin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.disease,
    required this.crop,
    required this.reports,
    required this.reportedAt,
    required this.isVerified,
    required this.contributorBadge,
  });
}

class SoilInfo {
  final String type;
  final String ph;
  final String moisture;
  final String diseaseRisk;
  final String riskLevel; // low / medium / high
  final String suggestion;

  const SoilInfo({
    required this.type,
    required this.ph,
    required this.moisture,
    required this.diseaseRisk,
    required this.riskLevel,
    required this.suggestion,
  });
}

class LocalShop {
  final String name;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  final List<String> inventory;

  const LocalShop({
    required this.name,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    required this.inventory,
  });
}

class CommunityTip {
  final String id;
  final String authorBadge; // anonymized e.g. "Farmer #4821"
  final String crop;
  final String tip;
  int likes;
  final DateTime postedAt;
  bool likedByMe;

  CommunityTip({
    required this.id,
    required this.authorBadge,
    required this.crop,
    required this.tip,
    required this.likes,
    required this.postedAt,
    this.likedByMe = false,
  });
}

class DiseaseWeeklyStat {
  final String disease;
  final int cases;
  final Color color;

  const DiseaseWeeklyStat({
    required this.disease,
    required this.cases,
    required this.color,
  });
}

import 'package:flutter/material.dart';

class CommunityGeoService {
  static final CommunityGeoService _instance = CommunityGeoService._();
  factory CommunityGeoService() => _instance;
  CommunityGeoService._();

  // Mock "current" user location (centre of mock map area)
  static const double _baseLat = 12.9716;
  static const double _baseLng = 77.5946;

  double get userLat => _baseLat;
  double get userLng => _baseLng;

  // ── Outbreak pins ──────────────────────────────────────────────────────────
  List<OutbreakPin> getOutbreakPins() => [
    OutbreakPin(
      id: 'ob1',
      lat: _baseLat + 0.018,
      lng: _baseLng - 0.012,
      disease: 'Late Blight',
      crop: 'Tomato',
      reports: 14,
      reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
      isVerified: true,
      contributorBadge: 'Farmer #3142',
    ),
    OutbreakPin(
      id: 'ob2',
      lat: _baseLat - 0.022,
      lng: _baseLng + 0.015,
      disease: 'Powdery Mildew',
      crop: 'Wheat',
      reports: 8,
      reportedAt: DateTime.now().subtract(const Duration(hours: 14)),
      isVerified: true,
      contributorBadge: 'Farmer #7809',
    ),
    OutbreakPin(
      id: 'ob3',
      lat: _baseLat + 0.031,
      lng: _baseLng + 0.024,
      disease: 'Leaf Rust',
      crop: 'Corn',
      reports: 5,
      reportedAt: DateTime.now().subtract(const Duration(days: 1)),
      isVerified: false,
      contributorBadge: 'Farmer #2256',
    ),
    OutbreakPin(
      id: 'ob4',
      lat: _baseLat - 0.008,
      lng: _baseLng - 0.031,
      disease: 'Bacterial Spot',
      crop: 'Pepper',
      reports: 11,
      reportedAt: DateTime.now().subtract(const Duration(days: 2)),
      isVerified: true,
      contributorBadge: 'Farmer #5573',
    ),
    OutbreakPin(
      id: 'ob5',
      lat: _baseLat + 0.042,
      lng: _baseLng - 0.038,
      disease: 'Downy Mildew',
      crop: 'Grapes',
      reports: 3,
      reportedAt: DateTime.now().subtract(const Duration(days: 3)),
      isVerified: false,
      contributorBadge: 'Farmer #9981',
    ),
  ];

  // ── Proximity check (within radiusKm) ─────────────────────────────────────
  List<OutbreakPin> getNearbyOutbreaks({double radiusKm = 5.0}) {
    return getOutbreakPins().where((pin) {
      final dist = _haversineKm(userLat, userLng, pin.lat, pin.lng);
      return dist <= radiusKm;
    }).toList();
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  // ── Soil info (mock GPS-based) ─────────────────────────────────────────────
  SoilInfo getSoilInfo() => const SoilInfo(
    type: 'Red Laterite Loam',
    ph: '6.2 – 6.8',
    moisture: '38%',
    diseaseRisk: 'Fungal diseases (Fusarium, Pythium)',
    riskLevel: 'medium',
    suggestion:
        'Consider a soil test to confirm pH and add lime if needed. Avoid over-irrigation to reduce fungal risk.',
  );

  // ── Local shops ───────────────────────────────────────────────────────────
  List<LocalShop> getLocalShops() => [
    LocalShop(
      name: 'Green Fields Agro Store',
      address: '14 Market Road, Jayanagar',
      phone: '+91 80 2663 1120',
      lat: _baseLat + 0.011,
      lng: _baseLng + 0.008,
      inventory: [
        'Copper Fungicide 500g',
        'Neem Oil Spray 1L',
        'NPK Fertilizer 5kg',
        'Bordeaux Mixture',
        'Thiram 75% WP',
      ],
    ),
    LocalShop(
      name: 'Kisan Krishi Kendra',
      address: '7 Agricultural Hub, Banashankari',
      phone: '+91 80 2671 4488',
      lat: _baseLat - 0.014,
      lng: _baseLng - 0.009,
      inventory: [
        'Mancozeb 75% WP 250g',
        'Propiconazole EC',
        'Bio-Pesticide Trichoderma',
        'Soil pH Tester Kit',
        'Drip Irrigation Tape',
      ],
    ),
  ];

  // ── Community tips ────────────────────────────────────────────────────────
  final List<CommunityTip> _tips = [
    CommunityTip(
      id: 't1',
      authorBadge: 'Farmer #4821',
      crop: 'Tomato',
      tip:
          'Spray copper-based fungicide early morning for best absorption. Repeat every 10 days during humid season.',
      likes: 24,
      postedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    CommunityTip(
      id: 't2',
      authorBadge: 'Farmer #6603',
      crop: 'Wheat',
      tip:
          'Rotate crops each season. Planting mustard after wheat greatly reduces rust re-infection from soil.',
      likes: 17,
      postedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    CommunityTip(
      id: 't3',
      authorBadge: 'Farmer #1192',
      crop: 'Rice',
      tip:
          'Drain fields for 3–5 days mid-season. This simple step cuts blast disease risk by nearly half.',
      likes: 31,
      postedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    CommunityTip(
      id: 't4',
      authorBadge: 'Farmer #8874',
      crop: 'Corn',
      tip:
          'Remove and burn infected leaves immediately. Do not compost — fungal spores survive and spread.',
      likes: 12,
      postedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    CommunityTip(
      id: 't5',
      authorBadge: 'Farmer #3359',
      crop: 'Potato',
      tip:
          'Late blight spreads fast in cool wet weather. Watch your forecast and pre-emptively apply Ridomil before rains.',
      likes: 20,
      postedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  List<CommunityTip> getTips({String? cropFilter}) {
    if (cropFilter == null || cropFilter == 'All') return List.from(_tips);
    return _tips.where((t) => t.crop == cropFilter).toList();
  }

  void addTip(String crop, String tipText) {
    final rng = Random();
    _tips.insert(
      0,
      CommunityTip(
        id: 't${DateTime.now().millisecondsSinceEpoch}',
        authorBadge: 'Farmer #${1000 + rng.nextInt(9000)}',
        crop: crop,
        tip: tipText,
        likes: 0,
        postedAt: DateTime.now(),
        likedByMe: false,
      ),
    );
  }

  void toggleLike(String tipId) {
    final tip = _tips.firstWhere((t) => t.id == tipId);
    tip.likedByMe = !tip.likedByMe;
    tip.likes += tip.likedByMe ? 1 : -1;
  }

  // ── Weekly summary ────────────────────────────────────────────────────────
  List<DiseaseWeeklyStat> getWeeklyStats() => [
    DiseaseWeeklyStat(disease: 'Late Blight', cases: 42, color: Colors.red.shade400),
    DiseaseWeeklyStat(disease: 'Powdery Mildew', cases: 28, color: Colors.orange.shade400),
    DiseaseWeeklyStat(disease: 'Leaf Rust', cases: 19, color: Colors.amber.shade600),
  ];
}
