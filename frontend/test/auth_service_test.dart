import 'package:flutter_test/flutter_test.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

void main() {
  group('AuthService Logic Tests', () {

    test('JwtDecoder correctly identifies expired token', () {
      // Example expired token (dummy format)
      final expiredToken =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
          'eyJleHAiOjE2MDAwMDAwMDB9.'
          'dummySignature';

      final isExpired = JwtDecoder.isExpired(expiredToken);

      expect(isExpired, true);
    });

  });
}
