import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/location_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/sg_pill.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  final _searchCtrl = TextEditingController();
  List<CityResult> _suggestions = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String q, LocationProvider loc) {
    setState(() => _suggestions = loc.searchCities(q));
  }

  Future<void> _useGps(LocationProvider loc) async {
    final ok = await loc.useCurrentLocation();
    if (!mounted) return;
    if (ok) {
      _searchCtrl.clear();
      setState(() => _suggestions = []);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Location updated'),
        duration: Duration(seconds: 2),
      ));
    } else if (loc.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.error!), duration: const Duration(seconds: 3)),
      );
    }
  }

  void _pickCity(CityResult city, LocationProvider loc) async {
    await loc.setManualLocation(city.lat, city.lng, city.displayName);
    if (!mounted) return;
    _searchCtrl.clear();
    setState(() => _suggestions = []);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Location set to ${city.city}'),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final c   = AppColors.of(context);
    final loc = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: c.surf,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: c.bd2),
                  ),
                  child: Icon(Icons.arrow_back_ios_rounded, color: c.gold, size: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Location', style: AppTextStyles.heading(c, fontSize: 19)),
                  Text('PRAYER TIME CALIBRATION', style: AppTextStyles.brandTag(c)),
                ],
              )),
              if (loc.isLoading)
                SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.gold),
                ),
            ]),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Current location card ─────────────────────────────────
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(18),
                    decoration: c.goldCardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.gold.withOpacity(0.15)),
                    ),
                    child: Row(children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          color: c.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.gold.withOpacity(0.25)),
                        ),
                        child: Icon(Icons.my_location_rounded, color: c.gold, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.hasLocation ? loc.locationLabel : 'No location set',
                            style: AppTextStyles.displaySm(c).copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            loc.hasLocation ? loc.coordLabel : 'Using London fallback',
                            style: AppTextStyles.body(c, color: c.gold, size: 10),
                          ),
                        ],
                      )),
                      SgPill(
                        label: loc.hasLocation ? 'Active' : 'Default',
                        variant: loc.hasLocation ? 'green' : 'gold',
                        fontSize: 8,
                      ),
                    ]),
                  ),

                  _EyeRow(label: 'GPS', c: c),

                  // ── Use current location ──────────────────────────────────
                  GestureDetector(
                    onTap: loc.isLoading ? null : () => _useGps(loc),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: c.bd),
                      ),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: c.goldSurface,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: c.gold.withOpacity(0.14)),
                          ),
                          child: loc.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(7),
                                  child: CircularProgressIndicator(strokeWidth: 2, color: c.gold),
                                )
                              : Icon(Icons.gps_fixed_rounded, color: c.gold, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Use Current Location', style: AppTextStyles.body(c, size: 13)),
                            Text('Detects your city via GPS', style: AppTextStyles.bodyMuted(c, size: 10)),
                          ],
                        )),
                        Icon(Icons.chevron_right_rounded, color: c.t3, size: 18),
                      ]),
                    ),
                  ),

                  _EyeRow(label: 'Search City', c: c),

                  // ── Search field ──────────────────────────────────────────
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: c.surf,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _searchCtrl.text.isNotEmpty
                            ? c.gold.withOpacity(0.40) : c.bd2,
                      ),
                    ),
                    child: Row(children: [
                      Icon(Icons.search_rounded, color: c.t3, size: 15),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          style: AppTextStyles.body(c, size: 13),
                          decoration: InputDecoration(
                            hintText: 'Search for a city...',
                            hintStyle: AppTextStyles.bodyMuted(c, size: 13),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (q) => _onSearchChanged(q, loc),
                        ),
                      ),
                      if (_searchCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _suggestions = []);
                          },
                          child: Icon(Icons.close_rounded, color: c.t3, size: 15),
                        ),
                    ]),
                  ),

                  // ── Suggestions ───────────────────────────────────────────
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: c.surf,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.bd),
                      ),
                      child: Column(
                        children: _suggestions.asMap().entries.map((e) {
                          final city = e.value;
                          final isLast = e.key == _suggestions.length - 1;
                          return GestureDetector(
                            onTap: () => _pickCity(city, loc),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: isLast ? null : Border(
                                    bottom: BorderSide(color: c.bd, width: 0.5)),
                              ),
                              child: Row(children: [
                                Icon(Icons.location_on_outlined, color: c.gold, size: 14),
                                const SizedBox(width: 10),
                                Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(city.city, style: AppTextStyles.body(c, size: 13)),
                                    Text('${city.country} · ${city.coordLabel}',
                                        style: AppTextStyles.bodyMuted(c, size: 10)),
                                  ],
                                )),
                                Icon(Icons.chevron_right_rounded, color: c.t3, size: 16),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // ── Popular cities (shown when search is empty) ────────────
                  if (_suggestions.isEmpty && _searchCtrl.text.isEmpty) ...[
                    Text('POPULAR CITIES', style: AppTextStyles.brandTag(c).copyWith(fontSize: 8)),
                    const SizedBox(height: 10),
                    ..._popularCities.map((city) => GestureDetector(
                      onTap: () => _pickCity(city, loc),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color: loc.cityName == city.displayName
                              ? c.goldSurface : c.surf,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: loc.cityName == city.displayName
                                ? c.gold.withOpacity(0.40) : c.bd,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: c.goldSurface,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: c.gold.withOpacity(0.14)),
                            ),
                            child: Icon(Icons.location_city_outlined,
                                color: c.gold, size: 15),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(city.displayName, style: AppTextStyles.body(c, size: 13)),
                              Text(city.coordLabel, style: AppTextStyles.bodyMuted(c, size: 10)),
                            ],
                          )),
                          if (loc.cityName == city.displayName)
                            const SgPill(label: 'Active', variant: 'gold', fontSize: 8)
                          else
                            Icon(Icons.chevron_right_rounded, color: c.t3, size: 18),
                        ]),
                      ),
                    )),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// Popular cities shown as quick-select
const List<CityResult> _popularCities = [
  CityResult('Mecca', 'Saudi Arabia', 21.3891, 39.8579),
  CityResult('London', 'UK', 51.5074, -0.1278),
  CityResult('New York', 'USA', 40.7128, -74.0060),
  CityResult('Dhaka', 'Bangladesh', 23.8103, 90.4125),
  CityResult('Karachi', 'Pakistan', 24.8607, 67.0011),
  CityResult('Istanbul', 'Turkey', 41.0082, 28.9784),
];

class _EyeRow extends StatelessWidget {
  const _EyeRow({required this.label, required this.c});
  final String label;
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Text(label.toUpperCase(), style: AppTextStyles.brandTag(c)),
        const SizedBox(width: 10),
        Expanded(child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.gold.withOpacity(0.2), Colors.transparent],
            ),
          ),
        )),
      ]),
    );
  }
}
