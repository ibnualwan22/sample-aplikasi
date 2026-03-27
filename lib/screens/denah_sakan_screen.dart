import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

enum SakanType { umum, banin, banat }

class SakanLocation {
  final String name;
  final double lat;
  final double lng;
  final SakanType type;

  const SakanLocation({
    required this.name,
    required this.lat,
    required this.lng,
    required this.type,
  });

  LatLng get coord => LatLng(lat, lng);
}

class DenahSakanScreen extends StatefulWidget {
  const DenahSakanScreen({super.key});

  @override
  State<DenahSakanScreen> createState() => _DenahSakanScreenState();
}

class _DenahSakanScreenState extends State<DenahSakanScreen> {
  final MapController _mapController = MapController();
  SakanType? _selectedFilter;

  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStream;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
      ).listen((Position position) {
        if (mounted) {
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
          });
        }
      });
    } catch (_) {}
  }

  Future<void> _getRoute(LatLng destination) async {
    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi saat ini belum tersedia, pastikan GPS aktif.')),
      );
      return;
    }

    setState(() => _isLoadingRoute = true);

    try {
      final start = _currentLocation!;
      final url = 'http://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}?geometries=geojson';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates'] as List;
        
        setState(() {
          _routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        });

        // Fit bounds
        final bounds = LatLngBounds.fromPoints([start, destination, ..._routePoints]);
        _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  // Colors
  static const kBgDark = Color(0xFF0A0A0A);
  static const kBgCard = Color(0xFF181818);
  static const kGold = Color(0xFFD4AF37);
  static const kGoldLight = Color(0xFFEDD56A);
  static const kGoldDim = Color(0xFF3A2E0A);
  static const kTextPri = Colors.white;
  static const kTextSec = Color(0xFFAAAAAA);

  static const List<SakanLocation> _allLocations = [
    SakanLocation(name: "Maktab/qo’ah baharun", lat: -7.7532991298009355, lng: 112.18303767163134, type: SakanType.umum),
    SakanLocation(name: "Al- Habsyi", lat: -7.753409104044285, lng: 112.18327723672631, type: SakanType.banin),
    SakanLocation(name: "Al hadad", lat: -7.753183864935693, lng: 112.18309216430697, type: SakanType.banat),
    SakanLocation(name: "Al aidit", lat: -7.753005938403868, lng: 112.18358749197417, type: SakanType.banat),
    SakanLocation(name: "Balfaqih", lat: -7.75263186830388, lng: 112.18359620915209, type: SakanType.banin),
    SakanLocation(name: "Al jufri", lat: -7.7528427394132065, lng: 112.18234464525383, type: SakanType.banat),
    SakanLocation(name: "Baalawi", lat: -7.752732445202674, lng: 112.18206971883879, type: SakanType.banin),
    SakanLocation(name: "Qoah al adni", lat: -7.75350637962075, lng: 112.18342865701378, type: SakanType.umum),
    SakanLocation(name: "Asy-Syatiri", lat: -7.7539843902514045, lng: 112.18398673180647, type: SakanType.banin),
    SakanLocation(name: "Al maknun", lat: -7.753670118944408, lng: 112.18395588640065, type: SakanType.banin),
    SakanLocation(name: "Baharun", lat: -7.753666587439677, lng: 112.18370292289845, type: SakanType.banat),
    SakanLocation(name: "Ruwaq al junaid", lat: -7.754106176720971, lng: 112.18361198647617, type: SakanType.umum),
    SakanLocation(name: "Bin syihab", lat: -7.754304840688638, lng: 112.18495252671165, type: SakanType.banat),
    SakanLocation(name: "Bin smith", lat: -7.754424357149842, lng: 112.18538050525545, type: SakanType.banin),
    SakanLocation(name: "Hadiqoh", lat: -7.753989826001614, lng: 112.1842673885424, type: SakanType.umum),
    SakanLocation(name: "Al athos", lat: -7.754811073749485, lng: 112.184037049368, type: SakanType.banin),
    SakanLocation(name: "Al kaff", lat: -7.754832335181036, lng: 112.18411349232193, type: SakanType.banin),
    SakanLocation(name: "Alaydrus", lat: -7.752630393913193, lng: 112.18477461552447, type: SakanType.banin),
    SakanLocation(name: "Jamal layl", lat: -7.752296181198041, lng: 112.18419457983343, type: SakanType.banin),
    SakanLocation(name: "Maula kheila", lat: -7.753808390491807, lng: 112.18411784514544, type: SakanType.banat),
  ];

  List<SakanLocation> get _filteredLocations {
    if (_selectedFilter == null) return _allLocations;
    return _allLocations.where((e) => e.type == _selectedFilter || e.type == SakanType.umum).toList();
  }

  void _moveTo(LatLng coords) {
    _mapController.move(coords, 18.5);
  }

  Color _getMarkerColor(SakanType type) {
    switch (type) {
      case SakanType.banin: return Colors.blueAccent;
      case SakanType.banat: return Colors.pinkAccent;
      case SakanType.umum: return kGoldLight;
    }
  }

  String _getTypeLabel(SakanType type) {
    switch (type) {
      case SakanType.banin: return 'Banin';
      case SakanType.banat: return 'Banat';
      case SakanType.umum: return 'Umum';
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _filteredLocations.map((loc) {
      return Marker(
        point: loc.coord,
        width: 120,
        height: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kBgCard.withOpacity(0.85),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _getMarkerColor(loc.type), width: 1),
              ),
              child: Text(
                loc.name,
                style: const TextStyle(color: kTextPri, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            Icon(
              Icons.location_on,
              color: _getMarkerColor(loc.type),
              size: 32,
            ),
          ],
        ),
      );
    }).toList();

    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 80,
          height: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                child: const Text('Saya (Nailong)', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 2),
              // Nailong icon using network image or placeholder emoji
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://i.pinimg.com/originals/44/21/cd/4421cd6deadaa3dbbb654cca22b64d14.png', // cute yellow dragon/nailong picture
                  width: 40, height: 40, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('🦖', style: TextStyle(fontSize: 30)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Denah Sakan', style: TextStyle(color: kGoldLight, fontSize: 18)),
        backgroundColor: kBgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: kGoldLight),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('Semua', null),
                _buildFilterChip('Banin', SakanType.banin),
                _buildFilterChip('Banat', SakanType.banat),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _allLocations.first.coord,
                  initialZoom: 17.5,
                  maxZoom: 20,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.markaz.sigma.app',
                  ),
                  PolylineLayer(
                    polylines: [
                      if (_routePoints.isNotEmpty)
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 4.0,
                          color: Colors.blueAccent,
                        ),
                    ],
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              color: kBgDark,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredLocations.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xFF2A2A2A), height: 1),
                itemBuilder: (context, index) {
                  final loc = _filteredLocations[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: _getMarkerColor(loc.type).withOpacity(0.2),
                      child: Icon(Icons.maps_home_work, color: _getMarkerColor(loc.type), size: 18),
                    ),
                    title: Text(loc.name, style: const TextStyle(color: kTextPri, fontWeight: FontWeight.bold)),
                    subtitle: Text(_getTypeLabel(loc.type), style: const TextStyle(color: kTextSec, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoadingRoute) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kGoldLight))
                        else TextButton(
                          onPressed: () => _getRoute(loc.coord),
                          style: TextButton.styleFrom(backgroundColor: kGoldDim, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                          child: const Text('Rute', style: TextStyle(color: kGoldLight, fontSize: 12)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.my_location, color: kGoldLight),
                          onPressed: () {
                            _moveTo(loc.coord);
                            setState(() => _routePoints = []); // clear route
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      _moveTo(loc.coord);
                      setState(() => _routePoints = []); // clear route
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kBgCard,
        child: const Icon(Icons.zoom_out_map, color: kGold),
        onPressed: () {
          // Center to roughly the middle of all points
          _mapController.move(const LatLng(-7.7536, 112.1837), 16.5);
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, SakanType? type) {
    final isSelected = _selectedFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? kGold : kBgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kGold.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : kGoldLight,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
