import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Bloc/auth_bloc.dart';
import '../start_journey_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';

/// Root shell screen shown after successful login.
///
/// Tab layout:
///   0 → HomeTabPage   — StartJourneyScreen + always-visible profile avatar
///   1 → HistoryScreen — all past scan sessions
///   2 → ProfileScreen — user info + logout
class HomeNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const HomeNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeNavigationScreen> createState() => _HomeNavigationScreenState();
}

class _HomeNavigationScreenState extends State<HomeNavigationScreen> {
  late int _currentIndex;
  late final AuthBloc _authBloc;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _authBloc = AuthBloc();

    // HomeTabPage owns the profile button — tapping it switches to History (index 1)
    // so the user sees their past scan results immediately.
    _pages = [
      HomeTabPage(onProfileTap: () => setState(() => _currentIndex = 1)),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  void dispose() {
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _authBloc,
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      ),
    );
  }
}

// ── Home Tab Page ─────────────────────────────────────────────────────────────
//
// Owns the profile avatar button as part of its own widget subtree.
// Because it is a full tab page (not a shell overlay), the button is
// always visible whenever this tab is active — the user never has to
// navigate away and back to find it.

class HomeTabPage extends StatefulWidget {
  /// Callback invoked when the user taps the profile avatar.
  /// HomeNavigationScreen passes a closure that switches to the History tab.
  final VoidCallback onProfileTap;

  const HomeTabPage({super.key, required this.onProfileTap});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage> {
  String _initials = '';

  @override
  void initState() {
    super.initState();
    _loadInitials();
  }

  Future<void> _loadInitials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('userInfo') ?? '{}';
    try {
      final info = json.decode(raw) as Map<String, dynamic>;
      final name = (info['name'] ?? '').toString().trim();
      if (name.isNotEmpty && mounted) {
        final parts = name.split(RegExp(r'\s+'));
        final initials = parts.length >= 2
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : parts[0][0].toUpperCase();
        setState(() => _initials = initials);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // The outer Scaffold (HomeNavigationScreen) has already placed this widget
    // below the status bar, so MediaQuery.padding.top is 0 here on most devices.
    // We keep the expression for safety in edge cases.
    final topPad = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── Scan start screen ─────────────────────────────────────────────
        const StartJourneyScreen(),

        // ── Profile avatar — ALWAYS visible on this tab ───────────────────
        // Embedded directly in this tab's Stack so it is never hidden by
        // tab switches or shell rebuilds.  Tapping shows scan history.
        Positioned(
          top: topPad + 14,
          right: 20,
          child: _ProfileAvatarButton(
            initials: _initials,
            onTap: widget.onProfileTap,
          ),
        ),
      ],
    );
  }
}

// ── Profile avatar button ─────────────────────────────────────────────────────

class _ProfileAvatarButton extends StatelessWidget {
  final String initials;
  final VoidCallback onTap;

  const _ProfileAvatarButton({required this.initials, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFE4B3B8), Color(0xFFD79096)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B1F1F).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: Center(
          child: initials.isNotEmpty
              ? Text(
                  initials,
                  style: GoogleFonts.lora(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                )
              : const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 22,
                ),
        ),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD79096).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history_rounded,
                label: 'History',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFD79096);
    const inactiveColor = Color(0xFFB0A0A0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
