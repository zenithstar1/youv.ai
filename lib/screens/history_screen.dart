import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/activity_model.dart';
import '../utils/responsive.dart';
import '../widgets/history_card.dart';
import '../widgets/empty_activity_widget.dart';
import 'analysis_type_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ActivityModel> _activities = [];
  bool _isLoading = true;

  // Filter state: 'all' | 'completed' | 'pending'
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  /// Simulates an async data fetch with a short delay.
  ///
  /// BACKEND INTEGRATION: Replace this with:
  ///   final token = prefs.getString('_token') ?? '';
  ///   final data  = await ApiService.getAnalysisHistory(token);
  ///   setState(() => _activities = data);
  Future<void> _loadActivities() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _activities = ActivityRepository.getMockActivities();
        _isLoading = false;
      });
    }
  }

  List<ActivityModel> get _filtered {
    if (_selectedFilter == 'all') return _activities;
    return _activities.where((a) => a.status == _selectedFilter).toList();
  }

  void _navigateToScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AnalysisTypeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F0),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFFFF5F0),
            elevation: 0,
            title: Text(
              'My Analysis History',
              style: GoogleFonts.lora(
                fontSize: r.sp(18),
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3B1F1F),
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(r.h(52)),
              child: _FilterChips(
                selected: _selectedFilter,
                onSelect: (f) => setState(() => _selectedFilter = f),
                r: r,
              ),
            ),
          ),

          // ── Content ────────────────────────────────────────────────────────
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFD79096)),
              ),
            )
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: EmptyActivityWidget(
                onStartScan: () => _navigateToScan(context),
              ),
            )
          else ...[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                r.w(18),
                r.h(16),
                r.w(18),
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: Text(
                  '${_filtered.length} scan${_filtered.length == 1 ? '' : 's'} found',
                  style: GoogleFonts.poppins(
                    fontSize: r.sp(12),
                    color: const Color(0xFF8A7A72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                r.w(18),
                r.h(12),
                r.w(18),
                r.h(24),
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final activity = _filtered[index];
                    return HistoryCard(
                      activity: activity,
                      // BACKEND INTEGRATION: onTap → navigate to detail screen
                      // passing activity.id to fetch full results
                      onTap: () => _showComingSoon(context),
                    );
                  },
                  childCount: _filtered.length,
                ),
              ),
            ),
          ],
        ],
      ),

      // FAB to start a new scan
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _navigateToScan(context),
              backgroundColor: const Color(0xFFD79096),
              icon: const Icon(Icons.add_a_photo_outlined, color: Colors.white),
              label: Text(
                'New Scan',
                style: GoogleFonts.lora(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF3B1F1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          'Detailed view coming soon!',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
    );
  }
}

// ── Filter chips bar ──────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final Responsive r;

  const _FilterChips({
    required this.selected,
    required this.onSelect,
    required this.r,
  });

  @override
  Widget build(BuildContext context) {
    final filters = [
      ('all', 'All'),
      ('completed', 'Completed'),
      ('pending', 'Pending'),
    ];

    return Container(
      height: r.h(48),
      color: const Color(0xFFFFF5F0),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.w(18), vertical: r.h(8)),
        children: filters.map((f) {
          final isActive = selected == f.$1;
          return GestureDetector(
            onTap: () => onSelect(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: r.w(10)),
              padding: EdgeInsets.symmetric(
                horizontal: r.w(16),
                vertical: r.h(4),
              ),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFD79096) : Colors.white,
                borderRadius: BorderRadius.circular(r.w(20)),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFD79096)
                      : const Color(0xFFE4B3B8),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color:
                              const Color(0xFFD79096).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                f.$2,
                style: GoogleFonts.poppins(
                  fontSize: r.sp(12.5),
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFF8A7A72),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
