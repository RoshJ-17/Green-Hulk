// lib/config/crop_data.dart
//
// Single source of truth for all supported crops.
// Import this everywhere instead of redefining the list.

const List<Map<String, String>> kCrops = [
  {'name': 'Apple',      'asset': 'assets/icons/apple.jpg'},
  {'name': 'Blueberry',  'asset': 'assets/icons/blueberry.jpg'},
  {'name': 'Cherry',     'asset': 'assets/icons/cherry.jpg'},
  {'name': 'Corn',       'asset': 'assets/icons/corn.png'},
  {'name': 'Grape',      'asset': 'assets/icons/grapes.jpg'},
  {'name': 'Orange',     'asset': 'assets/icons/orange.jpg'},
  {'name': 'Peach',      'asset': 'assets/icons/peach.jpg'},
  {'name': 'Pepper',     'asset': 'assets/icons/pepper.jpg'},
  {'name': 'Potato',     'asset': 'assets/icons/potato.jpg'},
  {'name': 'Raspberry',  'asset': 'assets/icons/raspberry.jpg'},
  {'name': 'Soybean',    'asset': 'assets/icons/soyabean.jpg'},
  {'name': 'Squash',     'asset': 'assets/icons/squash.jpg'},
  {'name': 'Strawberry', 'asset': 'assets/icons/strawberry.jpg'},
  {'name': 'Tomato',     'asset': 'assets/icons/tomato.png'},
];

/// Lookup the asset path for a given crop name. Returns null if not found.
String? cropAsset(String cropName) {
  for (final c in kCrops) {
    if (c['name'] == cropName) return c['asset'];
  }
  return null;
}
