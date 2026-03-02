import 'package:objectbox/objectbox.dart';
import 'objectbox_service.dart';

class PendingUploadService {
  static Box<PendingUpload> get _box => ObjectBoxService.store.box<PendingUpload>();

  static List<PendingUpload> get pendingUploads => _box.getAll();

  static Future<void> addPendingUpload({
    required String imagePath,
    required String cropName,
    bool heatmap = false,
  }) async {
    _box.put(
      PendingUpload(
        imagePath: imagePath,
        cropName: cropName,
        heatmap: heatmap,
        timestamp: DateTime.now(),
      ),
    );
  }

  static void removeUpload(PendingUpload upload) {
    if (upload.id != 0) {
      _box.remove(upload.id);
    }
  }

  static void clear() {
    _box.removeAll();
  }
}

@Entity()
class PendingUpload {
  @Id()
  int id = 0;

  final String imagePath;
  final String cropName;
  final bool heatmap;
  
  @Property(type: PropertyType.date)
  final DateTime timestamp;

  PendingUpload({
    this.id = 0,
    required this.imagePath,
    required this.cropName,
    this.heatmap = false,
    required this.timestamp,
  });
}
