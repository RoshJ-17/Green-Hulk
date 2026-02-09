class ScanResult {
  final String cropName;
  final String diseaseName;
  final double confidence;
  final String imagePath;
  final bool hasDisease;

  ScanResult({
    required this.cropName,
    required this.diseaseName,
    required this.confidence,
    required this.imagePath,
    required this.hasDisease,
    DateTime? date,
  }) : date = date ?? DateTime.now();
  
  final DateTime date;
}
