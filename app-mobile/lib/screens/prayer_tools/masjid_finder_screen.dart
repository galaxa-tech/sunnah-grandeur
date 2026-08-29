// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/masjid_result.dart';
import '../../providers/masjid_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_snackbar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dark Islamic map style (matches app dark theme: bg #0D0D0F, gold #C8A55A)
// ─────────────────────────────────────────────────────────────────────────────
const _kDarkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d0d0f"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#706860"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d0d0f"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a1a1d"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#c8a55a"}]},
  {"featureType":"poi","elementType":"labels.text","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#171719"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#0e130e"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1f1f23"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#252528"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#706860"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#252528"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2e2e34"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f1f23"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#b0a898"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#171719"}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#706860"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#080a0c"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#3d4b5c"}]}
]
''';

const _kLightMapStyle = '''
[
  {"featureType":"administrative","elementType":"labels.text.fill","stylers":[{"color":"#7a5a18"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#a07828"}]},
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f0ece0"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#d4e4f5"}]}
]
''';

// ─────────────────────────────────────────────────────────────────────────────
// MasjidFinderScreen — pure UI, reads from MasjidProvider via Consumer.
//
// Lifecycle-tied state that MUST live in the widget:
//   _mapCtrl     — GoogleMapController (disposes with widget)
//   _sheetCtrl   — DraggableScrollableController
//   _searchCtrl  — TextEditingController
//   _searchFocus — FocusNode
//   _searchActive — whether the search bar is expanded
//   _markers     — rebuilt from provider.masjids whenever data changes
//
// Everything else (position, masjids, status, error) lives in MasjidProvider.
// ─────────────────────────────────────────────────────────────────────────────
class MasjidFinderScreen extends StatefulWidget {
  const MasjidFinderScreen({super.key});

  @override
  State<MasjidFinderScreen> createState() => _MasjidFinderScreenState();
}

class _MasjidFinderScreenState extends State<MasjidFinderScreen>
    with SingleTickerProviderStateMixin {
  // ── Map (widget-owned, lifecycle-tied) ────────────────────────────────────
  GoogleMapController? _mapCtrl;
  Set<Marker>          _markers = {};
  BitmapDescriptor?    _mosqueIcon;
  BitmapDescriptor?    _selectedIcon;

  // ── Search ────────────────────────────────────────────────────────────────
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  bool   _searchActive = false;

  // ── Sheet ─────────────────────────────────────────────────────────────────
  final _sheetCtrl = DraggableScrollableController();

  // ── Animation ─────────────────────────────────────────────────────────────
  late final AnimationController _animCtrl;

  // ── Track last known provider state for camera sync ───────────────────────
  LatLng? _lastCameraCenter;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _initMarkerIcons();

    // Kick off location + mosque load via the provider.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MasjidProvider>().init();
    });
  }

  @override
  void dispose() {
    _mapCtrl?.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _sheetCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Marker icons ──────────────────────────────────────────────────────────

  Future<void> _initMarkerIcons() async {
    _mosqueIcon   = BitmapDescriptor.defaultMarkerWithHue(40);
    _selectedIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueYellow);
  }

  // ── Rebuild markers whenever provider data changes ────────────────────────

  void _rebuildMarkers(
      List<MasjidResult> masjids, MasjidResult? selected) {
    final newMarkers = <Marker>{};

    for (final m in masjids) {
      final isSelected = selected?.placeId == m.placeId;
      newMarkers.add(Marker(
        markerId: MarkerId(m.placeId),
        position: LatLng(m.lat, m.lng),
        icon: isSelected
            ? (_selectedIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueYellow))
            : (_mosqueIcon ??
                BitmapDescriptor.defaultMarkerWithHue(40)),
        zIndex: isSelected ? 2 : 1,
        onTap: () => _onMarkerTap(m),
        infoWindow: InfoWindow(
          title:   m.name,
          snippet: m.distanceText.isNotEmpty ? m.distanceText : m.vicinity,
        ),
      ));
    }

    if (mounted) setState(() => _markers = newMarkers);
  }

  // ── Map interactions ──────────────────────────────────────────────────────

  void _onMarkerTap(MasjidResult m) {
    context.read<MasjidProvider>().select(m);
    _rebuildMarkers(
        context.read<MasjidProvider>().masjids, m);
    _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(m.lat, m.lng), 16));
    _showDetailSheet(m);
  }

  void _onCardTap(MasjidResult m) {
    context.read<MasjidProvider>().select(m);
    _rebuildMarkers(
        context.read<MasjidProvider>().masjids, m);
    _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(m.lat, m.lng), 16));
    _sheetCtrl.animateTo(
      0.35,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _showDetailSheet(m);
  }

  void _goToMyLocation() {
    final pos = context.read<MasjidProvider>().center;
    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _navigate(MasjidResult m) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${m.lat},${m.lng}'
      '&destination_place_id=${m.placeId}'
      '&travelmode=walking',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        showAppSnackbar(context, 'Could not open navigation.',
            type: AppSnackbarType.error);
      }
    }
  }

  // ── Detail bottom sheet ───────────────────────────────────────────────────

  void _showDetailSheet(MasjidResult m) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context:    context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _MasjidDetailSheet(masjid: m, c: c, onNavigate: _navigate),
    ).whenComplete(() {
      if (mounted) {
        context.read<MasjidProvider>().select(null);
        _rebuildMarkers(
            context.read<MasjidProvider>().masjids, null);
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c      = AppColors.of(context);
    final isDark = c.isDark;

    return Consumer<MasjidProvider>(
      builder: (context, mp, _) {
        // ── Sync camera to provider position when it first arrives ──────────
        final center = mp.center;
        if (_mapCtrl != null && _lastCameraCenter != center) {
          _lastCameraCenter = center;
          _mapCtrl?.animateCamera(
              CameraUpdate.newLatLngZoom(center, 15));
        }

        // ── Sync markers when data changes ──────────────────────────────────
        // Schedule a post-frame rebuild so we don't call setState during build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _rebuildMarkers(mp.masjids, mp.selected);
        });

        return Scaffold(
          backgroundColor: c.bg,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // ── 1. Full-screen Google Map ────────────────────────────────
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition:
                      CameraPosition(target: center, zoom: 14),
                  onMapCreated: (ctrl) async {
                    _mapCtrl = ctrl;
                    await ctrl.setMapStyle(
                        isDark ? _kDarkMapStyle : _kLightMapStyle);
                    // Move to real position immediately if already known.
                    if (mp.position != null) {
                      ctrl.animateCamera(CameraUpdate.newLatLngZoom(
                          mp.center, 15));
                    }
                  },
                  markers: _markers,
                  myLocationEnabled:    mp.position != null,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled:  false,
                  mapToolbarEnabled:    false,
                  compassEnabled:       true,
                  buildingsEnabled:     true,
                  onTap: (_) {
                    _searchFocus.unfocus();
                    if (_searchActive && _searchCtrl.text.isEmpty) {
                      setState(() => _searchActive = false);
                    }
                  },
                ),
              ),

              // ── 2. Top bar (search + controls) ──────────────────────────
              Positioned(
                top: 0, left: 0, right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Column(
                      children: [
                        _TopBar(
                          c:            c,
                          searchCtrl:   _searchCtrl,
                          searchFocus:  _searchFocus,
                          searchActive: _searchActive,
                          onSearchToggle: () => setState(() {
                            _searchActive = !_searchActive;
                            if (_searchActive) {
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () => _searchFocus.requestFocus(),
                              );
                            } else {
                              _searchFocus.unfocus();
                              _searchCtrl.clear();
                              mp.refresh();
                            }
                          }),
                          onSearchSubmit: mp.search,
                          onMyLocation:   _goToMyLocation,
                          onRefresh:      mp.refresh,
                        ),
                        // Loading bar
                        if (mp.isBusy)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                backgroundColor: c.surf,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(c.gold),
                                minHeight: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 3. Error banner ──────────────────────────────────────────
              if (mp.hasError && mp.errorMessage != null)
                Positioned(
                  top: 110, left: 16, right: 16,
                  child: _ErrorBanner(
                    message: mp.errorMessage!,
                    c: c,
                    onRetry: mp.retry,
                  ),
                ),

              // ── 4. Bottom draggable sheet ────────────────────────────────
              DraggableScrollableSheet(
                controller:       _sheetCtrl,
                initialChildSize: 0.32,
                minChildSize:     0.12,
                maxChildSize:     0.88,
                snap:             true,
                snapSizes:        const [0.12, 0.32, 0.65, 0.88],
                builder: (ctx, scrollCtrl) => _BottomSheet(
                  c:          c,
                  masjids:    mp.masjids,
                  selected:   mp.selected,
                  isLoading:  mp.isBusy,
                  scrollCtrl: scrollCtrl,
                  onCardTap:  _onCardTap,
                  onNavigate: _navigate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.c,
    required this.searchCtrl,
    required this.searchFocus,
    required this.searchActive,
    required this.onSearchToggle,
    required this.onSearchSubmit,
    required this.onMyLocation,
    required this.onRefresh,
  });
  final AppColors              c;
  final TextEditingController  searchCtrl;
  final FocusNode              searchFocus;
  final bool                   searchActive;
  final VoidCallback           onSearchToggle;
  final void Function(String)  onSearchSubmit;
  final VoidCallback           onMyLocation;
  final VoidCallback           onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Back button
        _MapBtn(
          icon: Icons.arrow_back_ios_new_rounded,
          c: c,
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),

        // Search / title bar
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: searchActive
                ? _SearchField(
                    key: const ValueKey('search'),
                    c: c,
                    ctrl: searchCtrl,
                    focus: searchFocus,
                    onSubmit: onSearchSubmit,
                    onClear: () {
                      searchCtrl.clear();
                      onSearchSubmit('');
                    },
                  )
                : _TitleBar(key: const ValueKey('title'), c: c),
          ),
        ),
        const SizedBox(width: 8),

        // Search toggle
        _MapBtn(
          icon: searchActive
              ? Icons.close_rounded
              : Icons.search_rounded,
          c: c,
          onTap: onSearchToggle,
        ),
        const SizedBox(width: 6),

        // My location
        _MapBtn(
          icon: Icons.my_location_rounded,
          c: c,
          onTap: onMyLocation,
          gold: true,
        ),
        const SizedBox(width: 6),

        // Refresh
        _MapBtn(
          icon: Icons.refresh_rounded,
          c: c,
          onTap: onRefresh,
        ),
      ],
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({super.key, required this.c});
  final AppColors c;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color:        c.bg2.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(13),
        border:       Border.all(color: c.bd2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.mosque_rounded, color: c.gold, size: 16),
          const SizedBox(width: 8),
          Text(
            'Masjid Finder',
            style: GoogleFonts.inter(
              color:      c.t1,
              fontSize:   14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.c,
    required this.ctrl,
    required this.focus,
    required this.onSubmit,
    required this.onClear,
  });
  final AppColors             c;
  final TextEditingController ctrl;
  final FocusNode             focus;
  final void Function(String) onSubmit;
  final VoidCallback          onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color:        c.bg2.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(13),
        border:       Border.all(color: c.gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: c.gold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              focusNode:  focus,
              style:      GoogleFonts.inter(color: c.t1, fontSize: 13),
              decoration: InputDecoration(
                border:      InputBorder.none,
                isDense:     true,
                hintText:    'Search mosques, city…',
                hintStyle:   GoogleFonts.inter(color: c.t3, fontSize: 13),
                contentPadding: EdgeInsets.zero,
              ),
              textInputAction: TextInputAction.search,
              onSubmitted:   onSubmit,
            ),
          ),
          if (ctrl.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.clear_rounded, color: c.t3, size: 16),
            ),
        ],
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  const _MapBtn({
    required this.icon,
    required this.c,
    this.onTap,
    this.gold = false,
  });
  final IconData     icon;
  final AppColors    c;
  final VoidCallback? onTap;
  final bool         gold;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color:        gold ? c.gold : c.bg2.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: gold ? c.gold : c.bd2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 10,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon,
            color: gold ? Colors.white : c.t2, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBanner
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(
      {required this.message, required this.c, required this.onRetry});
  final String       message;
  final AppColors    c;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        c.bg2.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: c.red.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style:
                    GoogleFonts.inter(color: c.t2, fontSize: 12, height: 1.4)),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: c.gold, borderRadius: BorderRadius.circular(8)),
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontSize:   11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _BottomSheet — draggable list of mosques
// ─────────────────────────────────────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.c,
    required this.masjids,
    required this.selected,
    required this.isLoading,
    required this.scrollCtrl,
    required this.onCardTap,
    required this.onNavigate,
  });
  final AppColors                        c;
  final List<MasjidResult>               masjids;
  final MasjidResult?                    selected;
  final bool                             isLoading;
  final ScrollController                 scrollCtrl;
  final void Function(MasjidResult)      onCardTap;
  final Future<void> Function(MasjidResult) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        c.bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: c.bd2, width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 24,
              offset: const Offset(0, -8)),
        ],
      ),
      child: Column(
        children: [
          // ── Handle ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                  color: c.bd2, borderRadius: BorderRadius.circular(2)),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              Icon(Icons.mosque_rounded, color: c.gold, size: 18),
              const SizedBox(width: 8),
              Text(
                isLoading
                    ? 'Searching mosques…'
                    : masjids.isEmpty
                        ? 'No mosques found'
                        : '${masjids.length} mosque${masjids.length == 1 ? '' : 's'} nearby',
                style: GoogleFonts.inter(
                  color:      c.t1,
                  fontSize:   14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (!isLoading && masjids.isNotEmpty)
                Text(
                  'Sorted by distance',
                  style: GoogleFonts.inter(color: c.t3, fontSize: 10),
                ),
            ]),
          ),

          // ── List ─────────────────────────────────────────────────────
          Expanded(
            child: isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(c.gold),
                        ),
                        const SizedBox(height: 16),
                        Text('Finding nearby mosques…',
                            style: GoogleFonts.inter(
                                color: c.t3, fontSize: 12)),
                      ],
                    ),
                  )
                : masjids.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mosque_outlined,
                                color: c.t3.withValues(alpha: 0.4), size: 52),
                            const SizedBox(height: 14),
                            Text('No mosques found nearby',
                                style:
                                    AppTextStyles.heading(c, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text('Try searching a different area or city',
                                style: AppTextStyles.bodyMuted(c, size: 12)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        controller:  scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount:   masjids.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) => _MasjidCard(
                          masjid:     masjids[i],
                          isSelected:
                              selected?.placeId == masjids[i].placeId,
                          c:          c,
                          isFirst:    i == 0,
                          onTap:      () => onCardTap(masjids[i]),
                          onNavigate: () => onNavigate(masjids[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MasjidCard — list item
// ─────────────────────────────────────────────────────────────────────────────
class _MasjidCard extends StatelessWidget {
  const _MasjidCard({
    required this.masjid,
    required this.isSelected,
    required this.c,
    required this.isFirst,
    required this.onTap,
    required this.onNavigate,
  });
  final MasjidResult masjid;
  final bool         isSelected;
  final AppColors    c;
  final bool         isFirst;
  final VoidCallback onTap;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final highlighted = isFirst || isSelected;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        isSelected
              ? c.gold.withValues(alpha: 0.08)
              : highlighted
                  ? c.goldSurface
                  : c.surf,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? c.gold.withValues(alpha: 0.40)
                : highlighted
                    ? c.gold.withValues(alpha: 0.18)
                    : c.bd,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: c.gold.withValues(alpha: 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Row(
          children: [
            // Mosque icon
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color:        highlighted
                    ? c.gold.withValues(alpha: 0.12)
                    : c.elev,
                borderRadius: BorderRadius.circular(12),
                border:       Border.all(
                    color: highlighted
                        ? c.gold.withValues(alpha: 0.25)
                        : c.bd2),
              ),
              child: Icon(Icons.mosque_rounded,
                  color: highlighted ? c.gold : c.t3, size: 22),
            ),

            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    masjid.name,
                    style: GoogleFonts.inter(
                      color:      c.t1,
                      fontSize:   14,
                      fontWeight: FontWeight.w600,
                      height:     1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    masjid.vicinity,
                    style: GoogleFonts.inter(
                        color: c.t3, fontSize: 11, height: 1.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    // Distance
                    if (masjid.distanceText.isNotEmpty) ...[
                      _Pill(
                        label: masjid.distanceText,
                        icon:  Icons.place_rounded,
                        color: c.gold,
                        c:     c,
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Open status
                    if (masjid.openNow != null) ...[
                      _Pill(
                        label: masjid.openNow! ? 'Open' : 'Closed',
                        icon:  masjid.openNow!
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                        color: masjid.openNow! ? c.green : c.red,
                        c:     c,
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Rating
                    if (masjid.rating != null)
                      _Pill(
                        label: '★ ${masjid.ratingText}',
                        color: const Color(0xFFF59E0B),
                        c:     c,
                      ),
                  ]),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Navigate button
            GestureDetector(
              onTap: onNavigate,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  gradient:     c.goldGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: c.gold.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.navigation_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.c,
    this.icon,
  });
  final String    label;
  final Color     color;
  final AppColors c;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border:       Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon!, color: color, size: 9),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              color:      color,
              fontSize:   9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MasjidDetailSheet — modal bottom sheet shown on marker / card tap
// ─────────────────────────────────────────────────────────────────────────────
class _MasjidDetailSheet extends StatelessWidget {
  const _MasjidDetailSheet({
    required this.masjid,
    required this.c,
    required this.onNavigate,
  });
  final MasjidResult                    masjid;
  final AppColors                       c;
  final Future<void> Function(MasjidResult) onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        c.bg2,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: c.bd2)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 38, height: 4,
              decoration: BoxDecoration(
                  color: c.bd2, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          // Name row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient:     c.goldGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: c.gold.withValues(alpha: 0.30),
                        blurRadius: 14,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: const Icon(Icons.mosque_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      masjid.name,
                      style: GoogleFonts.cormorantGaramond(
                        color:      c.t1,
                        fontSize:   22,
                        fontWeight: FontWeight.w700,
                        height:     1.2,
                      ),
                    ),
                    if (masjid.rating != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < (masjid.rating! - 0.25).round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFF59E0B),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${masjid.ratingText}'
                          '${masjid.userRatingsTotal != null ? ' (${masjid.userRatingsTotal})' : ''}',
                          style:
                              GoogleFonts.inter(color: c.t3, fontSize: 11),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          Divider(color: c.bd, height: 1),
          const SizedBox(height: 16),

          // Details
          _DetailRow(
            icon:  Icons.place_rounded,
            label: 'Address',
            value: masjid.vicinity.isNotEmpty ? masjid.vicinity : 'Unknown',
            c:     c,
          ),
          const SizedBox(height: 12),
          if (masjid.distanceText.isNotEmpty) ...[
            _DetailRow(
              icon:  Icons.directions_walk_rounded,
              label: 'Distance',
              value: masjid.distanceText,
              c:     c,
            ),
            const SizedBox(height: 12),
          ],
          if (masjid.openNow != null)
            _DetailRow(
              icon:  masjid.openNow!
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              label: 'Status',
              value: masjid.openNow! ? 'Open now' : 'Closed',
              valueColor: masjid.openNow! ? c.green : c.red,
              c:    c,
            ),

          const SizedBox(height: 24),

          // Navigate button
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              onNavigate(masjid);
            },
            child: Container(
              width:  double.infinity,
              height: 54,
              decoration: BoxDecoration(
                gradient:     c.goldGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: c.gold.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: const Offset(0, 5))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.navigation_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Get Directions',
                    style: GoogleFonts.inter(
                      color:      Colors.white,
                      fontSize:   15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Close
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close',
                  style: GoogleFonts.inter(color: c.t3, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.c,
    this.valueColor,
  });
  final IconData  icon;
  final String    label;
  final String    value;
  final AppColors c;
  final Color?    valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color:        c.goldSurface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: c.gold, size: 15),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      color:      c.t3,
                      fontSize:   10,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.inter(
                    color:      valueColor ?? c.t1,
                    fontSize:   13,
                    fontWeight: FontWeight.w500,
                    height:     1.3,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
