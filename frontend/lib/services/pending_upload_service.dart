class PendingUploadService {
  static final List<PendingUpload> _pendingUploads = [];

  static List<PendingUpload> get pendingUploads =>
      List.unmodifiable(_pendingUploads);

  static Future<void> addPendingUpload({
    required String imagePath,
    required String cropName,
    bool heatmap = false,
  }) async {
    _pendingUploads.add(
      PendingUpload(
        imagePath: imagePath,
        cropName: cropName,
        heatmap: heatmap,
        timestamp: DateTime.now(),
      ),
    );
  }

  static void removeUpload(PendingUpload upload) {
    _pendingUploads.remove(upload);
  }

  static void clear() {
    _pendingUploads.clear();
  }
}

class PendingUpload {
  final String imagePath;
  final String cropName;
  final bool heatmap;
  final DateTime timestamp;

  PendingUpload({
    required this.imagePath,
    required this.cropName,
    this.heatmap = false,
    required this.timestamp,
  });
}
