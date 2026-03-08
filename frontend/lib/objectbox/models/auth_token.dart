// lib/objectbox/models/auth_token.dart
//
// ObjectBox entity for persisting authentication state.
// There is always at most one row (id = auto-assigned).

import 'package:objectbox/objectbox.dart';

@Entity()
class AuthTokenEntity {
  @Id()
  int id = 0;

  /// JWT access token string.
  String token = '';

  /// JSON-encoded user data map returned by the auth API.
  String userDataJson = '{}';
}
