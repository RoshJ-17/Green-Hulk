class FarmerCropService {
  /// internal storage
  static final List<String> _selectedCrops = [];

  /// getter (UI will read from here)
  static List<String> get selectedCrops => _selectedCrops;

  static bool isSelected(String crop) {
    return _selectedCrops.contains(crop);
  }

  /// toggle select/deselect
  static void toggleCrop(String crop) {
    if (_selectedCrops.contains(crop)) {
      _selectedCrops.remove(crop);
    } else {
      _selectedCrops.add(crop);
    }
  }

  /// clear all (useful after logout / reset)
  static void clear() {
    _selectedCrops.clear();
  }
}
