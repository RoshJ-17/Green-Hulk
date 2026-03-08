// lib/objectbox/models/app_settings.dart
//
// ObjectBox entity for persisting app settings (language, crop selection,
// first-launch flag). There is always exactly one row (id = auto-assigned).

import 'package:objectbox/objectbox.dart';

@Entity()
class AppSettingsEntity {
  @Id()
  int id = 0;

  /// BCP-47 language code, e.g. 'en', 'hi', 'ta'.
  String appLanguage = 'en';

  /// True after the user has completed language selection for the first time.
  bool hasSelectedLanguage = false;

  /// JSON-encoded list of selected crop names, e.g. '["Rice","Wheat"]'.
  String selectedCropsJson = '[]';
}
