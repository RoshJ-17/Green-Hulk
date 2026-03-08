class FarmerCropService {
  /// internal storage
  static final List<String> _selectedCrops = [];

  /// getter (UI will read from here)
  static List<String> get selectedCrops => _selectedCrops;

  static bool isSelected(String crop) {
    return _selectedCrops.contains(crop);
  }

  /// Single-select: clear previous selection, then add the tapped crop.
  /// If the same crop is tapped again, deselect it.
  static void toggleCrop(String crop) {
    if (_selectedCrops.contains(crop)) {
      _selectedCrops.remove(crop);
    } else {
      _selectedCrops.clear(); // enforce single selection
      _selectedCrops.add(crop);
    }
  }

  /// clear all (useful after logout / reset)
  static void clear() {
    _selectedCrops.clear();
  }
}
