import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/services/pending_upload_service.dart';

void main() {
  group('PendingUploadService Unit Tests', () {

    setUp(() {
      PendingUploadService.clear();
    });

    test('addPendingUpload adds item to list', () async {
      await PendingUploadService.addPendingUpload(
        imagePath: 'image.jpg',
        cropName: 'Tomato',
      );

      expect(PendingUploadService.pendingUploads.length, 1);

      final upload = PendingUploadService.pendingUploads.first;
      expect(upload.imagePath, 'image.jpg');
      expect(upload.cropName, 'Tomato');
      expect(upload.heatmap, false);
    });

    test('heatmap flag is stored correctly', () async {
      await PendingUploadService.addPendingUpload(
        imagePath: 'img2.jpg',
        cropName: 'Rice',
        heatmap: true,
      );

      final upload = PendingUploadService.pendingUploads.first;
      expect(upload.heatmap, true);
    });

    test('removeUpload removes correct item', () async {
      await PendingUploadService.addPendingUpload(
        imagePath: 'img3.jpg',
        cropName: 'Wheat',
      );

      final upload = PendingUploadService.pendingUploads.first;
      PendingUploadService.removeUpload(upload);

      expect(PendingUploadService.pendingUploads.isEmpty, true);
    });

    test('clear removes all pending uploads', () async {
      await PendingUploadService.addPendingUpload(
        imagePath: 'img4.jpg',
        cropName: 'Corn',
      );

      PendingUploadService.clear();

      expect(PendingUploadService.pendingUploads.isEmpty, true);
    });

  });
}
