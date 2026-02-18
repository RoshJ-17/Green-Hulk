import 'package:flutter/material.dart';

class ScanResult {
  final String id;
  final String cropName;
  final String diseaseName;
  final double confidence;
  final String imagePath;
  final bool hasDisease;
  final DateTime date;

  /// Severity level from backend (e.g., "Early Stage", "Medium", "Severe")
  final String? severity;

  /// Full label key (e.g., "Tomato___Early_blight") used to fetch treatments
  final String? fullLabel;

  /// Quality warnings from backend image analysis
  final String? qualityWarnings;

  /// User rating (1-5), null if not rated yet
  int? rating;

  ScanResult({
    String? id,
    required this.cropName,
    required this.diseaseName,
    required this.confidence,
    required this.imagePath,
    required this.hasDisease,
    DateTime? date,
    this.rating,
    this.severity,
    this.fullLabel,
    this.qualityWarnings,
  }) : id = id ?? UniqueKey().toString(),
       date = date ?? DateTime.now();
}
