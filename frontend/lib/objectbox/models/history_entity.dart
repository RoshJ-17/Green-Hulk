import 'package:objectbox/objectbox.dart';
import '../../models/scan_result.dart';
import 'dart:convert';

@Entity()
class HistoryEntity {
  @Id()
  int id = 0;

  String jsonPayload; // Store the whole ScanResult object as JSON
  
  HistoryEntity({required this.jsonPayload});

  ScanResult toScanResult() {
    return ScanResult.fromJson(jsonDecode(jsonPayload));
  }
}