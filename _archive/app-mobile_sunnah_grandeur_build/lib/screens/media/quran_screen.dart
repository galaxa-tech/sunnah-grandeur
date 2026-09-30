import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/eye_row.dart';
import '../../widgets/video_row_item.dart';
import '../../providers/media_provider.dart';
import '../../models/video_model.dart';
import 'video_player_screen.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'All Reciters', 'Tilawah', 'Tajweed', 'Hifz', 'Tafseer'
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final media = context.watch<MediaProvider>();
    
    // Filter logic
    final displayedMedia = _selectedFilter == 0 
        ? media.quranMedia 
        : media.quranMedia.where((m) => m.category.toLowerCase() == _filters[_selectedFilter].toLowerCase()).toList();

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
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Quran', style: AppTextStyles.brandSmall(c)),
                Text('Tilawah · Tajweed · Memorization',
                    style: AppTextStyles.brandTag(c)),
              ]),
            ]),
          ),

          // Filter chips
          SizedBox(
            height: 46,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              itemCount: _filters.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedFilter == i
                        ? c.gold
                        : (c.isDark ? c.surf : Colors.white),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: _selectedFilter == i ? c.gold3 : c.bd2,
                    ),
                  ),
                  child: Text(_filters[i],
                      style: AppTextStyles.pill(c, size: 10,
                          color: _selectedFilter == i ? Colors.white : c.t3)),
                ),
              ),
            ),
          ),

          Expanded(
            child: media.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => media.refreshType('quran'),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(children: [
                      // Featured card (using first one if available)
                      if (displayedMedia.isNotEmpty)
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: displayedMedia.first))),
                          child: _FeaturedQuranCard(c: c, video: displayedMedia.first),
                        ),

                      const EyeRow(label: 'Available Content'),

                      if (displayedMedia.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Text('No content found in this category.', style: AppTextStyles.bodyMuted(c)),
                        ),

                      // List items
                      ...displayedMedia.map((m) => VideoRowItem(
                        title: m.title, 
                        author: m.author, 
                        duration: m.duration,
                        views: m.views,
                        pillLabel: m.category,
                        pillVariant: 'green',
                        thumbnailUrl: m.thumbnail,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerScreen(video: m))),
                      )),

                      const SizedBox(height: 20),
                    ]),
                  ),
                ),
          ),
        ]),
      ),
    );
  }
}

class _FeaturedQuranCard extends StatelessWidget {
  const _FeaturedQuranCard({required this.c, required this.video});
  final AppColors c;
  final VideoModel video;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2E7D52).withOpacity(0.20)),
        boxShadow: [BoxShadow(color: const Color(0x1A2E7D52), blurRadius: 12)],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: [
        // Thumb
        Container(
          height: 140,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0D2E1E), Color(0xFF2E7D52)],
            ),
          ),
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.18),
                border: Border.all(color: Colors.white.withOpacity(0.38), width: 1.5),
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 28),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    stops: [0, 0.7],
                    colors: [Color(0xA6000000), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Featured Tilawah',
                    style: AppTextStyles.cinzelSm(c,
                        color: const Color(0xFF6EE8A8), size: 8)
                        .copyWith(letterSpacing: 0.22 * 8)),
                  const SizedBox(height: 3),
                  Text(video.title,
                    style: AppTextStyles.heading(c, color: Colors.white,
                        fontSize: 18)),
                ]),
              ),
            ),
            Positioned(
              top: 10, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x992E7D52),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(video.duration,
                  style: AppTextStyles.bodyMuted(c, size: 8)
                      .copyWith(color: Colors.white)),
              ),
            ),
          ]),
        ),
        // Meta
        Container(
          color: c.isDark ? c.surf : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Text(video.author,
                style: AppTextStyles.body(c, size: 11)),
            const Spacer(),
            Text('${video.views} views', style: AppTextStyles.bodyMuted(c, size: 10)),
          ]),
        ),
      ]),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.c, required this.number, required this.title,
    required this.meta, required this.reciters,
  });
  final AppColors c;
  final String number, title, meta, reciters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Number circle
        Container(
          width: 90, height: 62,
          decoration: BoxDecoration(
            color: c.green.withOpacity(0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.green.withOpacity(0.14)),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.green.withOpacity(0.12),
              border: Border.all(color: c.green.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child: Text(number,
              style: AppTextStyles.heading(c, color: c.green, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 2),
            Text(title, style: AppTextStyles.heading(c, fontSize: 14)),
            const SizedBox(height: 5),
            Row(children: [
              Text(meta, style: AppTextStyles.bodyMuted(c, size: 9.5)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: c.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: c.green.withOpacity(0.22)),
                ),
                child: Text(reciters,
                  style: TextStyle(fontSize: 8, color: c.green,
                      fontWeight: FontWeight.w500, fontFamily: 'Jost')),
              ),
            ]),
          ]),
        ),
      ]),
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
