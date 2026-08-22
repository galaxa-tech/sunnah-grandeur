import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/sg_pill.dart';

class MasjidFinderScreen extends StatefulWidget {
  const MasjidFinderScreen({super.key});

  @override
  State<MasjidFinderScreen> createState() => _MasjidFinderScreenState();
}

class _MasjidFinderScreenState extends State<MasjidFinderScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(51.5074, -0.1278); // London fallback
  bool _locationLoaded = false;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      bool svcEnabled = await Geolocator.isLocationServiceEnabled();
      if (!svcEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      final userLatLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return;

      setState(() {
        _center = userLatLng;
        _locationLoaded = true;
        _markers.add(Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ));
      });

      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userLatLng, 14));
    } catch (e) {
      debugPrint('[MasjidFinder] location: $e');
    }
  }

  void _addMasjidMarkers(List<QueryDocumentSnapshot> docs) {
    final masjidMarkers = <Marker>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final lat  = (data['lat']  as num?)?.toDouble();
      final lng  = (data['lng']  as num?)?.toDouble();
      if (lat == null || lng == null) continue;

      masjidMarkers.add(Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: data['name'] ?? 'Masjid',
          snippet: data['address'] ?? '',
        ),
      ));
    }
    if (mounted) {
      setState(() {
        _markers = {
          ..._markers.where((m) => m.markerId.value == 'user'),
          ...masjidMarkers,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(children: [
              _BackBtn(c: c),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Masjid Finder', style: AppTextStyles.brandSmall(c)),
                  Text(_locationLoaded ? 'Showing your area' : 'London · Default',
                      style: AppTextStyles.brandTag(c)),
                ],
              )),
              _IconBtn(icon: Icons.my_location_rounded, c: c,
                  onTap: () {
                    _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_center, 14));
                  }),
            ]),
          ),

          // Google Map
          Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.bd2),
            ),
            clipBehavior: Clip.hardEdge,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 13),
              onMapCreated: (ctrl) => _mapController = ctrl,
              markers: _markers,
              myLocationEnabled: _locationLoaded,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),

          // Masjid list from Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('masjids').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading masjids', style: AppTextStyles.body(c)));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mosque_outlined, color: c.t3, size: 40),
                      const SizedBox(height: 12),
                      Text('No masjids found nearby', style: AppTextStyles.bodyMuted(c)),
                    ],
                  ));
                }

                // Add masjid markers once data loads
                WidgetsBinding.instance.addPostFrameCallback((_) => _addMasjidMarkers(docs));

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isHighlighted = index == 0;
                    return Column(children: [
                      _MasjidCard(
                        c: c,
                        name:         data['name']    ?? 'Unknown Masjid',
                        address:      data['address'] ?? '',
                        distancePill: isHighlighted ? 'Nearest' : 'Nearby',
                        isHighlighted: isHighlighted,
                        bottomLine:   data['details'] as String?,
                        onTap: () {
                          final lat = (data['lat'] as num?)?.toDouble();
                          final lng = (data['lng'] as num?)?.toDouble();
                          if (lat != null && lng != null) {
                            _mapController?.animateCamera(
                                CameraUpdate.newLatLngZoom(LatLng(lat, lng), 16));
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ]);
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }
}

class _MasjidCard extends StatelessWidget {
  const _MasjidCard({
    required this.c, required this.name, required this.address,
    required this.distancePill, this.isHighlighted = false,
    this.bottomLine, this.onTap,
  });
  final AppColors c;
  final String name, address, distancePill;
  final bool isHighlighted;
  final String? bottomLine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted ? c.gold.withValues(alpha: 0.05) : (c.isDark ? c.surf : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isHighlighted ? c.gold.withValues(alpha: 0.20) : c.bd),
          boxShadow: isHighlighted ? null : [BoxShadow(color: const Color(0x0D644028), blurRadius: 4)],
        ),
        child: Column(children: [
          Row(children: [
            _MasjidIcon(c: c),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,    style: AppTextStyles.heading(c, fontSize: 16)),
                const SizedBox(height: 2),
                Text(address, style: AppTextStyles.bodyMuted(c, size: 10)),
                const SizedBox(height: 6),
                Row(children: [
                  SgPill(label: distancePill, variant: 'gold', fontSize: 8),
                  if (isHighlighted) ...[
                    const SizedBox(width: 5),
                    const SgPill(label: 'Open now', variant: 'green', fontSize: 8),
                  ],
                ]),
              ],
            )),
            Icon(Icons.chevron_right_rounded,
                color: isHighlighted ? c.gold : c.t3, size: 18),
          ]),
          if (bottomLine != null) ...[
            const SizedBox(height: 9),
            Divider(color: c.bd, height: 1),
            const SizedBox(height: 9),
            Text(bottomLine!, style: AppTextStyles.bodyMuted(c, size: 9.5), textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }
}

class _MasjidIcon extends StatelessWidget {
  const _MasjidIcon({required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: c.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.gold.withValues(alpha: 0.20)),
      ),
      child: Icon(Icons.mosque_outlined, color: c.gold, size: 20),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn({required this.c});
  final AppColors c;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Container(width: 30, height: 30,
      decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(9),
          border: Border.all(color: c.bd2)),
      child: Icon(Icons.chevron_left_rounded, color: c.gold, size: 20)),
  );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.c, this.onTap});
  final IconData icon;
  final AppColors c;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: c.surf, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.bd2)),
      child: Icon(icon, color: c.gold, size: 18)),
  );
}
