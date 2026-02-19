import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_1/services/farmer_crop_service.dart';

void main() {
  group('FarmerCropService Unit Tests', () {

    setUp(() {
      FarmerCropService.clear();
    });

    test('initially selectedCrops is empty', () {
      expect(FarmerCropService.selectedCrops.isEmpty, true);
    });

    test('toggleCrop adds crop if not selected', () {
      FarmerCropService.toggleCrop('Tomato');

      expect(FarmerCropService.selectedCrops.contains('Tomato'), true);
      expect(FarmerCropService.isSelected('Tomato'), true);
    });

    test('toggleCrop removes crop if already selected', () {
      FarmerCropService.toggleCrop('Rice');
      FarmerCropService.toggleCrop('Rice');

      expect(FarmerCropService.selectedCrops.contains('Rice'), false);
      expect(FarmerCropService.isSelected('Rice'), false);
    });

    test('clear removes all selected crops', () {
      FarmerCropService.toggleCrop('Wheat');
      FarmerCropService.toggleCrop('Corn');

      FarmerCropService.clear();

      expect(FarmerCropService.selectedCrops.isEmpty, true);
    });

  });
}
