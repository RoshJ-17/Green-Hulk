// lib/screens/map_screen.dart
// Works on Chrome (web) AND Android/iOS via google_maps_flutter + google_maps_flutter_web

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../services/localization_service.dart';
import '../services/gemini_translation_service.dart';
import '../theme/app_theme.dart';
import '../utils/geo_utils.dart';

// ── Models ────────────────────────────────────────────────────────────────

class OutbreakPin {
  final String id;
  final double lat, lng;
  final String disease, crop, contributorBadge;
  final int reports;
  final DateTime reportedAt;
  final bool isVerified;
  const OutbreakPin({
    required this.id, required this.lat, required this.lng,
    required this.disease, required this.crop, required this.reports,
    required this.reportedAt, required this.isVerified, required this.contributorBadge,
  });
}

class LocalShop {
  final String name, address, phone;
  final double lat, lng;
  final List<String> inventory;
  const LocalShop({
    required this.name, required this.address, required this.phone,
    required this.lat, required this.lng, required this.inventory,
  });
}

class CommunityTip {
  final String id, authorBadge, crop, tip;
  int likes;
  final DateTime postedAt;
  bool likedByMe;
  CommunityTip({
    required this.id, required this.authorBadge, required this.crop,
    required this.tip, required this.likes, required this.postedAt,
    this.likedByMe = false,
  });
}

class DiseaseWeeklyStat {
  final String disease;
  final int cases;
  final Color color;
  const DiseaseWeeklyStat({required this.disease, required this.cases, required this.color});
}

// ── Mock Data ─────────────────────────────────────────────────────────────

const _baseLat = 12.9716;
const _baseLng = 77.5946;

List<OutbreakPin> _mockPins() => [
  OutbreakPin(id: 'ob1', lat: _baseLat + 0.018, lng: _baseLng - 0.012,
    disease: 'Late Blight', crop: 'Tomato', reports: 14,
    reportedAt: DateTime.now().subtract(const Duration(hours: 6)),
    isVerified: true, contributorBadge: 'Farmer #3142'),
  OutbreakPin(id: 'ob2', lat: _baseLat - 0.022, lng: _baseLng + 0.015,
    disease: 'Powdery Mildew', crop: 'Wheat', reports: 8,
    reportedAt: DateTime.now().subtract(const Duration(hours: 14)),
    isVerified: true, contributorBadge: 'Farmer #7809'),
  OutbreakPin(id: 'ob3', lat: _baseLat + 0.031, lng: _baseLng + 0.024,
    disease: 'Leaf Rust', crop: 'Corn', reports: 5,
    reportedAt: DateTime.now().subtract(const Duration(days: 1)),
    isVerified: false, contributorBadge: 'Farmer #2256'),
  OutbreakPin(id: 'ob4', lat: _baseLat - 0.008, lng: _baseLng - 0.031,
    disease: 'Bacterial Spot', crop: 'Pepper', reports: 11,
    reportedAt: DateTime.now().subtract(const Duration(days: 2)),
    isVerified: true, contributorBadge: 'Farmer #5573'),
  OutbreakPin(id: 'ob5', lat: _baseLat + 0.042, lng: _baseLng - 0.038,
    disease: 'Downy Mildew', crop: 'Grapes', reports: 3,
    reportedAt: DateTime.now().subtract(const Duration(days: 3)),
    isVerified: false, contributorBadge: 'Farmer #9981'),
];

List<LocalShop> _mockShops() => [
  const LocalShop(
    name: 'Green Fields Agro Store', address: '14 Market Road, Jayanagar',
    phone: '+91 80 2663 1120', lat: _baseLat + 0.011, lng: _baseLng + 0.008,
    inventory: ['Copper Fungicide 500g', 'Neem Oil Spray 1L', 'NPK Fertilizer 5kg', 'Bordeaux Mixture', 'Thiram 75% WP'],
  ),
  const LocalShop(
    name: 'Kisan Krishi Kendra', address: '7 Agricultural Hub, Banashankari',
    phone: '+91 80 2671 4488', lat: _baseLat - 0.014, lng: _baseLng - 0.009,
    inventory: ['Mancozeb 75% WP 250g', 'Propiconazole EC', 'Bio-Pesticide Trichoderma', 'Soil pH Tester Kit', 'Drip Irrigation Tape'],
  ),
];

double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  return R * 2 * atan2(sqrt(a), sqrt(1 - a));
}

// ── MapScreen ─────────────────────────────────────────────────────────────

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _alertDismissed = false;
  bool _showContributorBadge = false;
  String _tipFilter = 'All';
  final _tipController = TextEditingController();
  String _writeTipCrop = 'Tomato';
  GoogleMapController? _mapController;
  bool _mapLoadError = false;

  BitmapDescriptor _verifiedMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  BitmapDescriptor _pendingMarker  = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
  BitmapDescriptor _shopMarker     = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  bool _iconsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only load once
    if (!_iconsLoaded) {
      _iconsLoaded = true;
      _loadMarkerIcons();
    }
  }

  Future<void> _loadMarkerIcons() async {
    final verified = await _createMarkerBitmap(
      bgColor: const Color(0xFFD32F2F),
      icon: Icons.warning_amber_rounded,
    );
    final pending = await _createMarkerBitmap(
      bgColor: const Color(0xFFF57C00),
      icon: Icons.warning_amber_rounded,
    );
    final shop = await _createMarkerBitmap(
      bgColor: const Color(0xFF2E7D32),
      icon: Icons.store,
    );
    if (mounted) {
      setState(() {
        _verifiedMarker = verified;
        _pendingMarker  = pending;
        _shopMarker     = shop;
      });
    }
  }

  Future<BitmapDescriptor> _createMarkerBitmap({
    required Color bgColor,
    required IconData icon,
  }) async {
    const size = 80.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = bgColor;

    // Draw pin circle
    canvas.drawCircle(const Offset(size / 2, size / 2 - 6), size / 2 - 4, paint);

    // Draw pin tail
    final tailPath = Path()
      ..moveTo(size / 2 - 10, size / 2 + 16)
      ..lineTo(size / 2 + 10, size / 2 + 16)
      ..lineTo(size / 2, size - 4)
      ..close();
    canvas.drawPath(tailPath, paint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(const Offset(size / 2, size / 2 - 6), size / 2 - 4, borderPaint);

    // Draw icon inside
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 30,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    tp.layout();
    tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2 - 10));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Set<Marker> get _markers {
    final markers = <Marker>{};
    for (final pin in _mockPins()) {
      markers.add(Marker(
        markerId: MarkerId(pin.id),
        position: LatLng(pin.lat, pin.lng),
        icon: pin.isVerified ? _verifiedMarker : _pendingMarker,
        infoWindow: InfoWindow(
            title: '${pin.disease} on ${pin.crop}', snippet: '${pin.reports} reports'),
        onTap: () => _showOutbreakBottomSheet(pin),
      ));
    }
    for (final shop in _mockShops()) {
      markers.add(Marker(
        markerId: MarkerId('shop_${shop.name}'),
        position: LatLng(shop.lat, shop.lng),
        icon: _shopMarker,
        infoWindow: InfoWindow(title: shop.name, snippet: shop.address),
        onTap: () => _showShopBottomSheet(shop),
      ));
    }
    return markers;
  }

  Set<Circle> get _circles => {
    Circle(
      circleId: const CircleId('radius_5km'),
      center: const LatLng(_baseLat, _baseLng),
      radius: 5000,
      strokeColor: Colors.blue.withValues(alpha: 0.4),
      strokeWidth: 1,
      fillColor: Colors.blue.withValues(alpha: 0.05),
    ),
  };

  final List<CommunityTip> _tips = [
    CommunityTip(id: 't1', authorBadge: 'Farmer #4821', crop: 'Tomato',
      tip: 'Spray copper-based fungicide early morning for best absorption. Repeat every 10 days during humid season.',
      likes: 24, postedAt: DateTime.now().subtract(const Duration(hours: 3))),
    CommunityTip(id: 't2', authorBadge: 'Farmer #6603', crop: 'Wheat',
      tip: 'Rotate crops each season. Planting mustard after wheat greatly reduces rust re-infection from soil.',
      likes: 17, postedAt: DateTime.now().subtract(const Duration(days: 1))),
    CommunityTip(id: 't3', authorBadge: 'Farmer #1192', crop: 'Rice',
      tip: 'Drain fields for 3-5 days mid-season. This simple step cuts blast disease risk by nearly half.',
      likes: 31, postedAt: DateTime.now().subtract(const Duration(days: 2))),
    CommunityTip(id: 't4', authorBadge: 'Farmer #8874', crop: 'Corn',
      tip: 'Remove and burn infected leaves immediately. Do not compost — fungal spores survive and spread.',
      likes: 12, postedAt: DateTime.now().subtract(const Duration(days: 3))),
    CommunityTip(id: 't5', authorBadge: 'Farmer #3359', crop: 'Potato',
      tip: 'Late blight spreads fast in cool wet weather. Pre-emptively apply Ridomil before forecast rains.',
      likes: 20, postedAt: DateTime.now().subtract(const Duration(days: 4))),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tipController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _weekRange() {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return '${start.day}/${start.month} to ${end.day}/${end.month}';
  }

  List<OutbreakPin> get _nearbyOutbreaks =>
      _mockPins().where((p) => _haversineKm(_baseLat, _baseLng, p.lat, p.lng) <= 5.0).toList();

  // ── Proximity Alert ───────────────────────────────────────────────────

  Widget _buildProximityAlert() {
    final appState = context.read<AppState>();
    final nearby = _nearbyOutbreaks;
    if (nearby.isEmpty || _alertDismissed) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.orange.shade600],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${nearby.length} ${appState.tr(nearby.length > 1 ? 'map_outbreaks' : 'map_outbreak')} ${appState.tr('map_within_5km')}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _alertDismissed = true),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${appState.trDisease(nearby.first.disease)} ${appState.tr('map_on')} ${appState.trCrop(nearby.first.crop)} ${appState.tr('map_detected_near')}. ${appState.tr('map_take_preventive')}.',
              style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPreventNowDialog(nearby.first),
                    icon: const Icon(Icons.health_and_safety, size: 15),
                    label: Text(context.read<AppState>().tr('map_prevent_now')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _alertDismissed = true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: Size.zero,
                    ),
                    child: Text(context.read<AppState>().tr('map_dismiss'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPreventNowDialog(OutbreakPin pin) {
    final appState = context.read<AppState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_outlined, color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            Text(appState.tr('map_prevention_guide'), style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv(appState.tr('map_disease_label'), appState.trDisease(pin.disease)),
            _kv(appState.tr('map_crop_label'), appState.trCrop(pin.crop)),
            const Divider(height: 20),
            Text(appState.tr('map_recommended_actions'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            _bullet(appState.tr('map_prevent_action_1')),
            _bullet(appState.tr('map_prevent_action_2')),
            _bullet(appState.tr('map_prevent_action_3')),
            _bullet(appState.tr('map_prevent_action_4')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appState.tr('map_got_it'), style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Text('$k: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Text(v, style: const TextStyle(fontSize: 13)),
      ],
    ),
  );

  Widget _bullet(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 8),
          width: 6, height: 6,
          decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
        ),
        Expanded(child: Text(t, style: const TextStyle(fontSize: 13, height: 1.4))),
      ],
    ),
  );

  // ── Map Tab ───────────────────────────────────────────────────────────

  Widget _buildMapTab() {
    final appState = context.read<AppState>();
    // Show setup instructions if map failed to load (invalid API key)
    if (_mapLoadError && kIsWeb) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.map_outlined, size: 56, color: Colors.orange.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'Google Maps API Key Required',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'To enable the map on web, add your Google Maps API key:',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'web/index.html\n<script src="...maps...key=YOUR_KEY">',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '1. Go to console.cloud.google.com\n2. Enable "Maps JavaScript API"\n3. Create API Key\n4. Replace YOUR_GOOGLE_MAPS_API_KEY in web/index.html',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.8),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Post to Map — top right (still functional)
          Positioned(
            top: 12, right: 12,
            child: ElevatedButton.icon(
              onPressed: _showPostToMapDialog,
              icon: const Icon(Icons.add_location_alt, size: 15),
              label: Text(context.read<AppState>().tr('map_post_tip')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: Size.zero,
                elevation: 3,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(_baseLat, _baseLng),
            zoom: 13.5,
          ),
          onMapCreated: (c) {
            _mapController = c;
            // On web, if map loaded successfully, clear any previous error
            if (_mapLoadError) setState(() => _mapLoadError = false);
          },
          markers: _markers,
          circles: _circles,
          myLocationEnabled: !kIsWeb,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
        ),
        // Legend — top left
        Positioned(
          top: 12, left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Legend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black54)),
                const SizedBox(height: 6),
                _legendRow(Colors.red.shade700, Icons.warning_amber_rounded, appState.tr('map_legend_verified')),
                _legendRow(Colors.orange.shade700, Icons.warning_amber_rounded, appState.tr('map_legend_pending')),
                _legendRow(Colors.green.shade800, Icons.store, appState.tr('map_legend_agro_shop')),
              ],
            ),
          ),
        ),
        // Post to Map — top right
        Positioned(
          top: 12, right: 12,
          child: ElevatedButton.icon(
            onPressed: _showPostToMapDialog,
            icon: const Icon(Icons.add_location_alt, size: 15),
            label: Text(context.read<AppState>().tr('map_post_tip')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: Size.zero,
              elevation: 3,
            ),
          ),
        ),
        // My Location FAB — bottom right (raised above the floating bottom navbar ~96px)
        Positioned(
          bottom: 100, right: 12,
          child: FloatingActionButton.small(
            heroTag: 'myLoc',
            backgroundColor: Colors.white,
            elevation: 4,
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(
                  const CameraPosition(target: LatLng(_baseLat, _baseLng), zoom: 14),
                ),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Centred on your location'), duration: Duration(seconds: 2)),
              );
            },
            child: const Icon(Icons.my_location, color: AppTheme.primaryGreen),
          ),
        ),
      ],
    );
  }

  Widget _legendRow(Color c, IconData icon, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Colors.black87))),
      ],
    ),
  );

  void _showOutbreakBottomSheet(OutbreakPin pin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OutbreakBottomSheet(
        pin: pin,
        timeAgo: _timeAgo(pin.reportedAt),
        onPrevent: () {
          Navigator.pop(context);
          _showPreventNowDialog(pin);
        },
      ),
    );
  }

  void _showShopBottomSheet(LocalShop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShopBottomSheet(shop: shop),
    );
  }

  void _showPostToMapDialog() {
    final appState = context.read<AppState>();
    String sCrop = 'Tomato', sDis = 'Late Blight';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_location_alt, color: AppTheme.primaryGreen, size: 20),
              ),
              const SizedBox(width: 10),
              Text(appState.tr('map_report_disease'), style: const TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: Colors.blue.shade600),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        appState.tr('map_post_anon_note'),
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _dropdown('Crop', ['Tomato','Wheat','Corn','Potato','Rice','Pepper'], sCrop, (v) => setDs(() => sCrop = v!)),
              const SizedBox(height: 10),
              _dropdown('Disease', ['Late Blight','Powdery Mildew','Leaf Rust','Bacterial Spot','Downy Mildew'], sDis, (v) => setDs(() => sDis = v!)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${appState.tr('map_posting_as')}: Farmer #${1000 + Random().nextInt(9000)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(appState.tr('map_cancel'), style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _showContributorBadge = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.verified, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(child: Text(appState.tr('map_report_badge_earned'))),
                      ],
                    ),
                    backgroundColor: AppTheme.primaryGreen,
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(appState.tr('map_confirm_report'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(String label, List<String> items, String val, void Function(String?) cb) =>
    DropdownButtonFormField<String>(
      value: val,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true, filled: true, fillColor: Colors.grey.shade50,
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: cb,
    );

  // ── Soil Tab ──────────────────────────────────────────────────────────

  Widget _buildSoilTab() {
    final appState = context.read<AppState>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppTheme.primaryGreen.withValues(alpha: 0.1),
                AppTheme.lightGreen.withValues(alpha: 0.15),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: AppTheme.primaryGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    appState.tr('map_soil_gps_fetch'),
                    style: const TextStyle(fontSize: 13, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(appState.tr('map_soil_info'), Icons.terrain, Column(
            children: [
              _soilRow(Icons.category_outlined, appState.tr('map_soil_type'), appState.tr('map_soil_type_val')),
              _soilRow(Icons.science_outlined, appState.tr('map_ph_range'), '6.2 to 6.8'),
              _soilRow(Icons.water_drop_outlined, appState.tr('map_moisture'), '38%'),
            ],
          )),
          const SizedBox(height: 12),
          _card(appState.tr('map_disease_risk'), Icons.bug_report_outlined, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${appState.tr('map_risk_level')}: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Text(appState.tr('map_risk_medium').toUpperCase(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(appState.tr('map_soil_fungal_risk'),
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          )),
          const SizedBox(height: 12),
          _card(appState.tr('map_recommendation'), Icons.lightbulb_outline, Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appState.tr('map_soil_rec_msg'),
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showSoilTestDialog,
                  icon: const Icon(Icons.biotech, size: 18),
                  label: Text(appState.tr('map_request_test')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _soilRow(IconData icon, String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.lightGreen.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 10),
        Flexible(flex: 2, child: Text('$k: ', overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        Flexible(flex: 3, child: Text(v, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  void _showSoilTestDialog() {
    final appState = context.read<AppState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.biotech, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(appState.tr('map_soil_test_request')),
          ],
        ),
        content: Text(
          appState.tr('map_soil_test_msg'),
          style: const TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appState.tr('map_cancel'), style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(appState.tr('map_soil_test_sent')), backgroundColor: AppTheme.primaryGreen),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(appState.tr('map_request_test'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Tips Tab ──────────────────────────────────────────────────────────

  Widget _buildTipsTab() {
    final appState = context.read<AppState>();
    final langCode = appState.locale.languageCode;
    final crops = ['All','Tomato','Wheat','Rice','Corn','Potato','Pepper'];
    final filtered = _tipFilter == 'All' ? _tips : _tips.where((t) => t.crop == _tipFilter).toList();
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: crops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (_, i) {
              final c = crops[i];
              final sel = _tipFilter == c;
              return FilterChip(
                label: Text(
                  c == 'All' ? appState.tr('all') : L10nService.trCrop(c, langCode),
                  style: TextStyle(fontSize: 12, color: sel ? Colors.white : AppTheme.primaryGreen, fontWeight: FontWeight.w600)
                ), // display translated, filter key stays English
                selected: sel,
                onSelected: (_) => setState(() => _tipFilter = c),
                selectedColor: AppTheme.primaryGreen,
                backgroundColor: AppTheme.lightGreen.withValues(alpha: 0.15),
                checkmarkColor: Colors.white,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note, color: AppTheme.primaryGreen, size: 20),
                      const SizedBox(width: 6),
                      const Text('Share a Tip', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 14)),
                      const Spacer(),
                      SizedBox(
                        width: 110,
                        child: DropdownButtonFormField<String>(
                          value: _writeTipCrop,
                          isDense: true,
                          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
                          items: ['Tomato','Wheat','Rice','Corn','Potato','Pepper']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                              .toList(),
                          onChanged: (v) => setState(() => _writeTipCrop = v!),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tipController,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Share your farming experience...',
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: AppTheme.primaryGreen)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _submitTip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                          minimumSize: Size.zero,
                        ),
                        child: const Text('Post', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tips_and_updates_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('No tips for $_tipFilter yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildTipCard(filtered[i]),
                ),
        ),
      ],
    );
  }

  void _submitTip() {
    final text = _tipController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tips.insert(0, CommunityTip(
        id: 'u${DateTime.now().millisecondsSinceEpoch}',
        authorBadge: 'Farmer #${1000 + Random().nextInt(9000)}',
        crop: _writeTipCrop, tip: text, likes: 0, postedAt: DateTime.now(),
      ));
    });
    _tipController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.read<AppState>().tr('map_tip_posted')), backgroundColor: AppTheme.primaryGreen),
    );
  }

  Widget _buildTipCard(CommunityTip tip) {
    final appState = context.read<AppState>();
    final langCode = appState.locale.languageCode;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.lightGreen.withValues(alpha: 0.35),
                child: const Icon(Icons.person, size: 18, color: AppTheme.primaryGreen),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tip.authorBadge, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
                  Text(_timeAgo(tip.postedAt), style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(L10nService.trCrop(tip.crop, langCode), style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tip text — translated via Gemini (cache keeps subsequent builds instant)
          FutureBuilder<String>(
            future: GeminiTranslationService.translate(tip.tip, langCode),
            initialData: tip.tip,
            builder: (_, snap) => Text(snap.data!, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() {
              tip.likedByMe = !tip.likedByMe;
              tip.likes += tip.likedByMe ? 1 : -1;
            }),
            child: Row(
              children: [
                Icon(tip.likedByMe ? Icons.favorite : Icons.favorite_border,
                    size: 20, color: tip.likedByMe ? Colors.red : Colors.grey),
                const SizedBox(width: 5),
                Text('${tip.likes}', style: TextStyle(
                    color: tip.likedByMe ? Colors.red : Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 4),
                Text(appState.tr('map_helpful'), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shops Tab ─────────────────────────────────────────────────────────

  Widget _buildShopsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _mockShops().length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildShopCard(_mockShops()[i]),
    );
  }

Widget _buildShopCard(LocalShop shop) {
  final appState = context.read<AppState>();
  final langCode = appState.locale.languageCode;

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.store, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen)),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 3),
                          Expanded(child: Text(shop.address, style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.phone, color: Colors.green.shade700, size: 16),
                ),
                const SizedBox(width: 10),
                Text(shop.phone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${appState.tr('map_calling')} ${shop.phone}...')),
                  ),
                  icon: const Icon(Icons.call, size: 15),
                  label: Text(context.read<AppState>().tr('map_call_shop')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.primaryGreen),
                    const SizedBox(width: 6),
                    Text(appState.tr('map_in_stock'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryGreen)),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: shop.inventory.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lightGreen.withValues(alpha: 0.5)),
                    ),
                    child: FutureBuilder<String>(
                      future: GeminiTranslationService.translate(item, langCode),
                      initialData: item,
                      builder: (_, snap) => Text(snap.data!, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Weekly Tab ────────────────────────────────────────────────────────

  Widget _buildWeeklyTab() {
    final appState = context.read<AppState>();
    final stats = [
      DiseaseWeeklyStat(disease: 'Late Blight', cases: 42, color: Colors.red.shade400),
      DiseaseWeeklyStat(disease: 'Powdery Mildew', cases: 28, color: Colors.orange.shade400),
      DiseaseWeeklyStat(disease: 'Leaf Rust', cases: 19, color: Colors.amber.shade600),
    ];
    final total = stats.fold<int>(0, (s, e) => s + e.cases);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.accentGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: AppTheme.primaryGreen.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.bar_chart, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.tr('map_weekly_report'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Week of ${_weekRange()}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(appState.tr('map_top3_diseases'), Icons.bar_chart, Column(
            children: stats.map((s) {
              final pct = s.cases / total;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Flexible(child: Text(s.disease, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(color: s.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: Text('${s.cases} cases', style: TextStyle(color: s.color, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: pct, minHeight: 10,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(s.color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🌿', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appState.tr('map_stay_safe'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF795548))),
                      const SizedBox(height: 6),
                      Text(
                        appState.tr('map_stay_safe_msg'),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF795548), height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _shareSummary,
              icon: const Icon(Icons.share, size: 18),
              label: Text(appState.tr('map_share_summary')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareSummary() {
    Clipboard.setData(const ClipboardData(
      text: 'Weekly Crop Disease Report\n\nLate Blight: 42 cases\nPowdery Mildew: 28 cases\nLeaf Rust: 19 cases\n\nCropGuard App',
    ));
    final appState = context.read<AppState>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(appState.tr('map_summary_copied')), backgroundColor: AppTheme.primaryGreen),
    );
  }

  Widget _card(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryGreen, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(title, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryGreen))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(appState.tr('crop_health_map'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_showContributorBadge)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified, color: Colors.amber, size: 16),
                  SizedBox(width: 3),
                  Text('Contributor', style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: const Icon(Icons.map_outlined, size: 18), text: appState.tr('map_tab_map')),
            Tab(icon: const Icon(Icons.terrain, size: 18), text: appState.tr('map_tab_soil')),
            Tab(icon: const Icon(Icons.lightbulb_outline, size: 18), text: appState.tr('map_tab_tips')),
            Tab(icon: const Icon(Icons.store_outlined, size: 18), text: appState.tr('map_tab_shops')),
            Tab(icon: const Icon(Icons.bar_chart, size: 18), text: appState.tr('map_tab_weekly')),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildProximityAlert(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildSoilTab(),
                _buildTipsTab(),
                _buildShopsTab(),
                _buildWeeklyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Outbreak Bottom Sheet ─────────────────────────────────────────────────

class _OutbreakBottomSheet extends StatelessWidget {
  final OutbreakPin pin;
  final String timeAgo;
  final VoidCallback onPrevent;
  const _OutbreakBottomSheet({required this.pin, required this.timeAgo, required this.onPrevent});

  @override
  Widget build(BuildContext context) {
    final color = pin.isVerified ? Colors.red.shade600 : Colors.orange.shade600;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.warning_amber_rounded, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pin.disease, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Crop: ${pin.crop}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: pin.isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: pin.isVerified ? Colors.green.shade300 : Colors.orange.shade300),
                      ),
                      child: Text(
                        pin.isVerified ? 'Verified' : 'Pending',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: pin.isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _infoRow(Icons.people_outline, 'Reports', '${pin.reports} farmers'),
                _infoRow(Icons.person_outline, 'Reported by', pin.contributorBadge),
                _infoRow(Icons.access_time, 'Reported', timeAgo),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPrevent,
                        icon: const Icon(Icons.health_and_safety, size: 18),
                        label: Text(context.read<AppState>().tr('map_prevent_now')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
      ],
    ),
  );
}

// ── Shop Bottom Sheet ─────────────────────────────────────────────────────

class _ShopBottomSheet extends StatelessWidget {
  final LocalShop shop;
  const _ShopBottomSheet({required this.shop});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();
    final langCode = appState.locale.languageCode;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.store, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 3),
                              Expanded(child: Text(shop.address, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.phone, color: Colors.green.shade700, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(shop.phone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(appState.tr('map_in_stock'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: shop.inventory.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lightGreen.withValues(alpha: 0.5)),
                    ),
                    child: FutureBuilder<String>(
                      future: GeminiTranslationService.translate(item, langCode),
                      initialData: item,
                      builder: (_, snap) => Text(snap.data!, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${appState.tr('map_calling')} ${shop.phone}...')),
                          );
                        },
                        icon: const Icon(Icons.call, size: 18),
                        label: Text(appState.tr('map_call_shop')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(appState.tr('map_close'), style: const TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Outbreak Bottom Sheet ─────────────────────────────────────────────────

class _OutbreakBottomSheet extends StatelessWidget {
  final OutbreakPin pin;
  final String timeAgo;
  final VoidCallback onPrevent;
  const _OutbreakBottomSheet({required this.pin, required this.timeAgo, required this.onPrevent});

  @override
  Widget build(BuildContext context) {
    final color = pin.isVerified ? Colors.red.shade600 : Colors.orange.shade600;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.warning_amber_rounded, color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pin.disease, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Crop: ${pin.crop}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: pin.isVerified ? Colors.green.shade50 : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: pin.isVerified ? Colors.green.shade300 : Colors.orange.shade300),
                      ),
                      child: Text(
                        pin.isVerified ? 'Verified' : 'Pending',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: pin.isVerified ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _infoRow(Icons.people_outline, 'Reports', '${pin.reports} farmers'),
                _infoRow(Icons.person_outline, 'Reported by', pin.contributorBadge),
                _infoRow(Icons.access_time, 'Reported', timeAgo),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onPrevent,
                        icon: const Icon(Icons.health_and_safety, size: 18),
                        label: const Text('Prevent Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
      ],
    ),
  );
}

// ── Shop Bottom Sheet ─────────────────────────────────────────────────────

class _ShopBottomSheet extends StatelessWidget {
  final LocalShop shop;
  const _ShopBottomSheet({required this.shop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.store, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                              const SizedBox(width: 3),
                              Expanded(child: Text(shop.address, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.phone, color: Colors.green.shade700, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(shop.phone, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('In Stock:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryGreen)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: shop.inventory.map((item) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.lightGreen.withValues(alpha: 0.5)),
                    ),
                    child: Text(item, style: const TextStyle(fontSize: 11, color: AppTheme.primaryGreen, fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${shop.phone}...')),
                          );
                        },
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call Shop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Colors.grey)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}